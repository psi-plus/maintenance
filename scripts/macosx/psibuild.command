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
# git - vcs system / система контроля версий
# gcc - compiler / компилятор
# qt4 sdk from qt.nokia.com / qt4 sdk c qt.nokia.com
# qca/QtCrypto - encryption libs / криптовальные либы
# Growl framework / фрэймворк Growl
# Sparkle framework / фреймворк Sparkle

# OPTIONS / НАСТРОЙКИ

# build and store directory / каталог для сорсов и сборки
PSI_DIR="${HOME}/psi"

# psimedia dir / каталог с psimedia
PSI_MEDIA_DIR="${PSI_DIR}/psimedia-svn737-mac"

# psi.app dir / каталог psi.app
PSIAPP_DIR=""

# icons for downloads / иконки для скачивания
ICONSETS="system clients activities moods affiliations roster"

# plugins list / список плагинов
PLUGINS=""
# PLUGINS=`ls ${PSI_DIR}/psi-dev/plugins/generic`

# psi version / версия psi
version="0.15"

# svn version / версия svn
rev=""

# do not update anything from repositories until required
WORK_OFFLINE=0

# upload to googlecode
UPLOAD=0

# log of applying patches / лог применения патчей
PATCH_LOG="${PSI_DIR}/psipatch.log"

# skip patches which applies with errors / пропускать глючные патчи
SKIP_INVALID_PATCH=0

# available translations
LANGS="ar be bg br ca cs da de ee el eo es et fi fr hr hu it ja mk nl pl pt pt_BR ru se sk sl sr sr@latin sv sw uk ur_PK vi zh_CN zh_TW"

# selected translations (space-separated, leave empty to autodetect by $LANG)
TRANSLATIONS="${TRANSLATIONS}"

# official repository / репозиторий официальной Psi
GIT_REPO_PSI=git://github.com/psi-im/psi.git

GIT_REPO_PLUS=git://github.com/psi-plus/main.git
GIT_REPO_PLUGINS=git://github.com/psi-plus/plugins.git
GIT_REPO_MAINTENANCE=git://github.com/psi-plus/maintenance.git
GIT_REPO_RESOURCES=git://github.com/psi-plus/resources.git

LANGS_REPO_URI="git://pv.et-inf.fho-emden.de/git/psi-l10n"
RU_LANG_REPO_URI="git://github.com/ivan101/psi-plus-ru.git"

SVN_FETCH="${SVN_FETCH:-svn co --trust-server-cert --non-interactive}"
SVN_UP="${SVN_UP:-svn up --trust-server-cert --non-interactive}"

# enabling WebKit
ENABLE_WEBKIT=0

# using Xcode
USING_XCODE=0

# upload to GoogleCode
UPLOAD=0

# configure options / опции скрипта configure
CONF_OPTS=""

# GoogleCode username / имя пользователя на GoogleCode
GCUSER="user"

# GoogleCode password / пароль на GoogleCode
GCPASS="password"

export QMAKESPEC="macx-g++"

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

	v=`svn --version 2>/dev/null` || die "You should install subversion first. / Сначала установите subversion"
	v=`gmake --version 2>/dev/null`
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
	log "\tFound make tool: ${MAKE}"

	# patch
	[ -z "`which patch`" ] &&
		die "patch tool not found / утилита для наложения патчей не найдена"
	# autodetect --dry-run or -C
	[ -n "`patch --help 2>/dev/null | grep dry-run`" ] && PATCH_DRYRUN_ARG="--dry-run" \
		|| PATCH_DRYRUN_ARG="-C"
	log "\tFound patch tool"

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
			log "\tFound ${name} Qt tool: ${result}"
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
		for qc in qt-qconf qconf qconf-qt4; do
			v=`$qc --version 2>/dev/null |grep affinix` && QCONF=$qc
		done
    [ -z "${QCONF}" ] && die "You should install "\
      "qconf(http://delta.affinix.com/qconf/) / Сначала установите qconf"
	fi
	log "\tFound qconf tool: " $QCONF

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

