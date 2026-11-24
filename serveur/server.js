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
  port: 5432
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
// 4️⃣ Lancer le serveur après préparation de la base
// ==============================
async function startServer() {
  try {
    await ensureDatabase();
    await initTables();

    const pool = new Pool(DB_CONFIG);

    // Servir le dossier public
    app.use(express.static("../client")); // le site (HTML, CSS, JS, images) est dans le dossier client

    // Route API : total des heures par compétence
    app.get("/api/heures", async (req, res) => {
      try {
        const query = `
          SELECT c.id_competence, c.intitule, SUM(a.heure) AS total_heures
          FROM COMPETENCE c
          LEFT JOIN ACTIVITE_PEDAGOGIQUE a ON a.id_competence = c.id_competence
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
          SELECT id_competence, intitule, description, preuve
          FROM COMPETENCE
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
    const query = `
      SELECT id_competence, intitule, description, preuve
      FROM COMPETENCE
      WHERE id_competence = $1;
    `;
    const { rows } = await pool.query(query, [id]);

    if (rows.length === 0) {
      return res.status(404).json({ error: "Compétence non trouvée" });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Erreur lors de la récupération de la compétence" });
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
