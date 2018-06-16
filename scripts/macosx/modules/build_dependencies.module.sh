DEP_GETTEXT_VER="0.19.8.1"
DEP_GETTEXT_FILE="gettext-${DEP_GETTEXT_VER}.tar.gz"
DEP_GETTEXT_URL="ftp://ftp.gnu.org/pub/gnu/gettext/${DEP_GETTEXT_FILE}"

DEP_GROWL_URL="https://drive.google.com/uc?export=download&id=0B9THQ10qg_RSNWhuOW1rbV9WYmc"
DEP_GROWL_FILE="Growl-2.0.1.tar.bz2"

DEP_LIBGCRYPT_VER=1.8.3
DEP_LIBGCRYPT_DIR=libgcrypt-${DEP_LIBGCRYPT_VER}
DEP_LIBGCRYPT_FILE=${DEP_LIBGCRYPT_DIR}.tar.gz
DEP_LIBGCRYPT_URL="https://gnupg.org/ftp/gcrypt/libgcrypt/${DEP_LIBGCRYPT_FILE}"

DEP_LIBGPGERROR_VER=1.31
DEP_LIBGPGERROR_DIR=libgpg-error-${DEP_LIBGPGERROR_VER}
DEP_LIBGPGERROR_FILE=${DEP_LIBGPGERROR_DIR}.tar.gz
DEP_LIBGPGERROR_URL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/${DEP_LIBGPGERROR_FILE}"

DEP_LIBOTR_VER=4.1.1
DEP_LIBOTR_DIR=libotr-${DEP_LIBOTR_VER}
DEP_LIBOTR_FILE=${DEP_LIBOTR_DIR}.tar.gz
DEP_LIBOTR_URL="https://otr.cypherpunks.ca/${DEP_LIBOTR_FILE}"

DEP_LIBIDN_VER=1.35
DEP_LIBIDN_DIR=libidn-${DEP_LIBIDN_VER}
DEP_LIBIDN_FILE=${DEP_LIBIDN_DIR}.tar.gz
DEP_LIBIDN_URL="https://ftp.gnu.org/gnu/libidn/${DEP_LIBIDN_FILE}"

DEP_LIBSIGNAL_VER=2.3.2
DEP_LIBSIGNAL_DIR=libsignal-protocol-c-${DEP_LIBSIGNAL_VER}
DEP_LIBSIGNAL_FILE=v${DEP_LIBSIGNAL_VER}.tar.gz
DEP_LIBSIGNAL_URL="https://github.com/signalapp/libsignal-protocol-c/archive/${DEP_LIBSIGNAL_FILE}"

DEP_OPENSSL_VER=1.1.0h
DEP_OPENSSL_DIR=openssl-${DEP_OPENSSL_VER}
DEP_OPENSSL_FILE=${DEP_OPENSSL_DIR}.tar.gz
DEP_OPENSSL_URL=https://ftp.openssl.org/source/${DEP_OPENSSL_FILE}

DEP_QJDNS_GIT=https://github.com/psi-im/jdns.git

DEP_QTKEYCHAIN_VER=0.8.0
DEP_QTKEYCHAIN_DIR="qtkeychain-${DEP_QTKEYCHAIN_VER}"
DEP_QTKEYCHAIN_FILE="v${DEP_QTKEYCHAIN_VER}.tar.gz"
DEP_QTKEYCHAIN_URL="https://github.com/frankosterfeld/qtkeychain/archive/${DEP_QTKEYCHAIN_FILE}"

DEP_ZLIB_VER=1.2.11
DEP_ZLIB_DIR=zlib-${DEP_ZLIB_VER}
DEP_ZLIB_FILE=${DEP_ZLIB_DIR}.tar.gz
DEP_ZLIB_URL="http://zlib.net/${DEP_ZLIB_FILE}"

function build_dependencies() {
    log "Building dependencies..."
    build_openssl
    _build_dep_default "gettext" "${DEP_GETTEXT_VER}" "${DEP_GETTEXT_FILE}" "${DEP_GETTEXT_URL}" "libintl.8.dylib"
    _build_dep_default "libgpg-error" "${DEP_LIBGPGERROR_VER}" "${DEP_LIBGPGERROR_FILE}" "${DEP_LIBGPGERROR_URL}" "libgpg-error.0.dylib"
    _build_dep_default "libgcrypt" "${DEP_LIBGCRYPT_VER}" "${DEP_LIBGCRYPT_FILE}" "${DEP_LIBGCRYPT_URL}" "libgcrypt.20.dylib"
    _build_dep_default "libidn" "${DEP_LIBIDN_VER}" "${DEP_LIBIDN_FILE}" "${DEP_LIBIDN_URL}" "libidn.12.dylib"
    _build_dep_default "zlib" "${DEP_ZLIB_VER}" "${DEP_ZLIB_FILE}" "${DEP_ZLIB_URL}" "libz.${DEP_ZLIB_VER}.dylib"
    build_minizip
    build_libotr
    build_libsignal
    build_qjdns
    build_qca
    build_qtkeychain
    build_growl
}

