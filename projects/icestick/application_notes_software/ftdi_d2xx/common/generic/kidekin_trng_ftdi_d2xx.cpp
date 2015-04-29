
#include <cstdlib>
#include <iostream>
#include <cstring>
#include <string.h>
#include "stdio.h"
#include "ftd2xx.h"
#define FTDI_BAUDRATE 3000000

#define BUF_USABLE_SIZE (sizeof(buf))

static FT_HANDLE ftHandle;
static uint8_t buf[1024];
static int readPos;
static bool verbose=true;

#ifdef FTD2XX_H_LINUX
//we use libusb to disconnect the ftdi_sio driver that tends to be loaded automatically on most systems
//in theory we could avoid this with udev rules, in practice coming up with a robust and portable solution is tricky...
#include <libusb-1.0/libusb.h>
static void libusb_disconnect_driver(void){
    struct libusb_context *usb_ctx;
    struct libusb_device_handle *usb_dev;
    libusb_device *dev;
    libusb_device **devs;
    int count = 0;
    int i = 0;

	if (libusb_init(&usb_ctx) < 0)
        throw new std::string("libusb_init() failed");

	try{
		if (libusb_get_device_list(usb_ctx, &devs) < 0)
			throw new std::string("libusb_get_device_list() failed");

		while ((dev = devs[i++]) != NULL){
			char description[1024];
			int desc_len=sizeof(description);
			struct libusb_device_descriptor desc;

			if (libusb_get_device_descriptor(dev, &desc) < 0)
				throw new std::string("libusb_get_device_descriptor() failed");

			if ((desc.idVendor == 0x403) &&(desc.idProduct == 0x6001 || 
											desc.idProduct == 0x6010 ||
											desc.idProduct == 0x6011 ||
											desc.idProduct == 0x6014 ||
											desc.idProduct == 0x6015)) {
				if(verbose) printf("device found: vendor=%X, product=%X\n",desc.idVendor, desc.idProduct);
				if (libusb_open(dev, &usb_dev) < 0) throw new std::string("libusb_open() failed");
				if (libusb_get_device_descriptor(dev, &desc) < 0) throw new std::string("libusb_get_device_descriptor() failed");

				if (libusb_get_string_descriptor_ascii(usb_dev, desc.iProduct, (unsigned char *)description, desc_len) < 0){
					libusb_close(usb_dev);
					throw new std::string("libusb_get_string_descriptor_ascii() failed");
				}
				
				if(strcmp(description,"kidekin_trng")==0){
					if(verbose) printf("%s found\n",description);
					libusb_detach_kernel_driver(usb_dev, 0);
					libusb_detach_kernel_driver(usb_dev, 1);
				}
				libusb_close(usb_dev);
			}
		}
		libusb_free_device_list(devs,1);
	} catch (std::string *s){
		libusb_exit(usb_ctx);
		throw s;
	}
	libusb_exit(usb_ctx);	
}
#endif
void kidekin_trng_set_verbose(bool verbose_value){
	verbose = verbose_value;
}

unsigned int kidekin_trng_ftdi_find_next(unsigned int start_index){
	unsigned int numDevs;
	#ifdef FTD2XX_H_LINUX
		libusb_disconnect_driver();
	#endif
	FT_STATUS ftStatus = FT_ListDevices(&numDevs,NULL,FT_LIST_NUMBER_ONLY); 
	if (ftStatus == FT_OK) { 
		if(verbose) printf("FT_ListDevices OK, number of devices connected is in numDevs=%d\n",numDevs); 
	} else {
		printf("FT_ListDevices failed\n");
		return -1;
	}
	if(numDevs<=start_index) throw new std::string("ERROR: index bigger than total number of devices");
	for(unsigned int index=start_index;index<numDevs;index++){
		char Buffer[64]; // buffer for description of the device 
		ftStatus = FT_ListDevices((PVOID)index,Buffer,FT_LIST_BY_INDEX|FT_OPEN_BY_DESCRIPTION); 
		if (ftStatus == FT_OK) { 
			if(verbose){
				printf("FT_ListDevices OK\n*");
				printf(Buffer);
				printf("*\n");
			}
		} else { 
			printf("FT_ListDevices failed\n");  
		}
		if(strcmp("kidekin_trng B", Buffer)==0) return index;//we can connect only to the "B" device, the "A" is used for programming the device itself...
	}
	return -1;
}

//return false if the device could not be openned
bool kidekin_trng_ftdi_d2xx_open(unsigned int device_index){
	readPos=-1;
	unsigned int numDevs;
	FT_STATUS ftStatus;

	ftStatus = FT_Open(device_index,&ftHandle);
	if (ftStatus == FT_OK) { 
		if(verbose) printf("FT_Open OK, use ftHandle to access device %d\n",device_index); 
	} else { 
		printf("FT_Open failed, device id=%d: 0x%08X\n",device_index,ftStatus);
		return false;
	}
	FT_SetTimeouts(ftHandle,10000,0);//set 10s timeout
	ftStatus = FT_SetBaudRate(ftHandle, FTDI_BAUDRATE); // Set baud rate
	if (ftStatus == FT_OK) { 
		if(verbose) printf("FT_SetBaudRate OK\n"); 
	} else { 
		printf("FT_SetBaudRate Failed: 0x%08X\n",ftStatus);
		return false;
	}
	// Set RTS/CTS flow control 
	ftStatus = FT_SetFlowControl(ftHandle, FT_FLOW_RTS_CTS, 0x11, 0x13); 
	if (ftStatus == FT_OK) { 
		if(verbose) printf("FT_SetFlowControl OK\n");  
	} else { 
		printf("FT_SetFlowControl Failed\n");  
	} 
	ftStatus = FT_Purge(ftHandle, FT_PURGE_RX | FT_PURGE_TX); // Purge both Rx and Tx buffers 
	if (ftStatus == FT_OK) { 
		if(verbose) printf("FT_Purge OK\n");   
	} else { 
		printf("FT_Purge failed\n");   
	}
	readPos=BUF_USABLE_SIZE;//buf is empty
	return true;
}
//return the number of bytes actually received, it should be equal to len, otherwise this indicates an error.
//if it is less than len, subsequent calls are likely to fail.
unsigned int kidekin_trng_ftdi_d2xx_read(uint8_t *rxBuffer, unsigned int len){
	if(readPos==-1) 
		return -1;
	unsigned int out=0;
	while(len){
		if(readPos==BUF_USABLE_SIZE){
			readPos=-1;
			FT_STATUS ftStatus;
			DWORD cnt;
			ftStatus = FT_Read(ftHandle,buf,BUF_USABLE_SIZE,&cnt); 
			if(ftStatus!=FT_OK) 
				return -1;
			if(cnt!=BUF_USABLE_SIZE) 
				return -1;
			readPos = 0;
		} 
		unsigned int remaining = BUF_USABLE_SIZE - readPos;
		unsigned int toRead = remaining;
		if(toRead > len) toRead = len;
		memcpy(rxBuffer+out,buf+readPos,toRead);
		readPos +=toRead;
		len-=toRead;
		out+=toRead;
	}
	return out;
}
void kidekin_trng_ftdi_d2xx_close(void){
	FT_Close (ftHandle);
}


