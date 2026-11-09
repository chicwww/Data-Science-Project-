# Données du portfolio

Ce dossier contient les données qui alimenteront les pages et les visualisations du site. Elles seront ensuite chargées dans la base PostgreSQL décrite dans le schéma relationnel (`maquette/schema-relationnel.png`).

## Fichiers

| Fichier | Contenu | État |
|---|---|---|
| `projets.csv` | Projets présentés dans la galerie et dans les visualisations | Premier brouillon |

## Description des colonnes de `projets.csv`

| Colonne | Type | Description |
|---|---|---|
| `id` | entier | Identifiant du projet (clé primaire de l'entité Projet) |
| `titre` | texte | Titre affiché sur la carte du projet |
| `type` | texte | Stage, projet de formation ou projet personnel (filtre « Type ») |
| `technologies` | texte | Technologies séparées par des points-virgules (filtre « Technologie ») |
| `annee` | entier | Année de réalisation (filtre « Année »), vide quand elle reste à confirmer |
| `statut` | texte | `A valider` tant que le contenu n'a pas été relu |

## Règles

- Seuls des projets dont la publication est possible figurent ici. Les projets réalisés pour une entreprise ou sous accord de confidentialité ne sont pas ajoutés sans accord écrit.
- Les années vides sont à compléter avant l'intégration dans la base.
- Les données restent un brouillon : chaque ligne doit être relue avant d'être affichée sur le site.

## Prochaines étapes

- Compléter les années et relire chaque ligne
- Ajouter les fichiers `competences.csv` et `parcours.csv`
- Relier chaque projet aux apprentissages critiques du référentiel BUT SD
