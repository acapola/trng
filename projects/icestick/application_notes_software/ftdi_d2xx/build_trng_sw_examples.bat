::assume MinGW 4.8 is installed
c++ -I .\windows kidekin_trng_ftdi_d2xx.cpp -c -std=c++11

::assume Boost 1.57.0 built using MinGW
c++ -I c:\boost_1_57_0 trng_client.cpp -o trng_client c:\boost_1_57_0\stage\lib\libboost_system-mgw48-mt-1_57.a -lws2_32 -lgomp
c++ -I c:\boost_1_57_0 trng_server.cpp -o trng_server c:\boost_1_57_0\stage\lib\libboost_system-mgw48-mt-1_57.a -lws2_32 kidekin_trng_ftdi_d2xx.o .\windows\ftd2xx.lib
c++ -I c:\boost_1_57_0 trng_capture.cpp -o trng_capture c:\boost_1_57_0\stage\lib\libboost_system-mgw48-mt-1_57.a -lws2_32 kidekin_trng_ftdi_d2xx.o .\windows\ftd2xx.lib -lgomp

