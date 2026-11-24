# Construit l'état du dépôt pour le jour N (1 à 13) à partir de la version finale.
# Usage : python3 construire.py N DOSSIER_FINAL DOSSIER_DEPOT
import json, os, re, shutil, sys

N = int(sys.argv[1]); FIN = sys.argv[2]; DEP = sys.argv[3]
ICI = os.path.dirname(os.path.abspath(__file__))
PREUVES = json.load(open(f"{ICI}/preuves.json"))

ANCIEN_402 = "Analyse multivariée de candidatures (SAE 402)"
NOUVEAU_402 = "Analyse multivariée de candidatures (SAÉ 4.02)"
ANCIENNE_LIGNE_402 = """('Analyse multivariée de candidatures (SAE 402)', 'Projet de formation', 2026,
 'Analyse de données d''admission avec KNIME, anonymisation avec ARX et restitution dans une application R Shiny.', 'SAE4.02'),"""
JOUR_PROJET = {
    "Tableau de bord du restaurant universitaire (SAÉ 4.01)": 6,
    "Collecte automatisée de données web (SAÉ 3.01)": 8,
    "Entrepôt de données des subventions publiques (SAÉ 3.02)": 10,
    "Séries temporelles de la varicelle (SAÉ 3.03)": 11,
    "Conformité réglementaire des données (SAÉ 3.04)": 12,
}
JOUR_TECHNO = {"Dash": 6, "Leaflet": 3, "FactoMineR": 3, "Talend": 10,
               "BeautifulSoup": 8, "Selenium": 8, "Flask": 8}

def q(s):
    return "NULL" if s is None else "'" + s.replace("'", "''") + "'"

sql = open(f"{FIN}/bdd/init_db.sql").read()

# ---- 1. Projets ----
debut = sql.index("INSERT INTO projet (titre, type, annee, description, code_sae) VALUES\n") + len("INSERT INTO projet (titre, type, annee, description, code_sae) VALUES\n")
fin = sql.index(";\n", debut)
lignes = sql[debut:fin].split("\n")
blocs = [lignes[i] + "\n" + lignes[i + 1] for i in range(0, len(lignes), 2)]
garde = []
for b in blocs:
    titre = re.match(r"\('((?:[^']|'')*)'", b).group(1).replace("''", "'")
    if titre == NOUVEAU_402 and N < 3:
        b = ANCIENNE_LIGNE_402
    if JOUR_PROJET.get(titre, 1) <= N:
        garde.append(b.rstrip(","))
sql = sql[:debut] + ",\n".join(garde) + sql[fin:]

# ---- 2. Technologies ----
debut = sql.index("INSERT INTO technologie (nom, categorie) VALUES\n") + len("INSERT INTO technologie (nom, categorie) VALUES\n")
fin = sql.index(";\n", debut)
tuples = re.findall(r"\('[^']*', '[^']*'\)", sql[debut:fin])
tuples = [t for t in tuples if JOUR_TECHNO.get(re.match(r"\('([^']*)'", t).group(1), 1) <= N]
sql = sql[:debut] + ",\n".join(", ".join(tuples[i:i + 4]) for i in range(0, len(tuples), 4)) + sql[fin:]

# ---- 3. Liens projet-technologie ----
debut = sql.index("FROM (VALUES\n", sql.index("INSERT INTO projet_technologie")) + len("FROM (VALUES\n")
fin = sql.index("\n) AS v(titre, nom)", debut)
liens = re.findall(r"\('((?:[^']|'')*)', '([^']*)'\)", sql[debut:fin])
garde = []
for titre_sql, nom in liens:
    titre = titre_sql.replace("''", "'")
    if titre == NOUVEAU_402:
        if nom in ("FactoMineR", "Leaflet") and N < 3:
            continue
        if N < 3:
            titre_sql = ANCIEN_402
    if JOUR_PROJET.get(titre, 1) <= N:
        garde.append(f"    ('{titre_sql}', '{nom}')")
sql = sql[:debut] + ",\n".join(garde) + sql[fin:]

# ---- 4. Preuves, AC et captures ----
debut = sql.index("-- Preuves : tirées de mes fiches portfolio")
fin = sql.index("-- ----------------------------------------------------------------------------\n--  Vues utilisées par le site")
liste = [p for p in PREUVES if p["jour"] <= N]
bloc = ["-- Preuves : tirées de mes fiches portfolio (fiches AC, fiche SAÉ 4.02, fiche de stage), ajoutées petit à petit.",
        "-- Les preuves du stage sont décrites sans capture : la plateforme du stage est confidentielle."]
