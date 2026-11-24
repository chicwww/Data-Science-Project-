-- ============================================================
-- BASE DU PORTFOLIO DE FRANCISCA WETIMANE
-- 1re partie : le référentiel du BUT Sciences des Données (base fournie en cours)
-- 2e partie  : mon parcours (formations, expériences, projets, certificats, preuves)
-- Le serveur relance ce fichier à chaque démarrage : toute donnée à garder s'écrit ici.
-- ============================================================

DROP VIEW IF EXISTS HEURES_PAR_ANNEE CASCADE;
DROP TABLE IF EXISTS PREUVE CASCADE;
DROP TABLE IF EXISTS PROJET_TECHNOLOGIE CASCADE;
DROP TABLE IF EXISTS TECHNOLOGIE CASCADE;
DROP TABLE IF EXISTS PROJET CASCADE;
DROP TABLE IF EXISTS EXPERIENCE CASCADE;
DROP TABLE IF EXISTS CERTIFICAT CASCADE;
DROP TABLE IF EXISTS FORMATION CASCADE;
DROP TABLE IF EXISTS LANGUE CASCADE;
DROP TABLE IF EXISTS ACTIVITE_PEDAGOGIQUE CASCADE;
DROP TABLE IF EXISTS APPRENTISSAGE_CRITIQUE CASCADE;
DROP TABLE IF EXISTS COMPETENCE CASCADE;
DROP TABLE IF EXISTS ANNEE CASCADE;

-- ============================================================
-- TABLE DES COMPÉTENCES DU BUT SCIENCES DES DONNÉES
-- ============================================================
CREATE TABLE IF NOT EXISTS COMPETENCE (
    id_competence CHAR(2) PRIMARY KEY,  -- C1 à C4
    intitule TEXT NOT NULL,
    description TEXT NOT NULL,
    preuve TEXT
);

INSERT INTO COMPETENCE (id_competence, intitule, description, preuve) VALUES
('C1', 'Traiter des données à des fins décisionnelles', $$
En intervenant à toutes les étapes du cycle de vie de la donnée (insertion, modification, extraction, suppression)
En utilisant le modèle de données adapté aux besoins
En s’inscrivant dans une démarche de documentation des réalisations adaptée au public visé
En traduisant correctement les demandes métier en programmes, avec le respect du cahier des charges s'il existe
En écrivant un programme correctement structuré et documenté, respectant les bonnes pratiques
En identifiant les librairies et langages dédiés
$$, 'test1.jpg'),
('C2', 'Analyser statistiquement les données', $$
En tenant compte du contexte de l’étude (économique, socio-démographique, commerciale, clinique...)
En mettant en évidence les grandes tendances et les informations principales
En identifiant et en mettant en œuvre les techniques adaptées aux attentes du client ou de l’instance décisionnaire
En identifiant et en mettant en œuvre les techniques adaptées aux données complexes (données massives, données mal structurées, flux de données…)
En tenant compte du contexte inférentiel (variabilité de l’échantillon)
$$, 'test2.jpg'),
('C3', 'Valoriser une production dans un contexte professionnel', $$
En s’adaptant au niveau d’expertise, à la culture et au statut du destinataire
En s’exprimant correctement, aussi bien en français qu’en anglais, à l'oral comme à l'écrit
En veillant aux aspects éthiques, déontologiques et réglementaires d’utilisation et de diffusion des données
En interprétant et contextualisant les résultats (citations, vérification des sources, esprit critique)
En utilisant la forme de restitution adaptée
En tenant compte des réalités économiques et managériales des entreprises
$$, 'test3.jpg'),
('C4', 'Développer un outil décisionnel', $$
En mettant en œuvre une structuration des données adaptée à leurs caractéristiques (type, volume...)
En assurant la qualité des données et minimisant les biais liés à l’incertitude et l’imprécision dans les sources
En étant sensible aux aspects éthiques, déontologiques et juridiques d’utilisation et de diffusion des données
En réalisant des solutions de visualisation spécifiques aux données métier
En intervenant à différents niveaux de la chaîne décisionnelle
En utilisant des méthodes de développement logiciel
$$, 'test.png')
ON CONFLICT DO NOTHING;


-- ============================================================
-- TABLE DES ANNÉES
-- ============================================================
CREATE TABLE IF NOT EXISTS ANNEE (
    id_annee CHAR(4) PRIMARY KEY,  -- ex: BUT1, BUT2, BUT3
    intitule TEXT NOT NULL
);

INSERT INTO ANNEE (id_annee, intitule) VALUES
('BUT1', 'Traiter des données structurées / Mettre en œuvre une analyse descriptive / Contextualiser et présenter les données'),
('BUT2', 'Automatiser le traitement de données multidimensionnelles / Mettre en œuvre une analyse exploratoire / Restituer et argumenter ses résultats / Développer un composant d’une solution décisionnelle'),
('BUT3', 'Intégrer le traitement de données complexes / Mettre en œuvre l''analyse exploratoire de données complexes / Intégrer et valoriser sa production dans l''écosystème de l''entreprise / Participer au déploiement d''une solution décisionnelle')
ON CONFLICT DO NOTHING;

-- ============================================================
-- TABLE DES ACTIVITÉS PÉDAGOGIQUES
-- ============================================================
CREATE TABLE IF NOT EXISTS ACTIVITE_PEDAGOGIQUE (
    num SERIAL PRIMARY KEY,             -- numéro créé automatiquement
    semestre INT NOT NULL CHECK (semestre BETWEEN 1 AND 6),   -- NOUVEAU : 6 semestres seulement
    heure INT NOT NULL CHECK (heure > 0),                      -- NOUVEAU : pas d'heures nulles ou négatives
    skill TEXT NOT NULL,
    id_competence CHAR(2) NOT NULL,
    id_annee CHAR(4),                   -- NOUVEAU : année du BUT (déduite du semestre)
    FOREIGN KEY (id_competence) REFERENCES COMPETENCE(id_competence),
    FOREIGN KEY (id_annee) REFERENCES ANNEE(id_annee)
);

