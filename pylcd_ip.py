'''
Copyright (C) 2012 Matthew Skolaut

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and 
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, 
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is 
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
'''

import pylcd

# Create instances of the tmp102 temp sensor and io
# expander controlling lcd
# tmp102 = pylcd.tmp102(0x48, 0) # address, bus#
lcd = pylcd.lcd(0x27, 1, 1)

#while 1:

#    lcd.lcd_puts("  Temp C: " + str(tmp102.read_temp()), 2)
#lcd.lcd_puts("Hello",1)
#lcd.lcd_puts("How are you doing?",2)
import socket
import fcntl
import struct

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

try:
    lcd.lcd_puts("wlan0 IP: " + get_ip_address('wlan0'),1)
    lcd.lcd_puts("eth0 IP: " + get_ip_address('eth0'),2)

except IOError:
    False
