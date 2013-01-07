#!/bin/bash
#######################################################################
#                                                                     #
#       Universal build script of Psi+ under MacOS X                  #
#       Универсальный скрипт сборки Psi+ под MacOS X                  #
#                                                                     #
#######################################################################

# REQUIREMENTS / ТРЕБОВАНИЯ

# In order to build Psi+ you must have next packages in your system
# Для сборки Psi+ вам понадобятся следующие пакеты
# 64-bit machine (even though universal binaries are produced)
# git
# Xcode
# Qt built for 32-bit/64-bit x86 universal 
# (Take a look here: https://github.com/psi-im/psideps/tree/master/qt)

# QTDIR, pointing to a 32/64-bit x86 build of Qt.
#   For example:
#    QTDIR=/usr/local/Trolltech/Qt-4.8.2


# OPTIONS / НАСТРОЙКИ

# build and store directory / каталог для сорсов и сборки
PSI_DIR="${HOME}/psi"

DEPS_DIR="${PSI_DIR}/deps"

# icons for downloads / иконки для скачивания
ICONSETS="system clients activities moods affiliations roster"

# psi version / версия psi
version="0.16"

# do not update anything from repositories until required
WORK_OFFLINE=0

# upload to googlecode
UPLOAD=0

#Sparkle staff
SPARKLE=0

# build psi deps useing psideps scripts
BUILDDEPS=0

# enabling WebKit
ENABLE_WEBKIT=0

# bundl dev/ plugins
DEV_PLUGINS=0

# log of applying patches / лог применения патчей
PATCH_LOG="${PSI_DIR}/psipatch.log"

# skip patches which applies with errors / пропускать глючные патчи
SKIP_INVALID_PATCH=0

# bandl all translations
ALL_TRANS=0

# make portable version
PORTABLE=0

# official repository / репозиторий официальной Psi
GIT_REPO_PSI=git://github.com/psi-im/psi.git
GIT_REPO_PLUS=git://github.com/psi-plus/main.git
GIT_REPO_PLUGINS=git://github.com/psi-plus/plugins.git
GIT_REPO_MAINTENANCE=git://github.com/psi-plus/maintenance.git
GIT_REPO_RESOURCES=git://github.com/psi-plus/resources.git

# psideps
GIT_REPO_PSIDEPS=git://github.com/psi-im/psideps.git

LANGS_REPO_URI="git://github.com/psi-plus/psi-plus-l10n.git"
#RU_LANG_REPO_URI="git://github.com/ivan101/psi-plus-ru.git"


# configure options / опции скрипта configure
CONF_OPTS=""

# GoogleCode username / имя пользователя на GoogleCode
GCUSER="user"

# GoogleCode password / пароль на GoogleCode
GCPASS="password"

export QMAKESPEC="macx-g++"
#export PATH="$QTDIR/bin:$PATH"

#######################
# FUNCTIONS / ФУНКЦИИ #
#######################
# Exit with error message
die() { echo; echo " !!!ERROR: $@"; exit 1; }
warning() { echo; echo " !!!WARNING: $@"; }
log() { echo -e "\033[1m*** $@ \033[0m"; }

#smart patcher
spatch() {
	popts=""
	PATCH_TARGET="${1}"

	#echo -n " * applying ${PATCH_TARGET}..." | tee -a $PATCH_LOG

	if (patch -p1 ${popts} --dry-run -i ${PATCH_TARGET}) >> $PATCH_LOG 2>&1
	then
		if (patch -p1 ${popts} -i ${PATCH_TARGET} >> $PATCH_LOG 2>&1)
		then
#			echo " done" | tee -a $PATCH_LOG
			return 0
		else
			echo "dry-run ok, but actual failed" | tee -a $PATCH_LOG
		fi
	else
		echo "failed" | tee -a $PATCH_LOG
	fi
	return 1
}