-- Les 254 vraies matières des 3 années (reprises de init_dbVersionComplete.sql)
INSERT INTO ACTIVITE_PEDAGOGIQUE (semestre, heure, skill, id_competence) VALUES
-- SEMESTRE 1
(1, 15, 'Etude données envt ent & éco (intro marketing)', 'C3'),
(1, 22, 'Base de données relationnelles 1', 'C1'),
(1, 40, 'Statistique descriptive 1', 'C2'),
(1, 19, 'Bases de la programmation 2', 'C4'),
(1, 4, 's1 Analyse des données d''une enquete', 'C2'),
(1, 15, 'Bases de l''algèbre', 'C2'),
(1, 22, 'Probabilités 1', 'C2'),
(1, 15, 'Bases de la programmation 1', 'C4'),
(1, 38, 'Découverte données entrepreunarial et économique', 'C3'),
(1, 6, 'Statistique descriptive 1 (TP)', 'C2'),
(1, 7, 'PPP - tutorat 1P', 'C3'),
(1, 4, 'Projet Personnel et Professionnel 1', 'C3'),
(1, 1, 'Bases de l''algèbre', 'C2'),
(1, 3, 'Probabilités 1 (machine)', 'C2'),
(1, 5, 'Bases de la programmation 1', 'C4'),
(1, 4, 'Statistique descriptive 1', 'C2'),
(1, 10, 'Bases de la programmation 1 (TP)', 'C4'),
(1, 8, 'Base de données relationnelles 1 (TP)', 'C1'),
(1, 4, 'Probabilités 1', 'C2'),
(1, 6, 's1 Communication de l''information : l''enquête', 'C3'),
(1, 2, 'Découverte données entrepreunarial et économique', 'C3'),
(1, 7, 'Projet Personnel et Professionnel 1 (autonomie)', 'C3'),
(1, 8, 's1 Communication de l''information et recherche documentaire', 'C3'),
(1, 6, 'Bases de la programmation 2 (TP)', 'C4'),
(1, 2, 'Projet Personnel et Professionnel 1 : fiches métiers', 'C3'),
(1, 2, 'Bases de la programmation 2', 'C4'),
(1, 6, 'Découverte données entrepreunarial et économique (autonomie)', 'C3'),
(1, 2, 'Bases de la programmation 1 (CJ)', 'C4'),
(1, 12, 'Tableur et reporting', 'C3'),
(1, 4, 'Analyse des données d''une enquete (projet)', 'C2'),
(1, 26, 'Mathématiques - Analyse (CJ)', 'C2'),
(1, 28, 'Statistique inférentielle', 'C2'),
(1, 7, 'Régression sur données réelles', 'C2'),
(1, 5, 'Ecriture et lecture de fichiers de données', 'C1'),
(1, 8, 'Reporting et datavisualisation CF', 'C3'),
(1, 2, 'dataviz rentrée', 'C3'),
(1, 8, 'Estimation par échantillonnage', 'C2'),
(1, 8, 'Communication et sémiologie - Suite office', 'C3'),
(1, 2, 'dataviz rentrée restit', 'C3'),
(1, 9, 'Analyse des données d''une enquete', 'C2'),
(1, 6, 'Ecriture et lecture de fichiers de données (non encadré)', 'C1'),
(1, 3, 'Reporting données stockées dans SGBD relationnel (projet)', 'C3'),
(1, 7, 'Mathématiques - Analyse (CF)', 'C2'),
(1, 12, 'Mathématiques - Analyse (DC)', 'C2'),
(1, 4, 'Mathématiques - Analyse (TP)', 'C2'),
(1, 16, 'Communication et sémiologie', 'C3'),
(1, 10, 'Tableur et reporting (TP)', 'C3'),
(1, 3, 'Analyse de données reporting et datavisualisation (restitution)', 'C3'),
(1, 9, 'Conception et implémentation d''une base de données (non encadré)', 'C1'),
(1, 9, 'Datavisualisation', 'C3'),
(1, 2, 'Préparation et synthèse tableau de données pour analyse (lancemen t)', 'C1'),
(1, 20, 'Apprendre en situation la prod°de données en entreprise', 'C3'),
(1, 6, 'Energie - environnement (POL)', 'C3'),
(1, 19, 'Communication de l''information et recherche documentaire (A.Morea ux)', 'C3'),
(1, 6, 'Programmation statistique (VBA)', 'C4'),
(1, 3, 'Apprendre en situation la prod°de données en entreprise (autonomi e)', 'C3'),
(1, 1, 'Méthodologie du travail universitaire', 'C3'),
(1, 3, 'Conférence métier (INSEE stat)', 'C3'),
(1, 2, 'PPP2 : Le métier d''Enseigant-Chercheur', 'C3'),
(1, 1, 'Présentation alternance (par mme Joly)', 'C3'),
(1, 3, 'Présentation en anglais territoire economique culturel', 'C3'),
(1, 3, 'Reporting et datavisualisation CJ', 'C3'),
(1, 2, 'rentrée PEC SD', 'C3'),
(1, 3, 'Présentation en anglais territoire économique culturel', 'C3'),

