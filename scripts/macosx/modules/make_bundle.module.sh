TEMPLATE_DMG="template.dmg"
#####################################################################
# This function creates DMG file.
#####################################################################
function make_bundle() {
    log "Making standalone bundle..."
    cd "${PSI_DIR}/build/"
    # Creating DMG image from template.
    cp "${PSI_DIR}/maintenance/scripts/macosx/template.dmg.bz2" "template.dmg.bz2"
    bunzip2 template.dmg.bz2
    # Compose filename for DMG file.
    # Version string for usage in filename should contain webkit flag.
    # This how resulted DMG will be named.
    DMG_FILENAME="psi-plus-${VERSION_STRING_RAW}-${SOURCE_TYPE}-${BUILD_DATE}-macosx.dmg"

    mkdir template
    hdiutil attach "${TEMPLATE_DMG}" -noautoopen -quiet -mountpoint "template"
    echo "PSIAPP_DIR: ${PSIAPP_DIR}"
    cp -R "Psi+.app" template
    hdiutil detach $(diskutil list | grep "Psi+" | awk {' print $6 '})
    rmdir template

    hdiutil convert "${TEMPLATE_DMG}" -quiet -format UDZO -imagekey zlib-level=9 -o "${DMG_FILENAME}"
    hdiutil internet-enable -yes -quiet "${DMG_FILENAME}" || true

    log "You can find bundle in ${PSI_DIR}/${DMG_FILENAME}"
}
