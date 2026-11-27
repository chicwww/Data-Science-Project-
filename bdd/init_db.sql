-- ============================================================================
--  BASE DU PORTFOLIO DE FRANCISCA WETIMANE · PostgreSQL 16
--
--  Schéma « referentiel » : le programme national du BUT Science des données
--    (PN LP-BUT SD 2022, parcours VCOD) : compétences, composantes essentielles,
--    niveaux, apprentissages critiques (AC), SAÉ et heures d'enseignement.
--  Schéma « portfolio »   : mon parcours (formations, expériences, projets,
--    technologies, certificats, langues) et mes preuves, rattachées aux AC.
--
--  Le serveur rejoue ce fichier à chaque démarrage : toute donnée à garder s'écrit ici.
-- ============================================================================

DROP SCHEMA IF EXISTS portfolio CASCADE;
DROP SCHEMA IF EXISTS referentiel CASCADE;
CREATE SCHEMA referentiel;
CREATE SCHEMA portfolio;
COMMENT ON SCHEMA referentiel IS 'Programme national du BUT Science des données (PN 2022), parcours VCOD';
COMMENT ON SCHEMA portfolio IS 'Parcours personnel et preuves de Francisca Wetimane';

SET search_path = referentiel, portfolio;

-- ############################################################################
--  1. RÉFÉRENTIEL NATIONAL
-- ############################################################################

-- Types et domaines : les règles de format sont écrites une seule fois
CREATE DOMAIN referentiel.code_competence AS char(2) CHECK (VALUE ~ '^C[1-4]$');
CREATE DOMAIN referentiel.code_ac AS varchar(12) CHECK (VALUE ~ '^AC[1-3][1-4]\.0[1-9](VCOD)?$');
CREATE TYPE referentiel.type_sae AS ENUM ('SAÉ', 'Stage', 'Portfolio');

CREATE TABLE annee (
    id_annee   char(4)  PRIMARY KEY CHECK (id_annee ~ '^BUT[1-3]$'),
    numero     smallint NOT NULL UNIQUE CHECK (numero BETWEEN 1 AND 3),
    intitule   text     NOT NULL
);

CREATE TABLE semestre (
    numero     smallint PRIMARY KEY CHECK (numero BETWEEN 1 AND 6),
    id_annee   char(4)  NOT NULL REFERENCES annee(id_annee),
    CHECK ((numero + 1) / 2 = substring(id_annee, 4, 1)::int)   -- S1-S2 = BUT1, S3-S4 = BUT2, S5-S6 = BUT3
);

CREATE TABLE competence (
    id_competence code_competence PRIMARY KEY,
    verbe         text NOT NULL,                  -- Traiter, Analyser, Valoriser, Développer
    intitule      text NOT NULL UNIQUE,
    parcours      text CHECK (parcours IN ('VCOD')) -- vide = tronc commun
);

CREATE TABLE composante_essentielle (
    code          varchar(6) PRIMARY KEY CHECK (code ~ '^CE[1-4]\.0[1-9]$'),
    id_competence code_competence NOT NULL REFERENCES competence(id_competence),
    libelle       text NOT NULL,
    CHECK (substring(code, 3, 1) = substring(id_competence, 2, 1))
);

CREATE TABLE niveau (
    id_competence code_competence NOT NULL REFERENCES competence(id_competence),
    numero        smallint NOT NULL CHECK (numero BETWEEN 1 AND 3),
    intitule      text     NOT NULL,
    id_annee      char(4)  NOT NULL REFERENCES annee(id_annee),
    PRIMARY KEY (id_competence, numero)          -- clé primaire composée
);

CREATE TABLE apprentissage_critique (
    code_ac       code_ac  PRIMARY KEY,
    intitule      text     NOT NULL,
    id_competence code_competence NOT NULL,
    numero_niveau smallint NOT NULL,
    FOREIGN KEY (id_competence, numero_niveau) REFERENCES niveau(id_competence, numero),
    -- le code AC<année><compétence> doit correspondre à la compétence
    CHECK (substring(code_ac, 4, 1) = substring(id_competence, 2, 1))
);
CREATE INDEX ON apprentissage_critique (id_competence, numero_niveau);

CREATE TABLE sae (
    code_sae   varchar(16) PRIMARY KEY,
    intitule   text     NOT NULL,
    type       type_sae NOT NULL DEFAULT 'SAÉ',
    semestre   smallint NOT NULL REFERENCES semestre(numero),
    parcours   text CHECK (parcours IN ('VCOD'))
);
CREATE INDEX ON sae (semestre);

-- Une SAÉ cible une ou plusieurs compétences (lien N-N)
CREATE TABLE sae_competence (
    code_sae      varchar(16)     NOT NULL REFERENCES sae(code_sae) ON DELETE CASCADE,
    id_competence code_competence NOT NULL REFERENCES competence(id_competence),
    PRIMARY KEY (code_sae, id_competence)
);
CREATE INDEX ON sae_competence (id_competence);

-- Matières du programme local et leurs heures (base fournie en cours)
CREATE TABLE activite_pedagogique (
    num           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    semestre      smallint NOT NULL REFERENCES semestre(numero),
    heure         integer  NOT NULL CHECK (heure > 0),
    skill         text     NOT NULL,
    id_competence code_competence NOT NULL REFERENCES competence(id_competence),
    -- C4 (Développer un outil décisionnel, parcours VCOD) ne commence qu'en 2e année (S3)
    CHECK (id_competence <> 'C4' OR semestre >= 3)
);
CREATE INDEX ON activite_pedagogique (id_competence);
CREATE INDEX ON activite_pedagogique (semestre);

INSERT INTO annee (id_annee, numero, intitule) VALUES
('BUT1', 1, '1re année'),
('BUT2', 2, '2e année'),
('BUT3', 3, '3e année');

INSERT INTO semestre (numero, id_annee) VALUES (1, 'BUT1'), (2, 'BUT1'), (3, 'BUT2'), (4, 'BUT2'), (5, 'BUT3'), (6, 'BUT3');

INSERT INTO competence (id_competence, verbe, intitule, parcours) VALUES
('C1', 'Traiter', 'Traiter des données à des fins décisionnelles', NULL),
('C2', 'Analyser', 'Analyser statistiquement les données', NULL),
('C3', 'Valoriser', 'Valoriser une production dans un contexte professionnel', NULL),
('C4', 'Développer', 'Développer un outil décisionnel', 'VCOD');