check_env() {
	log "Testing environment..."

	MAKEOPT=${MAKEOPT:--j$((`sysctl -n hw.ncpu`+1)) -s}
	STAT_USER_ID='stat -f %u'
	STAT_USER_NAME='stat -f %Su'
	SED_INPLACE_ARG=".bak"

	v=`gmake --version 2>/dev/null`
	v=`git --version 2>/dev/null` || \
		die "You should install Git first. / Сначала установите Git (http://git-scm.com/download)"

	# Make
	if [ ! -f "${MAKE}" ]; then
		MAKE=""
		for gn in gmake make; do
			[ -n "`$gn --version 2>/dev/null`" ] && { MAKE="$gn"; break; }
		done
		[ -z "${MAKE}" ] && die "You should install GNU Make first / "\
			"Сначала установите GNU Make"
	fi
	log "\tFound make tool: ${MAKE}"

	# patch
	[ -z "`which patch`" ] &&
		die "patch tool not found / утилита для наложения патчей не найдена"
	# autodetect --dry-run or -C
	[ -n "`patch --help 2>/dev/null | grep dry-run`" ] && PATCH_DRYRUN_ARG="--dry-run" \
		|| PATCH_DRYRUN_ARG="-C"
	log "\tFound patch tool"

	# PlistBuddy
	if [ $PORTABLE = 1 ]; then
		[ -x "/usr/libexec/PlistBuddy" ] || die "PlistBuddy not found"
		log "\tFound PlistBuddy"
	fi

	find_qt_util() {
		local name=$1
		result=""
		for un in $QTDIR/bin/$name $QTDIR/bin/$name-qt4 $QTDIR/bin/qt4-${name} $QTDIR/bin/${name}4; do
			[ -n "`$un -v 2>&1 |grep Qt`" ] && { result="$un"; break; }
		done
		if [ -z "${result}" ]; then
			[ "$nonfatal" = 1 ] || die "You should install $name util as part of"\
				"Qt framework / Сначала установите утилиту $name из Qt framework"
			log "${name} Qt tool is not found. ignoring.."
		else
			log "\tFound ${name} Qt tool: ${result}"
		fi
	}

	local result
	# qmake
	find_qt_util qmake; QMAKE="${result}"
	nonfatal=1 find_qt_util lrelease; LRELEASE="${result}"
	#find_qt_util moc; # we don't use it dirrectly but its required.
	#find_qt_util uic; # we don't use it dirrectly but its required.
	#find_qt_util rcc; # we don't use it dirrectly but its required.

	# QConf
	if [ -n "${QCONFDIR}" -a -n "`PATH="${PATH}:${QCONFDIR}" qconf 2>/dev/null`" ]; then
		QCONF="${QCONFDIR}/qconf"
	else
		for qc in qt-qconf qconf qconf-qt4; do
			v=`$qc --version 2>/dev/null |grep affinix` && QCONF=$qc
		done
    	fi
	[ ! -z "${QCONF}" ] && log "\tFound qconf tool: " $QCONF

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
	
	[ -z "${LRELEASE}" ] && warning "lrelease util is not available. so only ready qm files will be installed"

	TRANSLATIONS="$(echo ${selected_langs})"
	log "\tChoosen interface language:" $TRANSLATIONS

	log "Environment is OK"
}

get_qconf() {
	cd "${PSI_DIR}"
	qconf_file=qconf-1.4.tar.bz2
	qconf_dir="${PSI_DIR}/qconf-1.4"
	if [ ! -f $qconf_file ]; then
		log "Downloading qconf…"
		curl -o $qconf_file http://delta.affinix.com/download/$qconf_file
		tar jxvf $qconf_file
		cd $qconf_dir
		./configure && $MAKE $MAKEOPT || die "Can't build qconf!"
	fi
	if [ -f "$qconf_dir/qconf" ]; then
		QCONF="$qconf_dir/qconf"
	else
		die "Can'find qconf!"
	fi
	log "Qconf is ready: $QCONF"
}