prepare_workspace() {
	log "Init directories..."
	if [ ! -d "${PSI_DIR}" ]
	then
		mkdir "${PSI_DIR}" || die "can't create work directory ${PSI_DIR}"
	fi
	rm -rf "${PSI_DIR}"/build

	if [ -e "${PATCH_LOG}" ]
	then
		rm ${PATCH_LOG}
	fi
	[ -d "${PSI_DIR}"/build ] && die "can't delete old build directory ${PSI_DIR}/build"
	mkdir "${PSI_DIR}"/build || die "can't create build directory ${PSI_DIR}/build"
	log "\tCreated base directory structure"
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

# Checkout fresh copy or update existing from svn
# Example: svn_fetch svn://host/uri/trunk my_target_dir "Something useful"
svn_fetch() {
  local remote="$1"
  local target="$2"
  local comment="$3"
  [ -z "$target" ] && { target="${remote##*/}"; target="${target%%#*}"; }
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

	local actual_translations=""
	[ -n "$TRANSLATIONS" ] && {
		mkdir -p langs
		for l in $TRANSLATIONS; do
			if [ $l = ru ]; then
				git_fetch "${RU_LANG_REPO_URI}" "langs/$l" "$l langpack"
			else
				git_fetch "${LANGS_REPO_URI}-$l" "langs/$l" "$l langpack"
			fi
			[ -n "${LRELEASE}" -o -f "langs/$l/psi_$l.qm" ] && actual_translations="${actual_translations} $l"
		done
		actual_translations="$(echo $actual_translations)"
		[ -z "${actual_translations}" ] && warning "Translations not found"
	}
  
	cd "${PSI_DIR}"

	if [ ! -f psimedia-svn737-mac.tar.bz2 ]; then
  	log "Downloading psimedia..."
		curl -C http://psi-plus.droppages.com/psimedia/psimedia-svn737-mac.tar.bz2
	fi
	if [ ! -d ${PSI_MEDIA_DIR} ]; then
  	log "Extracting psimedia..."
		tar -xjf psimedia-svn737-mac.tar.bz2
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
	rev=$(cd git-plus/; echo $((`git describe --tags | cut -d - -f 2`+5000)))
	PATCHES=`ls -1 git-plus/patches/*diff | grep -v "0820-psi-dirty-check.diff" 2>/dev/null`
	PATCHESMACOSX=`ls -1 maintenance/scripts/macosx/patches/*diff 2>/dev/null`

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
	( cd "${PSI_DIR}/plugins/generic" ; git archive --format=tar master ) | ( cd "${PSI_DIR}/build/src/plugins/generic" ; tar xf - )
	[ -d "${PSI_DIR}/build/src/plugins/generic" ] || \
		die "preparing plugins requires prepared psi+ sources"
	for name in ${PLUGINS}; do
		mkdir -p `dirname "${PSI_DIR}/build/src/plugins/generic/$name"`
		cp -a "${PSI_DIR}/plugins/generic/$name" \
			"${PSI_DIR}/build/src/plugins/generic/$name"
	done

  cd ${PSI_DIR}/build
  
	if [ $ENABLE_WEBKIT != 0 ]; then
		sed -i "" "s/.xxx/.${rev}/" src/applicationinfo.cpp
		sed -i "" "s/configDif/configDir/" src/applicationinfo.cpp
		sed -i "" "s/psi-plus-mac.xml/psi-plus-wk-mac.xml/" src/applicationinfo.cpp
		sed -i "" "s/.xxx/.${rev}-webkit/" mac/Makefile
		sed -i "" "s/QtDBus phonon/QtDBus QtWebKit phonon/" mac/Makefile
		sed -i "" "s/-devel/.${rev}-webkit/g" mac/Info.plist
	else
		sed -i "" "s/.xxx/.${rev}/" src/applicationinfo.cpp
		sed -i "" "s/configDif/configDir/" src/applicationinfo.cpp
		sed -i "" "s/.xxx/.${rev}/" mac/Makefile
		sed -i "" "s/-devel/.${rev}/g" mac/Info.plist
	fi
	sed -i "" "s/<string>psi<\/string>/<string>psi-plus<\/string>/g" mac/Info.plist
	sed -i "" "s/<\!--<dep type='sparkle'\/>-->/<dep type='sparkle'\/>/g" psi.qc

	cp -f "${PSI_DIR}/maintenance/scripts/macosx/application.icns" "${PSI_DIR}/build/mac/application.icns"
}

src_compile() {
	log "Compiling..."
	cd ${PSI_DIR}/build
	local CONF_OPTS
	$QCONF
	# for Xcode: cd src; qmake; make xcode; xcodebuild -sdk macosx10.5 -configuration Release
	if [ $ENABLE_WEBKIT != 0 ]; then
		CONF_OPTS="--disable-qdbus --enable-plugins --enable-whiteboarding --disable-xss --enable-webkit"
	else
		CONF_OPTS="--disable-qdbus --enable-plugins --enable-whiteboarding --disable-xss"
	fi
	./configure ${CONF_OPTS} || die "configure failed"
	$MAKE $MAKEOPT sub-third-party-qca-all
	$MAKE $MAKEOPT sub-iris-all
	cd src
	qmake
	if [ $USING_XCODE != 0 ]; then
	  PSIAPP_DIR="${PSI_DIR}/build/src/build/Release/psi-plus.app/Contents"
	  $MAKE xcode || die "make failed"
  	xcodebuild -sdk macosx10.5 -configuration Release
	else
	  PSIAPP_DIR="${PSI_DIR}/build/src/psi-plus.app/Contents"
	  $MAKE $MAKEOPT || die "make failed"
	fi
}

plugins_compile() {
#	cd ${PSI_DIR}/build
	PLUGINS=`ls ${PSI_DIR}/plugins/generic | grep -v "videostatusplugin"`
	log "List plugins for compiling..."
	echo ${PLUGINS}
	log "Compiling plugins..."
	for pl in ${PLUGINS}; do
		cd ${PSI_DIR}/build/src/plugins/generic/${pl} && log "Compiling ${pl} plugin." && $QMAKE && $MAKE $MAKEOPT || die "make ${pl} plugin failed"; done

#	failed_plugins="" # global var
#
#	for name in ${PLUGINS}; do
#		log "Compiling ${name} plugin.."
#		cd "${PSI_DIR}/build/src/plugins/generic/$name"
#		$QMAKE && $MAKE $MAKEOPT || {
#			warning "Failed to make plugin ${name}! Skipping.."
#			failed_plugins="${failed_plugins} ${name}"
#		}
#	done
}

copy_resources(){
	log "Copying langpack, web, skins..."
	cd "${PSIAPP_DIR}/Resources/"
	for l in $TRANSLATIONS; do
		f="${PSI_DIR}/langs/$l/psi_$l"
		[ $l = ru ] && qtf="${PSI_DIR}/langs/$l/qt/qt_$l" || qtf="${PSI_DIR}/langs/$l/qt_$l"
		[ -n "${LRELEASE}" -a -f "${f}.ts" ] && "${LRELEASE}" "${f}.ts" 2> /dev/null
		[ -n "${LRELEASE}" -a -f "${qtf}.ts" ] && "${LRELEASE}" "${qtf}.ts" 2> /dev/null
		[ -f "${f}.qm" ] && cp "${f}.qm" .
		[ -f "${qtf}.qm" ] && cp "${qtf}.qm" .
  done

	cp "${PSI_DIR}/sign/dsa_pub.pem" dsa_pub.pem
	cp -r ${PSI_DIR}/build/themes .
	cp -r ${PSI_DIR}/build/sound .
	( cd ${PSI_DIR}/resources ; git archive --format=tar master ) | ( cd "${PSIAPP_DIR}/Resources" ; tar xf - )
	log "Copying plugins..."
	if [ ! -d ${PSIAPP_DIR}/Resources/plugins ]; then
    	mkdir -p "${PSIAPP_DIR}/Resources/plugins"
	fi
	
	for pl in ${PLUGINS}; do
		cd ${PSI_DIR}/build/src/plugins/generic/${pl} && cp *.dylib ${PSIAPP_DIR}/Resources/plugins/; done

	log "Copying psimedia in bundle..."
	cd ${PSI_MEDIA_DIR}

	if [ ! -d ${PSIAPP_DIR}/Frameworks ]; then
		mkdir -p "${PSIAPP_DIR}/Frameworks"
	fi
	cp Frameworks/*.dylib ${PSIAPP_DIR}/Frameworks
	cp -r Frameworks/gstreamer-0.10 ${PSIAPP_DIR}/Frameworks

	if [ ! -d ${PSIAPP_DIR}/Plugins ]; then
		mkdir -p "${PSIAPP_DIR}/Plugins"
	fi

	cp Plugins/libgstprovider.dylib ${PSIAPP_DIR}/Plugins
}

make_bundle() {
	log "Making standalone bundle..."
	cd ${PSI_DIR}/build/mac && make clean
	cp -f "${PSI_DIR}/maintenance/scripts/macosx/template.dmg.bz2" "${PSI_DIR}/build/mac/template.dmg.bz2"
	$MAKE $MAKEOPT && $MAKE $MAKEOPT dmg || die "make dmg failed"
	open ${PSI_DIR}/build/mac
	log "You can find bundle in ${PSI_DIR}/build/mac"
}

make_appcast() {
	cd ${PSI_DIR}
	if [ $ENABLE_WEBKIT != 0 ]; then
		APPCAST_FILE=psi-plus-wk-mac.xml
		VERSION="${version}"."${rev}"-webkit
	else
		APPCAST_FILE=psi-plus-mac.xml
		VERSION="${version}"."${rev}"
	fi
	ARCHIVE_FILENAME=`ls ${PSI_DIR}/build/mac | grep psi-plus`
	
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

	DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILENAME"
	KEYCHAIN_PRIVKEY_NAME="Sparkle Private Key 1"

	SIZE=`ls -lR ${PSI_DIR}/build/mac/disk/Psi\+.app | awk '{sum += $5} END{print sum}'`
	PUBDATE=$(LC_TIME=en_US date +"%a, %d %b %G %T %z")
	cd ${PSI_DIR}/build/mac/

	osversionlong=`sw_vers -productVersion`
	osvers=${osversionlong:3:1}

	if [ $osvers -eq 5 ]
	then
	  SIGNATURE=$(
		  openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" \
			  | openssl dgst -dss1 -sign <(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g') \
			  | openssl enc -base64
	  )
	elif [ $osvers -eq 6 ]
	then
	  SIGNATURE=$(
		  openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" \
			  | openssl dgst -dss1 -sign <(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g' | perl -MXML::LibXML -e 'print XML::LibXML->new()->parse_file("-")->findvalue(q(//string[preceding-sibling::key[1] = "NOTE"]))') \
			  | openssl enc -base64
	  )
	else
	  die "Unknown way of the signature"
	fi

	[ $SIGNATURE ] || { echo Unable to load signing private key with name "'$KEYCHAIN_PRIVKEY_NAME'"; false; }

#	REVINFO=`wget -q -O- http://code.google.com/feeds/p/psi-dev/svnchanges/basic| awk 'BEGIN{RS="<title>"}
#	/Revision/{
#		gsub(/.*<title>|<\/title>.*/,"")
#		print "\t<li>" $0
#	}'`

  cd ${PSI_DIR}/git-plus
	REVINFO=`git log --since="4 weeks ago" --pretty=format:'<li>%s'`

cat > ${PSI_DIR}/${APPCAST_FILE} <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel>
    <title>Psi+ ChangeLog</title>
    <link>http://psi-plus.droppages.com/psi-plus-mac.xml</link>
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
	cp ${PSI_DIR}/${APPCAST_FILE} ${HOME}/Dropbox/Sites/psi-plus.droppages.com/Public/
	cp ${PSI_DIR}/build/mac/$ARCHIVE_FILENAME ${HOME}/Desktop/
}

#############
# Go Go Go! #
#############
while [ "$1" != "" ]; do
	case $1 in
		-w | --webkit )		ENABLE_WEBKIT=1
							;;
		-off | --work-offline )		WORK_OFFLINE=1
							;;
		--upload )		UPLOAD=1
							;;
		-x | --xcode )    USING_XCODE=1
		          ;;
		-h | --help )		echo "usage: $0 [-w | --webkit] [-off | --work-offline] [--upload] | [-h]"
							exit
							;;
		* )					echo "usage: $0 [-w | --webkit] [-off | --work-offline] [--upload] | [-h]"
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
finishtime=`date "+Finish time: %H:%M:%S"`
make_bundle
make_appcast
echo $starttime
echo $finishtime
