// ============================================================
// Page Projets : liste filtrée par le serveur, détail d'un projet,
// graphique du nombre de projets par technologie
// ============================================================

const choixTechno = document.getElementById("filtre-techno");
const choixType = document.getElementById("filtre-type");

// ---------- 1. Liste des projets (les filtres passent dans l'URL) ----------
async function chargerProjets() {
  // Paramètres de requête : /api/projets?type=...&techno=...
  const parametres = new URLSearchParams();
  if (choixType.value) parametres.append("type", choixType.value);
  if (choixTechno.value) parametres.append("techno", choixTechno.value);

  const projets = await chargerJSON(`/api/projets?${parametres}`);
  const liste = document.getElementById("liste-projets");

  if (projets.length === 0) {
    liste.innerHTML = `<p class="secondaire">Aucun projet ne correspond à ces filtres.</p>`;
    return;
  }
  liste.innerHTML = projets.map(p => `
    <article class="carte">
      <p class="secondaire petit">${esc(p.type)} · ${esc(p.annee ?? "année à confirmer")}${p.code_sae ? " · " + esc(p.code_sae) : ""}</p>
      <h3>${esc(p.titre)}</h3>
      <p class="secondaire petit">${esc(p.technologies ?? "")}</p>
      <button class="filtre" data-id="${p.id_projet}">Voir le détail</button>
    </article>`).join("");

  liste.querySelectorAll("button[data-id]").forEach(b =>
    b.addEventListener("click", () => chargerDetail(b.dataset.id)));
}

// ---------- 2. Détail d'un projet : route /api/projet/:id ----------
async function chargerDetail(id) {
  const p = await chargerJSON(`/api/projet/${id}`);
  const zone = document.getElementById("detail-projet");
  zone.hidden = false;
  zone.innerHTML = `
    <h2>${esc(p.titre)}</h2>
    <p class="secondaire">${esc(p.description)}</p>
    <p>${p.technologies.map(t => `<span class="etiquette">${esc(t.nom)}</span>`).join("")}</p>
    <h3>Apprentissages critiques démontrés</h3>
    ${p.preuves.length === 0 ? `<p class="secondaire">Aucune preuve pour l'instant.</p>` :
      p.preuves.map(pr => `<p><strong>${esc(pr.code_ac)}</strong> · ${esc(pr.intitule_ac)}<br>
        <span class="secondaire petit">${esc(pr.titre)} : ${esc(pr.texte)}</span></p>`).join("")}`;
  zone.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

// ---------- 3. Technologies : menu déroulant et graphique ----------
async function chargerTechnologies() {
  const technos = (await chargerJSON("/api/technologies")).filter(t => Number(t.nb_projets) > 0);

  choixTechno.innerHTML += technos.map(t => `<option>${esc(t.nom)}</option>`).join("");

  new Chart(document.getElementById("graphique-technos"), {
    type: "bar",
    data: {
      labels: technos.map(t => t.nom),
      datasets: [{ label: "Projets", data: technos.map(t => Number(t.nb_projets)), backgroundColor: "#D93A22" }]
    },
    options: {
      indexAxis: "y",                                   // barres horizontales
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { x: { ticks: { stepSize: 1 } } },
      onClick: (evt, elements) => {                     // clic sur une barre = filtre par technologie
        if (elements.length > 0) {
          choixTechno.value = technos[elements[0].index].nom;
          chargerProjets();
        }
      }
    }
  });
}

choixTechno.addEventListener("change", chargerProjets);
choixType.addEventListener("change", chargerProjets);
document.getElementById("reinitialiser").addEventListener("click", () => {
  choixTechno.value = "";
  choixType.value = "";
  chargerProjets();
});

chargerTechnologies();
chargerProjets();
