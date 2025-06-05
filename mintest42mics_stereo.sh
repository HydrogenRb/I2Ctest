#!/bin/bash

set -e  # 让脚本在命令失败时退出

echo "开始I2C寄存器写入..."

write_register() {
    local reg=$1
    local value=$2
    echo -n "寄存器0x$reg 的值是"
    i2cget -y 1 0x18 0x$reg
    i2cset -y 1 0x18 0x$reg 0x$value
    echo -n "寄存器0x$reg 的新值是"
    i2cget -y 1 0x18 0x$reg
    echo ""
}

# Select Page 0
write_register 00 00
# Initialize the device through software reset
write_register 01 01

# Select Page 0
write_register 00 00
# NDAC = 1, MDAC = 2, dividers powered on
write_register 0b 81
#write_register 0c 82
write_register 0c 84 #加了这一行，修改了MDAC的值，输出clk应该是3Mhz

# NADC = 1, MADC = 4, dividers powered on 1000 0001
write_register 12 81
write_register 13 84 #1000 0100

# 设置GPIO读取频率
# CDIV_CLKIN应该被设置成ADC_MOD_CLK
# CLKOUT = CDIV_CLKIN / 1
# GPIO输出 合理的值应该是3Mhz
write_register 19 07 #CDIV_CLKIN被设置成0111
write_register 1a 81 #divider = 1 and power up
write_register 34 10 #设置GPIO输出
#write_register 34 1c #设置GPIO输出ADC_WCLK #备用

# Select Page 1
write_register 00 01
# Power up AVDD LDO
write_register 02 09
# Disable weak AVDD in presence of external
# AVDD supply
write_register 01 08
# Enable Master Analog Power Control
# Power up AVDD LDO
write_register 02 01

# Set the input power-up time to 3.1ms (for ADC)
write_register 47 32
# Set the REF charging time to 40ms
write_register 7b 01

#设置ADC
write_register 00 00 #Select Page 0
write_register 37 0e #Change the MFP4
write_register 38 02 #Change the MFP3
write_register 53 23 #Set the ADC 左音量是+20dB
write_register 54 23 #Set the ADC 右音量是+20dB
write_register 41 30 #set ADC with +24dB
write_register 42 30 #set ADC with +24dB
# write_register 1d 10 #直接将ADC的output链接DAC的input，看看到ADC这一步是否正确

# Select Page 1
write_register 00 01
# De-pop: 5 time constants, 6k resistance
write_register 14 25
# Route LDAC/RDAC to HPL/HPR
write_register 0c 08
write_register 0d 08
write_register 0e 08
write_register 0f 08
# Power up HPL/HPR
#write_register 09 30
write_register 09 3c #修改这个部分以配合LOL
# Unmute HPL/HPR driver, 0dB Gain
write_register 10 07 #set unmute and 29dB   00 011101
write_register 11 07 #set unmute and 29dB
write_register 12 07 #set unmute and 29dB
write_register 13 07 #set unmute and 29dB
# Select Page 0
write_register 00 00
# DAC => 0dB
write_register 41 00
write_register 42 00
# Power up LDAC/RDAC
write_register 3f d6
# Unmute LDAC/RDAC
write_register 40 00

#先启动DAC 再处理ADC
write_register 51 dc #Change the ADC channel and power 11011100
write_register 52 00 #Unmute the ADC 

#读取ADC的flag
echo "ADC的值是"
i2cget -y 1 0x18 0x24
