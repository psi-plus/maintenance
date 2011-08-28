@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer || psi-git 21.08.2011 17:14 MSD || Qt 4.7.2 || Win32 OpenSSL Libs v0.9.8r || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.15.5091-win32-setup.exe"
@echo Completed
pause & pause
