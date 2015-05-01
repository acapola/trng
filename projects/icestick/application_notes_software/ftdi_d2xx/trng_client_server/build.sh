#!/bin/sh

mkdir build_dir_linux
rm build_dir_linux/*

cd build_dir_linux

c++ -I ../../common/linux ../../common/generic/kidekin_trng_ftdi_d2xx.cpp -c -std=c++11

#assume Boost 1.57.0 built and installed in /usr/local/lib
c++ -I /usr/local/boost_1_57_0 ../trng_client.cpp -o trng_client /usr/local/lib/libboost_system.a -lpthread -lgomp
c++ -I /usr/local/boost_1_57_0 -I ../../common/generic ../trng_server.cpp -o trng_server /usr/local/lib/libboost_system.a -lpthread kidekin_trng_ftdi_d2xx.o ../../common/linux/x86_64/libftd2xx.a -lgomp -ldl -lusb -std=c++11

javac -d . ../TrngClient.java

cd ..