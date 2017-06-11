#####################################################################
# This function parses CLI parameters and set some variables
# dedicated for them.
#####################################################################
function parse_cli_parameters()
{
    log "Parsing CLI parameters..."
    log "======================================== BUILD PARAMETERS"
    local cliparams=$@

    # Build from snapshot or git?
    if [ "${cliparams/build-from-snapshot}" != "${cliparams}" ]; then
        log "Building from snapshotted sources"
        BUILD_FROM_SNAPSHOT=1
        SKIP_GENERIC_PATCHES=1
    else
        log "Building from git sources"
        BUILD_FROM_SNAPSHOT=0
        SKIP_GENERIC_PATCHES=0
    fi

    # Webkit build.
    if [ "${cliparams/enable-webkit}" != "${cliparams}" ]; then
        log "Enabling Webkit build"
        ENABLE_WEBKIT=1
    else
        log "Will not build webkit version"
        ENABLE_WEBKIT=0
    fi

    # All translations.
    if [ "${cliparams/bundle-all-translations}" != "${cliparams}" ]; then
        log "Enabling bundling all translations"
        BUNDLE_ALL_TRANSLATIONS=1
    else
        log "Will install only these translations: ${TRANSLATIONS_TO_INSTALL}"
        BUNDLE_ALL_TRANSLATIONS=0
    fi

    # Dev plugins.
    if [ "${cliparams/enable-dev-plugins}" != "${cliparams}" ]; then
        log "Enabling unstable (dev) plugins"
        ENABLE_DEV_PLUGINS=1
    else
        log "Will not build unstable (dev) plugins"
        ENABLE_DEV_PLUGINS=0
    fi

    # Portable?
    if [ "${cliparams/make-portable}" != "${cliparams}" ]; then
        log "Enabling portable mode"
        PORTABLE=1
    else
        log "Will not be portable"
        PORTABLE=0
    fi

    # Skip bad patches?
    if [ "${cliparams/skip-bad-patches}" != "${cliparams}" ]; then
        log "Will not apply bad patches."
        SKIP_BAD_PATCHES=1
    else
        log "Will not continue on bad patch"
        SKIP_BAD_PATCHES=0
    fi

    # Use Qt5 from website?
    if [ "${cliparams/use-qt5-from-website}" != "${cliparms}" ]; then
        log "Will try to use Qt5 installed from website."
        USE_QT5_FROM_WEBSITE=1
    else
        log "Will NOT try to use Qt5 installed from website."
        USE_QT5_FROM_WEBSITE=0
    fi
    log "========================================"
}