-- Composantes essentielles (« En ... ») de chaque compétence
INSERT INTO composante_essentielle (code, id_competence, libelle) VALUES
('CE1.01', 'C1', 'En intervenant à toutes les étapes du cycle de vie de la donnée (insertion, modification, extraction, suppression)'),
('CE1.02', 'C1', 'En utilisant le modèle de données adapté aux besoins'),
('CE1.03', 'C1', 'En s’inscrivant dans une démarche de documentation des réalisations adaptée au public visé'),
('CE1.04', 'C1', 'En traduisant correctement les demandes métier en programmes, avec le respect du cahier des charges s''il existe'),
('CE1.05', 'C1', 'En écrivant un programme correctement structuré et documenté, respectant les bonnes pratiques'),
('CE1.06', 'C1', 'En identifiant les librairies et langages dédiés'),
('CE2.01', 'C2', 'En tenant compte du contexte de l’étude (économique, socio-démographique, commerciale, clinique...)'),
('CE2.02', 'C2', 'En mettant en évidence les grandes tendances et les informations principales'),
('CE2.03', 'C2', 'En identifiant et en mettant en œuvre les techniques adaptées aux attentes du client ou de l’instance décisionnaire'),
('CE2.04', 'C2', 'En identifiant et en mettant en œuvre les techniques adaptées aux données complexes (données massives, données mal structurées, flux de données…)'),
('CE2.05', 'C2', 'En tenant compte du contexte inférentiel (variabilité de l’échantillon)'),
('CE3.01', 'C3', 'En s’adaptant au niveau d’expertise, à la culture et au statut du destinataire'),
('CE3.02', 'C3', 'En s’exprimant correctement, aussi bien en français qu’en anglais, à l''oral comme à l''écrit'),
('CE3.03', 'C3', 'En veillant aux aspects éthiques, déontologiques et réglementaires d’utilisation et de diffusion des données'),
('CE3.04', 'C3', 'En interprétant et contextualisant les résultats (citations, vérification des sources, esprit critique)'),
('CE3.05', 'C3', 'En utilisant la forme de restitution adaptée'),
('CE3.06', 'C3', 'En tenant compte des réalités économiques et managériales des entreprises'),
('CE4.01', 'C4', 'En mettant en œuvre une structuration des données adaptée à leurs caractéristiques (type, volume...)'),
('CE4.02', 'C4', 'En assurant la qualité des données et minimisant les biais liés à l’incertitude et l’imprécision dans les sources'),
('CE4.03', 'C4', 'En étant sensible aux aspects éthiques, déontologiques et juridiques d’utilisation et de diffusion des données'),
('CE4.04', 'C4', 'En réalisant des solutions de visualisation spécifiques aux données métier'),
('CE4.05', 'C4', 'En intervenant à différents niveaux de la chaîne décisionnelle'),
('CE4.06', 'C4', 'En utilisant des méthodes de développement logiciel');

-- Niveaux de développement : C1 à C3 sur 3 ans, C4 (parcours VCOD) en 2e et 3e années
INSERT INTO niveau (id_competence, numero, intitule, id_annee) VALUES
('C1', 1, 'Traiter des données structurées', 'BUT1'),
('C1', 2, 'Automatiser le traitement de données multidimensionnelles', 'BUT2'),
('C1', 3, 'Intégrer le traitement de données complexes', 'BUT3'),
('C2', 1, 'Mettre en œuvre une analyse descriptive', 'BUT1'),
('C2', 2, 'Mettre en œuvre une analyse exploratoire', 'BUT2'),
('C2', 3, 'Mettre en œuvre l''analyse exploratoire de données complexes', 'BUT3'),
('C3', 1, 'Contextualiser et présenter les données', 'BUT1'),
('C3', 2, 'Restituer et argumenter ses résultats', 'BUT2'),
('C3', 3, 'Intégrer et valoriser sa production dans l''écosystème de l''entreprise', 'BUT3'),
('C4', 1, 'Développer un composant d''une solution décisionnelle', 'BUT2'),
('C4', 2, 'Participer au déploiement d''une solution décisionnelle', 'BUT3');

-- Les 54 apprentissages critiques (code AC<année><compétence>.<numéro>)
INSERT INTO apprentissage_critique (code_ac, intitule, id_competence, numero_niveau) VALUES
('AC11.01', 'Correctement interpréter et prendre en compte le besoin du commanditaire ou du client', 'C1', 1),
('AC11.02', 'Respecter les formalismes de notation', 'C1', 1),
('AC11.03', 'Connaître la syntaxe des langages et savoir l’utiliser', 'C1', 1),
('AC11.04', 'Mesurer l’importance de maîtriser la structure des données à exploiter', 'C1', 1),
('AC11.05', 'Comprendre les structures algorithmiques de base et leur contexte d’usage', 'C1', 1),
('AC11.06', 'Prendre conscience de l’intérêt de la programmation', 'C1', 1),
('AC12.01', 'Réaliser que les sources de données ont des caractéristiques propres à considérer (variation, précision, mise à jour...)', 'C2', 1),
('AC12.02', 'Comprendre qu’une analyse correcte ne peut émaner que de données propres et préparées', 'C2', 1),
('AC12.03', 'Comprendre l’intérêt des synthèses numériques et graphiques pour décrire une variable statistique', 'C2', 1),
('AC12.04', 'Comprendre l’intérêt des synthèses numériques et graphiques pour mettre en évidence des liaisons entre variables.', 'C2', 1),
('AC12.05', 'Comprendre l''intérêt de l’utilisation d’un modèle probabiliste', 'C2', 1),
('AC12.06', 'Appréhender la notion de fluctuation d''échantillonnage, notamment à l’aide de simulations probabilistes', 'C2', 1),
('AC13.01', 'Prendre connaissance des biais rencontrés dans la mise en place d’une enquête', 'C3', 1),
('AC13.02', 'Identifier l’importance de contextualiser ses données', 'C3', 1),
('AC13.03', 'Mesurer l’importance de mettre en évidence des résultats clés par l’utilisation d’indicateurs pertinents', 'C3', 1),
('AC13.04', 'Lors de la restitution des résultats, mesurer l’importance d’expliciter également la démarche suivie', 'C3', 1),
('AC13.05', 'Comprendre les intérêts de la data visualisation et de l’infographie', 'C3', 1),
('AC13.06', 'Mesurer l’importance d’une expression précise et nuancée dans la communication en français et dans une langue étrangère des résultats', 'C3', 1),
('AC21.01', 'Comprendre l''organisation des données de l''entreprise', 'C1', 2),
('AC21.02', 'Réaliser le rôle central et spécifique de l''entrepôt de données dans la chaine décisionnelle', 'C1', 2),
('AC21.03', 'Identifier et résoudre les problèmes d’intégration de sources complémentaires et hétérogènes', 'C1', 2),
('AC21.04', 'Comprendre la nécessité de tester, corriger et documenter un programme', 'C1', 2),
('AC21.05', 'Apprécier l’intérêt de briques logicielles existantes et savoir les utiliser', 'C1', 2),
('AC22.01', 'Prendre conscience de la différence entre modélisation statistique et analyse exploratoire', 'C2', 2),
('AC22.02', 'Saisir la spécificité de l’analyse des données temporelles', 'C2', 2),
('AC22.03', 'Comprendre l’intérêt des analyses multivariées pour synthétiser et résumer l’information portée par plusieurs variables', 'C2', 2),
('AC22.04', 'Appréhender l’idée de confronter une hypothèse avec la réalité pour prendre une décision', 'C2', 2),
('AC22.05', 'Apprécier les limites de validité et les conditions d’application d’une analyse', 'C2', 2),
('AC23.01', 'Saisir l’intérêt de mobiliser de manière proactive des ressources métiers liées à l''environnement (y compris économique, international…)', 'C3', 2),
('AC23.02', 'Savoir défendre ses choix d’analyses', 'C3', 2),
('AC23.03', 'Saisir la nécessité de choisir des indicateurs pertinents pour communiquer sur les résultats', 'C3', 2),
('AC23.04', 'Prendre conscience de la rigueur requise dans ses productions et dans la communication à leur propos', 'C3', 2),
('AC23.05', 'Comprendre les enjeux des relations en milieu professionnel adaptées à l’interlocuteur et à sa culture', 'C3', 2),
('AC24.01VCOD', 'Comprendre le rôle fondamental de l’analyse des besoins et de l’existant dans un projet décisionnel (architecture, visualisation...)', 'C4', 1),
('AC24.02VCOD', 'Percevoir les enjeux de l’automatisation et de l''interopérabilité d’un ensemble de tâches', 'C4', 1),
('AC24.03VCOD', 'Prendre conscience des différences entre outils (logiciels, langages) pour choisir le plus adapté', 'C4', 1),
('AC24.04VCOD', 'Comprendre le cycle de vie d’un projet informatique', 'C4', 1),
('AC31.01', 'Identifier les solutions technologiques permettant la collecte et la diffusion de données', 'C1', 3),
('AC31.02', 'Comprendre les spécificités des données complexes et de leur exploitation', 'C1', 3),
('AC31.03', 'Savoir mener une veille technologique', 'C1', 3),
('AC32.01', 'Prendre conscience des différences entre des outils statistiques pour choisir le plus adapté', 'C2', 3),
('AC32.02', 'Saisir l’importance de la mise en œuvre de méthodes adaptées à des domaines et des données spécifiques (Marketing, Biostatistique, Statistique spatiale, Gestion …)', 'C2', 3),
('AC32.03', 'Prendre conscience des limites des méthodes classiques pour l’analyse des données complexes (données massives, données mal structurées…)', 'C2', 3),
('AC32.04', 'Comprendre les mécanismes de bases de l’intelligence artificielle (apprentissage statistique supervisé, échantillons d''apprentissage et échantillons de test…)', 'C2', 3),
('AC33.01', 'Savoir transformer la donnée pour la mettre en conformité avec des normes (anonymisation, normalisation)', 'C3', 3),
('AC33.02', 'Mesurer l''impact d''un respect de la législation en terme de droit des données.', 'C3', 3),
('AC33.03', 'Identifier les clés d''une bonne communication (procédures et techniques utilisées)', 'C3', 3),
('AC33.04', 'Mesurer l’importance de comprendre et de répondre à l''ensemble des problématiques posées', 'C3', 3),
('AC33.05', 'Être force de proposition', 'C3', 3),
('AC33.06', 'Prendre conscience de la nécessité d’intégrer la vision de l’interlocuteur (transversalité, international, multiculture, niveau d’expertise…)', 'C3', 3),
('AC34.01VCOD', 'Prendre conscience de la nécessité d’utiliser des moyens spécifiques pour exploiter les Big Data ou les flux de données', 'C4', 2),
('AC34.02VCOD', 'Défendre ses choix de solution par un argumentaire éclairé', 'C4', 2),
('AC34.03VCOD', 'Réaliser l’intérêt d’appliquer les méthodes de développement dans la réalisation d’un projet informatique', 'C4', 2),
('AC34.04VCOD', 'Apprécier l’intérêt de l’utilisation d’un gestionnaire de versions de code', 'C4', 2);

