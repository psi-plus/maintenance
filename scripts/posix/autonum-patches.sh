#!/usr/bin/env bash
home=${HOME:-/home/$USER}
logdir=${home}/github/psi
logfile=${logdir}/rename.log
buildpsi=${home}/github/psi/gitwork/main #Change me
patchdir=${buildpsi}/patches
data=$(LANG=en date '+%Y-%m-%d(%H:%M:%S)')
backupdir=${home}/github/psi/backup/${data}
#
minpatchnumber=0009
maxpatchnumber=8000
firstnumber=0010
#COLORS
green="\e[0;32m"
nocolor="\x1B[0m"
pink="\x1B[01;91m"
blue="\x1B[01;94m"
#
echo "-----Log started-----" > ${logfile}
patchlist=$(ls ${patchdir} | grep diff)
echo -e "${blue}Do you want to backup patches before renaming${nocolor}${pink} [y/n]:${nocolor}"
read answer
if [ "${answer}" == "y" ]; then
	mkdir -p ${backupdir}
	cp -r ${patchdir}/*.diff ${backupdir}/
	echo -e "${blue}Backup created in${nocolor} ${green}${backupdir}${nocolor}"
	echo "Backup created in ${backupdir}" >> ${logfile}
fi
inc=${firstnumber}
for patchfile in ${patchlist}; do
	if [ ${patchfile:0:4} -lt ${maxpatchnumber} ] && [ ${patchfile:0:4} -gt ${minpatchnumber} ]; then
		echo -e "${blue}Renaming:${nocolor} ${pink}${patchfile}
${blue} > to${nocolor} ${pink}${inc}${patchfile:4}${nocolor}"
		echo  "Renaming ${patchfile} to ${inc}${patchfile:4}">>${logfile}
		mv -f ${patchdir}/${patchfile} ${patchdir}/${inc}${patchfile:4}
		let shortinc=10#$inc+10
		if [ ${shortinc} -lt 100 ]; then
			inc=00${shortinc}
		else
			if [ ${shortinc} -lt 1000 ]; then
				inc=0${shortinc}
			else
				inc=${shortinc}
			fi
		fi
	fi
done
echo "-----Log finished-----" >> ${logfile}
