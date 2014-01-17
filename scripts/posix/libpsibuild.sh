# use REV_DATE to build Psi+ in state before this date:
[ -n "${REV_DATE}" ]
REV_NEED=$?
#[ ${REV_NEED} -ne 0 ] && REV_DATE=`date -dnext-week +%Y-%m-%d` # this line can be removed, but it shows emaple of REV_DATE format
# do not forget, that REV_DATE always allow you to get revision before "master".
# it will not give you "master" even if you set date to 9999-12-31. (i wrote this in 2014 year.)
# so if you want "master", then don't use REV_DATE, leave it as empty string.

# do not update anything from repositories until required
WORK_OFFLINE=${WORK_OFFLINE:-0}

# skip patches which applies with errors / пропускать глючные патчи
SKIP_INVALID_PATCH=${SKIP_INVALID_PATCH:-0}

# configure options / опции скрипта configure
DEFAULT_CONF_OPTS="${DEFAULT_CONF_OPTS:---enable-plugins --enable-whiteboarding}"
CONF_OPTS="${DEFAULT_CONF_OPTS} ${CONF_OPTS}"

# install root / каталог куда устанавливать (полезно для пакаджеров)
INSTALL_ROOT="${INSTALL_ROOT:-/}"

# icons for downloads / иконки для скачивания
ICONSETS="${ICONSETS:-system clients activities moods affiliations roster}"

# bin directory of compiler cache util (leave empty to try autodetect)
CCACHE_BIN_DIR="${CCACHE_BIN_DIR}"

BUILD_MISSING_QCONF="${BUILD_MISSING_QCONF:-0}"

EXTRA_PATCHES="${EXTRA_PATCHES}"

# available translations
LANGS="be bg ca cs de en eo es et fi fr hu it ja mk nl pl pt pt_BR ru sk sl sr@latin sv sw uk ur_PK vi zh_CN zh_TW"

# selected translations (space-separated, leave empty to autodetect by $LANG)
TRANSLATIONS="${TRANSLATIONS}"

# system libraries directory
[ "`uname -m`" = "x86_64" ] && [ -d /usr/lib64 ] && SYSLIBDIRNAME=${SYSLIBDIRNAME:-lib64} || SYSLIBDIRNAME=${SYSLIBDIRNAME:-lib}

# official repository / репозиторий официальной Psi
GIT_REPO_PSI=git://github.com/psi-im/psi.git

GIT_REPO_PLUS=git://github.com/psi-plus/main.git
GIT_REPO_PLUGINS=git://github.com/psi-plus/plugins.git

LANGS_REPO_URI="git://github.com/psi-plus/psi-plus-l10n.git"

QCONF_REPO="https://delta.affinix.com/svn/trunk/qconf@816"
QCA_REPO="svn://anonsvn.kde.org/home/kde/trunk/kdesupport/qca@1311233"

SVN_FETCH="${SVN_FETCH:-git_svn_clone}"
SVN_UP="${SVN_UP:-git_svn_pull}"

