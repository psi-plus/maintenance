@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer || psi-git 25.02.2012 18:21 MSD || Qt 4.8.0 || Win32 OpenSSL Libs v1.0.0g || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.15.5225-win32-setup.exe"
@echo Completed
pause & pause
