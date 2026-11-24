// ============================================================
// Page Compétences : code du cours (graphiques, tableau, sélection)
// adapté aux couleurs du site, avec en plus les preuves de chaque compétence
// ============================================================

let chartPrincipal, chartPie;
let labelsComp = [], heuresComp = [];
const couleurMap = {
  bar: ["#12161C", "#4A5361", "#8A94A3", "#CBD2DB"],   // couleurs de la maquette
  line: ["#12161C", "#4A5361", "#8A94A3", "#CBD2DB"]
};

async function loadData() {
  const data = await chargerJSON("/api/heures");   // fetch + console.log (commun.js)

  const competenceOrder = ["C1","C2","C3","C4"];
  const filteredComp = competenceOrder.map(id => 
    data.find(d => d.id_competence === id) || { total_heures: 0, intitule: "N/A", description: "Non disponible", preuve: "" }
  );

  labelsComp = competenceOrder;
  heuresComp = filteredComp.map(d => Number(d.total_heures));

  // Tableau
  const tbody = document.querySelector("#intitulesTable tbody");
  tbody.innerHTML = "";
  filteredComp.forEach(d=>{
    const row = document.createElement("tr");
    row.innerHTML = `<td>${esc(d.id_competence)}</td><td>${esc(d.intitule)}</td><td>${Number(d.total_heures)} h</td>`;
    row.addEventListener("click", ()=> highlightSelection(d.id_competence));
    tbody.appendChild(row);
  });

  // Graphique principal
  const ctxMain = document.getElementById("chartPrincipal").getContext("2d");
  chartPrincipal = new Chart(ctxMain, {
    type: "bar",
    data: { labels: labelsComp, datasets: [{ label: "Total d'heures", data: heuresComp, backgroundColor: couleurMap.bar, borderColor: "white", borderWidth: 2 }] },
    options: {
      responsive:true, maintainAspectRatio:false,
      plugins:{legend:{display:false},title:{display:true,text:"Heures par compétence (barres)"}},
      scales:{y:{beginAtZero:true},x:{title:{display:true,text:"Compétences"}}},
      onClick:(evt,elements)=>{ if(elements.length>0) highlightSelection(labelsComp[elements[0].index]); }
    }
  });

  // Camembert
  const ctxPie = document.getElementById("chartCamembert").getContext("2d");
  chartPie = new Chart(ctxPie, {
    type: "pie",
    data: { labels: labelsComp, datasets: [{ label: "Répartition des heures", data: heuresComp, backgroundColor: couleurMap.bar, borderColor: "white", borderWidth: 2 }] },
    options: {
      responsive:true, maintainAspectRatio:false,
      plugins:{title:{display:true,text:"Répartition des heures (camembert)"},legend:{position:"bottom"}},
      onClick:(evt,elements)=>{ if(elements.length>0) highlightSelection(labelsComp[elements[0].index]); }
    }
  });
}

async function highlightSelection(comp) {
  try {
    const data = await chargerJSON(`/api/competence/${comp}`);
    if (data.error) {
      document.getElementById("description").innerText = "Description non disponible.";
    } else {
      // Référentiel national : composantes essentielles, puis niveaux et leurs AC
      document.getElementById("description").innerHTML = `
        <p class="secondaire petit">${esc(data.verbe)}${data.parcours ? " · parcours " + esc(data.parcours) : " · tronc commun"}</p>
        <h2>${esc(data.id_competence)} · ${esc(data.intitule)}</h2>
        <h3>Composantes essentielles</h3>
        <ul class="petit">${data.composantes.map(c => `<li>${esc(c.libelle)}</li>`).join("")}</ul>
        ${data.niveaux.map(n => `
          <h3>Niveau ${n.numero} · ${esc(n.intitule)} <span class="secondaire petit">(${esc(n.id_annee)})</span></h3>
          <ul class="petit acs">${n.acs.map(ac => `<li><strong>${esc(ac.code_ac)}</strong> ${esc(ac.intitule)}
            ${pastille(ac.auto_evaluation, "Auto-évaluation : ")}${pastille(ac.visa_tuteur, "Visa du tuteur : ")}</li>`).join("")}</ul>`).join("")}`;
    }
    afficherPreuves(await chargerJSON(`/api/competence/${comp}/preuves`));
  } catch {
    document.getElementById("description").innerText = "Erreur de connexion à la base.";
  }

  // Effets graphiques
  chartPrincipal.data.datasets[0].backgroundColor = chartPrincipal.data.datasets[0].data.map((_,i)=> labelsComp[i]===comp ? '#D93A22': couleurMap.bar[i]);
  chartPrincipal.data.datasets[0].borderColor = chartPrincipal.data.datasets[0].data.map((_,i)=> labelsComp[i]===comp ? '#B8301B': 'white');
  chartPrincipal.data.datasets[0].borderWidth = chartPrincipal.data.datasets[0].data.map((_,i)=> labelsComp[i]===comp ? 5 : 2);
  chartPrincipal.update();

  chartPie.data.datasets[0].backgroundColor = chartPie.data.labels.map(label => label===comp ? '#D93A22' : couleurMap.bar[labelsComp.indexOf(label)]);
  chartPie.update();

  document.querySelectorAll('#intitulesTable tbody tr').forEach(row => row.classList.toggle('selectionne', row.cells[0].innerText === comp));
}

