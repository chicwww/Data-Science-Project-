let chartPrincipal, chartPie;
let labelsComp = [], heuresComp = [];
const couleurMap = {
  bar: ["rgba(75, 192, 192, 0.6)","rgba(54, 162, 235, 0.6)","rgba(153, 102, 255, 0.6)","rgba(255, 99, 132, 0.6)"],
  line: ["rgba(153, 102, 255, 0.6)","rgba(201, 203, 207, 0.6)","rgba(54, 162, 235, 0.6)","rgba(75, 192, 192, 0.6)"]
};

async function loadData() {
  const res = await fetch("/api/heures");
  const data = await res.json();

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
    row.innerHTML = `<td>${d.id_competence}</td><td>${d.intitule}</td>`;
    row.addEventListener("click", ()=> highlightSelection(d.id_competence));
    tbody.appendChild(row);
  });

  // Graphique principal
  const ctxMain = document.getElementById("chartPrincipal").getContext("2d");
  chartPrincipal = new Chart(ctxMain, {
    type: "bar",
    data: { labels: labelsComp, datasets: [{ label: "Total d'heures", data: heuresComp, backgroundColor: couleurMap.bar, borderColor: "white", borderWidth: 2 }] },
    options: {
      responsive:true,
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
      responsive:true,
      plugins:{title:{display:true,text:"Répartition des heures (camembert)"},legend:{position:"bottom"}},
      onClick:(evt,elements)=>{ if(elements.length>0) highlightSelection(labelsComp[elements[0].index]); }
    }
  });
}

async function highlightSelection(comp) {
  try {
    const res = await fetch(`/api/competence/${comp}`);
    const data = await res.json();
    if (data.error) {
      document.getElementById("description").innerText = "Description non disponible.";
      document.getElementById("preuveImg").src = "";
    } else {
      document.getElementById("description").innerText = `${data.intitule}\n\n${data.description}`;
      document.getElementById("preuveImg").src = data.preuve ? `/preuves/${data.preuve}` : "";
    }
  } catch {
    document.getElementById("description").innerText = "Erreur de connexion à la base.";
    document.getElementById("preuveImg").src = "";
  }

  // Effets graphiques
  chartPrincipal.data.datasets[0].backgroundColor = chartPrincipal.data.datasets[0].data.map((_,i)=> labelsComp[i]===comp ? 'rgba(255,206,86,0.9)': couleurMap.bar[i]);
  chartPrincipal.data.datasets[0].borderColor = chartPrincipal.data.datasets[0].data.map((_,i)=> labelsComp[i]===comp ? 'rgba(255,159,64,1)': 'white');
  chartPrincipal.data.datasets[0].borderWidth = chartPrincipal.data.datasets[0].data.map((_,i)=> labelsComp[i]===comp ? 5 : 2);
  chartPrincipal.update();

  chartPie.data.datasets[0].backgroundColor = chartPie.data.labels.map(label => label===comp ? 'rgba(255,206,86,0.9)' : couleurMap.bar[labelsComp.indexOf(label)]);
  chartPie.update();

  document.querySelectorAll('#intitulesTable tbody tr').forEach(row => row.classList.toggle('selected', row.cells[0].innerText === comp));
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
        backgroundColor: isLine ? "rgba(54,162,235,0.4)" : couleurMap[type],
        borderColor: isLine ? "rgba(54,162,235,1)" : "white",
        borderWidth:2,
        fill:false,
        pointBackgroundColor: isLine ? "rgba(54,162,235,1)": undefined,
        pointRadius: isLine ? 6 : 0,
        showLine: !isLine ? true : false
      }]
    },
    options:{
      responsive:true,
      plugins:{legend:{display:false}, title:{display:true,text: isLine ? "Heures par compétence (points)" : "Heures par compétence (barres)"}},
      scales:{y:{beginAtZero:true}, x:{title:{display:true,text:"Compétences"}}},
      onClick:(evt,elements)=>{ if(elements.length>0) highlightSelection(labelsComp[elements[0].index]); }
    }
  });

  chartPie.data.datasets[0].backgroundColor = couleurMap.bar;
  chartPie.update();
}

function setActive(id){
  document.querySelectorAll("button").forEach(b=>b.classList.remove("active"));
  document.getElementById(id).classList.add("active");
}

document.getElementById("btnBarres").addEventListener("click",()=>{ setActive("btnBarres"); switchChart("bar"); });
document.getElementById("btnCourbes").addEventListener("click",()=>{ setActive("btnCourbes"); switchChart("line"); });

loadData();
