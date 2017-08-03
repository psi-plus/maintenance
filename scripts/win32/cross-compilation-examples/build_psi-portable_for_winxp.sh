#! /bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2017-07-14
# Updated: 2017-08-04
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip
# Sibuserv: https://github.com/sibuserv/sibuserv
# MXE: https://github.com/sibuserv/mxe/tree/hobby

set -e

export MAIN_DIR="${HOME}/Tmp/Psi"

export VERSION="x.y.z"
export SUFFIX="winxp"

PSI_TAG="1.2.0"
DEF_COMMIT=4b8a3473ee1de59f84627000cba462e05f8a9b84

PROGRAM_NAME="psi"
PROJECT_DIR_NAME="psi"
PLUGINS_DIR_NAME="plugins"
TRANSLATIONS_DIR_NAME="psi-l10n"
QT_TRANSLATIONS_DIR_NAME="qt-l10n"
DICTIONARIES_DIR_NAME="myspell"
README_FILE_NAME="README.txt"

PROJECT_URL=https://github.com/psi-im/psi.git
PLUGINS_URL=https://github.com/psi-im/plugins.git
TRANSLATIONS_URL=https://github.com/psi-im/psi-l10n.git
DICTIONARIES_URL=https://deb.debian.org/debian/pool/main/libr/libreoffice-dictionaries
README_URL=https://sourceforge.net/projects/psi/files/Experimental-Builds/MS-Windows/tehnick

ARCHIVER_OPTIONS="a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on"

if [ "${1}" = "-h" ] || [ "${1}" = "--help" ]; then
    SCRIPT_NAME="$(basename ${0})"
    echo "Usage:"
    echo "   ./${SCRIPT_NAME} [options]"
    echo ;
    echo "Examples:"
    echo "  ./${SCRIPT_NAME}"
    echo "  ./${SCRIPT_NAME} release 1.1"
    echo "  ./${SCRIPT_NAME} --help"
    echo;
    exit 0;
elif [ "${1}" = "release" ]; then
    if [ -z "${2}" ]; then
        echo "Error: release version is not specified!"
        echo;
        exit 1;
    fi
else
    ARCHIVE_DIR_NAME="${PROGRAM_NAME}-${VERSION}_${SUFFIX}"
fi

# Test Internet connection:
host github.com > /dev/null

mkdir -p "${MAIN_DIR}"
cd "${MAIN_DIR}"
echo "Getting the sources..."
echo;

MOD="${PROJECT_DIR_NAME}"
URL="${PROJECT_URL}"
if [ -d "${MAIN_DIR}/${MOD}" ]; then
    echo "Updating ${MAIN_DIR}/${MOD}"
    cd "${MAIN_DIR}/${MOD}"
    git checkout .
    git checkout master
    git pull --all --prune -f
    git submodule init
    git submodule update
    PSI_NUM="$(git rev-list --count ${DEF_COMMIT}..HEAD)"
    VERSION="${PSI_TAG}.${PSI_NUM}"
    echo;
else
    echo "Creating ${MAIN_DIR}/${MOD}"
    cd "${MAIN_DIR}"
    git clone "${URL}"
    cd "${MAIN_DIR}/${MOD}"
    git checkout master
    git submodule init
    git submodule update
    PSI_NUM="$(git rev-list --count ${DEF_COMMIT}..HEAD)"
    VERSION="${PSI_TAG}.${PSI_NUM}"
    echo;
fi

if [ "${1}" = "release" ]; then
    VERSION="${2}"
    git checkout "${VERSION}" > /dev/null 2> /dev/null
    git submodule init > /dev/null 2> /dev/null
    git submodule update > /dev/null 2> /dev/null
fi

ARCHIVE_DIR_NAME="${PROGRAM_NAME}-portable-${VERSION}_${SUFFIX}"
echo "Current version of Psi: ${VERSION}"
echo;

MOD="${PLUGINS_DIR_NAME}"
URL="${PLUGINS_URL}"
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

MOD="${TRANSLATIONS_DIR_NAME}"
URL="${TRANSLATIONS_URL}"
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

MOD="${QT_TRANSLATIONS_DIR_NAME}"
if [ ! -d "${MAIN_DIR}/${MOD}" ]; then
    echo "Getting Qt translations..."
    # Load sibuserv settings
    for CONF_FILE in "/etc/sibuserv/sibuserv.conf" \
                     "${HOME}/.config/sibuserv/sibuserv.conf"
    do
        [ -r "${CONF_FILE}" ] && . "${CONF_FILE}"
    done
    # Copy translations from Qt SDK if it is available
    if [ -d "${QT_SDK_DIR}/gcc_64/translations" ]; then
        mkdir -p "${MAIN_DIR}/${MOD}"
        cd "${MAIN_DIR}/${MOD}"
        rsync -a "${QT_SDK_DIR}/gcc_64/translations"/qt*.qm ./
        rm -f qt_help_*.qm qtconfig_*.qm qtconnectivity_*.qm qtlocation_*.qm \
              qtquick1_*.qm qtquickcontrols_*.qm qtquickcontrols2_*.qm \
              qtscript_*.qm qtserialport_*.qm qtwebengine_*.qm qtwebsockets_*.qm \
              qtxmlpatterns_*.qm
        echo "Done."
    else
        echo "Localization files are not found!"
    fi
    echo;
