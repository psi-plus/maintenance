#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2018-12-19
# Updated: 2020-04-30
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip

set -e

VERSION="x.y.z"
SUFFIX="win7"

ARCHIVER_OPTIONS="a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on"

ShowHelp()
{
    [ -z "${SCRIPT_NAME}" ] && return 1

    if [ "${1}" = "-h" ] || [ "${1}" = "--help" ]; then
        echo "Usage:"
        echo "   ./${SCRIPT_NAME} [options]"
        echo ;
        echo "Examples:"
        echo "  ./${SCRIPT_NAME}"
        echo "  ./${SCRIPT_NAME} release 1.3"
        echo "  ./${SCRIPT_NAME} --help"
        echo;
        exit 0;
    elif [ "${1}" = "release" ]; then
        if [ -z "${2}" ]; then
            echo "Error: release version is not specified!"
            echo;
            exit 1;
        fi
    fi
}

PrepareMainDir()
{
    [ -z "${MAIN_DIR}" ] && return 1

    mkdir -p "${MAIN_DIR}"
    cd "${MAIN_DIR}"
}

GetPsiVersion()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PSI_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/${PSI_DIR_NAME}"
    if [ "${1}" = "release" ]; then
        VERSION="${2}"
    else
        PSI_TAG="$(git describe --tags | cut -d - -f1)"
        PSI_REV="$(git describe --tags | cut -d - -f2)"
        VERSION="${PSI_TAG}-${PSI_REV}"
    fi

    ARCHIVE_DIR_NAME="psi-portable-${VERSION}_${SUFFIX}"
    echo "Current version of Psi: ${VERSION}"
    echo;
}

GetPsiPlusVersion()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PSI_PLUS_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/${PSI_PLUS_DIR_NAME}"
        if [ "${1}" = "release" ]; then
        VERSION="${2}"
    else
        VERSION="$(git tag | sort -V | tail -n1)"
    fi

    ARCHIVE_DIR_NAME="psi-plus-portable-${VERSION}_${SUFFIX}"
    echo "Current version of Psi+: ${VERSION}"
    echo;
}

PrepareSourcesTree()
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
}

CopyPluginsToSourcesTree()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${PLUGINS_DIR_NAME}" ] && return 1

    for DIR in cmake dev generic unix CMakeLists.txt ; do
        rsync -a --del "${MAIN_DIR}/${PLUGINS_DIR_NAME}/${DIR}" \
                       "${MAIN_DIR}/${PROJECT_DIR_NAME}/src/plugins/" > /dev/null
    done
}

CleanBuildDir()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}"
    rm -rf "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    rm -rf "${MAIN_DIR}/${PROJECT_DIR_NAME}/builddir"
}

PrepareToFirstBuild()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    sed -i "s|option( ENABLE_PLUGINS .*$|option( ENABLE_PLUGINS \"\" ON )|g" CMakeLists.txt
    sed -i "s|set( CHAT_TYPE .*$|set( CHAT_TYPE BASIC  CACHE STRING \"Type of chatlog engine\" )|g" CMakeLists.txt
    sed -i "s|option( VERBOSE_PROGRAM_NAME .*$|option( VERBOSE_PROGRAM_NAME \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( ENABLE_PORTABLE .*$|option( ENABLE_PORTABLE \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( PRODUCTION .*$|option( PRODUCTION \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( USE_MXE .*$|option( USE_MXE \"\" ON )|g" CMakeLists.txt
    sed -i "s|option( USE_KEYCHAIN .*$|option( USE_KEYCHAIN \"\" OFF )|g" CMakeLists.txt
    sed -i "s|option( BUILD_DEV_PLUGINS .*$|option( BUILD_DEV_PLUGINS \"\" ON )|g" src/plugins/CMakeLists.txt
}

PrepareToSecondBuild()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    sed -i "s|CHAT_TYPE:STRING=.*$|CHAT_TYPE:STRING=WEBKIT|g" */CMakeCache.txt
}

BuildProjectForWindows()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${BUILD_TARGETS}" ] && return 1

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    build-project ${BUILD_TARGETS}
}

BuildProjectForMacOS()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    "${MAIN_DIR}/${PROJECT_DIR_NAME}/mac/build-using-homebrew.sh" \
        > /dev/null 2> /dev/null
}

CopyLibsAndResources()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    for DIR in ${BUILD_TARGETS} ; do
        echo "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}/psi"
        cd   "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}"
        make prepare-bin-libs > /dev/null
        make prepare-bin      > /dev/null
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
    rm -f ${ARCHIVE_DIR_NAME}*.7z
    for DIR in ${ARCHIVE_DIR_NAME}* ; do
        [ ! -d "${DIR}" ] && continue

        echo "Creating archive: ${DIR}.7z"
        7z ${ARCHIVER_OPTIONS} "${DIR}.7z" "${DIR}" > /dev/null
    done
}

RenamePsiAppBundles()
{
    [ "${1}" = "release" ] && return 0

    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${VERSION}" ] && return 1
    [ -z "${PSI_TAG}" ] && return 1


    cd "${MAIN_DIR}"
    rm -f Psi-${VERSION}*.dmg
    for FILE_IN in Psi-${PSI_TAG}*.dmg ; do
        FILE_OUT=$(echo ${FILE_IN} | sed "s|Psi-${PSI_TAG}|Psi-${VERSION}|g")
        echo "Rename ${FILE_IN} to ${FILE_OUT}"
        mv "${FILE_IN}" "${FILE_OUT}"
    done
}

