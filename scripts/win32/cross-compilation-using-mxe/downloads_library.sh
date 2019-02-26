#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2018-12-19
# Updated: 2019-02-26
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip

set -e

PSI_PLUS_DIR_NAME="psi-plus-snapshots"
PSI_PLUS_TRANSLATIONS_DIR_NAME="psi-plus-l10n"
DICTIONARIES_DIR_NAME="myspell"

PSI_PLUS_URL="https://github.com/psi-plus/psi-plus-snapshots.git"
PSI_PLUS_TRANSLATIONS_URL="https://github.com/psi-plus/psi-plus-l10n.git"
DICTIONARIES_URL="https://deb.debian.org/debian/pool/main/libr/libreoffice-dictionaries"
README_URL="https://sourceforge.net/projects/psiplus/files/Windows/Personal-Builds/tehnick"

ARCHIVER_OPTIONS="a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on"

TestInternetConnection()
{
    echo "Checking Internet connection..."
    host github.com 2>&1 > /dev/null && return 0 || return 1
    echo "Done."
    echo;
}


GetPsiPlusSources()
{
    [ -z "${MAIN_DIR}" ] && return 1
    cd "${MAIN_DIR}"

    MOD="${PSI_PLUS_DIR_NAME}"
    URL="${PSI_PLUS_URL}"
    if [ -d "${MAIN_DIR}/${MOD}" ]; then
        echo "Updating ${MAIN_DIR}/${MOD}"
        cd "${MAIN_DIR}/${MOD}"
        git checkout .
        git checkout master
        git pull --all --prune -f
        echo;
    else
        echo "Creating ${MAIN_DIR}/${MOD}"
        cd "${MAIN_DIR}"
        git clone "${URL}"
        cd "${MAIN_DIR}/${MOD}"
        git checkout master
        echo;
    fi
}

GetPsiPlusTranslations()
{
    [ -z "${MAIN_DIR}" ] && return 1
    cd "${MAIN_DIR}"

    MOD="${PSI_PLUS_TRANSLATIONS_DIR_NAME}"
    URL="${PSI_PLUS_TRANSLATIONS_URL}"
    if [ -d "${MAIN_DIR}/${MOD}" ]; then
        echo "Updating ${MAIN_DIR}/${MOD}"
        cd "${MAIN_DIR}/${MOD}"
        git checkout .
        git pull --all --prune -f
        echo;
    else
        echo "Creating ${MAIN_DIR}/${MOD}"
        cd "${MAIN_DIR}"
        git clone "${URL}"
        echo;
    fi
}

GetMyspellDictionaries()
{
    [ -z "${MAIN_DIR}" ] && return 1
    cd "${MAIN_DIR}"

    if [ ! -d "${MAIN_DIR}/${DICTIONARIES_DIR_NAME}" ]; then
        echo "Getting myspell dictionaries..."
        cd "${MAIN_DIR}"
        find . -type d -name "libreoffice-*" -print0 | xargs -0 rm -rf
        DICTIONARIES_TARBALL_NAME=$(curl -L "${DICTIONARIES_URL}" 2>&1 | sed -ne "s:^.*\(libreoffice-dictionaries_.*\.orig\.tar\.xz\).*$:\1:p" | tail -n1)
        wget -c "${DICTIONARIES_URL}/${DICTIONARIES_TARBALL_NAME}"
        tar -xf "${DICTIONARIES_TARBALL_NAME}"
        # Copy all available dictionaries
        mkdir -p "${DICTIONARIES_DIR_NAME}/dicts"
        cp -a libreoffice-*/ChangeLog-dictionaries \
              "${DICTIONARIES_DIR_NAME}"/ChangeLog.dictionaries.txt
        cp -a libreoffice-*/dictionaries/*/*.aff \
              "${DICTIONARIES_DIR_NAME}/dicts/"
        cp -a libreoffice-*/dictionaries/*/*.dic \
              "${DICTIONARIES_DIR_NAME}/dicts/"
        # Clean up
        rm -f "${DICTIONARIES_DIR_NAME}/dicts"/hyph_*.dic
        find . -type d -name "libreoffice-*" -print0 | xargs -0 rm -rf
        echo "Done."
        echo;
    fi
}

GetReadMe()
{
    [ -z "${MAIN_DIR}" ] && return 1
    cd "${MAIN_DIR}"

    [ -z "${README_FILE_NAME}" ] && return 1
    [ -z "${README_URL}" ] && return 1

    if [ ! -e "${MAIN_DIR}/${README_FILE_NAME}" ]; then
        echo "Getting ${README_FILE_NAME}..."
        cd "${MAIN_DIR}"
        wget -c "${README_URL}/${README_FILE_NAME}"
        echo "Done."
        echo;
    fi
}

