# Teste l'état construit d'un jour et régénère le diagramme de la base.
# Usage : python3 verifier.py DOSSIER_DEPOT   (PostgreSQL de test sur localhost:5432, mot de passe testmdp)
import asyncio, json, os, re, subprocess, sys, time, urllib.request
from playwright.async_api import async_playwright

DEP = sys.argv[1]; ICI = os.path.dirname(os.path.abspath(__file__))
ENV = dict(os.environ, PGPASSWORD="testmdp")
MODULES = "/tmp/apptest1/serveur/node_modules"
CHART = "/tmp/cjs1/node_modules/chart.js/dist/chart.umd.js"
erreurs = []

# Démarre PostgreSQL de test s'il est arrêté
if subprocess.run(["pg_isready", "-h", "localhost", "-q"]).returncode != 0:
    pid = "/tmp/pgdata1/postmaster.pid"
    if os.path.exists(pid): os.remove(pid)
    subprocess.run(["su", "nobody", "-s", "/bin/bash", "-c",
                    "/usr/lib/postgresql/16/bin/pg_ctl -D /tmp/pgdata1 -l /tmp/pg1.log -o '-k /tmp' -w start"], check=True)
nm = f"{DEP}/serveur/node_modules"
if not os.path.exists(nm):
    os.symlink(MODULES, nm)
srv = subprocess.Popen(["node", "server.js"], cwd=f"{DEP}/serveur", env=dict(os.environ, POSTGRES_PASSWORD="testmdp"),
                       stdout=open("/tmp/verif_srv.log", "w"), stderr=subprocess.STDOUT)
try:
    for _ in range(40):
        time.sleep(0.5)
        if "Serveur en ligne" in open("/tmp/verif_srv.log").read():
            break
    else:
        erreurs.append("le serveur ne démarre pas : " + open("/tmp/verif_srv.log").read()[-800:])
        raise SystemExit

    def code(u):
        try:
            return urllib.request.urlopen("http://localhost:3000" + u).status
        except urllib.error.HTTPError as e:
            return e.code
    attendus = {"/api/heures": 200, "/api/competences": 200, "/api/competence/C1": 200, "/api/competence/C9": 404,
                "/api/competence/C2/preuves": 200, "/api/heures-par-annee": 200, "/api/projets": 200,
                "/api/projets?type=Inconnu": 400, "/api/projet/1": 200, "/api/projet/abc": 400, "/api/projet/999": 404,
                "/api/technologies": 200, "/api/experiences": 200, "/api/formations": 200, "/api/certificats": 200,
                "/api/langues": 200, "/api/publications": 200, "/api/preuves": 200, "/api/preuve/abc": 400,
                "/api/preuve/999": 404, "/api/couverture": 200, "/api/sae": 200}
    for u, c in attendus.items():
        if code(u) != c:
            erreurs.append(f"{u} renvoie {code(u)} au lieu de {c}")
    preuves = json.load(urllib.request.urlopen("http://localhost:3000/api/preuves"))

    async def pages():
        async with async_playwright() as p:
            b = await p.chromium.launch()
            for w, h in [(1366, 900), (390, 844)]:
                pg = await b.new_page(viewport={"width": w, "height": h})
                pe = []
                pg.on("pageerror", lambda e: pe.append(str(e)))
                pg.on("console", lambda m: m.type == "error" and pe.append(m.text))
                await pg.route("**/cdn.jsdelivr.net/**", lambda r: r.fulfill(path=CHART, content_type="application/javascript"))
                await pg.route("**/fonts.googleapis.com/**", lambda r: r.fulfill(body="", content_type="text/css"))
                for page in ["index.html", "parcours.html", "projets.html", "competences.html", "contact.html"]:
                    await pg.goto(f"http://localhost:3000/{page}"); await pg.wait_for_timeout(900)
                    await pg.evaluate("document.querySelectorAll('img').forEach(i=>i.loading='eager')")
                    await pg.wait_for_timeout(500)
                    casse = await pg.evaluate("[...document.images].filter(i=>i.complete&&i.naturalWidth===0).map(i=>i.src)")
                    large = await pg.evaluate("document.documentElement.scrollWidth")
                    if casse: erreurs.append(f"{page} ({w}px) images cassées {casse}")
                    if large > w: erreurs.append(f"{page} ({w}px) déborde : {large}px")
                if pe: erreurs.append(f"erreurs JS ({w}px) : {pe}")
            # chaque capture déclarée dans la base existe
            for pr in preuves:
                for im in pr["images"]:
                    if not os.path.exists(f"{DEP}/client/preuves/{im['fichier']}"):
                        erreurs.append(f"capture manquante {im['fichier']}")
            # Diagramme de la base, avec les vrais nombres de lignes du jour
            subprocess.run(["psql", "-h", "localhost", "-U", "postgres", "-d", "butsd", "-q", "-c", "ANALYZE;"], env=ENV, check=True)
            raw = subprocess.run(["psql", "-h", "localhost", "-U", "postgres", "-d", "butsd", "-At", "-f", f"{ICI}/meta.sql"],
                                 env=ENV, capture_output=True, text=True, check=True).stdout
            meta = json.loads(raw[raw.index("{"):])
            # Nombres de lignes exacts (les statistiques de PostgreSQL peuvent être en retard)
            cnt = subprocess.run(["psql", "-h", "localhost", "-U", "postgres", "-d", "butsd", "-At", "-F", "|", "-c",
                "SELECT table_name, (xpath('/row/c/text()', query_to_xml(format('SELECT count(*) AS c FROM %I.%I', table_schema, table_name), false, true, '')))[1]::text "
                "FROM information_schema.tables WHERE table_schema IN ('referentiel','portfolio') AND table_type = 'BASE TABLE'"],
                env=ENV, capture_output=True, text=True, check=True).stdout
            meta["nrows"] = {l.split("|")[0]: int(l.split("|")[1]) for l in cnt.strip().splitlines()}
            html = open(f"{ICI}/erd.html").read()
            ancien = json.loads(re.search(r"const M=(\{.*?\});\n", html).group(1))
            pos = {t["t"]: (t["x"], t["y"]) for t in ancien["tables"]}
            for t in meta["tables"]:
                t["x"], t["y"] = pos[t["t"]]; t["n"] = meta["nrows"].get(t["t"], 0)
            html = re.sub(r"const M=\{.*?\};\n", lambda m: "const M=" + json.dumps(meta, ensure_ascii=False) + ";\n", html, count=1, flags=re.S)
            open("/tmp/erd_jour.html", "w").write(html)
            pg = await b.new_page(viewport={"width": 1700, "height": 1000}, device_scale_factor=1.5)
            await pg.route("**/fonts.googleapis.com/**", lambda r: r.fulfill(body="", content_type="text/css"))
            await pg.goto("file:///tmp/erd_jour.html"); await pg.wait_for_timeout(800)
            await pg.locator("#erd").screenshot(path=f"{DEP}/bdd/schema-relationnel.png")
            await b.close()
    asyncio.run(pages())
    import shutil
    shutil.copyfile(f"{DEP}/bdd/schema-relationnel.png", f"{DEP}/maquette/schema-relationnel.png")
    print(f"{len(preuves)} preuves en ligne")
finally:
    srv.terminate(); srv.wait()
    if os.path.islink(nm): os.remove(nm)
    print("OK" if not erreurs else "ÉCHEC :\n- " + "\n- ".join(erreurs))
    sys.exit(1 if erreurs else 0)
