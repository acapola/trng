#!/bin/sh
c++ -I ./linux kidekin_trng_ftdi_d2xx.cpp -c -std=c++11

#assume Boost 1.57.0 built and installed in /usr/local/lib
c++ -I /usr/local/boost_1_57_0 trng_client.cpp -o client /usr/local/lib/libboost_system.a -lpthread -lgomp
c++ -I /usr/local/boost_1_57_0 trng_server.cpp -o server /usr/local/lib/libboost_system.a -lpthread kidekin_trng_ftdi_d2xx.o ./linux/x86_64/libftd2xx.a -lgomp -ldl

