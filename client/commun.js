// ============================================================
// Fonctions communes à toutes les pages
// ============================================================

// Demande des données au serveur (une route de l'API) et renvoie le JSON reçu
async function chargerJSON(url) {
  const res = await fetch(url);
  const data = await res.json();
  console.log(`Données reçues de ${url} :`, data);   // visible dans F12 > Console
  return data;
}

// Protège un texte avant de l'insérer dans le HTML (évite d'interpréter < > & comme du code)
function esc(texte) {
  return String(texte ?? "").replace(/[&<>"']/g, c =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
}

// Transforme "2026-09-01" en "sept. 2026" (et une date vide en "aujourd'hui")
function moisAnnee(dateTexte) {
  if (!dateTexte) return "aujourd'hui";
  const [annee, mois] = dateTexte.split("-");
  const noms = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."];
  return `${noms[Number(mois) - 1]} ${annee}`;
}
