# Données du portfolio

Ce dossier contient les données qui alimenteront les pages et les visualisations du site. Elles seront ensuite chargées dans la base PostgreSQL décrite dans le schéma relationnel (`maquette/schema-relationnel.png`).

## Fichiers

| Fichier | Contenu | État |
|---|---|---|
| `projets.csv` | Projets présentés dans la galerie et dans les visualisations | Premier brouillon |
| `competences.csv` | Technologies utilisées, comptées à partir de `projets.csv` | Premier brouillon |

## Description des colonnes de `projets.csv`

| Colonne | Type | Description |
|---|---|---|
| `id` | entier | Identifiant du projet (clé primaire de l'entité Projet) |
| `titre` | texte | Titre affiché sur la carte du projet |
| `type` | texte | Stage, projet de formation ou projet personnel (filtre « Type ») |
| `technologies` | texte | Technologies séparées par des points-virgules (filtre « Technologie ») |
| `annee` | entier | Année de réalisation (filtre « Année »), vide quand elle reste à confirmer |
| `statut` | texte | `A valider` tant que le contenu n'a pas été relu |

## Description des colonnes de `competences.csv`

| Colonne | Type | Description |
|---|---|---|
| `technologie` | texte | Technologie citée dans au moins un projet de `projets.csv` |
| `nombre_projets` | entier | Nombre de projets qui l'utilisent |
| `ids_projets` | texte | Identifiants des projets concernés, séparés par des points-virgules |
| `statut` | texte | `A valider` tant que le contenu n'a pas été relu |

Le niveau de maîtrise n'est pas encore renseigné : il sera ajouté seulement une fois évalué.

## Règles

- Seuls des projets dont la publication est possible figurent ici. Les projets réalisés pour une entreprise ou sous accord de confidentialité ne sont pas ajoutés sans accord écrit.
- Les années vides sont à compléter avant l'intégration dans la base.
- Les données restent un brouillon : chaque ligne doit être relue avant d'être affichée sur le site.

## Prochaines étapes

- Compléter les années et relire chaque ligne
- Ajouter le fichier `parcours.csv` et les niveaux de maîtrise dans `competences.csv`
- Relier chaque projet aux apprentissages critiques du référentiel BUT SD
