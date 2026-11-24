#!/bin/bash
# Exécuté une seule fois, à la création du Codespace.

# 1. Créer le fichier .env avec un mot de passe aléatoire s'il n'existe pas.
#    Ce fichier reste dans le Codespace : il est ignoré par Git (.gitignore).
if [ ! -f .env ]; then
  echo "POSTGRES_PASSWORD=$(openssl rand -hex 12)" > .env
  echo "Fichier .env créé."
fi

# 2. Installer les dépendances du serveur (express, pg).
cd serveur && npm install
