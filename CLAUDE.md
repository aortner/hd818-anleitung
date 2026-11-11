# CLAUDE.md – anleitung-vector

Benutzerhandbuch **HD818 (Vector Agr / Huida, Software Vectoris Pro)** als Markdown, Deutsch + Englisch.

- `en/README.md` – Englisch, Grundlage ist `Anleitung_818_eng.docx` (G:\Meine Ablage\AgOpenGps\Infos der Hersteller\VETOR AGR\Anleitung\Software)
- `de/README.md` – Deutsch; gleiche Kapitelstruktur wie EN
- `bilder/` – gemeinsame Bilder (Namen `imageNN` = Reihenfolge in der docx)
- `glossar.md` – feste Begriffe EN↔DE, gilt für jede Änderung
- `build.ps1` – pandoc → `out/anleitung-de.html` / `-en.html` (Bilder eingebettet); `-Pdf` druckt zusätzlich per Chrome headless zu PDF
- `tools/clean.lua` – pandoc-Filter für die Erstkonvertierung aus Word (nur bei Neuimport nötig)

- `build.ps1 -Web` – `_site/` für GitHub Pages (Bilder als Dateien); läuft per `.github/workflows/pages.yml` bei jedem Push auf `main`

Online: https://aortner.github.io/hd818-anleitung/ (Repo aortner/hd818-anleitung, öffentlich; Erlaubnis Vector/Huida liegt vor).

Regeln: Jede inhaltliche Änderung in **beiden** Sprachen. `out/` und `_site/` sind nicht versioniert. Öffentlich: keine persönlichen Daten in Bildern (App-Screenshot ist geschwärzt). Push nur nach Rückfrage.
