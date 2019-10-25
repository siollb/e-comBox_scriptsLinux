#!/bin/bash

# Installation de Portainer
# Les fichiers incluant le docker-compose seront téléchargés dans /opt/e-comBox

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
        echo -e "ERREUR! Vous avez décidé de ne pas configurer e-comBox. Vous pouvez reprendre la procédure quand vous voulez"
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
	  echo -e "Peut-on poursuivre (o par défaut) ? (${COLCHOIX}o/n${COLTXT}) $COLSAISIE\c"
	  read REPONSE
          if [ -z "$REPONSE" ]; then
	     REPONSE="o"
	  fi
        done
        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
	   ERREUR
	fi
}

#clear
echo -e "$COLTITRE"
echo "***************************************************"
echo "*     INSTALLATION DE E-COMBOX ET CONFIGURATION   *"
echo "*                DE SON ENVIRONNEMENT             *"
echo "***************************************************"

echo -e "$COLINFO"
echo -e "Création d'un fichier de log : /var/log/ecombox.log"
echo -e "$COLCMD"
touch /var/log/ecombox.log


echo -e "$COLPARTIE"
echo -e "Configuration de l'adresse IP"

#Gestion des adresses IP
echo -e "$COLTXT"
echo -e "Saisissez l'adresse IP privée du serveur: $COLSAISIE\c"
read ADRESSE_IP_PRIVE

echo -e "$COLTXT"
echo -e "Si le serveur doit être accessible de l'extérieur, saisissez l'adresse IP publique ou un nom de domaine pleinement qualifié. C'est cette adresse IP ou ce nom de domaine qui apparaîtra au niveau de chaque site créé. $COLSAISIE\c"
echo -e "(Laisser vide et validez si le serveur ne sera pas accessible de l'extérieur. L'application e-comBox utilisera l'adresse IP privée) :" 
read ADRESSE_IP_PUBLIQUE


#Gestion du proxy
echo -e "$COLTXT"
echo -e "Saisissez l'adresse du proxy : $COLSAISIE\c"
echo -e "(Laisser vide et validez si pas de proxy sinon saisir ip-proxy:port) :"
read ADRESSE_PROXY


echo -e "$COLTXT"
echo -e "Saisissez les hôtes à ignorer par le proxy. $COLSAISIE\c"
echo -e "(Laisser vide et validez si pas de proxy sinon saisir les hôtes à ignorer séparés par une virgule (dans ce cas \"localhost\" doit obligatoirement en faire partie et les caractères spéciaux comme \".\" ou \"*\" sont acceptés) :"
read NO_PROXY

echo -e "$COLINFO"
echo -e "Vous vous apprêtez à utiliser les paramètres suivants:"
echo -e "IP privé :	$ADRESSE_IP_PRIVE"
echo -e "IP publique :	$ADRESSE_IP_PUBLIQUE"
echo -e "Proxy :	$ADRESSE_PROXY"
echo -e "No Proxy :	$NO_PROXY"
echo -e "$COLCMD"

POURSUIVRE

#Configuration du proxy pour GIT et pour Docker

if [ "$ADRESSE_PROXY" != "" ]; then
   echo -e "$COLDEFAUT"
   echo -e "Congiguration de GIT pour le proxy"
   echo -e "$COLCMD\c"
   git config --global http.proxy http://$ADRESSE_PROXY
   if [ ! -d "/etc/systemd/system/docker.service.d" ]; then
          mkdir /etc/systemd/system/docker.service.d
   fi
   echo -e "$COLDEFAUT"
   echo "Ajout des variables d'environnement à systemd (/etc/systemd/system/docker.service.d/http-proxy.conf)"
   echo -e "$COLCMD\c"
   echo "[Service]" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"HTTP_PROXY=http://$ADRESSE_PROXY\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"HTTPS_PROXY=http://$ADRESSE_PROXY\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"NO_PROXY=http://$NO_PROXY\"" >> /etc/systemd/system/docker.service.d/http-proxy.conf
   echo ""
   echo -e "Redémarrage de Docker"
   systemctl daemon-reload
   systemctl restart docker
   else
        echo -e "$COLINFO"
        echo "Aucun proxy configuré sur le système"
        echo -e "$COLCMD"
        git config --global --unset http.proxy
	if [ -f "/etc/systemd/system/docker.service.d/http-proxy.conf" ]; then
           rm -f /etc/systemd/system/docker.service.d/http-proxy.conf
           systemctl daemon-reload
           systemctl restart docker
        fi
