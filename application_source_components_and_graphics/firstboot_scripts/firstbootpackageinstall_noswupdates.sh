#!/bin/bash

install_dir=/var/fb_installers
log_location="/var/log/firstbootpackageinstall.log"
archive_log_location="/var/log/firstbootpackageinstall-`date +%Y-%m-%d-%H-%M-%S`.log"
LoginLogLaunchAgent="/Library/LaunchAgents/com.company.LoginLog.plist"
LoginLogApp="/Library/PrivilegedHelperTools/LoginLog.app"

# Function to check to see if /var/db/.AppleSetupDone is present
# If it is not, add it and /var/db/.firstboot.delete.AppleSetupDone 
# and reboot. 
#
# /var/db/.firstboot.delete.AppleSetupDone is added to provide 
# verification that this script added /var/db/.AppleSetupDone to
# suppress the Apple Setup Assistant, which in turn allows the LoginLog 
# application to launch and display the log.

AddAppleSetupDone(){

    if [[ ! -e /var/db/.AppleSetupDone ]]; then
        /usr/bin/touch /var/db/.AppleSetupDone
        /usr/bin/touch /var/db/.firstboot.delete.AppleSetupDone
        
        # After adding /var/db/.AppleSetupDone 
        # and /var/db/.firstboot.delete.AppleSetupDone, 
        # restart the Mac.
        
        /sbin/reboot
    fi
}

# Function to provide logging of the script's actions to
# the log file defined by the log_location variable

ScriptLogging(){

    DATE=`date +%Y-%m-%d\ %H:%M:%S`
    LOG="$log_location"
    
    echo "$DATE" " $1" >> $LOG
}

# Function that determines if the network is up by 
# looking for any non-loopback network interfaces.

CheckForNetwork(){

    local test
    
    if [[ -z "${NETWORKUP:=}" ]]; then
        test=$(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l)
        if [[ "${test}" -gt 0 ]]; then
            NETWORKUP="-YES-"
        else
            NETWORKUP="-NO-"
        fi
    fi
}

# Create the log file at the location defined by the
# log_location variable.

/usr/bin/touch "$log_location"

# Delay the login window by unloading the com.apple.loginwindow
# LaunchDaemon in /System/Library/LaunchDaemons/

/bin/launchctl unload /System/Library/LaunchDaemons/com.apple.loginwindow.plist

#
# If the installers directory is not found, the
# com.apple.loginwindow LaunchDaemon is loaded and
# this script and associated parts self-destruct
#

if [[ ! -d "$install_dir" ]]; then
 ScriptLogging "Firstboot installer directory not present. Cleaning up."
 /bin/launchctl unload -S loginwindow $LoginLogLaunchAgent
 /bin/rm $LoginLogLaunchAgent
 /bin/rm -rf $LoginLogApp
 /bin/launchctl load /System/Library/LaunchDaemons/com.apple.loginwindow.plist
 /bin/rm -rf /Library/LaunchDaemons/com.company.firstbootpackageinstall.plist

  # Rename logfile so that a
  # fresh log is generated for
  # each run.
 if [[ -f "$log_location" ]]; then
    /bin/mv $log_location $archive_log_location
 fi
 /bin/rm $0
fi

#
# If the installers directory is found, the
# script installs the packages found in 
# the subdirectories, using the numbered
# subdirectories to set the order of
# installation.
#

if [[ -d "$install_dir" ]]; then

 # Add /var/db/.AppleSetupDone on an as-needed basis. 
 # See the AddAppleSetupDone function for more information.

 AddAppleSetupDone

 /bin/launchctl load /System/Library/LaunchDaemons/com.apple.loginwindow.plist

# Wait up to 60 minutes for a network connection to become 
# available which doesn't use a loopback address. This 
# condition which may occur if this script is run by a 
# LaunchDaemon at boot time.
#
# The network connection check will occur every 5 seconds
# until the 60 minute limit is reached.

