#!/bin/bash

clear
export LC_ALL=C

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Display header
echo -e "${CYAN}Bypass MDM v2 By iPC${NC}"
echo
if [ -d /Users ]; then
	echo "FAIL: This can only be run in Recovery Mode"
	echo
	exit 1
fi

# Get drive name
dataVolume=$(ls -1 /Volumes | grep ' - Data$')
rootVolume=${dataVolume% - Data}
rootVolumeMnt="/Volumes/$rootVolume"
dataVolumeMnt="/Volumes/$dataVolume"
sysconfdir="/var/db/ConfigurationProfiles/Settings"
confdir="$rootVolumeMnt$sysconfdir"

# display drive name
echo "$rootVolumeMnt"
echo "$dataVolumeMnt"
echo

# Prompt user for choice
PS3='Please enter your choice: '
options=("Bypass MDM v2 from Recovery" "Exit & Reboot")
select opt in "${options[@]}"; do
	case $opt in
		"Bypass MDM v2 from Recovery")
			# Bypass MDM v2 from Recovery
			echo -e "${YEL}Bypass MDM v2 from Recovery"

			# Create Temporary User
			echo -e "${GRN}Creating Temporary User"
			read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
			realName="${realName:=Apple}"
			read -p "Enter Temporary Username (Default is 'Apple'): " username
			username="${username:=Apple}"
			read -p "Enter Temporary Password (Default is '1234'): " passw
			passw="${passw:=1234}"
			if [ ! -d "${dataVolumeMnt}/Users/$username" ]; then
				dscl_path="${dataVolumeMnt}/private/var/db/dslocal/nodes/Default"
				user_path="/Local/Default/Users"
				group_path="/Local/Default/Groups"
				uid="501"
				while dscl -f "$dscl_path" localhost -list "$user_path" UniqueID | grep "\<${uid}$"; do let uid++; done
				dscl -f "$dscl_path" localhost -create "$user_path/$username"
				dscl -f "$dscl_path" localhost -create "$user_path/$username" UserShell "/bin/zsh"
				dscl -f "$dscl_path" localhost -create "$user_path/$username" RealName "$realName"
				dscl -f "$dscl_path" localhost -create "$user_path/$username" UniqueID "$uid"
				dscl -f "$dscl_path" localhost -create "$user_path/$username" PrimaryGroupID "20"
				mkdir -p "${dataVolumeMnt}/Users/$username"
				dscl -f "$dscl_path" localhost -create "$user_path/$username" NFSHomeDirectory "/Users/$username"
				dscl -f "$dscl_path" localhost -passwd "$user_path/$username" "$passw"
				dscl -f "$dscl_path" localhost -append "$group_path/admin" GroupMembership $username
			else
				echo -e "${GRN}Temporary User already exist"
			fi

			# Block MDM domains
			hostsfile="$rootVolumeMnt/etc/hosts"
			if [ ! `grep 'acmdm.apple.com' "$hostsfile"` ]; then
				echo -e "${GRN}Blocking MDM & Profile Domains"
				echo "0.0.0.0 deviceenrollment.apple.com" >> "$hostsfile"
				echo "0.0.0.0 mdmenrollment.apple.com" >> "$hostsfile"
				echo "0.0.0.0 iprofiles.apple.com" >> "$hostsfile"
				echo "0.0.0.0 gdmf.apple.com" >> "$hostsfile"
				echo "0.0.0.0 acmdm.apple.com" >> "$hostsfile"
				echo "0.0.0.0 albert.apple.com" >> "$hostsfile"
			else
				echo -e "${GRN}MDM & Profile Domains already blocked"
			fi

			# Remove configuration profiles
			echo -e "${GRN}Removing configuration profiles"
			touch "${dataVolumeMnt}/private/var/db/.AppleSetupDone"
			rm -Rf "$confdir/.cloudConfigHasActivationRecord"
			rm -Rf "$confdir/.cloudConfigRecordFound"
			touch "$confdir/.cloudConfigProfileInstalled"
			touch "$confdir/.cloudConfigRecordNotFound"

			# Result message
			echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
			echo -e "${NC}Exit terminal and reboot your Mac.${NC}"
			break
			;;

		"Exit & Reboot")
			# Exit & Reboot
			echo "Rebooting..."
			sleep 3
			reboot
			break
			;;

		*) echo "Invalid option $REPLY" ;;
	esac
done