get_sparkle() {
	cd $PSI_DIR
	if [ ! -f sparkle.zip ]; then
		log "Downloading sparkle..."
		curl -o sparkle.zip http://sparkle.andymatuschak.org/files/Sparkle%201.5b6.zip
		unzip -d sparkle/ sparkle.zip
		echo "We need admin password for copying sparkle framework"
		sudo cp -a sparkle/Sparkle.framework /Library/Frameworks
	fi
}

prepare_workspace() {
	log "Init directories..."
	if [ ! -d "${PSI_DIR}" ]
	then
		mkdir "${PSI_DIR}" || die "can't create work directory ${PSI_DIR}"
	fi
	if [ ! -d "${DEPS_DIR}" ]
	then
		mkdir "${DEPS_DIR}" || die "can't create work directory ${DEPS_DIR}"
	fi
	rm -rf "${PSI_DIR}"/build

	if [ -e "${PATCH_LOG}" ]
	then
		rm ${PATCH_LOG}
	fi
	[ -d "${PSI_DIR}"/build ] && die "can't delete old build directory ${PSI_DIR}/build"
	mkdir "${PSI_DIR}"/build || die "can't create build directory ${PSI_DIR}/build"
	log "\tCreated base directory structure"

	[ -z "${QCONF}" ] && get_qconf
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
    git submodule update --init || die "git submodule update failed"
  }
  cd "${curd}"
}


fetch_sources() {
	cd "${PSI_DIR}"
	git_fetch "${GIT_REPO_PSI}" git "Psi"
	git_fetch "${GIT_REPO_PLUS}" git-plus "Psi+ additionals"
	git_fetch "${GIT_REPO_MAINTENANCE}" maintenance "Psi+ maintenance"
	git_fetch "${GIT_REPO_RESOURCES}" resources "Psi+ resources"
    	git_fetch "${GIT_REPO_PLUGINS}" plugins "Psi+ plugins"
    	git_fetch "${GIT_REPO_PSIDEPS}" psideps "psideps"
	git_fetch "${LANGS_REPO_URI}" translations "Psi+ translations"
    
	if [ $ALL_TRANS = 1 ]; then
		TRANSLATIONS=`ls ${PSI_DIR}/translations/translations | grep -v en | sed s/psi_// | sed s/.ts//`
	fi

	local actual_translations=""
	[ -n "$TRANSLATIONS" ] && {
		mkdir -p langs
		for l in $TRANSLATIONS; do
			mkdir -p "langs/$l"
			cp -f "translations/translations/psi_$l.ts"  "langs/$l/psi_$l.ts"
			[ -n "${LRELEASE}" -o -f "langs/$l/psi_$l.qm" ] && actual_translations="${actual_translations} $l"
		done
		actual_translations="$(echo $actual_translations)"
		[ -z "${actual_translations}" ] && warning "Translations not found"
	}
    
	. ${PSI_DIR}/git/admin/build/package_info
	PSI_FETCH="${PSI_DIR}/git/admin/fetch.sh"
	if [ $BUILDDEPS = 0 ]; then
		fetch_psi_deps
	fi

	if [ $SPARKLE = 1 ]; then
		get_sparkle
	fi
	cd "${PSI_DIR}"
}

