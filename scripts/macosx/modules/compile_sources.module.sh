#####################################################################
# This function will compile sources.
#####################################################################
function compile_sources()
{
    cd "${PSI_DIR}/build"

    log "Running qconf..."
    QTDIR="${QTDIR}" ${QCONF} >> "${PSI_DIR}/logs/psi-qconf.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring Psi sources" "${PSI_DIR}/logs/psi-qconf.log"
    fi

    cd "${PSI_DIR}/build/admin/build"
    # Generate configure_opts that will contain all options we will pass
    # to ./configure later (including CONF_OPTS).
    log "Creating configure parameters..."
    local configure_opts="${CONF_OPTS} --disable-sparkle"
    if [ ${ENABLE_WEBKIT} -eq 1 ]; then
        local configure_opts="${configure_opts} --enable-webkit"
    fi

    # Put configure_opts into some scripts.
    sed -i "" "s@./configure@& ${configure_opts}@g" build_package.sh
    sed -i "" "s@./configure@& ${configure_opts}@g" devconfig.sh
    sed -i "" 's@echo "$(VERSION)@& (\@\@DATE\@\@)@g' Makefile

    # Compile it!
    log "Starting psi-plus compilation. Logs redirected to '${PSI_DIR}/logs/psi-make.log'..."
    ${MAKE} ${MAKEOPTS} VERSION=${VERSION_STRING_RAW} >> "${PSI_DIR}/logs/psi-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Compiling Psi" "${PSI_DIR}/logs/psi-make.log"
    fi
}
