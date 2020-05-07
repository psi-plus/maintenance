#!/bin/bash

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2018-03-20
# Updated: 2020-05-07
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip
# Sibuserv: https://github.com/sibuserv/sibuserv
# MXE: https://github.com/sibuserv/mxe/tree/hobby

set -e

export MAIN_DIR="${HOME}/Tmp/PsiMedia"

CUR_DIR="$(dirname $(realpath -s ${0}))"
. "${CUR_DIR}/downloads_library.sh"
. "${CUR_DIR}/common_functions.sh"

PROJECT_DIR_NAME="psimedia"

BUILD_TARGETS="i686-w64-mingw32.shared x86_64-w64-mingw32.shared"
VERSION="x.y.z-n"

INS_SUBDIR="-out/usr"

# libgstbadbase-1.0-0.dll

LIBS="
    libbz2.dll
    libffi-6.dll
    libfontconfig-1.dll
    libfreetype-6.dll
    libgio-2.0-0.dll
    libglib-2.0-0.dll
    libgmodule-2.0-0.dll
    libgobject-2.0-0.dll
    libgstapp-1.0-0.dll
    libgstaudio-1.0-0.dll
    libgstbadaudio-1.0-0.dll
    libgstbase-1.0-0.dll
    libgstnet-1.0-0.dll
    libgstpbutils-1.0-0.dll
    libgstreamer-1.0-0.dll
    libgstriff-1.0-0.dll
    libgstrtp-1.0-0.dll
    libgsttag-1.0-0.dll
    libgstvideo-1.0-0.dll
    libgthread-2.0-0.dll
    libharfbuzz-0.dll
    libiconv-2.dll
    libintl-8.dll
    libjpeg-9.dll
    libogg-0.dll
    libopus-0.dll
    libpcre16-0.dll
    libpcre-1.dll
    libpcre2-16-0.dll
    libpng16-16.dll
    libspeex-1.dll
    libstdc++-6.dll
    libtheora-0.dll
    libtheoradec-1.dll
    libtheoraenc-1.dll
    libvorbis-0.dll
    libvorbisenc-2.dll
    libwinpthread-1.dll
    libzstd.dll
    zlib1.dll
"

I686_LIBS="
    libcrypto-1_1.dll
    libgcc_s_sjlj-1.dll
    libssl-1_1.dll
"

X86_64_LIBS="
    libcrypto-1_1-x64.dll
    libgcc_s_seh-1.dll
    libssl-1_1-x64.dll
"

QT_LIBS="
    Qt5Core.dll
    Qt5Gui.dll
    Qt5Network.dll
    Qt5Svg.dll
    Qt5Widgets.dll
"

QT_PLUGINS_DIRS="
    imageformats
    platforms
"


PLUGINS="
    libgstapp.dll
    libgstaudioconvert.dll
    libgstaudiomixer.dll
    libgstaudioresample.dll
    libgstcoreelements.dll
    libgstdirectsoundsrc.dll
    libgstogg.dll
    libgstopus.dll
    libgstopusparse.dll
    libgstplayback.dll
    libgsttheora.dll
    libgstvideoconvert.dll
    libgstvideorate.dll
    libgstvideoscale.dll
    libgstvolume.dll
    libgstvorbis.dll
    libgstwasapi.dll
    libgstwinks.dll
    libgstspeed.dll
    libgstspeex.dll
    libgstdirectsoundsink.dll
    libgstjpeg.dll
    libgstlevel.dll
    libgstrtp.dll
    libgstrtpmanager.dll
"

# Extra functions

InstallPsimediaToTmpDir()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${BUILD_TARGETS}" ] && return 1

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    build-project install ${BUILD_TARGETS}
    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    for DIR in ${BUILD_TARGETS} ; do
        cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}-out"
        cp -a ./usr/plugins/libgstprovider.dll ./usr/
    done
}

CopyLibsAndResources()
{
    . /etc/sibuserv/sibuserv.conf
    . ${HOME}/.config/sibuserv/sibuserv.conf || true

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    BUILD_DIR="${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    for TARGET in ${BUILD_TARGETS} ; do
        BIN_DIR="${BUILD_DIR}/${TARGET}${INS_SUBDIR}"
        echo "${BIN_DIR}"
        cd   "${BIN_DIR}"

        for LIB in ${LIBS} ; do
            cp -a "${MXE_DIR}/usr/${TARGET}/bin/${LIB}" ./
        done

        if [ "${TARGET}" = "i686-w64-mingw32.shared" ] ; then
            ARCH_SPEC_LIBS="${I686_LIBS}"
        else
            ARCH_SPEC_LIBS="${X86_64_LIBS}"
        fi

        for ARCH_SPEC_LIB in ${ARCH_SPEC_LIBS}
        do
            cp -a "${MXE_DIR}/usr/${TARGET}/bin/${ARCH_SPEC_LIB}" ./
        done

        for QT_LIB in ${QT_LIBS} ; do
            cp -a "${MXE_DIR}/usr/${TARGET}/qt5/bin/${QT_LIB}" ./
        done

        for QT_PLUGINS_DIR in ${QT_PLUGINS_DIRS} ; do
            cp -a "${MXE_DIR}/usr/${TARGET}/qt5/plugins/${QT_PLUGINS_DIR}" ./
        done

        mkdir -p "${BIN_DIR}/lib/gstreamer-1.0"
        cd "${BIN_DIR}/lib/gstreamer-1.0"

        for PLUGIN in ${PLUGINS} ; do
            cp -a "${MXE_DIR}/usr/${TARGET}/bin/gstreamer-1.0/${PLUGIN}" ./ || true
        done
    done
}

# Script body

TestInternetConnection
PrepareMainDir

echo "Getting the sources..."
echo;

GetPsiSources
GetPsimediaSources
GetPsimediaVersion

cd "${MAIN_DIR}"
echo "Preparing to build..."
CleanBuildDir
echo "Done."
echo;

echo "Building..."
BuildProjectForWindows
echo;

echo "Installing..."
InstallPsimediaToTmpDir
echo;

echo "Copying libraries and resources to..."
CopyLibsAndResources
echo;

echo "Copying the results to main directory..."
CopyFinalResults
echo "Done."
echo;

echo "Compressing files into 7z archives..."
CompressDirs
echo "Done."
echo;

echo "Builds are ready for distribution and usage!"

