#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2017-07-14
# Updated: 2019-02-27
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip
# Sibuserv: https://github.com/sibuserv/sibuserv
# MXE: https://github.com/sibuserv/mxe/tree/hobby

set -e

export MAIN_DIR="${HOME}/Tmp/Psi"

CUR_DIR="$(dirname $(realpath -s ${0}))"
. "${CUR_DIR}/downloads_library.sh"
. "${CUR_DIR}/common_functions.sh"

PROJECT_DIR_NAME="psi"
TRANSLATIONS_DIR_NAME="psi-l10n"

README_FILE_NAME="README.txt"
README_URL="https://sourceforge.net/projects/psi/files/Experimental-Builds/Windows/tehnick"

BUILD_TARGETS="i686-w64-mingw32.shared"
SUFFIX="winxp"

# Script body

SCRIPT_NAME="$(basename ${0})"
ShowHelp ${@}

TestInternetConnection
PrepareMainDir

echo "Getting the sources..."
echo;

GetPsiSources ${@}
GetPsiVersion ${@}
GetPluginsSources ${@}
GetPsiTranslations ${@}
GetMyspellDictionaries
GetReadMe

echo "Preparing to build..."
PrepareSourcesTree
CopyPluginsToSourcesTree
PrepareToFirstBuild
cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
sed -i "s|option( USE_QJDNS .*$|option( USE_QJDNS \"\" ON )|g" CMakeLists.txt
echo "Done."
echo;

echo "Building basic version of Psi with plugins..."
BuildProjectForWindows
echo;

echo "Preparing to the next step..."
PrepareToSecondBuild
echo "Done."
echo;

echo "Building webkit version of Psi without plugins..."
BuildProjectForWindows
echo;

echo "Copying libraries and resources to..."
CopyLibsAndResources
echo;

echo "Copying the results to main directory..."
CopyFinalResults
echo "Done."
echo;

echo "Compressing directories into 7z archives..."
CompressDirs
echo "Done."
echo;

echo "Builds are ready for distribution and usage!"