function switchChart(type){
  if(chartPrincipal) chartPrincipal.destroy();
  const ctx = document.getElementById("chartPrincipal").getContext("2d");
  const isLine = type==="line";

  chartPrincipal = new Chart(ctx, {
    type,
    data:{
      labels: labelsComp,
      datasets:[{
        label:"Total d'heures",
        data: heuresComp,
        backgroundColor: isLine ? "#D93A22" : couleurMap[type],
        borderColor: isLine ? "#D93A22" : "white",
        borderWidth:2,
        fill:false,
        pointBackgroundColor: isLine ? "#D93A22": undefined,
        pointRadius: isLine ? 6 : 0,
        showLine: !isLine ? true : false
      }]
    },
    options:{
      responsive:true, maintainAspectRatio:false,
      plugins:{legend:{display:false}, title:{display:true,text: isLine ? "Heures par compétence (points)" : "Heures par compétence (barres)"}},
      scales:{y:{beginAtZero:true}, x:{title:{display:true,text:"Compétences"}}},
      onClick:(evt,elements)=>{ if(elements.length>0) highlightSelection(labelsComp[elements[0].index]); }
    }
  });

  chartPie.data.datasets[0].backgroundColor = couleurMap.bar;
  chartPie.update();
}

function setActive(id){
  document.querySelectorAll(".filtres .filtre").forEach(b=>b.classList.remove("actif"));
  document.getElementById(id).classList.add("actif");
}

document.getElementById("btnBarres").addEventListener("click",()=>{ setActive("btnBarres"); switchChart("bar"); });
document.getElementById("btnCourbes").addEventListener("click",()=>{ setActive("btnCourbes"); switchChart("line"); });

// Preuves de la compétence sélectionnée (route /api/competence/:id/preuves),
// regroupées par apprentissage critique
function afficherPreuves(preuves) {
  const zone = document.getElementById("preuves");
  if (preuves.length === 0) {
    zone.innerHTML = `<p class="secondaire">Pas encore de preuve pour cette compétence.</p>`;
    return;
  }
  const codes = [...new Set(preuves.map(p => p.code_ac))];   // AC dans l'ordre reçu
  zone.innerHTML = codes.map(code => {
    const liste = preuves.filter(p => p.code_ac === code);
    return `
      <h3 class="titre-ac">${esc(code)} <span class="secondaire petit">${esc(liste[0].intitule_ac)}</span></h3>
      <div class="grille">${liste.map(p => `
        <div class="carte preuve">
          ${imagesPreuve(p.images, p.titre)}
          <p class="secondaire petit">${esc(p.source)}</p>
          <h3>${esc(p.titre)}</h3>
          <p class="secondaire petit">${esc(p.texte)}</p>
        </div>`).join("")}
      </div>`;
  }).join("");
}

// Couverture du référentiel : AC démontrés par au moins une preuve, par compétence
async function chargerCouverture() {
  const data = await chargerJSON("/api/couverture");
  const comps = ["C1", "C2", "C3", "C4"];
  const demontres = comps.map(c => data.filter(ac => ac.id_competence === c && Number(ac.nb_preuves) > 0).length);
  const restants = comps.map((c, i) => data.filter(ac => ac.id_competence === c).length - demontres[i]);
  new Chart(document.getElementById("chartCouverture"), {
    type: "bar",
    data: { labels: comps, datasets: [
      { label: "AC démontrés", data: demontres, backgroundColor: "#D93A22" },
      { label: "AC sans preuve", data: restants, backgroundColor: "#CBD2DB" }] },
    options: { responsive: true, maintainAspectRatio: false, indexAxis: "y",
      scales: { x: { stacked: true, title: { display: true, text: "Apprentissages critiques" } }, y: { stacked: true } } }
  });
}

loadData().then(() => highlightSelection("C1"));   // C1 sélectionnée au chargement
chargerCouverture();