-- SEMESTRE 2
(2, 4, 'Projet Personnel et Professionnel 2 (autonomie)', 'C3'),
(2, 8, 'Statistique descriptive 2', 'C2'),
(2, 21, 'Probabilités 2', 'C2'),
(2, 2, 'Statistique descriptive 2', 'C2'),
(2, 22, 'Approfondissement de l''anglais de spécialité', 'C3'),
(2, 2, 'Ecriture et lecture de fichiers de données (soutenances)', 'C1'),
(2, 2, 'Projet Personnel et Professionnel 2', 'C3'),
(2, 16, 'Base de données relationnelles 2', 'C1'),
(2, 6, 'Portfolio (soutenance)', 'C3'),
(2, 6, 'Soutenances PPP S2', 'C3'),
(2, 6, 'Probabilités 2 - simulation', 'C2'),
(2, 6, 'Base de données relationnelles 2 (TP)', 'C1'),
(2, 8, 'Participation aux soutenances', 'C3'),
(2, 2, 'Base de données relationnelles 2', 'C1'),
(2, 1, 'PPP - tutorat 2P', 'C3'),
(2, 3, 'Analyse de données reporting et datavisualisation (soutenance mét ier)', 'C3'),
(2, 4, 'Analyse de données reporting et datavisualisation (soutenance tec hnique)', 'C3'),
(2, 2, 'Probabilités 2', 'C2'),
(2, 93, 'Analyse de données reporting et datavisualisation (Non encadré)', 'C3'),
(2, 7, 'Portfolio (autonomie)', 'C3'),
(2, 32, 'Etude données environnement entrepreunarial & écononique', 'C3'),
(2, 12, 'Analyse de données reporting et datavisualisation (CdP)', 'C3'),
(2, 3, 'Energie - environnement', 'C3'),
(2, 10, 'Conception et implémentation d''une base de données', 'C1'),
(2, 8, 'enquête - administration terrain', 'C3'),
(2, 9, 'Reporting données stockées dans SGBD relationnel (projet)', 'C3'),
(2, 8, 'Analyse de données reporting et datavisualisation (tutorat CJ)', 'C3'),
(2, 14, 'Mise en oeuvre d''une enquête - projet non encadré', 'C2'),
(2, 6, 'Préparation et synthèse tableau de données pour analyse', 'C1'),
(2, 5, 'Programmation statistique (R TD)', 'C4'),
(2, 25, 'Anglais de spécialité', 'C3'),
(2, 10, 'Portfolio (non encadré)', 'C3'),
(2, 6, 'Programmation statistique (QGIS)', 'C4'),
(2, 8, 'Reporting et datavisualisation CJ TP', 'C3'),
(2, 12, 'Analyse des données d''une enquete (non encadré)', 'C2'),
(2, 4, 'PPP1 Presentation', 'C3'),
(2, 10, 'Mise en oeuvre d''une enquête', 'C2'),
(2, 7, 'Mise en oeuvre d''une enquête - projet', 'C2'),
(2, 2, 'Cours Moodle : Être étudiant\, ça s''apprend', 'C3'),
(2, 1, 'Estimation par échantillonnage (projet)', 'C2'),
(2, 10, 'Journées portes ouvertes Dole', 'C3'),
(2, 12, 'Analyse de données reporting et datavisualisation (tutorat)', 'C3'),
(2, 3, 'Présentation en anglais territoire economique culturel', 'C3'),
(2, 12, 'Construction et présentation d''indicateurs de performance', 'C3'),
(2, 2, 'Ecriture et lecture de fichiers de données (projet)', 'C1'),
(2, 4, 'Conférence métier (BD issus de capteurs)', 'C3'),
(2, 5, 'Alternance dating', 'C3'),
(2, 8, 'Communication et sémiologie - image de marque', 'C3'),
(2, 4, 'Communication et sémiologie TP', 'C3'),
(2, 5, 'Portfolio', 'C3'),
(2, 5, 'Reporting données stockées dans SGBD relationnel', 'C3'),
(2, 4, 'Programmation statistique (VBA)', 'C4'),
(2, 4, 'Analyse de données reporting et datavisualisation (rapport)', 'C3'),
(2, 1, 'Préparation et synthèse tableau de données pour analyse (projet)', 'C1'),
(2, 1, 'Mathématiques - Analyse (CJ)', 'C2'),
(2, 3, 'Fresque du climat', 'C3'),
(2, 1, 'Reporting et datavisualisation CF', 'C3'),
(2, 3, 'Conception et implémentation d''une base de données (projet)', 'C1'),
(2, 4, 'Programmation statistique (R TP)', 'C4'),
(2, 1, 'Conseil de département', 'C3'),
(2, 1, 'Prog - bonnes pratiques', 'C4'),
(2, 3, 'Préparation et synthèse tableau de données pour analyse', 'C1'),
(2, 2, 'Energie - environnement (POL)', 'C3'),
(2, 2, 'Apprendre en situation la prod°de données en entreprise (projet)', 'C3'),
(2, 2, 'Estimation par échantillonnage (non encadré)', 'C2'),
(2, 3, 'Communication de l''information et recherche documentaire', 'C3'),
(2, 2, 'retard ouverture gymnase', 'C3'),
(2, 2, 'Préparation et synthèse tableau de données pour analyse', 'C1'),
(2, 5, 'Dolesup', 'C3'),
(2, 2, 'dataviz rentrée (avec S3)', 'C3'),
(2, 2, 'Statistique inférentielle', 'C2'),
(2, 2, 'Mathématiques - Analyse (CF)', 'C2'),
(2, 2, 'Tableur et reporting', 'C3'),

-- SEMESTRE 3
(3, 24, 'SAÉ 3.03 - Description et prévision de données temporelles', 'C2'),
(3, 28, 's3 Communication organisationnelle et professionnelle', 'C3'),
(3, 12, 'SAÉ 3.01 - Collecte automatisée de données web (Autonomie)', 'C4'),
(3, 6, 'SAÉ 3.02 - Intégration de données dans un Datawarehouse (projet)', 'C1'),
(3, 3, 'SAÉ 3.01 - Collecte automatisée de données web (projet CJ)', 'C4'),
(3, 12, 'SAÉ 3.01 - Collecte automatisée de données web (CJ)', 'C4'),
(3, 3, 'SAÉ 3.01 - Collecte automatisée de données web (projet DT)', 'C4'),
(3, 12, 'SAÉ 3.01 - Collecte automatisée de données web (DT)', 'C4'),
(3, 20, 'SAÉ 3.02 - Intégration de données dans un Datawarehouse', 'C1'),
(3, 6, 'Introduction aux techniques de sondage', 'C2'),
(3, 18, 'SAÉ 3.02 - Intégration de données dans un Datawarehouse (autonomi e)', 'C1'),
(3, 2, 'dataviz rentrée (avec S3)', 'C3'),
(3, 12, 'Introduction à la cybersécurité des données', 'C1'),
(3, 12, 'Introduction aux données textuelles', 'C2'),
(3, 17, 'SAÉ 3.04 - Conformité réglementaire pour traiter des données', 'C1'),
(3, 1, 'Introduction aux techniques de sondage - test', 'C2'),
(3, 2, 'Technologie web', 'C4'),
(3, 10, 'Anglais scientifique et argumentation', 'C3'),
(3, 28, 'Sport', 'C3'),
(3, 10, 'Technologie web', 'C4'),
(3, 20, 'Algèbre linéaire', 'C2'),
(3, 12, 'Exploration et valorisation de la donnée cadre juridique/éco', 'C3'),
(3, 13, 'Automatisation et test', 'C4'),
(3, 12, 'Classification automatique', 'C2'),
(3, 2, 'Données de l''environnement (autonomie)', 'C3'),
(3, 6, 'Programmation objet (projet autonomie)', 'C4'),
(3, 22, 'Test d''hypothèses pour analyse bi-variée', 'C2'),
(3, 4, 'Projet personnel et professionnel : PE', 'C3'),
(3, 3, 'Projet personnel et professionnel : connaissance de soi', 'C3'),
(3, 2, 'dataviz rentrée restit', 'C3'),
(3, 8, 'Projet personnel et professionnel : Posture professionnelle', 'C3'),
(3, 8, 'Explor. et valor. cadre juridique/éco - partie RSE', 'C3'),
(3, 10, 'Journées portes ouvertes Dole', 'C3'),
(3, 1, 'rentrée PEC SD', 'C3'),
(3, 6, 'Projet personnel et professionnel', 'C3'),
(3, 2, 'Méthodes factorielles', 'C2'),
(3, 6, 'Automatisation et test (projet)', 'C4'),
(3, 13, 'Système d''information géographique', 'C3'),

