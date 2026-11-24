import express from "express";
import fs from "fs";
import path from "path";
import pkg from "pg";
const { Pool, Client } = pkg;

const app = express();
const PORT = 3000;

// ==============================
// 1️⃣ Configuration PostgreSQL
// ==============================
const DB_CONFIG = {
  host: "localhost",
  user: "postgres",
  password: process.env.POSTGRES_PASSWORD, // mot de passe lu dans le fichier .env (jamais sur GitHub)
  database: "butsd",
  port: 5432,
  options: "-c search_path=portfolio,referentiel"   // les tables sont rangées dans deux schémas
};

const INIT_SQL_FILE = path.resolve("../bdd/init_db.sql"); // le fichier SQL est dans le dossier bdd

// ==============================
// 2️⃣ Fonction pour créer la base si elle n'existe pas
// ==============================
async function ensureDatabase() {
  // Connexion à la base "postgres" par défaut
  const client = new Client({
    host: DB_CONFIG.host,
    user: DB_CONFIG.user,
    password: DB_CONFIG.password,
    database: "postgres",
    port: DB_CONFIG.port
  });

  await client.connect();

  // Vérifier si la base existe
  const res = await client.query(`SELECT 1 FROM pg_database WHERE datname='butsd';`);
  if (res.rowCount === 0) {
    console.log("🛠️  Base 'butsd' inexistante, création en cours...");
    await client.query(`CREATE DATABASE butsd;`);
    console.log("✅ Base 'butsd' créée.");
  } else {
    console.log("ℹ️  Base 'butsd' déjà existante.");
  }

  await client.end();
}

// ==============================
// 3️⃣ Fonction pour exécuter init_db.sql
// ==============================
async function initTables() {
  const sql = fs.readFileSync(INIT_SQL_FILE, "utf-8");
  const pool = new Pool(DB_CONFIG);
  await pool.query(sql);
  await pool.end();
  console.log("✅ Tables et données initialisées depuis init_db.sql");
}

// ==============================
// Afficher le contenu d'une table dans le terminal
// ==============================
const TABLES_AUTORISEES = [
  // schéma referentiel (programme national)
  "annee", "semestre", "competence", "composante_essentielle", "niveau", "apprentissage_critique",
  "sae", "sae_competence", "activite_pedagogique", "heures_par_annee",
  // schéma portfolio (mon parcours)
  "formation", "experience", "projet", "publication", "technologie", "projet_technologie", "certificat", "langue",
  "preuve", "preuve_ac", "preuve_image", "evaluation_ac", "preuve_detail", "couverture_ac"];

async function afficherTable(pool, nomTable) {
  // Un nom de table ne peut pas passer par $1 : on n'accepte que les tables de la liste (anti-injection SQL)
  if (!TABLES_AUTORISEES.includes(nomTable)) {
    console.log(`❌ Table inconnue : ${nomTable}`);
    return;
  }
  const { rows } = await pool.query(`SELECT * FROM ${nomTable};`);
  console.log(`\n📋 Table ${nomTable} : ${rows.length} lignes`);
  console.table(rows.slice(0, 5));   // les 5 premières lignes
}