function build_growl() {
    log "Installing dependency: growl..."

    if [ -f "${DEPS_ROOT}/lib/Growl.framework/Versions/Current/Growl" ]; then
        log "Growl already installed, skipping..."
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/growl" ]; then
        log "Growl sources wasn't found, fetching..."
        mkdir -p "${DEPS_BUILDROOT}/growl"
        cd "${DEPS_BUILDROOT}/growl"
        curl -L -o "${DEP_GROWL_FILE}" "${DEP_GROWL_URL}"
        tar -xf "${DEP_GROWL_FILE}"
    fi

    mv "${DEPS_BUILDROOT}/growl/Growl.framework" "${DEPS_ROOT}/lib"
}

function build_libotr() {
    log "Installing dependency: libotr..."

    if [ -f "${DEPS_ROOT}/lib/libotr.dylib" ]; then
        log "libotr already built, skipping"
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/libotr" ]; then
        log "libotr sources wasn't found, fetching..."
        mkdir -p "${DEPS_BUILDROOT}/libotr"
        cd "${DEPS_BUILDROOT}/libotr"
        curl -L -o "${DEP_LIBOTR_FILE}" "${DEP_LIBOTR_URL}"
        tar -xf "${DEP_LIBOTR_FILE}"
    fi

    cd "${DEPS_BUILDROOT}/libotr/${DEP_LIBOTR_DIR}"
    log "Configuring..."
    ./configure --prefix="${DEPS_ROOT}" --with-pic --with-libgcrypt-prefix="${DEPS_ROOT}" > "${PSI_DIR}/logs/deps/libotr-configure.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring libotr" "${PSI_DIR}/logs/deps/libotr-configure.log"
    fi
    log "Building..."
    ${MAKE} ${MAKEOPTS} > "${PSI_DIR}/logs/deps/libotr-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building libotr" "${PSI_DIR}/logs/deps/libotr-make.log"
    fi
    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/libotr-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing libotr" "${PSI_DIR}/logs/deps/libotr-makeinstall.log"
    fi
}

function build_libsignal() {
    log "Installing dependency: libsignal-protocol-c..."

    if [ -f "${DEPS_ROOT}/lib/libsignal-protocol-c.a" ]; then
        log "libsignal-protocol-c already built, skipping..."
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/libsignal-protocol-c" ]; then
        log "libsignal-protocol-c sources wasn't found, fetching..."
        mkdir -p "${DEPS_BUILDROOT}/libsignal-protocol-c"
        cd "${DEPS_BUILDROOT}/libsignal-protocol-c"
        curl -L -o "${DEP_LIBSIGNAL_FILE}" "${DEP_LIBSIGNAL_URL}"
        tar -xf "${DEP_LIBSIGNAL_FILE}"
    fi

    if [ -d "${DEPS_BUILDROOT}/libsignal-protocol-c/${DEP_LIBSIGNAL_DIR}/build" ]; then
        rm -rf "${DEPS_BUILDROOT}/libsignal-protocol-c/${DEP_LIBSIGNAL_DIR}/build"
    fi

    mkdir -p "${DEPS_BUILDROOT}/libsignal-protocol-c/${DEP_LIBSIGNAL_DIR}/build"
    cd "${DEPS_BUILDROOT}/libsignal-protocol-c/${DEP_LIBSIGNAL_DIR}/build"
    local cmakeopts="-DCMAKE_INSTALL_PREFIX=${DEPS_ROOT} -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -DCMAKE_BUILD_TYPE=Release"
    ${CMAKE} ${cmakeopts} .. > "${PSI_DIR}/logs/deps/libsignal-protocol-c-cmake.log"
    if [ $? -ne 0 ]; then
        action_failed "Configuring libsignal-protocol-c" "${PSI_DIR}/logs/deps/libsignal-protocol-c-cmake.log"
    fi

    log "Building..."
    ${MAKE} ${MAKEOPTS} > "${PSI_DIR}/logs/deps/libsignal-protocol-c-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building libsignal-protocol-c" "${PSI_DIR}/logs/deps/libsignal-protocol-c-make.log"
    fi

    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/libsignal-protocol-c-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing libsignal-protocol-c" "${PSI_DIR}/logs/deps/libsignal-protocol-c-makeinstall.log"
    fi
}

