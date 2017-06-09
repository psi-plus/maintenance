#####################################################################
# This function creates DMG file.
#####################################################################
function make_bundle() {
    log "Making standalone bundle..."
    cd "${PSI_DIR}/build/admin/build"
    # Creating DMG image from template.
    cp -f "${PSI_DIR}/maintenance/scripts/macosx/template.dmg.bz2" "template.dmg.bz2"
    # Compose filename for DMG file.
    # Version string for usage in filename should contain webkit flag.
    # This how resulted DMG will be named.
    DMG_FILENAME="psi-plus-${VERSION_STRING_RAW}-qt${QT_VERSION_MAJOR}-${SOURCE_TYPE}-${BUILD_DATE}-macosx.dmg"
    # pack_dmg.sh will create DMG image, copy resulted bundle in it.
    sh pack_dmg.sh "${DMG_FILENAME}" "Psi+" "dist/psi-${VERSION_STRING_RAW}-mac"

    cp -f "${DMG_FILENAME}" "${PSI_DIR}/${DMG_FILENAME}"
    log "You can find bundle in ${PSI_DIR}/${DMG_FILENAME}"

    # Portable version requires more actions.
    # WARNING: this code is completely untested! It might, or might not work!
    if [ ${PORTABLE} = 1 ]; then
        PORT_DMG="${DMG_FILENAME}"
        WC_DIR="wc"
        WC_DMG="wc.dmg"
        rm -fr "$WC_DIR"
        hdiutil convert "${DMG_FILENAME}" -quiet -format UDRW -o "$WC_DMG"
        hdiutil attach "$WC_DMG" -noautoopen -quiet -mountpoint "$WC_DIR"
        mv "$WC_DIR/Psi+.app" "$WC_DIR/Portable Psi+.app"
        mkdir -p "$WC_DIR/Portable Psi+.app/gpg"
        pushd "$WC_DIR/Portable Psi+.app/Contents"
        /usr/libexec/PlistBuddy -c 'Add :LSEnvironment:PSIDATADIR string "Portable Psi+.app/Psi+"' Info.plist
        /usr/libexec/PlistBuddy -c 'Add :LSEnvironment:GNUPGHOME string "Portable Psi+.app/gpg"' Info.plist
        /usr/libexec/PlistBuddy -c 'Set :CFBundleName string "Portable Psi+"' Info.plist
        popd
        rm -fr "$WC_DIR/.DS_Store" "$WC_DIR/Applications" "$WC_DIR/.background" "$WC_DIR/.fseventsd"
        diskutil rename "$WC_DIR" "Portable Psi+"
        diskutil eject "$WC_DIR"
        hdiutil convert "$WC_DMG" -quiet -format UDZO -imagekey zlib-level=9 -o "$PORT_DMG"
        cp -f ${DMG_FILENAME} "${PSI_DIR}/${DMG_FILENAME}" && rm -f ${DMG_FILENAME}
        log "You can find next bundle in ${PSI_DIR}/${DMG_FILENAME}"
    fi
    rm -f ${DMG_FILENAME}
}
