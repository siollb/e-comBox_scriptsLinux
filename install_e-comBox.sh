#!/bin/bash

echo -e "\033[0;33m"
echo "************************************************************"
echo "*   SCRIPT PERMETTANT D'INSTALLER L'APPLICATION E-COMBOX   *"
echo "************************************************************"

echo -e "\033[1;37m"

apt update
apt install -y curl

# Téléchargement et lancement du script qui installe Docker et Docker-compose
curl -fsSL https://raw.githubusercontent.com/siollb/e-comBox_scriptsLinux/master/install_docker_docker-compose.sh -o install_docker_docker-compose.sh
bash install_docker_docker-compose.sh

# Téléchargement et lancement du script qui installe e-comBox
curl -fsSL https://raw.githubusercontent.com/siollb/e-comBox_scriptsLinux/master/configure_application.sh -o configure_application.sh
bash configure_application.sh
