@echo off
setlocal
set GIT=%GITDIR%\bin\git.exe
set LRELEASE=%QTDIR%\bin\lrelease.exe
@echo Cloning Psi+ Russian localization sources from official repository
%GIT% clone --recursive https://github.com/ivan101/psi-plus-ru.git
rem pause
%LRELEASE% psi-plus-ru\psi_ru.ts
%LRELEASE% psi-plus-ru\qt\qt_ru.ts
move /Y psi-plus-ru\psi_ru.qm "%PSIPLUSDIR%\psi_ru.qm"
move /Y psi-plus-ru\qt\qt_ru.qm "%PSIPLUSDIR%\qt_ru.qm"
rem pause
@echo Archiving Psi+ Russian localization binaries
call 7z a -mx9 "%PSIPLUSDIR%\psi-ru-lang-2011-12-26.7z" "%PSIPLUSDIR%\psi_ru.qm" "%PSIPLUSDIR%\qt_ru.qm"
@echo Completed
@echo Uploading archived Psi+ Russian localization binaries to Google Code
call googlecode_upload.py -p "psi-dev" -s "Psi+ Russian Localization || Qt 4.7.4" -l "Russian,Localization,Archive" "%PSIPLUSDIR%\psi-ru-lang-2011-12-26.7z"
@echo Completed
pause & pause
