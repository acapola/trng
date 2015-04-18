
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <iostream>
#include "kidekin_trng_ftdi_d2xx.hpp"
#include <omp.h>

using namespace std;

enum { max_length = 1024*4 };

void trng_write_file(string filename, unsigned long long len){
	FILE* pFile;
	pFile = fopen(filename.c_str(), "wb");
	while(len){
		unsigned char data[max_length];
		unsigned int actual_len = kidekin_trng_ftdi_d2xx_read(data,max_length);
		if(actual_len!=max_length) throw new string("kidekin_trng_ftdi_d2xx_read failed");
		fwrite(data, 1, max_length, pFile);
		len-=max_length;
	}
	fclose(pFile);
}

int main(int argc, char* argv[]) try {
	if (argc-1 > 2){
	  cerr << "Usage: trng_capture [size_in_mega_bytes] [output_file_name]\n";
	  return 1;
	}
	//default values
	unsigned long long len = 2*1024*1024;
	string out_name = "trng_capture_output.dat";
	//command line
	if(argc>1) len = atoll(argv[1])*1024*1024;
	if(argc>2) out_name = argv[2];
		
	unsigned int id = kidekin_trng_ftdi_find_next(0);
	if(id<0) throw new std::string("ERROR: could not find any kidekin_trng");

	//open trng hardware
	if(!kidekin_trng_ftdi_d2xx_open(id)) throw new std::string("ERROR: could not open kidekin_trng");

	// Starting the time measurement
	double start = omp_get_wtime();
	
	// Computations to be measured
	trng_write_file(out_name,len);
	
	// Measuring the elapsed time
	double end = omp_get_wtime();
	
	// Time calculation (in seconds)	
	double exec_time = end-start;
	
	double mbits = ((double)len)/(1024*1024/8);
	double mbits_per_sec = mbits / exec_time;
	std::cout << "Reply time is: " << exec_time <<"s, "<< mbits_per_sec <<"MBits/s ("<< mbits_per_sec/8 <<"MBytes/s)\n";
	
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

