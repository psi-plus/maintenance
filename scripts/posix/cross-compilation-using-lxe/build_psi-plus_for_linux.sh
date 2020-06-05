#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2020-06-03
# Updated: 2020-06-05
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip
# Sibuserv: https://github.com/sibuserv/sibuserv
# LXE: https://github.com/sibuserv/lxe/tree/hobby

set -e

export MAIN_DIR="${HOME}/Tmp/Psi+"

CUR_DIR="$(dirname $(realpath -s ${0}))"
. "${CUR_DIR}/downloads_library.sh"
. "${CUR_DIR}/common_functions.sh"
. "${CUR_DIR}/dependencies_data.sh"

PROGRAM_NAME="psi-plus"
PROJECT_DIR_NAME="psi-plus-snapshots"
TRANSLATIONS_DIR_NAME="psi-plus-l10n"

README_FILE_NAME="README.txt"
README_URL="https://sourceforge.net/projects/psiplus/files/Linux/tehnick"

BUILD_TARGETS="Ubuntu-14.04_i386_shared Ubuntu-14.04_amd64_shared"
SUFFIX="linux"

BUILD_WITH_PSIMEDIA="false"

# Script body

SCRIPT_NAME="$(basename ${0})"
ShowHelp ${@}

TestInternetConnection
PrepareMainDir

echo "Getting the sources..."
echo;

GetPsiPlusSources ${@}
GetPsiPlusVersion ${@}
GetPsiPlusTranslations ${@}
GetMyspellDictionaries
GetReadMe

echo "Preparing to build..."
PrepareSourcesTree
PrepareToFirstBuildForLinux
CleanBuildDir
echo "Done."
echo;

echo "Building basic version of Psi+..."
BuildProjectUsingSibuserv
echo;

echo "Preparing to the next step..."
PrepareToSecondBuild
echo "Done."
echo;

echo "Building webkit version of Psi+..."
BuildProjectUsingSibuserv
echo;

echo "Installing..."
InstallToTmpDir
echo;

echo "Copying libraries and resources to..."
CopyLibsAndResources
echo;

echo "Copying the results to main directory..."
PrepareAppImageDirs
echo "Done."
echo;

echo "Compressing directories into 7z archives..."
CompressAppImageDirs
echo "Done."
echo;

echo "Builds are ready for distribution and usage!"

