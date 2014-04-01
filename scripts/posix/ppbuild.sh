#!/bin/bash

#CONSTANTS/КОНСТАНТЫ
home=${HOME:-/home/$USER} #домашний каталог
psi_version="0.16" #не менять без необходимости, нужно для пакетирования
bindirs="/usr/bin
/usr/local/bin
${home}/bin" #список каталогов где могут быть найдены бинарники
qconf_cmds="qconf
qconf-qt4
qt-qconf" #список возможных имён бинарника qconf
def_prefix="/usr" #префикс для сборки пси+
libpsibuild_url="https://raw.github.com/psi-plus/maintenance/master/scripts/posix/libpsibuild.sh"
#DEFAULT OPTIONS/ОПЦИИ ПО УМОЛЧАНИЮ
no_enchant="--disable-enchant"
iswebkit=""
use_iconsets="system clients activities moods affiliations roster"
isoffline=0
skip_invalid=0
use_plugins="*"
#

#VARIABLES/ПЕРЕМЕННЫЕ
#каталог где будет лежать скрипт libpsibuild.sh и каталог buildpsi(по умолчанию)
workdir=${home}/github
#значение переменной buildpsi по умолчанию
default_buildpsi=${workdir}/psi 
#имя временного каталога для пакетирования
inst_suffix=tmp
#префикс CMAKE по умолчанию
DEF_CMAKE_INST_PREFIX="${home}/.local"
#каталог плагинов в префиксе по умолчанию
DEF_CMAKE_INST_SUFFIX="share/psi+/plugins"
#список плагинов для сборки через ";" (otrplugin;cleanerplugin и.т.д.)
DEF_PLUG_LIST="ALL"
#тип сборки плагинов
DEF_CMAKE_BUILD_TYPE="Release"

#WARNING: следующие переменные будут изменены в процессе работы скрипта автоматически
buildpsi=${default_buildpsi} #инициализация переменной
orig_src=${buildpsi}/build #рабочий каталог для компиляции psi+
patches=${buildpsi}/git-plus/patches #путь к патчам psi+, необходим для разработки
inst_path=${buildpsi}/${inst_suffix} #только для пакетирования
cmake_files_dir=${buildpsi}/psi-plus-plugins-cmake #файлы CMAKE для сборки плагинов
#

#ENVIRONMENT VARIABLES/ПЕРЕМЕННЫЕ СРЕДЫ
psi_datadir=${home}/.local/share/psi+
psi_cachedir=${home}/.cache/psi+
psi_homeplugdir=${psi_datadir}/plugins
#

#CONFIG FILE PATH/ПУТЬ К ФАЙЛУ НАСТРОЕК
config_file=${home}/.config/psibuild.cfg

#PLUGINS_BUILD_LOG/ЛОГ ФАЙЛ СБОРКИ ПЛАГИНОВ
plugbuild_log=${orig_src}/plugins.log
#

#RPM_VARIABLES/ПЕРЕМЕННЫЕ ДЛЯ СБОРКИ RPM ПАКЕТОВ
rpmbuilddir=${home}/rpmbuild
rpmspec=${rpmbuilddir}/SPECS
rpmsrc=${rpmbuilddir}/SOURCES
#

#значения по умолчанию для поиска утилиты qconf
qconf_bin="qconf"
qconf_dir="/usr/bin"
#

