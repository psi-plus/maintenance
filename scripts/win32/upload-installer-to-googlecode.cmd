@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer with 30+ translations || psi-git 22.05.2012 14:29 MSD || Qt 4.8.1 || Win32 OpenSSL Libs v1.0.1 || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.15.5337-win32-setup.exe"
@echo Completed
pause & pause
