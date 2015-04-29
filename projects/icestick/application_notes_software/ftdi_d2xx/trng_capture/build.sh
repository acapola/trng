#!/bin/sh

mkdir build_dir_linux
rm build_dir_linux/*

cd build_dir_linux

c++ -I ../../common/linux ../../common/generic/kidekin_trng_ftdi_d2xx.cpp -c -std=c++11
c++ -I ../../common/generic ../trng_capture.cpp -o trng_capture -lpthread kidekin_trng_ftdi_d2xx.o ../../common/linux/x86_64/libftd2xx.a -lgomp -ldl -lusb -std=c++11

cd ..