find_qconf ()
{
  local isfound=0
  for cmd_item in ${qconf_cmds}; do
    for bin_path in ${bindirs}; do
    if [ -f "${bin_path}/${cmd_item}" ]; then
      qconf_dir="${bin_path}"
      qconf_bin="${bin_path}/${cmd_item}"
      isfound=1
      break
    fi
    done
    if [ ${isfound} -eq 1 ]; then
      echo "QConf utility found: ${qconf_bin}"; echo ""
      break
    fi
  done
  if [ ${isfound} -eq 0 ] || [ -z "${qconf_bin}" ]; then
    echo "Enter the absolute path to qconf binary (Example: /home/me/qconf):"
    read qconf_bin
  fi
}
#
quit ()
{
  break
}
#
read_options ()
{
  local pluginlist=""
  if [ -f ${config_file} ]; then
    local inc=0
    while read -r line; do
      case ${inc} in
      "0" ) iswebkit=$(echo ${line});;
      "1" ) use_iconsets=$(echo ${line});;
      "2" ) isoffline=$(echo ${line});;
      "3" ) skip_invalid=$(echo ${line});;
      "4" ) pluginlist=$(echo ${line});;
      "5" ) no_enchant=$(echo ${line});;
      "6" ) buildpsi=$(echo ${line});;
      esac
      let "inc+=1"
    done < ${config_file}
    if [ "$pluginlist" == "all" ]; then
      use_plugins="*"
    else
      use_plugins=${pluginlist}
    fi
    if [ -z "${buildpsi}" ]; then
      buildpsi=${default_buildpsi}
    fi
    if [ "${buildpsi:0:5}" == "\$HOME" ]; then
      buildpsi=${home}/${buildpsi:6}
    fi
  fi
  update_variables
}
#
set_options ()
{
  PSI_DIR="${buildpsi}"
  ICONSETS=${use_iconsets}
  WORK_OFFLINE=${WORK_OFFLINE:-$isoffline}
  PATCH_LOG=""
  SKIP_INVALID_PATCH="${SKIP_INVALID_PATCH:-$skip_invalid}"
  CONF_OPTS="${iswebkit} ${no_enchant}"
  INSTALL_ROOT="${INSTALL_ROOT:-$def_prefix}"
  QCONFDIR=${qconf_dir}
  PLUGINS="${PLUGINS:-$use_plugins}"
}
#
update_variables ()
{
  orig_src=${buildpsi}/build
  patches=${buildpsi}/git-plus/patches
  inst_path=${buildpsi}/${inst_suffix}
  cmake_files_dir=${buildpsi}/psi-plus-plugins-cmake
}
#
check_libpsibuild ()
{
  die() { echo "$@"; exit 1; }
  cd ${workdir}
  if [ "$isoffline" = 0 ]; then
    echo "**libpsibuild.sh library updates check**"; echo ""
    wget --output-document="libpsibuild.sh.new" --no-check-certificate ${libpsibuild_url};
    if [ "$(diff -q libpsibuild.sh libpsibuild.sh.new)" ] || [ ! -f "${workdir}/libpsibuild.sh" ]
    then
      echo "**libpsibuild.sh library has been updated**"; echo ""
      mv -f ${workdir}/libpsibuild.sh.new ${workdir}/libpsibuild.sh
    else
      echo "**you have the last version of libpsibuild.sh library**"; echo ""  
      rm -f ${workdir}/libpsibuild.sh.new
    fi
    chmod u+x ${workdir}/libpsibuild.sh
  fi
}
#
run_libpsibuild ()
{
  if [ ! -z "$1" ]; then
    cd ${workdir}
    . ./libpsibuild.sh
    check_env $CONF_OPTS
    $1
  fi
}
#
check_dir ()
{
  if [ ! -z "$1" ]; then
    if [ ! -d "$1" ]; then
      mkdir -pv "$1"
    fi
  fi
}
#
down_all ()
{
  check_dir ${buildpsi}/git
  check_dir ${buildpsi}/git-plus
  check_dir ${buildpsi}/plugins
  run_libpsibuild fetch_all
}
#
prepare_src ()
{
  down_all
  run_libpsibuild prepare_workspace
  run_libpsibuild prepare_all
  echo "Do you want to apply psi-new-history.patch [y/n(default)]"
  read ispatch
  if [ "${ispatch}" == "y" ]; then
    cd ${orig_src}
    patch -p1 < ${patches}/dev/psi-new-history.patch
    cd ${workdir}
  fi
}
#
backup_tar ()
{
  echo "Backup ${buildpsi##*/} into ${buildpsi%/*}/${buildpsi##*/}.tar.gz started..."
  cd ${buildpsi%/*}
  tar -pczf ${buildpsi##*/}.tar.gz ${buildpsi##*/}
  echo "Backup finished..."; echo " "
}
#
prepare_tar ()
{
  check_dir ${rpmbuilddir}
  check_dir ${rpmsrc}
  check_dir ${rpmspec}
  echo "Preparing Psi+ source package to build RPM..."
  local rev=$(cd ${buildpsi}/git-plus/; echo $(($(git describe --tags | cut -d - -f 2))))
  local tar_name=psi-plus-${psi_version}.${rev}
  local new_src=${buildpsi}/${tar_name}
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]; then
    cd ${buildpsi}
    tar -sczf ${tar_name}.tar.gz ${tar_name}
    rm -r -f ${new_src}
    if [ -d ${rpmsrc} ]; then
      if [ -f "${rpmsrc}/${tar_name}.tar.gz" ]; then
        rm -f ${rpmsrc}/${tar_name}.tar.gz
      fi
      cp -f ${buildpsi}/${tar_name}.tar.gz ${rpmsrc}
    fi
    echo "Preparing completed"
  fi
}
#
prepare_win ()
{
  echo "Preparing Psi+ source package to build in OS Windows..."
  prepare_src
  local rev=$(cd ${buildpsi}/git-plus/; echo $(($(git describe --tags | cut -d - -f 2))))
  local tar_name=psi-plus-${psi_version}.${rev}-win
  local new_src=${buildpsi}/${tar_name}
  local mainicon=${buildpsi}/git-plus/app.ico
  local file_pro=${new_src}/src/src.pro
  local ver_file=${new_src}/version
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]; then
    cd ${buildpsi}
    sed "s/#CONFIG += psi_plugins/CONFIG += psi_plugins/" -i "${file_pro}"
    sed "s/\(@@DATE@@\)/"$(date +"%Y-%m-%d")"/" -i "${ver_file}"
    cp -f ${mainicon} ${new_src}/win32/
    local makepsi='@echo off
@echo PSI-PLUS BUILD SCRIPT
@echo _
set /p HISTYPE=Do you want to build psi+ with new history [y/n(default)]:%=%
@echo _
set /p ARCHTYPE=Do you want to build psi+ x86_64 binary [y/n(default)]:%=%
@echo _
set /p WEBKIT=Do you want to build psi+ webkit binary [y/n(default)]:%=%
@echo _ 
set /p BINTYPE=Do you want to build psi+ debug binary [y/n(default)]:%=%
@echo _ 
set /p ISCLEAN=Do you want to launch clean and distclean commands [y/n(default)]:%=%
@echo _

set QMAKESPEC=win32-g++
set BUILDDIR=C:\build
set PLUGBUILDDIR=%BUILDDIR%\PluginsBuilder

