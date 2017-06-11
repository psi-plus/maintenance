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
contains(QT_CONFIG,x86_64):CONFIG += x86_64
QMAKE_MAC_SDK = macosx10.9
EOF

    # Compile plugins
    local PLUGINS=`ls -1 ${PSI_DIR}/build/src/plugins/generic/ | grep -v "videostatusplugin"`
    for plugin in ${PLUGINS}; do
        if [ "${plugin}" == "CMakeLists.txt" -o "${plugin}" == "generic.pro" -o "${DISABLED_PLUGINS/${plugin}}" != "${DISABLED_PLUGINS}" ]; then
            :
        elif [ "${plugin}" == "otrplugin" ]; then
            cd "${PSI_DIR}/build/src/plugins/generic/${plugin}"
            log "Compiling ${plugin} plugin"
            echo "INCLUDEPATH += ${DEPS_ROOT}/include/ ${DEPS_ROOT}/include/libotr" >> otrplugin.pro
            echo "LIBS += -L${DEPS_ROOT}/lib" >> otrplugin.pro
            log "Compiling ${plugin} plugin"
            ${QMAKE} ${plugin}.pro >> "${PSI_DIR}/logs/plugins/${plugin}-qmake.log" 2>&1
            if [ $? -ne 0 ]; then
                action_failed "Configuring ${plugin}" "${PSI_DIR}/logs/plugins/${plugin}-qmake.log"
            fi
            ${MAKE} ${MAKEOPTS} >> "${PSI_DIR}/logs/plugins/${plugin}-make.log" 2>&1
            if [ $? -ne 0 ]; then
                action_failed "Building ${plugin}" "${PSI_DIR}/logs/plugins/${plugin}-make.log"
            fi
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
