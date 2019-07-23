#!/bin/bash

# Installation de Portainer
# Les fichiers incluant le docker-compose seront téléchargés dans /opt

# Couleurs
COLTITRE="\033[1;35m"   # Rose
COLPARTIE="\033[1;34m"  # Bleu

COLTXT="\033[0;37m"     # Gris
COLCHOIX="\033[1;33m"   # Jaune
COLDEFAUT="\033[0;33m"  # Brun-jaune
COLSAISIE="\033[1;32m"  # Vert

COLCMD="\033[1;37m"     # Blanc

COLERREUR="\033[1;31m"  # Rouge
COLINFO="\033[0;36m"    # Cyan


ERREUR()
{
        echo -e "$COLERREUR"
        echo "ERREUR! e-comBox n'est pas correctement configuré ou n'a finalement pas été reconfiguré"
        echo -e "$1"
        echo -e "$COLTXT"
        exit 1
}



POURSUIVRE()
{
        REPONSE=""
        while [ "$REPONSE" != "o" -a "$REPONSE" != "O" -a "$REPONSE" != "n" ]
        do
          echo -e "$COLTXT"
          echo -e "Peut-on poursuivre? (${COLCHOIX}o/n${COLTXT}) $COLSAISIE\c"
	  read REPONSE
          if [ -z "$REPONSE" ]; then
	     REPONSE="o"
	  fi
        done
        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
	   ERREUR "Abandon!"
	fi
}

clear
echo -e "$COLTITRE"
echo "***************************************************"
echo "*  SCRIPT PERMETTANT D'INSTALLER E-COMBOX ET DE   *"
echo "*           CONFIGURER SON ENVIRONNEMENT          *"
echo "***************************************************"

echo -e "$COLPARTIE"
echo ""
echo "Configuration de l'adresse IP"
echo ""

#Gestion des adresses IP
echo -e "$COLTXT"
echo -e "Saisissez l'adresse IP privé du serveur: $COLSAISIE\c"
read ADRESSE_IP_PRIVE

echo -e "$COLTXT"
echo -e " Si le serveur doit être accessible de l'extérieur, saisissez l'adresse IP publique: $COLSAISIE\c"
echo -e "Laissez vide si le serveur ne sera pas accessible de l'extérieur" 
read ADRESSE_IP_PUBLIQUE


#Gestion du proxy
echo -e "$COLTXT"
echo -e "Saisissez l'adresse du proxy : $COLSAISIE\c"
echo "Laisser vide si pas de proxy sinon saisir ip-proxy:port"
read ADRESSE_PROXY


echo -e "$COLTXT"
echo -e "Saisissez les hôtes à ignorer par le proxy : $COLSAISIE\c"
echo "Laisser vide si pas de proxy sinon saisir les hôtes séparés par une virgule (localhost doit obligatoirement en faire partie)"
read NO_PROXY

echo -e "$COLINFO"
echo "Vous vous apprêtez à utiliser les paramètres suivants:"
echo -e "IP privé :	$ADRESSE_IP_PRIVE"
echo -e "IP publique :	$ADRESSE_IP_PUBLIQUE"
echo -e "Proxy:		$ADRESSE_PROXY"
echo -e "No Proxy:	$NO_PROXY"

POURSUIVRE

#Récupération de portainer
echo -e "$COLPARTIE"
echo -e "Récupération et configuration de Portainer"
echo ""
if [ -d "/opt/e-comBox_portainer" ]; then
	echo -e "$COLTXT"
	echo "Portainer existe et va être remplacé"
	echo -e "$COLCMD\c"
        cd /opt/e-comBox_portainer
	docker-compose down
	rm -rf /opt/e-comBox_portainer
fi
cd /opt
git clone https://github.com/siollb/e-comBox_portainer.git

#Configuration de l'adresse IP
echo -e "$COLTXT"
echo "Mise à jour de /opt/e-comBox_portainer/.env"
if [ $ADRESSE_IP_PUBLIQUE != "" ] ; then
	URL_UTILE=$ADRESSE_IP_PUBLIQUE
	else
		URL_UTILE=$ADRESSE_IP_PRIVE
fi

echo -e "$COLCMD\c"
#echo "DOCKER_IP_LOCALHOST=127.0.0.1" > /opt/e-comBox_portainer/.env
#echo "DOCKER_IP_HOST=0.0.0.0" > /opt/e-comBox_portainer/.env
echo "URL_UTILE=$URL_UTILE" >> /opt/e-comBox_portainer/.env
echo ""

#Configuration éventuelle du proxy en ajoutant la variable d'environnement
if [ "$ADRESSE_PROXY" != "" ]; then
   if [ ! -d "/etc/systemd/system/docker.service.d" ]; then
	  mkdir /etc/systemd/system/docker.service.d
   fi
   echo -e "$COLTXT"
   echo "Ajout des variables d'environnement à systemd (/etc/systemd/system/docker.service.d/http-proxy.conf)"
   echo ""
   echo "[Service]" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"HTTP_PROXY=http://$ADRESSE_PROXY" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"HTTPS_PROXY=http://$ADRESSE_PROXY" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"NO_PROXY=http://$NO_PROXY" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo ""
   echo "Redémarrage de Docker"
   systemctl daemon-reload
   systemctl restart docker   
   else
	echo -e "$COLTXT"
	echo "Il n'y a pas de proxy configuré sur le système"
	echo ""
fi

# Lancement de Portainer
echo -e "$COLTXT"
echo "Lancement de portainer"
echo ""
cd /opt/e-comBox_portainer/
docker-compose up -d

echo -e "$COLINFO"
echo "Portainer est maintenant accessible à l'URL suivante:"
echo -e "http://$URL_UTILE:8880"
echo -e ""



# Configuration de l'application

# Lancement de e-comBox
echo -e "$COLPARTIE"
echo "Lancement et configuration de l'environnement de l'application e-comBox"
echo ""

if docker ps -a | grep e-combox; then
	docker rm -f e-combox
fi

docker run -dit --name e-combox -v ecombox_data:/usr/local/apache2/htdocs/ --restart always -p 8888:80 aporaf/e-combox:1.0

# Mise à jour de l'accès à l'API

#echo -e "$COLINFO"
#echo -e "Lapplication e-comBox sera accessible par défaut via l'adresse IP $ADRESSE_IP"
#echo -e "Veuillez confirmer cette adresse IP : $COLSAISIE\c"
#echo "Appuyer sur Entrée si vous confirmez ou saisissez la nouvelle adresse IP"
#read NEW_IP
#echo ""

#if [ "$NEW_IP" != "" ]; then
#	ADRESSE_IP=$NEW_IP
#fi

for fichier in /var/lib/docker/volumes/ecombox_data/_data/*.js /var/lib/docker/volumes/ecombox_data/_data/*.js.map
do
        sed -i -e "s/localhost:8880/$URL_UTILE:8880/g" $fichier
done

echo -e "$COLINFO"
echo "L'application e-comBox est maintenant accessible à l'URL suivante:"
echo -e "http://$URL_UTILE:8888"
echo -e ""

echo -e "$COLSAISIE"
echo "tapez sur Entrée pour terminer l'installation"
echo -e "$COLTXT"
read FIN