if /i "%ARCHTYPE%"=="y" (
set QTDIR=%QTDIR64%
set MINGWDIR=C:\MinGW
set MINGW64=C:\mingw64
set ARCH=x86_64
set CC=%MINGW64%\bin\gcc
set CXX=%MINGW64%\bin\g++
) else (
set QTDIR=%QTDIR32%
set ARCH=i386
set MINGWDIR=C:\MinGW
) 
if /i "%ARCH%"=="i386" (
set PATH=%QTDIR%\;%QTDIR%\bin;%MINGWDIR%;%MINGWDIR%\bin
) else (
set PATH=%QTDIR%\;%QTDIR%\bin;%MINGW64%\;%MINGW64%\bin;%MINGWDIR%;%MINGWDIR%\bin
)
set JSONPATH=%BUILDDIR%\psideps\qjson\%ARCH%
set QCADIR=%BUILDDIR%\psideps\qca\%ARCH%
set ZLIBDIR=%BUILDDIR%\psideps\zlib\%ARCH%
set QCONFDIR=%BUILDDIR%\qconf\%ARCH%
set ASPELLDIR=%BUILDDIR%\psideps\aspell\%ARCH%
set LIBIDNDIR=%BUILDDIR%\psideps\libidn\%ARCH%
set MAKE=mingw32-make -j5

if /i "%ISCLEAN%"=="y" (
mingw32-make clean
mingw32-make distclean
)

%QCONFDIR%\qconf

if /i "%WEBKIT%"=="y" (
set ISWEBKIT=--enable-webkit
if /i "%ARCH%"=="i386" (
set INSTDIR=webkit32
) else (
set INSTDIR=webkit64
)
) else (
if /i "%ARCH%"=="i386" (
set INSTDIR=bin32
) else (
set INSTDIR=bin64
)
)

if /i "%HISTYPE%"=="y" (
set HISTORYLIBS=--with-qjson-lib=%JSONPATH%\lib
set HISTORYINC=--with-qjson-inc=%JSONPATH%\include
)
set ISDEBUG=--release
if /i "%BINTYPE%"=="y" (
set ISDEBUG=--debug
)

@echo configure %ISDEBUG% --enable-plugins --enable-whiteboarding %ISWEBKIT% --qtdir=%QTDIR% --with-zlib-inc=%ZLIBDIR%\include --with-zlib-lib=%ZLIBDIR%\lib --with-qca-inc=%QCADIR%\include --with-qca-lib=%QCADIR%\lib --disable-xss --disable-qdbus --with-aspell-inc=%ASPELLDIR%\include --with-aspell-lib=%ASPELLDIR%\lib --with-idn-inc=%LIBIDNDIR%\include --with-idn-lib=%LIBIDNDIR%\lib %HISTORYLIBS% %HISTORYINC%
configure %ISDEBUG% --enable-plugins --enable-whiteboarding %ISWEBKIT% --qtdir=%QTDIR% --with-zlib-inc=%ZLIBDIR%\include --with-zlib-lib=%ZLIBDIR%\lib --with-qca-inc=%QCADIR%\include --with-qca-lib=%QCADIR%\lib --disable-xss --disable-qdbus --with-aspell-inc=%ASPELLDIR%\include --with-aspell-lib=%ASPELLDIR%\lib --with-idn-inc=%LIBIDNDIR%\include --with-idn-lib=%LIBIDNDIR%\lib %HISTORYLIBS% %HISTORYINC%

pause
@echo Runing mingw32-make
mingw32-make -j5
mkdir %INSTDIR%
copy /Y psi-plus.exe %INSTDIR%\psi-plus.exe
@echo _ 
set /p ANS1=Do you want to create psi-plus-portable.exe binary [y(default)/n]:%=%
if /i not "%ANS1%"=="n" (
copy /Y psi-plus.exe psi-plus-portable.exe
)
@echo _ 
set /p ANS2=Do you want to psi+ plugins [y(default)/n]:%=%
if /i not "%ANS2%"=="n" (
%PLUGBUILDDIR%\compile-plugins -j 5 -o ..\
)
@goto exit