-- SAÉ, stages et portfolios du parcours VCOD (PN 2022)
-- À vérifier dans le PN : compétences de SAE3.03 et SAE3.VCOD.04 (fiches tronquées à la lecture)
INSERT INTO sae (code_sae, intitule, type, semestre, parcours) VALUES
('SAE1.01', 'Reporting à partir de données stockées dans un SGBD relationnel', 'SAÉ', 1, NULL),
('SAE1.02', 'Écriture et lecture de fichiers de données', 'SAÉ', 1, NULL),
('SAE1.03', 'Préparation et synthèse d''un tableau de données en vue d''une analyse exploratoire simple', 'SAÉ', 1, NULL),
('SAE1.04', 'Apprendre en situation la production de données en entreprise', 'SAÉ', 1, NULL),
('SAE1.05', 'Présentation en anglais d''un territoire économique et culturel', 'SAÉ', 1, NULL),
('SAE1.06', 'Mise en œuvre d''une enquête', 'SAÉ', 1, NULL),
('PORTFOLIO.S1', 'Démarche portfolio', 'Portfolio', 1, NULL),
('SAE2.01', 'Conception et implémentation d''une base de données', 'SAÉ', 2, NULL),
('SAE2.02', 'Estimation par échantillonnage', 'SAÉ', 2, NULL),
('SAE2.03', 'Régression sur données réelles', 'SAÉ', 2, NULL),
('SAE2.04', 'Datavisualisation', 'SAÉ', 2, NULL),
('SAE2.05', 'Construction et présentation d''indicateurs de performance', 'SAÉ', 2, NULL),
('SAE2.06', 'Analyse de données, reporting et datavisualisation', 'SAÉ', 2, NULL),
('PORTFOLIO.S2', 'Démarche portfolio', 'Portfolio', 2, NULL),
('SAE3.VCOD.01', 'Collecte automatisée de données web', 'SAÉ', 3, 'VCOD'),
('SAE3.02', 'Intégration de données dans un datawarehouse', 'SAÉ', 3, NULL),
('SAE3.03', 'Description et prévision de données temporelles', 'SAÉ', 3, NULL),
('SAE3.VCOD.04', 'Conformité réglementaire pour traiter des données', 'SAÉ', 3, 'VCOD'),
('PORTFOLIO.S3', 'Démarche portfolio', 'Portfolio', 3, 'VCOD'),
('SAE4.VCOD.01', 'Développement d''un composant d''une solution décisionnelle', 'SAÉ', 4, 'VCOD'),
('SAE4.02', 'Reporting d''une analyse multivariée', 'SAÉ', 4, NULL),
('STAGE.S4', 'Stage', 'Stage', 4, 'VCOD'),
('PORTFOLIO.S4', 'Démarche portfolio', 'Portfolio', 4, 'VCOD'),
('SAE5.VCOD.01', 'Analyse et conception d''un outil décisionnel', 'SAÉ', 5, 'VCOD'),
('SAE5.02', 'Migration de données vers ou depuis un environnement NoSQL', 'SAÉ', 5, NULL),
('SAE5.03', 'Mise en œuvre d''un processus de datamining', 'SAÉ', 5, NULL),
('PORTFOLIO.S5', 'Démarche portfolio', 'Portfolio', 5, 'VCOD'),
('SAE6.VCOD.01', 'Développement et test d''un outil décisionnel', 'SAÉ', 6, 'VCOD'),
('STAGE.S6', 'Stage', 'Stage', 6, 'VCOD'),
('PORTFOLIO.S6', 'Démarche portfolio', 'Portfolio', 6, 'VCOD');

