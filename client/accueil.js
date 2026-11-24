// ============================================================
// Page Accueil : chiffres clés, dernier projet et outils
// ============================================================

async function chargerAccueil() {
  // Plusieurs routes de l'API, appelées en même temps
  const [projets, experiences, certificats, technologies] = await Promise.all([
    chargerJSON("/api/projets"),
    chargerJSON("/api/experiences"),
    chargerJSON("/api/certificats"),
    chargerJSON("/api/technologies")
  ]);

  // 1. Chiffres clés : on compte les lignes reçues
  const nbCertificats = certificats.filter(c => c.type === "Certificat").length;
  document.getElementById("chiffres").innerHTML = `
    <div class="chiffre"><strong>${projets.length}</strong><span class="secondaire">projets</span></div>
    <div class="chiffre"><strong>${experiences.length}</strong><span class="secondaire">expériences</span></div>
    <div class="chiffre"><strong>${nbCertificats}</strong><span class="secondaire">certificats</span></div>
    <div class="chiffre"><strong>${technologies.length}</strong><span class="secondaire">technologies</span></div>`;

  // 2. Dernier projet : la route renvoie les projets du plus récent au plus ancien
  const dernier = projets[0];
  document.getElementById("dernier-projet").innerHTML = `
    <p class="secondaire petit">Dernier projet · ${esc(dernier.type)} · ${esc(dernier.annee ?? "année à confirmer")}</p>
    <h2>${esc(dernier.titre)}</h2>
    <p class="secondaire">${esc(dernier.description)}</p>
    <a href="projets.html">Voir tous les projets</a>`;

  // 3. Outils : une étiquette par technologie utilisée dans au moins un projet
  document.getElementById("outils").innerHTML = technologies
    .filter(t => Number(t.nb_projets) > 0)          // nb_projets arrive en texte : on le convertit
    .map(t => `<span class="etiquette">${esc(t.nom)}</span>`)
    .join("");
}

chargerAccueil();