# convert INSTALL_ROOT to absolute path
case "${INSTALL_ROOT}" in /*) ;; *) INSTALL_ROOT="$(pwd)/${INSTALL_ROOT}"; ;; esac
# convert PSI_DIR to absolute path
[ -n "${PSI_DIR}" ] && case "${PSI_DIR}" in /*) ;; *) PSI_DIR="$(pwd)/${PSI_DIR}"; ;; esac

[ -n "${PLUGINS_PREFIXES}" ] && plugprefset=1
PLUGINS_PREFIXES="${PLUGINS_PREFIXES:-generic}" # will be updated later while detecting platform specific settings
#######################
# FUNCTIONS / ФУНКЦИИ #
#######################

helper() {
  case "${LANG}" in
    "ru_"*) cat <<END
Скрипт для сборки Psi+

-h,--help    Помощь
--enable-webkit Собрать с поддержкой технологий webkit
--prefix=pass    Задать установочный каталог (автоопределение по умолчанию)

    Описание переменных окружения:
PLUGINS="*"           Собрать все плагины
PLUGINS="hello world" Собрать плагины "hello" и "world"
WORK_OFFLINE=[1,0]    Не обновлять из репозитория
SKIP_INVALID_PATCH=[1,0] Пропускать глючные патчи
PATCH_LOG             Лог применения патчей
INSTALL_ROOT          Каталог куда устанавливать (полезно для пакаджеров)
ICONSETS              Иконки для скачивания
CCACHE_BIN_DIR        Каталог кеша компилятора
QCONFDIR              Каталог с банирником qconf при ручной сборке или установке
                      с сайта
SYSLIBDIRNAME         Имя системного каталога с библиотеками (lib64/lib32/lib)
                      Автодетектится если не указана
PLUGINS_PREFIXES      Список префиксов плагинов через пробел (generic/unix/etc)
REV_DATE              Собрать Psi+ из кода свежести до этой даты (например:
                      2012-01-15)
END
    ;;
    *) cat <<END
Script to build the Psi+

-h,--help    This help
--enable-webkit Build with themed chats and enabled smileys animation
--prefix=pass    Set the installation directory

    Description of environment variables:
PLUGINS="*"           Build all plugins
PLUGINS="hello world" Build plugins "hello" and "world"
WORK_OFFLINE=[1,0]    Do not update anything from repositories until required
SKIP_INVALID_PATCH=[1,0] Skip patches which apply with errors
PATCH_LOG             Log of patching process
INSTALL_ROOT          Install root (usefull for package maintainers)
ICONSETS              Icons to download
CCACHE_BIN_DIR        Bin directory of compiler cache util
QCONFDIR              qconf's binary directory when compiled manually
SYSLIBDIRNAME         System libraries directory name (lib64/lib32/lib)
                      Autodetected when not given
PLUGINS_PREFIXES      Space-separated list of plugin prefixes (generic/unix/etc)
REV_DATE              Build Psi+ in state before this date (e.g.: 2012-01-15)
END
  esac
  exit 0
}

# Exit with error message
die() { echo; echo " !!!ERROR: $@"; exit 1; }
warning() { echo; echo " !!!WARNING: $@"; }
log() { local opt; [ "$1" = "-n" ] && { opt="-n"; shift; }; echo $opt "*** $@"; }

winpath2unix() {
  local path="$@"
  local drive=`echo "${path%%:*}" | tr '[A-Z]' '[a-z]'`
  path="${path#?:\\}"
  echo "/${drive}/${path//\\//}"
}

check_env() {
  log "Testing environment.. "

  unset COMPILE_PREFIX
  unset PSILIBDIR
  until [ -z "$1" ]; do
    case "$1" in
      "-h" | "--help")
        helper
        ;;
      "--prefix="*)
        COMPILE_PREFIX=${1#--prefix=}
        ;;
      "--libdir="*)
        PSILIBDIR=${1#--libdir=}
        ;;
      "--with-qca"*)
	    HAS_QCA_CONF_PATH=1
    esac
    shift
  done

  # Setting some internal variables
  local have_prefix=0 # compile prefix is set by --prefix argv
  [ -n "${COMPILE_PREFIX}" ] && have_prefix=1

  case "`uname`" in
  FreeBSD)
    MAKEOPT=${MAKEOPT:--j$((`sysctl -n hw.ncpu`+1))}
    STAT_USER_ID='stat -f %u'
    STAT_USER_NAME='stat -f %Su'
    SED_INPLACE_ARG=".bak"
    COMPILE_PREFIX="${COMPILE_PREFIX-/usr/local}"
    CCACHE_BIN_DIR="${CCACHE_BIN_DIR:-/usr/local/libexec/ccache/}"
    [ -z "${plugprefset}" ] && PLUGINS_PREFIXES="${PLUGINS_PREFIXES} unix"
    ;;
  Darwin)
    MAKEOPT=${MAKEOPT:--j$((`sysctl -n hw.ncpu`+1))}
    STAT_USER_ID='stat -f %u'
    STAT_USER_NAME='stat -f %Su'
    SED_INPLACE_ARG=".bak"
    COMPILE_PREFIX="${COMPILE_PREFIX-/Applications}"
    if [ -z "${CCACHE_BIN_DIR}" ]; then
        CCACHE_BIN_DIR="$(echo /usr/local/Cellar/ccache/*/libexec)"
    fi
    [ -z "${plugprefset}" ] && PLUGINS_PREFIXES="${PLUGINS_PREFIXES} unix"
    ;;
  SunOS)
    CPUS=`/usr/sbin/psrinfo | grep on-line | wc -l | tr -d ' '`
    if test "x$CPUS" = "x" -o $CPUS = 0; then
      CPUS=1
    fi
    MAKEOPT=${MAKEOPT:--j$CPUS}
    STAT_USER_ID='stat -c %u'
    STAT_USER_NAME='stat -c %U'
    SED_INPLACE_ARG=".bak"
    COMPILE_PREFIX="${COMPILE_PREFIX-/usr/local}"
    [ -z "${plugprefset}" ] && PLUGINS_PREFIXES="${PLUGINS_PREFIXES} unix"
    ;;
  MINGW32*)
    local qtpath=`qmake -query QT_INSTALL_PREFIX 2>/dev/null`
    if [ -n "${qtpath}" ]; then
      export QTDIR=`winpath2unix "${qtpath}"`
      log "Qt found in PATH: ${QTDIR}"
      QTSDKPATH=$(cd "${QTDIR}"; cd ../../../../; pwd)
    else
	  QTSDKPATH=`reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\Qt SDK" //s 2>/dev/null | grep InstallLocation | sed 's:.*REG_SZ\s*\(.*\)\s*:\1:'`
      if [ -n "${QTSDKPATH}" ]; then
	    QTSDKPATH=`winpath2unix "${QTSDKPATH}"`
        local versions="$(echo `ls -r "${QTSDKPATH}"/Desktop/Qt/`)"
        export QTDIR="${QTSDKPATH}/Desktop/Qt/${versions%% *}/mingw"
	  fi
    fi
    if [ -n "`mingw32-make --version 2>/dev/null`" ]; then
      MAKE="`which mingw32-make.exe`"
      log "make found in PATH: ${MAKE}"
    else
      MAKE="${QTSDKPATH}/mingw/bin/mingw32-make.exe"
      [ ! -f "${MAKE}" ] && die "QtSDK path detected but mingw not found"
	  PATH="$(dirname ${MAKE}):${PATH}"
    fi
    QCONFDIR="${QCONFDIR:-/c/local/QConf}"
    PATH="${QTDIR}/bin:${PATH}"
    CONFIGURE="configure.exe"
    CONF_OPTS="${CONF_OPTS} --qtdir=${QTDIR}"
	BUILD_MISSING_QCONF=1
	[ -z "${HAS_QCA_CONF_PATH}" ] && BUILD_MISSING_QCA=1
    ;;
  *)
    MAKEOPT=${MAKEOPT:--j$((`cat /proc/cpuinfo | grep processor | wc -l`+1))}
    STAT_USER_ID='stat -c %u'
    STAT_USER_NAME='stat -c %U'
    SED_INPLACE_ARG=""
    COMPILE_PREFIX="${COMPILE_PREFIX-/usr}"
    if [ -z "${CCACHE_BIN_DIR}" ]; then
      for d in "/usr/${SYSLIBDIRNAME}/ccache" \
               "/usr/${SYSLIBDIRNAME}/ccache/bin"; do
        [ -x "${d}/gcc" ] && { CCACHE_BIN_DIR="${d}"; break; }
      done
    fi
    [ -z "${plugprefset}" ] && PLUGINS_PREFIXES="${PLUGINS_PREFIXES} unix"
    ;;
  esac
   
  PSI_DIR="${PSI_DIR:-${HOME}/psi}"
  PATCH_LOG="${PATCH_LOG:-${PSI_DIR}/psipatch.log}"
  CONFIGURE="${CONFIGURE:-configure}"

  
  v=`git --version 2>/dev/null` || \
    die "You should install Git first. / Сначала установите Git"
  #v=`svn --version 2>/dev/null` || \
  #  die "You should install subversion first. / Сначала установите subversion"

  # Make
  if [ ! -f "${MAKE}" ]; then
    MAKE=""
    for gn in gmake make; do
      [ -n "`$gn --version 2>/dev/null`" ] && { MAKE="$gn"; break; }
    done
    [ -z "${MAKE}" ] && die "You should install GNU Make first / "\
            "Сначала установите GNU Make"
  fi
  log "Found make tool: ${MAKE}"

  # patch
  [ -z "`which patch`" ] &&
    die "patch tool not found / утилита для наложения патчей не найдена"
  # autodetect --dry-run or -C
  [ -n "`patch --help 2>/dev/null | grep dry-run`" ] && PATCH_DRYRUN_ARG="--dry-run" \
    || PATCH_DRYRUN_ARG="-C"
  log "Found patch tool"
  
  find_qt_util() {
    local name=$1
    result=""
    for un in $name-qt4 qt4-${name} ${name}4 $name; do
      [ -n "`$un -v 2>&1 |grep Qt`" ] && { result="$un"; break; }
    done
    if [ -z "${result}" ]; then
      [ "$nonfatal" = 1 ] || die "You should install $name util as part of"\
        "Qt framework / Сначала установите утилиту $name из Qt framework"
      log "${name} Qt tool is not found. ignoring.."
    else
      log "Found ${name} Qt tool: ${result}"
    fi
  }

  local result
  # qmake
  find_qt_util qmake; QMAKE="${result}"
  nonfatal=1 find_qt_util lrelease; LRELEASE="${result}"
  find_qt_util moc; # we don't use it dirrectly but its required.
  find_qt_util uic; # we don't use it dirrectly but its required.
  find_qt_util rcc; # we don't use it dirrectly but its required.

  # QConf
  if [ -n "${QCONFDIR}" -a -n "`PATH="${PATH}:${QCONFDIR}" qconf 2>/dev/null`" ]; then
    QCONF="${QCONFDIR}/qconf"
  else
    export PATH="${PATH}:${PSI_DIR}/qconf"
    for qc in qt-qconf qconf-qt4 qconf; do
      v=`$qc --version 2>/dev/null |grep affinix` && QCONF=$qc
    done
    [ -z "${QCONF}" -a ! "${BUILD_MISSING_QCONF}" = 1 ] && die "You should install "\
      "qconf(http://delta.affinix.com/qconf/) / Сначала установите qconf"
  fi
  if [ -z "${QCONF}" -a "${BUILD_MISSING_QCONF}" = 1 ]; then
    log "qconf tool will be built from source"
  else
    log "Found qconf tool: " $QCONF
  fi
  
  # CCache
  case "`which gcc`" in
    *cache*) log "Found ccache tool in PATH. will be used" ;;
    *)
      [ -n "${CCACHE_BIN_DIR}" ] && [ -x "${CCACHE_BIN_DIR}/gcc" ] && {
        log "Found ccache tool. going to use it."
        export PATH="${CCACHE_BIN_DIR}:${PATH}";
      } || log "ccache tool is not found"
      ;;
  esac

  # Plugins
  validate_plugins_list

  # Language
  validate_translations
  [ -z "${LRELEASE}" ] && warning "lrelease util is not available. so only ready qm files will be installed"

  # Compile prefix
  if [ -n "${COMPILE_PREFIX}" ]; then
    [ $have_prefix = 0 ] && CONF_OPTS="${CONF_OPTS} --prefix=$COMPILE_PREFIX"
    log "Compile prefix=${COMPILE_PREFIX}"
    if [ -z "${PSILIBDIR}" ]; then # --libdir is not present in argv
      PSILIBDIR="${COMPILE_PREFIX}/lib"
      [ "`uname -m`" = "x86_64" ] && [ -d "${COMPILE_PREFIX}"/lib64 ] && PSILIBDIR="${COMPILE_PREFIX}/lib64"
      CONF_OPTS="${CONF_OPTS} --libdir=${PSILIBDIR}";
    fi
  fi

  log "Environment is OK"
}