INSERT INTO sae_competence (code_sae, id_competence) VALUES
('SAE1.01', 'C1'),
('SAE1.02', 'C1'),
('SAE1.03', 'C2'),
('SAE1.04', 'C3'),
('SAE1.05', 'C3'),
('SAE1.06', 'C3'),
('PORTFOLIO.S1', 'C1'),
('PORTFOLIO.S1', 'C2'),
('PORTFOLIO.S1', 'C3'),
('SAE2.01', 'C1'),
('SAE2.02', 'C2'),
('SAE2.03', 'C2'),
('SAE2.04', 'C1'),
('SAE2.04', 'C2'),
('SAE2.04', 'C3'),
('SAE2.05', 'C3'),
('SAE2.06', 'C1'),
('SAE2.06', 'C2'),
('SAE2.06', 'C3'),
('PORTFOLIO.S2', 'C1'),
('PORTFOLIO.S2', 'C2'),
('PORTFOLIO.S2', 'C3'),
('SAE3.VCOD.01', 'C1'),
('SAE3.VCOD.01', 'C2'),
('SAE3.VCOD.01', 'C3'),
('SAE3.VCOD.01', 'C4'),
('SAE3.02', 'C1'),
('SAE3.02', 'C3'),
('SAE3.03', 'C2'),
('SAE3.03', 'C3'),
('SAE3.VCOD.04', 'C1'),
('SAE3.VCOD.04', 'C2'),
('SAE3.VCOD.04', 'C3'),
('PORTFOLIO.S3', 'C1'),
('PORTFOLIO.S3', 'C2'),
('PORTFOLIO.S3', 'C3'),
('PORTFOLIO.S3', 'C4'),
('SAE4.VCOD.01', 'C1'),
('SAE4.VCOD.01', 'C3'),
('SAE4.VCOD.01', 'C4'),
('SAE4.02', 'C1'),
('SAE4.02', 'C2'),
('SAE4.02', 'C3'),
('STAGE.S4', 'C1'),
('STAGE.S4', 'C2'),
('STAGE.S4', 'C3'),
('STAGE.S4', 'C4'),
('PORTFOLIO.S4', 'C1'),
('PORTFOLIO.S4', 'C2'),
('PORTFOLIO.S4', 'C3'),
('PORTFOLIO.S4', 'C4'),
('SAE5.VCOD.01', 'C1'),
('SAE5.VCOD.01', 'C2'),
('SAE5.VCOD.01', 'C3'),
('SAE5.VCOD.01', 'C4'),
('SAE5.02', 'C1'),
('SAE5.02', 'C3'),
('SAE5.03', 'C2'),
('SAE5.03', 'C3'),
('PORTFOLIO.S5', 'C1'),
('PORTFOLIO.S5', 'C2'),
('PORTFOLIO.S5', 'C3'),
('PORTFOLIO.S5', 'C4'),
('SAE6.VCOD.01', 'C1'),
('SAE6.VCOD.01', 'C2'),
('SAE6.VCOD.01', 'C3'),
('SAE6.VCOD.01', 'C4'),
('STAGE.S6', 'C1'),
('STAGE.S6', 'C2'),
('STAGE.S6', 'C3'),
('STAGE.S6', 'C4'),
('PORTFOLIO.S6', 'C1'),
('PORTFOLIO.S6', 'C2'),
('PORTFOLIO.S6', 'C3'),
('PORTFOLIO.S6', 'C4');

-- Les 254 matières du programme et leurs heures (version complète fournie en cours)
-- Correction : les 13 matières de programmation de BUT1 rattachées à C4 dans le fichier
-- d'origine sont rattachées à C1, car C4 ne commence qu'en BUT2 (programme national)
INSERT INTO activite_pedagogique (semestre, heure, skill, id_competence) VALUES
(1, 15, 'Etude données envt ent & éco (intro marketing)', 'C3'),
(1, 22, 'Base de données relationnelles 1', 'C1'),
(1, 40, 'Statistique descriptive 1', 'C2'),
(1, 19, 'Bases de la programmation 2', 'C1'),
(1, 4, 's1 Analyse des données d''une enquete', 'C2'),
(1, 15, 'Bases de l''algèbre', 'C2'),
(1, 22, 'Probabilités 1', 'C2'),
(1, 15, 'Bases de la programmation 1', 'C1'),
(1, 38, 'Découverte données entrepreunarial et économique', 'C3'),
(1, 6, 'Statistique descriptive 1 (TP)', 'C2'),
(1, 7, 'PPP - tutorat 1P', 'C3'),
(1, 4, 'Projet Personnel et Professionnel 1', 'C3'),
(1, 1, 'Bases de l''algèbre', 'C2'),
(1, 3, 'Probabilités 1 (machine)', 'C2'),
(1, 5, 'Bases de la programmation 1', 'C1'),
(1, 4, 'Statistique descriptive 1', 'C2'),
(1, 10, 'Bases de la programmation 1 (TP)', 'C1'),
(1, 8, 'Base de données relationnelles 1 (TP)', 'C1'),
(1, 4, 'Probabilités 1', 'C2'),
(1, 6, 's1 Communication de l''information : l''enquête', 'C3'),
(1, 2, 'Découverte données entrepreunarial et économique', 'C3'),
(1, 7, 'Projet Personnel et Professionnel 1 (autonomie)', 'C3'),
(1, 8, 's1 Communication de l''information et recherche documentaire', 'C3'),
(1, 6, 'Bases de la programmation 2 (TP)', 'C1'),
(1, 2, 'Projet Personnel et Professionnel 1 : fiches métiers', 'C3'),
(1, 2, 'Bases de la programmation 2', 'C1'),
(1, 6, 'Découverte données entrepreunarial et économique (autonomie)', 'C3'),
(1, 2, 'Bases de la programmation 1 (CJ)', 'C1'),
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
(1, 6, 'Programmation statistique (VBA)', 'C1'),
(1, 3, 'Apprendre en situation la prod°de données en entreprise (autonomi e)', 'C3'),
(1, 1, 'Méthodologie du travail universitaire', 'C3'),
(1, 3, 'Conférence métier (INSEE stat)', 'C3'),
(1, 2, 'PPP2 : Le métier d''Enseigant-Chercheur', 'C3'),
(1, 1, 'Présentation alternance (par mme Joly)', 'C3'),
(1, 3, 'Présentation en anglais territoire economique culturel', 'C3'),
(1, 3, 'Reporting et datavisualisation CJ', 'C3'),
(1, 2, 'rentrée PEC SD', 'C3'),
(1, 3, 'Présentation en anglais territoire économique culturel', 'C3'),
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
(2, 5, 'Programmation statistique (R TD)', 'C1'),
(2, 25, 'Anglais de spécialité', 'C3'),
(2, 10, 'Portfolio (non encadré)', 'C3'),
(2, 6, 'Programmation statistique (QGIS)', 'C1'),
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
(2, 4, 'Programmation statistique (VBA)', 'C1'),
(2, 4, 'Analyse de données reporting et datavisualisation (rapport)', 'C3'),
(2, 1, 'Préparation et synthèse tableau de données pour analyse (projet)', 'C1'),
(2, 1, 'Mathématiques - Analyse (CJ)', 'C2'),
(2, 3, 'Fresque du climat', 'C3'),
(2, 1, 'Reporting et datavisualisation CF', 'C3'),
(2, 3, 'Conception et implémentation d''une base de données (projet)', 'C1'),
(2, 4, 'Programmation statistique (R TP)', 'C1'),
(2, 1, 'Conseil de département', 'C3'),
(2, 1, 'Prog - bonnes pratiques', 'C1'),
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

