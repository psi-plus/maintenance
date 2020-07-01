#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2020-06-03
# Updated: 2020-07-01
# Version: N/A
#
# Dependencies:
# rsync, find, sed, appimagetool
# Sibuserv: https://github.com/sibuserv/sibuserv
# LXE: https://github.com/sibuserv/lxe/tree/hobby

set -e

GCC_EXTRA_VER="8.3.0"
INS_SUBDIR="-out/usr"

LIBS="
    libbz2.so.1.0
    libbz2.so.1.0.6
    libcrypto.so.1.0.0
    libexslt.so.0
    libexslt.so.0.8.17
    libgcrypt.so.11
    libgcrypt.so.11.8.2
    libgif.so.4
    libgif.so.4.1.6
    libhunspell-1.3.so.0
    libhunspell-1.3.so.0.0.0
    libicudata.so.52
    libicudata.so.52.1
    libicui18n.so.52
    libicui18n.so.52.1
    libicuio.so.52
    libicuio.so.52.1
    libicule.so.52
    libicule.so.52.1
    libiculx.so.52
    libiculx.so.52.1
    libicutest.so.52
    libicutest.so.52.1
    libicutu.so.52
    libicutu.so.52.1
    libicuuc.so.52
    libicuuc.so.52.1
    libidn.so.11
    libidn.so.11.6.11
    libjpeg.so.8
    libjpeg.so.8.3.0
    libminizip.so.1
    libminizip.so.1.0.0
    libotr.so.5
    libotr.so.5.1.1
    libpciaccess.so.0
    libpciaccess.so.0.11.1
    libpcre2-8.so.0
    libpcre2-8.so.0.8.0
    libpcre2-16.so.0
    libpcre2-16.so.0.8.0
    libpcre2-posix.so.2
    libpcre2-posix.so.2.0.2
    libpcre16.so.0
    libpcre16.so.0.2.11
    libpcrecpp.so.0
    libpcrecpp.so.0.0.1
    libpcreposix.so.0
    libpcreposix.so.0.0.6
    libpcre.so.1
    libpcre.so.1.2.11
    libpng12.so.0
    libpng12.so.0.50.0
    libpng.so.3
    libpng.so.3.50.0
    libsignal-protocol-c.so.2
    libsignal-protocol-c.so.2.3.2
    libsqlite3.so.0
    libsqlite3.so.0.8.6
    libssl.so.1.0.0
    libtidy.so.5
    libtidy.so.5.4.0
    libxcb-xkb.so
    libxcb-xkb.so.1
    libxcb-xkb.so.1.0.0
    libxkbcommon.so
    libxkbcommon-x11.so
    libxkbcommon-x11.so.0
    libxkbcommon-x11.so.0.0.0
    libxkbcommon.so.0
    libxkbcommon.so.0.0.0
    libxml2.so.2
    libxml2.so.2.9.1
    libxslt.so.1
    libxslt.so.1.1.28
"

I586_LIBS="
    gcc/i586-cross-linux-gnu/${GCC_EXTRA_VER}/libstdc++.so.6
    gcc/i586-cross-linux-gnu/${GCC_EXTRA_VER}/libstdc++.so.6.0.25
"

AMD64_LIBS="
    gcc/x86_64-cross-linux-gnu/${GCC_EXTRA_VER}/libstdc++.so.6
    gcc/x86_64-cross-linux-gnu/${GCC_EXTRA_VER}/libstdc++.so.6.0.25
"

