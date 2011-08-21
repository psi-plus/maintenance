@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer || psi-git 28.08.2011 16:01 MSD || Qt 4.7.2 || Win32 OpenSSL Libs v0.9.8r || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.15.5106-win32-setup.exe"
@echo Completed
pause & pause
