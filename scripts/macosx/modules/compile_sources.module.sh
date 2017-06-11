#####################################################################
# This function will compile sources.
#####################################################################
function compile_sources()
{
    cd "${PSI_DIR}/build"

    sed -i "" "s/build\/admin\/build\/deps\/qca-qt5\/include/deps_root\/lib\/qca-qt5.framework\/Versions\/Current\/Headers/" psi.pro
    echo "LIBS += ${DEPS_ROOT}/lib -framework qca" >> psi.pro
    echo "QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9" >> psi.pro
    echo "QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9" >> iris/src/irisnet/noncore/noncore.pro
    echo "QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9" >> iris/src/xmpp/zlib/zlib.pri

    log "Running qconf..."
    QTDIR="${QTDIR}" ${QCONF} >> "${PSI_DIR}/logs/psi-qconf.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring Psi sources" "${PSI_DIR}/logs/psi-qconf.log"
    fi

    # Generate configure_opts that will contain all options we will pass
    # to ./configure later (including CONF_OPTS).
    log "Creating configure parameters..."
    local configure_opts="${CONF_OPTS} --disable-sparkle --with-idn-inc=${DEPS_ROOT}/include/ --with-idn-lib=${DEPS_ROOT}/lib --with-qca-inc=${DEPS_ROOT}/lib/qca-qt5.framework/Versions/Current/Headers --with-qca-lib=${DEPS_ROOT}/lib --with-qjdns-inc=${DEPS_ROOT}/include/ --with-qjdns-lib=${DEPS_ROOT}/lib --with-zlib-inc=${DEPS_ROOT}/include/ --with-zlib-lib=${DEPS_ROOT}/lib --with-growl=${DEPS_ROOT}/lib/"
    if [ ${ENABLE_WEBKIT} -eq 1 ]; then
        local configure_opts="${configure_opts} --enable-webkit"
    fi

    log "Configuring Psi+"
    ./configure ${configure_opts} > "${PSI_DIR}/logs/psi-configure.log"
    if [ $? -ne 0 ]; then
        action_failed "Configuring Psi" "${PSI_DIR}/logs/psi-configure.log"
    fi

    echo "QMAKE_MAC_SDK = macosx10.9" >> conf.pri

    # Compile it!
    log "Starting psi-plus compilation. Logs redirected to '${PSI_DIR}/logs/psi-make.log'..."
    ${MAKE} ${MAKEOPTS} VERSION=${VERSION_STRING_RAW} >> "${PSI_DIR}/logs/psi-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Compiling Psi" "${PSI_DIR}/logs/psi-make.log"
    fi
}