QT_LIBS="
    libQt5Concurrent.so.5
    libQt5Concurrent.so.5.12
    libQt5Concurrent.so.5.12.3
    libQt5Core.so.5
    libQt5Core.so.5.12
    libQt5Core.so.5.12.3
    libQt5DBus.so.5
    libQt5DBus.so.5.12
    libQt5DBus.so.5.12.3
    libQt5Gui.so.5
    libQt5Gui.so.5.12
    libQt5Gui.so.5.12.3
    libQt5MultimediaQuick.so.5
    libQt5MultimediaQuick.so.5.12
    libQt5MultimediaQuick.so.5.12.3
    libQt5MultimediaWidgets.so.5
    libQt5MultimediaWidgets.so.5.12
    libQt5MultimediaWidgets.so.5.12.3
    libQt5Multimedia.so.5
    libQt5Multimedia.so.5.12
    libQt5Multimedia.so.5.12.3
    libQt5Network.so.5
    libQt5Network.so.5.12
    libQt5Network.so.5.12.3
    libQt5OpenGL.so.5
    libQt5OpenGL.so.5.12
    libQt5OpenGL.so.5.12.3
    libQt5PrintSupport.so.5
    libQt5PrintSupport.so.5.12
    libQt5PrintSupport.so.5.12.3
    libQt5Qml.so.5
    libQt5Qml.so.5.12
    libQt5Qml.so.5.12.3
    libQt5QuickParticles.so.5
    libQt5QuickParticles.so.5.12
    libQt5QuickParticles.so.5.12.3
    libQt5QuickShapes.so.5
    libQt5QuickShapes.so.5.12
    libQt5QuickShapes.so.5.12.3
    libQt5QuickTest.so.5
    libQt5QuickTest.so.5.12
    libQt5QuickTest.so.5.12.3
    libQt5QuickWidgets.so.5
    libQt5QuickWidgets.so.5.12
    libQt5QuickWidgets.so.5.12.3
    libQt5Quick.so.5
    libQt5Quick.so.5.12
    libQt5Quick.so.5.12.3
    libQt5Sensors.so.5
    libQt5Sensors.so.5.12
    libQt5Sensors.so.5.12.3
    libQt5Sql.so.5
    libQt5Sql.so.5.12
    libQt5Sql.so.5.12.3
    libQt5Svg.so.5
    libQt5Svg.so.5.12
    libQt5Svg.so.5.12.3
    libQt5WebChannel.so.5
    libQt5WebChannel.so.5.12
    libQt5WebChannel.so.5.12.3
    libQt5WebKitWidgets.so.5
    libQt5WebKitWidgets.so.5.212.0
    libQt5WebKit.so.5
    libQt5WebKit.so.5.212.0
    libQt5WebSockets.so.5
    libQt5WebSockets.so.5.12
    libQt5WebSockets.so.5.12.3
    libQt5Widgets.so.5
    libQt5Widgets.so.5.12
    libQt5Widgets.so.5.12.3
    libQt5X11Extras.so.5
    libQt5X11Extras.so.5.12
    libQt5X11Extras.so.5.12.3
    libQt5XcbQpa.so.5
    libQt5XcbQpa.so.5.12
    libQt5XcbQpa.so.5.12.3
    libQt5XmlPatterns.so.5
    libQt5XmlPatterns.so.5.12
    libQt5XmlPatterns.so.5.12.3
    libQt5Xml.so.5
    libQt5Xml.so.5.12
    libQt5Xml.so.5.12.3
    libqca-qt5.so.2
    libqca-qt5.so.2.1.3
"

QT_LIBEXEC="
    QtWebNetworkProcess
    QtWebProcess
    QtWebStorageProcess
"

QT_PLUGINS_DIRS="
    bearer
    crypto
    generic
    iconengines
    imageformats
    mediaservice
    platforminputcontexts
    platforms
    platformthemes
    playlistformats
    qmltooling
    sensorgestures
    sensors
    sqldrivers
"

GST_PLUGINS="
    libgstopus.so
"

# Extra functions

WriteQtConf()
{
    FILE="./bin/qt.conf"
    cat > "${FILE}" << EOF
[Paths]
Prefix = ../
Libraries = lib
LibraryExecutables = lib/qt5/libexec
Plugins = lib/qt5/plugins

EOF
}

