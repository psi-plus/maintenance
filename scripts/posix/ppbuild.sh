#!/bin/bash
home=/home/$USER
buildpsi=${home}/psi
orig_src=${buildpsi}/build
patches=${buildpsi}/git-plus/patches
psi_datadir=${home}/.local/share/Psi+
psi_cachedir=${home}/.cache/Psi+
psi_homeplugdir=${psi_datadir}/plugins
config_file=${home}/.psibuild.cfg
inst_suffix=tmp
inst_path=${buildpsi}/${inst_suffix}
rpmbuilddir=${home}/rpmbuild
rpmspec=${rpmbuilddir}/SPECS
rpmsrc=${rpmbuilddir}/SOURCES
isloop=1
# default options
iswebkit=""
use_iconsets="system clients activities moods affiliations roster"
isoffline=0
skip_invalid=0
use_plugins="*"
#
qconfspath ()
{
  if [ ! -f "/usr/bin/qconf" ]
  then
    if [ ! -f "/usr/local/bin/qconf" ]
      then
        echo "Enter the path to qconf directory (Example: /home/me/qconf):"
        read qconfpath
    fi
  fi
}
#
quit ()
{
  isloop=0
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
  cd ${home}
  die() { echo "$@"; exit 1; }
  if [ ! -f ./libpsibuild.sh -o "$WORK_OFFLINE" = 0 ]
  then
    [ -f libpsibuild.sh ] && { rm libpsibuild.sh || die "delete error"; }
    wget --no-check-certificate "https://raw.github.com/psi-plus/maintenance/master/scripts/posix/libpsibuild.sh" || die "Failed to update libpsibuild";
  fi
}
#
run_libpsibuild ()
{
  if [ ! -z "$1" ]
  then
    cmd=$1
    cd ${home}
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
  run_libpsibuild validate_plugins_list
  run_libpsibuild fetch_all
  run_libpsibuild prepare_all
}
#
backup_tar ()
{
  cd ${home}
  tar -pczf psi.tar.gz psi
}
#
prepare_tar ()
{
  check_dir ${rpmbuilddir}
  check_dir ${rpmsrc}
  check_dir ${rpmspec}
  echo "Preparing Psi+ source package to build RPM..."
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  tar_name=psi-plus-0.15.${rev}
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
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  tar_name=psi-plus-0.15.${rev}-win
  new_src=${buildpsi}/${tar_name}
  local winpri=${new_src}/conf_windows.pri
  local mainicon=${buildpsi}/git-plus/app.ico
  local file_pro=${new_src}/src/src.pro
  local ossl=${new_src}/third-party/qca/qca-ossl.pri
  cp -r ${orig_src} ${new_src}
  if [ -d ${new_src} ]
  then
    cd ${buildpsi}
    sed "s/#CONFIG += qca-static/CONFIG += qca-static\nCONFIG += webkit/" -i "${winpri}"
    sed "s/#DEFINES += HAVE_ASPELL/DEFINES += HAVE_ASPELL/" -i "${winpri}"
    sed "s/LIBS += -lgdi32 -lwsock32/LIBS += -lgdi32 -lwsock32 -leay32/" -i "${ossl}"
    sed "s/#CONFIG += psi_plugins/CONFIG += psi_plugins/" -i "${file_pro}"
    cp -f ${mainicon} ${new_src}/win32/
    makepsi='set QMAKESPEC=win32-g++
:: Paste to QTSDK variable your Qt SDK path
set QTSDK=C:\QtSDK
::
set QTDIR=%QTSDK%\Desktop\Qt\4.8.1\mingw
set PATH=%PATH%;%QTSDK%\Desktop\Qt\4.8.1\mingw\bin
set ZLIBDIR=%QTSDK%\zlib-1.2.6-win\i386
set OPENSSLDIR=%QTSDK%\OpenSSL
set CCACHE_DIR=%QTSDK%\ccache
set MINGWDIR=%QTSDK%\mingw
set QCONFDIR=%QTSDK%\QConf
set PLUGBUILDDIR=%QTSDK%\PBuilder
set MAKE=%MINGWDIR%\bin\mingw32-make -j3
%QCONFDIR%\qconf
configure --enable-plugins --enable-whiteboarding --qtdir=%QTDIR% --with-zlib-inc=%ZLIBDIR%\include --with-zlib-lib=%ZLIBDIR%\lib --with-openssl-inc=%OPENSSLDIR%\include --with-openssl-lib=%OPENSSLDIR%\lib\MinGW --disable-xss --disable-qdbus --with-aspell-inc=%MINGWDIR%\include --with-aspell-lib=%MINGWDIR%\lib
pause
@echo Runing mingw32-make
%MINGWDIR%\bin\mingw32-make -j3
pause
copy /Y src\release\psi-plus.exe ..\psi-plus-portable.exe
move /Y src\release\psi-plus.exe ..\psi-plus.exe
pause
%PLUGBUILDDIR%\compile-plugins -j 3 -o ..\
pause
@goto exit

:exit
pause'
    makewebkitpsi='set QMAKESPEC=win32-g++
:: Paste to QTSDK variable your Qt SDK path 
set QTSDK=C:\QtSDK
::
set QTDIR=%QTSDK%\Desktop\Qt\4.8.1\mingw
set PATH=%PATH%;%QTSDK%\Desktop\Qt\4.8.1\mingw\bin
set ZLIBDIR=%QTSDK%\zlib-1.2.6-win\i386
set OPENSSLDIR=%QTSDK%\OpenSSL
set CCACHE_DIR=%QTSDK%\ccache
set MINGWDIR=%QTSDK%\mingw
set QCONFDIR=%QTSDK%\QConf
set PLUGBUILDDIR=%QTSDK%\PBuilder
set MAKE=%MINGWDIR%\bin\mingw32-make -j3
%QCONFDIR%\qconf
configure --enable-plugins --enable-whiteboarding --enable-webkit --qtdir=%QTDIR% --with-zlib-inc=%ZLIBDIR%\include --with-zlib-lib=%ZLIBDIR%\lib --with-openssl-inc=%OPENSSLDIR%\include --with-openssl-lib=%OPENSSLDIR%\lib\MinGW --disable-xss --disable-qdbus --with-aspell-inc=%MINGWDIR%\include --with-aspell-lib=%MINGWDIR%\lib
pause
@echo Runing mingw32-make
%MINGWDIR%\bin\mingw32-make -j3
pause
copy /Y src\release\psi-plus.exe ..\psi-plus-portable.exe
move /Y src\release\psi-plus.exe ..\psi-plus.exe
pause
%PLUGBUILDDIR%\compile-plugins -j 3 -o ..\
pause
@goto exit

:exit
pause'
    echo "${makepsi}" > ${new_src}/make-psiplus.cmd
    echo "${makewebkitpsi}" > ${new_src}/make-webkit-psiplus.cmd
    tar -pczf ${tar_name}.tar.gz ${tar_name}
    rm -r -f ${new_src}
  fi
}
#
compile_psiplus ()
{
  set_options
  run_libpsibuild prepare_workspace
  prepare_src
  run_libpsibuild compile_psi
}
#
build_plugins ()
{
  cd ${buildpsi}
  run_libpsibuild prepare_workspace
  prepare_src
  check_dir ${inst_path}  
  run_libpsibuild compile_plugins
  run_libpsibuild install_plugins
  if [ ! -d ${psi_homeplugdir} ]
  then
    cd ${psi_datadir}
    mkdir plugins
  fi
  cp ${inst_path}/usr/lib/psi-plus/plugins/* ${psi_homeplugdir}
  rm -rf ${inst_path}
  cd ${home}
}
#
build_deb_package ()
{
  echo "Building Psi+ DEB package with checkinstall"
  cd ${patches}
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  desc='Psi is a cross-platform powerful Jabber client (Qt, C++) designed for the Jabber power users.
Psi+ - Psi IM Mod by psi-dev@conference.jabber.ru.'
  cd ${orig_src}
  echo "${desc}" > description-pak
  requires=' "libaspell15 (>=0.60)", "libc6 (>=2.7-1)", "libgcc1 (>=1:4.1.1)", "libqca2", "libqt4-dbus (>=4.4.3)", "libqt4-network (>=4.4.3)", "libqt4-qt3support (>=4.4.3)", "libqt4-xml (>=4.4.3)", "libqtcore4 (>=4.4.3)", "libqtgui4 (>=4.4.3)", "libstdc++6 (>=4.1.1)", "libx11-6", "libxext6", "libxss1", "zlib1g (>=1:1.1.4)" '
  sudo checkinstall -D --nodoc --pkgname=psi-plus --pkggroup=net --pkgversion=0.15.${rev} --pkgsource=${orig_src} --maintainer="thetvg@gmail.com" --requires="${requires}"
  cp -f ${orig_src}/*.deb ${buildpsi}
}
#
prepare_spec ()
{
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  if [ ! -z ${iswebkit} ]
  then
    webkit="--enable-webkit"
  fi
  qconfspath
  if [ ! -z ${qconfpath} ]
  then
    qconfcmd=${qconfpath}/qconf
  else
    qconfcmd="qconf"
  fi
  echo "Creating psi.spec file..."
  specfile="Summary: Client application for the Jabber network
Name: psi-plus
Version: 0.15.${rev}
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
  rev=$(cd ${buildpsi}/git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
  tar_name=psi-plus-0.15.${rev}
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
  if [ -d "resources" ]
  then
    cp -rf ${buildpsi}/resources/* ${psi_datadir}/ 
  else
    get_resources
  fi
}
#
install_iconsets ()
{
  cd ${buildpsi}
  if [ -d "resources" ]
  then
    cp -rf ${buildpsi}/resources/iconsets ${psi_datadir}/
  else
    get_resources
  fi  
}
#
install_skins ()
{
  cd ${buildpsi}
  if [ -d "resources" ]
  then
    cp -rf ${buildpsi}/resources/skins ${psi_datadir}/
  else
    get_resources
  fi 
}
#
install_sounds ()
{
  cd ${buildpsi}
  if [ -d "resources" ]
  then
    cp -rf ${buildpsi}/resources/sound ${psi_datadir}/
  else
    get_resources
  fi 
}
#
install_themes ()
{
  cd ${buildpsi}
  if [ -d "resources" ]
  then
    cp -rf ${buildpsi}/resources/themes ${psi_datadir}/
  else
    get_resources
  fi 
}
#
update_resources ()
{
  cd ${buildpsi}/resources
  git pull
}
#
install_locales ()
{
  cd ${buildpsi}
  run_libpsibuild fetch_sources
  if [ -d "langs" ]
  then
    lrelease "${buildpsi}/langs/ru/psi_ru.ts"
    lrelease "${buildpsi}/langs/ru/qt/qt_ru.ts"
    cp -rf ${buildpsi}/langs/ru/psi_ru.qm ${psi_datadir}/
    cp -rf ${buildpsi}/langs/ru/qt/qt_ru.qm ${psi_datadir}/
  fi 
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
  echo "[ia] - Install all resources to $HOME/.local/share/Psi+"
  echo "[ii] - Install iconsets to $HOME/.local/share/Psi+"
  echo "[is] - Install skins to $HOME/.local/share/Psi+"
  echo "[iz] - Install sounds to to $HOME/.local/share/Psi+"
  echo "[it] - Install themes to $HOME/.local/share/Psi+"
  echo "[il] - Install locales to $HOME/.local/share/Psi+"
  echo "[ur] - Update resources"
  echo "[up] - Download all sources and build psi+ binary"
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
    "up" ) prepare_src
              compile_psiplus;;
    "il" ) install_locales;;
    "0" ) quit;;
  esac
}
#
cd ${home}
check_libpsibuild
if [ ! -f "${config_file}" ]
then
  set_config
fi
read_options
set_options
echo "Cleaning builddir and preparing workspace..."
run_libpsibuild prepare_workspace
clear
#
while [ ${isloop} = 1 ]
do
  print_menu
  choose_action
done
exit 0
