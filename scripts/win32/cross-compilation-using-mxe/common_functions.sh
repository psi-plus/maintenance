#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2018-12-19
# Updated: 2021-05-07
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip

set -e

VERSION="x.y.z"
SUFFIX="win7"

INS_SUBDIR="/psi"

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

GetPsimediaVersion()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PSIMEDIA_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}/${PSIMEDIA_DIR_NAME}"
    if [ "${1}" = "release" ]; then
        VERSION="${2}"
    else
        MOD_TAG="$(git describe --tags | cut -d - -f1 | sed 's/v//')"
        MOD_REV="$(git describe --tags | cut -d - -f2)"
        VERSION="${MOD_TAG}-${MOD_REV}"
    fi

    ARCHIVE_DIR_NAME="psimedia-${VERSION}_${SUFFIX}"
    echo "Current version of PsiMedia: ${VERSION}"
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

    for DIR in dev generic unix ; do
        rsync -a --del "${MAIN_DIR}/${PLUGINS_DIR_NAME}/${DIR}" \
                       "${MAIN_DIR}/${PROJECT_DIR_NAME}/plugins/" > /dev/null
    done
    for DIR in cmake CMakeLists.txt ; do
        rsync -a "${MAIN_DIR}/${PLUGINS_DIR_NAME}/${DIR}" \
                 "${MAIN_DIR}/${PROJECT_DIR_NAME}/plugins/" > /dev/null
    done
}

CopyPsimediaToSourcesTree()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${PSIMEDIA_DIR_NAME}" ] && return 1

    rsync -a --del "${MAIN_DIR}/${PSIMEDIA_DIR_NAME}" \
                   "${MAIN_DIR}/${PROJECT_DIR_NAME}/plugins/generic/" \
                   --exclude=".git/" \
                   > /dev/null
}

RemovePsimediaFromSourcesTree()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    if [ ! -z "${PSIMEDIA_DIR_NAME}" ] ; then
        rm -rf "${MAIN_DIR}/${PROJECT_DIR_NAME}/plugins/generic/${PSIMEDIA_DIR_NAME}"
    fi
}

CleanBuildDir()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}"
    rm -rf "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    rm -rf "${MAIN_DIR}/${PROJECT_DIR_NAME}/builddir"
}

PrepareToFirstBuildForLinux()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    FILE=CMakeLists.txt

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    sed -i -E "s|(option\( ENABLE_PLUGINS .*) .+ (\).*)$|\1 ON \2|g"      ${FILE}
    sed -i -E "s|(option\( PRODUCTION .*) .+ (\).*)$|\1 ON \2|g"          ${FILE}
    sed -i -E "s|(option\( USE_KEYCHAIN .*) .+ (\).*)$|\1 OFF \2|g"       ${FILE}
    sed -i -E "s|(option\( LIMIT_X11_USAGE .*) .+ (\).*)$|\1 ON \2|g"     ${FILE}
    sed -i -E "s|(option\( VERBOSE_PROGRAM_NAME .*) .+ (\).*)$|\1 ON \2|g" ${FILE}
    sed -i -E "s|(set\( CHAT_TYPE) .+ (CACHE STRING .*)$|\1 BASIC \2|g"   ${FILE}

    sed -i -E "s|(option\( BUNDLED_QCA .*) .+ (\).*)$|\1 OFF \2|g"        ${FILE}
    sed -i -E "s|(option\( BUNDLED_USRSCTP .*) .+ (\).*)$|\1 ON \2|g"     ${FILE}

    sed -i -E "s|(option\( BUILD_DEV_PLUGINS .*) .+ (\).*)$|\1 ON \2|g"   plugins/${FILE}

    # Temporary workaround until library usrsctp is not packaged in LXE:
    sed -i -E "s|(option\( JINGLE_SCTP .*) .+ (\).*)$|\1 OFF \2|g"        iris/${FILE}

    if [ "${BUILD_WITH_PSIMEDIA}" = "true" ] ; then
        sed -i -E "s|(option\( BUILD_PSIMEDIA .*) .+ (\).*)$|\1 ON \2|g"  ${FILE}
    else
        sed -i -E "s|(option\( BUILD_PSIMEDIA .*) .+ (\).*)$|\1 OFF \2|g" ${FILE}
    fi
}

PrepareToFirstBuildForWindows()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    FILE=CMakeLists.txt

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    sed -i -E "s|(option\( ENABLE_PLUGINS .*) .+ (\).*)$|\1 ON \2|g"      ${FILE}
    sed -i -E "s|(option\( ENABLE_PORTABLE .*) .+ (\).*)$|\1 ON \2|g"     ${FILE}
    sed -i -E "s|(option\( PRODUCTION .*) .+ (\).*)$|\1 ON \2|g"          ${FILE}
    sed -i -E "s|(option\( USE_KEYCHAIN .*) .+ (\).*)$|\1 OFF \2|g"       ${FILE}
    sed -i -E "s|(option\( USE_MXE .*) .+ (\).*)$|\1 ON \2|g"             ${FILE}
    sed -i -E "s|(option\( VERBOSE_PROGRAM_NAME .*) .+ (\).*)$|\1 ON \2|g" ${FILE}
    sed -i -E "s|(set\( CHAT_TYPE) .+ (CACHE STRING .*)$|\1 BASIC \2|g"   ${FILE}

    sed -i -E "s|(option\( BUNDLED_QCA .*) .+ (\).*)$|\1 ON \2|g"         ${FILE}
    sed -i -E "s|(option\( BUNDLED_USRSCTP .*) .+ (\).*)$|\1 ON \2|g"     ${FILE}

    sed -i -E "s|(option\( BUILD_DEV_PLUGINS .*) .+ (\).*)$|\1 ON \2|g"   plugins/${FILE}

    if [ "${BUILD_WITH_PSIMEDIA}" = "true" ] ; then
        sed -i -E "s|(option\( BUILD_PSIMEDIA .*) .+ (\).*)$|\1 ON \2|g"  ${FILE}
    else
        sed -i -E "s|(option\( BUILD_PSIMEDIA .*) .+ (\).*)$|\1 OFF \2|g" ${FILE}
    fi
}

PrepareToSecondBuild()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1

    FILE=CMakeCache.txt

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    sed -i "s|CHAT_TYPE:STRING=.*$|CHAT_TYPE:STRING=WEBKIT|g" */${FILE}
}

BuildProjectUsingSibuserv()
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
        DIR_IN="${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${TARGET}${INS_SUBDIR}"
        if [ "${SUFFIX}" = "winxp" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}"
        elif [ "${TARGET}" = "i686-w64-mingw32.shared" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}_x86"
        elif [ "${TARGET}" = "x86_64-w64-mingw32.shared" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}_x86_64"
        elif [ "${TARGET}" = "Ubuntu-14.04_i386_shared" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}-i686/usr"
        elif [ "${TARGET}" = "Ubuntu-14.04_amd64_shared" ] ; then
            DIR_OUT="${ARCHIVE_DIR_NAME}-x86_64/usr"
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