validate_translations() {
  local selected_langs=""
  [ -z "${TRANSLATIONS}" ] && {
    test_lang() {
      tl=$1
      for l in $LANGS; do
        case "${tl}" in *"$l"*) selected_langs="$l"; return 0; ;; *) ;; esac
      done
      return 1
    }
    test_lang "${LANG%.*}" || test_lang "${LANG%_*}"
  } || {
    local tmp=" $(echo ${LANGS}) "
    for l in ${TRANSLATIONS}; do
      case "${tmp}" in
        *" $l "*) selected_langs="$selected_langs $l" ;;
        *) ;;
      esac
    done
  }
  TRANSLATIONS="$(echo ${selected_langs})"
  log "Choosen interface language:" $TRANSLATIONS
}

validate_plugins_list() {
  local plugins_enabled=0
  case "${CONF_OPTS}" in *--enable-plugins*) plugins_enabled=1; ;; *) ;; esac

  [ -n "${PLUGINS}" ] && [ "${plugins_enabled}" = 0 ] && {
    warning "WARNING: there are selected plugins but plugins are disabled in"
    warning "configuration options. no one will be built"
    PLUGINS=""
  }
}

prepare_workspace() {
  if [ ! -d "${PSI_DIR}" ]
  then
    mkdir "${PSI_DIR}" || die "can't create work directory ${PSI_DIR}"
  fi
  rm -rf "${PSI_DIR}"/build
  [ -d "${PSI_DIR}"/build ] && \
    die "can't delete old build directory ${PSI_DIR}/build"
  mkdir "${PSI_DIR}"/build || \
    die "can't create build directory ${PSI_DIR}/build"
  log "Created base directory structure"
}

