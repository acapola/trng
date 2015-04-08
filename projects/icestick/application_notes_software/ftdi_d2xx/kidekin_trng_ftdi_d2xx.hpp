#ifndef __KIDEKIN_TRNG_FTDI_D2XX_H__
#define __KIDEKIN_TRNG_FTDI_D2XX_H__

//find the index of a kidekin_trng device 
//call this with 0 to find the first device.
unsigned int kidekin_trng_ftdi_find_next(unsigned int start_index);

//return false if the device could not be openned
bool kidekin_trng_ftdi_d2xx_open(unsigned int device_index);

//return the number of bytes actually received, it should be equal to len, otherwise this indicates an error.
//if it is less than len, subsequent calls are likely to fail.
unsigned int kidekin_trng_ftdi_d2xx_read(uint8_t *rxBuffer, unsigned int len);

void kidekin_trng_ftdi_d2xx_close(void);

#endif
