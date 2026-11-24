# Portfolio de visualisation de données

Projet réalisé à l'issue du module Programmation Web pour la visualisation (BUT Sciences des Données, parcours VCOD, IUT de Besançon-Vesoul, antenne de Dôle).

## Auteure

Francisca Wetimane, étudiante en 3e année de BUT Sciences des Données, parcours VCOD (Visualisation, Conception d'Outils Décisionnels), en alternance. Je travaille en français, en portugais et en anglais.

## Sujet et objectif

Ce projet est un site web qui met en valeur mes compétences en science des données et en visualisation, pour de futurs employeurs ou de futures formations. Il présente mon parcours, mes projets et mes compétences, et utilise des visualisations de données interactives pour rendre ces informations explorables plutôt que simplement lisibles.

## Données utilisées et origine

Les données affichées proviennent de mon propre parcours : liste de projets réalisés, technologies utilisées, niveaux de compétence, dates et durées des expériences. Elles seront croisées avec le référentiel national du BUT Science des Données (compétences, niveaux, composantes essentielles et apprentissages critiques du parcours VCOD, 2e et 3e années), afin de relier chaque projet du portfolio aux apprentissages critiques qu'il démontre. Elles seront stockées dans une base de données PostgreSQL, que le site interrogera pour alimenter les pages et les visualisations. Un premier schéma relationnel est disponible dans `maquette/schema-relationnel.png` ; la description complète des données sera ajoutée ici une fois le choix final arrêté.

Un premier brouillon de la liste des projets est disponible dans `data/projets.csv`, et un brouillon des technologies utilisées dans `data/competences.csv` (sans niveau de maîtrise pour l'instant). Les colonnes de ces deux fichiers sont décrites dans `data/README.md`. Les projets réalisés pour une entreprise ou sous accord de confidentialité n'y figurent pas sans accord écrit.

## Principales fonctionnalités prévues

- Page d'accueil de présentation avec accès rapide aux autres sections
- Frise chronologique du parcours (formation, stage, projets)
- Galerie de projets avec filtres par technologie et par type de projet
- Visualisation des compétences avec choix du critère d'affichage
- Page de contact

## Technologies et bibliothèques

À confirmer au fil des séances (architecture et partie serveur au TD2 et TD3). Pour l'instant :

- HTML et CSS pour la structure et la mise en page
- JavaScript pour les interactions
- PostgreSQL pour la base de données
- Node.js avec Express pour le serveur (routes de l'API)
- Chart.js pour les graphiques
- Docker pour lancer la base PostgreSQL dans un conteneur
- Git et GitHub pour le suivi du projet

## Exécution du projet

Prérequis : Docker Desktop et Node.js (version 20.6 ou plus récente).

1. Créer un fichier `.env` à la racine du dépôt, en copiant `.env.example`, et y choisir un mot de passe. Ce fichier n'est jamais envoyé sur GitHub.
2. Lancer la base de données, depuis la racine du dépôt :
   ```
   docker compose up -d
   ```
3. Installer les dépendances puis lancer le serveur :
   ```
   cd serveur
   npm install
   npm start
   ```
4. Ouvrir `http://localhost:3000` dans le navigateur.

Pour arrêter la base : `docker compose down` (les données sont conservées dans un volume Docker).

À chaque démarrage, le serveur recrée les tables à partir de `bdd/init_db.sql` : les données à garder doivent donc être écrites dans ce fichier.

## Organisation du dépôt

- `client/` : le site vu dans le navigateur (`index.html`, `style.css`, `script.js`, images des preuves dans `preuves/`)
- `serveur/` : le serveur Express (`server.js`) et la liste de ses dépendances (`package.json`)
- `bdd/` : le script SQL qui crée et remplit la base (`init_db.sql`)
- `docker-compose.yml` : la base PostgreSQL lancée dans un conteneur Docker
- `.env.example` : modèle du fichier `.env` qui contient le mot de passe de la base
- `README.md` : présentation du projet
- `AVANCEMENT.md` : planning prévisionnel et suivi de l'avancement
- `maquette/` : maquette du site et son évolution
- `maquette/schema-relationnel.png` : schéma relationnel reliant le référentiel national BUT SD (parcours VCOD) aux données du portfolio
- `data/` : données du portfolio (brouillon : `projets.csv`, `competences.csv`) et description des colonnes

## Difficultés et limites connues

Aucune à ce stade. Cette section sera mise à jour au fur et à mesure du projet.
