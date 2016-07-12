if [ ! $1 ]
	then echo "Please specify a device. Eg: erase-drive.sh sda"
	exit
fi

chain="=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

echo "WARNING: This script will attempt to do an Enhanced Secure erase on /dev/$1"
echo "All data on this device will be deleted and the OS will be reloaded (if available)"
read -p "Enter \"I know what I am doing\" to continue. This will be your LAST chance: " choice
	if [ "$choice" != "I know what I am doing" ] ; then
		echo "Stopping now... restart with \"bash /root/erase-drive.sh sda\""
		exit
	fi

dd if=/dev/$1 bs=4k count=1 of=/root/temp1.dat 2> /dev/null

# Check if the drive is marked as "frozen"
	if [[ $( hdparm -I /dev/$1 | grep frozen ) != *"not"* ]]
		#if the drive is marked as "frozen"
		then 
		echo $chain
		echo "/dev/$1 is marked as frozen. The computer will go into standby"
		echo "               in 5 seconds to un-freeze the disk."
		echo $chain
		sleep 5 && rtcwake -m mem -s 5 > /dev/null
		#a second check to see if it is NOW unfrozen
		if [[ $( hdparm -I /dev/$1 | grep frozen ) != *"not"* ]]
			then
			echo "Drive still frozen. Please contact support."
			echo "=-=-=-=-=-= !!! DRIVE NOT ERASED !!! =-=-=-=-=-="
			exit

			#drive is not frozen and ready to be erased
			else echo "Drive not marked as frozen. Proceeding!"
		fi
	fi

	hdparm --user-master u --security-set-pass TAIS /dev/$1 > /dev/null
	echo $chain

	echo "Starting Secure Erase..."
	hdparm --security-erase-enhanced TAIS /dev/$1 > /dev/null
	echo $chain
	echo "Enhanced Secure Erase has completed."

	partprobe /dev/$1

	#take the stored 1st 4k bytes of /dev/sda and compare it with the new value of /dev/sda
	# to verify that drive erasure occured

	sleep 5
	
	dd if=/dev/$1 bs=4k count=1 of=/root/temp2.dat 2> /dev/null
	
	#	NOTE: if TEST; then ... fi syntax relies on if TEST returns 0 (indicating successful exit).
	#		cmp returns value of 0 if files are the same, 1 if files differ, or 2 if trouble
	if [[ ! $( cmp /root/temp1.dat /root/temp2.dat ) ]]
		then 
			echo $chain
			echo "------------------------------- SSD IS NOT CLEARED -------------------------------"
			echo $chain
			exit
		else 
			echo "SSD has been cleared. Rebuilding the drive for reuse"
	fi
	
	#Create a base MS-DOS partition table and leave it as that
	#NO OS WILL BE INSTALLED AND NO PARTITIONING IS PERFORMED - ONLY A PARTITION TABLE IS CREATED
	echo $chain
	echo "Creating MS-DOS type partition table now..."
	
	parted -a opt /dev/$1 mktable msdos
	partprobe /dev/$1
	echo "Partition table created."
	echo $chain