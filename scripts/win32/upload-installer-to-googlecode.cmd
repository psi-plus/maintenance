@echo off
@echo Uploading Psi+ Installer to Google Code
rem call googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer with 30+ translations || OTR Plugin included || Based on https://github.com/psi-im at 24.11.2013 15:03 MSD || Qt 4.8.5 || Win32 OpenSSL Libs v1.0.1e || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.16.261-win32-setup.exe"
CALL googlecode_upload.py ^
--user *********** ^
--password ************ ^
--project psi-dev ^
--summary "Psi+ Windows Installer with 30+ translations || OTR Plugin included || Based on https://github.com/psi-im at 24.11.2013 15:03 MSD || Qt 4.8.5 || Win32 OpenSSL Libs v1.0.1e || Psimedia/GStreamer included" ^
--labels "Featured,Windows,Installer" ^
"setup\psi-plus-0.16.261-win32-setup.exe"
@echo Completed
pause & pause
