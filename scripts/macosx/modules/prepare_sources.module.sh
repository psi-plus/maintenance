#####################################################################
# This function prepares sources to be built.
#####################################################################
function prepare_sources()
{
    log "Preparing sources..."

    # Copy data to build directory.
    log "Copying sources to build directory..."
    cp -a "${PSI_SOURCE_DIR}/" "${PSI_DIR}/build"

    # Create version string.
    log "Creating version string for about dialog..."
    # Snapshotted thing already have everything for version string.
    if [ "${SOURCE_TYPE}" == "git" ]; then
        PSI_REVISION=`cd "${PSI_SOURCE_DIR}" && git describe --tags | cut -d - -f 2`
        PSI_PLUS_REVISION=`cd "${PSI_DIR}/plus" && git describe --tags | cut -d - -f 2`
        PSI_PLUS_TAG=`cd "${PSI_DIR}/plus" && git describe --tags | cut -d - -f 1`
        VERSION_STRING_RAW="${PSI_PLUS_TAG}.${PSI_PLUS_REVISION}.${PSI_REVISION}"
        if [ ${ENABLE_WEBKIT} -eq 1 ]; then
            VERSION_STRING_RAW="${VERSION_STRING_RAW}-webkit"
        fi
    else
        VERSION_STRING_RAW=`cd "${PSI_SOURCE_DIR}" && git describe --tags | cut -d - -f 2`
        if [ ${ENABLE_WEBKIT} -eq 1 ]; then
            VERSION_STRING_RAW="${VERSION_STRING_RAW}-webkit"
        fi
    fi
    VERSION_STRING="${VERSION_STRING_RAW} ($(date +"%Y-%m-%d"))"

    log "Version string: ${VERSION_STRING}"
    log "Raw version string (will be used e.g. in filename): ${VERSION_STRING_RAW}"
    echo ${VERSION_STRING} > "${PSI_DIR}/build/version"

    log "Removing default plugins, they do not work as expected"
    rm -rf "${PSI_DIR}/build/src/plugins/generic"

    log "Copying iconsets to build directory..."
    cp -a "${PSI_DIR}/plus/iconsets" "${PSI_DIR}/build"

    log "Copying generic plugins to build directory..."
    mkdir -p "${PSI_DIR}/build/src/plugins/generic"
    for plugin in `ls ${PSI_DIR}/plugins/generic/`; do
        cp -R "${PSI_DIR}/plugins/generic/${plugin}" "${PSI_DIR}/build/src/plugins/generic"
    done

    if [ ${ENABLE_DEV_PLUGINS} -eq 1 ]; then
        log "Copying unstable (dev) plugins to build directory..."
        cp -a "${PSI_DIR}/plugins/dev/" "${PSI_DIR}/build/src/plugins/generic"
        #for plugin in `ls ${PSI_DIR}/plugins/dev/`; do
        #    cp -R "${PSI_DIR}/plugins/dev/${plugin}" "${PSI_DIR}/build/src/plugins/generic"
        #done
    fi

    log "Applying patches..."
    local patches_common=`ls -1 ${PSI_DIR}/plus/patches/*diff 2>/dev/null`
    local patches_osx=`ls -1 ${PSI_DIR}/plus/patches/mac/*diff 2>/dev/null`

    cd "${PSI_DIR}/build"
    # Applying generic patches.
    # This should be skipped if we're building from snapshot, because source
    # was already patched with generic patches.
    if [ ${SKIP_GENERIC_PATCHES} -eq 0 ]; then
        log "Applying common patches..."
        for item in ${patches_common[@]}; do
            apply_patch "${item}"
        done
    fi

    # OS X patches. Should always be applied.
    log "Applying OS X patches..."
    for item in ${patches_osx[@]}; do
        apply_patch "${item}"
    done

    # Sed magic. Quick'n'easy.
    log "Executing some sed magic..."
    sed -i "" "s/.xxx/.${PSI_PLUS_REVISION}/" src/applicationinfo.cpp
    sed -i "" "s:target.path.*:target.path = ${PSILIBDIR}/psi-plus/plugins:" src/plugins/psiplugin.pri

    sed -i "" "s/<string>psi<\/string>/<string>psi-plus<\/string>/g" mac/Info.plist.in
    sed -i "" "s/<\!--<dep type='sparkle'\/>-->/<dep type='sparkle'\/>/g" psi.qc

    sed -i "" "s/base\/psi.app/base\/psi-plus.app/" admin/build/prep_dist.sh
    sed -i "" "s/base\/Psi.app/base\/Psi+.app/" admin/build/prep_dist.sh
    sed -i "" "s/MacOS\/psi/MacOS\/psi-plus/" admin/build/prep_dist.sh
    sed -i "" "s/QtXml QtGui/QtXml QtGui QtWebKit QtSvg/" admin/build/prep_dist.sh
    sed -i "" "s/.\/pack_dmg.sh/# .\/pack_dmg.sh/" admin/build/Makefile

    sed -i "" "s/build\/admin\/build\/deps\/qca-qt5\/include/deps_root\/lib\/qca-qt5.framework\/Versions\/Current\/Headers/" psi.pro

    if [ ${ENABLE_WEBKIT} == 1 ]; then
        sed -i "" "s/psi-plus-mac.xml/psi-plus-wk-mac.xml/" src/applicationinfo.cpp
    fi

    # Removing "--std=gnu99" definition.
    # This is required for building with clang, apparently. It will not be built
    # without this.
    sed -i "" "/\*g\+\+\*\:QMAKE_OBJECTIVE_CFLAGS/d" "${PSI_DIR}/build/src/libpsi/tools/globalshortcut/globalshortcut.pri"

    log "Copying application icon..."
    cp -f "${PSI_DIR}/maintenance/scripts/macosx/application.icns" "${PSI_DIR}/build/mac/application.icns"

    log "Adding translations..."
    local available_translations=`ls ${PSI_DIR}/translations/translations | grep -v en | sed s/psi_// | sed s/.ts//`

    if [ ! -d "${PSI_DIR}/translations/compiled" ]; then
        mkdir -p "${PSI_DIR}/translations/compiled"
    fi

    if [ ${BUNDLE_ALL_TRANSLATIONS} -eq 1 ]; then
        log "Preparing all available translations..."
        for translation in ${available_translations[@]}; do
            log "Compiling translation for ${translation}..."
            cp -f "${PSI_DIR}/translations/translations/psi_${translation}.ts" "${PSI_DIR}/translations/compiled/"
            ${LRELEASE} "${PSI_DIR}/translations/compiled/psi_${translation}.ts" &>/dev/null
            rm "${PSI_DIR}/translations/compiled/psi_${translation}.ts"
        done
    fi

    log "Copying dependencies..."
    cd "${PSI_DIR}/build/admin/build"
    cp -a "${PSI_DIR}/packages/" packages/
    cp -a "${PSI_DIR}/deps/" deps/

    # We have some self-compiled dependencies for Qt5. Add them to psi.pro.
    if [ ${QT_VERSION_MAJOR} -eq 5 ]; then
        echo "INCLUDEPATH += ${PSI_DIR}/build/admin/build/deps/qca-qt5/include" >> "${PSI_DIR}/build/psi.pro"
    fi
}