// ==============================
// 4️⃣ Lancer le serveur après préparation de la base
// ==============================
async function startServer() {
  try {
    await ensureDatabase();
    await initTables();

    const pool = new Pool(DB_CONFIG);

    // Contenu de quelques tables dans le terminal, pour vérifier les données au démarrage
    await afficherTable(pool, "projet");
    await afficherTable(pool, "preuve_detail");

    // Servir le dossier public
    app.use(express.static("../client")); // le site (HTML, CSS, JS, images) est dans le dossier client

    // Route API : total des heures par compétence
    app.get("/api/heures", async (req, res) => {
      try {
        const query = `
          SELECT c.id_competence, c.intitule, SUM(a.heure) AS total_heures
          FROM competence c
          LEFT JOIN activite_pedagogique a ON a.id_competence = c.id_competence
          GROUP BY c.id_competence, c.intitule
          ORDER BY c.id_competence;
        `;
        const { rows } = await pool.query(query);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des données" });
      }
    });

    // Route API : compétences avec description
    app.get("/api/competences", async (req, res) => {
      try {
        const query = `
          SELECT id_competence, verbe, intitule, parcours
          FROM competence
          ORDER BY id_competence;
        `;
        const { rows } = await pool.query(query);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des compétences" });
      }
    });

    // Route API : description d'une compétence spécifique
    app.get("/api/competence/:id", async (req, res) => {
      const { id } = req.params; // ex: C1, C2...
      try {
        const competence = await pool.query(
          "SELECT id_competence, verbe, intitule, parcours FROM competence WHERE id_competence = $1;", [id]);
        if (competence.rows.length === 0) {
          return res.status(404).json({ error: "Compétence non trouvée" });
        }
        const composantes = await pool.query(
          "SELECT code, libelle FROM composante_essentielle WHERE id_competence = $1 ORDER BY code;", [id]);
        const niveaux = await pool.query(`
          SELECT n.numero, n.intitule, n.id_annee,
                 JSON_AGG(JSON_BUILD_OBJECT('code_ac', ac.code_ac, 'intitule', ac.intitule,
                          'auto_evaluation', ev.auto_evaluation, 'visa_tuteur', ev.visa_tuteur) ORDER BY ac.code_ac) AS acs
          FROM niveau n
          JOIN apprentissage_critique ac ON ac.id_competence = n.id_competence AND ac.numero_niveau = n.numero
          LEFT JOIN evaluation_ac ev ON ev.code_ac = ac.code_ac   -- LEFT : un AC sans auto-évaluation reste affiché
          WHERE n.id_competence = $1
          GROUP BY n.numero, n.intitule, n.id_annee
          ORDER BY n.numero;`, [id]);
        res.json({ ...competence.rows[0], composantes: composantes.rows, niveaux: niveaux.rows });
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération de la compétence" });
      }
    });

    // ==============================
    // Routes de mon parcours
    // ==============================

    // Heures par année et par compétence (vue HEURES_PAR_ANNEE)
    app.get("/api/heures-par-annee", async (req, res) => {
      try {
        const { rows } = await pool.query("SELECT * FROM heures_par_annee;");
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des heures par année" });
      }
    });

    // Projets, avec filtres facultatifs : /api/projets?type=Projet personnel&techno=Python
    const TYPES_PROJET = ["Projet de formation", "Projet personnel"];
    app.get("/api/projets", async (req, res) => {
      const type = req.query.type || null;     // null = pas de filtre
      const techno = req.query.techno || null;

      // Validation : un type inconnu est une requête mal formée
      if (type && !TYPES_PROJET.includes(type)) {
        return res.status(400).json({ error: "Type de projet inconnu" });
      }

      try {
        const query = `
          SELECT p.id_projet, p.titre, p.type, p.annee, p.description, p.lien, p.code_sae,
                 STRING_AGG(t.nom, ', ' ORDER BY t.nom) AS technologies
          FROM projet p
          LEFT JOIN projet_technologie pt ON pt.id_projet = p.id_projet
          LEFT JOIN technologie t ON t.id_techno = pt.id_techno
          WHERE ($1::text IS NULL OR p.type::text = $1)
            AND ($2::text IS NULL OR p.id_projet IN (
                  SELECT pt2.id_projet
                  FROM projet_technologie pt2
                  JOIN technologie t2 ON t2.id_techno = pt2.id_techno
                  WHERE t2.nom = $2))
          GROUP BY p.id_projet
          ORDER BY p.annee DESC NULLS LAST, p.titre;
        `;
        const { rows } = await pool.query(query, [type, techno]);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des projets" });
      }
    });

    // Un projet, avec ses technologies et ses preuves
    app.get("/api/projet/:id", async (req, res) => {
      const { id } = req.params;
      if (isNaN(Number(id))) {
        return res.status(400).json({ error: "Identifiant de projet invalide" });
      }
      try {
        const projet = await pool.query("SELECT * FROM projet WHERE id_projet = $1;", [id]);
        if (projet.rows.length === 0) {
          return res.status(404).json({ error: "Projet non trouvé" });
        }
        const technos = await pool.query(`
          SELECT t.nom, t.categorie
          FROM projet_technologie pt JOIN technologie t ON t.id_techno = pt.id_techno
          WHERE pt.id_projet = $1 ORDER BY t.nom;`, [id]);
        const preuves = await pool.query(`
          SELECT pd.id_preuve, pd.titre, pd.texte, pd.images, ac.code_ac, ac.intitule AS intitule_ac
          FROM preuve_detail pd
          JOIN preuve pr ON pr.id_preuve = pd.id_preuve
          JOIN preuve_ac pa ON pa.id_preuve = pd.id_preuve
          JOIN apprentissage_critique ac ON ac.code_ac = pa.code_ac
          WHERE pr.id_projet = $1 ORDER BY ac.code_ac, pd.id_preuve;`, [id]);
        res.json({ ...projet.rows[0], technologies: technos.rows, preuves: preuves.rows });
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération du projet" });
      }
    });

    // Technologies, avec le nombre de projets qui les utilisent
    app.get("/api/technologies", async (req, res) => {
      try {
        const query = `
          SELECT t.nom, t.categorie, COUNT(pt.id_projet) AS nb_projets
          FROM technologie t
          LEFT JOIN projet_technologie pt ON pt.id_techno = t.id_techno
          GROUP BY t.id_techno
          ORDER BY nb_projets DESC, t.nom;
        `;
        const { rows } = await pool.query(query);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des technologies" });
      }
    });

    // Expériences, de la plus récente à la plus ancienne
    app.get("/api/experiences", async (req, res) => {
      try {
        const { rows } = await pool.query(`
          SELECT id_experience, intitule, structure, type, lieu, description,
                 date_debut::text AS date_debut, date_fin::text AS date_fin   -- dates en texte : pas de décalage horaire
          FROM experience ORDER BY date_debut DESC;`);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des expériences" });
      }
    });

    // Formations, de la plus récente à la plus ancienne
    app.get("/api/formations", async (req, res) => {
      try {
        const { rows } = await pool.query(`
          SELECT id_formation, diplome, etablissement, lieu,
                 date_debut::text AS date_debut, date_fin::text AS date_fin
          FROM formation ORDER BY date_debut DESC;`);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des formations" });
      }
    });

    // Certificats et distinctions (ceux sans date à la fin)
    app.get("/api/certificats", async (req, res) => {
      try {
        const { rows } = await pool.query(`
          SELECT id_certificat, intitule, organisme, type, fichier, document, lien, site_officiel, description, date_obtention::text AS date_obtention
          FROM certificat ORDER BY type, date_obtention DESC NULLS LAST;`);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des certificats" });
      }
    });

    // Publications, avec la distinction liée
    app.get("/api/publications", async (req, res) => {
      try {
        const { rows } = await pool.query(`
          SELECT p.id_publication, p.titre, p.ouvrage, p.editeur, p.isbn, p.langue, p.resume,
                 p.fichier, p.document, p.date_parution::text AS date_parution,
                 lower(p.pages) AS page_debut, upper(p.pages) - 1 AS page_fin,
                 c.intitule AS distinction
          FROM publication p
          LEFT JOIN certificat c ON c.id_certificat = p.id_certificat
          ORDER BY p.date_parution DESC;`);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des publications" });
      }
    });

    // Langues
    app.get("/api/langues", async (req, res) => {
      try {
        const { rows } = await pool.query("SELECT nom, niveau FROM langue ORDER BY id_langue;");
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des langues" });
      }
    });

    // Les preuves d'une compétence (C1 à C4), avec leur source
    app.get("/api/competence/:id/preuves", async (req, res) => {
      const { id } = req.params;
      try {
        const query = `
          SELECT pd.id_preuve, pd.titre, pd.texte, pd.images, pd.code_sae, pd.source,
                 ac.code_ac, ac.intitule AS intitule_ac
          FROM preuve_detail pd
          JOIN preuve_ac pa ON pa.id_preuve = pd.id_preuve
          JOIN apprentissage_critique ac ON ac.code_ac = pa.code_ac
          WHERE ac.id_competence = $1
          ORDER BY ac.code_ac, pd.id_preuve;
        `;
        const { rows } = await pool.query(query, [id]);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des preuves" });
      }
    });

    // Toutes les preuves
    app.get("/api/preuves", async (req, res) => {
      try {
        const { rows } = await pool.query("SELECT * FROM preuve_detail ORDER BY id_preuve;");
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des preuves" });
      }
    });

    // Une preuve selon son identifiant
    app.get("/api/preuve/:id", async (req, res) => {
      const { id } = req.params;
      if (isNaN(Number(id))) {
        return res.status(400).json({ error: "Identifiant de preuve invalide" });
      }
      try {
        const { rows } = await pool.query("SELECT * FROM preuve_detail WHERE id_preuve = $1;", [id]);
        if (rows.length === 0) {
          return res.status(404).json({ error: "Preuve non trouvée" });
        }
        res.json(rows[0]);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération de la preuve" });
      }
    });

    // Couverture du référentiel : nombre de preuves par AC (vue couverture_ac)
    app.get("/api/couverture", async (req, res) => {
      try {
        const { rows } = await pool.query("SELECT * FROM couverture_ac;");
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération de la couverture" });
      }
    });

    // SAÉ du programme national, avec les compétences qu'elles ciblent
    app.get("/api/sae", async (req, res) => {
      try {
        const { rows } = await pool.query(`
          SELECT s.code_sae, s.intitule, s.type, s.semestre,
                 ARRAY_AGG(sc.id_competence::text ORDER BY sc.id_competence) AS competences
          FROM sae s JOIN sae_competence sc ON sc.code_sae = s.code_sae
          GROUP BY s.code_sae
          ORDER BY s.semestre, s.code_sae;`);
        res.json(rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Erreur lors de la récupération des SAÉ" });
      }
    });

    app.listen(PORT, () => {
      console.log(`🌐 Serveur en ligne sur http://localhost:${PORT}`);
    });

  } catch (err) {
    console.error("❌ Erreur lors de la préparation de la base :", err);
  }
}

startServer();
