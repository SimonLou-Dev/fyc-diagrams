# Diagrammes du cours

Diagrammes d'architecture en code (D2, PlantUML), rendus en SVG par Kroki
dans GitHub Actions et publiés sur GitHub Pages. Moodle affiche les images
par URL : une modification fusionnée sur `main` est visible dans le cours
quelques minutes plus tard, sans ré-upload.

```
sources/          sources des diagrammes (.d2, .puml)
styles/           thèmes communs (theme.d2, theme.puml)
scripts/render.sh rendu, identique en local et en CI
public/           sortie générée, ignorée par Git
```

## Mise en place (une seule fois)

1. Créer le dépôt sur GitHub (**public** : un `<img>` dans Moodle ne peut pas
   s'authentifier) et pousser ce contenu sur `main`.
2. `Settings > Pages > Build and deployment > Source` : choisir **GitHub Actions**.
3. `Settings > Branches` : ajouter une règle de protection sur `main` :
   pull request obligatoire, 1 approbation, check `render` obligatoire.
   C'est ce qui garantit que les trois respectent le thème : chaque
   diagramme est relu par quelqu'un d'autre.
4. Remplacer `yuzutech/kroki:latest` par une version fixe, au même endroit
   dans `docker-compose.yml` et dans le workflow.
5. Lancer le workflow une fois (`Actions > Diagrams > Run workflow`) puis
   ouvrir `https://<compte>.github.io/<depot>/` : la page liste tous les SVG.

## Travailler en local

```bash
docker compose up -d          # démarre Kroki sur 127.0.0.1:8000
./scripts/render.sh           # génère public/*.svg et public/index.html
xdg-open public/index.html    # ou open sur macOS
```

Pour éditer avec aperçu en direct, l'extension D2 de VS Code fonctionne
directement grâce à la ligne `...@../styles/theme` en tête des sources.

## Insérer un diagramme dans Moodle

Dans l'éditeur : *Image* > *URL* :

```
https://<compte>.github.io/<depot>/<nom-du-fichier>.svg
```

Renseignez toujours le texte alternatif (accessibilité).

## Conventions

- **Nommage** : `kebab-case.d2`, sans accent ni espace. Le nom du fichier
  devient l'URL dans Moodle : **renommer un fichier casse le lien**.
- **Style** : uniquement les classes du thème (`zone`, `service`,
  `database`, `queue`, `external`, `flux-async`). Pas de `style` en ligne.
  Besoin d'une nouvelle classe : on l'ajoute au thème via une PR dédiée.
- **Thème** : `theme.d2` ne contient que `vars` et `classes`. Tout objet
  déclaré dedans apparaîtrait dans chaque diagramme.
- **Deux thèmes** : `theme.d2` et `theme.puml` partagent la même palette.
  Toute modification de couleur se fait dans les deux. Si vous n'utilisez
  pas PlantUML, supprimez `theme.puml` pour n'avoir qu'une source de vérité.

## Limites connues

- Pas de versionnage côté Moodle : modifier un diagramme le change pour
  tous les étudiants immédiatement, y compris pour un chapitre déjà vu.
- Si le dépôt est supprimé ou rendu privé, les images disparaissent du
  cours. Une sauvegarde Moodle n'inclut pas ces images externes.
- Délai de quelques minutes (cache Pages et navigateur) entre la fusion
  et l'affichage dans Moodle.
- Mermaid n'est pas pris en charge : il nécessite le conteneur compagnon
  `yuzutech/kroki-mermaid`, à ajouter si besoin.
