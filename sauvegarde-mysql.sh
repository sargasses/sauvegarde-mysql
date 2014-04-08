#!/bin/bash
#
# Copyright 2013-2014 
# Développé par : Stéphane HACQUARD
# Date : 08-04-2014
# Version 1.0
# Pour plus de renseignements : stephane.hacquard@sargasses.fr



#############################################################################
# Variables d'environnement
#############################################################################


DIALOG=${DIALOG=dialog}

REPERTOIRE_CONFIG=/usr/local/scripts/config
FICHIER_CENTRALISATION_SAUVEGARDE=config_centralisation_sauvegarde

REPERTOIRE_SCRIPTS=/usr/local/scripts
FICHIER_SCRIPTS_MySQL_LOCAL=sauvegarde_mysql_local.sh
FICHIER_SCRIPTS_MySQL_RESEAU=sauvegarde_mysql_reseau.sh
FICHIER_SCRIPTS_MySQL_FTP=sauvegarde_mysql_ftp.sh
FICHIER_SCRIPTS_MySQL_FTPS=sauvegarde_mysql_ftps.sh

FICHIER_PURGE_MySQL_LOCAL=purge_mysql_local.sh
FICHIER_PURGE_MySQL_RESEAU=purge_mysql_reseau.sh
FICHIER_PURGE_MySQL_FTP=purge_mysql_ftp.sh
FICHIER_PURGE_MySQL_FTPS=purge_mysql_ftps.sh

REPERTOIRE_CRON=/etc/cron.d
FICHIER_CRON_SAUVEGARDE=sauvegarde_mysql

TMP=/tmp

DATE='`date '+%d-%m-%Y'`'
DATE_HEURE='`date +%d.%m.%y`-`date +%H`h`date +%M`'


#############################################################################
# Fonction Verification installation de dialog
#############################################################################


if [ ! -f /usr/bin/dialog ] ; then
	echo "Le programme dialog n'est pas installé!"
	apt-get install dialog
else
	echo "Le programme dialog est déjà installé!"
fi


#############################################################################
# Fonction Activation De La Banner Pour SSH
#############################################################################


if grep "^#Banner" /etc/ssh/sshd_config > /dev/null ; then
	echo "Configuration de Banner en cours!"
	sed -i "s/#Banner/Banner/g" /etc/ssh/sshd_config 
	/etc/init.d/ssh reload
else 
	echo "Banner déjà activée!"
fi


#############################################################################
# Fonction Verification Installation SmbClient 
#############################################################################


if [ -f /sbin/mount.smbfs ] ; then
	CLIENT_SMB=smbfs
fi

if [ -f /sbin/mount.cifs ] ; then
	CLIENT_SMB=cifs
fi


#############################################################################
# Fonction Lecture Fichier Configuration Gestion Centraliser Sauvegarde
#############################################################################

lecture_config_centraliser_sauvegarde()
{

if test -e $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE ; then

num=10
while [ "$num" -le 15 ] 
	do
	VAR=VAR$num
	VAL1=`cat $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE | grep $VAR=`
	VAL2=`expr length "$VAL1"`
	VAL3=`expr substr "$VAL1" 7 $VAL2`
	eval VAR$num="$VAL3"
	num=`expr $num + 1`
	done

else 

mkdir -p $REPERTOIRE_CONFIG

num=10
while [ "$num" -le 15 ] 
	do
	echo "VAR$num=" >> $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE
	num=`expr $num + 1`
	done

num=10
while [ "$num" -le 15 ] 
	do
	VAR=VALFIC$num
	VAL1=`cat $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE | grep $VAR=`
	VAL2=`expr length "$VAL1"`
	VAL3=`expr substr "$VAL1" 7 $VAL2`
	eval VAR$num="$VAL3"
	num=`expr $num + 1`
	done

fi

if [ "$VAR10" = "" ] ; then
	REF10=`uname -n`
else
	REF10=$VAR10
fi

if [ "$VAR11" = "" ] ; then
	REF11=3306
else
	REF11=$VAR11
fi

if [ "$VAR12" = "" ] ; then
	REF12=sauvegarde
else
	REF12=$VAR12
fi

if [ "$VAR13" = "" ] ; then
	REF13=root
else
	REF13=$VAR13
fi

if [ "$VAR14" = "" ] ; then
	REF14=password
else
	REF14=$VAR14
fi

}

#############################################################################
# Fonction Creation Automatique des Scripts Sauvegarde
#############################################################################

creation_automatique_scripts_sauvegarde()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$

if [ "$VAR15" = "OUI" ] &&
   [ ! -f $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE ] ; then


	cat <<- EOF > $fichtemp
	select nombre_bases
	from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/nombre-bases-lister.txt

	nombre_bases_lister=$(sed '$!d' /tmp/nombre-bases-lister.txt)
	rm -f /tmp/nombre-bases-lister.txt
	rm -f $fichtemp

	if [ "$nombre_bases_lister" != "0" ] ; then

	creation_fichier_cron_sauvegarde
	
	fi

	cat <<- EOF > $fichtemp
	select cron_activer
	from sauvegarde_local
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/cron-sauvegarde-local.txt

	cron_sauvegarde_local=$(sed '$!d' /tmp/cron-sauvegarde-local.txt)
	rm -f /tmp/cron-sauvegarde-local.txt
	rm -f $fichtemp

	if [ "$cron_sauvegarde_local" = "oui" ] ; then

	creation_script_sauvegarde_local
	
	fi

	cat <<- EOF > $fichtemp
	select cron_activer
	from sauvegarde_reseau
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/cron-sauvegarde-reseau.txt

	cron_sauvegarde_reseau=$(sed '$!d' /tmp/cron-sauvegarde-reseau.txt)
	rm -f /tmp/cron-sauvegarde-reseau.txt
	rm -f $fichtemp

	if [ "$cron_sauvegarde_reseau" = "oui" ] ; then

	creation_script_sauvegarde_reseau
	
	fi

	cat <<- EOF > $fichtemp
	select cron_activer
	from sauvegarde_ftp
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/cron-sauvegarde-ftp.txt

	cron_sauvegarde_ftp=$(sed '$!d' /tmp/cron-sauvegarde-ftp.txt)
	rm -f /tmp/cron-sauvegarde-ftp.txt
	rm -f $fichtemp

	if [ "$cron_sauvegarde_ftp" = "oui" ] ; then

	creation_script_sauvegarde_ftp

	fi

	cat <<- EOF > $fichtemp
	select cron_activer
	from sauvegarde_ftps
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/cron-sauvegarde-ftps.txt

	cron_sauvegarde_ftps=$(sed '$!d' /tmp/cron-sauvegarde-ftps.txt)
	rm -f /tmp/cron-sauvegarde-ftps.txt
	rm -f $fichtemp

	if [ "$cron_sauvegarde_ftps" = "oui" ] ; then

	creation_script_sauvegarde_ftps

	fi
fi

rm -f $fichtemp

}

#############################################################################
# Fonction Lecture Des Valeurs Dans La Base de Donnée
#############################################################################

lecture_valeurs_base_donnees()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


cat <<- EOF > $fichtemp
select user
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-user.txt

lecture_user=$(sed '$!d' /tmp/lecture-user.txt)
rm -f /tmp/lecture-user.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select password
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-password.txt

lecture_password=$(sed '$!d' /tmp/lecture-password.txt)
rm -f /tmp/lecture-password.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select base
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-bases.txt

sed -i '1d' /tmp/lecture-bases.txt

lecture_bases_no1=$(sed -n '1p' /tmp/lecture-bases.txt)
lecture_bases_no2=$(sed -n '2p' /tmp/lecture-bases.txt)
lecture_bases_no3=$(sed -n '3p' /tmp/lecture-bases.txt)
lecture_bases_no4=$(sed -n '4p' /tmp/lecture-bases.txt)
rm -f /tmp/lecture-bases.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select nombre_bases
from information
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/nombre-bases-lister.txt

nombre_bases_lister=$(sed '$!d' /tmp/nombre-bases-lister.txt)
rm -f /tmp/nombre-bases-lister.txt
rm -f $fichtemp


if [ "$nombre_bases_lister" = "" ] ; then

cat <<- EOF > $fichtemp
insert into information ( uname, nombre_bases, application )
values ( '`uname -n`' , '0' , 'mysql' ) ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

rm -f $fichtemp

nombre_bases_lister=0

fi


if [ "$lecture_user" = "" ] ; then
	REF20=root
else
	REF20=$lecture_user
fi

if [ "$lecture_password" = "" ] ; then
	REF21=password
else
	REF21=$lecture_password
fi

if [ "$lecture_bases_no1" = "" ] ; then
	REF22=centreon
else
	REF22=$lecture_bases_no1
fi

if [ "$lecture_bases_no2" = "" ] ; then
	REF23=centcore
else
	REF23=$lecture_bases_no2
fi

if [ "$lecture_bases_no3" = "" ] ; then
	REF24=centstorage
else
	REF24=$lecture_bases_no3
fi

if [ "$lecture_bases_no4" = "" ] ; then
	REF25=centaudit
else
	REF25=$lecture_bases_no4
fi

if [ "$nombre_bases_lister" -ge "5" ] ; then
	default_item=5
else
if [ "$nombre_bases_lister" = "0" ] ; then
	default_item=6
else
	default_item="$nombre_bases_lister"
fi
fi

cat <<- EOF > $fichtemp
select chemin
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-chemin.txt

lecture_chemin=$(sed '$!d' /tmp/lecture-chemin.txt)
rm -f /tmp/lecture-chemin.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select heures
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-heures.txt

lecture_heures=$(sed '$!d' /tmp/lecture-heures.txt)
rm -f /tmp/lecture-heures.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select minutes
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-minutes.txt

lecture_minutes=$(sed '$!d' /tmp/lecture-minutes.txt)
rm -f /tmp/lecture-minutes.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select jours
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-jours.txt

lecture_jours=$(sed '$!d' /tmp/lecture-jours.txt)
rm -f /tmp/lecture-jours.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select retentions
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp


if [ "$lecture_chemin" = "" ] ; then
	REF30=/sauvegarde
else
	REF30=$lecture_chemin
fi

if [ "$lecture_heures" = "" ] ; then
	REF31=21
else
	REF31=$lecture_heures
fi

if [ "$lecture_minutes" = "" ] ; then
	REF32=30
else
	REF32=$lecture_minutes
fi

if [ "$lecture_jours" = "" ] ; then
	REF33=1-7
else
	REF33=$lecture_jours
fi

if [ "$lecture_retentions" = "" ] ; then
	REF34=31
	REF35=00
else
	REF34=$lecture_retentions
	REF35=$lecture_retentions
fi


cat <<- EOF > $fichtemp
select serveur
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-serveur.txt

