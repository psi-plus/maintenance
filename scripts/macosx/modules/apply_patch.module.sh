#####################################################################
# Patch helper.
#####################################################################
function apply_patch()
{
    local patch=$1
    local patch_file=`echo ${patch} | awk -F"/" {'print $NF'}`
    local patch_logs_dir="${PSI_DIR}/logs/patches/"
    if [ ! -d $"{patch_logs_dir}" ]; then
        mkdir -p "${patch_logs_dir}"
    fi
    local patch_log="${patch_logs_dir}/${patch_file}.log"
    log "Applying patch '${patch}'..."
    patch -p1 -i "${patch}" >> "${patch_log}" 2>&1
    if [ $? -ne 0 ]; then
        if [ ${SKIP_BAD_PATCHES} -eq 0 ]; then
            die "Patch failed. Cannot continue. Use --skip-bad-patches to\
skip patches that cannot be applied."
        else
            log "Patch failed. See '${patch_log}' for details."
        fi
    fi
}
