#!/bin/bash

help_text="Documentation:
Creates a new swapfile

Usage: 
  $(basename "$0") [OPTIONS]

Help Options:
  -h, --help		Display help message

Application Options:
  -n, --name		[Unimplemented] Set the name of the swapfile. (Default: '/swapfile')
			
			Format: [/][Name]
			 - / 		Optional
			 - Name:	Required. Alphanumeric name + (Special: '_' and '-').

			Examples:
			 - 'swapfile' for the name '/swapfile'.
			 - '/swapfile' for the name '/swapfile'	
			 - '/swapfile_ext' for the name '/swapfile_ext'

  -s, --size		[Unimplemented] Set the size of the swapfile, in bytes. 

			Format: [Number][Unit]
			 - Number: 	Required: Any positive integer greater than zero (0)
			 - Unit:	Required: Standard byte multiplicative suffix.

				* M, m		Megabytes [1000 * 1000]
				* G, g		Gigabytes [1000 * 1000 * 1000]
				
				[Unimplemented]	
				* T, t		Terabytes [1000 * 1000 * 1000 * 1000]
				* MiB, mib	Mebibytes [1024 * 1024]
				* GiB, gib	Gigibytes [1024 * 1024 * 1024]
				* TiB, tib	Teribytes [1024 * 1024 * 1024 * 1024]
				

			Examples:
			 - '512M' for 512 megabytes	[512,000,000 bytes]
			 - '1G' for 1 gigabyte

  -p, --permanent	[Unimplemented] Creates a permanent swapfile on the system.


Future Work:
  - Allow non-interactive script mode
  - Move everything to functions
  - Implement Swappiness
  - Allow single / batch swapfile removal
  - Allow easy debugging / testing support
  - Add color and bold support
  - Split up swapfile.sh into different parts. Help file, functions, CLI interactor
  - Split up Help (simple, format, examples)
"
			



ask_for_size_allocation="
>>>> Amount to allocate for new swapfile? (default: 4G) : "

ask_for_swapfile_name="
>>>> Filename for new swapfile? (default: '/swapfile') : "

line="# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #"

if [ "$(id -u)" != 0 ]; then
    echo "$0 must be run as root or with sudo (i.e. 'sudo $0')" >&2
    exit 1
fi

shopt -s extglob
shopt -s nocasematch

show_help=false
argument_error=false
error_message=

while true; do
	case "$1" in
		-h | --help ) 
			show_help=true; 
			shift ;;
		-- ) shift; break ;;
		?* ) 
			argument_error=true
			error_message="Invalid argument: $1" 
			shift; break ;;
		*) break ;;
	esac
done

if "$argument_error" ; then
	echo "$error_message"; exit 0
elif "$show_help" ; then
	echo "$help_text"; exit 0

fi

retry=true
while "$retry"; do
	read -r -p ">>>> Are you sure you want to create a new swapfile? (Y / N):" yes_no 
	case "$yes_no" in
		y | yes )

			echo -e "\n$line"
			echo -e "Current Swapfiles:\n"
			swapon -s 
			echo -e "$line"
			retry=false
			;;
		n | no | quit )
			echo -e ""
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
read -r -p "$ask_for_size_allocation" swap_size

if [ -z "${swap_size}" ]; then
	swap_size="4G"
elif [[ "$swap_size" =~ [1-9][0-9]*[mMgG] ]]; then
	:
elif [[ "$swap_size" =~ quit ]]; then
	echo -e ""
	echo -e ">> Exiting..."
	exit 0
else
	echo -e ">> Invalid Size: ${swap_size^^}."
	echo -e ""
	echo -e "Exiting..."
	exit 1
fi

echo -e ""
echo -e ">> Step 2: File Name"
read -r -p "$ask_for_swapfile_name" swap_name

if [ -z "${swap_name}" ]; then
	swap_name="/swapfile"
elif [[ "$swap_size" =~ quit ]]; then
	echo -e ""
	echo -e ">> Exiting..."
	exit 0
elif [[ "$swap_name" =~ [/]+([0-9a-zA-Z]|[_-]) ]]; then
	:
elif [[ "$swap_name" =~ [+([0-9a-zA-Z]|[_-])] ]]; then 
	swap_name="/$swap_name"	
else
	echo -e ">> Invalid Pattern: $swap_name."
	echo -e ""
	echo -e "Exiting..."
	exit 1
fi

echo -e ""
read -r -p ">>>> Continue? '$swap_name' (${swap_size^^}) will be created. (Y / N):" yes_no
case "$yes_no" in
	y | yes )
		echo -e""
		echo -e ">> 1. Creating swapfile..."
		
		echo -e ""
		echo -e "$line"

		fallocate -l "$swap_size" "$swap_name"
		chmod 600 "$swap_name"
		mkswap "$swap_name"
		
		echo -e "$line"
		echo -e ""

		echo -e ">> 2. Enabling swapfile..."
		swapon "$swap_name"

		echo -e ">> 3. Swapfile added."
		echo -e ""
		echo -e "$line"
		echo -e "Current Swapfiles:"
		echo -e ""
		swapon -s 
		echo -e "$line"
		echo -e ""
		;;
	n | no | quit | * )
		echo -e ""
		echo -e ">> Exiting..."
		exit 0
		;;
esac

read -r -p ">>>> Make swapfile permanent? (Y / N):" yes_no

case "$yes_no" in
	y | yes )

		echo -e "$swap_name none swap sw 0 0" | tee -a /etc/fstab > /dev/null

		echo -e ""
		echo -e ">> 4. Created permanent swapfile. Modified '/etc/fstab'"

		read -r -p ">>>> Do you want to view '/etc/fstab?' (Y / N):" yes_no

		case "$yes_no" in
			y | yes )
				
				echo -e ""
				echo -e "$line"
				cat /etc/fstab 
				echo -e "$line"
				;;
			* )
				echo -e ""
				echo -e ">> Exiting..."
				exit 0
				;;
		esac
		;;
	quit )
		echo -e ""
		echo -e ">> Exiting..."
		exit 0	
		;;
	n | no | * )
		echo -e ""
		echo -e ">> 4. Created temp swapfile."
		echo -e ""
		echo -e ">> Exiting..."
		exit 0
		;;
esac