fi


# Création du réseau pour l'application

echo -e "$COLPARTIE"
echo -e "Création ou modification du réseau pour e-comBox"
echo -e "$COLCMD"

if ( docker network ls | grep bridge_e-combox ); then
   NET_ECB=`docker network inspect --format='{{range .IPAM.Config}}{{.Subnet}}{{end}}' bridge_e-combox`
   echo -e "$COLINFO"
   echo -e "Le système constate que le réseau $NET_ECB est déjà créé"
   echo -e "Si vous désirez modifier les paramètres de ce réseau, les sites existants seront supprimés"
   echo -e ""
   echo -e "Voulez-vous modifier le réseau ? $COLSAISIE\c"
   echo -e "(tapez oui pour modifier le réseau et SUPPRIMER les sites ou sur n'importe quel autre touche pour continuer)."
   read CONFIRM_RESEAU
   if [ "$CONFIRM_RESEAU" = "oui" ]; then
      docker rm -f $(docker ps -aq)
      docker volume rm $(docker volume ls -qf dangling=true)
      docker network rm bridge_e-combox
      echo -e "$COLSAISIE\n"
      echo "Saisissez le nouveau réseau sous la forme edresseIP/CIDR."
      read NET_ECB
      echo ""
      echo "$COLCMD"
      docker network create --subnet $NET_ECB bridge_e-combox
      echo -e "$COLINFO"
      echo -e "Le nouveau réseau $NET_ECB a été créé."
      else echo -e "Vous avez décidé de ne pas modifier le réseau."
   fi
   else
	echo -e "$COLINFO"
        echo -e ""
        echo -e "Le réseau d'e-comBox sera défini par défaut à 192.168.97.0/24"
        echo -e "Voulez-vous changer ce paramétrage ? $COLSAISIE\c"
        echo -e "(tapez oui pour changer l'adresse IP du réseau créé par défaut ou sur n'importe quelle touche pour continuer sans changement)."
        read CONFIRM_RESEAU
        if [ "$CONFIRM_RESEAU" = "oui" ]; then
           echo -e "$COLSAISIE\n"
           echo "Saisissez l'adresse du réseau sous la forme adresseIP/CIDR."
           read NET_ECB
           echo -e ""
           echo -e "$COLCMD"
           docker network create --subnet $NET_ECB bridge_e-combox
           echo -e "$COLINFO"
           echo -e "Le réseau $NET_ECB a été créé."
           else
               NET_ECB=192.168.97.0/24
               echo -e ""
               echo -e "$COLCMD"
               docker network create --subnet $NET_ECB bridge_e-combox
               echo -e "$COLINFO"
               echo -e "Le réseau $NET_ECB a été créé."
       fi
 fi


# Portainer

#Récupération de portainer
echo -e "$COLPARTIE"
echo -e "Récupération et configuration de Portainer"
echo -e "$COLCMD"

if [ ! -d "/opt/e-comBox" ]; then
	mkdir /opt/e-comBox
fi

if [ -d "/opt/e-comBox/e-comBox_portainer" ]; then
	echo -e "$COLDEFAUT"
	echo "Portainer existe et va être remplacé"
	echo -e "$COLCMD\c"
        cd /opt/e-comBox/e-comBox_portainer
	docker-compose down
	rm -rf /opt/e-comBox/e-comBox_portainer
fi

cd /opt/e-comBox
git clone https://github.com/siollb/e-comBox_portainer.git

#Configuration de l'adresse IP
echo -e "$COLDEFAUT"
echo "Mise à jour de /opt/e-comBox/e-comBox_portainer/.env"
echo -e "$COLCMD"

if [ "$ADRESSE_IP_PUBLIQUE" != "" ] ; then
	URL_UTILE=$ADRESSE_IP_PUBLIQUE
	else URL_UTILE=$ADRESSE_IP_PRIVE
fi

