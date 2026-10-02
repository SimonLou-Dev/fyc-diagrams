#!/usr/bin/env bash
# Rend tous les diagrammes de sources/ en SVG dans public/ via Kroki.
#
# Le MEME script tourne en local et en CI : si le rendu passe chez vous,
# il passe en CI. Ne dupliquez pas cette logique dans le workflow.
#
# Usage :
#   docker compose up -d        # démarre Kroki en local
#   ./scripts/render.sh         # génère public/*.svg
#   KROKI_URL=http://autre:8000 ./scripts/render.sh

set -euo pipefail
shopt -s nullglob

KROKI_URL="${KROKI_URL:-http://localhost:8000}"
SRC_DIR="sources"
STYLE_DIR="styles"
OUT_DIR="public"

# Se placer à la racine du dépôt, quel que soit le dossier d'appel
cd "$(dirname "$0")/.."

mkdir -p "$OUT_DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

errors=0
count=0

# Kroki reçoit le diagramme dans le corps HTTP et n'a pas accès au dépôt :
# les imports de fichiers locaux ne peuvent pas être résolus côté serveur.
# On injecte donc le thème nous-mêmes et on retire la ligne d'import.

prepare_d2() {
  # Thème en tête, puis la source sans les lignes "...@" (imports D2)
  cat "$STYLE_DIR/theme.d2"
  sed '/^[[:space:]]*\.\.\.@/d' "$1"
}

prepare_puml() {
  # Le thème doit se trouver APRES @startuml, sinon PlantUML l'ignore.
  # On retire aussi un éventuel !include local du thème.
  awk -v theme="$STYLE_DIR/theme.puml" '
    /^[[:space:]]*!include[[:space:]].*theme\.puml/ { next }
    /^[[:space:]]*@startuml/ {
      print
      while ((getline line < theme) > 0) print line
      next
    }
    { print }
  ' "$1"
}

render() {
  # $1 = type Kroki (d2, plantuml...), $2 = fichier source
  local type="$1" src="$2" name
  name="$(basename "${src%.*}")"
  count=$((count + 1))

  # -f : un code HTTP >= 400 (erreur de syntaxe) fait échouer curl
  if curl -sS -f -X POST "$KROKI_URL/$type/svg" \
       -H "Content-Type: text/plain" \
       --data-binary @"$tmp" \
       -o "$OUT_DIR/$name.svg"; then
    echo "OK      $src"
  else
    echo "ERREUR  $src" >&2
    rm -f "$OUT_DIR/$name.svg"
    errors=$((errors + 1))
  fi
}

# On continue après une erreur pour lister TOUS les diagrammes cassés
# en une seule exécution, puis on échoue globalement à la fin.
for f in "$SRC_DIR"/*.d2; do
  prepare_d2 "$f" > "$tmp"
  render d2 "$f"
done

for f in "$SRC_DIR"/*.puml; do
  prepare_puml "$f" > "$tmp"
  render plantuml "$f"
done

# Page d'index : permet de retrouver et copier l'URL de chaque SVG
{
  echo '<!doctype html><html lang="fr"><head><meta charset="utf-8">'
  echo '<title>Diagrammes du cours</title>'
  echo '<style>body{font-family:sans-serif;max-width:1100px;margin:2rem auto;padding:0 1rem}'
  echo 'figure{border:1px solid #ddd;padding:1rem;margin:0 0 2rem}img{max-width:100%}</style>'
  echo '</head><body><h1>Diagrammes du cours</h1>'
  for svg in "$OUT_DIR"/*.svg; do
    n="$(basename "$svg")"
    echo "<figure><img src=\"$n\" alt=\"$n\"><figcaption><code>$n</code></figcaption></figure>"
  done
  echo '</body></html>'
} > "$OUT_DIR/index.html"

echo "---"
echo "$count diagramme(s) traité(s), $errors erreur(s)."
[ "$errors" -eq 0 ]
