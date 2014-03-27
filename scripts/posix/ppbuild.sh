#!/bin/bash
#CONSTANTS
home=/home/$USER
psi_version="0.16"
bindirs="/usr/bin
/usr/local/bin
${home}/bin
"
#VARIABLES
workdir=${home}
buildpsi=${workdir}/psi
orig_src=${buildpsi}/build
patches=${buildpsi}/git-plus/patches
psi_datadir=${home}/.local/share/psi+
psi_cachedir=${home}/.cache/psi+
psi_homeplugdir=${psi_datadir}/plugins
config_file=${home}/.config/psibuild.cfg
inst_suffix=tmp
inst_path=${buildpsi}/${inst_suffix}
plugbuild_log=${orig_src}/plugins.log
rpmbuilddir=${home}/rpmbuild
rpmspec=${rpmbuilddir}/SPECS
rpmsrc=${rpmbuilddir}/SOURCES
#DEFAULT OPTIONS
iswebkit=""
use_iconsets="system clients activities moods affiliations roster"
isoffline=0
skip_invalid=0
use_plugins="*"
#
qconfspath ()
{
  qconf_cmds="qconf
  qconf-qt4
  qt-qconf"
  for cmd_item in ${qconf_cmds}
  do
    for bin_path in ${bindirs}
    do
    if [ -f "${bin_path}/${cmd_item}" ]
    then
      echo "QConf utility found"
      qconfpath="cmd_item"
      echo "${bin_path}/${cmd_item}"
      break
    fi
    done
  done
  if [ -z "${qconfpath}" ]
  then
    echo "Enter the path to qconf binary (Example: /home/me/qconf):"
    read qconfpath
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
  if [ -f ${config_file} ]
  then
    inc=0
    while read -r line
    do
      case ${inc} in
      "0" ) iswebkit=`echo ${line}`;;
      "1" ) use_iconsets=`echo ${line}`;;
      "2" ) isoffline=`echo ${line}`;;
      "3" ) skip_invalid=`echo ${line}`;;
      "4" ) pluginlist=`echo ${line}`;;
      esac
      let "inc+=1"
    done < ${config_file}
    if [ "$pluginlist" == "all" ]
    then
      use_plugins="*"
    else
      use_plugins=${pluginlist}
    fi
  fi

}
#
set_options ()
{
  # OPTIONS / НАСТРОЙКИ
  # build and store directory / каталог для сорсов и сборки
  PSI_DIR="${buildpsi}" # leave empty for ${HOME}/psi on *nix or /c/psi on windows
  # icons for downloads / иконки для скачивания
  ICONSETS=${use_iconsets}
  # do not update anything from repositories until required
  # не обновлять ничего из репозиториев если нет необходимости
  WORK_OFFLINE=${WORK_OFFLINE:-$isoffline}
  # log of applying patches / лог применения патчей
  PATCH_LOG="" # PSI_DIR/psipatch.log by default (empty for default)
  # skip patches which applies with errors / пропускать глючные патчи
  SKIP_INVALID_PATCH="${SKIP_INVALID_PATCH:-$skip_invalid}"
  # configure options / опции скрипта configure
  CONF_OPTS=${iswebkit}
  # install root / каталог куда устанавливать (полезно для пакаджеров)
  INSTALL_ROOT="${INSTALL_ROOT:-$inst_path}"
  # bin directory of compiler cache (all compiler wrappers are there)
  CCACHE_BIN_DIR="${CCACHE_BIN_DIR}"
  # if system doesn't have qconf package set this variable to
  # manually compiled qconf directory.
  QCONFDIR="${QCONFDIR}"
  # plugins to build
  PLUGINS="${PLUGINS:-$use_plugins}"
}
#
check_libpsibuild ()
{
  # checkout libpsibuild
  libpsibuild_url="https://raw.github.com/psi-plus/maintenance/master/scripts/posix/libpsibuild.sh"
  die() { echo "$@"; exit 1; }
  cd ${workdir}
  if [ "$isoffline" = 0 ]
  then
    echo "**libpsibuild.sh library updates check**"; echo ""
    wget --output-document="libpsibuild.sh.new" --no-check-certificate ${libpsibuild_url};
    if [ "`diff -q libpsibuild.sh libpsibuild.sh.new`" ] || [ ! -f "${workdir}/libpsibuild.sh" ]
    then
      echo "**libpsibuild.sh library has been updated**"; echo ""
      mv -f ${workdir}/libpsibuild.sh.new ${workdir}/libpsibuild.sh
    else
      echo "**you have the last version of libpsibuild.sh library**"; echo ""  
      rm -f ${workdir}/libpsibuild.sh.new
    fi
  fi
}
#
run_libpsibuild ()
{
  if [ ! -z "$1" ]
  then
    cmd=$1
    cd ${workdir}
    . ./libpsibuild.sh
    check_env $CONF_OPTS
    $cmd
  fi
}
#
check_dir ()
{
  if [ ! -z "$1" ]
  then
    if [ ! -d "$1" ]
    then
      mkdir -pv "$1"
    fi
  fi
}
#
down_all ()
{
  echo "Downloading all psi+ sources needed to build"
  run_libpsibuild fetch_all
}
#
prepare_src ()
{
  echo "Downloading and preparing psi+ sources needed to build"
  set_options
  echo "Cleaning builddir and preparing workspace..."
  run_libpsibuild prepare_workspace
  run_libpsibuild fetch_all
  run_libpsibuild prepare_all
  echo "Do you want to apply psi-new-history.patch [y/n(default)]"
  read ispatch
  if [ "${ispatch}" == "y" ]
  then
    cd ${orig_src}
    patch -p1 < ${patches}/dev/psi-new-history.patch
    cd ${workdir}
  fi
}
#
backup_tar ()
{
  cd ${workdir}
  tar -pczf psi.tar.gz psi
}
#
prepare_tar ()
{
  check_dir ${rpmbuilddir}
  check_dir ${rpmsrc}
  check_dir ${rpmspec}
  echo "Preparing Psi+ source package to build RPM..."
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`)))
  tar_name=psi-plus-${psi_version}.${rev}
  new_src=${buildpsi}/${tar_name}
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]
  then
    cd ${buildpsi}
    tar -sczf ${tar_name}.tar.gz ${tar_name}
    rm -r -f ${new_src}
    if [ -d ${rpmsrc} ]
    then
      if [ -f "${rpmsrc}/${tar_name}.tar.gz" ]
      then
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
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`)))
  tar_name=psi-plus-${psi_version}.${rev}-win
  new_src=${buildpsi}/${tar_name}
  local mainicon=${buildpsi}/git-plus/app.ico
  local file_pro=${new_src}/src/src.pro
  local ver_file=${new_src}/version
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]
  then
    cd ${buildpsi}
    sed "s/#CONFIG += psi_plugins/CONFIG += psi_plugins/" -i "${file_pro}"
    sed "s/\(@@DATE@@\)/"`date +"%Y-%m-%d"`"/" -i "${ver_file}"
    cp -f ${mainicon} ${new_src}/win32/
    makepsi='@echo off
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
set MINGWDIR=%QTDIR32%\mingw
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
    rm -r -f ${new_src}
  fi
}
#
compile_psiplus ()
{
  set_options
  def_prefix="/usr"
  INSTALL_ROOT="${INSTALL_ROOT:-$def_prefix}"
  prepare_src
  run_libpsibuild compile_psi
}
#
qmakecmd ()
{
  if [ -f "/usr/bin/qmake" ] || [ -f "/usr/local/bin/qmake" ]
  then
    qmake
  else
    if [ -f "/usr/bin/qmake-qt4" ] || [ -f "/usr/local/bin/qmake-qt4" ]
    then
      qmake-qt4
    else
      echo "ERROR qmake not found"
    fi
  fi
}
#
build_plugins ()
{
  if [ ! -f "${orig_src}/psi.pro" ]
  then
    prepare_src
  fi
  tmpplugs=${orig_src}/plugins
  check_dir ${tmpplugs}
  plugins=`find ${orig_src}/src/plugins -name '*plugin.pro' -print0 | xargs -0 -n1 dirname`
  for pplugin in ${plugins}
  do
    make_plugin ${pplugin} 2>>${plugbuild_log}
  done
  echo "*******************************"
  echo "Plugins compiled succesfully!!!"
  echo "*******************************"
  echo "Do you want to install psi+ plugins into ${psi_homeplugdir} [y/n(default)]"
  read isinstall
  if [ "${isinstall}" == "y" ]
  then
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
  if [ ! -z "$1" ]
  then
    currdir=$(pwd)
    cd "$1"
    if [ -d "/usr/lib/ccache/bin" ] || [ -d "/usr/lib64/ccache/bin" ]
    then
      QMAKE_CCACHE_CMD="QMAKE_CXX=ccache g++"
    fi
    if [ ! -z "`ls .obj | grep -e '.o$'`" ]; then make && make distclean; fi
    qmakecmd -t ${QMAKE_CCACHE_CMD} && make && cp -f *.so ${tmpplugs}/
    cd ${currdir}
  fi
}
#
build_deb_package ()
{
  if [ ! -f "${orig_src}/psi.pro" ]
  then
    compile_psiplus
  fi
  echo "Building Psi+ DEB package with checkinstall"
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`)))
  desc='Psi is a cross-platform powerful Jabber client (Qt, C++) designed for the Jabber power users.
Psi+ - Psi IM Mod by psi-dev@conference.jabber.ru.'
  cd ${orig_src}
  echo "${desc}" > description-pak
  requires=' "libaspell15 (>=0.60)", "libc6 (>=2.7-1)", "libgcc1 (>=1:4.1.1)", "libqca2", "libqt4-dbus (>=4.4.3)", "libqt4-network (>=4.4.3)", "libqt4-qt3support (>=4.4.3)", "libqt4-xml (>=4.4.3)", "libqtcore4 (>=4.4.3)", "libqtgui4 (>=4.4.3)", "libstdc++6 (>=4.1.1)", "libx11-6", "libxext6", "libxss1", "zlib1g (>=1:1.1.4)" '
  sudo checkinstall -D --nodoc --pkgname=psi-plus --pkggroup=net --pkgversion=${psi_version}.${rev} --pkgsource=${orig_src} --maintainer="thetvg@gmail.com" --requires="${requires}"
  cp -f ${orig_src}/*.deb ${buildpsi}
}
#
prepare_spec ()
{
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`)))
  if [ ! -z ${iswebkit} ]
  then
    webkit="--enable-webkit"
  fi
  qconfspath
  if [ ! -z ${qconfpath} ]
  then
    qconfcmd=${qconfpath}
  fi
  echo "Creating psi.spec file..."
  specfile="Summary: Client application for the Jabber network
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
  tmp_spec=${buildpsi}/test.spec
  usr_spec=${rpmspec}/psi-plus.spec
  echo "${specfile}" > ${tmp_spec}
  cp -f ${tmp_spec} ${usr_spec}
}
#
build_rpm_package ()
{
  prepare_src
  prepare_tar
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`)))
  tar_name=psi-plus-${psi_version}.${rev}
  sources=${rpmsrc}
  if [ -f "${sources}/${tar_name}.tar.gz" ]
  then
    prepare_spec
    echo "Building Psi+ RPM package"
    cd ${rpmspec}
    rpmbuild -ba --clean --rmspec --rmsource ${usr_spec}
    rpm_ready=`find $HOME/rpmbuild/RPMS | grep psi-plus`
    rpm_src_ready=`find $HOME/rpmbuild/SRPMS | grep psi-plus`
    cp -f ${rpm_ready} ${buildpsi}
    cp -f ${rpm_src_ready} ${buildpsi}
  fi
}
#
prepare_dev ()
{
  psidev=$buildpsi/psidev
  orig=$psidev/git.orig
  new=$psidev/git
  rm -rf $orig
  rm -rf $new
  cd ${buildpsi}
  echo ${psidev}
  check_dir ${psidev}
  check_dir ${orig}
  check_dir ${new}
  cp -r git/* ${orig}
  cp -r git/* ${new}
  cd ${psidev}
  if [ ! -f deploy ]
  then
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/deploy" || die "Failed to update deploy";
  fi
  if [ ! -f mkpatch ]
  then
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/mkpatch" || die "Failed to update mkpatch";
  fi
  if [ ! -f psidiff.ignore ]
  then
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/psidiff.ignore" || die "Failed to update psidiff.ignore";
  fi
  patchlist=`ls ${buildpsi}/git-plus/patches/ | grep diff`
  cd ${orig}
  echo "Enter maximum patch number to patch orig src"
  read patchnumber
  for patchfile in ${patchlist}
    do
      if [  ${patchfile:0:4} -lt ${patchnumber} ]
      then
        echo  ${patchfile}
        patch -p1 < ${buildpsi}/git-plus/patches/${patchfile}
      fi
  done
  cd ${new}
  echo "Enter maximum patch number to patch work src"
  read patchnumber
  for patchfile in ${patchlist}
    do
      if [  ${patchfile:0:4} -lt ${patchnumber} ]
      then
        echo  ${patchfile}
        patch -p1 < ${buildpsi}/git-plus/patches/${patchfile}
      fi
  done
}
#
otr_deb ()
{
  prepare_src
  cd $buildpsi
  if [ -d $buildpsi/plugins/dev/otrplugin ]
  then
    cd $buildpsi/plugins
    git pull
  else
    git clone git://github.com/psi-plus/plugins.git
  fi
  otrorigdir=$buildpsi/plugins/dev/otrplugin
  cd $buildpsi/plugins/dev
  cp -r $otrorigdir $orig_src/src/plugins/generic
  otrdebdir=$orig_src/src/plugins/generic/otrplugin
  cd $otrdebdir
  PREFIX=/usr
  user="Vitaly Tonkacheyev"
  email="thetvg@gmail.com"
  data=`LANG=en date +'%a, %d %b %Y %T %z'`
  year=`date +'%Y'`
  cd $otrdebdir
  debver=`grep -Po '\d\.\d\.\d+' src/psiotrplugin.cpp`
#
  control='Source: psi-plus-otrplugin
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
  copyright="This work was packaged for Debian by:

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
  dirs='usr/lib/psi-plus/plugins'
  compat='7'
  rules='#!/usr/bin/make -f
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
  package_sh="#!/bin/bash
set -e

debuild -us -uc
debuild -S -us -uc
su -c pbuilder build ../psi-plus-otrplugin-${debver}.dsc"
  changelog_template="psi-plus-otrplugin (${debver}-1) unstable; urgency=low

  * New upstream release see README for details

 -- ${user} <${email}>  ${data}"
  docs='COPYING
INSTALL
README'
#
  builddeb=$orig_src/src/plugins/generic/psi-plus-otrplugin-${debver}
  if [ -d ${builddeb} ]
  then
    rm -r -f ${builddeb}
  fi
  mkdir ${builddeb}
  cp -r ${otrdebdir}/* ${builddeb}
  mkdir ${builddeb}/debian
  changefile=${builddeb}/debian/changelog
  rulesfile=${builddeb}/debian/rules
  controlfile=${builddeb}/debian/control
  dirsfile=${builddeb}/debian/dirs
  compatfile=${builddeb}/debian/compat
  copyrightfile=${builddeb}/debian/copyright
  docsfile=${builddeb}/debian/docs
  package_sh_file=${builddeb}/package.sh
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
  qmake
  dpkg-buildpackage -rfakeroot
  cp -f ../psi-plus-otrplugin_${debver}*.deb $buildpsi
}
#
prepare_plugins_spec ()
{
  specfile="
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
  progname="psi-plus-otrplugin"
  prepare_src
  cd $buildpsi
  if [ -d $buildpsi/plugins/dev/otrplugin ]
  then
    cd $buildpsi/plugins
    git pull
  else
    git clone git://github.com/psi-plus/plugins.git
  fi
  cd $buildpsi
  #
  otrorigdir=$buildpsi/plugins/dev/otrplugin
  PREFIX="/usr"
  rpmver=`grep -Po '\d\.\d\.\d+' ${otrorigdir}/src/psiotrplugin.cpp`
  package_name="${progname}-${rpmver}.tar.gz"
  summary="Off-The-Record-Messaging plugin for Psi"
  breq="libotr-devel, libtidy-devel, libgcrypt-devel"
  urlpath="https://github.com/psi-plus/plugins"
  group="Applications/Internet"
  desc="This is a Off-The-Record-Messaging plugin for the Psi+ instant messenger.
 Psi+ (aka Psi-dev) is a collection of patches for Psi. Psi+ is available from
 http://code.google.com/p/psi-dev/"
  plugdir="dev/otrplugin"
  libfile="libotrplugin.so"
  docfiles="%doc $plugdir/README $plugdir/COPYING"
  #
  check_dir ${inst_path}/${progname}-${rpmver}/dev/otrplugin
  cp -r $orig_src/src/plugins/*.pri ${inst_path}/${progname}-${rpmver}/
  cp -r $orig_src/src/plugins/include ${inst_path}/${progname}-${rpmver}/
  cp -r $otrorigdir/* ${inst_path}/${progname}-${rpmver}/dev/otrplugin/
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
  if [ ! -d "resources" ]
  then
    get_resources
  fi
  cp -rf ${buildpsi}/resources/* ${psi_datadir}/
}
#
install_iconsets ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ -d "resources" ]
  then
    get_resources
  fi  
  cp -rf ${buildpsi}/resources/iconsets ${psi_datadir}/
}
#
install_skins ()
{
  cd ${buildpsi}
  check_dir ${psi_datadir}
  if [ -d "resources" ]
  then
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
  if [ -d "resources" ]
  then
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
  if [ -d "resources" ]
  then
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
  if [ -d "${tr_path}" ]
  then
    rm -f ${tr_path}/*.qm
    if [ -f "/usr/bin/lrelease" ] || [ -f "/usr/local/bin/lrelease" ]
    then
      lrelease ${tr_path}/*.ts 
    fi
    if [ -f "/usr/bin/lrelease-qt4" ] || [ -f "/usr/local/bin/lrelease-qt4" ]
    then
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
  if [ ! -z "$iswebkit" ]
  then
    use_webkit="y"
  else
    use_webkit="n"
  fi
  local is_offline="n"
  if [ "$isoffline" -eq 0 ]
  then
    is_offline="n"
  else
    is_offline="y"
  fi
  local skip_patches="n"
  if [ "$skip_invalid" -eq 0 ]
  then
    skip_patches="n"
  else
    skip_patches="y"
  fi
  local loop=1
  while [ ${loop} = 1 ]
  do
    echo "Choose action TODO:"
    echo "--[1] - Set WebKit version to use (current: ${use_webkit})"
    echo "--[2] - Set iconsets list needed to build"
    echo "--[3] - Set Offline Mode (current: ${is_offline})"
    echo "--[4] - Skip Invalid patches (current: ${skip_patches})"
    echo "--[5] - Set list of plugins needed to build (for all use *)"
    echo "--[6] - Print option values"
    echo "--[0] - Do nothing"
    read deistvo
    case ${deistvo} in
      "1" ) echo "Do you want use WebKit [y/n] ?"
            read variable
            if [ "$variable" == "y" ]
            then
              iswebkit="--enable-webkit"
              use_webkit="y"
            else
              iswebkit=""
              use_webkit="n"
            fi;;
      "2" ) echo "Please enter iconsets separated by space"
            read variable
            if [ ! -z "$variable" ]
            then
              use_iconsets=${variable}
            else
              use_iconsets="system clients activities moods affiliations roster"
            fi;;
      "3" ) echo "Do you want use Offline Mode [y/n] ?"
            read variable
            if [ "$variable" == "y" ]
            then
              isoffline=1
              is_offline="y"
            else
              isoffline=0
              is_offline="n"
            fi;;
      "4" ) echo "Do you want to skip invalid patches when patching [y/n] ?"
            read variable
            if [ "$variable" == "y" ]
            then
              skip_invalid=1
              skip_patches="y"
            else
              skip_invalid=0
              skip_patches="n"
            fi;;
      "5" ) echo "Please enter plugins needed to build separated by space (* for all)"
            read variable
            if [ ! -z "$variable" ]
            then
              use_plugins=${variable}
            else
              use_plugins=""
            fi;;
      "6" ) echo "==Options=="
            echo "WebKit = ${use_webkit}"
            echo "Iconsets = ${use_iconsets}"
            echo "Offline Mode = ${is_offline}"
            echo "Skip Invalid Patches = ${skip_patches}"
            echo "Plugins = ${use_plugins}"
            echo "===========";;
      "0" ) clear
            loop=0;;
    esac
  done
  echo "$iswebkit" > ${config_file}
  echo "$use_iconsets" >> ${config_file}
  echo "$isoffline" >> ${config_file}
  echo "$skip_invalid" >> ${config_file}
  if [ "$use_plugins" == "*" ]
  then
    echo "all" >> ${config_file}
  else
    echo "$use_plugins" >> ${config_file}
  fi
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
  echo "[ia] - Install all resources to $HOME/.local/share/psi+"
  echo "[ii] - Install iconsets to $HOME/.local/share/psi+"
  echo "[is] - Install skins to $HOME/.local/share/psi+"
  echo "[iz] - Install sounds to to $HOME/.local/share/psi+"
  echo "[it] - Install themes to $HOME/.local/share/psi+"
  echo "[il] - Install locales to $HOME/.local/share/psi+"
  echo "[bl] - Just build locale files without installing"
  echo "[ba] - Download all sources and build psi+ binary with plugins"
  echo "[ur] - Update resources"
  echo "-------------------------------------------"
  echo "Press Enter to continue..."
  read
}
#
choose_action ()
{
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
    "0" ) quit;;
  esac
}
#
cd ${workdir}
read_options
check_libpsibuild
if [ ! -f "${config_file}" ]
then
  set_config
fi
set_options
clear
#
while true
do
  print_menu
  choose_action
done
exit 0
