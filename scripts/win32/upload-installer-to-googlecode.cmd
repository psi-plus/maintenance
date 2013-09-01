@echo off
@echo Uploading Psi+ Installer to Google Code
call autobuild\googlecode_upload.py -p "psi-dev" -s "Psi+ Windows Installer with 30+ translations || Based on https://github.com/psi-im at 01.09.2013 16:54 MSD || Qt 4.8.5 || Win32 OpenSSL Libs v1.0.1e || Psimedia/GStreamer included" -l "Featured,Windows,Installer" "setup\psi-plus-0.16.204-win32-setup.exe"
@echo Completed
pause & pause
