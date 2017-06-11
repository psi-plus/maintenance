#####################################################################
# This function installs required for build tools in ${PSI_DIR}/deps
# directory.
#####################################################################
function install_build_deps()
{
    log "Installing build dependencies..."
    # QConf.
    local QCONFDIR="${PSI_DIR}/qconf-qt5"

    if [ -f "${QCONFDIR}/qconf" ]; then
        # Okay, qconf already compiled.
        QCONF="${QCONFDIR}/qconf"
        log "Found qconf binary: '${QCONF}'"
    else
        # qconf isn't found.
        log "Installing qconf..."
        mkdir -p "${QCONFDIR}" && cd $_
        if [ ! -d ".git" ]; then
            git clone "${GIT_REPO_DEP_QCONF}" .
        else
            git pull
        fi
        local qconf_conf_opts="--qtdir=${QTDIR}"
        ./configure ${qconf_conf_opts}
        if [ $? -ne 0 ]; then
            action_failed "QConf sources configuration" "None"
        fi
        ${MAKE} ${MAKEOPTS} >> "${PSI_DIR}/logs/qconf-make.log" 2>&1
        if [ $? -ne 0 ]; then
            action_failed "QConf compilation" "${PSI_DIR}/logs/qconf-make.log"
        fi
        QCONF="${QCONFDIR}/qconf"
    fi
}
