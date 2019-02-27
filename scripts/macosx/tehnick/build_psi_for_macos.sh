#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2018-12-19
# Updated: 2019-02-27
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
echo;

echo "Preparing to the next step..."
ENABLE_WEBENGINE="ON"
echo "Done."
echo;

echo "Building webengine version of Psi..."
BuildProjectForMacOS
echo;

echo "Checking macOS app bundles in main directory..."
RenamePsiAppBundles ${@}
ls -alp Psi-${VERSION}*.dmg
du -shc Psi-${VERSION}*.dmg
echo "Done."
echo;

echo "Builds are ready for distribution and usage!"

