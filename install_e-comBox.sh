#!/bin/bash

echo -e "\033[0;33m"
echo "************************************************************"
echo "*   SCRIPT PERMETTANT D'INSTALLER L'APPLICATION E-COMBOX   *"
echo "************************************************************"

echo -e "\033[1;37m"

apt update
apt install -y curl

# Téléchargement et lancement du script qui installe Docker et Docker-compose
curl -fsSL https://github.com/siollb/ -o install_docker_docker-compose.sh
bash install_docker_docker-compose.sh

# Téléchargement et lancement du script qui installe e-comBox
curl -fsSL https://github.com/siollb/ -o install_application.sh
bash install_application.sh