function build_minizip() {
    log "Installing dependency: minizip"

    if [ -f "${DEPS_ROOT}/lib/libminizip.1.dylib" ]; then
        log "minizip already built, skipping"
        return
    fi

    # Minizip is a part of zlib, so reusing it's sources.
    cd "${DEPS_BUILDROOT}/zlib/${DEP_ZLIB_DIR}/contrib/minizip"
    log "Configuring..."
     autoreconf --install > "${PSI_DIR}/logs/deps/minizip-configure.log" 2>&1
    ./configure --prefix="${DEPS_ROOT}" >> "${PSI_DIR}/logs/deps/minizip-configure.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring minizip" "${PSI_DIR}/logs/deps/minizip-configure.log"
    fi
    log "Building..."
    ${MAKE} > "${PSI_DIR}/logs/deps/minizip-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building minizip" "${PSI_DIR}/logs/deps/minizip-make.log"
    fi
    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/minizip-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing minizip" "${PSI_DIR}/logs/deps/minizip-makeinstall.log"
    fi
}

function build_openssl() {
    log "Installing dependency: openssl (this WILL take awhile)"

    if [ -f "${DEPS_ROOT}/lib/libssl.dylib" ]; then
        log "openssl already built, skipping"
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/openssl" ]; then
        log "openssl sources wasn't found, fetching..."
        mkdir -p "${DEPS_BUILDROOT}/openssl"
        cd "${DEPS_BUILDROOT}/openssl"
        curl -L -o "${DEP_OPENSSL_FILE}" "${DEP_OPENSSL_URL}"
        tar -xf "${DEP_OPENSSL_FILE}"
    fi

    cd "${DEPS_BUILDROOT}/openssl/${DEP_OPENSSL_DIR}"
    log "Configuring..."
    perl ./Configure --prefix="${DEPS_ROOT}" no-ssl2 zlib-dynamic shared enable-cms darwin64-x86_64-cc enable-ec_nistp_64_gcc_128 > "${PSI_DIR}/logs/deps/openssl-configure.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring openssl" "${PSI_DIR}/logs/deps/openssl-configure.log"
    fi
    log "Building..."
    ${MAKE} depend > "${PSI_DIR}/logs/deps/openssl-makedepend.log" 2>&1
    ${MAKE} > "${PSI_DIR}/logs/deps/openssl-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building openssl" "${PSI_DIR}/logs/deps/openssl-make.log"
    fi
    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/openssl-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing openssl" "${PSI_DIR}/logs/deps/openssl-makeinstall.log"
    fi
}

function build_qca() {
    log "Installing dependency: QCA..."

    if [ -f "${DEPS_ROOT}/lib/qca-qt5.framework/Versions/Current/qca-qt5" ]; then
        log "QCA already built, skipping..."
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/qca" ]; then
        mkdir -p "${DEPS_BUILDROOT}/qca"
    fi

    cd "${DEPS_BUILDROOT}/qca"

    if [ -d "${DEPS_BUILDROOT}/qca/.git" ]; then
        git pull
    else
        git clone "${GIT_REPO_DEP_QCA_QT5}" .
    fi

    if [ -d "${DEPS_BUILDROOT}/qca/build" ]; then
        rm -rf "${DEPS_BUILDROOT}/qca/build"
    fi

    mkdir build
    cd build

    log "Configuring..."
    local opts="-DCMAKE_INSTALL_PREFIX=${DEPS_ROOT} -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS:STRING=-L${DEPS_ROOT}/lib -DOPENSSL_ROOT_DIR=${DEPS_ROOT} -DOPENSSL_LIBRARIES=${DEPS_ROOT}/lib"
    ${CMAKE} ${opts} .. > "${PSI_DIR}/logs/deps/qca-cmake.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring QCA" "${PSI_DIR}/logs/deps/qca-cmake.log"
    fi

    log "Building..."
    ${MAKE} ${MAKEOPTS} > "${PSI_DIR}/logs/deps/qca-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building QCA" "${PSI_DIR}/logs/deps/qca-make.log"
    fi

    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/qca-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing QCA" "${PSI_DIR}/logs/deps/qca-makeinstall.log"
    fi
}

