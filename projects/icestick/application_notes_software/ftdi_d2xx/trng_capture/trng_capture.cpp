
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <iostream>
#include "kidekin_trng_ftdi_d2xx.hpp"
#include <omp.h>

using namespace std;

enum { max_length = 1024*4 };

void trng_write(FILE* pFile, unsigned long long len){
	while(len){
		unsigned char data[max_length];
		unsigned int read_len = len < max_length ? len : max_length;
		unsigned int actual_len = kidekin_trng_ftdi_d2xx_read(data,read_len);
		if(actual_len!=read_len) throw new string("kidekin_trng_ftdi_d2xx_read failed");
		if(pFile!=0) fwrite(data, 1, actual_len, pFile);
		len-=actual_len;
	}
}

void trng_write_file(string filename, unsigned long long len){
	FILE* pFile;
	pFile = fopen(filename.c_str(), "wb");
	trng_write(pFile,len);
	fclose(pFile);
}

unsigned char nibbleToHex(unsigned int n){
	unsigned char lsbs = 0x0F & n;//we look only at the 4 least significant bits
	if(lsbs<10) return lsbs+'0';
	else return lsbs-10+'A';
}

void toHexStr(const unsigned char* bin, unsigned char* hexStr, unsigned int len){
	for(unsigned int i=0;i<len;i++){
		hexStr[2*i]   = nibbleToHex(bin[i]>>4);//MSBs
		hexStr[2*i+1] = nibbleToHex(bin[i]);//LSBs
	}
}

void trng_write_hex(FILE* pFile, unsigned long long len){
	while(len){
		unsigned char data[max_length];
		unsigned char hexdata[2*max_length];//hex data size is doubled as it takes two characters to encode numbers from 0 to 255 (0xFF).
		unsigned int read_len = len < max_length ? len : max_length;
		unsigned int actual_len = kidekin_trng_ftdi_d2xx_read(data,read_len);
		if(actual_len!=read_len) throw new string("kidekin_trng_ftdi_d2xx_read failed");
		toHexStr(data,hexdata,actual_len);//could be included in the following if. Leaving this out allows to see the impact of the hex conversion on throughput (likely insignificant on most systems).
		if(pFile!=0) fwrite(hexdata, 1, 2*actual_len, pFile);
		len-=actual_len;
	}
}

void trng_write_file_hex(string filename, unsigned long long len){
	FILE* pFile;
	pFile = fopen(filename.c_str(), "w");
	trng_write_hex(pFile,len);
	fclose(pFile);
}

int main(int argc, char* argv[]) try {
	if ((argc-1 > 3) || (argc==2 && strcmp(argv[1],"help")==0)){
	  cerr << "Usage: trng_capture [size] [output_file_name] [txt]"<<endl;
	  cerr << "   size:             " << "Data size in mega bytes if output is a file, in bytes if output is 'stdout'"<<endl;
	  cerr << "   output_file_name: " << "File name or 'stdout' (screen output) or 'null' (don't write anywhere)" << endl;
	  cerr << "   txt:              " << "Output text rather than binary data" << endl; 
	  return 1;
	}
	//default values
	unsigned long long len = 2;
	string out_name = "trng_capture_output.dat";
	bool txt=false;
	
	//command line
	if(argc>1) len = atoll(argv[1]);
	if(argc>2) out_name = argv[2];
	if(argc>3){
		if(strcmp(argv[3],"txt")) throw new std::string("ERROR: third argument is optional, but if present it must be exactly `txt`");
		txt = true;
	}
	bool output_to_stdout = out_name=="stdout";
	bool output_to_null = out_name=="null";
	if(output_to_stdout){
		kidekin_trng_set_verbose(false); //don't print info message to stdout as a calling program expects only random data.
	} else {
		len = len *1024*1024; //length in mega bytes when writing to file. 
	}
	unsigned int id = kidekin_trng_ftdi_find_next(0);
	if(id<0) throw new std::string("ERROR: could not find any kidekin_trng");

	//open trng hardware
	if(!kidekin_trng_ftdi_d2xx_open(id)) throw new std::string("ERROR: could not open kidekin_trng");

	// Starting the time measurement
	double start = omp_get_wtime();
	
	// Computations to be measured
	if(txt){
		if(output_to_stdout) trng_write_hex(stdout,len);
		else if(output_to_null)  trng_write_hex(0,len);
		else trng_write_file_hex(out_name,len);
	}else{
		if(output_to_stdout) trng_write(stdout,len);
		else if(output_to_null)  trng_write(0,len);
		else trng_write_file(out_name,len);
	}
	// Measuring the elapsed time
	double end = omp_get_wtime();
	
	// Time calculation (in seconds)	
	double exec_time = end-start;
	
	double mbits = ((double)len)/(1024*1024/8);
	double mbits_per_sec = mbits / exec_time;
	if(!output_to_stdout) std::cout << "Reply time is: " << exec_time <<"s, "<< mbits_per_sec <<"MBits/s ("<< mbits_per_sec/8 <<"MBytes/s)\n";
	
	//close trng hardware
	kidekin_trng_ftdi_d2xx_close();//does not matter much if open failed or was not even called.
	return 0;
} catch (exception& e){
	cerr << "Exception: " << e.what() << "\n";
	return 3;
} catch (std::string* s){
	cerr << "Exception: " << *s <<"\n";
	return 4;
}

