#!/bin/bash
me/apollonie/lycee/appli_ecombox/e-comBox_scriptsLinux/install_application.sh' 

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
	  echo -e "Peut-on poursuivre (o par défaut) ? (${COLCHOIX}o/n${COLTXT}) $COLSAISIE\c"
	  read REPONSE
          if [ -z "$REPONSE" ]; then
	     REPONSE="o"
	  fi
        done
        if [ "$REPONSE" != "o" -a "$REPONSE" != "O" ]; then
	   ERREUR "Abandon!"
	fi
}

#clear
echo -e "$COLTITRE"
echo "***************************************************"
echo "*     INSTALLATION DE E-COMBOX ET CONFIGURATION   *"
echo "*                DE SON ENVIRONNEMENT             *"
echo "***************************************************"

echo -e "$COLPARTIE"
echo ""
echo "Configuration de l'adresse IP"
echo ""

#Gestion des adresses IP
echo -e "$COLTXT"
echo -e "Saisissez l'adresse IP privée du serveur: $COLSAISIE\c"
read ADRESSE_IP_PRIVE

echo -e "$COLTXT"
echo -e " Si le serveur doit être accessible de l'extérieur, saisissez l'adresse IP publique ou un nom de domaine pleinement qualifié. C'est cette adresse IP ou ce nom de domaine qui apparaîtra au niveau de chaque site créé : $COLSAISIE\n"
echo -e "Laisser vide et validez si le serveur ne sera pas accessible de l'extérieur. L'application e-comBox utilisera l'adresse IP privée." 
read ADRESSE_IP_PUBLIQUE


#Gestion du proxy
echo -e "$COLTXT"
echo -e "Saisissez l'adresse du proxy : $COLSAISIE\n"
echo "Laisser vide et validez si pas de proxy sinon saisir ip-proxy:port"
read ADRESSE_PROXY


echo -e "$COLTXT"
echo -e "Saisissez les hôtes à ignorer par le proxy : $COLSAISIE\n"
echo "Laisser vide et validez si pas de proxy sinon saisir les hôtes à ignorer séparés par une virgule (dans ce cas \"localhost\" doit obligatoirement en faire partie et les caractères spéciaux comme \".\" ou \"*\" sont acceptés)"
read NO_PROXY

echo -e "$COLINFO"
echo "Vous vous apprêtez à utiliser les paramètres suivants:"
echo -e "IP privé :	$ADRESSE_IP_PRIVE"
echo -e "IP publique :	$ADRESSE_IP_PUBLIQUE"
echo -e "Proxy:		$ADRESSE_PROXY"
echo -e "No Proxy:	$NO_PROXY"
echo -e "$COLCMD"

POURSUIVRE

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

#Configuration éventuelle du proxy en ajoutant la variable d'environnement
if [ "$ADRESSE_PROXY" != "" ]; then
   if [ ! -d "/etc/systemd/system/docker.service.d" ]; then
	  mkdir /etc/systemd/system/docker.service.d
   fi
   echo -e "$COLDEFAUT"
   echo "Ajout des variables d'environnement à systemd (/etc/systemd/system/docker.service.d/http-proxy.conf)"
   echo -e "$COLCMD\c"
   echo "[Service]" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"HTTP_PROXY=http://$ADRESSE_PROXY" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"HTTPS_PROXY=http://$ADRESSE_PROXY" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo "Environment=\"NO_PROXY=http://$NO_PROXY" > /etc/systemd/system/docker.service.d/http-proxy.conf
   echo ""
   echo -e "Redémarrage de Docker"
   systemctl daemon-reload
   systemctl restart docker   
   else
	echo -e "$COLINFO"
	echo "Aucun proxy configuré sur le système"
	echo -e "$COLCMD"
fi

# Lancement de Portainer
echo -e "$COLDEFAUT"
echo "Lancement de portainer"
echo -e "$COLCMD\c"
cd /opt/e-comBox/e-comBox_portainer/
docker-compose up -d

echo -e "$COLINFO"
echo "Portainer est maintenant accessible à l'URL suivante :"
echo -e "http://$URL_UTILE:8880"
echo -e "$COLCMD\n"



# Configuration de l'application

# Lancement de e-comBox
echo -e "$COLPARTIE"
echo "Lancement et configuration de l'environnement de l'application e-comBox"
echo -e "$COLCMD\c"

if docker ps -a | grep e-combox; then
	docker rm -f e-combox
	docker volume rm $(docker volume ls -qf dangling=true)
fi
docker pull aporaf/e-combox:1.0
docker run -dit --name e-combox -v ecombox_data:/usr/local/apache2/htdocs/ --restart always -p 8888:80 aporaf/e-combox:1.0

# Nettoyage
docker rmi $(docker images -q -f dangling=true)

for fichier in /var/lib/docker/volumes/ecombox_data/_data/*.js /var/lib/docker/volumes/ecombox_data/_data/*.js.map
do
        sed -i -e "s/localhost:8880/$URL_UTILE:8880/g" $fichier
done


echo -e "$COLTITRE"
echo "***************************************************"
echo "*        FIN DE L'INSTALLATION DE E-COMBOX        *"
echo "***************************************************"

# Téléchargement du fichier contenant les identifiants d'accès

wget https://github.com/siollb/e-comBox_scriptsLinux/raw/master/e-comBox_identifiants_acces_applications.pdf -O /opt/e-comBox/e-comBox_identifiants_acces_applications.pdf

echo -e "$COLINFO"
echo "L'application e-comBox est maintenant accessible à l'URL suivante :"
echo -e "http://$URL_UTILE:8888"
echo -e ""
echo -e "Les identifiants d'accès figurent dans le fichier /opt/e-comBox/e-comBox_identifiants_acces_applications.pdf"
echo -e "$COLCMD"