# fetches defined set of something from psi-dev svn. ex: plugins or iconsets
#
# svn_fetch_set(name, remote_path, items, [sub_item_path])
# name - a name of what you ar fetching. for example "plugin"
# remote - a path relative to SVN_BATH_REPO
# items - space separated items string
# sub_item_path - checkout subdirectory of item with this relative path
#
# Example: svn_fetch_set("iconset", "iconsets", "system, mood", "default")
svn_fetch_set() {
  local name="$1"
  local remote="$2"
  local items="$3"
  local subdir="$4"
  local curd=`pwd`
  cd "${PSI_DIR}"
  [ -n "${remote}" ] || die "invalid remote path in set fetching"
  if [ ! -d "${remote}" ]; then
    mkdir -p "${remote}"
  fi
  cd "${remote}"

  for item in ${items}; do
    svn_fetch "${SVN_BASE_REPO}/${remote}/${item}/${subdir}" "$item" \
              "${item} ${name}"
  done
  cd "${curd}"
}

git_svn_clone() {
  local rev="${1##*@}"
  local repo
  [ -z `echo "$rev" | grep -E "^[0-9]+$"` ] && {
    rev=""
	repo="$1"
  } || {
    rev="${rev}:"
    repo="${1%@*}"
  }
  git svn clone -r "$rev"HEAD "$repo" "$2"
}

