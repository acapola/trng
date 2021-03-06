mkdir build_dir
rm build_dir\*

cd build_dir

::assume MinGW 4.8 is installed
c++ -I ..\..\common\windows ..\..\common\generic\kidekin_trng_ftdi_d2xx.cpp -c -std=c++11

::assume Boost 1.57.0 built using MinGW
c++ -I c:\boost_1_57_0 ..\trng_client.cpp -o trng_client c:\boost_1_57_0\stage\lib\libboost_system-mgw48-mt-1_57.a -lws2_32 -lgomp
c++ -I c:\boost_1_57_0 ..\trng_server.cpp -I ..\..\common\generic -o trng_server c:\boost_1_57_0\stage\lib\libboost_system-mgw48-mt-1_57.a -lws2_32 kidekin_trng_ftdi_d2xx.o ..\..\common\windows\ftd2xx.lib -std=c++11

javac -d . ..\TrngClient.java

cd ..