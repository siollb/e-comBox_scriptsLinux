#!/bin/bash

# Désinstallation de Docker et suppression de tous les conteneurs

apt-get purge docker-ce
rm -rf /var/lib/docker
rm -rf /opt/e-comBox_portainer