git_svn_pull() {
  cd "$@"
  git svn fetch || die "git svn fetch failed"
  git svn rebase || die "git svn rebase failed"
  cd - > /dev/null
}

# Checkout fresh copy or update existing from svn
# Example: svn_fetch svn://host/uri/trunk my_target_dir "Something useful"
svn_fetch() {
  local remote="$1"
  local target="$2"
  local comment="$3"
  [ -z "$target" ] && { target="${remote##*/}"; target="${target%%#*}"; target="${target%%@*}"; }
  [ -z "$target" ] && die "can't determine target dir"
  if [ -d "$target" ]; then
    [ $WORK_OFFLINE = 0 ] && {
      [ -n "$comment" ] && log -n "Update ${comment} ... "
      $SVN_UP "${target}" || die "${comment} update failed"
    } || true
  else
    [ -n "$comment" ] && log "Checkout ${comment} .."
    $SVN_FETCH "${remote}" "$target" \
    || die "${comment} checkout failed"
  fi
}

git_fetch() {
  local remote="$1"
  local target="$2"
  local comment="$3"
  local curd=`pwd`
  local forcesubmodule=0
  [ -d "${target}/.git" ] && [ "$(cd "${target}" && git config --get remote.origin.url)" = "${remote}" ] && {
    [ $WORK_OFFLINE = 0 ] && {
      cd "${target}"
      [ -n "${comment}" ] && log "Update ${comment} .."
      git checkout master || die "git checkout to master failed"
      git pull || die "git update failed"
      cd "${curd}"
    } || true
  } || {
    forcesubmodule=1
    log "Checkout ${comment} .."
    [ -d "${target}" ] && rm -rf "$target"
    git clone "${remote}" "$target" || die "git clone failed"
  }
  [ $WORK_OFFLINE = 0 -o $forcesubmodule = 1 ] && {
    cd "${target}"
    if [ ${REV_NEED} -eq 0 ]; then
	  REV=`git rev-list master -n 1 --first-parent --before=${REV_DATE}`
	  if [ -z "${REV}" ]; then
        log "!!!WARNING: git revision before ${REV_DATE} does not exist (remote=${remote}, target=${target})"
      else  
	    log "checkout to ${REV} (${REV_DATE}) .."
        git checkout "${REV}" || die "git checkout to ${REV} (${REV_DATE}) failed"
      fi
    fi
    git submodule update --init || die "git submodule update failed"
  }
  cd "${curd}"
}

