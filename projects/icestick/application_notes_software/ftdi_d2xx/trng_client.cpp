
#include <cstdlib>
#include <cstring>
#include <cstdio>
#include <iostream>
#include <boost/asio.hpp>
#include <omp.h>

using boost::asio::ip::udp;

enum { max_length = 1024*4 };

void write_binary_file(const char *name, const char *data, unsigned long long len){
    FILE* pFile;
    pFile = fopen(name, "wb");
    fwrite(data, 1, len, pFile);
    fclose(pFile);
}

int main(int argc, char* argv[])
{
	try
	{
		if (argc != 3)
		{
		  std::cerr << "Usage: trng_client <host> <port>\n";
		  return 1;
		}

		boost::asio::io_service io_service;

		udp::socket s(io_service, udp::endpoint(udp::v4(), 0));

		udp::resolver resolver(io_service);
		udp::resolver::query query(udp::v4(), argv[1], argv[2]);
		udp::resolver::iterator iterator = resolver.resolve(query);

		using namespace std;
		unsigned int req_cnt=0;
		while(true) {
			cout << "\nEnter amount of random data to request (in mega bytes): ";
			char request[10];
			cin.getline(request, sizeof(request));
			stringstream filename;
			filename << "reply_" << req_cnt << ".dat";
			
			FILE* pFile;
			pFile = fopen(filename.str().c_str(), "wb");
			
			unsigned long long len=atoll(request)*1024*1024;
			double mbits = ((double)len)/(1024*1024/8);
			request[0]=max_length & 0xFF;
			request[1]=(max_length>>8) & 0xFF;
			request[2]=(max_length>>16) & 0xFF;
			size_t request_length = 3;
			char reply[max_length];
			// Starting the time measurement
			double start = omp_get_wtime();
			// Computations to be measured
			while(len){
				if(len<max_length){
					request[0]=len & 0xFF;
					request[1]=(len>>8) & 0xFF;
					request[2]=(len>>16) & 0xFF;
				}
				s.send_to(boost::asio::buffer(request, request_length), *iterator);

				udp::endpoint sender_endpoint;
				size_t reply_length = s.receive_from(
					boost::asio::buffer(reply, max_length), sender_endpoint);
				fwrite(reply, 1, reply_length, pFile);
				len-=reply_length;
			}
			fclose(pFile);
			// Measuring the elapsed time
			double end = omp_get_wtime();
			// Time calculation (in seconds)	

			double exec_time = end-start;
			double mbits_per_sec = mbits / exec_time;
			std::cout << "Reply time is: " << exec_time <<"s, "<< mbits_per_sec <<"MBits/s ("<< mbits_per_sec/8 <<"MBytes/s)\n";
			req_cnt++;
		}
	}
  catch (std::exception& e)
  {
    std::cerr << "Exception: " << e.what() << "\n";
  }

  return 0;
}
