#####################################################################
# This function checks that environment are good for building Psi+.
# It'll check some environment variables (like QTDIR), as well as
# presence of required utilities.
#####################################################################
function check_environment()
{
    # Just a checking of OS where we launched this script. We shouldn't
    # allow anyone to runit anywhere besides OS X, isn't it?
    if [ `uname` != "Darwin" ]; then
        error "This script intended to be launched only on OS X!"
        die "Do you want your data to be vanished?"
    fi
    # Some Qt5 local vars.
    local qt5_found=0
    local qt5_path=""
    local qt5_version=""
    log "Checking environment..."
    # We should not even try to build as root. At all.
    if [ `whoami` == "root" ]; then
        die "${WE_WILL_BUILD} should not be built as root. Restart build process \
as normal user!"
    fi
    # Checking Qt presence and it's version.
    # If QTDIR environment variable wasn't defined - we will try to
    # autodetect installed Qt version.
    if [ ! -z "${QTDIR}" ]; then
        # QTDIR defined - skipping autodetection.
        log "Qt path passed: ${QTDIR}"
        local qt_v=`echo ${QTDIR} | awk -F"/" {' print $(NF) '}`
        if [ ${#qt_v} -eq 0 ]; then
            local qt_v=`echo ${QTDIR} | awk -F"/" {' print $(NF-1) '}`
        fi
        use_qt "${qt_v}" "${QTDIR}"

        # Check is we want to use Qt installed from website. In that case
        # we should add "clang_64" to QTDIR.
        if [ "${USE_QT5_FROM_WEBSITE}" == "1" ]; then
            use_qt "${qt_v}" "${QTDIR}/clang_64"
        fi
    else
        # Try to autodetect installed versions. We should detect one version
        # for Qt4 and one version for Qt5.
        # We are wanting self-compiled version of Qt4/5, so searching in
        # default prefix location (/usr/local/Trolltech/ for Qt4 and /usr/local/
        # for Qt5).
        log "QTDIR not defined, trying to autodetect Qt version..."
        local possible_qt5=`ls -1 /usr/local | grep "Qt-5*"`
        if [ ${#possible_qt5} -ne 0 ]; then
            qt5_found=1
        else
            qt5_found=0
        fi

        # Detect Qt5 path and version
        if [ ${qt5_found} -eq 1 ]; then
            # Detecting installed Qt5 version.
            # We are relying on assumption that Qt5 is installed in
            # /usr/local/. If you're installed Qt5 in other prefix
            # you should specify QTDIR manually.
            qt5_version=`echo ${possible_qt5} | grep Qt | awk '{print $NF}' | cut -d "-" -f 2`
            if [ "${#qt5_version}" -eq 0 ]; then
                die "Could not detect installed Qt5 version."
            else
                log "Detected Qt5 version: ${qt5_version}"
                use_qt "${qt5_version}" "/usr/local/Qt-${qt5_version}"
            fi
        fi
    fi

    # Prepare CMAKE_PREFIX_PATH.
    export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}:/usr/local/lib/cmake"
    if [ "${USE_QT5_FROM_WEBSITE}" == "1" ]; then
        export CMAKE_PREFIX_PATH="${QTDIR}/lib/cmake:${CMAKE_PREFIX_PATH}"
    fi
    log "Cmake module path: '${CMAKE_PREFIX_PATH}'"

    # Prepare PKG_CONFIG_PATH.
    export PKG_CONFIG_PATH="${DEPS_ROOT}/lib/pkgconfig:${PKG_CONFIG_PATH}"
    # Use tools from DEPS_ROOT/bin directory (notable gpg-error).
    export PATH="${DEPS_ROOT}/bin:${PATH}"

    # Compiler options.
    export MACOSX_DEPLOYMENT_TARGET=10.9
    export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.9
    export QMAKESPEC="macx-clang"

    # Libraries path.
    export DYLD_LIBRARY_PATH="${DEPS_ROOT}/lib:${DYLD_LIBRARY_PATH}"

    # Type of source. Can be "snapshot" or "git"
    SOURCE_TYPE=""

    # Build from snapshot sources of Psi, or from git?
    if [ ${BUILD_FROM_SNAPSHOT} -eq 1 ]; then
        SOURCE_TYPE="snapshot"
        PSI_SOURCE_DIR="${PSI_DIR}/psi/snapshot"
    else
        SOURCE_TYPE="git"
        PSI_SOURCE_DIR="${PSI_DIR}/psi/git"
    fi

    log "Psi sources directory: '${PSI_SOURCE_DIR}'"
}