-- SEMESTRE 4
(4, 10, 'SAÉ 4.02 - Reporting d''une analyse multivariée (autonomie)', 'C3'),
(4, 7, 'SAÉ 4.01 - Développement composant solution décisionnelle (projet )', 'C4'),
(4, 4, 'Programmation statistique avancée (projet autonomie)', 'C4'),
(4, 18, 'Utilisation d''outils de reporting 2', 'C3'),
(4, 16, 'Utilisation avancée d''outils de reporting', 'C3'),
(4, 11, 'SAÉ 4.02 - Reporting d''une analyse multivariée (ACM)', 'C3'),
(4, 9, 'SAÉ 4.02 - Reporting d''une analyse multivariée (RShiny)', 'C3'),
(4, 2, 'Programmation statistique avancée (projet)', 'C4'),
(4, 2, 'SAÉ 4.02 - Reporting d''une analyse multivariée (ACM)', 'C3'),
(4, 18, 'Programmation statistique avancée', 'C4'),
(4, 3, 'Projet personnel et professionnel : soutenance', 'C3'),
(4, 3, 'SAÉ 4.02 - Reporting d''une analyse multivariée (projet CJ)', 'C3'),
(4, 3, 'soutenances PPP s4', 'C3'),
(4, 27, 'SAÉ 4.01 - Développement composant solution décisionnelle (autono mie)', 'C4'),
(4, 8, 'soutenances alternance', 'C3'),
(4, 6, 'SAÉ 4.01 - Développement composant solution décisionnelle', 'C4'),
(4, 4, 'Portfolio s4', 'C3'),
(4, 4, 'soutenances Portfolio s4', 'C3'),
(4, 2, 'SAÉ 4.01 - Développement composant solution décisionnelle (souten ance)', 'C4'),
(4, 20, 'Programmation objet', 'C4'),
(4, 4, 'Portfolio', 'C3'),
(4, 31, 'Données de l''environnement entreprena et éco pour aide décis', 'C1'),
(4, 24, 'Anglais professionnel', 'C3'),
(4, 20, 'Systèmes d''information décisionnels', 'C4'),
(4, 3, 'Portfolio (autonomie)', 'C3'),
(4, 16, 'Méthodes factorielles', 'C2'),
(4, 16, 'Préparation / Intégration de données', 'C1'),
(4, 8, 'Communication scientifique et argumentation', 'C3'),
(4, 4, 'Projet personnel et professionnel : IA génératives', 'C2'),
(4, 6, 'Classification automatique (compléments)', 'C2'),
(4, 10, 'Droit', 'C3'),
(4, 12, 'Programmation web', 'C4'),
(4, 2, 'Programmation objet (projet)', 'C4'),
(4, 2, 'Présentation règles de l''alternance', 'C3'),
(4, 2, 'Test d''hypothèses pour analyse bi-variée', 'C2'),
(4, 4, 'Mon alternance en anglais', 'C3'),
(4, 1, 'Conseil de département', 'C3'),
(4, 2, 'Test d''hypothèses pour analyse bi-variée', 'C2'),

-- SEMESTRE 5
(5, 12, 'SAÉ 5.01 - Analyse et conception d''un outil décisionnel', 'C4'),
(5, 7, 'SAÉ 5.01 - Analyse et conception d''un outil décisionnel (projet)', 'C4'),
(5, 14, 'SAÉ 5.01 - Analyse et conception d''un outil décisionnel JA', 'C4'),
(5, 12, 'SAÉ 5.02 - Migration NoSQL', 'C1'),
(5, 21, 'SAÉ 5.01 - Analyse et conception d''un outil décisionnel (projet a utonomie)', 'C4'),
(5, 12, 'SAÉ 5.03 - Datamining', 'C2'),
(5, 15, 's5 Communication des données', 'C3'),
(5, 18, 'Traitement des données textuelles', 'C2'),
(5, 20, 'Méthodes statistiques pour le big data', 'C2'),
(5, 10, 'Anglais pour la communication d''entreprise', 'C3'),
(5, 20, 'Big Data : enjeux\, stockage et extraction', 'C1'),
(5, 24, 'Développement logiciel', 'C4'),
(5, 15, 'base de données NoSQL DT', 'C1'),
(5, 6, 'Classification de données textuelles', 'C2'),
(5, 2, 'base de données NoSQL CJ', 'C1'),
(5, 12, 'Apprentissage automatique pour l''IA', 'C2'),
(5, 8, 'Projet personnel et professionnel', 'C3'),
(5, 3, 'Data Mining', 'C2'),
(5, 3, 'Portfolio (autonomie)', 'C3'),
(5, 10, 'Communication pour le management', 'C3'),
(5, 1, 'Conseil de département', 'C3'),
(5, 6, 'Data Mining (MS)', 'C2'),

