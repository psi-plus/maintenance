@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer || psi-git 02.10.2011 14:59 MSD || Qt 4.7.4 || Win32 OpenSSL Libs v1.0.0e || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.15.5122-win32-setup.exe"
@echo Completed
pause & pause