fetch_psi_deps() {
    log "Prepare Psi dependencies..."
    cd "${DEPS_DIR}"
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

prepare_sources() {
	log "Exporting sources..."
	cd "${PSI_DIR}"/git
	git archive --format=tar HEAD | ( cd "${PSI_DIR}/build" ; tar xf - )
	(
		export ddir="${PSI_DIR}/build"
		git submodule foreach '( git archive --format=tar HEAD ) \
			| ( cd "${ddir}/${path}" ; tar xf - )'
	)

	cd "${PSI_DIR}"
	rev=$(cd git-plus/; git describe --tags | cut -d - -f 2)
	PATCHES=`ls -1 git-plus/patches/*diff | grep -v "0820-psi-dirty-check.diff" 2>/dev/null`
	PATCHESMACOSX=`ls -1 git-plus/patches/mac/*diff 2>/dev/null`

	cd "${PSI_DIR}/build"
	[ -e "$PATCH_LOG" ] && rm "$PATCH_LOG"
	echo "$PATCHES" | while read p; do
		spatch "${PSI_DIR}/${p}"
		if [ "$?" != 0 ]
		then
			[ $SKIP_INVALID_PATCH = "0" ] \
				&& die "can't continue due to patch failed" \
				|| log "skip invalid patch"
		fi
	done

	echo "$PATCHESMACOSX" | while read pm; do
		spatch "${PSI_DIR}/${pm}"
		if [ "$?" != 0 ]
		then
			[ $SKIP_INVALID_PATCH = "0" ] \
				&& die "can't continue due to patch failed" \
				|| log "skip invalid patch"
		fi
	done

	sed -i${SED_INPLACE_ARG} "s/.xxx/.${rev}/"  src/applicationinfo.cpp
	sed -i${SED_INPLACE_ARG} \
    "s:target.path.*:target.path = ${PSILIBDIR}/psi-plus/plugins:" \
    src/plugins/psiplugin.pri

	# prepare icons
	cp -a "${PSI_DIR}"/git-plus/iconsets "${PSI_DIR}/build"

	log "Copying plugins..."
	cd "${PSI_DIR}"
	# plugins list / список плагинов
	PLUGINS=`ls ${PSI_DIR}/plugins/generic | grep -v "videostatusplugin"`
	( cd "${PSI_DIR}/plugins/generic" ; git archive --format=tar master ) | ( cd "${PSI_DIR}/build/src/plugins/generic" ; tar xf - )
	[ -d "${PSI_DIR}/build/src/plugins/generic" ] || \
		die "preparing plugins requires prepared psi+ sources"
	for name in ${PLUGINS}; do
		mkdir -p `dirname "${PSI_DIR}/build/src/plugins/generic/$name"`
		cp -a "${PSI_DIR}/plugins/generic/$name" \
			"${PSI_DIR}/build/src/plugins/generic/$name"
	done
    
	if [ $DEV_PLUGINS = 1 ]; then
		copy_dev_plugins
	fi

	cd ${PSI_DIR}/build

	#sed -i "" "s/QtDBus phonon/QtDBus QtWebKit phonon/" mac/Makefile
	#sed -i "" "s/.xxx/.${rev}/" src/applicationinfo.cpp
    
	if [ $ENABLE_WEBKIT != 0 ]; then
		sed -i "" "s/psi-plus-mac.xml/psi-plus-wk-mac.xml/" src/applicationinfo.cpp
		#sed -i "" "s/.xxx/.${rev}-webkit/" mac/Makefile
		#sed -i "" "s/-devel/.${rev}-webkit/g" mac/Info.plist.in
	#else		
		#sed -i "" "s/.xxx/.${rev}/" mac/Makefile
		#sed -i "" "s/-devel/.${rev}/g" mac/Info.plist.in
	fi
	sed -i "" "s/<string>psi<\/string>/<string>psi-plus<\/string>/g" mac/Info.plist.in
	sed -i "" "s/<\!--<dep type='sparkle'\/>-->/<dep type='sparkle'\/>/g" psi.qc
    
	sed -i "" "s/base\/psi.app/base\/psi-plus.app/" admin/build/prep_dist.sh
	sed -i "" "s/base\/Psi.app/base\/Psi+.app/" admin/build/prep_dist.sh
	sed -i "" "s/MacOS\/psi/MacOS\/psi-plus/" admin/build/prep_dist.sh
	sed -i "" "s/QtXml QtGui/QtXml QtGui QtWebKit QtSvg/" admin/build/prep_dist.sh
	sed -i "" "s/.\/pack_dmg.sh/# .\/pack_dmg.sh/" admin/build/Makefile

	cp -f "${PSI_DIR}/maintenance/scripts/macosx/application.icns" "${PSI_DIR}/build/mac/application.icns"
   
	if [ $BUILDDEPS = 1 ]; then
		builddeps
		log "Copy deps..." 
		cd "${PSI_DIR}/build/admin/build"
		mkdir -p deps packages
		cp -a ${PSI_DIR}/psideps/qca/dist/${qca_mac_dir} deps/${qca_mac_dir}
		cp -f "${PSI_DIR}/psideps/qca/${qca_mac_file}" packages/${qca_mac_file}

		cp -a ${PSI_DIR}/psideps/psimedia/dist/${psimedia_mac_dir} deps/${psimedia_mac_dir}
 		cp -f "${PSI_DIR}/psideps/psimedia/${psimedia_mac_file}" packages/${psimedia_mac_file}

		cp -a ${PSI_DIR}/psideps/gstbundle/dist/${gstbundle_mac_dir} deps/${gstbundle_mac_dir}
		cp -f "${PSI_DIR}/psideps/gstbundle/${gstbundle_mac_file}" packages/${gstbundle_mac_file}

		cd $DEPS_DIR
		mkdir -p deps packages
		if [ ! -f "packages/${growl_file}" ]; then
        		sh ${PSI_FETCH} ${growl_url} packages/${growl_file}
        		cd deps && unzip ../packages/${growl_file} && cd ..
    		fi
		cd "${PSI_DIR}/build/admin/build"
		cp -a ${DEPS_DIR}/deps/${growl_dir} deps/${growl_dir}
		cp -f ${DEPS_DIR}/packages/${growl_file} packages/${growl_file}
	else
		log "Copy deps..." 
 		cd "${PSI_DIR}/build/admin/build"
   		mkdir -p packages deps 
    		cp -a "${DEPS_DIR}/packages/" packages/
     		cp -a "${DEPS_DIR}/deps/" deps/
	fi	
}

copy_dev_plugins() {
	PLUGINS_DEV=`ls ${PSI_DIR}/plugins/dev`
	for name in ${PLUGINS_DEV}; do
		mkdir -p `dirname "${PSI_DIR}/build/src/plugins/generic/$name"`
		cp -a "${PSI_DIR}/plugins/dev/$name" \
			"${PSI_DIR}/build/src/plugins/generic/$name"
	done
	PLUGINS="${PLUGINS} ${PLUGINS_DEV}"
}

builddeps() {
    log "Build psi deps..."
    if [ ! -d /psidepsbase ]; then
        die "Create /psidepsbase directory with write access! sudo mkdir /psidepsbase && sudo chmod 777 /psidepsbase"
    fi
    PSIDEPS="${PSI_DIR}/psideps/qca ${PSI_DIR}/psideps/gstbundle ${PSI_DIR}/psideps/psimedia"
    for l in $PSIDEPS; do
        cd "$l"        
        $MAKE || die "Error while building ${l}"
    done
}

src_compile() {
	log "All ready. Now run make..."
	cd ${PSI_DIR}/build
	${QCONF}
	cd ${PSI_DIR}/build/admin/build
	if [ $SPARKLE = 0 ]; then
		CONF_OPTS="--disable-sparkle"
	#else
	#	CONF_OPTS="--with-sparkle=${PSI_DIR}/sparkle"
	#	sed -i "" "s@qca_mac_dir/lib:@&$PSI_DIR/sparkle:@g" build_package.sh
	fi
	if [ $ENABLE_WEBKIT != 0 ]; then
		rev="${rev}-webkit"
		CONF_OPTS="--disable-qdbus --enable-plugins --enable-whiteboarding --disable-xss --enable-webkit $CONF_OPTS"
	else
		CONF_OPTS="--disable-qdbus --enable-plugins --enable-whiteboarding --disable-xss $CONF_OPTS"
	fi

	sed -i "" "s@./configure@& ${CONF_OPTS}@g" build_package.sh
	sed -i "" "s@./configure@& ${CONF_OPTS}@g" devconfig.sh
	sed -i "" 's@echo "$(VERSION)@& (\@\@DATE\@\@)@g' Makefile
	
	$MAKE $MAKEOPT VERSION=${version}.${rev} || die "make failed"
}

plugins_compile() {
	cd "${PSI_DIR}/build/src/plugins"
	echo "CONFIG += x86 x86_64" >> psiplugin.pri
	echo "QMAKE_MAC_SDK=/Developer/SDKs/MacOSX10.5.sdk" >> psiplugin.pri
	echo "QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.5" >> psiplugin.pri
	log "List plugins for compiling..."
	echo ${PLUGINS}
	log "Compiling plugins..."
	for pl in ${PLUGINS}; do
		if [ $pl = "otrplugin" ]; then
			OTRDEPS_DIR=$PSI_DIR/otrdeps
			sh $PSI_DIR/maintenance/scripts/macosx/otrdeps.sh $OTRDEPS_DIR ${PSI_DIR}/build/src/plugins/generic/${pl} 2>/dev/null || die "make ${pl} plugin failed"
		else
			cd ${PSI_DIR}/build/src/plugins/generic/${pl} && log "Compiling ${pl} plugin." && $QMAKE && $MAKE $MAKEOPT || die "make ${pl} plugin failed"
		fi
	done
}

copy_resources() {
	PSIAPP_DIR="${PSI_DIR}/build/admin/build/dist/psi-${version}.${rev}-mac/Psi+.app/Contents"
	log "Copying langpack, web, skins..."
	cd "${PSIAPP_DIR}/Resources/"
	mkdir -p translations/
	cd translations/
	for l in $TRANSLATIONS; do
		f="${PSI_DIR}/langs/$l/psi_$l"
		qtf="${QTDIR}/translations/qt_$l"
		[ -n "${LRELEASE}" -a -f "${f}.ts" ] && "${LRELEASE}" "${f}.ts" 2> /dev/null
		#[ -n "${LRELEASE}" -a -f "${qtf}.ts" ] && "${LRELEASE}" "${qtf}.ts" 2> /dev/null
		[ -f "${f}.qm" ] && cp "${f}.qm" .
		[ -f "${qtf}.qm" ] && cp "${qtf}.qm" .
	done

	cd "${PSIAPP_DIR}/Resources/"    
	cp -r ${PSI_DIR}/build/sound .
	cp -r ${PSI_DIR}/build/themes .
	( cd ${PSI_DIR}/resources ; git archive --format=tar master ) | ( cd "${PSIAPP_DIR}/Resources" ; tar xf - )
	log "Copying plugins..."
	if [ ! -d ${PSIAPP_DIR}/Resources/plugins ]; then
    		mkdir -p "${PSIAPP_DIR}/Resources/plugins"
	fi
	
	for pl in ${PLUGINS}; do
		cd ${PSI_DIR}/build/src/plugins/generic/${pl} && cp *.dylib ${PSIAPP_DIR}/Resources/plugins/; done
        
	PSIPLUS_PLUGINS=`ls $PSIAPP_DIR/Resources/plugins`
	QT_FRAMEWORKS="QtCore QtNetwork QtXml QtGui QtWebKit QtSvg"
	QT_FRAMEWORK_VERSION=4
	for f in ${QT_FRAMEWORKS}; do
		for p in ${PSIPLUS_PLUGINS}; do
			install_name_tool -change "${QTDIR}/lib/${f}.framework/Versions/${QT_FRAMEWORK_VERSION}/${f}" "@executable_path/../Frameworks/${f}.framework/Versions/${QT_FRAMEWORK_VERSION}/${f}" "${PSIAPP_DIR}/Resources/plugins/${p}"
		done
	done

	if [ $DEV_PLUGINS = 1 ]; then
		otr_deps=`ls $OTRDEPS_DIR/uni/lib | grep "dylib"`
		for d in $otr_deps; do
			cp -a "$OTRDEPS_DIR/uni/lib/$d" "${PSIAPP_DIR}/Frameworks/$d"
		done
	fi

	if [ $SPARKLE = 1 ]; then
		log "Copying Sparkle..."
		cp "${PSI_DIR}/sign/dsa_pub.pem" dsa_pub.pem
		cp -a "/Library/Frameworks/Sparkle.framework" "${PSIAPP_DIR}/Frameworks/"
	fi
}

make_bundle() {
	log "Making standalone bundle..."
	cd ${PSI_DIR}/build/admin/build
	cp -f "${PSI_DIR}/maintenance/scripts/macosx/template.dmg.bz2" "template.dmg.bz2"
	sh pack_dmg.sh "psi-plus-${version}.${rev}.dmg" "Psi+" "dist/psi-${version}.${rev}-mac"

	cp -f psi-plus-${version}.${rev}.dmg "${PSI_DIR}/psi-plus-${version}.${rev}-macosx.dmg"
	log "You can find bundle in ${PSI_DIR}/psi-plus-${version}.${rev}-macosx.dmg"

	if [ $PORTABLE = 1 ]; then
		PORT_DMG="psi-plus-portable-${version}.${rev}.dmg"
		WC_DIR="wc"
		WC_DMG="wc.dmg"
		rm -fr "$WC_DIR"
		hdiutil convert "psi-plus-${version}.${rev}.dmg" -quiet -format UDRW -o "$WC_DMG"
		hdiutil attach "$WC_DMG" -noautoopen -quiet -mountpoint "$WC_DIR"
		mv "$WC_DIR/Psi+.app" "$WC_DIR/Portable Psi+.app"
		pushd "$WC_DIR/Portable Psi+.app/Contents"
		/usr/libexec/PlistBuddy -c 'Add :LSEnvironment:PSIDATADIR string "Portable Psi+.app/Psi+"' Info.plist
		/usr/libexec/PlistBuddy -c 'Set :CFBundleName string "Portable Psi+"' Info.plist
		popd
		rm -fr "$WC_DIR/.DS_Store" "$WC_DIR/Applications" "$WC_DIR/.background" "$WC_DIR/.fseventsd"
		diskutil rename "$WC_DIR" "Portable Psi+"
		diskutil eject "$WC_DIR"
		hdiutil convert "$WC_DMG" -quiet -format UDZO -imagekey zlib-level=9 -o "$PORT_DMG"
		cp -f psi-plus-portable-${version}.${rev}.dmg "${PSI_DIR}/psi-plus-portable-${version}.${rev}-macosx.dmg" && rm -f psi-plus-potable-${version}.${rev}.dmg
		log "You can find next bundle in ${PSI_DIR}/psi-plus-portable-${version}.${rev}-macosx.dmg"
	fi
	rm -f psi-plus-${version}.${rev}.dmg
}

make_appcast() {
	cd ${PSI_DIR}
	if [ $ENABLE_WEBKIT != 0 ]; then
		APPCAST_FILE=psi-plus-wk-mac.xml
	else
		APPCAST_FILE=psi-plus-mac.xml
	fi
	VERSION="${version}"."${rev}"
	ARCHIVE_FILENAME="psi-plus-${VERSION}-macosx.dmg"
	
	if [ $UPLOAD != 0 ]; then
	  log "Uploading dmg on GoogleCode"
	  if [ $ENABLE_WEBKIT != 0 ]; then
		  time googlecode_upload.py -s "Psi+ IM || psi-git `date +"%Y-%m-%d"` || Qt 4.7.4 || WebKit included || Unstable || FOR TEST ONLY" -p psi-dev --labels=WebKit,MacOSX,DiskImage --user=${GCUSER} --password=${GCPASS} ${PSI_DIR}/build/mac/$ARCHIVE_FILENAME || die "uploading failed"
	  else
		  time googlecode_upload.py -s "Psi+ IM || psi-git `date +"%Y-%m-%d"` || Qt 4.7.4 || Beta" -p psi-dev --labels=Featured,MacOSX,DiskImage --user=${GCUSER} --password=${GCPASS} ${PSI_DIR}/build/mac/$ARCHIVE_FILENAME || die "uploading failed"
	  fi
	fi

	log "Making appcast file..."
	DOWNLOAD_BASE_URL="http://psi-dev.googlecode.com/files"
	APPCAST_LINK="${DOWNLOAD_BASE_URL}/${APPCAST_FILE}"

	DOWNLOAD_URL="${DOWNLOAD_BASE_URL}/${ARCHIVE_FILENAME}"
	KEYCHAIN_PRIVKEY_NAME="Sparkle Private Key 1"

	SIZE=`ls -lR ${PSI_DIR}/build/admin/build/dist/psi-${version}.${rev}-mac/Psi\+.app | awk '{sum += $5} END{print sum}'`
	PUBDATE=$(LC_TIME=en_US date +"%a, %d %b %G %T %z")

	osversionlong=`sw_vers -productVersion`
	osvers=${osversionlong:3:1}


    cd ${PSI_DIR}/git-plus
	REVINFO=`git log --since="4 weeks ago" --pretty=format:'<li>%s'`
    
    SIGNATURE=$( ruby "${PSI_DIR}/sign/sign_update.rb" "${PSI_DIR}/${ARCHIVE_FILENAME}" "${PSI_DIR}/sign/dsa_priv.pem" )

cat > ${PSI_DIR}/${APPCAST_FILE} <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel>
    <title>Psi+ ChangeLog</title>
    <link>$APPCAST_LINK</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
		<item>
		<title>Version $VERSION</title>
		<description><![CDATA[
		<h2>Changes</h2>
		<ul>
${REVINFO}
		</ul>
		]]></description>
		<pubDate>$PUBDATE</pubDate>
		<enclosure
	    	url="$DOWNLOAD_URL"
	    	sparkle:version="$VERSION"
	    	type="application/octet-stream"
	    	length="$SIZE"
	    	sparkle:dsaSignature="$SIGNATURE"
		/>
    	</item>
</channel>
</rss>
EOF

	log "You can find appcast in ${PSI_DIR}/${APPCAST_FILE}"
}

#############
# Go Go Go! #
#############
while [ "$1" != "" ]; do
	case $1 in
		-w | --webkit )		ENABLE_WEBKIT=1
							;;
		-b | --build-deps )	BUILDDEPS=1
							;;
		-off | --work-offline )	WORK_OFFLINE=1
							;;
		--upload )		UPLOAD=1
							;;
		--sparkle )		SPARKLE=1
							;;
		--with-translations )	ALL_TRANS=1
							;;
		--with-devplugins )	DEV_PLUGINS=1
							;;
		-p | --portable )	PORTABLE=1
							;;
		-h | --help )		echo "usage: $0 [-w | --webkit] [-b | --build-deps] [-off | --work-offline] [--upload] [--sparkle] [--with-devplugins] [--with-translations] | [-p | --portable] | [-h]"
							exit
							;;
		* )					echo "usage: $0 [-w | --webkit] [-b | --build-deps] [-off | --work-offline] [--upload] [--sparkle] [--with-devplugins] [--with-translations] | [-p | --portable] | [-h]"
							exit 1
	esac
	shift
done

starttime=`date "+Start time: %H:%M:%S"`
check_env
prepare_workspace
fetch_sources
prepare_sources
src_compile
plugins_compile
copy_resources
make_bundle
if [ $SPARKLE = 1 ]; then
	make_appcast
fi
finishtime=`date "+Finish time: %H:%M:%S"`
echo $starttime
echo $finishtime
