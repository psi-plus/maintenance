#####################################################################
# This function checks for tools required to build Psi+.
# It relies on QTDIR variable, that checked (or created) in
# check_environment function.
#####################################################################
function check_tools_presence()
{
    # Detecting make binary path.
    # It cannot be overrided from environment.
    MAKE=`whereis make | awk {' print $1'}`

    # Cmake path.
    CMAKE=`which cmake | awk {' print $1 '}`

    # Detecting qmake binary path.
    # It cannot be overrided from environment.
    QMAKE="${QTDIR}/bin/qmake"
    if [ ! -f "${QMAKE}" ]; then
        die "qmake not found! Please, install Qt!"
    fi
    log "Found qmake binary: '${QMAKE}'"

    # Detecting lrelease binary path.
    # It cannot be overrided from environment.
    LRELEASE="${QTDIR}/bin/lrelease"
    if [ ! -f "${LRELEASE}" ]; then
        die "lrelease not found! Please, install Qt from sources!"
    fi
    log "Found lrelease binary: '${LRELEASE}'"

    # Detecting git binary path.
    # It can be overrided with GIT environment variable (e.g.
    # GIT=/usr/bin/git)
    if [ ! -z "${GIT}" ]; then
        log "Found git binary (from env): ${GIT}"
    else
        # We know default git path.
        GIT="/usr/bin/git"
        # Check that binary exists. Just in case :)
        if [ ! -f "${GIT}" ]; then
            die "Git binary not found! Why you deleted it?"
        fi
        log "Found git binary: '${GIT}'"
    fi

    # Detect PlistBuddy, which is used for making portable version of Psi+.
    if [ ${PORTABLE} = 1 ]; then
        if [ -x "/usr/libexec/PlistBuddy" ]; then
            log "Found PlistBuddy"
        else
            die "PlistBuddy not found. This tool is required to make Psi+ be portable."
        fi
    fi
}
