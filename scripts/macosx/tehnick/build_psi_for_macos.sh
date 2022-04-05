#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2018-12-19
# Updated: 2022-04-05
# Version: N/A
#
# Dependencies:
# See: https://github.com/psi-im/psi/blob/master/mac/build-using-homebrew.sh

set -e

export MAIN_DIR="${HOME}/Hobby/Psi+"

CUR_DIR="$(dirname $(realpath -s ${0}))"
. "${CUR_DIR}/downloads_library.sh"
. "${CUR_DIR}/common_functions.sh"

PROJECT_DIR_NAME="psi"
TRANSLATIONS_DIR_NAME="psi-l10n"
QT_SDK_VER="$(ls ${HOME}/Qt/ 2>/dev/null | grep '5.' | tail -n1)"

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

echo "Preparing to build..."
PrepareSourcesTree
CopyPluginsToSourcesTree
CleanBuildDir
echo "Done."
echo;

echo "Building basic version of Psi..."
BuildProjectForMacOS
echo "Done."
echo;

echo "Preparing to the next step..."
export CHAT_TYPE="webengine"
CleanBuildDir
echo "Done."
echo;

echo "Building webengine version of Psi..."
BuildProjectForMacOS
echo "Done."
echo;

echo "Checking macOS app bundles in main directory..."
RenamePsiAppBundles ${@}
cd "${MAIN_DIR}"
ls -alp Psi-${VERSION}*.dmg
du -shc Psi-${VERSION}*.dmg
echo "Done."
echo;

echo "Builds are ready for distribution and usage!"