fetch_build_deps_sources() {
  cd "${PSI_DIR}"
  [ "${BUILD_MISSING_QCONF}" = 1 ] && svn_fetch "${QCONF_REPO}" qconf "QConf"
  [ "${BUILD_MISSING_QCA}" ] && svn_fetch "${QCA_REPO}" qca "QCA"
}

fetch_sources() {
  cd "${PSI_DIR}"
  git_fetch "${GIT_REPO_PSI}" git "Psi"
  git_fetch "${GIT_REPO_PLUS}" git-plus "Psi+ additionals"

  local actual_translations=""
  [ -n "$TRANSLATIONS" ] && {
    git_fetch "${LANGS_REPO_URI}" "langs" "language packs"
    for l in $TRANSLATIONS; do
      [ -n "${LRELEASE}" -o -f "langs/translations/psi_$l.qm" ] && actual_translations="${actual_translations} $l"
    done
    actual_translations="$(echo $actual_translations)"
    [ -z "${actual_translations}" ] && warning "Translations not found"
  }
}

fetch_plugins_sources() {
  git_fetch "${GIT_REPO_PLUGINS}" plugins "Psi+ plugins"
  [ -z "${PLUGINS}" ] && return 0
  log "Validate plugins list.."
  local plugins_tmp=""
  local require_all_plugins="$([ "$PLUGINS" = "*" ] && echo 1 || echo 0)"
  local actual_plugins=""
  for plugins_prefix in $PLUGINS_PREFIXES; do
    PLUGINS_ALL=`echo $(ls -F "${PSI_DIR}/plugins/$plugins_prefix" | grep 'plugin/')`
    [ $require_all_plugins = 1 ] && {
      for p in $PLUGINS_ALL; do actual_plugins="$actual_plugins $plugins_prefix/${p%/}"; done
    } || {
      for pn in $PLUGINS; do
        for p in $PLUGINS_ALL; do [ "${p}" = "${pn}plugin/" ] && actual_plugins="$actual_plugins $plugins_prefix/${p%/}"; done
      done
    }
  done
  PLUGINS="${actual_plugins}"
  log "Enabled plugins:" $(echo $PLUGINS | sed 's:generic/::g')
}

fetch_all() {
  fetch_build_deps_sources
  fetch_sources
  fetch_plugins_sources
}

#smart patcher
spatch() {
  PATCH_TARGET="$1"

  log -n "applying ${PATCH_TARGET##*/} ..." | tee -a "$PATCH_LOG"

  if (patch -p1 ${PATCH_DRYRUN_ARG} -i "${PATCH_TARGET}") >> "$PATCH_LOG" 2>&1
  then
    if (patch -p1 -i "${PATCH_TARGET}" >> "$PATCH_LOG" 2>&1)
    then
        echo " done" | tee -a "$PATCH_LOG"
    return 0
    else
        echo "dry-run ok, but actual failed" | tee -a "$PATCH_LOG"
    fi
  else
    echo "failed" | tee -a "$PATCH_LOG"
  fi
  return 1
}

