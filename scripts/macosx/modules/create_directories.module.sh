#####################################################################
# This function created neccessary directory structure and defines
# variables for each of four subdirectories.
#####################################################################
function create_directories()
{
    log "Creating directory structure..."

    # Root directory for build process.
    if [ ! -d "${PSI_DIR}" ]; then
        log "Creating root directory: '${PSI_DIR}'"
        mkdir -p "${PSI_DIR}" || die "Can't create work directory ${PSI_DIR}!"
    fi

    # Directory for dependencies handling.
    if [ ! -d "${DEPS_ROOT}" ]; then
        log "Creating directory for dependencies: '${DEPS_ROOT}'"
        mkdir -p "${DEPS_ROOT}" || die "Can't create work directory ${DEPS_ROOT}!"
    fi

    log "Creating build directory: '${PSI_DIR}/build'"
    mkdir -p "${PSI_DIR}/build"

    if [ ! -d "${DEPS_BUILDROOT}" ]; then
        log "Creating dependencies build directory: '${DEPS_BUILDROOT}'"
        mkdir -p "${DEPS_BUILDROOT}"
    fi

    # Directory for logs.
    PSIBUILD_LOGS_PATH="${PSI_DIR}/logs"
    if [ -d "${PSIBUILD_LOGS_PATH}" ]; then
        log "Logs directory exists, removing..."
        rm -rf "${PSIBUILD_LOGS_PATH}"
    fi
    log "Creating logs directory: '${PSIBUILD_LOGS_PATH}'"
    mkdir -p "${PSIBUILD_LOGS_PATH}/deps"
    mkdir -p "${PSIBUILD_LOGS_PATH}/plugins"

    # Psi sources
    if [ ! -d "${PSI_DIR}/psi" ]; then
        log "Creating directory for Psi sources..."
        mkdir -p "${PSI_DIR}/psi"
        obtain_sources
    fi
}
