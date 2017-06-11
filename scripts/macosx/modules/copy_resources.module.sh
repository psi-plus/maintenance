#####################################################################
# This function copying compiled data, translations and other assets
# into bundle.
#####################################################################
function copy_resources()
{
    log "Copying resources into bundle..."
    mv "${PSI_DIR}/build/psi-plus.app/" "${PSI_DIR}/build/Psi+.app/"
    PSIAPP_DIR="${PSI_DIR}/build/Psi+.app/"
    mkdir -p "${PSIAPP_DIR}/Contents/Resources/"
    cd "${PSIAPP_DIR}/Contents/Resources/"

    log "Copying Psi resources..."
    cp -r "${PSI_DIR}/build/sound" .
    cp -r "${PSI_DIR}/build/themes" .

    log "Copying themes..."
    for item in `ls -1 ${PSI_DIR}/build/themes/`; do
        cp -R "${PSI_DIR}/build/themes/${item}" "${PSIAPP_DIR}/Contents/Resources/themes/${item}"
    done

    log "Copying translations..."

    mkdir -p translations
    cp -R "${PSI_DIR}/translations/compiled/" "${PSIAPP_DIR}/Contents/Resources/translations/"

    log "Copying Psi+ resources..."
    for item in `ls -1 "${PSI_DIR}/resources"`; do
        cp -a "${PSI_DIR}/resources/${item}" "${PSIAPP_DIR}/Contents/Resources/"
    done
    cp "${PSI_DIR}/build/client_icons.txt" "${PSIAPP_DIR}/Contents/Resources/"

    log "Copying plugins..."
    if [ ! -d "${PSIAPP_DIR}/Contents/Resources/plugins" ]; then
            mkdir -p "${PSIAPP_DIR}/Contents/Resources/plugins"
    fi

    local PLUGINS=`ls -1 ${PSI_DIR}/build/src/plugins/generic/ | grep -v "videostatusplugin"`
    for plugin in ${PLUGINS}; do
        if [ "${plugin}" == "CMakeLists.txt" -o "${plugin}" == "generic.pro" -o "${DISABLED_PLUGINS/${plugin}}" != "${DISABLED_PLUGINS}" ]; then
            :
        else
            log "Installing plugin ${plugin}"
            cd "${PSI_DIR}/build/src/plugins/generic/${plugin}/"
            cp *.dylib "${PSIAPP_DIR}/Contents/Resources/plugins/"
        fi
    done
}
