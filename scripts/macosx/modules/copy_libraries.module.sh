QT_FRAMEWORKS="QtCore QtNetwork QtXml QtGui QtMultimedia QtMultimediaWidgets QtWidgets QtConcurrent QtPrintSupport QtOpenGL QtSvg QtWebEngineWidgets QtWebEngineCore QtQuick QtQml QtWebChannel QtPositioning QtQuickWidgets"  #QtDBus QtWebEngine

QT_PLUGINS="audio/libqtaudio_coreaudio.dylib bearer/libqcorewlanbearer.dylib bearer/libqgenericbearer.dylib platforms/libqcocoa.dylib printsupport/libcocoaprintersupport.dylib iconengines/libqsvgicon.dylib"
QT_PLUGINS="${QT_PLUGINS} mediaservice/libqtmedia_audioengine.dylib mediaservice/libqavfmediaplayer.dylib imageformats/libqgif.dylib imageformats/libqjpeg.dylib imageformats/libqsvg.dylib  imageformats/libqwbmp.dylib imageformats/libqtiff.dylib imageformats/libqwebp.dylib  imageformats/libqtga.dylib imageformats/libqico.dylib imageformats/libqicns.dylib imageformats/libqmacjp2.dylib"

#####################################################################
# This function will bundle neccessary libraries.
#####################################################################
function copy_libraries()
{
    log "Bundling neccessary libraries..."

    # Bundle libraries from /usr/local, if any.
    local brew_libs_to_bundle=`otool -L ${PSIAPP_DIR}/Contents/MacOS/psi-plus | grep "/usr/local" | awk {' print $1 '}`

    for lib in ${brew_libs_to_bundle[@]}; do
        log "WARNING: homebrew library: ${lib_name}, Psi+ might not be distributable!"
    done

    mkdir -p "${PSIAPP_DIR}/Contents/Frameworks"

    # Copy Qt libraries.
    for f in $QT_FRAMEWORKS; do
        cp -a ${QTDIR}/lib/$f.framework ${PSIAPP_DIR}/Contents/Frameworks
        cleanup_framework "${PSIAPP_DIR}/Contents/Frameworks/${f}.framework" "${f}" "5"
    done

    for p in $QT_PLUGINS; do
        mkdir -p ${PSIAPP_DIR}/Contents/PlugIns/$(dirname $p);
        cp -a ${QTDIR}/plugins/$p ${PSIAPP_DIR}/Contents/PlugIns/$p
    done

    qt_conf_file="${PSIAPP_DIR}/Contents/Resources/qt.conf"
    touch ${qt_conf_file}
    echo "[Paths]" >> ${qt_conf_file}
    echo "Plugins = PlugIns" >> ${qt_conf_file}

    install_name_tool -add_rpath "@executable_path/../Frameworks" "${PSIAPP_DIR}/Contents/MacOS/psi-plus"

    # Copy QCA.
    cp -R "${DEPS_ROOT}/lib/qca-qt5.framework" "${PSIAPP_DIR}/Contents/Frameworks"
    cleanup_framework "${PSIAPP_DIR}/Contents/Frameworks/qca-qt5.framework" "qca-qt5" "2.2.0"
    mkdir -p "${PSIAPP_DIR}/Contents/PlugIns/crypto/"
    local QCA_PLUGINS=`ls ${DEPS_ROOT}/lib/qca-qt5/crypto | grep "dylib"`

    for p in $QCA_PLUGINS; do
        cp -f "${DEPS_ROOT}/lib/qca-qt5/crypto/$p" "${PSIAPP_DIR}/Contents/PlugIns/crypto/$p"

                install_name_tool -change "${DEPS_ROOT}/lib/libcrypto.1.0.0.dylib" "@executable_path/../Frameworks/libcrypto.dylib"    "${PSIAPP_DIR}/Contents/PlugIns/crypto/$p"
                install_name_tool -change "${DEPS_ROOT}/lib/libssl.1.0.0.dylib"    "@executable_path/../Frameworks/libssl.dylib"       "${PSIAPP_DIR}/Contents/PlugIns/crypto/$p"
        install_name_tool -change "${DEPS_ROOT}/lib/libgcrypt.20.dylib"   "@executable_path/../Frameworks/libgcrypt.dylib"    "${PSIAPP_DIR}/Contents/PlugIns/crypto/$p"
                install_name_tool -change "${DEPS_ROOT}/lib/libgpg-error.0.dylib" "@executable_path/../Frameworks/libgpg-error.dylib" "${PSIAPP_DIR}/Contents/PlugIns/crypto/$p"
    done

    # Other libs.
    cp -f "${DEPS_ROOT}/lib/libz.dylib"     "${PSIAPP_DIR}/Contents/Frameworks/"
    cp -f "${DEPS_ROOT}/lib/libidn.dylib"   "${PSIAPP_DIR}/Contents/Frameworks/"
    cp -f "${DEPS_ROOT}/lib/libssl.dylib"    "${PSIAPP_DIR}/Contents/Frameworks/"
    cp -f "${DEPS_ROOT}/lib/libcrypto.dylib" "${PSIAPP_DIR}/Contents/Frameworks/"
    chmod +w "${PSIAPP_DIR}/Contents/Frameworks/libssl.dylib"
    chmod +w "${PSIAPP_DIR}/Contents/Frameworks/libcrypto.dylib"

    install_name_tool -id "@executable_path/../Frameworks/libz.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libz.dylib"
    install_name_tool -id "@executable_path/../Frameworks/libidn.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libidn.dylib"
    install_name_tool -id "@executable_path/../Frameworks/libssl.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libssl.dylib"
    install_name_tool -change "${DEPS_ROOT}/lib/libcrypto.1.0.0.dylib" "@executable_path/../Frameworks/libcrypto.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libssl.dylib"
    install_name_tool -id "@executable_path/../Frameworks/libcrypto.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libcrypto.dylib"

    install_name_tool -change "${DEPS_ROOT}/lib/libz.1.dylib"    "@executable_path/../Frameworks/libz.dylib"   "${PSIAPP_DIR}/Contents/MacOS/psi-plus"
    install_name_tool -change "${DEPS_ROOT}/lib/libidn.11.dylib" "@executable_path/../Frameworks/libidn.dylib" "${PSIAPP_DIR}/Contents/MacOS/psi-plus"

    # OTR.
    cp -f "${DEPS_ROOT}/lib/libgpg-error.dylib" "${PSIAPP_DIR}/Contents/Frameworks/"
    cp -f "${DEPS_ROOT}/lib/libgcrypt.dylib"    "${PSIAPP_DIR}/Contents/Frameworks/"
    cp -f "${DEPS_ROOT}/lib/libotr.dylib"       "${PSIAPP_DIR}/Contents/Frameworks/"

    install_name_tool -id "@executable_path/../Frameworks/libgpg-error.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libgpg-error.dylib"

    install_name_tool -id "@executable_path/../Frameworks/libgcrypt.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libgcrypt.dylib"
    install_name_tool -change "${DEPS_ROOT}/lib/libgpg-error.0.dylib" "@executable_path/../Frameworks/libgpg-error.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libgcrypt.dylib"

    install_name_tool -id "@executable_path/../Frameworks/libotr.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libotr.dylib"
        install_name_tool -change "${DEPS_ROOT}/lib/libgcrypt.20.dylib" "@executable_path/../Frameworks/libgcrypt.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libotr.dylib"
    install_name_tool -change "${DEPS_ROOT}/lib/libgpg-error.0.dylib" "@executable_path/../Frameworks/libgpg-error.dylib" "${PSIAPP_DIR}/Contents/Frameworks/libotr.dylib"

    install_name_tool -change "${DEPS_ROOT}/lib/libotr.5.dylib"       "@executable_path/../Frameworks/libotr.dylib"       "${PSIAPP_DIR}/Contents/Resources/plugins/libotrplugin.dylib"
    install_name_tool -change "${DEPS_ROOT}/lib/libgcrypt.20.dylib"   "@executable_path/../Frameworks/libgcrypt.dylib"    "${PSIAPP_DIR}/Contents/Resources/plugins/libotrplugin.dylib"
    install_name_tool -change "${DEPS_ROOT}/lib/libgpg-error.0.dylib" "@executable_path/../Frameworks/libgpg-error.dylib" "${PSIAPP_DIR}/Contents/Resources/plugins/libotrplugin.dylib"

    # Growl
    cp -R "${DEPS_ROOT}/lib/Growl.framework" "${PSIAPP_DIR}/Contents/Frameworks"
    cleanup_framework "${PSIAPP_DIR}/Contents/Frameworks/Growl.framework" "Growl" "A"

    # Go thru all bundled libraries, and check for dependencies.
    # If something is outside of bundle - install it.
    log "Bundling Qt library dependencies..."
    QTLIBS=`find ${PSIAPP_DIR}/Contents/Frameworks -type f -name "Qt*" | grep -v ".prl"`
    bundle_library "${PSIAPP_DIR}/Contents/Frameworks" ${QTLIBS[@]}

    LIBS=`find ${PSIAPP_DIR}/Contents/Frameworks -type f -name "*.dylib"`
    log "Bundling libraries dependencies..."
    bundle_library "${PSIAPP_DIR}/Contents/Frameworks" ${LIBS[@]}
}