lecture_serveur=$(sed '$!d' /tmp/lecture-serveur.txt)
rm -f /tmp/lecture-serveur.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select partage
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-partage.txt

lecture_partage=$(sed '$!d' /tmp/lecture-partage.txt)
rm -f /tmp/lecture-partage.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select utilisateur
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-utilisateur.txt

lecture_utilisateur=$(sed '$!d' /tmp/lecture-utilisateur.txt)
rm -f /tmp/lecture-utilisateur.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select password
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-password.txt

lecture_password=$(sed '$!d' /tmp/lecture-password.txt)
rm -f /tmp/lecture-password.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select heures
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-heures.txt

lecture_heures=$(sed '$!d' /tmp/lecture-heures.txt)
rm -f /tmp/lecture-heures.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select minutes
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-minutes.txt

lecture_minutes=$(sed '$!d' /tmp/lecture-minutes.txt)
rm -f /tmp/lecture-minutes.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select jours
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-jours.txt

lecture_jours=$(sed '$!d' /tmp/lecture-jours.txt)
rm -f /tmp/lecture-jours.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select retentions
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp


if [ "$lecture_serveur" = "" ] ; then
	REF40=`uname -n`
else
	REF40=$lecture_serveur
fi

if [ "$lecture_partage" = "" ] ; then
	REF41=Sauvegarde
else
	REF41=$lecture_partage
fi

if [ "$lecture_utilisateur" = "" ] ; then
	REF42=Administrateur
else
	REF42=$lecture_utilisateur
fi

if [ "$lecture_password" = "" ] ; then
	REF43=admin
else
	REF43=$lecture_password
fi

if [ "$lecture_heures" = "" ] ; then
	REF44=21
else
	REF44=$lecture_heures
fi

if [ "$lecture_minutes" = "" ] ; then
	REF45=30
else
	REF45=$lecture_minutes
fi

if [ "$lecture_jours" = "" ] ; then
	REF46=1-7
else
	REF46=$lecture_jours
fi

if [ "$lecture_retentions" = "" ] ; then
	REF47=31
	REF48=00
else
	REF47=$lecture_retentions
	REF48=$lecture_retentions
fi


cat <<- EOF > $fichtemp
select serveur
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-serveur.txt

lecture_serveur=$(sed '$!d' /tmp/lecture-serveur.txt)
rm -f /tmp/lecture-serveur.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select port
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-port.txt

lecture_port=$(sed '$!d' /tmp/lecture-port.txt)
rm -f /tmp/lecture-port.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select dossier
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-dossier.txt

lecture_dossier=$(sed '$!d' /tmp/lecture-dossier.txt)
rm -f /tmp/lecture-dossier.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select utilisateur
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-utilisateur.txt

lecture_utilisateur=$(sed '$!d' /tmp/lecture-utilisateur.txt)
rm -f /tmp/lecture-utilisateur.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select password
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-password.txt

lecture_password=$(sed '$!d' /tmp/lecture-password.txt)
rm -f /tmp/lecture-password.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select heures
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-heures.txt

lecture_heures=$(sed '$!d' /tmp/lecture-heures.txt)
rm -f /tmp/lecture-heures.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select minutes
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-minutes.txt

lecture_minutes=$(sed '$!d' /tmp/lecture-minutes.txt)
rm -f /tmp/lecture-minutes.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select jours
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-jours.txt

lecture_jours=$(sed '$!d' /tmp/lecture-jours.txt)
rm -f /tmp/lecture-jours.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select retentions
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp


if [ "$lecture_serveur" = "" ] ; then
	REF50=ftpperso.free.fr
else
	REF50=$lecture_serveur
fi

if [ "$lecture_port" = "" ] ; then
	REF51=21
else
	REF51=$lecture_port
fi

if [ "$lecture_dossier" = "" ] ; then
	REF52=Sauvegarde
else
	REF52=$lecture_dossier
fi

if [ "$lecture_utilisateur" = "" ] ; then
	REF53=Administrateur
else
	REF53=$lecture_utilisateur
fi

if [ "$lecture_password" = "" ] ; then
	REF54=admin
else
	REF54=$lecture_password
fi

if [ "$lecture_heures" = "" ] ; then
	REF55=21
else
	REF55=$lecture_heures
fi

if [ "$lecture_minutes" = "" ] ; then
	REF56=30
else
	REF56=$lecture_minutes
fi

if [ "$lecture_jours" = "" ] ; then
	REF57=1-7
else
	REF57=$lecture_jours
fi

if [ "$lecture_retentions" = "" ] ; then
	REF58=31
	REF59=00
else
	REF58=$lecture_retentions
	REF59=$lecture_retentions
fi


cat <<- EOF > $fichtemp
select serveur
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-serveur.txt

lecture_serveur=$(sed '$!d' /tmp/lecture-serveur.txt)
rm -f /tmp/lecture-serveur.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select port
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-port.txt

lecture_port=$(sed '$!d' /tmp/lecture-port.txt)
rm -f /tmp/lecture-port.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select dossier
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-dossier.txt

lecture_dossier=$(sed '$!d' /tmp/lecture-dossier.txt)
rm -f /tmp/lecture-dossier.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select utilisateur
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-utilisateur.txt

lecture_utilisateur=$(sed '$!d' /tmp/lecture-utilisateur.txt)
rm -f /tmp/lecture-utilisateur.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select password
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-password.txt

lecture_password=$(sed '$!d' /tmp/lecture-password.txt)
rm -f /tmp/lecture-password.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select heures
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-heures.txt

lecture_heures=$(sed '$!d' /tmp/lecture-heures.txt)
rm -f /tmp/lecture-heures.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select minutes
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-minutes.txt

lecture_minutes=$(sed '$!d' /tmp/lecture-minutes.txt)
rm -f /tmp/lecture-minutes.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select jours
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-jours.txt

lecture_jours=$(sed '$!d' /tmp/lecture-jours.txt)
rm -f /tmp/lecture-jours.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select retentions
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp


if [ "$lecture_serveur" = "" ] ; then
	REF60=ftpperso.free.fr
else
	REF60=$lecture_serveur
fi

if [ "$lecture_port" = "" ] ; then
	REF61=21
else
	REF61=$lecture_port
fi

if [ "$lecture_dossier" = "" ] ; then
	REF62=Sauvegarde
else
	REF62=$lecture_dossier
fi

if [ "$lecture_utilisateur" = "" ] ; then
	REF63=Administrateur
else
	REF63=$lecture_utilisateur
fi

if [ "$lecture_password" = "" ] ; then
	REF64=admin
else
	REF64=$lecture_password
fi

if [ "$lecture_heures" = "" ] ; then
	REF65=21
else
	REF65=$lecture_heures
fi

if [ "$lecture_minutes" = "" ] ; then
	REF66=30
else
	REF66=$lecture_minutes
fi

if [ "$lecture_jours" = "" ] ; then
	REF67=1-7
else
	REF67=$lecture_jours
fi

if [ "$lecture_retentions" = "" ] ; then
	REF68=31
	REF69=00
else
	REF68=$lecture_retentions
	REF69=$lecture_retentions
fi


cat <<- EOF > $fichtemp
select cron_activer
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-cron-local.txt

lecture_cron_local=$(sed '$!d' /tmp/lecture-cron-local.txt)
rm -f /tmp/lecture-cron-local.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select cron_activer
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-cron-reseau.txt

lecture_cron_reseau=$(sed '$!d' /tmp/lecture-cron-reseau.txt)
rm -f /tmp/lecture-cron-reseau.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select cron_activer
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-cron-ftp.txt

lecture_cron_ftp=$(sed '$!d' /tmp/lecture-cron-ftp.txt)
rm -f /tmp/lecture-cron-ftp.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select cron_activer
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-cron-ftps.txt

lecture_cron_ftps=$(sed '$!d' /tmp/lecture-cron-ftps.txt)
rm -f /tmp/lecture-cron-ftps.txt
rm -f $fichtemp


if [ "$lecture_cron_local" = "" ] ; then
	lecture_cron_local=non
fi

if [ "$lecture_cron_reseau" = "" ] ; then
	lecture_cron_reseau=non
fi

if [ "$lecture_cron_ftp" = "" ] ; then
	lecture_cron_ftp=non
fi

if [ "$lecture_cron_ftps" = "" ] ; then
	lecture_cron_ftps=non
fi


cat <<- EOF > $fichtemp
select erreur
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-erreur-local.txt

lecture_erreur_local=$(sed '$!d' /tmp/lecture-erreur-local.txt)
rm -f /tmp/lecture-erreur-local.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select erreur
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-erreur-reseau.txt

lecture_erreur_reseau=$(sed '$!d' /tmp/lecture-erreur-reseau.txt)
rm -f /tmp/lecture-erreur-reseau.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select erreur
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-erreur-ftp.txt

lecture_erreur_ftp=$(sed '$!d' /tmp/lecture-erreur-ftp.txt)
rm -f /tmp/lecture-erreur-ftp.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select erreur
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-erreur-ftps.txt

lecture_erreur_ftps=$(sed '$!d' /tmp/lecture-erreur-ftps.txt)
rm -f /tmp/lecture-erreur-ftps.txt
rm -f $fichtemp


if [ "$lecture_erreur_local" = "" ] ; then
	lecture_erreur_local=oui
fi

if [ "$lecture_erreur_reseau" = "" ] ; then
	lecture_erreur_reseau=oui
fi

if [ "$lecture_erreur_ftp" = "" ] ; then
	lecture_erreur_ftp=oui
fi

if [ "$lecture_erreur_ftps" = "" ] ; then
	lecture_erreur_ftps=oui
fi

}

#############################################################################
# Fonction Lecture Des Valeurs De Retention
#############################################################################

lecture_valeurs_retentions()
{

RETENTION_MySQL_LOCAL='`date +%d-%m-%Y --date '"'$REF34 days ago'"'`'
RETENTION_MySQL_RESEAU='`date +%d-%m-%Y --date '"'$REF47 days ago'"'`'
RETENTION_MySQL_FTP='`date +%d-%m-%Y --date '"'$REF58 days ago'"'`'
RETENTION_MySQL_FTPS='`date +%d-%m-%Y --date '"'$REF68 days ago'"'`'

}

#############################################################################
# Fonction Creation Script Sauvegarde Local
#############################################################################

