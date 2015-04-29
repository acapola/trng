mkdir build_dir
rm build_dir\*

cd build_dir

::assume MinGW 4.8 is installed
c++ -I ..\..\common\windows ..\..\common\generic\kidekin_trng_ftdi_d2xx.cpp -c -std=c++11
c++ -I ..\..\common\generic ..\trng_capture.cpp -o trng_capture -lws2_32 kidekin_trng_ftdi_d2xx.o ..\..\common\windows\ftd2xx.lib -lgomp -std=c++11

cd ..