echo -e "$COLCMD\c"
echo "URL_UTILE=$URL_UTILE" > /opt/e-comBox/e-comBox_portainer/.env
echo ""



# Lancement de Portainer
echo -e "$COLDEFAUT"
echo "Lancement de portainer"
echo -e "$COLCMD\c"
cd /opt/e-comBox/e-comBox_portainer/
docker-compose up --build -d

echo -e "$COLINFO"
echo "Portainer est maintenant accessible à l'URL suivante :"
echo -e "http://$URL_UTILE:8880"
echo -e "$COLCMD\n"



# Configuration de l'application

echo -e "$COLPARTIE"
echo -e "Suppression d'e-comBox si une version existe"
echo -e "$COLCMD"

if docker ps -a | grep e-combox; then
	docker rm -f e-combox
	docker volume rm $(docker volume ls -qf dangling=true)
fi


# Récupération d'une éventuelle nouvelle version d'e-comBox
echo -e "$COLPARTIE"
echo "Récupération d'e-combox"
echo -e "$COLCMD\c"
echo -e ""

docker pull aporaf/e-combox:1.0

# Lancement de e-comBox
echo -e "$COLPARTIE"
echo "Lancement et configuration de l'environnement de l'application e-comBox"
echo -e "$COLCMD\c"
echo -e ""
docker run -dit --name e-combox -v ecombox_data:/usr/local/apache2/htdocs/ --restart always -p 8888:80 --network bridge_e-combox aporaf/e-combox:1.0

# Nettoyage des anciennes images si elles existent
echo -e "$COLDEFAUT"
echo "Suppression éventuelle des images si elle ne sont associées à aucun site"
echo -e "$COLCMD\c"
echo -e ""

docker image rm -f $(docker images -q) 2>> /var/log/errorEcomBox.log

if [ `docker images -qf dangling=true` ]; then
 docker rmi $(docker images -qf dangling=true) 2>> /var/log/errorEcomBox.log
fi

# Configuration de l'API 
for fichier in /var/lib/docker/volumes/ecombox_data/_data/*.js /var/lib/docker/volumes/ecombox_data/_data/*.js.map
do
        sed -i -e "s/localhost:8880/$URL_UTILE:8880/g" $fichier
done

echo -e "$COLTITRE"
echo "***************************************************"
echo "*        FIN DE L'INSTALLATION DE E-COMBOX        *"
echo "***************************************************"

echo -e "$COLDEFAUT"
echo "Téléchargement du fichier contenant les identifiants d'accès et des scripts permettant de reconfigurer l'application si nécessaire"
echo -e "$COLCMD\c"

# Téléchargement du fichier contenant les identifiants d'accès
if [ "$ADRESSE_PROXY" != "" ]; then
   wget --proxy $ADRESSE_PROXY https://github.com/siollb/e-comBox_scriptsLinux/raw/master/e-comBox_identifiants_acces_applications.pdf -O /opt/e-comBox/e-comBox_identifiants_acces_applications.pdf
   wget --proxy $ADRESSE_PROXY https://github.com/siollb/e-comBox_scriptsLinux/raw/master/change_config_ip.sh -O /opt/e-comBox/change_config_ip.sh
   wget --proxy $ADRESSE_PROXY https://github.com/siollb/e-comBox_scriptsLinux/raw/master/configure_application.sh -O /opt/e-comBox/configure_application.sh
    else
       wget https://github.com/siollb/e-comBox_scriptsLinux/raw/master/e-comBox_identifiants_acces_applications.pdf -O /opt/e-comBox/e-comBox_identifiants_acces_applications.pdf
       wget https://github.com/siollb/e-comBox_scriptsLinux/raw/master/change_config_ip.sh -O /opt/e-comBox/change_config_ip.sh
       wget https://github.com/siollb/e-comBox_scriptsLinux/raw/master/configure_application.sh -O /opt/e-comBox/configure_application.sh
fi

echo -e "$COLINFO"
echo "L'application e-comBox est maintenant accessible à l'URL suivante :"
echo -e "http://$URL_UTILE:8888"
echo -e ""
echo -e "Les identifiants d'accès figurent dans le fichier /opt/e-comBox/e-comBox_identifiants_acces_applications.pdf"
echo -e "$COLCMD"







