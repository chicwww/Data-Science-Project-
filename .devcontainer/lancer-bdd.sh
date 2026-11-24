#!/bin/bash
# Exécuté à chaque démarrage du Codespace : lance la base PostgreSQL dans Docker.

# Attendre que Docker soit prêt (il démarre en même temps que le Codespace).
for i in $(seq 1 30); do
  docker info > /dev/null 2>&1 && break
  sleep 2
done

docker compose up -d
