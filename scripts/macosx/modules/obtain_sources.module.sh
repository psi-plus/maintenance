#####################################################################
# This function obtains Psi and Psi+ sources.
#####################################################################
function obtain_sources()
{
    log "Getting sources..."

    log "Getting Psi sources..."

    # Separate clone-pull algo for Psi sources.
    if [ ! -d "${PSI_SOURCE_DIR}/.git" ]; then
        # Clone sources.
        if [ "${SOURCE_TYPE}" == "snapshot" ]; then
            log "Using snapshotted sources"
            git clone ${GIT_REPO_PSI_SNAPSHOTTED} ${PSI_SOURCE_DIR}
        elif [ "${SOURCE_TYPE}" == "git" ]; then
            log "Using git sources"
            git clone ${GIT_REPO_PSI} ${PSI_SOURCE_DIR}
        else
            # Something bad happen, and SOURCE_TYPE contains something strange
            # and unexpected.
            die "Unknown Psi source type: '${SOURCE_TYPE}'"
        fi
    else
        # Update sources.
        log "Found already cloned sources, updating..."
        cd ${PSI_SOURCE_DIR}
        git pull
    fi

    # Check git exitcode. If it is not zero - we should not continue.
    if [ $? -ne 0 ]; then
        die "Git failed."
    fi

    # Obtain submodules.
    log "Updating submodules..."
    cd "${PSI_SOURCE_DIR}"
    git submodule update --init

    # Obtain psi dependencies.
    if [ ! -d "${PSI_DIR}/psideps" ]; then
        log "Obtaining Psi dependencies..."
        git clone ${GIT_REPO_PSIDEPS} "${PSI_DIR}/psideps"
    else
        log "Updating Psi dependencies..."
        cd "${PSI_DIR}/psideps"
        git pull
    fi

    # Obtain other sources.
    for item in PLUS PLUGINS MAINTENANCE RESOURCES; do
        local var="GIT_REPO_${item}"
        local source_address="${!var}"
        local lower_item=`echo ${item} | awk {' print tolower($0) '}`
        log "Obtaining sources for '${lower_item}'..."

        if [ ! -d "${PSI_DIR}/${lower_item}" ]; then
            mkdir -p "${PSI_DIR}/${lower_item}"
        fi

        if [ -d "${PSI_DIR}/${lower_item}/.git" ]; then
            log "Previous sources found, updating..."
            cd "${PSI_DIR}/${lower_item}"
            git pull
        else
            git clone ${source_address} "${PSI_DIR}/${lower_item}"
        fi

        # Check git exitcode. If it is not zero - we should not continue.
        if [ $? -ne 0 ]; then
            die "Git failed."
        fi
    done
    echo ${SOURCE_TYPE} > "${PSI_SOURCE_DIR}/source_type"

    log "Obtaining translations..."
    if [ ! -d "${PSI_DIR}/translations" ]; then
        mkdir -p "${PSI_DIR}/translations"
        git clone ${GIT_REPO_LANGS} "${PSI_DIR}/translations"
    else
        cd "${PSI_DIR}/translations"
        git pull
    fi

    log "Fetching dependencies..."
    PSI_FETCH="${PSI_SOURCE_DIR}/admin/fetch.sh"
    . "${PSI_SOURCE_DIR}/admin/build/package_info"

    cd "${PSI_DIR}"
    mkdir -p packages deps
    if [ ! -f "packages/${growl_file}" ]
    then
        sh ${PSI_FETCH} ${growl_url} packages/${growl_file}
        cd deps && unzip ../packages/${growl_file} && cd ..
    fi
    if [ ! -f "packages/${gstbundle_mac_file}" ]
    then
        sh ${PSI_FETCH} ${gstbundle_mac_url} packages/${gstbundle_mac_file}
        cd deps && tar jxvf ../packages/${gstbundle_mac_file} && cd ..
    fi
    if [ ! -f "packages/${psimedia_mac_file}" ]
    then
        sh ${PSI_FETCH} ${psimedia_mac_url} packages/${psimedia_mac_file}
        cd deps && tar jxvf ../packages/${psimedia_mac_file} && cd ..
    fi
    if [ ! -f "packages/${qca_mac_file}" ]
    then
        sh ${PSI_FETCH} ${qca_mac_url} packages/${qca_mac_file}
        cd deps && tar jxvf ../packages/${qca_mac_file} && cd ..
    fi

}