if liste:
    rows = []
    for p in liste:
        if p["source"] == "STAGE":
            src = "NULL, (SELECT id_experience FROM experience WHERE structure = 'Serviciale')"
        else:
            src = f"(SELECT id_projet FROM projet WHERE titre = {q(p['source'])}), NULL"
        rows.append(f"({q(p['titre'])},\n {q(p['texte'])},\n {q(p['sae'])}, {src}, NULL)")
    bloc += ["INSERT INTO preuve (titre, texte, code_sae, id_projet, id_experience, id_certificat) VALUES",
             ",\n".join(rows) + ";", "",
             "-- (titre de la preuve, AC démontré) : le déclencheur vérifie chaque ligne",
             "INSERT INTO preuve_ac (id_preuve, code_ac)\nSELECT p.id_preuve, v.code_ac\nFROM (VALUES",
             ",\n".join(f"    ({q(p['titre'])}, {q(ac)})" for p in liste for ac in p["acs"]),
             ") AS v(titre, code_ac)\nJOIN preuve p ON p.titre = v.titre;", ""]
    imgs = [f"    ({q(p['titre'])}, {i}, {q(n)}, {q(l)})" for p in liste for i, (n, l) in enumerate(p["images"], 1)]
    if imgs:
        bloc += ["-- Captures d'écran des preuves (dans client/preuves/)",
                 "INSERT INTO preuve_image (id_preuve, ordre, fichier, legende)\nSELECT p.id_preuve, v.ordre, v.fichier, v.legende\nFROM (VALUES",
                 ",\n".join(imgs), ") AS v(titre, ordre, fichier, legende)\nJOIN preuve p ON p.titre = v.titre;", ""]
else:
    bloc += ["-- (les preuves de mes fiches arrivent dans les prochains jours)", ""]
# auto-évaluations : à partir du jour 2
ev = sql[sql.index("-- Auto-évaluation des AC (fiches portfolio)"):fin]
bloc.append(ev if N >= 2 else "\n")
sql = sql[:debut] + "\n".join(bloc) + sql[fin:]

# ---- Écriture des fichiers ----
for racine, _, fichiers in os.walk(FIN):
    for f in fichiers:
        chemin = os.path.join(racine, f); rel = os.path.relpath(chemin, FIN)
        if rel.startswith("client/preuves/") or rel in ("bdd/init_db.sql", "AVANCEMENT.md",
                                                      "bdd/schema-relationnel.png", "maquette/schema-relationnel.png"):
            continue
        os.makedirs(os.path.dirname(os.path.join(DEP, rel)), exist_ok=True)
        shutil.copyfile(chemin, os.path.join(DEP, rel))
open(f"{DEP}/bdd/init_db.sql", "w").write(sql)

# Captures : celles des preuves du jour et avant, plus les fichiers des certificats
voulues = {n for p in liste for n, _ in p["images"]}
for f in os.listdir(f"{FIN}/client/preuves"):
    cible = f"{DEP}/client/preuves/{f}"
    if not f.startswith("s") or f in voulues:
        shutil.copyfile(f"{FIN}/client/preuves/{f}", cible)
    elif os.path.exists(cible):
        os.remove(cible)

# AVANCEMENT.md
av = open(f"{ICI}/AVANCEMENT_avant.md").read()
L1 = "- Tables `preuve_image` (captures d'écran des preuves) et `evaluation_ac` (auto-évaluation et visa du tuteur) ; les preuves de test sont retirées, les preuves réelles de mes fiches portfolio sont ajoutées petit à petit, une SAÉ à la fois\n"
L13 = "- Preuves réelles tirées de mes fiches portfolio : 60 preuves (SAÉ 3.01 à 4.02 et stage) qui couvrent tous les AC du niveau 2 de C1, C2, C3 et du niveau 1 de C4 ; 5 projets de SAÉ ajoutés ; captures d'écran rangées dans une table `preuve_image` ; auto-évaluation et visa du tuteur par AC dans une table `evaluation_ac`, affichés sur la page Compétences\n"
a = "\n### À faire ensuite\n"
av = av.replace(a, "\n" + (L13 if N == 13 else L1).rstrip("\n") + a, 1) if False else av.replace(a, (L13 if N == 13 else L1) + a, 1)
av = av.replace("- Remplacer les images de test par les preuves du portfolio\n", "")
open(f"{DEP}/AVANCEMENT.md", "w").write(av)
print(f"jour {N} : {len(liste)} preuves, {len(voulues)} captures")
