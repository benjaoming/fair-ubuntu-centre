# TODO

- Remember to make the database in KA Lite writable

Updated 2015-02-22

 - Ensure that error message is understandable when no drive detected
 - Ensure that running ./install.sh again does not corrupt fstab
 - Everything should be modular and dynamic such that data sources can be added and removed on the go and without any system administration.
 - Do not fail when folders are missing, just give a warning.
 - Make passwords configurable
 - The "postinstall" section has a "filesystem" part that is easily confused with the "filesystem" part in
   configurations, which more intuitively refers to a folder structure that should be copied into '/' on
   the target machine.
 - Technicians log added to local servers
 - Machine ID as part of installation (upstart prompt), ask only first time and save in file, see: http://askubuntu.com/a/172729/38291
 - Log login/logout on local machine, server should rsync log files
