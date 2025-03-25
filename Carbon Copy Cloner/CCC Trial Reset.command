#!/bin/bash
clear

export LC_ALL=C
echo Carbon Copy Cloner Trial Reset
echo ==================================
echo

if [ $EUID != 0 ]; then
	sudo "$0" "$@"
	exit $?
fi

killall "CCC User Agent" &>/dev/null
killall com.bombich.ccchelper &>/dev/null
defaults delete com.bombich.ccc TrialExpirationV4 &>/dev/null
defaults delete com.bombich.ccc TrialExpirationV5 &>/dev/null
defaults delete com.bombich.ccc TrialExpirationV6 &>/dev/null
defaults delete com.bombich.ccc RegistrationName &>/dev/null
defaults delete com.bombich.ccc SULastCheckTime &>/dev/null
defaults delete com.bombich.ccc TrialStartDateV4 &>/dev/null
defaults delete com.bombich.ccc TrialStartDateV5 &>/dev/null
defaults delete com.bombich.ccc TrialStartDateV6 &>/dev/null
defaults delete com.bombich.ccc paid &>/dev/null
rm -Rf "$HOME"/Library/Application\ Support/com.bombich.ccc
rm -f /Library/PrivilegedHelperTools/com.bombich.ccchelper
rm -Rf /Library/Application\ Support/com.bombich.ccc

echo Done!
echo

exit 0
