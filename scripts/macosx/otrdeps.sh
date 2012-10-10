#!/bin/sh

#Script for getting otrplugin dependencies and building otrplugin
#Used by psibuild.command
#Don't use it direct

if [ $# != 2 ]; then
	echo "usage: $0 [otrdeps dir] [otrplugin dir]"
	exit 1
fi

OTRDEPS_DIR=$1
OTRPLUGIN_DIR=$2

OTR_DIR=libotr-3.2.0
OTR_FILE=libotr-3.2.0.tar.gz
OTR_URL="http://www.cypherpunks.ca/otr/$OTR_FILE"
GPGERROR_DIR=libgpg-error-1.10
GPGERROR_FILE=libgpg-error-1.10.tar.gz
GPGERROR_URL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/$GPGERROR_FILE"
GCRYPT_DIR=libgcrypt-1.5.0
GCRYPT_FILE=libgcrypt-1.5.0.tar.gz
GCRYPT_URL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/$GCRYPT_FILE"
#TIDY_DIR="tidy/tidy"
#TIDY_FILE=tidy.tar.gz
#TIDY_URL="http://tidy.cvs.sourceforge.net/viewvc/tidy/?view=tar"

export MACOSX_DEPLOYMENT_TARGET=10.5

TARGET_ARCHES="i386 x86_64"

build_lib() {
	echo "*** Compiling $1 $2..."
	lib_dir=$1
	target_arch=$2
	target_platform=$target_arch-apple-darwin
	arch_prefix=$OTRDEPS_DIR/$target_arch
	cd $OTRDEPS_DIR/$lib_dir
	make clean >/dev/null
	#CFLAGS="-I$OTRDEPS_DIR/$target_arch/include" LDFLAGS="-L$OTRDEPS_DIR/$target_arch/lib"
	CC="gcc -arch $target_arch" CXX="g++ -arch $target_arch" ./configure -q --host=$target_platform --prefix=$arch_prefix $3
	make >/dev/null
	make install >/dev/null
}

die() { echo "$@"; exit 1; }

prep_deps() {
	deps_libs=`ls $OTRDEPS_DIR/uni/lib | grep ".dylib"`
	for l in $deps_libs; do
		for a in $TARGET_ARCHES; do
			install_name_tool -change "$OTRDEPS_DIR/$a/lib/$l" "@executable_path/../Frameworks/$l" "$OTRPLUGIN_DIR/libotrplugin.dylib"
			for dl in $deps_libs; do
				install_name_tool -change "$OTRDEPS_DIR/$a/lib/$dl" "@executable_path/../Frameworks/$dl" "$OTRDEPS_DIR/uni/lib/$l"
			done
		done
		install_name_tool -id $l "$OTRDEPS_DIR/uni/lib/$l"
	done
}

mkdir -p $OTRDEPS_DIR || die "Error creating $OTRDEPS_DIR!"
 
cd $OTRDEPS_DIR
if [ ! -f $GPGERROR_FILE ]; then
    curl -o $GPGERROR_FILE $GPGERROR_URL
    tar jxvf $GPGERROR_FILE
    for a in $TARGET_ARCHES; do
       	build_lib $GPGERROR_DIR $a
    done
	cd $OTRDEPS_DIR
fi

if [ ! -f $GCRYPT_FILE ]; then
    curl -o $GCRYPT_FILE $GCRYPT_URL
    tar jxvf $GCRYPT_FILE
    for a in $TARGET_ARCHES; do
        build_lib $GCRYPT_DIR $a "--disable-asm --with-gpg-error-prefix=$OTRDEPS_DIR/$a --enable-digests=crc,md4,md5,rmd160,sha1,sha256,sha512,whirlpool"
    done
	cd $OTRDEPS_DIR
fi


if [ ! -f $OTR_FILE ]; then
	curl -o $OTR_FILE $OTR_URL
	tar jxvf $OTR_FILE
	for a in $TARGET_ARCHES; do
		build_lib $OTR_DIR $a "--with-pic --with-libgcrypt-prefix=$OTRDEPS_DIR/$a"
	done
	cd $OTRDEPS_DIR
fi

#if [ ! -f $TIDY_FILE ]; then
#	curl -o $TIDY_FILE $TIDY_URL
#	tar jxvf $TIDY_FILE
#	cd $TIDY_DIR
#	sh build/gnuauto/setup.sh >/dev/null
#	for a in $TARGET_ARCHES; do
#		build_lib $TIDY_DIR $a
#	done
#	cd $OTRDEPS_DIR
#fi

mkdir -p uni
cp -a i386/ uni/
rm -rf uni/lib
rm -rf uni/bin
mkdir -p uni/lib

LIBS=
for n in `find $OTRDEPS_DIR/i386/lib -maxdepth 1 -type f -name \*.dylib`; do
	base_n=`basename $n`
	if [ ! -f "$OTRDEPS_DIR/x86_64/lib/$base_n" ]; then
		continue
	fi
	LIBS="$LIBS $base_n"
done
echo "*** Making universal libs"
for n in $LIBS; do
	PARTS=
	for target_arch in $TARGET_ARCHES; do
		PARTS="$PARTS $target_arch/lib/$n"
	done
	lipo -output uni/lib/$n -create $PARTS
done

LIB_LINKS=
for n in `find $OTRDEPS_DIR/i386/lib -maxdepth 1 -type l -name \*.dylib`; do
	base_n=`basename $n`
	if [ ! -f "$OTRDEPS_DIR/x86_64/lib/$base_n" ]; then
		continue
	fi
	LIB_LINKS="$LIB_LINKS $base_n"
done

for n in $LIB_LINKS; do
	cp -a $OTRDEPS_DIR/i386/lib/$n $OTRDEPS_DIR/uni/lib/$n
done

echo "*** Compiling otrplugin..."
cd $OTRPLUGIN_DIR
#export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$OTRDEPS_DIR/uni/lib
echo "INCLUDEPATH += $OTRDEPS_DIR/uni/include" >> otrplugin.pro
echo "LIBS += -L$OTRDEPS_DIR/uni/lib" >> otrplugin.pro
make clean >/dev/null
$QTDIR/bin/qmake >/dev/null
make >/dev/null

prep_deps