-- SEMESTRE 6
(6, 28, 'SAÉ 6.01 - Développement et test d''un outil décisionnel', 'C4'),
(6, 8, 'SAÉ 6.01 - Développement et test d''un outil décisionnel (projet)', 'C4'),
(6, 12, 'Applications en économie et gestion 2', 'C3'),
(6, 22, 'SAÉ 6.01 - Développement et test d''un outil décisionnel (projet a utonomie))', 'C4'),
(6, 30, 'Approfondissement en Big Data', 'C1'),
(6, 8, 'soutenances alternance', 'C3'),
(6, 8, 'soutenances stage BUT2 / ALT BUT3', 'C3'),
(6, 1, 'soutenances Portfolio s6 FI', 'C3'),
(6, 12, 'Anglais de spécialité (MC)', 'C3'),
(6, 16, 'Data Mining', 'C2'),
(6, 2, 'rentrée PEC SD', 'C3'),
(6, 30, 'Programmation web pour la visualisation', 'C4'),
(6, 10, 'Classification automatique (Réseaux de neurones)', 'C2'),
(6, 13, 'base de données NoSQL CJ', 'C1'),
(6, 6, 'Classification de données textuelles', 'C2'),
(6, 18, 'Applications en économie et gestion (A. Delachaux)', 'C3'),
(6, 4, 'Portfolio', 'C3'),
(6, 5, 'Dolesup', 'C3'),
(6, 7, 'Classification automatique (renforcements)', 'C2');

-- NOUVEAU : chaque activité est rattachée à son année (S1-S2 -> BUT1, S3-S4 -> BUT2, S5-S6 -> BUT3)
UPDATE ACTIVITE_PEDAGOGIQUE
SET id_annee = 'BUT' || ((semestre + 1) / 2);

-- ============================================================
-- TABLE DES APPRENTISSAGES CRITIQUES
-- ============================================================
CREATE TABLE IF NOT EXISTS APPRENTISSAGE_CRITIQUE (
    id_ac VARCHAR(12) PRIMARY KEY,      -- ex: AC11.01, AC24.02VCOD
    intitule TEXT NOT NULL,             -- description complète
    id_annee CHAR(4) NOT NULL,         -- référence au BUT
    niveau INT CHECK (niveau BETWEEN 1 AND 3),   -- NOUVEAU : niveau 1 à 3 seulement
    id_competence CHAR(2),              -- NOUVEAU : compétence de l'AC
    FOREIGN KEY (id_annee) REFERENCES ANNEE(id_annee),
    FOREIGN KEY (id_competence) REFERENCES COMPETENCE(id_competence)
);

-- BUT1 : Traiter des données structurées
INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC11.01', 'Correctement interpréter et prendre en compte le besoin du commanditaire ou du client', 'BUT1'),
('AC11.02', 'Respecter les formalismes de notation', 'BUT1'),
('AC11.03', 'Connaître la syntaxe des langages et savoir l’utiliser', 'BUT1'),
('AC11.04', 'Mesurer l’importance de maîtriser la structure des données à exploiter', 'BUT1'),
('AC11.05', 'Comprendre les structures algorithmiques de base et leur contexte d’usage', 'BUT1'),
('AC11.06', 'Prendre conscience de l’intérêt de la programmation', 'BUT1'),
('AC12.01', 'Réaliser que les sources de données ont des caractéristiques propres à considérer (variation, précision, mise à jour...)', 'BUT1'),
('AC12.02', 'Comprendre qu’une analyse correcte ne peut émaner que de données propres et préparées', 'BUT1'),
('AC12.03', 'Comprendre l’intérêt des synthèses numériques et graphiques pour décrire une variable statistique', 'BUT1'),
('AC12.04', 'Comprendre l’intérêt des synthèses numériques et graphiques pour mettre en évidence des liaisons entre variables.', 'BUT1'),
('AC12.05', 'Comprendre l''intérêt de l’utilisation d’un modèle probabiliste', 'BUT1'),
('AC12.06', 'Appréhender la notion de fluctuation d''échantillonnage, notamment à l’aide de simulations probabilistes', 'BUT1'),
('AC13.01', 'Prendre connaissance des biais rencontrés dans la mise en place d’une enquête', 'BUT1'),
('AC13.02', 'Identifier l’importance de contextualiser ses données', 'BUT1'),
('AC13.03', 'Mesurer l’importance de mettre en évidence des résultats clés par l’utilisation d’indicateurs pertinents', 'BUT1'),
('AC13.04', 'Lors de la restitution des résultats, mesurer l’importance d’expliciter également la démarche suivie', 'BUT1'),
('AC13.05', 'Comprendre les intérêts de la data visualisation et de l’infographie', 'BUT1'),
('AC13.06', 'Mesurer l’importance d’une expression précise et nuancée dans la communication en français et dans une langue étrangère des résultats', 'BUT1')
ON CONFLICT DO NOTHING;

-- BUT2 : Automatiser le traitement de données multidimensionnelles
INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC21.01', 'Comprendre l''organisation des données de l''entreprise', 'BUT2'),
('AC21.02', 'Réaliser le rôle central et spécifique de l''entrepôt de données dans la chaine décisionnelle', 'BUT2'),
('AC21.03', 'Identifier et résoudre les problèmes d’intégration de sources complémentaires et hétérogènes', 'BUT2'),
('AC21.04', 'Comprendre la nécessité de tester, corriger et documenter un programme', 'BUT2'),
('AC21.05', 'Apprécier l’intérêt de briques logicielles existantes et savoir les utiliser', 'BUT2')
ON CONFLICT DO NOTHING;

INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC22.01', 'Prendre conscience de la différence entre modélisation statistique et analyse exploratoire', 'BUT2'),
('AC22.02', 'Saisir la spécificité de l’analyse des données temporelles', 'BUT2'),
('AC22.03', 'Comprendre l’intérêt des analyses multivariées pour synthétiser et résumer l’information portée par plusieurs variables', 'BUT2'),
('AC22.04', 'Appréhender l’idée de confronter une hypothèse avec la réalité pour prendre une décision', 'BUT2'),
('AC22.05', 'Apprécier les limites de validité et les conditions d’application d’une analyse', 'BUT2')
ON CONFLICT DO NOTHING;

INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC23.01', 'Saisir l’intérêt de mobiliser de manière proactive des ressources métiers liées à l''environnement (y compris économique, international…)', 'BUT2'),
('AC23.02', 'Savoir défendre ses choix d’analyses', 'BUT2'),
('AC23.03', 'Saisir la nécessité de choisir des indicateurs pertinents pour communiquer sur les résultats', 'BUT2'),
('AC23.04', 'Prendre conscience de la rigueur requise dans ses productions et dans la communication à leur propos', 'BUT2'),
('AC23.05', 'Comprendre les enjeux des relations en milieu professionnel adaptées à l’interlocuteur et à sa culture', 'BUT2')
ON CONFLICT DO NOTHING;

INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC24.01VCOD', 'Comprendre le rôle fondamental de l’analyse des besoins et de l’existant dans un projet décisionnel (architecture, visualisation...)', 'BUT2'),
('AC24.02VCOD', 'Percevoir les enjeux de l’automatisation et de l''interopérabilité d’un ensemble de tâches', 'BUT2'),
('AC24.03VCOD', 'Prendre conscience des différences entre outils (logiciels, langages) pour choisir le plus adapté', 'BUT2'),
('AC24.04VCOD', 'Comprendre le cycle de vie d’un projet informatique', 'BUT2')
ON CONFLICT DO NOTHING;

-- BUT3 : Intégrer le traitement de données complexes
INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC31.01', 'Identifier les solutions technologiques permettant la collecte et la diffusion de données', 'BUT3'),
('AC31.02', 'Comprendre les spécificités des données complexes et de leur exploitation', 'BUT3'),
('AC31.03', 'Savoir mener une veille technologique', 'BUT3')
ON CONFLICT DO NOTHING;

INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC32.01', 'Prendre conscience des différences entre des outils statistiques pour choisir le plus adapté', 'BUT3'),
('AC32.02', 'Saisir l’importance de la mise en œuvre de méthodes adaptées à des domaines et des données spécifiques (Marketing, Biostatistique, Statistique spatiale, Gestion …)', 'BUT3'),
('AC32.03', 'Prendre conscience des limites des méthodes classiques pour l’analyse des données complexes (données massives, données mal structurées…)', 'BUT3'),
('AC32.04', 'Comprendre les mécanismes de bases de l’intelligence artificielle (apprentissage statistique supervisé, échantillons d''apprentissage et échantillons de test…)', 'BUT3')
ON CONFLICT DO NOTHING;

INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC33.01', 'Savoir transformer la donnée pour la mettre en conformité avec des normes (anonymisation, normalisation)', 'BUT3'),
('AC33.02', 'Mesurer l''impact d''un respect de la législation en terme de droit des données.', 'BUT3'),
('AC33.03', 'Identifier les clés d''une bonne communication (procédures et techniques utilisées)', 'BUT3'),
('AC33.04', 'Mesurer l’importance de comprendre et de répondre à l''ensemble des problématiques posées', 'BUT3'),
('AC33.05', 'Être force de proposition', 'BUT3'),
('AC33.06', 'Prendre conscience de la nécessité d’intégrer la vision de l’interlocuteur (transversalité, international, multiculture, niveau d’expertise…)', 'BUT3')
ON CONFLICT DO NOTHING;

INSERT INTO APPRENTISSAGE_CRITIQUE (id_ac, intitule, id_annee) VALUES
('AC34.01VCOD', 'Prendre conscience de la nécessité d’utiliser des moyens spécifiques pour exploiter les Big Data ou les flux de données', 'BUT3'),
('AC34.02VCOD', 'Défendre ses choix de solution par un argumentaire éclairé', 'BUT3'),
('AC34.03VCOD', 'Réaliser l’intérêt d’appliquer les méthodes de développement dans la réalisation d’un projet informatique', 'BUT3'),
('AC34.04VCOD', 'Apprécier l’intérêt de l’utilisation d’un gestionnaire de versions de code', 'BUT3')
ON CONFLICT DO NOTHING;



-- ============================================================
-- EXERCICE 1 : LIEN AC -> COMPETENCE
-- Le 4e caractère du code donne la compétence (AC11.01 -> C1, AC24.01VCOD -> C4)
-- ============================================================
UPDATE APPRENTISSAGE_CRITIQUE
SET id_competence = 'C' || SUBSTRING(id_ac, 4, 1);


-- Les images de test du cours ne font pas partie du portfolio : pas d'image par compétence
UPDATE COMPETENCE SET preuve = NULL;

-- Vue : heures par année et par compétence (pour le graphique de la page Parcours)
CREATE VIEW HEURES_PAR_ANNEE AS
SELECT a.id_annee, a.id_competence, SUM(a.heure) AS total_heures, COUNT(*) AS nb_activites
FROM ACTIVITE_PEDAGOGIQUE a
GROUP BY a.id_annee, a.id_competence
ORDER BY a.id_annee, a.id_competence;


-- ############################################################
-- 2e PARTIE : MON PARCOURS
-- Source : mon profil LinkedIn, mes certificats et data/projets.csv
-- ############################################################