:exit
pause
'
    echo "${makepsi}" > ${new_src}/make-psiplus.cmd
    tar -pczf ${tar_name}.tar.gz ${tar_name}
    rm -rf ${new_src}
  fi
}
#
compile_psiplus ()
{
  prepare_src
  run_libpsibuild compile_psi 2>${buildpsi}/errors.txt
}
#
qmakecmd ()
{
  if [ -f "/usr/bin/qmake" ] || [ -f "/usr/local/bin/qmake" ]; then
    qmake
  else
    if [ -f "/usr/bin/qmake-qt4" ] || [ -f "/usr/local/bin/qmake-qt4" ]; then
      qmake-qt4
    else
      echo "ERROR qmake not found"
    fi
  fi
}
#
build_plugins ()
{
  if [ ! -f "${orig_src}/psi.pro" ]; then
    prepare_src
  fi
  local tmpplugs=${orig_src}/plugins
  check_dir ${tmpplugs}
  local plugins=$(find ${orig_src}/src/plugins -name '*plugin.pro' -print0 | xargs -0 -n1 dirname)
  for pplugin in ${plugins}; do
    make_plugin ${pplugin} 2>>${plugbuild_log}
  done
  echo "*******************************"
  echo "Plugins compiled succesfully!!!"
  echo "*******************************"
  echo "Do you want to install psi+ plugins into ${psi_homeplugdir} [y/n(default)]"
  read isinstall
  if [ "${isinstall}" == "y" ]; then
    check_dir ${psi_homeplugdir}
    cp -vf ${buildpsi}/build/plugins/*.so ${psi_homeplugdir}/
  fi
  echo "********************************"
  echo "Plugins installed succesfully!!!"
  echo "********************************"
  cd ${workdir}
}
#
make_plugin ()
{
  if [ ! -z "$1" ]; then
    local currdir=$(pwd)
    cd "$1"
    if [ -d "/usr/lib/ccache/bin" ] || [ -d "/usr/lib64/ccache/bin" ]; then
      QMAKE_CCACHE_CMD="QMAKE_CXX=ccache g++"
    fi
    if [ ! -z "$(ls .obj | grep -e '.o$')" ]; then make && make distclean; fi
    qmakecmd -t ${QMAKE_CCACHE_CMD} && make && cp -f *.so ${tmpplugs}/
    cd ${currdir}
  fi
}
#
fetch_cmake_files ()
{
  local repo_url="https://github.com/Vitozz/psi-plus-plugins-cmake.git"
  
  cd ${buildpsi}
  if [ ! -d "${cmake_files_dir}" ]; then
    check_dir ${cmake_files_dir}
    git clone ${repo_url} ${cmake_files_dir}
  else
    cd ${cmake_files_dir}
    git reset --hard
    git pull
  fi
}
#
build_cmake_plugins ()
{
  echo_done() {
    echo " "
    echo "********************************"
    echo "Plugins installed succesfully!!!"
    echo "********************************"
    echo " "
  }
  local pl_preffix=${DEF_CMAKE_INST_PREFIX}
  local pl_suffix=${DEF_CMAKE_INST_SUFFIX}
  fetch_cmake_files
  if [ ! -f "${orig_src}/psi.pro" ]; then
    prepare_src
  fi
  check_dir ${orig_src}
  cp -rf ${cmake_files_dir}/* ${orig_src}/
  cd ${orig_src}
  local b_dir=${orig_src}/build
  check_dir ${b_dir}
  cd ${b_dir}
  echo "Do you want to install psi+ plugins into ${psi_homeplugdir} [y/n(default)]"
  read isinstall
  if [ "${isinstall}" != "y" ]; then
    pl_preffix=${orig_src}
    pl_suffix="plugins"
  fi  
  local cmake_flags="-DCMAKE_BUILD_TYPE=${DEF_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${pl_preffix} -DPLUGINS_PATH=${pl_suffix} -DBUILD_PLUGINS=${DEF_PLUG_LIST}"
  echo " "; echo "Build psi+ plugins using CMAKE started..."; echo " "
  cmake ${cmake_flags} ..
  make && make install && echo_done
  cd ${orig_src}
  rm -rf ${b_dir}
}
#
build_deb_package ()
{
  if [ ! -f "${orig_src}/psi.pro" ]; then
    compile_psiplus
  fi
  echo "Building Psi+ DEB package with checkinstall"
  local rev=$(cd ${buildpsi}/git-plus/; echo $(($(git describe --tags | cut -d - -f 2))))
  local desc='Psi is a cross-platform powerful Jabber client (Qt, C++) designed for the Jabber power users.
Psi+ - Psi IM Mod by psi-dev@conference.jabber.ru.'
  cd ${orig_src}
  echo "${desc}" > description-pak
  local requires=' "libaspell15 (>=0.60)", "libc6 (>=2.7-1)", "libgcc1 (>=1:4.1.1)", "libqca2", "libqt4-dbus (>=4.4.3)", "libqt4-network (>=4.4.3)", "libqt4-qt3support (>=4.4.3)", "libqt4-xml (>=4.4.3)", "libqtcore4 (>=4.4.3)", "libqtgui4 (>=4.4.3)", "libstdc++6 (>=4.1.1)", "libx11-6", "libxext6", "libxss1", "zlib1g (>=1:1.1.4)" '
  sudo checkinstall -D --nodoc --pkgname=psi-plus --pkggroup=net --pkgversion=${psi_version}.${rev} --pkgsource=${orig_src} --maintainer="thetvg@gmail.com" --requires="${requires}"
  cp -f ${orig_src}/*.deb ${buildpsi}
}
#
prepare_spec ()
{
  local rev=$(cd ${buildpsi}/git-plus/; echo $(($(git describe --tags | cut -d - -f 2))))
  if [ ! -z ${iswebkit} ]; then
    webkit="--enable-webkit"
  fi
  if [ ! -z ${qconf_bin} ] && [ -f "${qconf_bin}" ]; then
    qconfcmd=${qconf_bin}
  fi
  echo "Creating psi.spec file..."
  local specfile="Summary: Client application for the Jabber network
Name: psi-plus
Version: ${psi_version}.${rev}
Release: 1
License: GPL
Group: Applications/Internet
URL: http://code.google.com/p/psi-dev/
Source0: %{name}-%{version}.tar.gz


BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root


BuildRequires: openssl-devel, gcc-c++, zlib-devel
%{!?_without_freedesktop:BuildRequires: desktop-file-utils}


%description
Psi is the premiere Instant Messaging application designed for Microsoft Windows, 
Apple Mac OS X and GNU/Linux. Built upon an open protocol named Jabber,           
si is a fast and lightweight messaging client that utilises the best in open      
source technologies. The goal of the Psi project is to create a powerful, yet     
easy-to-use Jabber/XMPP client that tries to strictly adhere to the XMPP drafts.  
and Jabber JEPs. This means that in most cases, Psi will not implement a feature  
unless there is an accepted standard for it in the Jabber community. Doing so     
ensures that Psi will be compatible, stable, and predictable, both from an end-user 
and developer standpoint.
Psi+ - Psi IM Mod by psi-dev@conference.jabber.ru


%prep
%setup


%build
${qconfcmd}
./configure --prefix=\"%{_prefix}\" --bindir=\"%{_bindir}\" --datadir=\"%{_datadir}\" --qtdir=$QTDIR --enable-plugins ${webkit} --release --no-separate-debug-info
%{__make} %{?_smp_mflags}


%install
%{__rm} -rf %{buildroot}


%{__make} install INSTALL_ROOT=\"%{buildroot}\"


# Install the pixmap for the menu entry
%{__install} -Dp -m0644 iconsets/system/default/logo_128.png \
    %{buildroot}%{_datadir}/pixmaps/psi-plus.png ||:               


%post
touch --no-create %{_datadir}/icons/hicolor || :
%{_bindir}/gtk-update-icon-cache --quiet %{_datadir}/icons/hicolor || :


%postun
touch --no-create %{_datadir}/icons/hicolor || :
%{_bindir}/gtk-update-icon-cache --quiet %{_datadir}/icons/hicolor || :


%clean
%{__rm} -rf %{buildroot}


%files
%defattr(-, root, root, 0755)
%doc COPYING README TODO
%{_bindir}/psi-plus
#%{_bindir}/psi-plus.debug
%{_datadir}/psi-plus/
%{_datadir}/pixmaps/psi-plus.png
%{_datadir}/applications/psi-plus.desktop
%{_datadir}/icons/hicolor/*/apps/psi-plus.png
%exclude %{_datadir}/psi-plus/COPYING
%exclude %{_datadir}/psi-plus/README
"
  local tmp_spec=${buildpsi}/test.spec
  usr_spec=${rpmspec}/psi-plus.spec
  echo "${specfile}" > ${tmp_spec}
  cp -f ${tmp_spec} ${usr_spec}
}
#
build_rpm_package ()
{
  prepare_src
  prepare_tar
  local rev=$(cd ${buildpsi}/git-plus/; echo $(($(git describe --tags | cut -d - -f 2))))
  local tar_name=psi-plus-${psi_version}.${rev}
  local sources=${rpmsrc}
  if [ -f "${sources}/${tar_name}.tar.gz" ]; then
    prepare_spec
    echo "Building Psi+ RPM package"
    cd ${rpmspec}
    rpmbuild -ba --clean --rmspec --rmsource ${usr_spec}
    local rpm_ready=$(find $HOME/rpmbuild/RPMS | grep psi-plus)
    local rpm_src_ready=$(find $HOME/rpmbuild/SRPMS | grep psi-plus)
    cp -f ${rpm_ready} ${buildpsi}
    cp -f ${rpm_src_ready} ${buildpsi}
  fi
}
#
prepare_dev ()
{
  local psidev=$buildpsi/psidev
  local orig=$psidev/git.orig
  local new=$psidev/git
  rm -rf $orig
  rm -rf $new
  cd ${buildpsi}
  echo ${psidev}
  check_dir ${psidev}
  check_dir ${orig}
  check_dir ${new}
  if [ ! -d ${buildpsi}/git ]; then
    down_all
  fi
  cp -r git/* ${orig}
  cp -r git/* ${new}
  cd ${psidev}
  if [ ! -f deploy ]; then
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/deploy" || die "Failed to update deploy";
  fi
  if [ ! -f mkpatch ]; then
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/mkpatch" || die "Failed to update mkpatch";
  fi
  if [ ! -f psidiff.ignore ]; then
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/psidiff.ignore" || die "Failed to update psidiff.ignore";
  fi
  local patchlist=$(ls ${buildpsi}/git-plus/patches/ | grep diff)
  cd ${orig}
  echo "Enter maximum patch number to patch orig src"
  read patchnumber
  for patchfile in ${patchlist}; do
      if [  ${patchfile:0:4} -lt ${patchnumber} ]; then
        echo  ${patchfile}
        patch -p1 < ${buildpsi}/git-plus/patches/${patchfile}
      fi
  done
  cd ${new}
  echo "Enter maximum patch number to patch work src"
  read patchnumber
  for patchfile in ${patchlist}; do
      if [  ${patchfile:0:4} -lt ${patchnumber} ]; then
        echo  ${patchfile}
        patch -p1 < ${buildpsi}/git-plus/patches/${patchfile}
      fi
  done
}
#
otr_deb ()
{
  prepare_src
  cd ${buildpsi}
  local otrorigdir=${buildpsi}/plugins/generic/otrplugin
  cd ${buildpsi}/plugins/generic
  cp -r ${otrorigdir} ${orig_src}/src/plugins/generic
  local otrdebdir=${orig_src}/src/plugins/generic/otrplugin
  cd ${otrdebdir}
  local PREFIX=/usr
  local user="Vitaly Tonkacheyev"
  local email="thetvg@gmail.com"
  local data=$(LANG=en date +'%a, %d %b %Y %T %z')
  local year=$(date +'%Y')
  cd ${otrdebdir}
  local debver=$(grep -Po '\d\.\d\.\d+' src/psiotrplugin.cpp)
#
  local control='Source: psi-plus-otrplugin
Section: libs
Priority: optional
Maintainer: Vitaly Tonkacheyev <thetvg@gmail.com>
Build-Depends: debhelper (>= 7), cdbs, libqt4-dev, libtidy-dev, libotr2-dev, libgcrypt11-dev
Standards-Version: 3.8.3
Homepage: https://github.com/psi-plus/plugins

Package: psi-plus-otrplugin
Architecture: any
Depends: ${shlibs:Depends}, ${misc:Depends}, libc6 (>=2.7-1), libgcc1 (>=1:4.1.1), libqtcore4 (>=4.6), libqtgui4 (>=4.6), libqt4-xml (>=4.6), libotr2, libgcrypt11, libtidy-0.99-0, libstdc++6 (>=4.1.1), libx11-6, zlib1g (>=1:1.1.4)
Description: Off-The-Record-Messaging plugin for Psi
 This is a Off-The-Record-Messaging plugin for the Psi+ instant messenger. Psi+ (aka Psi-dev) is a collection of patches for Psi. Psi+ is available from http://code.google.com/p/psi-dev/.'
  local copyright="This work was packaged for Debian by:

    ${user} <${email}> on ${data}

It was downloaded from:

   https://github.com/psi-plus/plugins

Upstream Author(s):

     Timo Engel <timo-e@freenet.de>

Copyright:

    <Copyright (C) 2007 Timo Engel>

License:

### SELECT: ###
    This package is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
### OR ###
   This package is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 2 as
   published by the Free Software Foundation.
##########

    This package is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this package; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

On Debian systems, the complete text of the GNU General
Public License version 2 can be found in \"/usr/share/common-licenses/GPL-2\".

The Debian packaging is:

    Copyright (C) ${year} $user <$email>

you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

# Please also look if there are files or directories which have a
# different copyright/license attached and list them here."
  local dirs='usr/lib/psi-plus/plugins'
  local compat='7'
  local rules='#!/usr/bin/make -f
# -*- makefile -*-
# Sample debian/rules that uses debhelper.
# This file was originally written by Joey Hess and Craig Small.
# As a special exception, when this file is copied by dh-make into a
# dh-make output file, you may use that output file without restriction.
# This special exception was added by Craig Small in version 0.37 of dh-make.

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1
config.status: configure
	dh_testdir

	# Add here commands to configure the package.
	./configure --host=$(DEB_HOST_GNU_TYPE)
	--build=$(DEB_BUILD_GNU_TYPE)
	--prefix=/usr 
  
include /usr/share/cdbs/1/rules/debhelper.mk
include /usr/share/cdbs/1/class/qmake.mk

# Add here any variable or target overrides you need.
QMAKE=qmake-qt4
CFLAGS=-O3
CXXFLAGS=-O3'
  local package_sh="#!/bin/bash
set -e

debuild -us -uc
debuild -S -us -uc
su -c pbuilder build ../psi-plus-otrplugin-${debver}.dsc"
  local changelog_template="psi-plus-otrplugin (${debver}-1) unstable; urgency=low

  * New upstream release see README for details

 -- ${user} <${email}>  ${data}"
  local docs='COPYING
INSTALL
README'
#
  builddeb=${orig_src}/src/plugins/generic/psi-plus-otrplugin-${debver}
  check_dir ${builddeb}/debian
  cp -r ${otrdebdir}/* ${builddeb}
  local changefile=${builddeb}/debian/changelog
  local rulesfile=${builddeb}/debian/rules
  local controlfile=${builddeb}/debian/control
  local dirsfile=${builddeb}/debian/dirs
  local compatfile=${builddeb}/debian/compat
  local copyrightfile=${builddeb}/debian/copyright
  local docsfile=${builddeb}/debian/docs
  local package_sh_file=${builddeb}/package.sh
  echo "${changelog_template}" > ${changefile}
  echo "${package_sh}" > ${package_sh_file}
  echo "${rules}" > ${rulesfile}
  echo "${control}" > ${controlfile}
  echo "${dirs}" > ${dirsfile}
  echo "${docs}" > ${docsfile}
  echo "${compat}" > ${compatfile}
  echo "${copyright}" > ${copyrightfile}
#
  cd ${builddeb}
  qmakecmd
  dpkg-buildpackage -rfakeroot
  cp -f ../psi-plus-otrplugin_${debver}*.deb $buildpsi
}
#
prepare_plugins_spec ()
{
  local specfile="
Summary: ${summary}
Name: ${progname}
Version: ${rpmver}
Release: 1
License: GPL-2
Group: ${group}
URL: ${urlpath}
Source0: ${package_name}
BuildRequires: ${breq}
Requires: psi-plus
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-build

%description
${desc}

%prep
%setup

%build
cd ${plugdir}
qmake
%{__make} %{?_smp_mflags} 

%install
cd ${plugdir}
[ \"%{buildroot}\" != \"/\"] && rm -rf %{buildroot}
%{__make} install INSTALL_ROOT=\"%{buildroot}\"

%clean
[ \"%{buildroot}\" != \"/\" ] && rm -rf %{buildroot}

%files
%defattr(-, root, root, 0755)
%{_libdir}/psi-plus/plugins/${libfile}
${docfiles}
"
  echo "${specfile}" > ${rpmspec}/${progname}.spec
}
#
otr_rpm ()
{
  local progname="psi-plus-otrplugin"
  prepare_src
  cd ${buildpsi}
  local otrorigdir=${buildpsi}/plugins/generic/otrplugin
  local PREFIX="/usr"
  local rpmver=$(grep -Po '\d\.\d\.\d+' ${otrorigdir}/src/psiotrplugin.cpp)
  local package_name="${progname}-${rpmver}.tar.gz"
  local summary="Off-The-Record-Messaging plugin for Psi"
  local breq="libotr-devel, libtidy-devel, libgcrypt-devel"
  local urlpath="https://github.com/psi-plus/plugins"
  local group="Applications/Internet"
  local desc="This is a Off-The-Record-Messaging plugin for the Psi+ instant messenger.
 Psi+ (aka Psi-dev) is a collection of patches for Psi. Psi+ is available from
 http://code.google.com/p/psi-dev/"
  local plugdir="generic/otrplugin"
  local libfile="libotrplugin.so"
  local docfiles="%doc ${plugdir}/README ${plugdir}/COPYING"
  #
  check_dir ${inst_path}/${progname}-${rpmver}/generic/otrplugin
  cp -r ${orig_src}/src/plugins/*.pri ${inst_path}/${progname}-${rpmver}/
  cp -r ${orig_src}/src/plugins/include ${inst_path}/${progname}-${rpmver}/
  cp -r ${otrorigdir}/* ${inst_path}/${progname}-${rpmver}/generic/otrplugin/
  cd ${inst_path}
  tar -pczf $package_name ${progname}-${rpmver}
  #
  prepare_plugins_spec
  cp -rf ${package_name} ${rpmsrc}/
  rpmbuild -ba --clean --rmspec --rmsource ${rpmspec}/${progname}.spec
  echo "Cleaning..."
  cd $buildpsi
  rm -rf ${inst_suffix}
}
#
get_resources ()
{
  cd ${buildpsi}
  git clone git://github.com/psi-plus/resources.git
}
#
install_resources ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ ! -d "resources" ]; then
    get_resources
  fi
  cp -rf ${buildpsi}/resources/* ${psi_datadir}/
}
#
install_iconsets ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ -d "resources" ]; then
    get_resources
  fi  
  cp -rf ${buildpsi}/resources/iconsets ${psi_datadir}/
}
#
install_skins ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ -d "resources" ]; then
    cp -rf ${buildpsi}/resources/skins ${psi_datadir}/
  else
    get_resources
    cp -rf ${buildpsi}/resources/skins ${psi_datadir}/
  fi 
}
#
install_sounds ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ -d "resources" ]; then
    cp -rf ${buildpsi}/resources/sound ${psi_datadir}/
  else
    get_resources
    cp -rf ${buildpsi}/resources/sound ${psi_datadir}/
  fi 
}
#
install_themes ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ -d "resources" ]; then
    cp -rf ${buildpsi}/resources/themes ${psi_datadir}/
  else
    get_resources
    cp -rf ${buildpsi}/resources/themes ${psi_datadir}/
  fi 
}
#
update_resources ()
{
  cd ${buildpsi}/resources
  git pull
}
#
build_locales ()
{
  local tr_path=${buildpsi}/langs/translations
  run_libpsibuild fetch_sources
  if [ -d "${tr_path}" ]; then
    rm -f ${tr_path}/*.qm
    if [ -f "/usr/bin/lrelease" ] || [ -f "/usr/local/bin/lrelease" ]; then
      lrelease ${tr_path}/*.ts 
    fi
    if [ -f "/usr/bin/lrelease-qt4" ] || [ -f "/usr/local/bin/lrelease-qt4" ]; then
      lrelease-qt4 ${tr_path}/*.ts 
    fi
  fi 
}
#
install_locales ()
{
  local tr_path=${buildpsi}/langs/translations
  build_locales
  check_dir ${psi_datadir}
  cp -rf ${tr_path}/*.qm ${psi_datadir}/
}
#
set_config ()
{
  local use_webkit="n"
  if [ ! -z "$iswebkit" ]; then
    use_webkit="y"
  else
    use_webkit="n"
  fi
  local is_offline="n"
  if [ "$isoffline" -eq 0 ]; then
    is_offline="n"
  else
    is_offline="y"
  fi
  local skip_patches="n"
  if [ "$skip_invalid" -eq 0 ]; then
    skip_patches="n"
  else
    skip_patches="y"
  fi
  local noenchant="y"
  if [ ! -z "${no_enchant}" ]; then
    noenchant="y"
  else
    noenchant="n"
  fi
  local loop=1
  while [ ${loop} = 1 ];  do
    echo "Choose action TODO:"
    echo "--[1] - Set WebKit version to use (current: ${use_webkit})"
    echo "--[2] - Set iconsets list needed to build"
    echo "--[3] - Set Offline Mode (current: ${is_offline})"
    echo "--[4] - Skip Invalid patches (current: ${skip_patches})"
    echo "--[5] - Set list of plugins needed to build (for all use *)"
    echo "--[6] - Set use aspell instead of enchant (current: ${noenchant})"
    echo "--[7] - Set psi+ sources path (current: ${buildpsi})"
    echo "--[8] - Print option values"
    echo "--[0] - Do nothing"
    read deistvo
    case ${deistvo} in
      "1" ) echo "Do you want use WebKit [y/n] ?"
            read variable
            if [ "$variable" == "y" ]; then
              iswebkit="--enable-webkit"
              use_webkit="y"
            else
              iswebkit=""
              use_webkit="n"
            fi;;
      "2" ) echo "Please enter iconsets separated by space"
            read variable
            if [ ! -z "$variable" ]; then
              use_iconsets=${variable}
            else
              use_iconsets="system clients activities moods affiliations roster"
            fi;;
      "3" ) echo "Do you want use Offline Mode [y/n] ?"
            read variable
            if [ "$variable" == "y" ]; then
              isoffline=1
              is_offline="y"
            else
              isoffline=0
              is_offline="n"
            fi;;
      "4" ) echo "Do you want to skip invalid patches when patching [y/n] ?"
            read variable
            if [ "$variable" == "y" ]; then
              skip_invalid=1
              skip_patches="y"
            else
              skip_invalid=0
              skip_patches="n"
            fi;;
      "5" ) echo "Please enter plugins needed to build separated by space (* for all)"
            read variable
            if [ ! -z "$variable" ]; then
              use_plugins=${variable}
            else
              use_plugins=""
            fi;;
      "6" ) echo "Do you want use aspell spellcheck engine instead on enchant [y/n] ?"
            read variable
            if [ "$variable" == "y" ]; then
              no_enchant="--disable-enchant"
            else
              no_enchant=""
            fi;;
      "7" ) echo "Please set psi+ sources path (absolute path, or \$HOME/path)"
            read variable
            if [ ! -z "${variable}" ]; then
              if [ "${variable:0:5}" == "\$HOME" ]; then
                buildpsi=${home}/${variable:6}
              else
                buildpsi=${variable}
              fi
            else
              buildpsi=${default_buildpsi}
            fi;;            
      "8" ) echo "==Options=="
            echo "WebKit = ${use_webkit}"
            echo "Iconsets = ${use_iconsets}"
            echo "Offline Mode = ${is_offline}"
            echo "Skip Invalid Patches = ${skip_patches}"
            echo "Plugins = ${use_plugins}"
            echo "No Enchant = ${noenchant}"
            echo "Psi+ sources path = ${buildpsi}"
            echo "===========";;
      "0" ) clear
            loop=0;;
    esac
  done
  echo "$iswebkit" > ${config_file}
  echo "$use_iconsets" >> ${config_file}
  echo "$isoffline" >> ${config_file}
  echo "$skip_invalid" >> ${config_file}
  if [ "$use_plugins" == "*" ]; then
    echo "all" >> ${config_file}
  else
    echo "$use_plugins" >> ${config_file}
  fi
  echo "$no_enchant" >> ${config_file}
  echo "$buildpsi" >> ${config_file}
  update_variables
}
#
print_menu ()
{
  local menu_text='Choose action TODO!
[1] - Download All needed source files to build psi+
[2] - Prepare psi+ sources
---[21] - Prepare psi+ source package to build in OS Windows
[3] - Build psi+ binary
---[31] - Build and install psi+ plugins
[4] - Build Debian package with checkinstall
[5] - Build openSUSE RPM-package
[6] - Set libpsibuild options
[7] - Prepare psi+ sources for development
[8] - Build otrplugin deb-package 
---[81] - Build otrplugin openSUSE RPM-package
[9] - Get help on additional actions
[0] - Exit'
  echo "${menu_text}"
}
#
get_help ()
{
  echo "---------------HELP-----------------------"
  echo "[ia] - Install all resources to $psi_datadir"
  echo "[ii] - Install iconsets to $psi_datadir"
  echo "[is] - Install skins to $psi_datadir"
  echo "[iz] - Install sounds to to $psi_datadir"
  echo "[it] - Install themes to $psi_datadir"
  echo "[il] - Install locales to $psi_datadir"
  echo "[bl] - Just build locale files without installing"
  echo "[ba] - Download all sources and build psi+ binary with plugins"
  echo "[ur] - Update resources"
  echo "[bs] - Backup ${buildpsi##*/} directory in ${buildpsi%/*}"
  echo "[pw] - Prepare psi+ workspace (clean ${buildpsi}/build dir)"
  echo "-------------------------------------------"
  echo "Press Enter to continue..."
  read
}
#
choose_action ()
{
  set_options
  read vibor
  case ${vibor} in
    "1" ) down_all;;
    "2" ) prepare_src;;
    "21" ) prepare_win;;
    "3" ) compile_psiplus;;
    "31" ) build_plugins;;
    "4" ) build_deb_package;;
    "5" ) build_rpm_package;;
    "6" ) set_config;;
    "7" ) prepare_dev;;
    "8" ) otr_deb;;
    "81" ) otr_rpm;;
    "9" ) get_help;;
    "ia" ) install_resources;;
    "ii" ) install_iconsets;;
    "is" ) install_skins;;
    "iz" ) install_sounds;;
    "it" ) install_themes;;
    "ur" ) update_resources;;
    "ba" ) compile_psiplus
           build_plugins;;
    "il" ) install_locales;;
    "bl" ) build_locales;;
    "bs" ) backup_tar;;
    "pw" ) run_libpsibuild prepare_workspace;;
    "cb" ) build_cmake_plugins;;
    "0" ) quit;;
  esac
}
#
cd ${workdir}
read_options
check_libpsibuild
if [ ! -f "${config_file}" ]; then
  set_config
fi
find_qconf
set_options
clear
#
while true; do
  print_menu
  choose_action
done
exit 0
