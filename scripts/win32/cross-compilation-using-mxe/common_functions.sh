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

VERSION="x.y.z"
SUFFIX="win7"

ARCHIVER_OPTIONS="a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on"

PrepareMainDir()
{
    [ -z "${MAIN_DIR}" ] && return 1

    mkdir -p "${MAIN_DIR}"
    cd "${MAIN_DIR}"
}

GetPsiPlusVersion()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PSI_PLUS_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/${PSI_PLUS_DIR_NAME}"
    VERSION="$(git tag | sort -V | tail -n1)"

    ARCHIVE_DIR_NAME="psi-plus-portable-${VERSION}_${SUFFIX}"
    echo "Current version of Psi+: ${VERSION}"
    echo;
}

PrepareToFirstBuild()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${TRANSLATIONS_DIR_NAME}" ] && return 1
    [ -z "${DICTIONARIES_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}"
    rsync -a --del "${MAIN_DIR}/${TRANSLATIONS_DIR_NAME}/translations" \
                   "${MAIN_DIR}/${PROJECT_DIR_NAME}/" > /dev/null
    rsync -a --del "${MAIN_DIR}/${DICTIONARIES_DIR_NAME}" \
                   "${MAIN_DIR}/${PROJECT_DIR_NAME}/" > /dev/null

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    sed -i "s|option( ENABLE_PLUGINS .*$|option( ENABLE_PLUGINS \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( ENABLE_WEBKIT .*$|option( ENABLE_WEBKIT \"\" OFF )|g" CMakeLists.txt
    sed -i "s|option( VERBOSE_PROGRAM_NAME .*$|option( VERBOSE_PROGRAM_NAME \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( ENABLE_PORTABLE .*$|option( ENABLE_PORTABLE \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( PRODUCTION .*$|option( PRODUCTION \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( USE_MXE .*$|option( USE_MXE \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( USE_KEYCHAIN .*$|option( USE_KEYCHAIN \"\" OFF )|g" CMakeLists.txt
    sed -i "s|option( BUILD_DEV_PLUGINS .*$|option( BUILD_DEV_PLUGINS \"\" ON )|g" src/plugins/CMakeLists.txt

    rm -rf "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
}

PrepareToSecondBuild()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    sed -i "s|ENABLE_PLUGINS:BOOL=.*$|ENABLE_PLUGINS:BOOL=OFF|g" */CMakeCache.txt
    sed -i "s|ENABLE_WEBKIT:BOOL=.*$|ENABLE_WEBKIT:BOOL=ON|g"    */CMakeCache.txt
}

BuildProject()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${BUILD_TARGETS}" ] && return 1

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    build-project ${BUILD_TARGETS}
}

CopyLibsAndResources()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${QT_TRANSLATIONS_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    for DIR in ${BUILD_TARGETS} ; do
        echo "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}/psi"
        cd   "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}"
        make prepare-bin-libs > /dev/null
        make prepare-bin      > /dev/null
        cp -af "${MAIN_DIR}/${QT_TRANSLATIONS_DIR_NAME}"/*.qm psi/translations/ > /dev/null
        cp -af "${MAIN_DIR}/${PROJECT_DIR_NAME}/skins"  psi/ > /dev/null
        cp -af "${MAIN_DIR}/README.txt" psi/ > /dev/null
    done
}

CopyFinalResults()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${ARCHIVE_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}"
    for TARGET in ${BUILD_TARGETS} ; do
        DIR_IN="${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${TARGET}/psi"
        if [ "${SUFFIX}" = "winxp" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}"
        elif [ "${TARGET}" = "i686-w64-mingw32.shared" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}_x86"
        elif [ "${TARGET}" = "x86_64-w64-mingw32.shared" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}_x86_64"
        else
            continue
        fi

        mkdir -p "${DIR_OUT}"
        rsync -a --del "${DIR_IN}/" "${DIR_OUT}/" > /dev/null
    done
}

CompressDirs()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${ARCHIVE_DIR_NAME}" ] && return 1
    [ -z "${ARCHIVER_OPTIONS}" ] && return 1

    cd "${MAIN_DIR}"
    rm -f ${ARCHIVE_DIR_NAME}_x86*.7z
    for DIR in ${ARCHIVE_DIR_NAME}_x86* ; do
        [ ! -d "${DIR}" ] && continue

        echo "Creating archive: ${DIR}.7z"
        7z ${ARCHIVER_OPTIONS} "${DIR}.7z" "${DIR}" > /dev/null
    done
}