prepare_sources() {
  log "Exporting sources"
  cd "${PSI_DIR}"/git
  git archive --format=tar HEAD | ( cd "${PSI_DIR}/build" ; tar xf - )
  (
    export ddir="${PSI_DIR}/build"
    git submodule foreach "( git archive --format=tar HEAD ) \
        | ( cd \"${ddir}/\${path}\" ; tar xf - )"
  )

  cd "${PSI_DIR}"
  rev=$(cd git-plus/; git describe --tags | cut -d - -f 2)
  PATCHES=`ls -1 git-plus/patches/*diff 2>/dev/null`
  PATCHES="${PATCHES} ${EXTRA_PATCHES}"
  cd "${PSI_DIR}/build"
  [ -e "$PATCH_LOG" ] && rm "$PATCH_LOG"
  for p in $PATCHES; do
     spatch "${PSI_DIR}/${p}"
     if [ "$?" != 0 ]
     then
       [ $SKIP_INVALID_PATCH = "0" ] \
         && die "can't continue due to patch failed" \
         || log "skip invalid patch"
     fi
  done

  rev_date_list="$(cd ${PSI_DIR}/git/; git log -n1 --date=short --pretty=format:'%ad')
                 $(cd ${PSI_DIR}/git-plus/; git log -n1 --date=short --pretty=format:'%ad')"
  rev_date=$(echo "${rev_date_list}" | sort -r | head -n1)

  case "${CONF_OPTS}" in
    *--enable-webkit*)
      echo "0.16.${rev}-webkit ($(echo ${rev_date}))" > version
      ;;
    *)
      echo "0.16.${rev} ($(echo ${rev_date}))" > version
      ;;
  esac
  sed -i${SED_INPLACE_ARG} \
    "s:target.path.*:target.path = ${PSILIBDIR}/psi-plus/plugins:" \
    src/plugins/psiplugin.pri

  # prepare icons
  cp -a "${PSI_DIR}"/git-plus/iconsets "${PSI_DIR}/build"
  cp "${PSI_DIR}"/git-plus/app.ico "${PSI_DIR}/build/win32"
}

prepare_plugins_sources() {
  [ -d "${PSI_DIR}/build/src/plugins/generic" ] || \
    die "preparing plugins requires prepared psi+ sources"
  for name in ${PLUGINS}; do
    mkdir -p `dirname "${PSI_DIR}/build/src/plugins/$name"`
    cp -a "${PSI_DIR}/plugins/$name" \
      "${PSI_DIR}/build/src/plugins/$name"
  done
}

prepare_all() {
  prepare_sources
  prepare_plugins_sources
}

compile_deps() {
  if [ ! -f "${QCONF}" -a "${BUILD_MISSING_QCONF}" = 1 ]; then
    cd "${PSI_DIR}/qconf"
	./${CONFIGURE} || die "failed to configure qconf"
	"$MAKE" $MAKEOPT || die "failed to make qconf"
	export PATH="${PATH}:$PWD"
	QCONFDIR="${PWD}"
	QCONF="${QCONFDIR}/qconf"
  fi
  if  [ "${BUILD_MISSING_QCA}" = 1 ]; then
    cd "${PSI_DIR}/qca"
	"$QCONF"
	./${CONFIGURE} || die "failed to cofigure qca"
	"$MAKE" $MAKEOPT || die "failed to make qca"
  fi
}

compile_psi() {
  cd "${PSI_DIR}/build"
  "$QCONF"
  log "./${CONFIGURE} ${CONF_OPTS}"
  ./${CONFIGURE} ${CONF_OPTS} || die "configure failed"
  "$MAKE" $MAKEOPT || die "make failed"
}

compile_plugins() {
  failed_plugins="" # global var

  for name in ${PLUGINS}; do
    log "Compiling ${name} plugin.."
    cd  "${PSI_DIR}/build/src/plugins/$name"
    "$QMAKE" "PREFIX=${COMPILE_PREFIX}" && "$MAKE" $MAKEOPT || {
      warning "Failed to make plugin ${name}! Skipping.."
      failed_plugins="${failed_plugins} ${name}"
    }
  done
}

