@echo off
setlocal
set GIT=%GITDIR%\bin\git.exe
@echo Cloning Psi+ Plugins sources
"%GIT%" clone https://github.com/psi-plus/plugins.git
move /Y plugins\generic\attentionplugin psi\build\src\plugins\generic\attentionplugin
move /Y plugins\generic\autoreplyplugin psi\build\src\plugins\generic\autoreplyplugin
move /Y plugins\generic\birthdayreminderplugin psi\build\src\plugins\generic\birthdayreminderplugin
move /Y plugins\generic\captchaformsplugin psi\build\src\plugins\generic\captchaformsplugin
move /Y plugins\generic\chessplugin psi\build\src\plugins\generic\chessplugin
move /Y plugins\generic\cleanerplugin psi\build\src\plugins\generic\cleanerplugin
move /Y plugins\generic\clientswitcherplugin psi\build\src\plugins\generic\clientswitcherplugin
move /Y plugins\generic\conferenceloggerplugin psi\build\src\plugins\generic\conferenceloggerplugin
move /Y plugins\generic\contentdownloaderplugin psi\build\src\plugins\generic\contentdownloaderplugin
move /Y plugins\generic\extendedmenuplugin psi\build\src\plugins\generic\extendedmenuplugin
move /Y plugins\generic\extendedoptionsplugin psi\build\src\plugins\generic\extendedoptionsplugin
move /Y plugins\generic\gmailserviceplugin psi\build\src\plugins\generic\gmailserviceplugin
move /Y plugins\generic\gomokugameplugin psi\build\src\plugins\generic\gomokugameplugin
move /Y plugins\generic\historykeeperplugin psi\build\src\plugins\generic\historykeeperplugin
move /Y plugins\generic\icqdieplugin psi\build\src\plugins\generic\icqdieplugin
move /Y plugins\generic\imageplugin psi\build\src\plugins\generic\imageplugin
move /Y plugins\generic\jabberdiskplugin psi\build\src\plugins\generic\jabberdiskplugin
move /Y plugins\generic\juickplugin psi\build\src\plugins\generic\juickplugin
move /Y plugins\generic\pepchangenotifyplugin psi\build\src\plugins\generic\pepchangenotifyplugin
move /Y plugins\generic\qipxstatusesplugin psi\build\src\plugins\generic\qipxstatusesplugin
move /Y plugins\generic\screenshotplugin psi\build\src\plugins\generic\screenshotplugin
move /Y plugins\generic\skinsplugin psi\build\src\plugins\generic\skinsplugin
move /Y plugins\generic\stopspamplugin psi\build\src\plugins\generic\stopspamplugin
move /Y plugins\generic\storagenotesplugin psi\build\src\plugins\generic\storagenotesplugin
move /Y plugins\generic\translateplugin psi\build\src\plugins\generic\translateplugin
move /Y plugins\generic\watcherplugin psi\build\src\plugins\generic\watcherplugin
rd /S /Q plugins
@echo Completed
@echo Building Psi+ Plugins
cd psi\build\src\plugins\generic\attentionplugin
qmake attentionplugin.pro
mingw32-make -f makefile.release
cd ..\autoreplyplugin
qmake autoreplyplugin.pro
mingw32-make -f makefile.release
cd ..\birthdayreminderplugin
qmake birthdayreminderplugin.pro
mingw32-make -f makefile.release
cd ..\captchaformsplugin
qmake captchaformsplugin.pro
mingw32-make -f makefile.release
cd ..\chessplugin
qmake chessplugin.pro
mingw32-make -f makefile.release
cd ..\cleanerplugin
qmake cleanerplugin.pro
mingw32-make -f makefile.release
cd ..\clientswitcherplugin
qmake clientswitcherplugin.pro
mingw32-make -f makefile.release
cd ..\conferenceloggerplugin
qmake conferenceloggerplugin.pro
mingw32-make -f makefile.release
cd ..\contentdownloaderplugin
qmake contentdownloaderplugin.pro
mingw32-make -f makefile.release
cd ..\extendedmenuplugin
qmake extendedmenuplugin.pro
mingw32-make -f makefile.release
cd ..\extendedoptionsplugin
qmake extendedoptionsplugin.pro
mingw32-make -f makefile.release
cd ..\gmailserviceplugin
qmake gmailserviceplugin.pro
mingw32-make -f makefile.release
cd ..\gomokugameplugin
qmake gomokugameplugin.pro
mingw32-make -f makefile.release
cd ..\historykeeperplugin
qmake historykeeperplugin.pro
mingw32-make -f makefile.release
cd ..\icqdieplugin
qmake icqdieplugin.pro
mingw32-make -f makefile.release
cd ..\imageplugin
qmake imageplugin.pro
mingw32-make -f makefile.release
cd ..\jabberdiskplugin
qmake jabberdiskplugin.pro
mingw32-make -f makefile.release
cd ..\juickplugin
qmake juickplugin.pro
mingw32-make -f makefile.release
cd ..\pepchangenotifyplugin
qmake pepchangenotifyplugin.pro
mingw32-make -f makefile.release
cd ..\qipxstatusesplugin
qmake qipxstatusesplugin.pro
mingw32-make -f makefile.release
cd ..\screenshotplugin
qmake screenshotplugin.pro
mingw32-make -f makefile.release
cd ..\skinsplugin
qmake skinsplugin.pro
mingw32-make -f makefile.release
cd ..\stopspamplugin
qmake stopspamplugin.pro
mingw32-make -f makefile.release
cd ..\storagenotesplugin
qmake storagenotesplugin.pro
mingw32-make -f makefile.release
cd ..\translateplugin
qmake translateplugin.pro
mingw32-make -f makefile.release
cd ..\watcherplugin
qmake watcherplugin.pro
mingw32-make -f makefile.release
cd ..
@echo Completed
pause
@echo Copying Psi+ Plugins to work dir
rd /S /Q "%PSIPLUSDIR%\plugins\changelogs"
mkdir "%PSIPLUSDIR%\plugins\changelogs"
copy attentionplugin\release\attentionplugin.dll "%PSIPLUSDIR%\plugins\attentionplugin.dll" /Y
copy attentionplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\attentionplugin.txt" /Y
copy autoreplyplugin\release\autoreplyplugin.dll "%PSIPLUSDIR%\plugins\autoreplyplugin.dll" /Y
copy autoreplyplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\autoreplyplugin.txt" /Y
copy birthdayreminderplugin\release\birthdayreminderplugin.dll "%PSIPLUSDIR%\plugins\birthdayreminderplugin.dll" /Y
copy birthdayreminderplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\birthdayreminderplugin.txt" /Y
copy captchaformsplugin\release\captchaformsplugin.dll "%PSIPLUSDIR%\plugins\captchaformsplugin.dll" /Y
copy captchaformsplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\captchaformsplugin.txt" /Y
copy chessplugin\release\chessplugin.dll "%PSIPLUSDIR%\plugins\chessplugin.dll" /Y
copy chessplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\chessplugin.txt" /Y
copy cleanerplugin\release\cleanerplugin.dll "%PSIPLUSDIR%\plugins\cleanerplugin.dll" /Y
copy cleanerplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\cleanerplugin.txt" /Y
copy clientswitcherplugin\release\clientswitcherplugin.dll "%PSIPLUSDIR%\plugins\clientswitcherplugin.dll" /Y
copy clientswitcherplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\clientswitcherplugin.txt" /Y
copy conferenceloggerplugin\release\conferenceloggerplugin.dll "%PSIPLUSDIR%\plugins\conferenceloggerplugin.dll" /Y
copy conferenceloggerplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\conferenceloggerplugin.txt" /Y
copy contentdownloaderplugin\release\contentdownloaderplugin.dll "%PSIPLUSDIR%\plugins\contentdownloaderplugin.dll" /Y
copy contentdownloaderplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\contentdownloaderplugin.txt" /Y
copy extendedmenuplugin\release\extendedmenuplugin.dll "%PSIPLUSDIR%\plugins\extendedmenuplugin.dll" /Y
copy extendedmenuplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\extendedmenuplugin.txt" /Y
copy extendedoptionsplugin\release\extendedoptionsplugin.dll "%PSIPLUSDIR%\plugins\extendedoptionsplugin.dll" /Y
copy extendedoptionsplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\extendedoptionsplugin.txt" /Y
copy gmailserviceplugin\release\gmailserviceplugin.dll "%PSIPLUSDIR%\plugins\gmailserviceplugin.dll" /Y
copy gmailserviceplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\gmailserviceplugin.txt" /Y
copy gomokugameplugin\release\gomokugameplugin.dll "%PSIPLUSDIR%\plugins\gomokugameplugin.dll" /Y
copy gomokugameplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\gomokugameplugin.txt" /Y
copy historykeeperplugin\release\historykeeperplugin.dll "%PSIPLUSDIR%\plugins\historykeeperplugin.dll" /Y
copy historykeeperplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\historykeeperplugin.txt" /Y
copy icqdieplugin\release\icqdieplugin.dll "%PSIPLUSDIR%\plugins\icqdieplugin.dll" /Y
copy icqdieplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\icqdieplugin.txt" /Y
copy imageplugin\release\imageplugin.dll "%PSIPLUSDIR%\plugins\imageplugin.dll" /Y
copy imageplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\imageplugin.txt" /Y
copy jabberdiskplugin\release\jabberdiskplugin.dll "%PSIPLUSDIR%\plugins\jabberdiskplugin.dll" /Y
copy jabberdiskplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\jabberdiskplugin.txt" /Y
copy juickplugin\release\juickplugin.dll "%PSIPLUSDIR%\plugins\juickplugin.dll" /Y
copy juickplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\juickplugin.txt" /Y
copy pepchangenotifyplugin\release\pepchangenotifyplugin.dll "%PSIPLUSDIR%\plugins\pepchangenotifyplugin.dll" /Y
copy pepchangenotifyplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\pepchangenotifyplugin.txt" /Y
copy qipxstatusesplugin\release\qipxstatusesplugin.dll "%PSIPLUSDIR%\plugins\qipxstatusesplugin.dll" /Y
copy qipxstatusesplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\qipxstatusesplugin.txt" /Y
copy screenshotplugin\release\screenshotplugin.dll "%PSIPLUSDIR%\plugins\screenshotplugin.dll" /Y
copy screenshotplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\screenshotplugin.txt" /Y
copy skinsplugin\release\skinsplugin.dll "%PSIPLUSDIR%\plugins\skinsplugin.dll" /Y
copy skinsplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\skinsplugin.txt" /Y
copy stopspamplugin\release\stopspamplugin.dll "%PSIPLUSDIR%\plugins\stopspamplugin.dll" /Y
copy stopspamplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\stopspamplugin.txt" /Y
copy storagenotesplugin\release\storagenotesplugin.dll "%PSIPLUSDIR%\plugins\storagenotesplugin.dll" /Y
copy storagenotesplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\storagenotesplugin.txt" /Y
copy translateplugin\release\translateplugin.dll "%PSIPLUSDIR%\plugins\translateplugin.dll" /Y
copy translateplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\translateplugin.txt" /Y
copy watcherplugin\release\watcherplugin.dll "%PSIPLUSDIR%\plugins\watcherplugin.dll" /Y
copy watcherplugin\changelog.txt "%PSIPLUSDIR%\plugins\changelogs\watcherplugin.txt" /Y
@echo Archiving Psi+ Plugins
call 7z a -mx9 "%PSIPLUSDIR%\plugins\psi-plus-plugins-0.15.5045-win32.7z" "%PSIPLUSDIR%\plugins\changelogs" "%PSIPLUSDIR%\plugins\*.dll"
@echo Completed
@echo Uploading archived Psi+ Plugins to Google Code
call ..\..\..\..\..\googlecode_upload.py -p "psi-dev" -s "Psi+ Plugins || Qt 4.7.2" -l "Plugins,Windows,Archive" "%PSIPLUSDIR%\plugins\psi-plus-plugins-0.15.5045-win32.7z"
@echo Completed
pause & pause
