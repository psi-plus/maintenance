#####################################################################
# This function copying compiled data, translations and other assets
# into bundle.
#####################################################################
function copy_resources()
{
    log "Copying resources into bundle..."
    PSIAPP_DIR="${PSI_DIR}/build/admin/build/dist/psi-${VERSION_STRING_RAW}-mac/Psi+.app/Contents"
    cd "${PSIAPP_DIR}/Resources/"

    log "Copying Psi resources..."
    cp -r "${PSI_DIR}/build/sound" .
    cp -r "${PSI_DIR}/build/themes" .

    log "Copying themes..."
    for item in `ls -1 ${PSI_DIR}/build/themes/`; do
        cp -R "${PSI_DIR}/build/themes/${item}" "${PSIAPP_DIR}/Resources/themes/${item}"
    done

    log "Copying translations..."

    mkdir -p translations
    cp -R "${PSI_DIR}/translations/compiled/" "${PSIAPP_DIR}/Resources/translations/"

    log "Copying Psi+ resources..."
    for item in `ls -1 "${PSI_DIR}/resources"`; do
        cp -a "${PSI_DIR}/resources/${item}" "${PSIAPP_DIR}/Resources/"
    done
    cp "${PSI_DIR}/build/client_icons.txt" "${PSIAPP_DIR}/Resources/"

    log "Copying plugins..."
    if [ ! -d "${PSIAPP_DIR}/Resources/plugins" ]; then
            mkdir -p "${PSIAPP_DIR}/Resources/plugins"
    fi

    local PLUGINS=`ls -1 ${PSI_DIR}/build/src/plugins/generic/ | grep -v "videostatusplugin"`
    for plugin in ${PLUGINS}; do
        log "Installing plugin ${plugin}"
        cd "${PSI_DIR}/build/src/plugins/generic/${plugin}/"
        cp *.dylib "${PSIAPP_DIR}/Resources/plugins/"
    done

    log "Copying libraries..."
    PSIPLUS_PLUGINS=`ls $PSIAPP_DIR/Resources/plugins`
    QT_FRAMEWORKS="QtCore QtNetwork QtXml QtGui QtWebKit QtSvg"
    QT_FRAMEWORK_VERSION=4
    for f in ${QT_FRAMEWORKS}; do
        for p in ${PSIPLUS_PLUGINS}; do
            install_name_tool -change "${QTDIR}/lib/${f}.framework/Versions/${QT_FRAMEWORK_VERSION}/${f}" "@executable_path/../Frameworks/${f}.framework/Versions/${QT_FRAMEWORK_VERSION}/${f}" "${PSIAPP_DIR}/Resources/plugins/${p}"
        done
    done

    if [ ${ENABLE_DEV_PLUGINS} -eq 1 ]; then
        otr_deps=`ls $OTRDEPS_DIR/uni/lib | grep "dylib"`
        for d in $otr_deps; do
            cp -a "$OTRDEPS_DIR/uni/lib/$d" "${PSIAPP_DIR}/Frameworks/$d"
        done
    fi
}