-- Vue : heures par année et par compétence
CREATE VIEW heures_par_annee AS
SELECT s.id_annee, a.id_competence, SUM(a.heure) AS total_heures, COUNT(*) AS nb_activites
FROM activite_pedagogique a
JOIN semestre s ON s.numero = a.semestre
GROUP BY s.id_annee, a.id_competence
ORDER BY s.id_annee, a.id_competence;

-- ############################################################################
--  2. MON PARCOURS
--  Sources : mon profil LinkedIn, mes certificats, data/projets.csv
-- ############################################################################
SET search_path = portfolio, referentiel;

CREATE TYPE portfolio.type_experience AS ENUM ('Alternance', 'Stage', 'Expérience académique', 'Engagement');
CREATE TYPE portfolio.type_projet AS ENUM ('Projet de formation', 'Projet personnel');
CREATE TYPE portfolio.type_certificat AS ENUM ('Certificat', 'Distinction');
CREATE TYPE portfolio.niveau_langue AS ENUM ('Élémentaire', 'Professionnel', 'Langue maternelle ou bilingue');
CREATE TYPE portfolio.niveau_acquisition AS ENUM ('Non acquis', 'En cours d''acquisition', 'Acquis');

CREATE TABLE formation (
    id_formation  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    diplome       text NOT NULL,
    etablissement text NOT NULL,
    lieu          text,
    date_debut    date NOT NULL,
    date_fin      date,                                  -- vide = en cours
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

CREATE TABLE experience (
    id_experience integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    intitule      text NOT NULL,
    structure     text NOT NULL,
    type          type_experience NOT NULL,
    lieu          text,
    date_debut    date NOT NULL,
    date_fin      date,
    description   text,
    code_sae      varchar(16) REFERENCES referentiel.sae(code_sae),   -- stage du BUT : SAÉ « Stage »
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
);

CREATE TABLE projet (
    id_projet   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre       text NOT NULL UNIQUE,
    type        type_projet NOT NULL,
    annee       smallint CHECK (annee BETWEEN 2020 AND 2030),   -- vide = à confirmer
    description text,
    lien        text CHECK (lien ~ '^https://'),
    code_sae    varchar(16) REFERENCES referentiel.sae(code_sae)  -- projet réalisé dans une SAÉ
);
CREATE INDEX ON projet (code_sae);

CREATE TABLE technologie (
    id_techno integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom       text NOT NULL UNIQUE,
    categorie text NOT NULL CHECK (categorie IN ('Langage', 'Base de données', 'Visualisation',
                                                 'Machine learning', 'Statistique', 'Data engineering', 'Web', 'Outil'))
);

-- Un projet utilise plusieurs technologies, une technologie sert à plusieurs projets (N-N)
CREATE TABLE projet_technologie (
    id_projet integer NOT NULL REFERENCES projet(id_projet) ON DELETE CASCADE,
    id_techno integer NOT NULL REFERENCES technologie(id_techno) ON DELETE CASCADE,
    PRIMARY KEY (id_projet, id_techno)
);
CREATE INDEX ON projet_technologie (id_techno);

CREATE TABLE certificat (
    id_certificat  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    intitule       text NOT NULL,
    organisme      text,                 -- vide = à confirmer
    type           type_certificat NOT NULL,
    date_obtention date,                 -- vide = à confirmer
    fichier        text,                 -- image dans client/preuves/
    document       text,                 -- PDF dans client/preuves/
    lien           text CHECK (lien ~ '^https://'),          -- page publique (annonce, vérification)
    site_officiel  text CHECK (site_officiel ~ '^https://'), -- site officiel de l'organisme ou du cours
    description    text
);

CREATE TABLE langue (
    id_langue integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom       text NOT NULL UNIQUE,
    niveau    niveau_langue NOT NULL
);

-- Une preuve : vient d'UN projet, d'UNE expérience ou d'UN certificat,
-- se rattache à UNE SAÉ au plus, et démontre UN OU PLUSIEURS AC (table preuve_ac)
CREATE TABLE preuve (
    id_preuve     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre         text NOT NULL UNIQUE,
    texte         text NOT NULL,                     -- ce que la preuve montre
    code_sae      varchar(16) REFERENCES referentiel.sae(code_sae),
    id_projet     integer REFERENCES projet(id_projet) ON DELETE CASCADE,
    id_experience integer REFERENCES experience(id_experience) ON DELETE CASCADE,
    id_certificat integer REFERENCES certificat(id_certificat) ON DELETE CASCADE,
    CHECK (num_nonnulls(id_projet, id_experience, id_certificat) = 1)    -- une seule source
);
CREATE INDEX ON preuve (code_sae);
CREATE INDEX ON preuve (id_projet);
CREATE INDEX ON preuve (id_experience);
CREATE INDEX ON preuve (id_certificat);

-- Une preuve démontre plusieurs AC, un AC est démontré par plusieurs preuves (N-N)
CREATE TABLE preuve_ac (
    id_preuve integer NOT NULL REFERENCES preuve(id_preuve) ON DELETE CASCADE,
    code_ac   referentiel.code_ac NOT NULL REFERENCES referentiel.apprentissage_critique(code_ac),
    PRIMARY KEY (id_preuve, code_ac)
);
CREATE INDEX ON preuve_ac (code_ac);

-- Une preuve a zéro, une ou plusieurs captures d'écran, dans un ordre donné (1-N)
CREATE TABLE preuve_image (
    id_preuve integer  NOT NULL REFERENCES preuve(id_preuve) ON DELETE CASCADE,
    ordre     smallint NOT NULL CHECK (ordre > 0),
    fichier   text     NOT NULL UNIQUE CHECK (fichier ~ '^[a-z0-9_]+\.(png|jpg)$'),  -- dans client/preuves/
    legende   text,
    PRIMARY KEY (id_preuve, ordre)
);

-- Auto-évaluation de chaque AC (fiches portfolio) et visa du tuteur s'il existe
CREATE TABLE evaluation_ac (
    code_ac         referentiel.code_ac PRIMARY KEY REFERENCES referentiel.apprentissage_critique(code_ac),
    auto_evaluation niveau_acquisition NOT NULL,
    visa_tuteur     niveau_acquisition                -- vide = pas encore de visa
);

-- Règle de cohérence : si la preuve est rattachée à une SAÉ, chaque AC démontré
-- doit appartenir à une compétence ciblée par cette SAÉ (programme national)
CREATE FUNCTION portfolio.verifier_ac_dans_sae() RETURNS trigger AS $$
DECLARE
    sae_preuve varchar(16);
BEGIN
    SELECT code_sae INTO sae_preuve FROM portfolio.preuve WHERE id_preuve = NEW.id_preuve;
    IF sae_preuve IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM referentiel.apprentissage_critique ac
        JOIN referentiel.sae_competence sc ON sc.id_competence = ac.id_competence
        WHERE ac.code_ac = NEW.code_ac AND sc.code_sae = sae_preuve
    ) THEN
        RAISE EXCEPTION 'L''AC % n''appartient à aucune compétence ciblée par la SAÉ %', NEW.code_ac, sae_preuve;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER preuve_ac_coherence
