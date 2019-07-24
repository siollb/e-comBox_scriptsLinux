#!/bin/sh
# Ce script lance des scripts qui automatise l'installation de Docker et Docker-Compose

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

clear
echo -e "$COLTITRE"
echo "************************************************************"
echo "*         INSTALLATION DE DOCKER ET DOCKER-COMPOSE         *"
echo "************************************************************"



# Installation de Docker
# Utilisation du script officiel fourni par Docker 
# https://github.com/docker/docker-install pour Docker

echo -e ""
echo -e "$COLPARTIE"
echo -e "Installation de Docker"
echo -e ""

echo -e "$COLCMD"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Installation de Docker Compose
echo -e ""
echo -e "$COLPARTIE"
echo -e "Installation de Docker-Compose"
echo -e ""

echo -e "$COLCMD"

# Installation des dépendances
apt install -y python-backports.ssl-match-hostname python-cached-property python-docker python-dockerpty python-docopt python-functools32 python-jsonschema python-texttable python-websocket python-yaml git

# Téléchargement de la dernière version du docker-compose

# Récupération de la dernière version dans une variable :
COMPOSE_VERSION=`git ls-remote https://github.com/docker/compose | grep refs/tags | grep -oP "[0-9]+\.[0-9][0-9]+\.[0-9]+$" | tail -n 1`

# Installation de la dernière version
curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

echo -e ""
echo -e "$COLINFO"
echo -e "Docker et Docker-Compose sont installés"
echo -e "Le script va maintenant procéder à l'installation de e-comBox"
echo -e ""

echo -e "$COLCMD"


