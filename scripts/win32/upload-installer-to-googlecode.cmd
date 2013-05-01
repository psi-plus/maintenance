@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer with 30+ translations || psi-git 01.05.2013 17:15 MSD || Qt 4.8.4 || Win32 OpenSSL Libs v1.0.1e || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.16.116-win32-setup.exe"
@echo Completed
pause & pause