BEFORE INSERT OR UPDATE ON preuve_ac
FOR EACH ROW EXECUTE FUNCTION portfolio.verifier_ac_dans_sae();

-- ----------------------------------------------------------------------------
--  Données
-- ----------------------------------------------------------------------------
INSERT INTO formation (diplome, etablissement, lieu, date_debut, date_fin) VALUES
('BUT Science des données, parcours VCOD', 'IUT de Besançon-Vesoul (antenne de Dôle)', 'Dôle', '2025-09-01', '2027-06-30'),
('BUT Science des données (1re année)', 'IUT de Vannes', 'Vannes', '2024-09-01', '2025-06-30'),
('Ingénierie informatique et télécommunications', 'Instituto Superior de Transportes e de Comunicações (ISUTC)', 'Mozambique', '2023-02-01', '2024-05-31'),
('Baccalauréat Mathématiques et Sciences naturelles', 'Escola Secundária « 29 de Setembro »', 'Maxixe, Mozambique', '2021-02-01', '2022-12-31');

INSERT INTO experience (intitule, structure, type, lieu, date_debut, date_fin, description, code_sae) VALUES
('Data scientist apprentie', 'Colas', 'Alternance', 'Nouvelle-Aquitaine', '2026-09-01', NULL,
 'Alternance en data science, en parallèle de la 3e année de BUT.', NULL),
('Stage d''été data analyst junior', 'SFMI', 'Stage', 'Charquemont', '2026-07-01', '2026-08-31',
 'Stage d''été, en dehors du stage officiel du BUT. Conception d''une application de covoiturage interne avec navettes en temps réel. Dashboard de pilotage industriel avec gestion des rôles et requêtes SQL Server.', NULL),
('Cheffe de projet data (stage officiel du BUT)', 'Serviciale', 'Stage', 'Metz', '2026-04-01', '2026-06-30',
 'Seule ressource data science et développeuse full stack d''une marketplace de services à domicile, sous la direction du CEO. Score de fiabilité multicritère validé par simulation Monte Carlo, détection d''anomalies (IsolationForest), tableau de bord Dash/Plotly et suite de 132 tests automatisés en CI/CD.', 'STAGE.S4'),
('Analyste de données junior (projet académique)', 'IUT de Vannes', 'Expérience académique', 'Vannes', '2024-09-01', '2025-06-30',
 'Modèles prédictifs et projets collaboratifs d''analyse de données, avec identification des besoins métier et production de rapports.', NULL),
('Membre', 'The New York Academy of Sciences', 'Engagement', 'À distance', '2022-06-01', '2024-01-31',
 'Projets collaboratifs internationaux, communication interculturelle et travail en équipe à distance.', NULL);

INSERT INTO projet (titre, type, annee, description, code_sae) VALUES
('Portfolio de visualisation de données', 'Projet de formation', 2026,
 'Ce site : base PostgreSQL lancée dans Docker, serveur Express qui expose une API, pages qui affichent les données avec Chart.js.', 'PORTFOLIO.S5'),
('Analyse multivariée de candidatures (SAÉ 4.02)', 'Projet de formation', 2026,
 'Restitution d''une analyse multivariée des candidatures à la filière Santé de l''UBFC : préparation avec KNIME, anonymisation avec ARX (k-anonymat k = 5, l-diversité l = 3), ACM puis classification ascendante hiérarchique en 3 classes, application R Shiny pour un commanditaire non statisticien. Projet en équipe de 3 : 80 h au total, dont 41 h pour ma part (anonymisation, application Shiny et analyse statistique).', 'SAE4.02'),
('Atlas démographique des communes françaises', 'Projet personnel', 2026,
 'Exploration et visualisation des données INSEE 2016-2022 sur les communes françaises.', NULL),
('BRICOLIB : location d''outils de bricolage (SAÉ)', 'Projet de formation', 2025,
 'Cartographie des offres et demandes de location d''outils en France, modèles prédictifs et tableaux de bord interactifs sous Power BI.', NULL),
('Plateforme de données FactoryFlow', 'Projet personnel', NULL,
 'Plateforme de données de bout en bout : orchestration avec Airflow, transformations avec dbt, modèles scikit-learn et interface Streamlit.', NULL);

INSERT INTO technologie (nom, categorie) VALUES
('Python', 'Langage'), ('R', 'Langage'), ('JavaScript', 'Langage'), ('SQL', 'Langage'),
('PostgreSQL', 'Base de données'), ('pandas', 'Data engineering'), ('dbt', 'Data engineering'), ('Airflow', 'Data engineering'),
('matplotlib', 'Visualisation'), ('Plotly', 'Visualisation'), ('Power BI', 'Visualisation'), ('Shiny', 'Visualisation'),
('Streamlit', 'Visualisation'), ('Chart.js', 'Visualisation'), ('scikit-learn', 'Machine learning'), ('HTML', 'Web'),
('Node.js', 'Web'), ('Express', 'Web'), ('KNIME', 'Outil'), ('ARX', 'Outil'),
('Docker', 'Outil'), ('Leaflet', 'Visualisation'), ('FactoMineR', 'Statistique');

-- (titre du projet, nom de la technologie) : on retrouve les identifiants par jointure
INSERT INTO projet_technologie (id_projet, id_techno)
SELECT p.id_projet, t.id_techno
FROM (VALUES
    ('Portfolio de visualisation de données', 'PostgreSQL'),
    ('Portfolio de visualisation de données', 'SQL'),
    ('Portfolio de visualisation de données', 'Docker'),
    ('Portfolio de visualisation de données', 'Node.js'),
    ('Portfolio de visualisation de données', 'Express'),
    ('Portfolio de visualisation de données', 'JavaScript'),
    ('Portfolio de visualisation de données', 'HTML'),
    ('Portfolio de visualisation de données', 'Chart.js'),
    ('Analyse multivariée de candidatures (SAÉ 4.02)', 'KNIME'),
    ('Analyse multivariée de candidatures (SAÉ 4.02)', 'ARX'),
    ('Analyse multivariée de candidatures (SAÉ 4.02)', 'R'),
    ('Analyse multivariée de candidatures (SAÉ 4.02)', 'Shiny'),
    ('Analyse multivariée de candidatures (SAÉ 4.02)', 'FactoMineR'),
    ('Analyse multivariée de candidatures (SAÉ 4.02)', 'Leaflet'),
    ('Atlas démographique des communes françaises', 'Python'),
    ('Atlas démographique des communes françaises', 'pandas'),
    ('Atlas démographique des communes françaises', 'matplotlib'),
    ('Atlas démographique des communes françaises', 'Plotly'),
    ('Atlas démographique des communes françaises', 'HTML'),
    ('BRICOLIB : location d''outils de bricolage (SAÉ)', 'Power BI'),
    ('Plateforme de données FactoryFlow', 'Python'),
    ('Plateforme de données FactoryFlow', 'PostgreSQL'),
    ('Plateforme de données FactoryFlow', 'dbt'),
    ('Plateforme de données FactoryFlow', 'Airflow'),
    ('Plateforme de données FactoryFlow', 'scikit-learn'),
    ('Plateforme de données FactoryFlow', 'Streamlit')
) AS v(titre, nom)
JOIN projet p ON p.titre = v.titre
JOIN technologie t ON t.nom = v.nom;

