#!/bin/bash

help_text="
Documentation:

    Usage: $(basename "$0") [-h]
    Creates a new permanent swapfile

    where:
        -h  displays help text"

ask_for_size_allocation="
>>>> Amount to allocate for new swapfile? (default: 4G) : "

ask_for_swapfile_name="
>>>> Filename for new swapfile? (default: '/swapfile') : "

line="# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"

shopt -s extglob

case $1 in
	-h|--help )
		echo -e "$help_text"
		exit 0
		;;
esac

retry=true
while $retry; do
	echo -e -n ">>>> Are you sure you want to create a new swapfile? (Y / N):"
	read yes_no
	case $yes_no in
		[Yy]|[Yy][Ee][Ss] )

			echo -e "\n$line"
			echo -e "Current Swapfiles:\n"
			sudo swapon -s 
			echo -e "$line"
			retry=false
			;;
		[Nn]|[Nn][Oo]|[Qq][Uu][Ii][Tt] )
			echo -e ">> Exiting..."
			exit 0
			;;
		* )
			echo -e ">> Error: invalid response\n"
			retry=true
	esac
done

echo -e ""
echo -e ">> Step 1: Size Allocation"
echo -e -n $ask_for_size_allocation
read swap_size

if [ -z "${swap_size}" ]; then
	swap_size="4G"
elif [[ $swap_size =~ [1-9][0-9]*[mMgG] ]]; then
	:
elif [[ $swap_size =~ [Qq][Uu][Ii][Tt] ]]; then
	echo -e ">> Exiting..."
	exit 0
else
	echo -e ">> Invalid Size: ${swap_size^^}. Exiting..."
	exit 1
fi

echo -e ""
echo -e ">> Step 2: File Name"
echo -e -n $ask_for_swapfile_name
read swap_name

if [ -z "${swap_name}" ]; then
	swap_name="/swapfile"
elif [[ $swap_size =~ [Qq][Uu][Ii][Tt] ]]; then
	echo -e ">> Exiting..."
	exit 0
elif [[ $swap_name =~ [/]+([0-9a-zA-Z]|[_-]) ]]; then
	:
elif [[ $swap_name =~ [+([0-9a-zA-Z]|[_-])] ]]; then 
	swap_name="/$swap_name"	
else
	echo -e ">> Invalid Pattern: $swap_name. Exiting..."
	exit 1
fi

echo -e ""
echo -e -n ">>>> Continue? '$swap_name' (${swap_size^^}) will be created. (Y / N):"
read yes_no
case $yes_no in
	[Yy]|[Yy][Ee][Ss] )
		echo -e""
		echo -e ">> 1. Creating swapfile..."
		
		echo -e ""
		echo -e "$line"

		sudo fallocate -l $swap_size $swap_name
		sudo chmod 600 $swap_name
		sudo mkswap $swap_name
		
		echo -e "$line"
		echo -e ""

		echo -e ">> 2. Enabling swapfile..."
		sudo swapon $swap_name

		echo -e ">> 3. Swapfile added."
		echo -e ""
		echo -e "$line"
		echo -e "Current Swapfiles:"
		echo -e ""
		sudo swapon -s 
		echo -e "$line"
		echo -e ""
		;;
	[Qq][Uu][Ii][Tt]|[Nn]|[Nn][Oo]|[*])
		echo -e ">> Exiting..."
		exit 0
		;;
esac

echo -e -n ">>>> Make swapfile permanent? (Y / N):"
read yes_no

case $yes_no in
	[Yy]|[Yy][Ee][Ss] )

		echo -e "$swap_name none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null

		echo -e ""
		echo -e ">> 4. Created permanent swapfile. Modified '/etc/fstab'"

		echo -e -n ">>>> Do you want to view '/etc/fstab?' (Y / N):"
			read yes_no

			case $yes_no in
				[Yy]|[Yy][Ee][Ss] )
					
					lenght=${#swap_name}
					echo -e ""
					echo -e "$line"
					cat /etc/fstab 
					echo -e "$line"
					;;
				*)
					echo -e ">> Exiting..."
					exit 0
					;;
			esac
		;;
	[Qq][Uu][Ii][Tt] )
		echo -e ">> Exiting..."
		exit 0	
		;;
	*)
		echo -e ">> 4. Created temp swapfile."
		echo -e ">> Exiting..."
		exit 0
		;;
esac

shopt -u extglob

