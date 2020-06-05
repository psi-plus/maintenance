#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: MIT (Expat)
# Created: 2020-06-03
# Updated: 2020-06-04
# Version: N/A
#
# Dependencies:
# git, wget, curl, rsync, find, sed, p7zip

set -e

GCC_EXTRA_VER="8.3.0"
INS_SUBDIR="-out/usr"

LIBS="
    libbz2.so.1.0
    libbz2.so.1.0.6
    libcc1.so.0
    libcc1.so.0.0.0
    libcrypto.so.1.0.0
    libexpat.so.1
    libexpat.so.1.6.0
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
    libkms.so.1
    libkms.so.1.0.0
    libminiupnpc.so.2.0
    libminiupnpc.so.16
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
    libpspell.so.15
    libpspell.so.15.1.5
    libsignal-protocol-c.so.2
    libsignal-protocol-c.so.2.3.2
    libsqlite3.so.0
    libsqlite3.so.0.8.6
    libssl.so.1.0.0
    libtidy.so.5
    libtidy.so.5.4.0
    libxml2.so.2
    libxml2.so.2.9.1
    libxslt.so.1
    libxslt.so.1.1.28
    libz.so.1
    libz.so.1.2.11
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
    libQt5Help.so.5
    libQt5Help.so.5.12
    libQt5Help.so.5.12.3
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
    libQt5Test.so.5
    libQt5Test.so.5.12
    libQt5Test.so.5.12.3
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
LibraryExecutables=../lib/qt5/libexec
Plugins = ../lib/qt5/plugins

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

\${MAIN_DIR}/usr/bin/${PROGRAM_NAME} \$@

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
        rm -r "usr/share/icons"
        chrpath -d "usr/bin"/* 2> /dev/null || true
    done
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

        for LIB in ${LIBS} ; do
            rsync -a "${SYSROOT}/usr/lib/${LIB}" ./lib/
        done

        if [ "${TARGET}" = "Ubuntu-14.04_i386_shared" ] ; then
            ARCH_SPEC_LIBS="${I586_LIBS}"
        elif [ "${TARGET}" = "Ubuntu-14.04_amd64_shared" ] ; then
            ARCH_SPEC_LIBS="${AMD64_LIBS}"
        else
            continue
        fi

        DEST="./lib"
        for ARCH_SPEC_LIB in ${ARCH_SPEC_LIBS}
        do
            rsync -a "${SYSROOT}/usr/lib/${ARCH_SPEC_LIB}" "${DEST}/"
        done
        chrpath -d "${DEST}"/* 2> /dev/null || true

        DEST="./lib"
        for QT_LIB in ${QT_LIBS} ; do
            rsync -a "${SYSROOT}/qt5/lib/${QT_LIB}" "${DEST}/"
        done
        chrpath -d "${DEST}"/* 2> /dev/null || true

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
        rsync -a "${SYSROOT}/qt5/translations"/*.qm "${DEST}/"

        WriteQtConf
    done
}

WriteLaunchers()
{
    [ -z "${MAIN_DIR}" ] && return 1
    [ -z "${ARCHIVE_DIR_NAME}" ] && return 1

    cd "${MAIN_DIR}"
    for DIR in ${ARCHIVE_DIR_NAME}* ; do
        [ ! -d "${MAIN_DIR}/${DIR}" ] && continue

        cd "${MAIN_DIR}/${DIR}"
        WriteAppRun
    done
}
