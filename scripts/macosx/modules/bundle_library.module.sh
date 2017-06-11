#####################################################################
# This function bundle library with rewriting of all neccessary links
# and paths. Also work on psi-plus binary itself.
#####################################################################
function bundle_library()
{
    local path=$1
    shift
    local libs=$@
    for library in ${libs[@]}; do
        # Filename of library.
        local lfname=`echo ${library} | awk -F"/" {' print $NF '}`
        # Check libs deps
        deps=`otool -L ${library} | awk {' print $1 '} | grep -v "/usr/lib\|/System/Library"`
        for dep in ${deps[@]}; do
            # If we have dependency name not equal to library name, and
            # even not containing it.
            if [ "${dep/${lfname}}" == "${dep}" ]; then
                # If it is not already bundled.
                if [ "${dep/executable_path}" == "${dep}" ]; then
                    log "Found unbundled depencency '${dep}' for library '${lfname}'"
                    local lib_path=`echo $dep | awk {' print $1 '}`
                    local lib_name=`echo $lib_path | awk -F"/" {' print $NF '}`
                    install_name_tool -change "${lib_path}" "@executable_path/../Frameworks/${lib_name}" "${library}"
                    cp -a "${dep}" "${path}" &>/dev/null
                    # We should make a symlink if cp failed. This means that
                    # $dep is a file in current directory.
                    if [ $? -ne 1 ]; then
                        cd "${PSIAPP_DIR}/Contents/Frameworks"
                        ln -s "${dep}" "${lfname}"
                    fi
                fi
            fi
        done
    done
}
