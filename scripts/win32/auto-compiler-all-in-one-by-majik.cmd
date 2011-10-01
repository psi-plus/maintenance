REM auto-compiler-all-in-one-by-majik.cmd
REM http://psi-dev.googlecode.com/
REM Psi+ auto compiler 'all-in-one' script, v0.1.0
REM Written by majik <maj@jabber.ru>
REM Optimized by zet <mailto:vladimir.shelukhin@gmail.com>
REM Date: 2011-10-01
REM -----------------------------------------------------------------------------------------

@ECHO OFF
setlocal
set GIT=%GITDIR%\bin\git.exe
set TR=%GITDIR%\bin\tr.exe
set SED=%GITDIR%\bin\sed.exe
set PATCH=%GITDIR%\bin\patch.exe
set QMAKE=%QTDIR%\bin\qmake.exe

REM Please configure script before use
REM Description:
REM 1 = yes, 0 = no (if you aren't member of Psi+ Project you should use 0 for Upload fields)
REM vOpenSSL = Need only for members of Psi+ Project. Version of your libraries of OpenSSL
REM GoogleUser = Need only for members of Psi+ Project. Your Google account name
REM GooglePass = Need only for members of Psi+ Project. The googlecode.com password for your account
REM (Note that this is NOT your global Google Account password!) See at https://code.google.com/hosting/settings
SET MakeClassic=1
SET UploadClassic=0
SET MakeClassicDebug=0
SET UploadClassicDebug=0
SET MakeWebkit=0
SET UploadWebkit=0
SET MakeWebkitDebug=0
SET UploadWebkitDebug=0
SET MakePlugins=1
SET UploadPlugins=0
SET MakePluginsDebug=0
SET UploadPluginsDebug=0
SET vOpenSSL=1.0.0e
SET GoogleUser=yourlogin
SET GooglePass=yourpass
REM End of configuring, now you can try using script

REM Check compiling
IF EXIST vPsiPlusNew ECHO Likely last compilation process is not yet completed & EXIT
IF EXIST vPluginsNew ECHO Likely last compilation process is not yet completed & EXIT
SET Update=0

REM Set current time
ECHO SET currentTime=>currentTime
TIME /T>>currentTime
%TR% -d \n\r<currentTime>currentTime.cmd
CALL currentTime.cmd & DEL currentTime & DEL currentTime.cmd
ECHO Set current time to %currentTime%
ECHO ========================>> logs.txt
ECHO %DATE% %TIME%>> logs.txt

REM Check/clone Psi sources
ECHO Check Psi sources
ECHO :checking psi sources>> logs.txt
IF NOT EXIST psi (
	ECHO Psi sources not found
	ECHO Cloning Psi sources from official repository
	ECHO :cloning psi sources>> logs.txt
	%GIT% clone --recursive https://github.com/psi-im/psi.git
	IF ERRORLEVEL 1 ECHO Unable to clone & ECHO !clonning fail>> logs.txt & RMDIR psi /S /Q & GOTO :exit
	) ELSE (
	ECHO Found Psi sources
	)

REM Check/clone Psi+ sources
ECHO Check Psi+ sources
ECHO :checking psiplus sources>> logs.txt
IF NOT EXIST PsiPlus (
	ECHO Psi+ sources not found
	ECHO Cloning Psi+ sources
	ECHO :cloning psiplus sources>> logs.txt
	%GIT% clone https://github.com/psi-plus/main.git PsiPlus
	IF ERRORLEVEL 1 ECHO Unable to cloning psiplus sources & ECHO !cloning psiplus sources fail>> logs.txt & RMDIR PsiPlus /S /Q & GOTO :exit
	CD PsiPlus
	%GIT% clone https://github.com/psi-plus/plugins.git
	IF ERRORLEVEL 1 CD .. & ECHO Unable to cloning plugins sources & ECHO !cloning plugins sources fail>> logs.txt & RMDIR PsiPlus /S /Q & GOTO :exit
	SET Update=1
	FOR /f "tokens=2 delims=-" %%x IN ('%GIT% describe --tags') DO ECHO %%x > ..\vPsiPlusNew
	CD plugins
	FOR /f "tokens=1 delims=-" %%x IN ('%GIT% describe --tags') DO ECHO %%x > ..\..\vPluginsNew
	CD ..\..
	) ELSE (
	ECHO Found Psi+ sources
	)

REM Checking for first start
IF %Update%==1 GOTO :preparing_and_patching

REM Updating Psi sources
ECHO Updating Psi and Submodules
ECHO :updating psi sources>> logs.txt
CD psi
%GIT% pull
IF ERRORLEVEL 1 ECHO Unable to update & ECHO !Psi updating fail>> ..\logs.txt & GOTO :exit
%GIT% submodule update
IF ERRORLEVEL 1 ECHO Unable to update & ECHO !submodules updating fail>> ..\logs.txt & GOTO :exit
CD ..
	
REM Updating PsiPlus sources
ECHO Updating PsiPlus sources
ECHO :updating psiplus sources>> logs.txt
CD PsiPlus
%GIT% pull
IF ERRORLEVEL 1 ECHO Psi+ updating fail & ECHO !Psi+ updating fail>> ..\logs.txt & GOTO :EXIT
CD plugins
%GIT% pull
IF ERRORLEVEL 1 ECHO Plugins updating fail & ECHO !Psi+ updating fail>> ..\..\logs.txt & CD .. & GOTO :EXIT
CD ..
FOR /f "tokens=2 delims=-" %%x IN ('%GIT% describe --tags') DO ECHO %%x > ..\vPsiPlusNew
CD plugins
FOR /f "tokens=2 delims=-" %%x IN ('%GIT% describe --tags') DO ECHO %%x > ..\..\vPluginsNew
CD ..\..

REM Checking updates
ECHO Checking updates
ECHO :checking updates>> logs.txt
SET Update=0
ECHO N | COMP vPsiPlusOld vPsiPlusNew
IF ERRORLEVEL 1 (
	ECHO Found updates for Psi+ & ECHO :found updates for psiplus>> logs.txt & SET Update=1 & SET PsiPlusUpdate=1
	) ELSE (
	ECHO Updates for Psi+ not found & :updates for psiplus not found>> logs.txt
	SET PsiPlusUpdate=0
	SET MakeWebkit=0
	SET UploadWebkit=0
	SET MakeWebkitDebug=0
	SET UploadWebkitDebug=0
	SET MakeClassic=0
	SET UploadClassic=0
	SET MakeClassicDebug=0
	SET UploadClassicDebug=0
	)
ECHO N | COMP vPluginsOld vPluginsNew
IF ERRORLEVEL 1 (
	ECHO Found updates for psiplus plugins & ECHO :found updates for psiplus plugins>> logs.txt & SET Update=1 & SET PluginsUpdate=1
	) ELSE (
	ECHO Updates for psiplus plugins not found
	SET PluginsUpdate=0
	SET MakePlugins=0
	SET UploadPlugins=0
	SET MakePluginsDebug=0
	SET UploadPluginsDebug=0
	)

REM Preparing and patching
:preparing_and_patching
	FOR /f "tokens=4 delims=: " %%x IN ('%QMAKE% -v ^| findstr /C:"Using Qt version "') DO SET vQt=%%x
	CD PsiPlus
	FOR /f "tokens=1 delims=-" %%x IN ('%GIT% describe --tags') DO SET vPsiPlusMajor=%%x
	FOR /f "tokens=2 delims=-" %%x IN ('%GIT% describe --tags') DO SET /A vPsiPlusMinor=%%x+5000
	CD plugins
	FOR /f "tokens=2 delims=-" %%x IN ('%GIT% describe --tags') DO SET vPlugins=%vPsiPlusMinor%.%%x
	CD ..\..
	REM For plugins
	SET patchdir=patches\
	SET pluginsBinDir=%CD%\plugins
	SET pluginsSrcDir=%CD%\PsiPlusWorkdir\src\plugins\generic
IF %Update%==1 (
	REM Preparing to patching
	ECHO Preparing to patching
	ECHO :preparing to patching>> logs.txt
	IF EXIST PsiPlusWorkdir RMDIR PsiPlusWorkdir /S /Q
	ECHO D | xcopy psi PsiPlusWorkdir /E /Y /Q
	ECHO D | xcopy PsiPlus\patches PsiPlusWorkdir\patches /E /Y /Q
	REM Patching Psi to Psi+
	ECHO Patching Psi to Psi+
	ECHO :patching psi to psiplus r.%vPsiPlusMinor%>> logs.txt
	ECHO D | XCOPY PsiPlus\iconsets\system\default PsiPlusWorkdir\iconsets\system\default /E /Y /Q
	ECHO D | XCOPY PsiPlus\iconsets\roster\default PsiPlusWorkdir\iconsets\roster\default /E /Y /Q
	CD PsiPlusWorkdir
	COPY /Y ..\PsiPlus\app.ico win32\app.ico
	REN iris\conf_win.pri.example conf_win.pri
	MOVE /Y patches\9999-psiplus-application-info.diff 9999-psiplus-application-info.diff
	%SED% "s/\(xxx\)/%vPsiPlusMinor%/" "9999-psiplus-application-info.diff">patches\9999-psiplus-application-info.diff
	DIR /B %patchdir%*.diff | SORT > series.txt
	FOR /F %%v IN (series.txt) DO %PATCH% -p1 -r rejects < %patchdir%%%v
	DEL series.txt
	CD ..
	RMDIR /S /Q PsiPlusWorkdir\src\plugins\generic
	ECHO D | XCOPY PsiPlus\plugins\generic PsiPlusWorkdir\src\plugins\generic /E /Y /Q
	DIR %pluginsSrcDir% /AD /B > %pluginsSrcDir%\plugins.txt
	) ELSE (
	ECHO Newest versions of Psi+ or plugins don't detected & ECHO :no changes>> logs.txt & GOTO :exit
	)

REM Checking rejects
ECHO Checking rejects
ECHO :checking rejects>> logs.txt
IF EXIST PsiPlusWorkdir\rejects (
	ECHO !rejects>> logs.txt
	ECHO Rejects has been detected, compiling can not be start
	GOTO :exit
	)

REM Compiling Psi+ Classic release version
IF %MakeClassic%==1 (
	REM Configuring Psi+ Classic release version
	ECHO Configuring Psi+ Classic release version
	ECHO :configuring classic release>> logs.txt
	CD PsiPlusWorkdir
	call qconf.cmd
	IF ERRORLEVEL 1 ECHO QConf failed & CD .. & ECHO !qconf failed>> logs.txt & GOTO :exit
	configure ^
	--enable-plugins ^
	--with-openssl-inc=%OPENSSLDIR%\include ^
	--with-openssl-lib=%OPENSSLDIR%\lib ^
	--disable-xss ^
	--disable-qdbus ^
	--with-aspell-inc=%MINGWDIR%\include ^
	--with-aspell-lib=%MINGWDIR%\lib ^
	--enable-whiteboarding
	IF ERRORLEVEL 1 ECHO Configuring failed & CD .. & ECHO !configuring failed>> logs.txt & GOTO :exit
	REM Compiling Psi+ Classic release version
	ECHO Compiling Psi+ Classic release version
	ECHO :compiling classic release>> ..\logs.txt
	ECHO :compiling started: %TIME%>> ..\logs.txt
	mingw32-make
	CD ..
	IF NOT EXIST PsiPlusWorkdir\src\release\psi-plus.exe ECHO !compiling failed: %TIME%>> logs.txt & ECHO Compiling failed, but will try again after next updating & GOTO :exit
	ECHO :compiling completed: %TIME%>> logs.txt
	REM Preparing for upload
	ECHO Preparing for upload
	ECHO :archiving>> logs.txt
	MOVE /Y PsiPlusWorkdir\src\release\psi-plus.exe psi-plus.exe
	ECHO MOVE /Y psi-plus.exe psi-plus-portable.exe ^&^& DEL make-psi-plus-portable.bat>make-psi-plus-portable.bat
	ECHO Archiving Psi+ Classic release version
	7z a -mx9 "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-win32.7z" "make-psi-plus-portable.bat" "psi-plus.exe"
	IF ERRORLEVEL 1 ECHO Archiving failed & ECHO !archiving failed>> logs.txt & GOTO :exit
	)

REM Uploading Psi+ Classic release version to GoogleCode
IF %UploadClassic%==1 (
	ECHO Uploading Psi+ Classic release version to GoogleCode
	ECHO :uploading>> logs.txt
	CALL googlecode_upload.py ^
	--user %GoogleUser% ^
	--password %GooglePass% ^
	--project psi-dev ^
	--summary "Psi+ Classic Nightly Build || psi-git %date% %currentTime% MSD || Qt %vQt% || Win32 OpenSSL Libs v%vOpenSSL%" ^
	--labels "Windows,Classic,NightlyBuild,Archive" "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-win32.7z"
	)

REM Compiling Psi+ Classic debug version
IF %MakeClassicDebug%==1 (
	REM Configuring Psi+ Classic debug version
	ECHO Configuring Psi+ Webkit debug version
	ECHO :configuring classic debug>> logs.txt
	CD PsiPlusWorkdir
	mingw32-make distclean
	qconf
	IF ERRORLEVEL 1 ECHO QConf failed & CD .. & ECHO !qconf failed>> logs.txt & GOTO :exit
	configure ^
	--debug ^
	--enable-plugins ^
	--with-openssl-inc=%OPENSSLDIR%\include ^
	--with-openssl-lib=%OPENSSLDIR%\lib ^
	--disable-xss ^
	--disable-qdbus ^
	--with-aspell-inc=%MINGWDIR%\include ^
	--with-aspell-lib=%MINGWDIR%\lib ^
	--enable-whiteboarding
	IF ERRORLEVEL 1 ECHO Configuring failed & CD .. & ECHO !configuring failed>> logs.txt & GOTO :exit
	REM Compiling Psi+ Classic debug version
	ECHO Compiling Psi+ Classic debug version
	ECHO :compiling classic debug>> logs.txt
	ECHO :compiling started: %TIME%>> logs.txt
	mingw32-make
	CD ..
	IF NOT EXIST PsiPlusWorkdir\src\debug\psi-plus.exe ECHO !compiling failed: %TIME%>> logs.txt & ECHO Compiling failed, but will try again after next update & GOTO :exit
	ECHO :compiling completed: %TIME%>> logs.txt
	REM Preparing for upload
	ECHO Preparing for upload
	ECHO :archiving>> logs.txt
	MOVE /Y PsiPlusWorkdir\src\debug\psi-plus.exe psi-plus.exe
	ECHO MOVE /Y psi-plus.exe psi-plus-portable.exe ^&^& DEL make-psi-plus-portable.bat>make-psi-plus-portable.bat
	ECHO Archiving Psi+ Classic debug version
	7z a -mx9 "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-debug-win32.7z" "make-psi-plus-portable.bat" "psi-plus.exe"
	IF ERRORLEVEL 1 ECHO Archiving failed & ECHO !archiving failed>> logs.txt & GOTO :exit
	)

REM Uploading Psi+ Classic debug version to GoogleCode
IF %UploadClassicDebug%==1 (
	ECHO Uploading Psi+ Classic debug version to GoogleCode
	ECHO :uploading classic debug>> logs.txt
	CALL googlecode_upload.py ^
	--user %GoogleUser% ^
	--password %GooglePass% ^
	--project psi-dev ^
	--summary "Psi+ Classic Debug Build || psi-git %date% %currentTime% MSD || Qt %vQt% || Win32 OpenSSL Libs v%vOpenSSL% || FOR DEBUG ONLY!!!" ^
	--labels "Classic,Debug,Windows,Archive" "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-debug-win32.7z"
	)

REM Compiling Psi+ Webkit release version
IF %MakeWebkit%==1 (
	REM Configuring Psi+ Webkit release version
	ECHO Configuring Psi+ Webkit release version
	ECHO :configuring webkit release>> logs.txt
	CD PsiPlusWorkdir
	mingw32-make distclean
	qconf
	IF ERRORLEVEL 1 ECHO QConf failed & CD .. & ECHO !qconf failed>> logs.txt & GOTO :exit
	configure ^
	--enable-plugins ^
	--with-openssl-inc=%OPENSSLDIR%\include ^
	--with-openssl-lib=%OPENSSLDIR%\lib ^
	--disable-xss ^
	--disable-qdbus ^
	--with-aspell-inc=%MINGWDIR%\include ^
	--with-aspell-lib=%MINGWDIR%\lib ^
	--enable-webkit ^
	--enable-whiteboarding
	IF ERRORLEVEL 1 ECHO Configuring failed & CD .. & ECHO !configuring failed>> logs.txt & GOTO :exit
	REM Compiling Psi+ Webkit release version
	ECHO Compiling Psi+ Webkit release version
	ECHO :compiling webkit release>> ..\logs.txt
	ECHO :compiling started: %TIME%>> ..\logs.txt
	mingw32-make
	CD ..
	IF NOT EXIST PsiPlusWorkdir\src\release\psi-plus.exe ECHO !compiling failed: %TIME%>> logs.txt & ECHO Compiling failed, but will try again after next updating & GOTO :exit
	ECHO :compiling completed: %TIME%>> logs.txt
	REM Preparing for upload
	ECHO Preparing for upload
	ECHO :archiving>> logs.txt
	MOVE /Y PsiPlusWorkdir\src\release\psi-plus.exe psi-plus.exe
	ECHO D | xcopy PsiPlusWorkdir\themes themes /E
	ECHO MOVE /Y psi-plus.exe psi-plus-portable.exe ^&^& DEL make-psi-plus-portable.bat>make-psi-plus-portable.bat
	ECHO Archiving Psi+ Webkit release version
	7z a -mx9 "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-webkit-win32.7z" "themes" "make-psi-plus-portable.bat" "psi-plus.exe" "%PSIPLUSDIR%\readme.txt"
	IF ERRORLEVEL 1 ECHO Archiving failed & ECHO !archiving failed>> logs.txt & GOTO :exit
	)

REM Uploading Psi+ Webkit release version to GoogleCode
IF %UploadWebkit%==1 (
	ECHO Uploading Psi+ Webkit release version to GoogleCode
	ECHO :uploading>> logs.txt
	CALL googlecode_upload.py ^
	--user %GoogleUser% ^
	--password %GooglePass% ^
	--project psi-dev ^
	--summary "Psi+ WebKit Nightly Build || psi-git %date% %currentTime% MSD || Qt %vQt% || Win32 OpenSSL Libs v%vOpenSSL% || see the file README.TXT inside the archive" ^
	--labels "Windows,WebKit,NightlyBuild,Archive" "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-webkit-win32.7z"
	)

REM Compiling Psi+ Webkit debug version
IF %MakeWebkitDebug%==1 (
	REM Configuring Psi+ Webkit debug version
	ECHO Configuring Psi+ Webkit debug version
	ECHO :configuring webkit debug>> logs.txt
	CD PsiPlusWorkdir
	mingw32-make distclean
	qconf
	IF ERRORLEVEL 1 ECHO QConf failed & CD .. & ECHO !qconf failed>> logs.txt & GOTO :exit
	configure ^
	--debug ^
	--enable-plugins ^
	--with-openssl-inc=%OPENSSLDIR%\include ^
	--with-openssl-lib=%OPENSSLDIR%\lib ^
	--disable-xss ^
	--disable-qdbus ^
	--with-aspell-inc=%MINGWDIR%\include ^
	--with-aspell-lib=%MINGWDIR%\lib ^
	--enable-webkit ^
	--enable-whiteboarding
	IF ERRORLEVEL 1 ECHO Configuring failed & CD .. & ECHO !configuring failed>> logs.txt & GOTO :exit
	REM Compiling Psi+ Webkit debug version
	ECHO Compiling Psi+ Webkit debug version
	ECHO :compiling webkit debug>> ..\logs.txt
	ECHO :compiling started: %TIME%>> ..\logs.txt
	mingw32-make
	CD ..
	IF NOT EXIST PsiPlusWorkdir\src\debug\psi-plus.exe ECHO !compiling failed: %TIME%>> logs.txt & ECHO Compiling failed, but will try again after next update & GOTO :exit
	ECHO :compiling completed: %TIME%>> logs.txt
	REM Preparing for upload
	ECHO Preparing for upload
	ECHO :archiving>> logs.txt
	MOVE /Y PsiPlusWorkdir\src\debug\psi-plus.exe psi-plus.exe
	ECHO MOVE /Y psi-plus.exe psi-plus-portable.exe ^&^& DEL make-psi-plus-portable.bat>make-psi-plus-portable.bat
	ECHO Archiving Psi+ Webkit debug version
	7z a -mx9 "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-webkit-debug-win32.7z" "make-psi-plus-portable.bat" "psi-plus.exe"
	IF ERRORLEVEL 1 ECHO Archiving failed & ECHO !archiving failed>> logs.txt & GOTO :exit
	)

REM Uploading Psi+ Webkit debug version to GoogleCode
IF %UploadWebkitDebug%==1 (
	ECHO Uploading Psi+ Webkit debug version to GoogleCode
	ECHO :uploading webkit debug>> logs.txt
	CALL googlecode_upload.py ^
	--user %GoogleUser% ^
	--password %GooglePass% ^
	--project psi-dev ^
	--summary "Psi+ WebKit Debug Build || psi-git %date% %currentTime% MSD || Qt %vQt% || Win32 OpenSSL Libs v%vOpenSSL% || FOR DEBUG ONLY!!!" ^
	--labels "WebKit,Debug,Windows,Archive" "psi-plus-%vPsiPlusMajor%.%vPsiPlusMinor%-webkit-debug-win32.7z"
	)

REM Compiling Psi+ Plugins release versions
IF %MakePlugins%==1 (
	ECHO :compiling plugins release r.%vPlugins%>> logs.txt
	IF EXIST plugins RMDIR /S /Q plugins
	MKDIR plugins
	ECHO Compiling Psi+ Plugins release versions
	ECHO :compiling started: %TIME%>> logs.txt
	FOR /F %%v IN (%pluginsSrcDir%\plugins.txt) DO CD %pluginsSrcDir%\%%v & %QMAKE% & mingw32-make -f makefile.release & MOVE release\%%v.dll %pluginsBinDir%\%%v.dll & MKDIR %pluginsBinDir%\..\changelogs.txt\%%v & COPY changelog.txt %pluginsBinDir%\..\changelogs.txt\%%v\changelog.txt
	CD %pluginsBinDir%\..
	ECHO :compiling completed: %TIME%>> logs.txt
	ECHO Archiving Psi+ Plugins release versions
	7z a -mx9 "psi-plus-plugins-%vPsiPlusMajor%.%vPlugins%-win32.7z" "plugins" "changelogs.txt"
	RMDIR /S /Q plugins & RMDIR /S /Q changelogs.txt
	)

REM Uploading Psi+ Plugins release versions to GoogleCode
IF %UploadPlugins%==1 (
	ECHO Uploading Psi+ Plugins release versions to GoogleCode
	ECHO :uploading plugins release>> logs.txt
	CALL googlecode_upload.py ^
	--user %GoogleUser% ^
	--password %GooglePass% ^
	--project psi-dev ^
	--summary "Psi+ Plugins || %date% %currentTime% MSD || Qt %vQt%" ^
	--labels "Plugins,Windows,Archive" "psi-plus-plugins-%vPsiPlusMajor%.%vPlugins%-win32.7z"
	)

REM Compiling Psi+ Plugins debug versions
IF %MakePluginsDebug%==1 (
	ECHO :compiling plugins debug r.%vPlugins%>> logs.txt
	IF EXIST plugins RMDIR /S /Q plugins
	MKDIR plugins
	ECHO Compiling Psi+ Plugins debug versions
	ECHO :compiling started: %TIME%>> logs.txt
	FOR /F %%v IN (%pluginsSrcDir%\plugins.txt) DO CD %pluginsSrcDir%\%%v & %QMAKE% & mingw32-make -f makefile.debug & MOVE debug\%%v.dll %pluginsBinDir%\%%v.dll & MKDIR %pluginsBinDir%\..\changelogs.txt\%%v & COPY changelog.txt %pluginsBinDir%\..\changelogs.txt\%%v\changelog.txt
	CD %pluginsBinDir%\..
	ECHO :compiling completed: %TIME%>> logs.txt
	ECHO Archiving Psi+ Plugins debug versions
	7z a -mx9 "psi-plus-plugins-%vPsiPlusMajor%.%vPlugins%-debug-win32.7z" "plugins" "changelogs.txt"
	RMDIR /S /Q plugins & RMDIR /S /Q changelogs.txt
	)

REM Uploading Psi+ Plugins debug versions to GoogleCode
IF %UploadPluginsDebug%==1 (
	ECHO Uploading Psi+ plugins debug versions to GoogleCode
	ECHO :uploading plugins debug>> logs.txt
	CALL googlecode_upload.py ^
	--user %GoogleUser% ^
	--password %GooglePass% ^
	--project psi-dev ^
	--summary "Psi+ Plugins Debug || %date% %currentTime% MSD || Qt %vQt% || FOR DEBUG ONLY!!!" ^
	--labels "Debug,Plugins,Windows,Archive" "psi-plus-plugins-%vPsiPlusMajor%.%vPlugins%-debug-win32.7z"
	)

REM Preparing to exit
:exit
ECHO Preparing to exit
ECHO :exit>> logs.txt
IF EXIST psi-plus.exe DEL psi-plus.exe
IF EXIST themes RMDIR themes /S /Q
IF EXIST make-psi-plus-portable.bat DEL make-psi-plus-portable.bat
IF EXIST vPsiPlusNew MOVE /Y vPsiPlusNew vPsiPlusOld
IF EXIST vPluginsNew MOVE /Y vPluginsNew vPluginsOld
IF EXIST plugins RMDIR /S /Q plugins
IF EXIST changelogs.txt RMDIR /S /Q changelogs.txt
ECHO Script completed
EXIT