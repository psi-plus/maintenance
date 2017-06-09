#####################################################################
# This function will compile plugins.
#####################################################################
function compile_plugins()
{
    log "Compiling plugins..."
    cd "${PSI_DIR}/build/src/plugins"

    # Logs directory check.
    if [ ! -d "${PSI_DIR}/logs/plugins/" ]; then
        mkdir -p "${PSI_DIR}/logs/plugins/"
    fi

    # qmake config for plugins.
    cat >> psiplugin.pri << "EOF"
contains(QT_CONFIG,x86):CONFIG += x86
contains(QT_CONFIG,x86_64):CONFIG += x86_64
EOF

    # Compile plugins
    local PLUGINS=`ls -1 ${PSI_DIR}/build/src/plugins/generic/ | grep -v "videostatusplugin"`
    for plugin in ${PLUGINS}; do
        if [ "${plugin}" == "otrplugin" ]; then
            # We should launch separate compilation script for otrplugin
            # which will download and compile some dependencies for it, and
            # then will compile plugin itself.
            OTRDEPS_DIR="${PSI_DIR}/otrdeps"
            sh ${PSI_DIR}/maintenance/scripts/macosx/otrdeps.sh ${OTRDEPS_DIR} ${PSI_DIR}/build/src/plugins/generic/${plugin} 2>/dev/null || die "make ${plugin} plugin failed"
        else
            # This is default plugin compilation sequence.
            cd "${PSI_DIR}/build/src/plugins/generic/${plugin}"
            log "Compiling ${plugin} plugin"
            ${QMAKE} ${plugin}.pro >> "${PSI_DIR}/logs/plugins/${plugin}-qmake.log" 2>&1
            if [ $? -ne 0 ]; then
                action_failed "Configuring ${plugin}" "${PSI_DIR}/logs/plugins/${plugin}-qmake.log"
            fi
            ${MAKE} ${MAKEOPTS} >> "${PSI_DIR}/logs/plugins/${plugin}-make.log" 2>&1
            if [ $? -ne 0 ]; then
                action_failed "Building ${plugin}" "${PSI_DIR}/logs/plugins/${plugin}-make.log"
            fi
        fi
    done
}
