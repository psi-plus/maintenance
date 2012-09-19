#!/bin/sh


#Script for getting otrplugin dependencies
#Run as root!!!


OTR_FILE=libotr-4.0.0.tar.gz
GPGERROR_FILE=libgpg-error-1.9.tar.gz
GCRYPT_FILE=libgcrypt-1.5.0.tar.gz
OTR_DIR=libotr-4.0.0
GPGERROR_DIR=libgpg-error-1.9
GCRYPT_DIR=libgcrypt-1.5.0
OTR_URL="http://www.cypherpunks.ca/otr/$OTR_FILE"
GPGERROR_URL="ftp://ftp.gnupg.org/gcrypt/libgpg-error/$GPGERROR_FILE"
GCRYPT_URL="ftp://ftp.gnupg.org/gcrypt/libgcrypt/$GCRYPT_FILE"

OTRDEPS_DIR=/otrdeps

mkdir -p $OTRDEPS_DIR || echo "Error creating $OTRDEPS_DIR! Run script as root!"; exit 1
 
cd $OTRDEPS_DIR
if [ ! -f $GPGERROR_FILE ]; then
        curl -o $GPGERROR_FILE $GPGERROR_URL
        tar jxvf $GPGERROR_FILE
        cd $GPGERROR_DIR
        ./configure && make && make install
	cd $OTRDEPS_DIR
fi

if [ ! -f $GCRYPT_FILE ]; then
        curl -o $GCRYPT_FILE $GCRYPT_URL
        tar jxvf $GCRYPT_FILE
        cd $GCRYPT_DIR
        ./configure && make && make install
	cd $OTRDEPS_DIR
fi


if [ ! -f $OTR_FILE ]; then
	curl -o $OTR_FILE $OTR_URL
	tar jxvf $OTR_FILE
	cd $OTR_DIR
	./configure && make && make install
	cd $OTRDEPS_DIR
fi

