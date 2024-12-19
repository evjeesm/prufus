#!/bin/sh
echo "Creating usb...."

echo $1
echo $2

mkdir -p /tmp/prufus
#if already exist clean first
rm -rf /tmp/prufus/status

echo 1 > /tmp/prufus/status

printf "g\nw\n" | fdisk -w always -W always $2 #create GPT table

iso_size=$(stat -c%s "$1") #iso file size in bytes
printf "File size in bytes $iso_size\n"

iso_size="$(($iso_size/1024))"
printf "File size in KiB $iso_size\n"

final_size="$(($iso_size+(1024*1024)))" #we add 1GiB for using

fdisk_size="+$final_size""K"
echo $fdisk_size

printf "n\n\n\n$fdisk_size\nt\n1\nw\n" | fdisk -w always -W always $2

mkfs.fat $2"1"

echo 8 > /tmp/prufus/status


echo "Creating temporal directories.."
echo 2 > /tmp/prufus/status
mkdir -p /tmp/prufus/iso
mkdir -p /tmp/prufus/usb

echo "Mounting USB and ISO"
echo 3 > /tmp/prufus/status
mount -t udf -o loop $1 /tmp/prufus/iso
mount $2"1" /tmp/prufus/usb #we use the number 1 partition EFI

rm -r /tmp/prufus/usb/* #temporal format

echo "Copying regular installtion files.."
echo 4 > /tmp/prufus/status
rsync -v -r -I --no-links --no-perms --no-owner --no-group --exclude sources/install.wim /tmp/prufus/iso/ /tmp/prufus/usb

echo "Copying big installation file.."
echo 5 > /tmp/prufus/status
wimlib-imagex split /tmp/prufus/iso/sources/install.wim /tmp/prufus/usb/sources/install.wim 1024

echo "Syncronizing disk..."
echo 6 > /tmp/prufus/status
time(sync)

echo "Synconization done"


echo "Cleaning..."
echo 7 > /tmp/prufus/status
umount /tmp/prufus/iso
umount /tmp/prufus/usb

echo "Booteable USB created!"
echo 8 > /tmp/prufus/status

#rm -r /tmp/prufus

#watch -d grep -e Dirty: -e Writeback: /proc/meminfo