compile_all() {
  compile_deps
  compile_psi
  compile_plugins
}

install_psi() {
  case "`uname`" in MINGW*) return 0; ;; esac # disable on windows, must be reimplemented
  log "Installing psi.."
  BATCH_CODE="${BATCH_CODE}
cd \"${PSI_DIR}/build\";
$MAKE  INSTALL_ROOT=\"${INSTALL_ROOT}\" install || die \"Failed to install Psi+\""
  datadir=`grep PSI_DATADIR "${PSI_DIR}/build/conf.pri" 2>/dev/null`
  datadir="${datadir#*=}"
  if [ -n "${datadir}" -a -n "$TRANSLATIONS" ]; then
    BATCH_CODE="${BATCH_CODE}
mkdir -p \"${INSTALL_ROOT}${datadir}/translations\""
    for l in $TRANSLATIONS; do
      f="${PSI_DIR}/langs/translations/psi_$l"
      #qtf="langs/$l/qt_$l"
      [ -n "${LRELEASE}" -a -f "${f}.ts" ] && "${LRELEASE}" "${f}.ts" 2> /dev/null
      #[ -n "${LRELEASE}" -a -f "${qtf}.ts" ] && "${LRELEASE}" "${qtf}.ts" 2> /dev/null
      [ -f "${f}.qm" ] && BATCH_CODE="${BATCH_CODE}
cp \"${f}.qm\" \"${INSTALL_ROOT}${datadir}/translations\""
      #[ -f "${qtf}.qm" ] && BATCH_CODE="${BATCH_CODE}
#cp \"${PSI_DIR}/${qtf}.qm\" \"${INSTALL_ROOT}${datadir}\""
    done
  fi
  [ "${batch_mode}" = 1 ] || exec_install_batch
}

install_plugins() {
  case "`uname`" in MINGW*) return 0; ;; esac # disable on windows, must be reimplemented
  for name in ${PLUGINS}; do
    case "$failed_plugins" in
      *"$name"*)
        log "Skipping installation of failed plugin ${name}"
    ;;
      *)
        log "Installing ${name} plugin.."
        BATCH_CODE="${BATCH_CODE}
cd \"${PSI_DIR}/build/src/plugins/$name\";
$MAKE  INSTALL_ROOT=\"${INSTALL_ROOT}\" install || die \"Failed to install ${name} plugin..\""
        ;;
    esac
  done
  [ "${batch_mode}" = 1 ] || exec_install_batch
}

start_install_batch() {
  batch_mode=1
  BATCH_CODE=""
}

reset_install_batch() {
  batch_mode=0
  BATCH_CODE=""
}

exec_install_batch() {
  cd "${PSI_DIR}"

  echo "#!/usr/bin/env sh
die() {
  echo; echo \" !!!ERROR: \$@\";
  exit 1;
}

mkdir -p \"${INSTALL_ROOT}\" || die \"can't create install root directory ${INSTALL_ROOT}.\";
$BATCH_CODE
" > install.sh
  chmod +x install.sh

  local real_root="${INSTALL_ROOT}"
  while [ ! -e "$real_root" -a -n "$real_root" ]; do real_root=${real_root%/*}; done
  [ -z "$real_root" ] && real_root=/
  local ir_user=`$STAT_USER_NAME "${real_root}"`
  [ -z "${ir_user}" ] && die "Failed to detect destination directory's user name"
  if [ "${ir_user}" = "`id -un`" ]; then
    ./install.sh || die "install failed"
  else
    log "owner of ${real_root} is ${ir_user} and this is not you."
    priveleged_exec "./install.sh" "${ir_user}"
  fi
  reset_install_batch
}

priveleged_exec() {
  local script="${1}"
  local dest_user="${2}"
  log "Executing: su -m \"${dest_user}\" -c \"${script}\""
  log "please enter ${dest_user}'s password.."
  su -m "${dest_user}" -c "${script}" || die "install failed"
}

install_all() {
  start_install_batch
  install_psi
  install_plugins
  exec_install_batch
}
