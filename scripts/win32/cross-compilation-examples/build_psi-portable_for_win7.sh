#! /bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2017-07-14
# Updated: 2017-07-17
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, zip
# Sibuserv: https://github.com/sibuserv/sibuserv
# MXE: https://github.com/sibuserv/mxe/tree/hobby

set -e

export MAIN_DIR="${HOME}/Tmp/Psi"

export VERSION="x.y.z"
export SUFFIX="win7"

PSI_TAG="1.1.0"
DEF_COMMIT=000473ebfd463c910ee81d599a7982d8753b83dc

PROGRAM_NAME="psi"
PROJECT_DIR_NAME="psi"
PLUGINS_DIR_NAME="plugins"
TRANSLATIONS_DIR_NAME="psi-l10n"
DICTIONARIES_DIR_NAME="myspell"
README_FILE_NAME="README.txt"

PROJECT_URL=https://github.com/psi-im/psi.git
PLUGINS_URL=https://github.com/psi-im/plugins.git
TRANSLATIONS_URL=https://github.com/psi-im/psi-l10n.git
DICTIONARIES_URL=https://deb.debian.org/debian/pool/main/libr/libreoffice-dictionaries
README_URL=https://sourceforge.net/projects/psi/files/Experimental-Builds/MS-Windows/tehnick

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
    git submodule init
    git submodule update
    PSI_NUM="$(git rev-list --count ${DEF_COMMIT}..HEAD)"
    VERSION="${PSI_TAG}.${PSI_NUM}"
    echo;
fi

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
build-project i686-w64-mingw32.shared x86_64-w64-mingw32.shared
echo;

cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
echo "Preparing to the next step..."
sed -i "s|ENABLE_PLUGINS:BOOL=.*$|ENABLE_PLUGINS:BOOL=OFF|g" */CMakeCache.txt
sed -i "s|ENABLE_WEBKIT:BOOL=.*$|ENABLE_WEBKIT:BOOL=ON|g"    */CMakeCache.txt
echo;

cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
echo "Building webkit version of Psi without plugins..."
# build-project i686-w64-mingw32.shared x86_64-w64-mingw32.shared
build-project x86_64-w64-mingw32.shared
echo;

cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
echo "Copying libraries and resources to..."
for DIR in i686-w64-mingw32.shared x86_64-w64-mingw32.shared ; do
    echo "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}/psi"
    cd   "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}"
    make prepare-bin-libs > /dev/null
    make prepare-bin      > /dev/null
    cp -af "${MAIN_DIR}/${PROJECT_DIR_NAME}/themes" psi/ > /dev/null
    cp -af "${MAIN_DIR}/myspell"    psi/ > /dev/null
    cp -af "${MAIN_DIR}/README.txt" psi/ > /dev/null
done
echo;

cd "${MAIN_DIR}"
echo "Copying the results to main directory..."
mkdir -p "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86"
mkdir -p "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86_64"
rsync -a --del "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/i686-w64-mingw32.shared/psi/" \
               "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86/" > /dev/null
rsync -a --del "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/x86_64-w64-mingw32.shared/psi/" \
               "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86_64/" > /dev/null
echo;

echo "Compressing files into zip archives..."
rm -f ${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86*.zip
zip -rq9 "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86.zip" \
         "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86"
zip -rq9 "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86_64.zip" \
         "${PROGRAM_NAME}-${VERSION}_${SUFFIX}_x86_64"
echo;

echo "Builds are ready for distribution and usage!"