INSERT INTO certificat (intitule, organisme, type, date_obtention, fichier, document, lien, site_officiel, description) VALUES
('Databricks Fundamentals Accreditation', 'Databricks', 'Certificat', '2026-08-01', 'certificat_databricks.png', 'certificat_databricks.pdf', NULL,
 'https://www.databricks.com/training/catalog/databricks-fundamentals-accreditation-2308',
 'Accréditation Databricks Academy : questionnaire de 20 questions sur la plateforme Databricks Data Intelligence Platform.'),
('AWS Database Offerings', 'AWS Training & Certification', 'Certificat', '2025-07-21', 'certificat_aws.png', 'certificat_aws.pdf', NULL,
 'https://aws.amazon.com/getting-started/use-cases/databases',
 'Cours en autonomie d''AWS : panorama des technologies et architectures de bases de données (relationnelles, non relationnelles, migration, serverless) et des services de bases de données AWS.'),
('CS403 : Introduction to Modern Database Systems (42 h)', 'Saylor Academy', 'Certificat', '2025-07-21', 'certificat_cs403.png', 'certificat_cs403.pdf', NULL,
 'https://learn.saylor.org/course/CS403',
 'Cours de 42 heures validé par un examen final : histoire des bases de données, modèle entité-association, modèle relationnel, algèbre relationnelle, normalisation et SQL.'),
('Introduction to Career Skills in Data Analytics', 'LinkedIn Learning', 'Certificat', '2025-07-20', 'certificat_data_analytics.png', 'certificat_data_analytics.pdf', NULL,
 'https://www.linkedin.com/learning/',
 'Cours de 2 h 21 min. Compétences couvertes : analyse de données et compétences pour une carrière dans la tech.'),
('Introduction to Career Skills in Software Development', 'LinkedIn Learning (Microsoft et LinkedIn)', 'Certificat', NULL, NULL, NULL, NULL,
 'https://www.linkedin.com/learning/',
 'Premier cours du parcours « Career Essentials in Software Development » de Microsoft et LinkedIn : bases de la programmation.'),
('AI Fluency for Students', 'Anthropic Academy', 'Certificat', NULL, NULL, NULL, NULL,
 'https://anthropic.skilljar.com/ai-fluency-for-students',
 'Cours sur la collaboration responsable avec l''IA dans les études et la carrière, autour du cadre des 4D : délégation, description, discernement, diligence.'),
('Opérateur informatique (B.A. en ELT)', NULL, 'Certificat', NULL, NULL, NULL, NULL, NULL, NULL),
('Gazprom Olympiad', 'Université électrotechnique de Saint-Pétersbourg « LETI »', 'Certificat', NULL, NULL, NULL, NULL,
 'https://etu.ru/en/university',
 'Olympiade Gazprom organisée à l''université électrotechnique de Saint-Pétersbourg « LETI ».'),
('2e prix du concours « Ler nas Férias » (Lire en vacances), 3e édition 2023/2024', 'Ethale Publishing', 'Distinction', NULL, NULL, 'publication_caminhos_da_leitura_extrait.pdf', NULL,
 'https://www.ethalebooks.com',
 'Concours littéraire de la maison d''édition mozambicaine Ethale Publishing : les participants résument et analysent un livre de son catalogue. La 3e édition a réuni 304 adolescents et jeunes. Mon texte sur « As Madames » de Zukiswa Wanner est publié dans l''anthologie « Caminhos da Leitura » (2024).'),
('Runner-up du BSGCT Scientific Writing Competition 2026 : « Rewriting the Code of Life: How Gene Editing is Curing Sickle Cell Disease »', 'British Society for Gene and Cell Therapy (BSGCT)', 'Distinction', '2026-04-22', NULL, NULL,
 'https://bsgct.org/bsgct-scientific-writing-competition-runner-up-rewriting-the-code-of-life/',
 'https://bsgct.org/scientific-writing-competition-2026/',
 'Concours de rédaction scientifique de la British Society for Gene and Cell Therapy. Mon article, classé parmi les runners-up, explique comment les thérapies fondées sur CRISPR transforment le traitement de la drépanocytose et ce qu''elles annoncent pour la médecine génétique.');

-- Publications : textes publiés, éventuellement issus d'un concours (distinction)
CREATE TABLE publication (
    id_publication integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre          text NOT NULL,
    ouvrage        text NOT NULL,
    editeur        text NOT NULL,
    isbn           varchar(17) CHECK (isbn ~ '^97[89]-[0-9]+-[0-9]+-[0-9]+-[0-9]$'),
    date_parution  date NOT NULL,
    langue         text NOT NULL,
    pages          int4range,                        -- pages du texte dans l'ouvrage
    resume         text,
    fichier        text,                             -- aperçu dans client/preuves/
    document       text,                             -- extrait PDF dans client/preuves/
    id_certificat  integer REFERENCES certificat(id_certificat)   -- distinction liée
);

INSERT INTO publication (titre, ouvrage, editeur, isbn, date_parution, langue, pages, resume, fichier, document, id_certificat) VALUES
('Entre Raças e Papéis: A Nova Realidade das Madames',
 'Caminhos da Leitura: O que dizem os nossos leitores? (coord. Jennifer Banze)',
 'Ethale Publishing, Maputo', '978-989-9318-02-1', '2024-11-01', 'Portugais', '[18,21)',
 'Analyse du roman « As Madames » de Zukiswa Wanner : féminisme, rapports sociaux et inégalités dans l''Afrique du Sud post-apartheid. Texte retenu dans l''anthologie issue de la 3e édition du concours « Ler nas Férias ».',
 'publication_caminhos_da_leitura.png', 'publication_caminhos_da_leitura_extrait.pdf',
 (SELECT id_certificat FROM certificat WHERE intitule LIKE '2e prix du concours%'));

INSERT INTO langue (nom, niveau) VALUES
('Portugais', 'Langue maternelle ou bilingue'), ('Anglais', 'Langue maternelle ou bilingue'),
('Français', 'Professionnel'), ('Espagnol', 'Professionnel'), ('Russe', 'Élémentaire');

