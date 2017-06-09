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
    if [ ! -d "${DEPS_DIR}" ]; then
        log "Creating directory for dependencies: '${DEPS_DIR}'"
        mkdir -p "${DEPS_DIR}" || die "Can't create work directory ${DEPS_DIR}!"
    fi

    # Directory for build process.
    if [ -d "${PSI_DIR}/build" ]; then
        log "Build directory exists, removing..."
        rm -rf "${PSI_DIR}/build"
    fi
    log "Creating build directory: '${PSI_DIR}/build'"
    mkdir -p "${PSI_DIR}/build"

    # Directory for logs.
    PSIBUILD_LOGS_PATH="${PSI_DIR}/logs"
    if [ -d "${PSIBUILD_LOGS_PATH}" ]; then
        log "Logs directory exists, removing..."
        rm -rf "${PSIBUILD_LOGS_PATH}"
    fi
    log "Creating logs directory: '${PSIBUILD_LOGS_PATH}'"
    mkdir -p "${PSIBUILD_LOGS_PATH}"

}
