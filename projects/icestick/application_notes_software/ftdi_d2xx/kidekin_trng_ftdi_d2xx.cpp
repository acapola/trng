
#include <cstdlib>
#include <iostream>
#include <cstring>
#include <string.h>
#include "stdio.h"
#include "ftd2xx.h"
#include <cstdint>
#define FTDI_BAUDRATE 3000000

#define BUF_USABLE_SIZE (sizeof(buf))

static FT_HANDLE ftHandle;
static uint8_t buf[1024];
static int readPos;

unsigned int kidekin_trng_ftdi_find_next(unsigned int start_index){
	unsigned int numDevs;
	FT_STATUS ftStatus = FT_ListDevices(&numDevs,NULL,FT_LIST_NUMBER_ONLY); 
	if (ftStatus == FT_OK) { 
		printf("FT_ListDevices OK, number of devices connected is in numDevs=%d\n",numDevs); 
	} else {
		printf("FT_ListDevices failed\n"); 
	}
	if(numDevs<=start_index) throw new std::string("ERROR: index bigger than total number of devices");
	for(unsigned int index=start_index;index<numDevs;index++){
		char Buffer[64]; // buffer for description of the device 
		ftStatus = FT_ListDevices((PVOID)index,Buffer,FT_LIST_BY_INDEX|FT_OPEN_BY_DESCRIPTION); 
		if (ftStatus == FT_OK) { 
			printf("FT_ListDevices OK\n*");
			printf(Buffer);
			printf("*\n");
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
		printf("FT_Open OK, use ftHandle to access device %d\n",device_index); 
	} else { 
		printf("FT_Open failed, device id=%d: 0x%08X\n",device_index,ftStatus);
		return false;
	}
	FT_SetTimeouts(ftHandle,10000,0);//set 10s timeout
	ftStatus = FT_SetBaudRate(ftHandle, FTDI_BAUDRATE); // Set baud rate
	if (ftStatus == FT_OK) { 
		printf("FT_SetBaudRate OK\n"); 
	} else { 
		printf("FT_SetBaudRate Failed: 0x%08X\n",ftStatus);
		return false;
	}
	// Set RTS/CTS flow control 
	ftStatus = FT_SetFlowControl(ftHandle, FT_FLOW_RTS_CTS, 0x11, 0x13); 
	if (ftStatus == FT_OK) { 
		printf("FT_SetFlowControl OK\n");  
	} else { 
		printf("FT_SetFlowControl Failed\n");  
	} 
	ftStatus = FT_Purge(ftHandle, FT_PURGE_RX | FT_PURGE_TX); // Purge both Rx and Tx buffers 
	if (ftStatus == FT_OK) { 
		printf("FT_Purge OK\n");   
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


