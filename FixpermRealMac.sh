#!/bin/bash

clear

#Check if it's Apple
if [[ `ioreg -lw0|grep -i 'org.netkas.fakesmc'` ]]; then
	echo "ERROR: This is not an Apple."
	echo
	exit 1
fi
#Done Check if it's Apple

export LC_ALL=C
MY_DIR=$(dirname "$0")
KERNEL_VERSION=$(uname -r)
KERNEL_MAJOR=$(echo "${KERNEL_VERSION}"|awk -F'.' '{print $1}')
KERNEL_MINOR=$(echo "${KERNEL_VERSION}"|awk -F'.' '{print $2}')
KERNEL_PATCH=$(echo "${KERNEL_VERSION}"|awk -F'.' '{print $3}')
KERNEL_BUILD="${KERNEL_MAJOR}.${KERNEL_MINOR}"
ver () { echo "$@"|awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }
BoldON="\033[1m"
BoldOFF="\033[0m"

echo -e "${BoldON}Running macOS Maintenance${BoldOFF}"
echo

#Enabling Tweaks
if [[ $(id -u) -ne 0 ]]; then # If not Root
	echo "Updating Preferences"
	if [ "$KERNEL_MAJOR" -ge 13 ]; then # Mav & above
		defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
		defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
		defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
		defaults write com.apple.finder ShowPathbar -bool true
		defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
		defaults write com.apple.finder ShowStatusBar -bool true
		defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
		defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
		defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
		defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
		defaults write -g com.apple.swipescrolldirection -bool false
		defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
		defaults write com.apple.dock autohide -bool true
		defaults write NSGlobalDomain AppleShowScrollBars -string 'Always'
		defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
		defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
		defaults write com.apple.CrashReporter UseUNC 1
		defaults write com.apple.LaunchServices LSQuarantine -bool false
	fi
	if [ "$KERNEL_MAJOR" -ge 19 ]; then # Catalina & above
		defaults write com.apple.finder NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow -bool true
	else
		defaults write com.apple.finder ShowTabView -bool true
	fi
	if [ "$KERNEL_MAJOR" -eq 14 -o "$KERNEL_MAJOR" -eq 15 -o "$KERNEL_MAJOR" -eq 16 -o "$KERNEL_MAJOR" -eq 17 ]; then # Yose-HS
		defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add "1" "MM/dd/yyyy"
		defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add "2" "MMM d y"
		defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add "3" "MMMM d y"
		defaults write NSGlobalDomain AppleICUDateFormatStrings -dict-add "4" "EEEE, MMMM d y"
	fi
	if [ "$KERNEL_MAJOR" -ge 17 ]; then # HS & above
		defaults write -g CSUIDisable32BitWarning -boolean true
	fi
	if [ "$KERNEL_MAJOR" -ge 18 ]; then # Mojave & above
		defaults write com.apple.dock show-recents -bool false
	fi
	if [ "$KERNEL_MAJOR" -le 20 ]; then # Bigsur & below (Disable Chrome Outdated Notification)
		defaults write com.google.Chrome SuppressUnsupportedOSWarning -bool true
	else
		defaults delete com.google.Chrome SuppressUnsupportedOSWarning #&>/dev/null
	fi
fi
#Done Enabling Tweaks

#Admin Rights
if [ $EUID != 0 ]; then
	exec sudo "$0" "$@"
	exit $?
fi
#Done Admin Rights

#Make it R/W
if [ "$KERNEL_MAJOR" -eq 19 ]; then # Catalina
	if [ ! -w / ]; then
		mount -uw / #&>/dev/null
	fi
fi
#Done Make it R/W

#Disabling Gatekeeper
status=$(csrutil status | grep "System Integrity Protection status:" | sed -n 's/.*status: *//p')
if [[ "$status" == "disabled." ]] ; then
	echo "Disabling Gatekeeper"
	if [ "$KERNEL_MAJOR" -le 19 ]; then # Catalina & below
		spctl --master-disable
	elif [ "$KERNEL_MAJOR" -eq 20 -o "$KERNEL_MAJOR" -eq 21 -o "$KERNEL_MAJOR" -eq 22 -o "$KERNEL_MAJOR" -eq 23 ]; then # BigSur-Sonoma
		spctl --global-disable
	fi
	if [ "$KERNEL_MAJOR" -eq 14 -o "$KERNEL_MAJOR" -eq 15 -o "$KERNEL_MAJOR" -eq 16 -o "$KERNEL_MAJOR" -eq 17 -o "$KERNEL_MAJOR" -eq 18 -o "$KERNEL_MAJOR" -eq 19 -o "$KERNEL_MAJOR" -eq 20 -o "$KERNEL_MAJOR" -eq 21 -o "$KERNEL_MAJOR" -eq 22 -o "$KERNEL_MAJOR" -eq 23 ]; then # Yose-Sonoma
		defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool false
	fi
	if [ "$KERNEL_MAJOR" -ge 24 ]; then # Sequoia & above
		defaults write /var/db/SystemPolicyConfiguration/SystemPolicy-prefs.plist enabled -string no
		chmod 644 /var/db/SystemPolicyConfiguration/SystemPolicy-prefs.plist
	fi