# Detect unregistered network services prior
# to beginning the network connection check

  /usr/sbin/networksetup -detectnewhardware

  ScriptLogging "Checking for active network connection."
  ScriptLogging "========================================="
  ScriptLogging "This check will automatically run every five"
  ScriptLogging "seconds until an active network connection is" 
  ScriptLogging "detected or until sixty minutes have passed."
  ScriptLogging "========================================="
  CheckForNetwork
  i=1
  while [[ "${NETWORKUP}" != "-YES-" ]] && [[ $i -ne 720 ]]
    do
      /bin/sleep 5
      NETWORKUP=
      CheckForNetwork
      echo $i
      i=$(( $i + 1 ))
    done

  if [[ "${NETWORKUP}" != "-YES-" ]]; then
   ScriptLogging "Network connection appears to be offline."
   ScriptLogging "Removing $install_dir from this Mac and restarting."
   /bin/rm -rf $install_dir

   # Sleeping for 10 seconds to allow folks to read the last message
  
   /bin/sleep 10
   /sbin/reboot
  fi
  
  if [[ "${NETWORKUP}" == "-YES-" ]]; then
   ScriptLogging "Active network connection detected. Proceeding."
  fi

 ScriptLogging "$install_dir present on Mac"

  # Check to see if both /var/db/.AppleSetupDone and /var/db/.firstboot.delete.AppleSetupDone
  # are present. If both files are present, remove them because this script added them to suppress
  # the Apple Setup Assistant, which in turn allows the LoginLog application to launch and display the log.
  # 
  # The reason to remove them is that these files are no longer needed past this point in the 
  # script's execution and may interfere with an otherwise desired launch of the Apple Setup
  # Assistant.
  
  if [[ -e /var/db/.firstboot.delete.AppleSetupDone ]] && [[ -e /var/db/.AppleSetupDone ]]; then
       /bin/rm /var/db/.AppleSetupDone
       /bin/rm /var/db/.firstboot.delete.AppleSetupDone       
  fi

  # Installing the packages found in 
  # the installers directory using
  # an array

  # Save current IFS state

   OLDIFS=$IFS

  # Change IFS to
  # create newline

   IFS=$'\n'
 
  # read all installer names into an array

  install=($(/usr/bin/find -s "$install_dir" -maxdepth 2 \( -iname \*\.pkg -o -iname \*\.mpkg \)))
 
  # restore IFS to previous state

  IFS=$OLDIFS
 
  # Get length of the array

  tLen=${#install[@]}
 
  # Use for loop to read all filenames
  # and install the corresponding installer
  # packages
  
  ScriptLogging "Found ${tLen} packages to install."
  ScriptLogging "Please be patient. This process may take a while to complete."
  ScriptLogging "Once all installations are finished, this machine will automatically reboot."
  
  for (( i=0; i<${tLen}; i++ ));
  do
     /bin/echo "`date +%Y-%m-%d\ %H:%M:%S`  Installing "${install[$i]}" on this Mac." >> $log_location
     /usr/sbin/installer -dumplog -verbose -pkg "${install[$i]}" -target /

	# Check for installation success. If an installation did not return
	# an exit status of 0, add a note to the log that the installation
	# had problems and should be checked.
     
	if [ $? != "0" ]
	then
        INSTALLRESULT="FAILURE: "${install[$i]}" did not install correctly."
    else
        INSTALLRESULT="SUCCESS: "${install[$i]}" has been successfully installed."
	fi
     
     /bin/echo "`date +%Y-%m-%d\ %H:%M:%S`  $INSTALLRESULT" >> $log_location
  done

  # Remove the installers
   ScriptLogging "Finished with all installations."
   ScriptLogging "If any installations were reported as not installing correctly,"
   ScriptLogging "please check /var/log/install.log on this Mac for details."
   ScriptLogging "Removing $install_dir from this Mac."
   /bin/rm -rf $install_dir

  # Check to see if /var/db/.AppleSetupDone is present
  # after all the packages have been installed. 
  #
  # If /var/db/.AppleSetupDone is not present, display a message 
  # that the Apple Setup Assistant will appear at the next reboot.
  #
  # If /var/db/.AppleSetupDone is present, display a message that
  # the Apple Setup Assistant has been suppressed and will not
  # appear after the next reboot.
  
  if [[ ! -f /var/db/.AppleSetupDone ]]; then
       ScriptLogging "The Apple Setup Assistant will appear after the Mac reboots."
  elif [[ -f /var/db/.AppleSetupDone ]]; then
      ScriptLogging "The Apple Setup Assistant is set to be skipped."
      ScriptLogging "The Apple Setup Assistant will not appear after the Mac reboots."
  fi
   
  # To accomodate packages needing 
  # a restart, the Mac is restarted
  # at this point.

  ScriptLogging "Restarting Mac."  
  
  # Sleeping for 10 seconds to allow folks to read
  # the last message
  
  /bin/sleep 10

  # Restart

  /sbin/reboot

fi
