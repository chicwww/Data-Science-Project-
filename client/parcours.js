// ============================================================
// Page Parcours : frise des formations et expériences, heures par année,
// certificats et langues
// ============================================================

let etapes = [];   // toutes les étapes de la frise (formations + expériences)

// ---------- 1. Frise ----------
async function chargerFrise() {
  const [formations, experiences] = await Promise.all([
    chargerJSON("/api/formations"),
    chargerJSON("/api/experiences")
  ]);

  // On met les deux listes au même format pour les afficher ensemble
  etapes = [
    ...formations.map(f => ({ categorie: "Formation", titre: f.diplome, lieu: f.etablissement,
      debut: f.date_debut, fin: f.date_fin, texte: f.lieu ? `Lieu : ${f.lieu}.` : "" })),
    ...experiences.map(e => ({ categorie: "Expérience", titre: e.intitule, lieu: `${e.structure} · ${e.type}`,
      debut: e.date_debut, fin: e.date_fin, texte: e.description }))
  ];
  etapes.sort((a, b) => b.debut.localeCompare(a.debut));   // de la plus récente à la plus ancienne
  afficherFrise("Tout");
}

function afficherFrise(categorie) {
  const visibles = etapes.filter(e => categorie === "Tout" || e.categorie === categorie);
  document.getElementById("frise").innerHTML = visibles.map((e, i) => `
    <li data-index="${etapes.indexOf(e)}">
      <div class="date">${moisAnnee(e.debut)} – ${moisAnnee(e.fin)} · ${esc(e.categorie)}</div>
      <div class="titre">${esc(e.titre)}</div>
      <div class="secondaire petit">${esc(e.lieu)}</div>
    </li>`).join("");

  // Un clic sur une étape affiche son détail
  document.querySelectorAll("#frise li").forEach(li => {
    li.addEventListener("click", () => afficherDetail(Number(li.dataset.index)));
  });
  if (visibles.length > 0) afficherDetail(etapes.indexOf(visibles[0]));
}

function afficherDetail(index) {
  const e = etapes[index];
  document.querySelectorAll("#frise li").forEach(li =>
    li.classList.toggle("actif", Number(li.dataset.index) === index));
  document.getElementById("detail").innerHTML = `
    <p class="secondaire petit">${esc(e.categorie)} · ${moisAnnee(e.debut)} – ${moisAnnee(e.fin)}</p>
    <h2>${esc(e.titre)}</h2>
    <p><strong>${esc(e.lieu)}</strong></p>
    <p class="secondaire">${esc(e.texte)}</p>`;
}

// Boutons de filtre Tout / Formation / Expérience
document.querySelectorAll("#filtres-parcours .filtre").forEach(bouton => {
  bouton.addEventListener("click", () => {
    document.querySelectorAll("#filtres-parcours .filtre").forEach(b => b.classList.remove("actif"));
    bouton.classList.add("actif");
    afficherFrise(bouton.dataset.type);
  });
});

// ---------- 2. Graphique : heures par année et par compétence ----------
async function chargerHeuresParAnnee() {
  const data = await chargerJSON("/api/heures-par-annee");
  const annees = ["BUT1", "BUT2", "BUT3"];
  const competences = ["C1", "C2", "C3", "C4"];
  const couleurs = ["#12161C", "#4A5361", "#D93A22", "#CBD2DB"];

  // Un jeu de données (une couleur) par compétence, une barre par année
  const datasets = competences.map((c, i) => ({
    label: c,
    data: annees.map(a => {
      const ligne = data.find(d => d.id_annee === a && d.id_competence === c);
      return ligne ? Number(ligne.total_heures) : 0;     // total_heures arrive en texte
    }),
    backgroundColor: couleurs[i]
  }));

  new Chart(document.getElementById("graphique-annees"), {
    type: "bar",
    data: { labels: annees, datasets },
    options: {
      responsive: true, maintainAspectRatio: false,
      scales: { x: { stacked: true }, y: { stacked: true, title: { display: true, text: "Heures" } } }
    }
  });
}

// ---------- 3. Certificats et langues ----------
async function chargerCertificatsEtLangues() {
  const [certificats, langues] = await Promise.all([
    chargerJSON("/api/certificats"),
    chargerJSON("/api/langues")
  ]);

  document.getElementById("certificats").innerHTML = certificats.map(c => `
    <div class="carte preuve">
      ${c.fichier ? `<img src="/preuves/${esc(c.fichier)}" alt="Certificat ${esc(c.intitule)}">` : ""}
      <p class="secondaire petit">${esc(c.type)}${c.date_obtention ? " · " + moisAnnee(c.date_obtention) : ""}</p>
      <h3>${esc(c.intitule)}</h3>
      <p class="secondaire petit">${esc(c.organisme ?? "")}</p>
      ${c.document ? `<a class="petit" href="/preuves/${esc(c.document)}" target="_blank">Voir le certificat (PDF)</a>` : ""}
      ${c.lien ? `<a class="petit" href="${esc(c.lien)}" target="_blank">Voir l'annonce</a>` : ""}
    </div>`).join("");

  document.getElementById("langues").innerHTML = langues
    .map(l => `<tr><td>${esc(l.nom)}</td><td>${esc(l.niveau)}</td></tr>`).join("");
}

// ---------- 4. Publications ----------
async function chargerPublications() {
  const publications = await chargerJSON("/api/publications");
  document.getElementById("publications").innerHTML = publications.map(p => `
    <div class="carte deux-colonnes preuve">
      ${p.fichier ? `<img src="/preuves/${esc(p.fichier)}" alt="Première page du texte ${esc(p.titre)}">` : ""}
      <div>
        <p class="secondaire petit">${esc(p.langue)} · ${moisAnnee(p.date_parution)} · pages ${p.page_debut} à ${p.page_fin}</p>
        <h3>${esc(p.titre)}</h3>
        <p><em>${esc(p.ouvrage)}</em>, ${esc(p.editeur)}, ISBN ${esc(p.isbn)}</p>
        <p class="secondaire">${esc(p.resume)}</p>
        ${p.distinction ? `<p class="petit"><strong>Distinction liée :</strong> ${esc(p.distinction)}</p>` : ""}
        ${p.document ? `<a href="/preuves/${esc(p.document)}" target="_blank">Lire l'extrait (PDF)</a>` : ""}
      </div>
    </div>`).join("");
}

chargerFrise();
chargerPublications();
chargerHeuresParAnnee();
chargerCertificatsEtLangues();