WriteAppRun()
{
    [ -z "${PROGRAM_NAME}" ] && return 1

    FILE="./AppRun"
    cat > "${FILE}" << EOF
#!/bin/sh

export MAIN_DIR=\$(dirname \$(readlink -f "\${0}"))
export PATH="\${MAIN_DIR}/usr/bin:\${PATH}"
export LD_LIBRARY_PATH="\${MAIN_DIR}/usr/lib"
export QT_PLUGIN_PATH="\${MAIN_DIR}/usr/lib/qt5/plugins"


GetFullFileName()
{
    find "\${1}" -name '*libstdc++.so*' 2> /dev/null | \
        grep "libstdc++\.so\.6\." | \
        sed -ne "s|^.*\(libstdc++\.so\.6.*\)\$|\1|p" | \
        sort -V | tail -n1
}

BUNDLED_LIBSTDCPP=\$(GetFullFileName "\${MAIN_DIR}/usr/lib")
SYSTEM_LIBSTDCPP=\$(GetFullFileName /usr/lib*)
NEWEST_LIBSTDCPP=\$(echo "\${BUNDLED_LIBSTDCPP}
\${SYSTEM_LIBSTDCPP}" | sort -V | tail -n1)

if [ "\${NEWEST_LIBSTDCPP}" = "\${BUNDLED_LIBSTDCPP}" ] ; then
    export LD_LIBRARY_PATH="\${LD_LIBRARY_PATH}:\${MAIN_DIR}/usr/lib/gcc"
fi


\${MAIN_DIR}/usr/bin/${PROGRAM_NAME}${PROGRAM_NAME_SUFFIX} \$@

EOF
    chmod uog+x "${FILE}"
}

InstallToTmpDir()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROGRAM_NAME}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${BUILD_TARGETS}" ] && return 1

    cd "${MAIN_DIR}/${PROJECT_DIR_NAME}"
    build-project install ${BUILD_TARGETS}

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    for DIR in ${BUILD_TARGETS} ; do
        cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}-out"
        cp -a "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}"/${PROGRAM_NAME}*.desktop \
              "usr/share/applications/"
        cp -a "${MAIN_DIR}/build-${PROJECT_DIR_NAME}/${DIR}/psi"/${PROGRAM_NAME}* \
              "usr/bin/"
        cp -a "usr/share/pixmaps/${PROGRAM_NAME}-webkit.png" \
              "usr/share/pixmaps/${PROGRAM_NAME}.png"
        chrpath -d "usr/bin"/* 2> /dev/null || true
    done
}

CopyLibs()
{
    [ -z "${LIB_DIR}" ] && return 1
    [ -z "${DEST}" ] && return 1
    [ -z "${1}" ] && return 1

    mkdir -p "${DEST}/"
    for LIB in ${@} ; do
        rsync -a "${LIB_DIR}/${LIB}" "${DEST}/"
    done
    chrpath -d "${DEST}"/* 2> /dev/null || true
}

CopyLibsAndResources()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROGRAM_NAME}" ] && return 1
    [ -z "${PROJECT_DIR_NAME}" ] && return 1
    [ -z "${BUILD_TARGETS}" ] && return 1

    . /etc/sibuserv/sibuserv.conf
    . ${HOME}/.config/sibuserv/sibuserv.conf || true

    cd "${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    BUILD_DIR="${MAIN_DIR}/build-${PROJECT_DIR_NAME}"
    for TARGET in ${BUILD_TARGETS} ; do
        INST_DIR="${BUILD_DIR}/${TARGET}${INS_SUBDIR}"
        echo "${INST_DIR}"
        cd   "${INST_DIR}"

        SYSROOT="${LXE_DIR}/dist/${TARGET}/sysroot"

        if [ "${TARGET}" = "Ubuntu-14.04_i386_shared" ] ; then
            ARCH_SPEC_LIBS="${I586_LIBS}"
        elif [ "${TARGET}" = "Ubuntu-14.04_amd64_shared" ] ; then
            ARCH_SPEC_LIBS="${AMD64_LIBS}"
        else
            continue
        fi

        LIB_DIR="${SYSROOT}/usr/lib"
        DEST="./lib/gcc"
        CopyLibs ${ARCH_SPEC_LIBS}

        LIB_DIR="${SYSROOT}/usr/lib"
        DEST="./lib"
        CopyLibs ${LIBS}

        LIB_DIR="${SYSROOT}/qt5/lib"
        DEST="./lib"
        CopyLibs ${QT_LIBS}

        DEST="./lib/qt5/libexec"
        mkdir -p "${DEST}/"
        for QT_EXEC in ${QT_LIBEXEC} ; do
            rsync -a "${SYSROOT}/qt5/libexec/${QT_EXEC}" "${DEST}/"
        done
        chrpath -d "${DEST}"/* 2> /dev/null || true

        DEST="./lib/qt5/plugins"
        mkdir -p "${DEST}/"
        for QT_PLUGINS_DIR in ${QT_PLUGINS_DIRS} ; do
            rsync -a "${SYSROOT}/qt5/plugins/${QT_PLUGINS_DIR}" "${DEST}/"
        done

        DEST="./share/${PROGRAM_NAME}/translations"
        mkdir -p "${DEST}/"
        rsync -a "${SYSROOT}/qt5/translations"/qt*.qm "${DEST}/"

        WriteQtConf
    done
}

GetArchSuffix()
{
    [ -z "${1}" ] && return 1

    if [ "${TARGET}" = "Ubuntu-14.04_i386_shared" ] ; then
        echo "-i686"
    elif [ "${TARGET}" = "Ubuntu-14.04_amd64_shared" ] ; then
        echo "-x86_64"
    else
        return 1
    fi
}

CopyAppDirFiles()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${ARCHIVE_DIR_NAME}" ] && return 1
    [ -z "${PROGRAM_NAME}" ] && return 1

    for TARGET in ${BUILD_TARGETS} ; do
        ARCHITECTURE_SUFFIX="$(GetArchSuffix ${TARGET})"
        DIR="${ARCHIVE_DIR_NAME}${ARCHITECTURE_SUFFIX}"
        [ ! -d "${MAIN_DIR}/${DIR}" ] && continue

        echo "${DIR}"
        cd "${MAIN_DIR}/${DIR}"
        cp -a usr/share/*/${PROGRAM_NAME}${PROGRAM_NAME_SUFFIX}.desktop ./
        cp -a usr/share/*/${PROGRAM_NAME}${PROGRAM_NAME_SUFFIX}.png ./
        cp -a ${PROGRAM_NAME}${PROGRAM_NAME_SUFFIX}.png .DirIcon
        # Workaround for bug: https://github.com/AppImage/AppImageKit/issues/871
        sed -i -E "s|Version=.*|Version=1.0|g" \
            ${PROGRAM_NAME}${PROGRAM_NAME_SUFFIX}.desktop
        # end
        WriteAppRun
    done
}

CleanUpAppDirs()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${ARCHIVE_DIR_NAME}" ] && return 1
    [ -z "${PROGRAM_NAME}" ] && return 1

    for TARGET in ${BUILD_TARGETS} ; do
        ARCHITECTURE_SUFFIX="$(GetArchSuffix ${TARGET})"
        DIR="${ARCHIVE_DIR_NAME}${ARCHITECTURE_SUFFIX}"
        [ ! -d "${MAIN_DIR}/${DIR}" ] && continue

        cd "${MAIN_DIR}/${DIR}"
        if [ "${PROGRAM_NAME_SUFFIX}" = "-webkit" ] ; then
            rm -f usr/bin/${PROGRAM_NAME}
            rm -f usr/share/*/${PROGRAM_NAME}.desktop
            rm -f usr/share/*/${PROGRAM_NAME}.png
        else
            rm -f usr/bin/${PROGRAM_NAME}-webkit
            rm -f usr/share/*/${PROGRAM_NAME}-webkit.desktop
            rm -f usr/share/*/${PROGRAM_NAME}-webkit.png
            # Remove QtWebKit releated files
            rm -f usr/lib/libQt5MultimediaQuick*
            rm -f usr/lib/libQt5Qml*
            rm -f usr/lib/libQt5Quick*
            rm -f usr/lib/libQt5Sensors*
            rm -f usr/lib/libQt5Web*
            rm -rf usr/lib/qt5/libexec
        fi
    done
}

GetPrettyProgramName()
{
    [ -z "${PROGRAM_NAME}" ] && return 1

    if [ "${PROGRAM_NAME}" = "psi-plus" ] ; then
        echo "Psi+"
    elif [ "${PROGRAM_NAME}" = "psi" ] ; then
        echo "Psi"
    else
        return 1
    fi
}

PrepareAppDirs()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${PROGRAM_NAME}" ] && return 1
    [ -z "${VERSION}" ] && return 1

    PRETTY_PROGRAM_NAME="$(GetPrettyProgramName)"
    [ -z "${PRETTY_PROGRAM_NAME}" ] && \
        echo "Unknown PRETTY_PROGRAM_NAME!" && return 1

    PROGRAM_NAME_SUFFIX="-webkit"
    ARCHIVE_DIR_NAME="${PRETTY_PROGRAM_NAME}-${VERSION}-webkit${SUFFIX}"
    cd "${MAIN_DIR}" && rm -rf "${ARCHIVE_DIR_NAME}"
    CopyFinalResults
    CopyAppDirFiles
    CleanUpAppDirs

    unset PROGRAM_NAME_SUFFIX
    ARCHIVE_DIR_NAME="${PRETTY_PROGRAM_NAME}-${VERSION}${SUFFIX}"
    cd "${MAIN_DIR}" && rm -rf "${ARCHIVE_DIR_NAME}"
    CopyFinalResults
    CopyAppDirFiles
    CleanUpAppDirs
}

BuildAppImageFiles()
{
    [ -z "${MAIN_DIR}" ] && return 1

    PRETTY_PROGRAM_NAME="$(GetPrettyProgramName)"
    [ -z "${PRETTY_PROGRAM_NAME}" ] && \
        echo "Unknown PRETTY_PROGRAM_NAME!" && return 1

    cd "${MAIN_DIR}"
    rm -f "${PRETTY_PROGRAM_NAME}-${VERSION}"*.AppImage
    for DIR in "${PRETTY_PROGRAM_NAME}-${VERSION}"* ; do
        [ ! -d "${DIR}" ] && continue

        echo "Creating: ${DIR}.AppImage"
        appimagetool "${DIR}" "${DIR}.AppImage" 2>&1 > appimagetool.log
    done
}

