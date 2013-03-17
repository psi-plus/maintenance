@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer with 30+ translations || psi-git 17.03.2013 18:19 MSD || Qt 4.8.4 || Win32 OpenSSL Libs v1.0.1e || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.16.105-win32-setup.exe"
@echo Completed
pause & pause
