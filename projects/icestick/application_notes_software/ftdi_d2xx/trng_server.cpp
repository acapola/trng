
#include <cstdlib>
#include <iostream>
#include <boost/asio.hpp>
#include "kidekin_trng_ftdi_d2xx.hpp"

using boost::asio::ip::udp;
using namespace std;
    
enum { max_length = 1024*4 };

void server(boost::asio::io_service& io_service, unsigned short port){
  udp::socket sock(io_service, udp::endpoint(udp::v4(), port));
  for (;;)
  {
    unsigned char data[max_length];
    udp::endpoint sender_endpoint;
    size_t length = sock.receive_from(
        boost::asio::buffer(data, max_length), sender_endpoint);
	unsigned int rndlen=max_length+1;
	if(length==3) rndlen = data[0]|(data[1]<<8)|(data[2]<<16);
	
	if(rndlen>max_length) continue;//invalid request, ignore it.
	
	//for(int i=0;i<rndlen;i++) data[i]=i;
	unsigned int actual_len = kidekin_trng_ftdi_d2xx_read(data,rndlen);
	if(actual_len!=rndlen) throw new string("kidekin_trng_ftdi_d2xx_read failed");
	sock.send_to(boost::asio::buffer(data, actual_len), sender_endpoint);
  }
}

int main(int argc, char* argv[])
{
	try{
		if (argc != 2)
		{
		  cerr << "Usage: blocking_udp_echo_server <port>\n";
		  return 1;
		}
		unsigned int id = kidekin_trng_ftdi_find_next(0);
		if(id<0) throw new std::string("ERROR: could not find any kidekin_trng");
	
		if(!kidekin_trng_ftdi_d2xx_open(id)) throw new std::string("ERROR: could not open kidekin_trng");

		boost::asio::io_service io_service;

		server(io_service, atoi(argv[1]));
	} catch (exception& e){
		cerr << "Exception: " << e.what() << "\n";
		return 3;
	} catch (std::string& s){
		cerr << "Exception: " << s <<"\n";
		return 4;
	}

	kidekin_trng_ftdi_d2xx_close();//does not matter much if open failed or was not even called.
	return 0;
}