-- Preuves : tirées de mes fiches portfolio (fiches AC, fiche SAÉ 4.02, fiche de stage), ajoutées petit à petit.
-- Les preuves du stage sont décrites sans capture : la plateforme du stage est confidentielle.
INSERT INTO preuve (titre, texte, code_sae, id_projet, id_experience, id_certificat) VALUES
('Préparation des variables des candidats',
 'La fonction de chargement structure les variables (sexe, statut boursier, type de bac, zone géographique) après avoir compris la logique de la filière Santé de l''UBFC.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL),
('Unification de la palette de couleurs',
 'Les graphiques de classification utilisaient deux palettes différentes ; une palette unique et une légende explicite ont corrigé l''incohérence.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL),
('Packages R de l''application Shiny',
 'L''application s''appuie sur des packages existants : shiny et shinydashboard, FactoMineR et factoextra, leaflet, DT, ggplot2.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL),
('Classification sur les résultats de l''ACM',
 'La classification (fonction HCPC de FactoMineR) explore la structure des données sans hypothèse préalable sur les groupes : c''est de l''exploration, pas de la modélisation.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL),
('ACM sur les variables qualitatives des candidats',
 'L''analyse des correspondances multiples résume l''information portée par de nombreuses variables qualitatives en quelques axes.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL),
('CAH, dendrogramme et courbe d''inertie',
 'La classification ascendante hiérarchique sur les coordonnées de l''ACM forme des groupes homogènes ; le nombre de classes est choisi avec la courbe d''inertie.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL),
('Limite : la zone géographique est une variable active',
 'La zone géographique a servi à construire les classes : dire qu''elle est le facteur le plus discriminant est en partie circulaire. L''interprétation est reformulée en homogénéité des profils dans une même zone.',
 'SAE4.02', (SELECT id_projet FROM projet WHERE titre = 'Analyse multivariée de candidatures (SAÉ 4.02)'), NULL, NULL);

-- (titre de la preuve, AC démontré) : le déclencheur vérifie chaque ligne
INSERT INTO preuve_ac (id_preuve, code_ac)
SELECT p.id_preuve, v.code_ac
FROM (VALUES
    ('Préparation des variables des candidats', 'AC21.01'),
    ('Unification de la palette de couleurs', 'AC21.04'),
    ('Packages R de l''application Shiny', 'AC21.05'),
    ('Classification sur les résultats de l''ACM', 'AC22.01'),
    ('ACM sur les variables qualitatives des candidats', 'AC22.03'),
    ('CAH, dendrogramme et courbe d''inertie', 'AC22.03'),
    ('Limite : la zone géographique est une variable active', 'AC22.05')
) AS v(titre, code_ac)
JOIN preuve p ON p.titre = v.titre;

-- Captures d'écran des preuves (dans client/preuves/)
INSERT INTO preuve_image (id_preuve, ordre, fichier, legende)
SELECT p.id_preuve, v.ordre, v.fichier, v.legende
FROM (VALUES
    ('Préparation des variables des candidats', 1, 's402_data_preparation.png', NULL),
    ('Unification de la palette de couleurs', 1, 's402_palette_code.png', 'Code'),
    ('Unification de la palette de couleurs', 2, 's402_palette_rapport.png', 'Rapport de modifications'),
    ('Packages R de l''application Shiny', 1, 's402_packages.png', NULL),
    ('Classification sur les résultats de l''ACM', 1, 's402_hcpc.png', NULL),
    ('ACM sur les variables qualitatives des candidats', 1, 's402_acm.png', NULL),
    ('CAH, dendrogramme et courbe d''inertie', 1, 's402_dendrogramme.png', 'Code du dendrogramme'),
    ('CAH, dendrogramme et courbe d''inertie', 2, 's402_courbe_inertie.png', 'Onglet Classification de l''application'),
    ('Limite : la zone géographique est une variable active', 1, 's402_limite_code.png', 'Code'),
    ('Limite : la zone géographique est une variable active', 2, 's402_limite_rapport.png', 'Rapport de changements')
) AS v(titre, ordre, fichier, legende)
JOIN preuve p ON p.titre = v.titre;

-- Auto-évaluation des AC (fiches portfolio) ; visa du tuteur pour la compétence Traiter niveau 2.
-- Les AC de la compétence Valoriser ne sont pas évalués dans les fiches : pas de ligne.
INSERT INTO evaluation_ac (code_ac, auto_evaluation, visa_tuteur) VALUES
('AC21.01', 'Acquis', 'Acquis'),
('AC21.02', 'Acquis', 'Acquis'),
('AC21.03', 'En cours d''acquisition', 'En cours d''acquisition'),
('AC21.04', 'Acquis', 'Acquis'),
('AC21.05', 'En cours d''acquisition', 'Acquis'),
('AC22.01', 'En cours d''acquisition', NULL),
('AC22.02', 'En cours d''acquisition', NULL),
('AC22.03', 'En cours d''acquisition', NULL),
('AC22.04', 'Acquis', NULL),
('AC22.05', 'Acquis', NULL),
('AC24.01VCOD', 'Acquis', NULL),
('AC24.02VCOD', 'Acquis', NULL),
('AC24.03VCOD', 'En cours d''acquisition', NULL),
('AC24.04VCOD', 'Acquis', NULL);

-- ----------------------------------------------------------------------------
--  Vues utilisées par le site
-- ----------------------------------------------------------------------------
-- Couverture du référentiel : pour chaque AC, le nombre de preuves qui le démontrent
CREATE VIEW couverture_ac AS
SELECT ac.code_ac, ac.intitule, ac.id_competence, ac.numero_niveau, n.id_annee,
       COUNT(pa.id_preuve) AS nb_preuves,
       ev.auto_evaluation, ev.visa_tuteur
FROM referentiel.apprentissage_critique ac
JOIN referentiel.niveau n ON n.id_competence = ac.id_competence AND n.numero = ac.numero_niveau
LEFT JOIN preuve_ac pa ON pa.code_ac = ac.code_ac
LEFT JOIN evaluation_ac ev ON ev.code_ac = ac.code_ac
GROUP BY ac.code_ac, n.id_annee, ev.auto_evaluation, ev.visa_tuteur
ORDER BY ac.code_ac;

-- Preuves détaillées : source lisible, SAÉ et liste des AC
CREATE VIEW preuve_detail AS
SELECT pr.id_preuve, pr.titre, pr.texte, pr.code_sae, s.intitule AS intitule_sae,
       COALESCE(p.titre, e.intitule || ' · ' || e.structure, c.intitule) AS source,
       CASE WHEN p.id_projet IS NOT NULL THEN 'Projet'
            WHEN e.id_experience IS NOT NULL THEN 'Expérience'
            ELSE 'Certificat' END AS type_source,
       ARRAY_AGG(pa.code_ac::text ORDER BY pa.code_ac) AS codes_ac,  -- ::text : liste lisible par Node
       -- sous-requête : les images ne doivent pas multiplier les lignes des AC
       COALESCE((SELECT JSON_AGG(JSON_BUILD_OBJECT('fichier', pi.fichier, 'legende', pi.legende) ORDER BY pi.ordre)
                 FROM preuve_image pi WHERE pi.id_preuve = pr.id_preuve), '[]') AS images
FROM preuve pr
LEFT JOIN referentiel.sae s ON s.code_sae = pr.code_sae
LEFT JOIN projet p ON p.id_projet = pr.id_projet
LEFT JOIN experience e ON e.id_experience = pr.id_experience
LEFT JOIN certificat c ON c.id_certificat = pr.id_certificat
LEFT JOIN preuve_ac pa ON pa.id_preuve = pr.id_preuve
GROUP BY pr.id_preuve, s.intitule, p.titre, p.id_projet, e.intitule, e.structure, e.id_experience, c.intitule;