function build_qjdns() {
    log "Installing dependency: qjdns..."

    if [ -f "${DEPS_ROOT}/lib/libqjdns.dylib" ]; then
        log "qjdns already built, skipping."
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/qjdns" ]; then
        log "qjdns sources wasn't found, fetching..."
        mkdir -p "${DEPS_BUILDROOT}/qjdns"
        cd "${DEPS_BUILDROOT}/qjdns"
        git clone "${DEP_QJDNS_GIT}" .
    fi

    if [ -d "${DEPS_BUILDROOT}/qjdns/build" ]; then
        rm -rf "${DEPS_BUILDROOT}/qjdns/build"
    fi

    mkdir -p "${DEPS_BUILDROOT}/qjdns/build"
    cd "${DEPS_BUILDROOT}/qjdns/build"
    local cmakeopts="-DCMAKE_INSTALL_PREFIX=${DEPS_ROOT} -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -DCMAKE_BUILD_TYPE=Release -DQT4_BUILD=OFF"
    log "Configuring..."
    ${CMAKE} ${cmakeopts} .. > "${PSI_DIR}/logs/deps/qjdns-cmake.log"
    if [ $? -ne 0 ]; then
        action_failed "Configuring QJDNS" "${PSI_DIR}/logs/deps/qjdns-cmake.log"
    fi

    log "Building..."
    ${MAKE} ${MAKEOPTS} > "${PSI_DIR}/logs/deps/qjdns-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building QJDNS" "${PSI_DIR}/logs/deps/qjdns-make.log"
    fi

    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/qjdns-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing QJDNS" "${PSI_DIR}/logs/deps/qjdns-makeinstall.log"
    fi

}

function build_qtkeychain() {
    log "Installing dependency: qtkeychain..."

    if [ -f "${DEPS_ROOT}/lib/libqt5keychain.1.dylib" ]; then
        log "QtKeychain already built, skipping..."
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/qtkeychain" ]; then
        log "qtkeychain sources wasn't found, fetching..."
        mkdir -p "${DEPS_BUILDROOT}/qtkeychain"
        cd "${DEPS_BUILDROOT}/qtkeychain"
        curl -L -o "${DEP_QTKEYCHAIN_FILE}" "${DEP_QTKEYCHAIN_URL}"
        tar -xf "${DEP_QTKEYCHAIN_FILE}"
    fi

    if [ -d "${DEPS_BUILDROOT}/qtkeychain/${DEP_QTKEYCHAIN_DIR}/build" ]; then
        rm -rf "${DEPS_BUILDROOT}/qtkeychain/${DEP_QTKEYCHAIN_DIR}/build"
    fi

    mkdir -p "${DEPS_BUILDROOT}/qtkeychain/${DEP_QTKEYCHAIN_DIR}/build"
    cd "${DEPS_BUILDROOT}/qtkeychain/${DEP_QTKEYCHAIN_DIR}/build"
    local cmakeopts="-DCMAKE_INSTALL_PREFIX=${DEPS_ROOT} -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -DCMAKE_BUILD_TYPE=Release -DECM_MKSPECS_INSTALL_DIR=${DEPS_ROOT}/lib/mkspecs/modules"
    ${CMAKE} ${cmakeopts} .. > "${PSI_DIR}/logs/deps/qtkeychain-cmake.log"
    if [ $? -ne 0 ]; then
        action_failed "Configuring QtKeychain" "${PSI_DIR}/logs/deps/qtkeychain-cmake.log"
    fi

    log "Building..."
    ${MAKE} ${MAKEOPTS} > "${PSI_DIR}/logs/deps/qtkeychain-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building QtKeychain" "${PSI_DIR}/logs/deps/qtkeychain-make.log"
    fi

    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/qtkeychain-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing QtKeychain" "${PSI_DIR}/logs/deps/qtkeychain-makeinstall.log"
    fi
}

function _build_dep_default() {
    local depname=$1
    local depver=$2
    local depfile=$3
    local depurl=$4
    local deplib=$5

    log "Installing dependency: ${depname}..."

    if [ -f "${DEPS_ROOT}/lib/${deplib}" ]; then
        log "${depname} already built, skipping."
        return
    fi

    if [ ! -d "${DEPS_BUILDROOT}/${depname}" ]; then
        log "${depname} sources wasn't found, fetching from '${depurl}'..."
        mkdir -p "${DEPS_BUILDROOT}/${depname}"
        cd "${DEPS_BUILDROOT}/${depname}"
        curl -L -o "${depfile}" "${depurl}"
        tar -xf "${depfile}"
    fi

    cd "${DEPS_BUILDROOT}/${depname}/${depname}-${depver}"
    log "Configuring..."
    ./configure --prefix="${DEPS_ROOT}" > "${PSI_DIR}/logs/deps/${depname}-configure.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Configuring ${depname}" "${PSI_DIR}/logs/deps/${depname}-configure.log"
    fi
    log "Building..."
    ${MAKE} > "${PSI_DIR}/logs/deps/${depname}-make.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Building ${depname}" "${PSI_DIR}/logs/deps/${depname}-make.log"
    fi
    log "Installing..."
    ${MAKE} install > "${PSI_DIR}/logs/deps/${depname}-makeinstall.log" 2>&1
    if [ $? -ne 0 ]; then
        action_failed "Installing ${depname}" "${PSI_DIR}/logs/deps/${depname}-makeinstall.log"
    fi
}
