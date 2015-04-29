#!/bin/bash
#date > /home/seb/run.log
#need to wait a little, the system take few seconds to actually mount the device.
sleep 20
#/bin/stty raw -F /dev/kidekin_trng speed 3000000
echo $kernel > /sys/bus/usb/drivers/ftdi_sio/unbind

#date >> /home/seb/run.log
#/bin/stty raw -F /dev/kidekin_trng speed 3000000 >> /home/seb/run.log
#/bin/stty -F /dev/kidekin_trng -a >> /home/seb/run.log
#date >> /home/seb/run.log