creation_script_sauvegarde_local()
{

lecture_valeurs_base_donnees
lecture_valeurs_retentions


if [ "$nombre_bases_lister" = "1" ] ; then
echo "mkdir -p $REF30/MySQL/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

echo "rm -rf $REF30/MySQL/$RETENTION_MySQL_LOCAL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi


if [ "$nombre_bases_lister" = "2" ] ; then
echo "mkdir -p $REF30/MySQL/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

echo "rm -rf $REF30/MySQL/$RETENTION_MySQL_LOCAL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi


if [ "$nombre_bases_lister" = "3" ] ; then
echo "mkdir -p $REF30/MySQL/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > $REF30/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

echo "rm -rf $REF30/MySQL/$RETENTION_MySQL_LOCAL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi


if [ "$nombre_bases_lister" = "4" ] ; then
echo "mkdir -p $REF30/MySQL/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
echo "rm -f $REF30/MySQL/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $REF30/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $REF30/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > $REF30/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

if [ "$REF25" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases > $REF30/MySQL/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi

echo "rm -rf $REF30/MySQL/$RETENTION_MySQL_LOCAL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
fi


if [ "$nombre_bases_lister" -ge "5" ] ; then

echo "mkdir -p $REF30/MySQL/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

cat <<- EOF > $fichtemp
select base
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-bases.txt

sed -i '1d' /tmp/lecture-bases.txt

nombres_lignes=$(sed -n '$=' /tmp/lecture-bases.txt)


num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	echo "rm -f $REF30/MySQL/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

	num=`expr $num + 1`
	done

num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)

	if [ "$NOM_BASE" = "mysql" ] ; then	
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases --ignore-table=mysql.event > $REF30/MySQL/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
	else
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases > $REF30/MySQL/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL
	fi

	num=`expr $num + 1`
	done

echo "rm -rf $REF30/MySQL/$RETENTION_MySQL_LOCAL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

rm -f /tmp/lecture-bases.txt
rm -f $fichtemp

fi

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

}

#############################################################################
# Fonction Creation Script Sauvegarde Reseau
#############################################################################

