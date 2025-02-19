#!/bin/bash

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
echo -e "${CYAN}Bypass MDM By iPC${NC}"
echo

# Get drive name
default_drive_name="Macintosh HD"
get_drive_name() {
	while true; do
		if [ -d "/Volumes/$default_drive_name" ]; then
			echo "Drive Name: $default_drive_name"
			return
		else
			read -p "Default drive name '$default_drive_name' not found. Enter your drive name: " drive_name
			if [ -d "/Volumes/${drive_name}" ]; then
				echo "$drive_name"
				return
			else
				echo -e "${RED}Error: The drive name '${drive_name}' was not found. Try again.${NC}" >&2
			fi
		fi
	done
}

# Get drive name
DRIVE_NAME=$(get_drive_name)
DATA_VOLUME="${DRIVE_NAME} - Data"

# display drive name
echo "$DRIVE_NAME"
echo "$DATA_VOLUME"
echo

# Prompt user for choice
PS3='Please enter your choice: '
options=("Bypass MDM from Recovery" "Quit")
select opt in "${options[@]}"; do
	case $opt in
		"Bypass MDM from Recovery")
			# Bypass MDM from Recovery
			echo -e "${YEL}Bypass MDM from Recovery"
			#if [ -d "/Volumes/${DATA_VOLUME}" ]; then
			#	echo -e "${GRN}Renaming ${DATA_VOLUME}"
			#	diskutil rename "${DATA_VOLUME}" "Data"
			#	DATA_VOLUME="Data"
			#fi

			# Create Temporary User
			echo -e "${GRN}Creating Temporary User"
			read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
			realName="${realName:=Apple}"
			read -p "Enter Temporary Username (Default is 'Apple'): " username
			username="${username:=Apple}"
			read -p "Enter Temporary Password (Default is '1234'): " passw
			passw="${passw:=1234}"
			if [[ ! -d "/Volumes/${DATA_VOLUME}/Users/$username" ]]; then
				dscl_path="/Volumes/${DATA_VOLUME}/private/var/db/dslocal/nodes/Default"
				dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
				dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
				dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
				dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
				dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
				mkdir -p "/Volumes/${DATA_VOLUME}/Users/$username"
				dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
				dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
				dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership $username
			else
				echo -e "${GRN}Temporary User already exist"
			fi

			# Block MDM domains
			if [[ ! `grep 'acmdm.apple.com' "/Volumes/${DRIVE_NAME}/etc/hosts"` ]]; then
				echo -e "${GRN}Blocking MDM & Profile Domains"
				echo "0.0.0.0 deviceenrollment.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
				echo "0.0.0.0 mdmenrollment.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
				echo "0.0.0.0 iprofiles.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
				echo "0.0.0.0 gdmf.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
				echo "0.0.0.0 acmdm.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
				echo "0.0.0.0 albert.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
			else
				echo -e "${GRN}MDM & Profile Domains already blocked"
			fi

			# Remove configuration profiles
			echo -e "${GRN}Removing configuration profiles"
			rm -f "/Volumes/${DATA_VOLUME}/private/var/db/.AppleSetupDone"
			rm -f "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
			rm -f "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
			touch "/Volumes/${DATA_VOLUME}/private/var/db/.AppleSetupDone"
			touch "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
			touch "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"

			# Result message
			echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
			echo -e "${NC}Quit terminal and reboot your Mac.${NC}"
			break
			;;

		"Quit")
			# Quit
			echo "Quitting..."
			sleep 3
			echo "Done"
			break
			;;

		*) echo "Invalid option $REPLY" ;;
	esac
done
