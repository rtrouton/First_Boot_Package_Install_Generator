First Boot Package Install Generator.app
============================

**OS Compatibility:**

**First Boot Package Install Generator.app** has been tested and verified to run on the following versions of OS X:

**10.8.x**

**10.9.x**

**10.10.x**


**First Boot Package Install Generator.app** has been tested and verified that it does not run on the following version of OS X:

**10.7.x**


Not tested:

**10.6.x or earlier**

============================

***Preparing installers for use with First Boot Package Install Generator.app***

1: Set up a folder to hold your installers.   

**NOTE:** *createOSXinstallPkg has an upper limit of 350 MBs of available space for added packages. This is sufficient space for basic configuration, payload-free or bootstrapping packages, but it’s not a good idea to add Microsoft Office or similar large installers to this installer.*

2: Create numbered directories inside that folder, with **00** being the first and proceeding on to as many as you need. For numbers less than 10, make sure to label the directory with a leading zero (For example, **06**).

3: Add one installer package to each numbered directory. The number of the directory indicates the install order, with **00** being the first.   

**Note:** *If installing more than 100 packages, be aware that this was beyond the scope of my testing. I recommend adding another leading zero where appropriate.*

4: Once finished adding installers to the numbered directories, see the ***Using First Boot Package Install Generator.app*** section.

***Using First Boot Package Install Generator.app***

1. If needed, download the **First_Boot_Package_Install_Generator.zip** file from the **installer** directory in this GitHub repo and install the application on your Mac.

2. Once downloaded and installed, double-click on the **First Boot Package Install Generator** application.

3. You'll be prompted to select the directory that contains the installers you want to have installed at first boot.

4. Once you've selected the folder with your installers, you'll be prompted to name the installer package. By default, the name filled in will be **First Boot Package Install**, but this name can be changed as desired.

5. Once you've entered a name for the installer package, you'll be prompted for a package identifier. By default, the name filled in will be **com.github.first_boot**, but this name should be changed to be something unique.

6. Once you've entered an identifier for the installer package, you'll be prompted for a version number. By default, the value filled in will be **1.0**, but this value can be changed as needed.

7. You will be prompted to choose if you want to have all available Apple software updates applied before your packages are installed. Choose **Yes** or **No** as appropriate. 


Once the package name, package identifier, package version and software update choice have been set, **First Boot Package Install Generator.app** will prompt for an administrator's username and password.

9. Once the admin username and password are provided, **First Boot Package Install Generator.app** will create the installer package and prompt you when it's finished.

10. Click **OK** at the prompt and a new Finder window will open and display the newly-created first boot installer package.

11. **First Boot Package Install Generator.app** will automatically exit.





***How First Boot Package Install Generator.app works***


**First Boot Package Install Generator.app** is an Automator application that uses AppleScript, shell scripting,  **pkgbuild** and **productbuild** behind the scenes to create payload-free packages. When a script is selected, the following process takes place:

1. The directory with the user-selected packages is copied to **/tmp** as a zip archive named **fb_installers**, to give the package-building script a consistent value to work with.

2. After the package name, package identifier and package version are set, **/tmp** is checked to make sure that there is not an existing directory that is named the same as the chosen name. If a matching directory is found, it is removed.

3. A new directory is created in **/tmp** that matches the chosen name of the package. This directory will be used for building the first boot package.

4. Next, the **installer_build_components.tgz** and **xmlstarlet.tgz** tar files are copied into **/tmp** from the Contents/Resources directory inside **First Boot Package Install Generator.app** and then un-tar'd into the build directory inside **/tmp**.

5. Using the choice of whether to run Apple software updates or not, the appropriate script is moved into the build directory and renamed **firstbootpackageinstall.sh**.

6. The **fb_installers** directory with the user-selected packages is moved into the correct location in the build directory for inclusion in the package when it's created.

7. The new first installer package is built first as a component flat package by **pkgbuild**.

8. A new distribution XML file is synthesized using productbuild for the first boot component package.

9. **xmlstarlet** is used to add a title field to the distribution XML file.

10. The component package is converted to a distribution-style flat package using **productbuild** and the edited distribution XML file

11. The **installer_build_components.tgz** and **xmlstarlet.tgz** tar files are removed from **/tmp**.

12. The finished installer package is stored in **/tmp/package_name_here** and the user is prompted that the process is finished.

13. Once the user is notified and clicks OK, a new Finder window opens for **/tmp/package_name_here**. The package is ready to be added to a **createOSXinstallPkg**-built OS installer.

***How First Boot Package Install Generator.app-generated installer packages work***
 

When the First Boot Package Install Generator.app-generated installer package is installed via **createOSXinstallPkg**, it does the following:

1. Installs the folder containing the user-selected installers to **/var/fb_installers**.

2. Installs **/Library/LaunchDaemons/com.company.firstbootpackageinstall.plist**

3. Installs **/var/firstbootpackageinstall.sh**.
4.  Installs **/Library/LaunchAgents/com.company.LoginLog.plist**

5. Installs **/Library/PrivilegedHelperTools/LoginLog.app**

 

After OS X is installed by createOSXinstallPkg and reboots, the following process occurs:

1. The **com.company.firstbootpackageinstall** LaunchDaemon triggers **/var/firstbootpackageinstall.sh **to run.

2. **/var/firstbootpackageinstall.sh** stops the login window from loading and checks for the existence of /var/fb_installers.

 

If /var/fb_installers is not found, the following actions take place:

A. The login window is allowed to load

B. **/Library/LaunchDaemons/com.company.firstbootpackageinstall.plist** is deleted

C. **/var/firstbootpackageinstall.sh** is deleted

D. **/Library/LaunchAgents/com.company.LoginLog.plist** is deleted

E. **/Library/PrivilegedHelperTools/LoginLog.app** is deleted.

F. **/var/firstbootpackageinstall.sh** checks for an existing **/var/log/firstbootpackageinstall.log** logfile and renames the existing logfile to include the current date and time.

G. **/var/firstbootpackageinstall.sh** deletes itself.

 

If **/var/fb_installers** is present, the following actions take place:

A: If **/var/fb_installers** exists, the login window is allowed to load

B: A log is created to record the actions taken by **/var/firstbootpackageinstall.sh**. By default, this logfile named **firstbootpackageinstall.log** and is stored in **/var/log**.

C: **/Library/LaunchAgents/com.company.LoginLog.plist** loads and launches /Library/PrivilegedHelperTools/LoginLog.app

D: **/Library/PrivilegedHelperTools/LoginLog.app** opens a window over the Mac's login window and displays the logfile.

E: A network check is run, to ensure that the Mac has a network address other than 127.0.0.1 or 0.0.0.0 (which are otherwise known as loopback addresses.) This network check will check every five seconds for the next 60 minutes for a working network connection. 

Network check fails - If only loopback addresses are detected within 60 minutes, the script will take the following actions:

1. Log a failure message to the log  

2. Delete **/var/fb_installers**  

3. Restart.  

4. On restart, the "if **/var/fb_installers** is not found" actions occur.

Network check succeeds - If a non-loopback address is detected, the script will take the following actions:

1. Log a success message to the log and proceed with the rest of the script.

F: If the option to install Apple software updates was selected, all available Apple software updates are downloaded and installed prior to installing the user-selected packages.

G: The user-selected packages are installed, using the numbered subdirectories to set the order of installation

H: Once installation has finished, **/var/fb_installers** is deleted

I: The Mac is restarted

J: On restart, the “**if /var/fb_installers is not found**” actions occur and all remaining traces of the first boot package are removed from the Mac.