creation_script_sauvegarde_reseau()
{

lecture_valeurs_base_donnees
lecture_valeurs_retentions


if [ "$nombre_bases_lister" = "1" ] ; then
echo "mkdir -p /mnt/sauvegarde-mysql" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if ! grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	mount -t $CLIENT_SMB -o username=$REF42,password=$REF43 //$REF40/$REF41 /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "mkdir -p /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

echo "rm -rf /mnt/sauvegarde-mysql/`uname -n`/MySQL/$RETENTION_MySQL_RESEAU" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	grep /mnt/sauvegarde-mysql /etc/mtab > /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	nombres_mount=\$(sed -n '\$=' /tmp/nombres-mount.txt)" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	num=1" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	while [ "\$num" -le \$nombres_mount ]" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU 
echo "		do" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		umount /mnt/sauvegarde-mysql -l" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		num=\`expr \$num + 1\`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	done" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -rf /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi


if [ "$nombre_bases_lister" = "2" ] ; then
echo "mkdir -p /mnt/sauvegarde-mysql" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if ! grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	mount -t $CLIENT_SMB -o username=$REF42,password=$REF43 //$REF40/$REF41 /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "mkdir -p /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

echo "rm -rf /mnt/sauvegarde-mysql/`uname -n`/MySQL/$RETENTION_MySQL_RESEAU" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	grep /mnt/sauvegarde-mysql /etc/mtab > /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	nombres_mount=\$(sed -n '\$=' /tmp/nombres-mount.txt)" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	num=1" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	while [ "\$num" -le \$nombres_mount ]" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU 
echo "		do" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		umount /mnt/sauvegarde-mysql -l" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		num=\`expr \$num + 1\`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	done" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -rf /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi


if [ "$nombre_bases_lister" = "3" ] ; then
echo "mkdir -p /mnt/sauvegarde-mysql" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if ! grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	mount -t $CLIENT_SMB -o username=$REF42,password=$REF43 //$REF40/$REF41 /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "mkdir -p /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

echo "rm -rf /mnt/sauvegarde-mysql/`uname -n`/MySQL/$RETENTION_MySQL_RESEAU" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	grep /mnt/sauvegarde-mysql /etc/mtab > /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	nombres_mount=\$(sed -n '\$=' /tmp/nombres-mount.txt)" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	num=1" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	while [ "\$num" -le \$nombres_mount ]" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU 
echo "		do" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		umount /mnt/sauvegarde-mysql -l" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		num=\`expr \$num + 1\`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	done" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -rf /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi


if [ "$nombre_bases_lister" = "4" ] ; then
echo "mkdir -p /mnt/sauvegarde-mysql" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if ! grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	mount -t $CLIENT_SMB -o username=$REF42,password=$REF43 //$REF40/$REF41 /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "mkdir -p /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

if [ "$REF25" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi

echo "rm -rf /mnt/sauvegarde-mysql/`uname -n`/MySQL/$RETENTION_MySQL_RESEAU" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	grep /mnt/sauvegarde-mysql /etc/mtab > /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	nombres_mount=\$(sed -n '\$=' /tmp/nombres-mount.txt)" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	num=1" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	while [ "\$num" -le \$nombres_mount ]" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU 
echo "		do" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		umount /mnt/sauvegarde-mysql -l" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		num=\`expr \$num + 1\`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	done" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -rf /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
fi


if [ "$nombre_bases_lister" -ge "5" ] ; then

echo "mkdir -p /mnt/sauvegarde-mysql" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if ! grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	mount -t $CLIENT_SMB -o username=$REF42,password=$REF43 //$REF40/$REF41 /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "mkdir -p /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

cat <<- EOF > $fichtemp
select base
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-bases.txt

sed -i '1d' /tmp/lecture-bases.txt

nombres_lignes=$(sed -n '$=' /tmp/lecture-bases.txt)


num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	echo "rm -f /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

	num=`expr $num + 1`
	done

num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	if [ "$NOM_BASE" = "mysql" ] ; then	
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases --ignore-table=mysql.event > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
	else
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases > /mnt/sauvegarde-mysql/`uname -n`/MySQL/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
	fi
	
	num=`expr $num + 1`
	done

echo "rm -rf /mnt/sauvegarde-mysql/`uname -n`/MySQL/$RETENTION_MySQL_RESEAU" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "if grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	grep /mnt/sauvegarde-mysql /etc/mtab > /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	nombres_mount=\$(sed -n '\$=' /tmp/nombres-mount.txt)" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	num=1" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	while [ "\$num" -le \$nombres_mount ]" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU 
echo "		do" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		umount /mnt/sauvegarde-mysql -l" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "		num=\`expr \$num + 1\`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "	done" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -f /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU
echo "rm -rf /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

rm -f /tmp/lecture-bases.txt
rm -f $fichtemp

fi

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

}

#############################################################################
# Fonction Creation Script Sauvegarde FTP
#############################################################################

creation_script_sauvegarde_ftp()
{

lecture_valeurs_base_donnees
lecture_valeurs_retentions


if [ "$nombre_bases_lister" = "1" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

echo "ftp -i -n -z nossl<<transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "open $REF50 $REF51" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "user $REF53 $REF54" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rmdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi


if [ "$nombre_bases_lister" = "2" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

echo "ftp -i -n -z nossl<<transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "open $REF50 $REF51" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "user $REF53 $REF54" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF23*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rmdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi


if [ "$nombre_bases_lister" = "3" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

echo "ftp -i -n -z nossl<<transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "open $REF50 $REF51" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "user $REF53 $REF54" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF23*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF24*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rmdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi


if [ "$nombre_bases_lister" = "4" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

if [ "$REF25" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases > $TMP/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi

echo "ftp -i -n -z nossl<<transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "open $REF50 $REF51" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "user $REF53 $REF54" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF23*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF24*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "put $REF25*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rmdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
fi


if [ "$nombre_bases_lister" -ge "5" ] ; then

echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

cat <<- EOF > $fichtemp
select base
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-bases.txt

sed -i '1d' /tmp/lecture-bases.txt

nombres_lignes=$(sed -n '$=' /tmp/lecture-bases.txt)


num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	if [ "$NOM_BASE" = "mysql" ] ; then	
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases --ignore-table=mysql.event > $TMP/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
	else
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases > $TMP/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
	fi

	num=`expr $num + 1`
	done

echo "ftp -i -n -z nossl<<transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "open $REF50 $REF51" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "user $REF53 $REF54" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP


num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	echo "put $NOM_BASE*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

	num=`expr $num + 1`
	done

echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rmdir $REF52/`uname -n`/MySQL/$RETENTION_MySQL_FTP" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "transfert-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

rm -f /tmp/lecture-bases.txt
rm -f $fichtemp

fi

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

}

#############################################################################
# Fonction Creation Script Sauvegarde FTPS
#############################################################################

creation_script_sauvegarde_ftps()
{

lecture_valeurs_base_donnees
lecture_valeurs_retentions


if [ "$nombre_bases_lister" = "1" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

echo "ftp-ssl -i -n -z ssl<<transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "open $REF60 $REF61" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "user $REF63 $REF64" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rmdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi


if [ "$nombre_bases_lister" = "2" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

echo "ftp-ssl -i -n -z ssl<<transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "open $REF60 $REF61" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "user $REF63 $REF64" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF23*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rmdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi


if [ "$nombre_bases_lister" = "3" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

echo "ftp-ssl -i -n -z ssl<<transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "open $REF60 $REF61" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "user $REF63 $REF64" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF23*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF24*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rmdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi


if [ "$nombre_bases_lister" = "4" ] ; then
echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

if [ "$REF22" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF22 --databases > $TMP/$DATE/$REF22-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

if [ "$REF23" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF23 --databases > $TMP/$DATE/$REF23-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

if [ "$REF24" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF24 --databases > $TMP/$DATE/$REF24-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

if [ "$REF25" = "mysql" ] ; then
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases --ignore-table=mysql.event > $TMP/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
else
	echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $REF25 --databases > $TMP/$DATE/$REF25-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi

echo "ftp-ssl -i -n -z ssl<<transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "open $REF60 $REF61" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "user $REF63 $REF64" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF22*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF23*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF24*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "put $REF25*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rmdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
fi


if [ "$nombre_bases_lister" -ge "5" ] ; then

echo "rm -rf $TMP/$DATE" > $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir -p $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

cat <<- EOF > $fichtemp
select base
from sauvegarde_bases
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-bases.txt

sed -i '1d' /tmp/lecture-bases.txt

nombres_lignes=$(sed -n '$=' /tmp/lecture-bases.txt)


num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	if [ "$NOM_BASE" = "mysql" ] ; then	
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases --ignore-table=mysql.event > $TMP/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
	else
		echo "mysqldump -h `uname -n` -u $REF20 -p$REF21 $NOM_BASE --databases > $TMP/$DATE/$NOM_BASE-$DATE_HEURE.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
	fi

	num=`expr $num + 1`
	done

echo "ftp-ssl -i -n -z ssl<<transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "open $REF60 $REF61" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "user $REF63 $REF64" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "lcd $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS


num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	NOM_BASE=$(sed -n "$num"p /tmp/lecture-bases.txt)
	
	echo "put $NOM_BASE*.sql" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

	num=`expr $num + 1`
	done

echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP
echo "rmdir $REF62/`uname -n`/MySQL/$RETENTION_MySQL_FTPS" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "transfert-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS
echo "rm -rf $TMP/$DATE" >> $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

rm -f /tmp/lecture-bases.txt
rm -f $fichtemp

fi

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

}

#############################################################################
# Fonction Creation Exécution Script Purge MySQL Local
#############################################################################

creation_execution_script_purge_local()
{


cat <<- EOF > $fichtemp
select retentions
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select purges
from sauvegarde_local
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-purges.txt

lecture_purges=$(sed '$!d' /tmp/lecture-purges.txt)
rm -f /tmp/lecture-purges.txt
rm -f $fichtemp


REF70=$lecture_retentions
REF71=$lecture_purges


if [ "$REF71" != "0" ] ; then
if [ "$REF70" -le "$REF71" ] ; then

REF71=`expr $REF71 + 1`

while [ "$REF70" != "$REF71" ] 
do
PURGE='`date +%d-%m-%Y --date '"'$REF70 days ago'"'`'
REF70=`expr $REF70 + 1`
if [ ! -f $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_LOCAL ] ; then
echo "rm -rf $REF30/MySQL/$PURGE" > $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_LOCAL
else
echo "rm -rf $REF30/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_LOCAL
fi
done

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_LOCAL

$REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_LOCAL
rm -f $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_LOCAL

fi
fi

}

#############################################################################
# Fonction Creation Exécution Script Purge MySQL Reseau
#############################################################################

creation_execution_script_purge_reseau()
{


cat <<- EOF > $fichtemp
select retentions
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select purges
from sauvegarde_reseau
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-purges.txt

lecture_purges=$(sed '$!d' /tmp/lecture-purges.txt)
rm -f /tmp/lecture-purges.txt
rm -f $fichtemp


REF72=$lecture_retentions
REF73=$lecture_purges


if [ "$REF73" != "0" ] ; then
if [ "$REF72" -le "$REF73" ] ; then

REF73=`expr $REF73 + 1`

echo "mkdir -p  /mnt/sauvegarde-mysql" > $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "if ! grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "	mount -t $CLIENT_SMB -o username=$REF42,password=$REF43 //$REF40/$REF41 /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU

while [ "$REF72" != "$REF73" ] 
do
PURGE='`date +%d-%m-%Y --date '"'$REF72 days ago'"'`'
REF72=`expr $REF72 + 1`
echo "rm -rf /mnt/sauvegarde-mysql/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
done

echo "if grep "/mnt/sauvegarde-mysql" /etc/mtab &>/dev/null ; then" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "	grep /mnt/sauvegarde-mysql /etc/mtab > /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "	nombres_mount=\$(sed -n '\$=' /tmp/nombres-mount.txt)" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "	num=1" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "	while [ "\$num" -le \$nombres_mount ]" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU 
echo "		do" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "		umount /mnt/sauvegarde-mysql -l" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "		num=\`expr \$num + 1\`" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "	done" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "rm -f /tmp/nombres-mount.txt" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "fi" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
echo "rm -rf /mnt/sauvegarde-mysql" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU

$REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU
rm -f $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_RESEAU

fi
fi

}

#############################################################################
# Fonction Creation Exécution Script Purge MySQL FTP
#############################################################################

creation_execution_script_purge_ftp()
{


cat <<- EOF > $fichtemp
select retentions
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select purges
from sauvegarde_ftp
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-purges.txt

lecture_purges=$(sed '$!d' /tmp/lecture-purges.txt)
rm -f /tmp/lecture-purges.txt
rm -f $fichtemp


REF74=$lecture_retentions
REF75=$lecture_purges


if [ "$REF75" != "0" ] ; then
if [ "$REF74" -le "$REF75" ] ; then

REF75=`expr $REF75 + 1`

echo "ftp -i -n -z nossl<<purge-ftp" > $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "open $REF50 $REF51" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "user $REF53 $REF54" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "mkdir $REF52" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "mkdir $REF52/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP

while [ "$REF74" != "$REF75" ] 
do
PURGE='`date +%d-%m-%Y --date '"'$REF74 days ago'"'`'
REF74=`expr $REF74 + 1`
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "mkdir $REF52/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "cd $REF52/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "rmdir $REF52/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
done

echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP
echo "purge-ftp" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP

$REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP &> /dev/null
rm -f $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTP

fi
fi

}

#############################################################################
# Fonction Creation Exécution Script Purge MySQL FTPS
#############################################################################

creation_execution_script_purge_ftps()
{


cat <<- EOF > $fichtemp
select retentions
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-retentions.txt

lecture_retentions=$(sed '$!d' /tmp/lecture-retentions.txt)
rm -f /tmp/lecture-retentions.txt
rm -f $fichtemp

cat <<- EOF > $fichtemp
select purges
from sauvegarde_ftps
where uname='`uname -n`' and application='mysql' ;
EOF

mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp >/tmp/lecture-purges.txt

lecture_purges=$(sed '$!d' /tmp/lecture-purges.txt)
rm -f /tmp/lecture-purges.txt
rm -f $fichtemp


REF75=$lecture_retentions
REF76=$lecture_purges


if [ "$REF76" != "0" ] ; then
if [ "$REF75" -le "$REF76" ] ; then

REF76=`expr $REF76 + 1`

echo "ftp-ssl -i -n -z ssl<<purge-ftps" > $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "open $REF60 $REF61" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "user $REF63 $REF64" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "mkdir $REF62" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "mkdir $REF62/`uname -n`" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS

while [ "$REF75" != "$REF76" ] 
do
PURGE='`date +%d-%m-%Y --date '"'$REF75 days ago'"'`'
REF75=`expr $REF75 + 1`
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "mkdir $REF62/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "cd $REF62/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "mdelete *.*" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "cd /" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "rmdir $REF62/`uname -n`/MySQL/$PURGE" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
done

echo "bye" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "quit" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS
echo "purge-ftps" >> $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS

chmod 0755 $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS

$REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS &> /dev/null
rm -f $REPERTOIRE_SCRIPTS/$FICHIER_PURGE_MySQL_FTPS

fi
fi

}

#############################################################################
# Fonction Creation Cron Sauvegarde MySQL
#############################################################################

creation_fichier_cron_sauvegarde()
{

lecture_valeurs_base_donnees


cat <<- EOF > $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
################### Fichier Cron Sauvegarde MySQL ###################

###### Sauvegarde MySQL Local ######


###### Sauvegarde MySQL Reseau ######


###### Sauvegarde MySQL FTP ######


###### Sauvegarde MySQL FTPS ######


################### Fichier Cron Sauvegarde MySQL ###################
EOF


if [ "$lecture_cron_local" = "oui" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL Local ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"$REF32 $REF31 * * $REF33 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_local" = "non" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL Local ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"#$REF32 $REF31 * * $REF33 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_reseau" = "oui" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL Reseau ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"$REF45 $REF44 * * $REF46 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_reseau" = "non" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL Reseau ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"#$REF45 $REF44 * * $REF46 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_ftp" = "oui" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL FTP ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"$REF56 $REF55 * * $REF57 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_ftp" = "non" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL FTP ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"#$REF56 $REF55 * * $REF57 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_ftps" = "oui" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL FTPS ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"$REF66 $REF65 * * $REF67 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

if [ "$lecture_cron_ftps" = "non" ] ; then
	ligne=$(sed -n '/###### Sauvegarde MySQL FTPS ######/=' $REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE)
	sed -i "`expr $ligne + 2`"i"#$REF66 $REF65 * * $REF67 root $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS" /$REPERTOIRE_CRON/$FICHIER_CRON_SAUVEGARDE
fi

/etc/init.d/cron restart &> /dev/null

}

#############################################################################
# Fonction Exécution Script Sauvegarde Local
#############################################################################

execution_script_sauvegarde_local()
{

$REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

}

#############################################################################
# Fonction Exécution Script Sauvegarde Reseau
#############################################################################

execution_script_sauvegarde_reseau()
{

$REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

}

#############################################################################
# Fonction Exécution Script Sauvegarde FTP
#############################################################################

execution_script_sauvegarde_ftp()
{

$REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

}

#############################################################################
# Fonction Exécution Script Sauvegarde FTPS
#############################################################################

execution_script_sauvegarde_ftps()
{

$REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

}

#############################################################################
# Fonction Suppression Script Sauvegarde Local
#############################################################################

suppression_script_sauvegarde_local()
{

rm -f $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_LOCAL

}

#############################################################################
# Fonction Suppression Script Sauvegarde Reseau
#############################################################################

suppression_script_sauvegarde_reseau()
{

rm -f $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_RESEAU

}

#############################################################################
# Fonction Suppression Script Sauvegarde FTP
#############################################################################

suppression_script_sauvegarde_ftp()
{

rm -f $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTP

}

#############################################################################
# Fonction Suppression Script Sauvegarde FTPS
#############################################################################

suppression_script_sauvegarde_ftps()
{

rm -f $REPERTOIRE_SCRIPTS/$FICHIER_SCRIPTS_MySQL_FTPS

}

#############################################################################
# Fonction Message d'erreur
#############################################################################

message_erreur()
{
	
cat <<- EOF > /tmp/erreur
Veuillez vous assurer que les parametres saisie
                sont correcte
EOF

erreur=`cat /tmp/erreur`

$DIALOG --ok-label "Quitter" \
	 --colors \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Erreur" \
	 --msgbox  "\Z1$erreur\Zn" 6 52 

rm -f /tmp/erreur

}

#############################################################################
# Fonction Message d'erreur Serveur CIFS
#############################################################################

message_erreur_serveur_cifs()
{
	
cat <<- EOF > /tmp/erreur     
Probleme de connexion avec le serveur de fichier 
  Veuillez verifier que les parametres saisies
 sont correcte et que le serveur soit joignable
EOF

erreur=`cat /tmp/erreur`

$DIALOG --ok-label "Quitter" \
	 --colors \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Erreur" \
	 --msgbox  "\Z1$erreur\Zn" 7 52 

rm -f /tmp/erreur

}

#############################################################################
# Fonction Message d'erreur Serveur FTP
#############################################################################

message_erreur_serveur_ftp()
{
	
cat <<- EOF > /tmp/erreur     
  Probleme de connexion avec le serveur ftp
 Veuillez verifier que les parametres saisies
sont correcte et que le serveur soit joignable
EOF

erreur=`cat /tmp/erreur`

$DIALOG --ok-label "Quitter" \
	 --colors \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Erreur" \
	 --msgbox  "\Z1$erreur\Zn" 7 52 

rm -f /tmp/erreur

}

#############################################################################
# Fonction Message d'erreur Serveur FTPS
#############################################################################

message_erreur_serveur_ftps()
{
	
cat <<- EOF > /tmp/erreur     
  Probleme de connexion avec le serveur ftps
 Veuillez verifier que les parametres saisies
sont correcte et que le serveur soit joignable
EOF

erreur=`cat /tmp/erreur`

$DIALOG --ok-label "Quitter" \
	 --colors \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Erreur" \
	 --msgbox  "\Z1$erreur\Zn" 7 52 

rm -f /tmp/erreur

}

#############################################################################
# Fonction Verification Couleur
#############################################################################

verification_couleur()
{


# 0=noir, 1=rouge, 2=vert, 3=jaune, 4=bleu, 5=magenta, 6=cyan 7=blanc

if ! grep -w "OUI" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE > /dev/null ; then
	choix1="\Z1Gestion Centraliser des Sauvegardes\Zn" 
else
	choix1="\Z2Gestion Centraliser des Sauvegardes\Zn" 
fi

if [ "$nombre_bases_lister" = "0" ] ; then
	choix2="\Z1Configuration Bases MySQL\Zn" 
else
	choix2="\Z2Configuration Bases MySQL\Zn" 
fi

if [ "$lecture_erreur_local" = "oui" ] ; then
	choix3="\ZB\Z1Configuration Sauvegarde Local\Zn" 

elif [ "$lecture_cron_local" = "non" ] ; then
	choix3="\Zb\Z3Configuration Sauvegarde Local\Zn" 

else
	choix3="\ZB\Z2Configuration Sauvegarde Local\Zn" 
fi

if [ "$lecture_erreur_reseau" = "oui" ] ; then
	choix4="\ZB\Z1Configuration Sauvegarde Reseau\Zn" 

elif [ "$lecture_cron_reseau" = "non" ] ; then
	choix4="\Zb\Z3Configuration Sauvegarde Reseau\Zn" 

else
	choix4="\ZB\Z2Configuration Sauvegarde Reseau\Zn" 
fi

if [ "$lecture_erreur_ftp" = "oui" ] ; then
	choix5="\ZB\Z1Configuration Sauvegarde FTP/FTPS\Zn" 

elif [ "$lecture_cron_ftp" = "non" ] ; then
	choix5="\Zb\Z3Configuration Sauvegarde FTP/FTPS\Zn" 

else
	choix5="\ZB\Z2Configuration Sauvegarde FTP/FTPS\Zn" 
fi

if [ "$lecture_erreur_ftp" = "oui" ] ; then
	choix6="\ZB\Z1Configuration Sauvegarde FTP\Zn" 

elif [ "$lecture_cron_ftp" = "non" ] ; then
	choix6="\Zb\Z3Configuration Sauvegarde FTP\Zn" 

else
	choix6="\ZB\Z2Configuration Sauvegarde FTP\Zn" 
fi

if [ "$lecture_erreur_ftps" = "oui" ] ; then
	choix7="\ZB\Z1Configuration Sauvegarde FTPS\Zn" 

elif [ "$lecture_cron_ftps" = "non" ] ; then
	choix7="\Zb\Z3Configuration Sauvegarde FTPS\Zn" 

else
	choix7="\ZB\Z2Configuration Sauvegarde FTPS\Zn" 
fi


}

#############################################################################
# Fonction Menu 
#############################################################################

menu()
{

lecture_config_centraliser_sauvegarde
creation_automatique_scripts_sauvegarde
verification_couleur

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde MySQL" \
	 --clear \
	 --colors \
	 --default-item "3" \
	 --menu "Quel est votre choix" 12 60 4 \
	 "1" "$choix1" \
	 "2" "Configuration Sauvegarde MySQL" \
	 "3" "Quitter" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Gestion Centraliser des Sauvegardes
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp
              menu_gestion_centraliser_sauvegardes
	fi

	# Configuration Sauvegarde MySQL
	if [ "$choix" = "2" ]
	then
		if [ "$VAR15" = "OUI" ] ; then
			rm -f $fichtemp
			menu_configuration_sauvegarde_mysql
		else
			rm -f $fichtemp
			message_erreur
			menu
		fi
	fi

	# Quitter
	if [ "$choix" = "3" ]
	then
		clear
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

exit
}

#############################################################################
# Fonction Menu Gestion Centraliser des Sauvegardes
#############################################################################

menu_gestion_centraliser_sauvegardes()
{

lecture_config_centraliser_sauvegarde

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --insecure \
	 --title "Gestion Centraliser des Sauvegardes" \
	 --mixedform "Quel est votre choix" 12 60 0 \
	 "Nom Serveur:"     1 1  "$REF10"  1 20  30 28 0  \
	 "Port Serveur:"    2 1  "$REF11"  2 20  30 28 0  \
	 "Base de Donnees:" 3 1  "$REF12"  3 20  30 28 0  \
	 "Compte Root:"     4 1  "$REF13"  4 20  30 28 0  \
	 "Password Root:"   5 1  "$REF14"  5 20  30 28 1  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Gestion Centraliser des Sauvegardes
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	

	sed -i "s/VAR10=$VAR10/VAR10=$VARSAISI10/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE
	sed -i "s/VAR11=$VAR11/VAR11=$VARSAISI11/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE
	sed -i "s/VAR12=$VAR12/VAR12=$VARSAISI12/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE
	sed -i "s/VAR13=$VAR13/VAR13=$VARSAISI13/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE
	sed -i "s/VAR14=$VAR14/VAR14=$VARSAISI14/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE

      
	cat <<- EOF > /tmp/databases.txt
	SHOW DATABASES;
	EOF

	mysql -h $VARSAISI10 -P $VARSAISI11 -u $VARSAISI13 -p$VARSAISI14 < /tmp/databases.txt &>/tmp/resultat.txt

	if grep -w "^$VARSAISI12" /tmp/resultat.txt > /dev/null ; then
	sed -i "s/VAR15=$VAR15/VAR15=OUI/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE

	else
	sed -i "s/VAR15=$VAR15/VAR15=NON/g" $REPERTOIRE_CONFIG/$FICHIER_CENTRALISATION_SAUVEGARDE
	message_erreur
	fi

	rm -f /tmp/databases.txt
	rm -f /tmp/resultat.txt
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu
}

#############################################################################
# Fonction Menu Configuration Sauvegarde MySQL
#############################################################################

menu_configuration_sauvegarde_mysql()
{

lecture_valeurs_base_donnees
verification_couleur

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde MySQL" \
	 --clear \
	 --colors \
	 --default-item "8" \
	 --menu "Quel est votre choix" 15 62 8 \
	 "1" "$choix2" \
	 "2" "$choix3" \
	 "3" "$choix4" \
	 "4" "$choix5" \
	 "5" "Execution Sauvegarde Local" \
	 "6" "Execution Sauvegarde Reseau" \
	 "7" "Execution Sauvegarde FTP/FTPS" \
	 "8" "\Z4Retour\Zn" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Configuration Bases MySQL
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp
		menu_configuration_bases_mysql
	fi

	# Configuration Sauvegarde Local
	if [ "$choix" = "2" ]
	then
		rm -f $fichtemp
		menu_configuration_sauvegarde_mysql_local
	fi

	# Configuration Sauvegarde Reseau
	if [ "$choix" = "3" ]
	then
		rm -f $fichtemp
		menu_configuration_sauvegarde_mysql_reseau
	fi

	# Configuration Sauvegarde FTP/FTPS
	if [ "$choix" = "4" ]
	then
		rm -f $fichtemp
		menu_configuration_sauvegarde_mysql_ftp_ftps
	fi

	# Execution Sauvegarde Local 
	if [ "$choix" = "5" ]
	then
		rm -f $fichtemp

		if [ "$lecture_erreur_local" = "oui" ]; then
			message_erreur
			menu_configuration_sauvegarde_mysql
		else
			creation_script_sauvegarde_local
			execution_script_sauvegarde_local
			menu_configuration_sauvegarde_mysql
		fi
	fi
	
	# Execution Sauvegarde Reseau 
	if [ "$choix" = "6" ]
	then
		rm -f $fichtemp

		if [ "$lecture_erreur_reseau" = "oui" ] ; then
			message_erreur
			menu_configuration_sauvegarde_mysql
		else
			creation_script_sauvegarde_reseau
			execution_script_sauvegarde_reseau
			menu_configuration_sauvegarde_mysql
		fi
	fi

	# Execution Sauvegarde FTP/FTPS 
	if [ "$choix" = "7" ]
	then
		rm -f $fichtemp
		menu_execution_sauvegarde_mysql_ftp_ftps
	fi

	# Retour
	if [ "$choix" = "8" ]
	then
		clear
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu
}

#############################################################################
# Fonction Menu Configuration Bases MySQL     
#############################################################################

menu_configuration_bases_mysql()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Bases MySQL" \
	 --clear \
	 --colors \
	 --default-item "$default_item" \
	 --menu "Quel est votre choix" 14 56 6 \
	 "1" "Sauvegarde Une Base de Donnees" \
	 "2" "Sauvegarde Deux Bases de Donnees" \
	 "3" "Sauvegarde Troix Bases de Donnees" \
	 "4" "Sauvegarde Quatre Bases de Donnees" \
	 "5" "Sauvegarde Plusieurs Bases de Donnees" \
      	 "6" "\Z4Retour\Zn" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Sauvegarde Une Base de Donnees
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp
		menu_sauvegarde_une_base
	fi

	# Sauvegarde Deux Bases de Donnees
	if [ "$choix" = "2" ]
	then
		rm -f $fichtemp
		menu_sauvegarde_deux_bases
	fi

	# Sauvegarde Trois Bases de Donnees
	if [ "$choix" = "3" ]
	then
		rm -f $fichtemp
		menu_sauvegarde_trois_bases
	fi

	# Sauvegarde Quatre Bases de Donnees 
	if [ "$choix" = "4" ]
	then
		rm -f $fichtemp
		menu_sauvegarde_quatre_bases
	fi

	# Sauvegarde Plusieurs Bases de Donnees
	if [ "$choix" = "5" ]
	then
		rm -f $fichtemp
		menu_sauvegarde_plusieurs_bases
	fi
	
	# Retour
	if [ "$choix" = "6" ]
	then
		clear
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Sauvegarde Une Base de Donnees
#############################################################################

menu_sauvegarde_une_base()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --insecure \
	 --title "Sauvegarde Une Base de Donnees" \
	 --mixedform "Quel est votre choix" 11 60 0 \
	 "Utilisateur de la Base:" 1 1  "$REF20"     1 25  28 26 0  \
	 "Password de la Base:"    2 1  "$REF21"     2 25  28 26 1  \
	 "Nom de la Base:"         3 1  "$REF22"     3 25  28 26 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Sauvegarde Une Base de Donnees
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)


	cat <<- EOF > $fichtemp
	update sauvegarde_local 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_reseau 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_ftp 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select distinct schema_name from information_schema.SCHEMATA;
	EOF

	mysql -h `uname -n` -u $VARSAISI10 -p$VARSAISI11 < $fichtemp >/tmp/resultat.txt 2>&1

	if ! grep -w "^$VARSAISI12" /tmp/resultat.txt > /dev/null ; then

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '0' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_fichier_cron_sauvegarde
	message_erreur

	else

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	delete from sauvegarde_bases
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	optimize table sauvegarde_bases ; 
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp > /dev/null

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI12' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table sauvegarde_bases order by application ;
	alter table sauvegarde_bases order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '1' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table information order by application ;
	alter table information order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	fi

	rm -f /tmp/resultat.txt
	suppression_script_sauvegarde_local
	suppression_script_sauvegarde_reseau
	suppression_script_sauvegarde_ftp
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Sauvegarde Deux Bases de Donnees
#############################################################################

menu_sauvegarde_deux_bases()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --insecure \
	 --title "Sauvegarde Deux Bases de Donnees" \
	 --mixedform "Quel est votre choix" 11 60 0 \
	 "Utilisateur de la Base:" 1 1  "$REF20"     1 25  28 26 0  \
	 "Password de la Base:"    2 1  "$REF21"     2 25  28 26 1  \
	 "Nom de la Base:"         3 1  "$REF22"     3 25  28 26 0  \
	 "Nom de la Base:"         4 1  "$REF23"     4 25  28 26 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Sauvegarde Deux Bases de Donnees
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)


	cat <<- EOF > $fichtemp
	update sauvegarde_local 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_reseau 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_ftp 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select distinct schema_name from information_schema.SCHEMATA;
	EOF

	mysql -h `uname -n` -u $VARSAISI10 -p$VARSAISI11 < $fichtemp >/tmp/resultat.txt 2>&1

	if ! grep -w "^$VARSAISI12" /tmp/resultat.txt > /dev/null ||
	   ! grep -w "^$VARSAISI13" /tmp/resultat.txt > /dev/null ; then

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '0' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_fichier_cron_sauvegarde
	message_erreur

	else
	
	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	delete from sauvegarde_bases
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	optimize table sauvegarde_bases ; 
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp > /dev/null

	rm -f $fichtemp
	
	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI12' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI13' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table sauvegarde_bases order by application ;
	alter table sauvegarde_bases order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '2' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table information order by application ;
	alter table information order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	fi

	rm -f /tmp/resultat.txt
	suppression_script_sauvegarde_local
	suppression_script_sauvegarde_reseau
	suppression_script_sauvegarde_ftp
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Sauvegarde Troix Bases de Donnees
#############################################################################

menu_sauvegarde_trois_bases()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --insecure \
	 --title "Sauvegarde Troix Bases de Donnees" \
	 --mixedform "Quel est votre choix" 12 60 0 \
	 "Utilisateur de la Base:" 1 1  "$REF20"     1 25  28 26 0  \
	 "Password de la Base:"    2 1  "$REF21"     2 25  28 26 1  \
	 "Nom de la Base:"         3 1  "$REF22"     3 25  28 26 0  \
	 "Nom de la Base:"         4 1  "$REF23"     4 25  28 26 0  \
	 "Nom de la Base:"         5 1  "$REF24"     5 25  28 26 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Sauvegarde Troix Bases de Donnees
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)


	cat <<- EOF > $fichtemp
	update sauvegarde_local 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_reseau 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_ftp 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select distinct schema_name from information_schema.SCHEMATA;
	EOF

	mysql -h `uname -n` -u $VARSAISI10 -p$VARSAISI11 < $fichtemp >/tmp/resultat.txt 2>&1

	if ! grep -w "^$VARSAISI12" /tmp/resultat.txt > /dev/null ||
	   ! grep -w "^$VARSAISI13" /tmp/resultat.txt > /dev/null ||
	   ! grep -w "^$VARSAISI14" /tmp/resultat.txt > /dev/null ; then

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '0' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_fichier_cron_sauvegarde
	message_erreur

	else

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	delete from sauvegarde_bases
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	optimize table sauvegarde_bases ; 
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp > /dev/null

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI12' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI13' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI14' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table sauvegarde_bases order by application ;
	alter table sauvegarde_bases order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '3' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table information order by application ;
	alter table information order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	fi

	rm -f /tmp/resultat.txt
	suppression_script_sauvegarde_local
	suppression_script_sauvegarde_reseau
	suppression_script_sauvegarde_ftp
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Sauvegarde Quatre Bases de Donnees
#############################################################################

menu_sauvegarde_quatre_bases()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --insecure \
	 --title "Sauvegarde Quatre Bases de Donnees" \
	 --mixedform "Quel est votre choix" 14 60 0 \
	 "Utilisateur de la Base:" 1 1  "$REF20"     1 25  28 26 0  \
	 "Password de la Base:"    2 1  "$REF21"     2 25  28 26 1  \
	 "Nom de la Base:"         3 1  "$REF22"     3 25  28 26 0  \
	 "Nom de la Base:"         4 1  "$REF23"     4 25  28 26 0  \
	 "Nom de la Base:"         5 1  "$REF24"     5 25  28 26 0  \
	 "Nom de la Base:"         6 1  "$REF25"     6 25  28 26 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Sauvegarde Quatre Bases de Donnees
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)


	cat <<- EOF > $fichtemp
	update sauvegarde_local 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_reseau 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_ftp 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select distinct schema_name from information_schema.SCHEMATA;
	EOF

	mysql -h `uname -n` -u $VARSAISI10 -p$VARSAISI11 < $fichtemp >/tmp/resultat.txt 2>&1

	if ! grep -w "^$VARSAISI12" /tmp/resultat.txt > /dev/null ||
	   ! grep -w "^$VARSAISI13" /tmp/resultat.txt > /dev/null ||
	   ! grep -w "^$VARSAISI14" /tmp/resultat.txt > /dev/null ||
	   ! grep -w "^$VARSAISI15" /tmp/resultat.txt > /dev/null ; then

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '0' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_local 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_fichier_cron_sauvegarde
	message_erreur

	else

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	delete from sauvegarde_bases
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	optimize table sauvegarde_bases ; 
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp > /dev/null

	rm -f $fichtemp
	
	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI12' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI13' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI14' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases ( uname, base, user, password, application )
	values ( '`uname -n`' , '$VARSAISI15' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table sauvegarde_bases order by application ;
	alter table sauvegarde_bases order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '4' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table information order by application ;
	alter table information order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	fi

	rm -f /tmp/resultat.txt
	suppression_script_sauvegarde_local
	suppression_script_sauvegarde_reseau
	suppression_script_sauvegarde_ftp
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Sauvegarde Plusieurs Bases de Donnees
#############################################################################

menu_sauvegarde_plusieurs_bases()
{

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --insecure \
	 --title "Sauvegarde Plusieurs Bases de Donnees" \
	 --mixedform "Quel est votre choix" 10 60 0 \
	 "Utilisateur de la Base:" 1 1  "root"  1 25  28 26 0  \
	 "Password de la Base:"    2 1  "password"  2 25  28 26 1  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Sauvegarde Plusieurs Bases de Donnees
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)


	cat <<- EOF > $fichtemp
	update sauvegarde_local 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_reseau 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	update sauvegarde_ftp 
	set cron_activer='non', erreur='oui' 
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select distinct schema_name from information_schema.SCHEMATA;
	EOF

	mysql -h `uname -n` -u $VARSAISI10 -p$VARSAISI11 < $fichtemp >/tmp/resultat.txt 2>&1

	if ! grep -w "^information_schema" /tmp/resultat.txt > /dev/null ; then

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '0' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_fichier_cron_sauvegarde
	message_erreur
	
	else

	cat <<- EOF > $fichtemp
	delete from information
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	delete from sauvegarde_bases
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	optimize table sauvegarde_bases ; 
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp > /dev/null

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	select distinct schema_name from information_schema.SCHEMATA;
	EOF

	mysql -h `uname -n` -u $VARSAISI10 -p$VARSAISI11 < $fichtemp >/tmp/bases.txt

	nombres_lignes=$(sed -n '$=' /tmp/bases.txt)


bases=0
num=1
while [ "$num" -le $nombres_lignes ] 
	do	
	ligne=$(sed -n "$num"p /tmp/bases.txt)
	if [ "$ligne" != "schema_name" ] && [ "$ligne" != "information_schema" ] && [ "$ligne" != "performance_schema" ] ; then
	
	cat <<- EOF > $fichtemp
	insert into sauvegarde_bases  ( uname, base, user, password, application )
	values ( '`uname -n`' , '$ligne' , '$VARSAISI10' , '$VARSAISI11' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp
	
	bases=`expr $bases + 1`
	fi
	num=`expr $num + 1`
	done

	rm -f /tmp/bases.txt

	cat <<- EOF > $fichtemp
	alter table sauvegarde_bases order by application ;
	alter table sauvegarde_bases order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	insert into information ( uname, nombre_bases, application )
	values ( '`uname -n`' , '$bases' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table information order by application ;
	alter table information order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	$DIALOG  --ok-label "Suivant" \
		  --colors \
		  --backtitle "Configuration Sauvegarde MySQL" \
		  --msgbox  "Le Nombre de Bases de Donnees est: $bases" 6 44

	fi

	rm -f /tmp/resultat.txt
	suppression_script_sauvegarde_local
	suppression_script_sauvegarde_reseau
	suppression_script_sauvegarde_ftp
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Configuration Sauvegarde MySQL Local
#############################################################################

menu_configuration_sauvegarde_mysql_local()
{

if [ "$nombre_bases_lister" = "0" ] ; then
	message_erreur
else

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --ok-label "Activation" \
	 --extra-button \
	 --extra-label "Desactivation" \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde Local" \
	 --form "Configuration Sauvegarde Local" 12 62 0 \
	 "Chemin Sauvegarde Local:"    1 1 "$REF30"  1 28 28 0  \
	 "Planification Des Heures:"   2 1 "$REF31"  2 28 28 0  \
	 "Planification Des Minutes:"  3 1 "$REF32"  3 28 3  0  \
	 "Planification Des Jours:"    4 1 "$REF33"  4 28 14 0  \
	 "Choix De La Retention:"      5 1 "$REF34"  5 28 4  0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Activation Sauvegarde Local
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$REF35

	
	cat <<- EOF > $fichtemp
	delete from sauvegarde_local
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp
	
	cat <<- EOF > $fichtemp
	insert into sauvegarde_local ( uname, chemin, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
	values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , 'oui' , 'non' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table sauvegarde_local order by application ;
	alter table sauvegarde_local order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_script_sauvegarde_local
	creation_fichier_cron_sauvegarde
	creation_execution_script_purge_local
	;;

 3)	# Désactivation Sauvegarde Local
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$REF35


	cat <<- EOF > $fichtemp
	delete from sauvegarde_local
	where uname='`uname -n`' and application='mysql' ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp
	
	cat <<- EOF > $fichtemp
	insert into sauvegarde_local ( uname, chemin, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
	values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , 'non' , 'non' , 'mysql' ) ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	cat <<- EOF > $fichtemp
	alter table sauvegarde_local order by application ;
	alter table sauvegarde_local order by uname ;
	EOF

	mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

	rm -f $fichtemp

	creation_script_sauvegarde_local
	creation_fichier_cron_sauvegarde
	creation_execution_script_purge_local
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

fi

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Configuration Sauvegarde MySQL Reseau
#############################################################################

menu_configuration_sauvegarde_mysql_reseau()
{

if [ "$nombre_bases_lister" = "0" ] ; then
	message_erreur
else

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --ok-label "Activation" \
	 --extra-button \
	 --extra-label "Desactivation" \
	 --insecure \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde Reseau" \
	 --mixedform "Configuration Sauvegarde Reseau" 15 62 0 \
	 "Serveur De Fichier:"         1 1 "$REF40"  1 28  28 28 0  \
	 "Nom Du Partage Reseau:"      2 1 "$REF41"  2 28  28 28 0  \
	 "Nom De L'Utilisateur:"       3 1 "$REF42"  3 28  28 28 0  \
	 "Saisie Du Password:"         4 1 "$REF43"  4 28  28 28 0  \
	 "Planification Des Heures:"   5 1 "$REF44"  5 28  28 28 0  \
	 "Planification Des Minutes:"  6 1 "$REF45"  6 28  03 03 0  \
	 "Planification Des Jours:"    7 1 "$REF46"  7 28  14 14 0  \
	 "Choix De La Retention:"      8 1 "$REF47"  8 28  04 04 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Activation Sauvegarde Reseau
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)
	VARSAISI16=$(sed -n 7p $fichtemp)
	VARSAISI17=$(sed -n 8p $fichtemp)
	VARSAISI18=$REF48


	ping -c 4 $VARSAISI10 >/dev/null 2>&1

	if [ $? -eq 0 ] ; then
	
		if ! grep "/mnt/verification-mount" /etc/mtab &>/dev/null ; then
			mkdir -p /mnt/verification-mount
			mount -t $CLIENT_SMB -o username=$VARSAISI12,password=$VARSAISI13 //$VARSAISI10/$VARSAISI11 /mnt/verification-mount &>/dev/null
		fi

		if grep "/mnt/verification-mount" /etc/mtab &>/dev/null ; then
			
			cat <<- EOF > $fichtemp
			delete from sauvegarde_reseau
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			insert into sauvegarde_reseau ( uname, serveur, partage, utilisateur, password, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
			values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , '$VARSAISI16' , '$VARSAISI17' , '$VARSAISI18' , 'oui' , 'non' , 'mysql' ) ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			cat <<- EOF > $fichtemp
			alter table sauvegarde_reseau order by application ;
			alter table sauvegarde_reseau order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			umount /mnt/verification-mount -l
			rm -rf /mnt/verification-mount

			creation_script_sauvegarde_reseau
			creation_fichier_cron_sauvegarde
			creation_execution_script_purge_reseau

		else

			cat <<- EOF > $fichtemp
			update sauvegarde_reseau 
			set cron_activer='non', erreur='oui' 
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			alter table sauvegarde_reseau order by application ;
			alter table sauvegarde_reseau order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			creation_fichier_cron_sauvegarde
    			message_erreur_serveur_cifs
			menu_configuration_sauvegarde_mysql
		fi

	else

		cat <<- EOF > $fichtemp
		update sauvegarde_reseau 
		set cron_activer='non', erreur='oui' 
		where uname='`uname -n`' and application='mysql' ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp
	
		cat <<- EOF > $fichtemp
		alter table sauvegarde_reseau order by application ;
		alter table sauvegarde_reseau order by uname ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		creation_fichier_cron_sauvegarde
		message_erreur_serveur_cifs
		menu_configuration_sauvegarde_mysql
	fi
	;;

 3)	# Désactivation Sauvegarde Reseau
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)
	VARSAISI16=$(sed -n 7p $fichtemp)
	VARSAISI17=$(sed -n 8p $fichtemp)
	VARSAISI18=$REF48


	ping -c 4 $VARSAISI10 >/dev/null 2>&1

	if [ $? -eq 0 ] ; then
	
		if ! grep "/mnt/verification-mount" /etc/mtab &>/dev/null ; then
			mkdir -p /mnt/verification-mount
			mount -t $CLIENT_SMB -o username=$VARSAISI12,password=$VARSAISI13 //$VARSAISI10/$VARSAISI11 /mnt/verification-mount &>/dev/null
		fi

		if grep "/mnt/verification-mount" /etc/mtab &>/dev/null ; then

			cat <<- EOF > $fichtemp
			delete from sauvegarde_reseau
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			insert into sauvegarde_reseau ( uname, serveur, partage, utilisateur, password, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
			values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , '$VARSAISI16' , '$VARSAISI17' , '$VARSAISI18' , 'non' , 'non' , 'mysql' ) ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			cat <<- EOF > $fichtemp
			alter table sauvegarde_reseau order by application ;
			alter table sauvegarde_reseau order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			umount /mnt/verification-mount -l
			rm -rf /mnt/verification-mount

			creation_script_sauvegarde_reseau
			creation_fichier_cron_sauvegarde
			creation_execution_script_purge_reseau

		else

			cat <<- EOF > $fichtemp
			update sauvegarde_reseau 
			set cron_activer='non', erreur='oui' 
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			alter table sauvegarde_reseau order by application ;
			alter table sauvegarde_reseau order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			creation_fichier_cron_sauvegarde
    			message_erreur_serveur_cifs
			menu_configuration_sauvegarde_mysql
		fi

	else

		cat <<- EOF > $fichtemp
		update sauvegarde_reseau 
		set cron_activer='non', erreur='oui' 
		where uname='`uname -n`' and application='mysql' ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp
	
		cat <<- EOF > $fichtemp
		alter table sauvegarde_reseau order by application ;
		alter table sauvegarde_reseau order by uname ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		creation_fichier_cron_sauvegarde
		message_erreur_serveur_cifs
		menu_configuration_sauvegarde_mysql
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

fi

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Configuration Sauvegarde MySQL FTP/FTPS
#############################################################################

menu_configuration_sauvegarde_mysql_ftp_ftps()
{

lecture_valeurs_base_donnees
verification_couleur

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde FTP/FTPS" \
	 --clear \
	 --colors \
	 --default-item "3" \
	 --menu "Quel est votre choix" 10 58 3 \
	 "1" "$choix6" \
	 "2" "$choix7" \
	 "3" "\Z4Retour\Zn" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Configuration Sauvegarde FTP
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp
		menu_configuration_sauvegarde_mysql_ftp
	fi

	# Configuration Sauvegarde FTPS
	if [ "$choix" = "2" ]
	then
		rm -f $fichtemp
		menu_configuration_sauvegarde_mysql_ftps
	fi

	# Retour
	if [ "$choix" = "3" ]
	then
		clear
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Exécution Sauvegarde MySQL FTP/FTPS
#############################################################################

menu_execution_sauvegarde_mysql_ftp_ftps()
{

lecture_valeurs_base_donnees

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Execution Sauvegarde FTP/FTPS" \
	 --clear \
	 --colors \
	 --default-item "3" \
	 --menu "Quel est votre choix" 10 44 3 \
	 "1" "Execution Sauvegarde FTP" \
	 "2" "Execution Sauvegarde FTPS" \
	 "3" "\Z4Retour\Zn" 2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Exécution Sauvegarde FTP
	if [ "$choix" = "1" ]
	then
		rm -f $fichtemp

		if [ "$lecture_erreur_ftp" = "oui" ] ; then
			message_erreur
			menu_execution_sauvegarde_mysql_ftp_ftps
		else
			creation_script_sauvegarde_ftp
			execution_script_sauvegarde_ftp
			menu_execution_sauvegarde_mysql_ftp_ftps
		fi
	fi

	# Exécution Sauvegarde FTPS
	if [ "$choix" = "2" ]
	then
		rm -f $fichtemp

		if [ "$lecture_erreur_ftps" = "oui" ] ; then
			message_erreur
			menu_execution_sauvegarde_mysql_ftp_ftps
		else
			creation_script_sauvegarde_ftps
			execution_script_sauvegarde_ftps
			menu_execution_sauvegarde_mysql_ftp_ftps
		fi
	fi

	# Retour
	if [ "$choix" = "3" ]
	then
		clear
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

menu_configuration_sauvegarde_mysql
}

#############################################################################
# Fonction Menu Configuration Sauvegarde MySQL FTP
#############################################################################

menu_configuration_sauvegarde_mysql_ftp()
{

if [ "$nombre_bases_lister" = "0" ] ; then
	message_erreur
else

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --ok-label "Activation" \
	 --extra-button \
	 --extra-label "Desactivation" \
	 --insecure \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde FTP" \
	 --mixedform "Configuration Sauvegarde FTP" 16 62 0 \
	 "Nom Du Serveur FTP:"         1 1 "$REF50"  1 28  28 28 0  \
	 "Numero Port FTP:"            2 1 "$REF51"  2 28  28 28 0  \
	 "Nom Du Dossier FTP:"         3 1 "$REF52"  3 28  28 28 0  \
	 "Nom De L'Utilisateur:"       4 1 "$REF53"  4 28  28 28 0  \
	 "Saisie Du Password:"         5 1 "$REF54"  5 28  28 28 0  \
	 "Planification Des Heures:"   6 1 "$REF55"  6 28  28 28 0  \
	 "Planification Des Minutes:"  7 1 "$REF56"  7 28  03 03 0  \
	 "Planification Des Jours:"    8 1 "$REF57"  8 28  14 14 0  \
	 "Choix De La Retention:"      9 1 "$REF58"  9 28  04 04 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Activation Sauvegarde FTP
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)
	VARSAISI16=$(sed -n 7p $fichtemp)
	VARSAISI17=$(sed -n 8p $fichtemp)
	VARSAISI18=$(sed -n 9p $fichtemp)
	VARSAISI19=$REF59


	cat <<- EOF > $fichtemp
	open $VARSAISI10 $VARSAISI11
	user $VARSAISI13 $VARSAISI14
	bye
	quit
	EOF

	ftp -i -n -z nossl< $fichtemp > verification-connexion-ftp.txt 2>&1

	verification_connexion_ftp=`cat verification-connexion-ftp.txt`

	rm -f verification-connexion-ftp.txt
	rm -f $fichtemp

	if [ -z "$verification_connexion_ftp" ] ; then

		cat <<- EOF > $fichtemp
		delete from sauvegarde_ftp
		where uname='`uname -n`' and application='mysql' ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp
	
		cat <<- EOF > $fichtemp
		insert into sauvegarde_ftp ( uname, serveur, port, dossier, utilisateur, password, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
		values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , '$VARSAISI16' , '$VARSAISI17' , '$VARSAISI18' , '$VARSAISI19' , 'oui' , 'non' , 'mysql' ) ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		cat <<- EOF > $fichtemp
		alter table sauvegarde_ftp order by application ;
		alter table sauvegarde_ftp order by uname ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		creation_script_sauvegarde_ftp
		creation_fichier_cron_sauvegarde
		creation_execution_script_purge_ftp 

	else
		
		cat <<- EOF > $fichtemp
		update sauvegarde_ftp 
		set cron_activer='non', erreur='oui' 
		where uname='`uname -n`' and application='mysql' ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp
	
		cat <<- EOF > $fichtemp
		alter table sauvegarde_ftp order by application ;
		alter table sauvegarde_ftp order by uname ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		creation_fichier_cron_sauvegarde
		message_erreur_serveur_ftp
		menu_configuration_sauvegarde_mysql_ftp_ftps
	fi
	;;

 3)	# Désactivation Sauvegarde FTP
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)
	VARSAISI16=$(sed -n 7p $fichtemp)
	VARSAISI17=$(sed -n 8p $fichtemp)
	VARSAISI18=$(sed -n 9p $fichtemp)
	VARSAISI19=$REF59


	cat <<- EOF > $fichtemp
	open $VARSAISI10 $VARSAISI11
	user $VARSAISI13 $VARSAISI14
	bye
	quit
	EOF

	ftp -i -n -z nossl< $fichtemp > verification-connexion-ftp.txt 2>&1

	verification_connexion_ftp=`cat verification-connexion-ftp.txt`

	rm -f verification-connexion-ftp.txt
	rm -f $fichtemp

	if [ -z "$verification_connexion_ftp" ] ; then

		cat <<- EOF > $fichtemp
		delete from sauvegarde_ftp
		where uname='`uname -n`' and application='mysql' ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp
	
		cat <<- EOF > $fichtemp
		insert into sauvegarde_ftp ( uname, serveur, port, dossier, utilisateur, password, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
		values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , '$VARSAISI16' , '$VARSAISI17' , '$VARSAISI18' , '$VARSAISI19' , 'non' , 'non' , 'mysql' ) ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		cat <<- EOF > $fichtemp
		alter table sauvegarde_ftp order by application ;
		alter table sauvegarde_ftp order by uname ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		creation_script_sauvegarde_ftp
		creation_fichier_cron_sauvegarde
		creation_execution_script_purge_ftp

	else
		
		cat <<- EOF > $fichtemp
		update sauvegarde_ftp 
		set cron_activer='non', erreur='oui' 
		where uname='`uname -n`' and application='mysql' ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp
	
		cat <<- EOF > $fichtemp
		alter table sauvegarde_ftp order by application ;
		alter table sauvegarde_ftp order by uname ;
		EOF

		mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

		rm -f $fichtemp

		creation_fichier_cron_sauvegarde
		message_erreur_serveur_ftp
		menu_configuration_sauvegarde_mysql_ftp_ftps
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

fi

menu_configuration_sauvegarde_mysql_ftp_ftps
}

#############################################################################
# Fonction Menu Configuration Sauvegarde MySQL FTPS
#############################################################################

menu_configuration_sauvegarde_mysql_ftps()
{

if [ "$nombre_bases_lister" = "0" ] ; then
	message_erreur
else

fichtemp=`tempfile 2>/dev/null` || fichtemp=/tmp/test$$


$DIALOG --ok-label "Activation" \
	 --extra-button \
	 --extra-label "Desactivation" \
	 --insecure \
	 --backtitle "Configuration Sauvegarde MySQL" \
	 --title "Configuration Sauvegarde FTPS" \
	 --mixedform "Configuration Sauvegarde FTPS" 16 62 0 \
	 "Nom Du Serveur FTPS:"        1 1 "$REF60"  1 28  28 28 0  \
	 "Numero Port FTPS:"           2 1 "$REF61"  2 28  28 28 0  \
	 "Nom Du Dossier FTPS:"        3 1 "$REF62"  3 28  28 28 0  \
	 "Nom De L'Utilisateur:"       4 1 "$REF63"  4 28  28 28 0  \
	 "Saisie Du Password:"         5 1 "$REF64"  5 28  28 28 0  \
	 "Planification Des Heures:"   6 1 "$REF65"  6 28  28 28 0  \
	 "Planification Des Minutes:"  7 1 "$REF66"  7 28  03 03 0  \
	 "Planification Des Jours:"    8 1 "$REF67"  8 28  14 14 0  \
	 "Choix De La Retention:"      9 1 "$REF68"  9 28  04 04 0  2> $fichtemp


valret=$?
choix=`cat $fichtemp`
case $valret in

 0)	# Activation Sauvegarde FTPS
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)
	VARSAISI16=$(sed -n 7p $fichtemp)
	VARSAISI17=$(sed -n 8p $fichtemp)
	VARSAISI18=$(sed -n 9p $fichtemp)
	VARSAISI19=$REF69


	ping -c 4 $VARSAISI10 >/dev/null 2>&1

	if [ $? -eq 0 ] ; then

		cat <<- EOF > $fichtemp
		open $VARSAISI10 $VARSAISI11
		user $VARSAISI13 $VARSAISI14
		bye
		quit
		EOF

		ftp-ssl -i -n -z ssl< $fichtemp > verification-connexion-ftps.txt 2>&1

		verification_connexion_ftps=$(sed -n '$=' verification-connexion-ftps.txt)

		rm -f verification-connexion-ftps.txt
		rm -f $fichtemp

		if [ "$verification_connexion_ftps" == "1" ] ; then

			cat <<- EOF > $fichtemp
			delete from sauvegarde_ftps
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			insert into sauvegarde_ftps ( uname, serveur, port, dossier, utilisateur, password, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
			values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , '$VARSAISI16' , '$VARSAISI17' , '$VARSAISI18' , '$VARSAISI19' , 'oui' , 'non' , 'mysql' ) ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			cat <<- EOF > $fichtemp
			alter table sauvegarde_ftps order by application ;
			alter table sauvegarde_ftps order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			creation_script_sauvegarde_ftps
			creation_fichier_cron_sauvegarde
			creation_execution_script_purge_ftps 

		else
		
			cat <<- EOF > $fichtemp
			update sauvegarde_ftps 
			set cron_activer='non', erreur='oui' 
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			alter table sauvegarde_ftps order by application ;
			alter table sauvegarde_ftps order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			creation_fichier_cron_sauvegarde
			message_erreur_serveur_ftps
			menu_configuration_sauvegarde_mysql_ftp_ftps
		fi

	else
		message_erreur_serveur_ftps
	fi
	;;

 3)	# Désactivation Sauvegarde FTPS
	VARSAISI10=$(sed -n 1p $fichtemp)
	VARSAISI11=$(sed -n 2p $fichtemp)
	VARSAISI12=$(sed -n 3p $fichtemp)
	VARSAISI13=$(sed -n 4p $fichtemp)
	VARSAISI14=$(sed -n 5p $fichtemp)
	VARSAISI15=$(sed -n 6p $fichtemp)
	VARSAISI16=$(sed -n 7p $fichtemp)
	VARSAISI17=$(sed -n 8p $fichtemp)
	VARSAISI18=$(sed -n 9p $fichtemp)
	VARSAISI19=$REF69


	ping -c 4 $VARSAISI10 >/dev/null 2>&1

	if [ $? -eq 0 ] ; then

		cat <<- EOF > $fichtemp
		open $VARSAISI10 $VARSAISI11
		user $VARSAISI13 $VARSAISI14
		bye
		quit
		EOF

		ftp-ssl -i -n -z ssl< $fichtemp > verification-connexion-ftps.txt 2>&1

		verification_connexion_ftps=$(sed -n '$=' verification-connexion-ftps.txt)

		rm -f verification-connexion-ftps.txt
		rm -f $fichtemp

		if [ "$verification_connexion_ftps" == "1" ] ; then

			cat <<- EOF > $fichtemp
			delete from sauvegarde_ftps
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			insert into sauvegarde_ftps ( uname, serveur, port, dossier, utilisateur, password, heures, minutes, jours, retentions, purges, cron_activer, erreur, application )
			values ( '`uname -n`' , '$VARSAISI10' , '$VARSAISI11' , '$VARSAISI12' , '$VARSAISI13' , '$VARSAISI14' , '$VARSAISI15' , '$VARSAISI16' , '$VARSAISI17' , '$VARSAISI18' , '$VARSAISI19' , 'non' , 'non' , 'mysql' ) ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			cat <<- EOF > $fichtemp
			alter table sauvegarde_ftps order by application ;
			alter table sauvegarde_ftps order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			creation_script_sauvegarde_ftps
			creation_fichier_cron_sauvegarde
			creation_execution_script_purge_ftps

		else
		
			cat <<- EOF > $fichtemp
			update sauvegarde_ftps 
			set cron_activer='non', erreur='oui' 
			where uname='`uname -n`' and application='mysql' ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp
	
			cat <<- EOF > $fichtemp
			alter table sauvegarde_ftps order by application ;
			alter table sauvegarde_ftps order by uname ;
			EOF

			mysql -h $VAR10 -P $VAR11 -u $VAR13 -p$VAR14 $VAR12 < $fichtemp

			rm -f $fichtemp

			creation_fichier_cron_sauvegarde
			message_erreur_serveur_ftps
			menu_configuration_sauvegarde_mysql_ftp_ftps
		fi

	else
		message_erreur_serveur_ftps
	fi
	;;

 1)	# Appuyé sur Touche CTRL C
	echo "Appuyé sur Touche CTRL C."
	;;

 255)	# Appuyé sur Touche Echap
	echo "Appuyé sur Touche Echap."
	;;

esac

rm -f $fichtemp

fi

menu_configuration_sauvegarde_mysql_ftp_ftps
}

#############################################################################
# Demarrage du programme
#############################################################################

menu