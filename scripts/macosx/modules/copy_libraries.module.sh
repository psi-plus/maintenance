#####################################################################
# This function will bundle neccessary libraries.
#####################################################################
function copy_libraries()
{
    log "Bundling neccessary libraries..."

    # Bundle libraries from /usr/local, if any.
    local brew_libs_to_bundle=`otool -L ${PSIAPP_DIR}/MacOS/psi-plus | grep "/usr/local" | awk {' print $1 '}`
    log "Bundling Homebrew-installed libraries, if neccessary..."

    for lib in ${brew_libs_to_bundle[@]}; do
        local lib_path=`echo $lib | awk {' print $1 '}`
        local lib_name=`echo $lib_path | awk -F"/" {' print $NF '}`
        log "Bundling homebrew library: ${lib_name}"
        install_name_tool -change "${lib_path}" "@executable_path/../Frameworks/${lib_name}" "${PSIAPP_DIR}/MacOS/psi-plus"
        cp -a "${lib}" "${PSIAPP_DIR}/Frameworks"
    done

    # Go thru all bundled libraries, and check for dependencies.
    # If something is outside of bundle - install it.
    log "Bundling Qt library dependencies..."
    QTLIBS=`find ${PSIAPP_DIR}/Frameworks -type f -name "Qt*" | grep -v ".prl"`
    bundle_library "${PSIAPP_DIR}/Frameworks" ${QTLIBS[@]}

    LIBS=`find ${PSIAPP_DIR}/Frameworks -type f -name "*.dylib"`
    log "Bundling libraries dependencies..."
    bundle_library "${PSIAPP_DIR}/Frameworks" ${LIBS[@]}
}