-- ============================================================
-- FORMATIONS
-- ============================================================
CREATE TABLE FORMATION (
    id_formation SERIAL PRIMARY KEY,
    diplome TEXT NOT NULL,
    etablissement TEXT NOT NULL,
    lieu TEXT,
    date_debut DATE NOT NULL,
    date_fin DATE,                                   -- vide = en cours
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

INSERT INTO FORMATION (diplome, etablissement, lieu, date_debut, date_fin) VALUES
('BUT Sciences des Données, parcours VCOD', 'IUT de Besançon-Vesoul (antenne de Dôle)', 'Dôle', '2025-09-01', '2027-06-30'),
('BUT Sciences des Données (1re année)', 'IUT de Vannes', 'Vannes', '2024-09-01', '2025-06-30'),
('Ingénierie informatique et télécommunications', 'Instituto Superior de Transportes e de Comunicações (ISUTC)', 'Mozambique', '2023-02-01', '2024-05-31'),
('Baccalauréat Mathématiques et Sciences naturelles', 'Escola Secundária « 29 de Setembro »', 'Maxixe, Mozambique', '2021-02-01', '2022-12-31');

-- ============================================================
-- EXPÉRIENCES
-- ============================================================
CREATE TABLE EXPERIENCE (
    id_experience SERIAL PRIMARY KEY,
    intitule TEXT NOT NULL,
    structure TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Alternance', 'Stage', 'Expérience académique', 'Engagement')),
    lieu TEXT,
    date_debut DATE NOT NULL,
    date_fin DATE,                                   -- vide = en cours
    description TEXT,
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

INSERT INTO EXPERIENCE (intitule, structure, type, lieu, date_debut, date_fin, description) VALUES
('Data scientist apprentie', 'Colas', 'Alternance', 'Nouvelle-Aquitaine', '2026-09-01', NULL,
 'Alternance en data science, en parallèle de la 3e année de BUT.'),
('Stage data analyst junior', 'SFMI', 'Stage', 'Charquemont', '2026-07-01', '2026-08-31',
 'Conception d''une application de covoiturage interne avec navettes en temps réel. Dashboard de pilotage industriel avec gestion des rôles et requêtes SQL Server.'),
('Cheffe de projet data', 'Serviciale', 'Stage', 'Metz', '2026-04-01', '2026-06-30',
 'Seule ressource data science et développeuse full stack d''une marketplace de services à domicile, sous la direction du CEO. Score de fiabilité multicritère validé par simulation Monte Carlo, détection d''anomalies (IsolationForest), tableau de bord Dash/Plotly et suite de 132 tests automatisés en CI/CD.'),
('Analyste de données junior (projet académique)', 'IUT de Vannes', 'Expérience académique', 'Vannes', '2024-09-01', '2025-06-30',
 'Modèles prédictifs et projets collaboratifs d''analyse de données, avec identification des besoins métier et production de rapports.'),
('Membre', 'The New York Academy of Sciences', 'Engagement', 'À distance', '2022-06-01', '2024-01-31',
 'Projets collaboratifs internationaux, communication interculturelle et travail en équipe à distance.');

-- ============================================================
-- PROJETS
-- (les projets réalisés pour une entreprise ne sont pas publiés : ils sont décrits dans EXPERIENCE)
-- ============================================================
CREATE TABLE PROJET (
    id_projet SERIAL PRIMARY KEY,
    titre TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Projet de formation', 'Projet personnel')),
    annee INT CHECK (annee BETWEEN 2020 AND 2030),   -- vide tant qu'elle n'est pas confirmée
    description TEXT,
    lien TEXT
);

INSERT INTO PROJET (titre, type, annee, description) VALUES
('Portfolio de visualisation de données', 'Projet de formation', 2026,
 'Ce site : base PostgreSQL lancée dans Docker, serveur Express qui expose une API, pages qui affichent les données avec Chart.js.'),
('Analyse multivariée de candidatures (SAE 402)', 'Projet de formation', 2026,
 'Analyse de données d''admission avec KNIME, anonymisation avec ARX et restitution dans une application R Shiny.'),
('Atlas démographique des communes françaises', 'Projet personnel', 2026,
 'Exploration et visualisation des données INSEE 2016-2022 sur les communes françaises.'),
('BRICOLIB : location d''outils de bricolage (SAÉ)', 'Projet de formation', 2025,
 'Cartographie des offres et demandes de location d''outils en France, modèles prédictifs et tableaux de bord interactifs sous Power BI.'),
('Plateforme de données FactoryFlow', 'Projet personnel', NULL,
 'Plateforme de données de bout en bout : orchestration avec Airflow, transformations avec dbt, modèles scikit-learn et interface Streamlit.');

-- ============================================================
-- TECHNOLOGIES et TABLE D'ASSOCIATION PROJET <-> TECHNOLOGIE (lien N-N)
-- ============================================================
CREATE TABLE TECHNOLOGIE (
    id_techno SERIAL PRIMARY KEY,
    nom TEXT NOT NULL UNIQUE,
    categorie TEXT NOT NULL CHECK (categorie IN ('Langage', 'Base de données', 'Visualisation', 'Machine learning', 'Data engineering', 'Web', 'Outil'))
);

INSERT INTO TECHNOLOGIE (nom, categorie) VALUES
('Python', 'Langage'), ('R', 'Langage'), ('JavaScript', 'Langage'), ('SQL', 'Langage'),
('PostgreSQL', 'Base de données'),
('pandas', 'Data engineering'), ('dbt', 'Data engineering'), ('Airflow', 'Data engineering'),
('matplotlib', 'Visualisation'), ('Plotly', 'Visualisation'), ('Power BI', 'Visualisation'),
('Shiny', 'Visualisation'), ('Streamlit', 'Visualisation'), ('Chart.js', 'Visualisation'),
('scikit-learn', 'Machine learning'),
('HTML', 'Web'), ('Node.js', 'Web'), ('Express', 'Web'),
('KNIME', 'Outil'), ('ARX', 'Outil'), ('Docker', 'Outil');

CREATE TABLE PROJET_TECHNOLOGIE (
    id_projet INT NOT NULL,
    id_techno INT NOT NULL,
    PRIMARY KEY (id_projet, id_techno),            -- clé primaire composée : pas de doublon
    FOREIGN KEY (id_projet) REFERENCES PROJET(id_projet) ON DELETE CASCADE,
    FOREIGN KEY (id_techno) REFERENCES TECHNOLOGIE(id_techno) ON DELETE CASCADE
);

-- Chaque ligne : (numéro du projet, nom de la technologie)
INSERT INTO PROJET_TECHNOLOGIE (id_projet, id_techno)
SELECT v.id_projet, t.id_techno
FROM (VALUES
    (1, 'PostgreSQL'), (1, 'SQL'), (1, 'Docker'), (1, 'Node.js'), (1, 'Express'), (1, 'JavaScript'), (1, 'HTML'), (1, 'Chart.js'),
    (2, 'KNIME'), (2, 'ARX'), (2, 'R'), (2, 'Shiny'),
    (3, 'Python'), (3, 'pandas'), (3, 'matplotlib'), (3, 'Plotly'), (3, 'HTML'),
    (4, 'Power BI'),
    (5, 'Python'), (5, 'PostgreSQL'), (5, 'dbt'), (5, 'Airflow'), (5, 'scikit-learn'), (5, 'Streamlit')
) AS v(id_projet, nom)
JOIN TECHNOLOGIE t ON t.nom = v.nom;   -- on retrouve le numéro de chaque technologie par son nom

-- ============================================================
-- CERTIFICATS ET DISTINCTIONS
-- ============================================================
CREATE TABLE CERTIFICAT (
    id_certificat SERIAL PRIMARY KEY,
    intitule TEXT NOT NULL,
    organisme TEXT,                                  -- vide = à confirmer
    type TEXT NOT NULL CHECK (type IN ('Certificat', 'Distinction')),
    date_obtention DATE,                             -- vide = à confirmer
    fichier TEXT,                                    -- image du certificat dans client/preuves/
    document TEXT                                    -- certificat original en PDF dans client/preuves/
);

INSERT INTO CERTIFICAT (intitule, organisme, type, date_obtention, fichier, document) VALUES
('Databricks Fundamentals Accreditation', 'Databricks', 'Certificat', '2026-08-01', 'certificat_databricks.png', 'certificat_databricks.pdf'),
('AWS Database Offerings', 'AWS Training & Certification', 'Certificat', '2025-07-21', 'certificat_aws.png', 'certificat_aws.pdf'),
('CS403 : Introduction to Modern Database Systems (42 h)', 'Saylor Academy', 'Certificat', '2025-07-21', 'certificat_cs403.png', 'certificat_cs403.pdf'),
('Introduction to Career Skills in Data Analytics', 'LinkedIn Learning', 'Certificat', '2025-07-20', 'certificat_data_analytics.png', 'certificat_data_analytics.pdf'),
('Introduction to Career Skills in Software Development', 'LinkedIn Learning (Microsoft et LinkedIn)', 'Certificat', NULL, NULL, NULL),
('AI Fluency for Students', 'Anthropic Academy', 'Certificat', NULL, NULL, NULL),
('Opérateur informatique (B.A. en ELT)', NULL, 'Certificat', NULL, NULL, NULL),
('Gazprom Olympiad', 'Université électrotechnique « LETI »', 'Certificat', NULL, NULL, NULL),
('2e prix du concours « Lire en vacances » 2023/2024', 'Ethale Publishing', 'Distinction', NULL, NULL, NULL),
('BSGCT Scientific Writing Competition 2026', NULL, 'Distinction', NULL, NULL, NULL);

-- ============================================================
-- LANGUES
-- ============================================================
CREATE TABLE LANGUE (
    id_langue SERIAL PRIMARY KEY,
    nom TEXT NOT NULL UNIQUE,
    niveau TEXT NOT NULL CHECK (niveau IN ('Langue maternelle ou bilingue', 'Professionnel', 'Élémentaire'))
);

INSERT INTO LANGUE (nom, niveau) VALUES
('Portugais', 'Langue maternelle ou bilingue'),
('Anglais', 'Langue maternelle ou bilingue'),
('Français', 'Professionnel'),
('Espagnol', 'Professionnel'),
('Russe', 'Élémentaire');

-- ============================================================
-- PREUVES : un projet, une expérience OU un certificat qui démontre un AC
-- ============================================================
CREATE TABLE PREUVE (
    id_preuve SERIAL PRIMARY KEY,
    fichier TEXT,                                    -- image (facultative)
    texte TEXT,                                      -- explication (facultative)
    id_ac VARCHAR(12) NOT NULL,
    id_projet INT,
    id_experience INT,
    id_certificat INT,
    FOREIGN KEY (id_ac) REFERENCES APPRENTISSAGE_CRITIQUE(id_ac) ON DELETE CASCADE,
    FOREIGN KEY (id_projet) REFERENCES PROJET(id_projet) ON DELETE CASCADE,
    FOREIGN KEY (id_experience) REFERENCES EXPERIENCE(id_experience) ON DELETE CASCADE,
    FOREIGN KEY (id_certificat) REFERENCES CERTIFICAT(id_certificat) ON DELETE CASCADE,
    CHECK (fichier IS NOT NULL OR texte IS NOT NULL),                   -- image et/ou texte
    CHECK (num_nonnulls(id_projet, id_experience, id_certificat) = 1)   -- une seule source
);

-- Propositions à valider : chaque ligne relie une source à l'AC qu'elle démontre
INSERT INTO PREUVE (fichier, texte, id_ac, id_projet, id_experience, id_certificat) VALUES
(NULL, 'Analyse multivariée des données d''admission (KNIME, R Shiny).', 'AC22.03', 2, NULL, NULL),
(NULL, 'Données sensibles anonymisées avec ARX avant l''analyse.', 'AC33.01', 2, NULL, NULL),
(NULL, 'Visualisations des données démographiques INSEE.', 'AC13.05', 3, NULL, NULL),
(NULL, 'Chaîne de traitement automatisée avec Airflow et dbt.', 'AC24.02VCOD', 5, NULL, NULL),
(NULL, 'Historique Git du portfolio et suivi de l''avancement.', 'AC34.04VCOD', 1, NULL, NULL),
(NULL, 'Suite de 132 tests automatisés en CI/CD.', 'AC21.04', NULL, 3, NULL),
(NULL, 'Score de fiabilité validé par simulation Monte Carlo.', 'AC12.06', NULL, 3, NULL),
('certificat_cs403.png', 'Cours de 42 h sur les bases de données modernes.', 'AC11.04', NULL, NULL, 3),
('certificat_aws.png', 'Panorama des bases de données proposées par AWS.', 'AC31.01', NULL, NULL, 2),
('certificat_databricks.png', 'Plateforme Databricks pour les grands volumes de données.', 'AC34.01VCOD', NULL, NULL, 1);