fi

if [ ! -d "${MAIN_DIR}/${DICTIONARIES_DIR_NAME}" ]; then
    echo "Getting myspell dictionaries..."
    cd "${MAIN_DIR}"
    find . -type d -name "libreoffice-*" -print0 | xargs -0 rm -rf
    DICTIONARIES_TARBALL_NAME=$(curl -L "${DICTIONARIES_URL}" 2>&1 | sed -ne "s:^.*\(libreoffice-dictionaries_.*\.orig\.tar\.xz\).*$:\1:p")
    wget -c "${DICTIONARIES_URL}/${DICTIONARIES_TARBALL_NAME}"
    tar -xf "${DICTIONARIES_TARBALL_NAME}"
    mkdir -p "${DICTIONARIES_DIR_NAME}/dicts"
    cp -a libreoffice-*/ChangeLog-dictionaries "${DICTIONARIES_DIR_NAME}/"
    cp -a libreoffice-*/dictionaries/*/*.aff "${DICTIONARIES_DIR_NAME}/dicts/"
    cp -a libreoffice-*/dictionaries/*/*.dic "${DICTIONARIES_DIR_NAME}/dicts/"
    rm -f "${DICTIONARIES_DIR_NAME}/dicts"/hyph_*.dic
    find . -type d -name "libreoffice-*" -print0 | xargs -0 rm -rf
    echo "Done."
    echo;
fi

if [ ! -e "${MAIN_DIR}/${README_FILE_NAME}" ]; then
    echo "Getting ${README_FILE_NAME}..."
    cd "${MAIN_DIR}"
    wget -c "${README_URL}/${README_FILE_NAME}"
    echo "Done."
    echo;
fi

cd "${MAIN_DIR}"
echo "Preparing to build..."

rsync -a --del "${MAIN_DIR}/${TRANSLATIONS_DIR_NAME}/translations" \
               "${MAIN_DIR}/${PROJECT_DIR_NAME}/" > /dev/null
rsync -a --del "${MAIN_DIR}/${PLUGINS_DIR_NAME}"/* \
               "${MAIN_DIR}/${PROJECT_DIR_NAME}/src/plugins/" > /dev/null

cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
sed -i "s|option( ENABLE_PLUGINS .*$|option( ENABLE_PLUGINS \"\" ON )|g" CMakeLists.txt
sed -i "s|option( ENABLE_WEBKIT .*$|option( ENABLE_WEBKIT \"\" OFF )|g" CMakeLists.txt
sed -i "s|option( VERBOSE_PROGRAM_NAME .*$|option( VERBOSE_PROGRAM_NAME \"\" ON )|g" CMakeLists.txt
sed -i "s|option( ENABLE_PORTABLE .*$|option( ENABLE_PORTABLE \"\" ON )|g" CMakeLists.txt
sed -i "s|option( PRODUCTION .*$|option( PRODUCTION \"\" ON )|g" CMakeLists.txt
sed -i "s|option( USE_MXE .*$|option( USE_MXE \"\" ON )|g" CMakeLists.txt

rm -rf "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
echo;

cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
echo "Building basic version of Psi with plugins..."
build-project i686-w64-mingw32.shared
echo;

cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
echo "Preparing to the next step..."
sed -i "s|ENABLE_PLUGINS:BOOL=.*$|ENABLE_PLUGINS:BOOL=OFF|g" */CMakeCache.txt
sed -i "s|ENABLE_WEBKIT:BOOL=.*$|ENABLE_WEBKIT:BOOL=ON|g"    */CMakeCache.txt
echo;

cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
echo "Building webkit version of Psi without plugins..."
build-project i686-w64-mingw32.shared
echo;

cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
echo "Copying libraries and resources to..."
for DIR in i686-w64-mingw32.shared ; do
    echo "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}/psi"
    cd   "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}"
    make prepare-bin-libs > /dev/null
    make prepare-bin      > /dev/null
    cp -af "${MAIN_DIR}/${QT_TRANSLATIONS_DIR_NAME}"/*.qm psi/translations/ > /dev/null
    cp -af "${MAIN_DIR}/${PROJECT_DIR_NAME}/themes" psi/ > /dev/null
    cp -af "${MAIN_DIR}/myspell"    psi/ > /dev/null
    cp -af "${MAIN_DIR}/README.txt" psi/ > /dev/null
done
echo;

cd "${MAIN_DIR}"
echo "Copying the results to main directory..."
mkdir -p "${ARCHIVE_DIR_NAME}"
rsync -a --del "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/i686-w64-mingw32.shared/psi/" \
               "${ARCHIVE_DIR_NAME}/" > /dev/null
echo;

echo "Compressing files into 7z archives..."
rm -f ${ARCHIVE_DIR_NAME}*.7z
echo "Creating archive: ${ARCHIVE_DIR_NAME}.7z"
7z ${ARCHIVER_OPTIONS} "${ARCHIVE_DIR_NAME}.7z" \
                       "${ARCHIVE_DIR_NAME}" > /dev/null
echo "Done."
echo;

echo "Builds are ready for distribution and usage!"

