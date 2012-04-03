::@echo off
setlocal

set PSI_GIT=git://github.com/psi-im/psi.git
set PSI_PLUS_MAIN_GIT=git://github.com/psi-plus/main.git
set QCONF_SVN=http://delta.affinix.com/svn/trunk/qconf/
set ICONSETS=system clients activities moods affiliations

@echo Check enviroment
set ORIGCD=%CD%
set ERRORLEVEL=0
if defined GITDIR goto :checkUtils
call :getInstallDirFromRegistryWOW64 Git_is1
set GITDIR=%InstallationLocation%bin\

:::findSVN
::if defined SVNDIR goto :checkUtils
::FOR /F "tokens=2,*" %%A IN ('REG QUERY "HKLM\Software\SlikSvn\Install" /v Location ^| findstr Location') DO SET SVNDIR=%%B

:checkUtils
set GIT=%GITDIR%git.exe
set SED=%GITDIR%sed.exe
set PATCH=%GITDIR%patch.exe
::set SVN=%SVNDIR%svn.exe
::set SVNVERSION=%SVNDIR%svnversion.exe
set WORKDIR=%CD%

if defined MINGWDIR goto :ensureExist
call :getInstallDirFromRegistryWOW64 "Qt SDK" HKCU
set GITDIR=%InstallationLocation%bin\
set MINGWDIR=%InstallationLocation%\mingw\bin
set PATH=%MINGWDIR%;%PATH%

:ensureExist
::if not exist "%SVN%" @echo Please set proper SVNDIR before start&goto :failExit
if not exist "%GIT%" @echo git.exe not found. Please set GITDIR before start&goto :failExit
if not exist "%PATCH%" @echo patch.exe not found. Please set GITDIR before start&goto :failExit
if not exist "%SED%" @echo sed.exe not found. Please set GITDIR before start&goto :failExit
( mingw32-make --version 2>&1 ) 1>nul || @echo mingw32-make not found or doesn't work. be sure its in PATH&goto :failExit


@echo Fetching sources
if not exist "%WORKDIR%" mkdir "%WORKDIR%"
cd "%WORKDIR%"
@echo Fetching git sources
if not exist git "%GIT%" clone %PSI_GIT% git || @echo "failed to fetch Psi repo"&goto :failExit
cd git
"%GIT%" pull || @echo "failed to update Psi repo"&goto :failExit
"%GIT%" submodule update --init || @echo "failed to fetch Psi submodules"&goto :failExit

cd "%WORKDIR%"
@echo Fetching Psi+ main repo
if not exist main "%GIT%" clone %PSI_PLUS_MAIN_GIT% main || @echo "failed to clone Psi+ main repo"&goto :failExit
cd main
"%GIT%" pull || @echo "failed to update Psi+ main repo"&goto :failExit

@echo Prepare sources
if exist "%WORKDIR%\build" rd /S /Q "%WORKDIR%\build" || @echo "failed to remove old build dir"&goto :failExit
md "%WORKDIR%\build" || @echo "failed to make new build dir"&goto :failExit
cd "%WORKDIR%\build"
cd "%WORKDIR%\git"
"%GIT%" checkout-index -a --f --prefix=%WORKDIR%\build\
cd "%WORKDIR%\git\iris"
"%GIT%" checkout-index -a --f --prefix=%WORKDIR%\build\iris\
cd "%WORKDIR%\git\src\libpsi"
"%GIT%" checkout-index -a --f --prefix=%WORKDIR%\build\src\libpsi\
xcopy /Y /E /Q "%WORKDIR%\main\iconsets" "%WORKDIR%\build\iconsets" || @echo icons export failed&goto :failExit
copy /Y "%WORKDIR%\main\app.ico" "%WORKDIR%\build\win32\app.ico"
cd "%WORKDIR%"\build
FOR /F "usebackq delims==" %%i IN (`dir /B "%WORKDIR%\main\patches\*.diff"`) DO (
	@echo Apply: %%i
	@echo %%i > "%WORKDIR%\patch.log"
	"%PATCH%" -p1 <  "%WORKDIR%\main\patches\%%i" >> "%WORKDIR%\patch.log" || @echo patch failed&goto :failExit
)

cd "%WORKDIR%"\main
for /f "tokens=2 delims=-" %%i in ('"%GIT%" describe --tags') do set psiplusrev=%%i
set /a psiplusrev=%psiplusrev%+5000
call :doSed "s/\(xxx\)/%psiplusrev%/" "%WORKDIR%\build\src\applicationinfo.cpp"
if %ERRORLEVEL% neq 0 @echo failed to set revision&goto :failExit

cd "%WORKDIR%\build"
:: TODO qconf, configure and make here 

set QCONF="%WORKDIR%"\qconf\qconf.exe
if exist "%QCONF%" goto :callQconf
cd "%WORKDIR%"
"%GIT%" svn clone -r693:HEAD %QCONF_SVN% qconf || @echo failed to clone qconf&goto :failExit
@echo compile qconf
cd "%WORKDIR%"\qconf
configure.exe || @echo failed to configure qconf&goto :failExit
mingw32-make || @echo failed to make qconf&goto :failExit


:callQconf
cd "%WORKDIR%"\build
"%QCONF%" || @echo qconf call failed&goto :failExit
configure.exe --debug --no-separate-debug-info --with-openssl-inc=\local\include --with-openssl-lib=\local\lib  || @echo failed to configure Psi+&goto :failExit

goto :exit



::------------------------------------------------------------
::
::           FUNCTIONS SECTION
::
::------------------------------------------------------------
 ::  finds install path from windows registry. (any app from "Add/Remove software")
:getInstallDirFromRegistryWOW64
setlocal
echo Search install dir for %1
set root=HKLM
if not %2xxx == xxx set root=%2
set is64=0
( for /F "delims==" %%i IN ('REG QUERY  "HKLM\Software\Wow6432Node"') DO set is64=1 ) 2>nul
if %is64% == 1 (goto 64bit) else goto 32bit

:64bit
FOR /F "tokens=2,*" %%A IN ('REG QUERY "%root%\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\%~1" /v InstallLocation ^| findstr InstallLocation') DO SET InstallationLocation=%%B
goto :getInstallDirFromRegistryWOW64Exit

:32bit
FOR /F "tokens=2,*" %%A IN ('REG QUERY "%root%\Software\Microsoft\Windows\CurrentVersion\Uninstall\%~1" /v InstallLocation ^| findstr InstallLocation') DO SET InstallationLocation=%%B

:getInstallDirFromRegistryWOW64Exit
( endlocal
 set InstallationLocation=%InstallationLocation%
)
goto :eof







:doSed  -  Simple sed wrapper. Needed in case of sed 3.x
setlocal
set "expr=%~1"
set "fn=%~2"
"%SED%" -e  "%expr%" %fn% > "%fn%.tmp"&move "%fn%.tmp" "%fn%"
(	endlocal
	set ERRORLEVEL=%ERRORLEVEL%
)
goto :eof


:failExit
set ERRORLEVEL=1
:exit
( endlocal
	set ERRORLEVEL=%ERRORLEVEL%
	cd "%ORIGCD%"
)
goto :eof

