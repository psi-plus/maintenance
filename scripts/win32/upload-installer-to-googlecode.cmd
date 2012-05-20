@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer || psi-git 20.05.2012 19:38 MSD || Qt 4.8.1 || Win32 OpenSSL Libs v1.0.1 || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.15.5335-win32-setup.exe"
@echo Completed
pause & pause