fi
#Done Disabling Gatekeeper

if [[ `sysctl -n hw.model|grep -i "MacBookAir7,2" ` ]]; then # if MacBookAir 2015 is using NVME 
	if [[ `system_profiler SPNVMeDataType|grep -i "NVMExpress:" ` ]]; then
		echo "NVME Detected. Setting Hibernate mode to 25"
		pmset -a hibernatemode 25
	else
		echo "Restoring Hibernate mode to 3"
		pmset -a hibernatemode 3
	fi
fi

#Delaying Microsoft Office Auto Update
if [ -e /Library/LaunchAgents/com.microsoft.update.agent.plist ]; then
	if [[ ! `grep -i '86400' /Library/LaunchAgents/com.microsoft.update.agent.plist` ]]; then
		echo "Delaying Microsoft Offce Update"
		plutil -replace StartInterval -integer 86400 /Library/LaunchAgents/com.microsoft.update.agent.plist
		chmod 644 /Library/LaunchAgents/com.microsoft.update.agent.plist
		chown root:wheel /Library/LaunchAgents/com.microsoft.update.agent.plist
	fi
fi
#Done Delaying Microsoft Office Auto Update

#Disabling Adobe Genuine Software Service
if [ -d /Library/Application\ Support/Adobe/AdobeGCClient ]; then
	if [[ ! `stat -f %A /Library/Application\ Support/Adobe/AdobeGCClient` == '444' ]]; then # if Permissions not 444
		echo "Disabling Adobe Genuine Software Service"
		rm -Rf /Library/Application\ Support/Adobe/AdobeGCClient/* #&>/dev/null
		chmod -R 0444 /Library/Application\ Support/Adobe/AdobeGCClient
		if [ -e /Library/LaunchDaemons/com.adobe.agsservice.plist ]; then
			"$PlistBuddy" -c "Set :RunAtLoad false" /Library/LaunchDaemons/com.adobe.agsservice.plist
			chmod 644 /Library/LaunchDaemons/com.adobe.agsservice.plist
		fi
	fi
fi
#Done Disabling Adobe Genuine Software Service

#Hide OTHER account from the Login Window
echo "Hidding OTHER account"
defaults write /Library/Preferences/com.apple.loginwindow SHOWOTHERUSERS_MANAGED -bool false
#Done Hide OTHER account from the Login Window

echo "Cleaning Up [Approximately 1-2mins]"
#find "$HOME" -name "~$"* -depth -exec rm -f {} \;
#dot_clean "$HOME"
rm -Rf /.fseventsd #&>/dev/null
rm -Rf /.Spotlight-V100 #&>/dev/null
rm -Rf /.TemporaryItems #&>/dev/null
rm -Rf /private/var/tmp/* #&>/dev/null
rm -Rf /private/var/log/* #&>/dev/null
rm -Rf /private/var/logs/* #&>/dev/null
rm -Rf /Library/Logs/* #&>/dev/null
rm -Rf "$HOME"/Library/Logs/* #&>/dev/null
rm -f "$HOME"/.bash_history #&>/dev/null
rm -Rf "$HOME"/.bash_sessions #&>/dev/null
rm -f "$HOME"/.zsh_history #&>/dev/null
rm -Rf "$HOME"/.zsh_sessions #&>/dev/null
#rm -Rf "$HOME"/Library/Application\ Support/CloudDocs #&>/dev/null
#Safari
rm -Rf "$HOME"/Library/Caches/com.apple.Safari/* #&>/dev/null
rm -f "$HOME"/Library/Safari/History* #&>/dev/null
rm -f "$HOME"/Library/Safari/LastSession* #&>/dev/null
rm -f "$HOME"/Library/Safari/RecentlyClosedTabs* #&>/dev/null
#Done Safari
#Chrome
rm -Rf "$HOME"/Library/Caches/Google/Chrome/* #&>/dev/null
rm -f "$HOME"/Library/Application\ Support/Google/Chrome/Default/History* #&>/dev/null
#Done Chrome
#Firefox
rm -Rf "$HOME"/Library/Caches/Firefox/Profiles/* #&>/dev/null
rm -f "$HOME"/Library/Application\ Support/Firefox/Profiles/*/places* #&>/dev/null
#Done Firefox
dscacheutil -flushcache #&>/dev/null
killall -HUP mDNSResponder #&>/dev/null
rm -Rf /Volumes/*/.Trashes/* #&>/dev/null
if [ -d /.Trashes ]; then
	rm -Rf /.Trashes/* #&>/dev/null
fi
if [ -d "$HOME"/.Trash ]; then
	rm -Rf "$HOME"/.Trash/* #&>/dev/null
fi
timeout () {
	tput sc
	time=$1; while [ $time -ge 0 ]; do
		tput rc; tput el
		printf "$2" $time
		((time--))
		sleep 1
	done
	tput rc; tput ed;
}
echo
timeout 5 "Done in %s seconds"
echo -e "${BoldON}Please Restart Now${BoldOFF}"
echo

exit 0
