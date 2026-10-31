# ⚡ Advanced Highlights v2.0 for mIRC

<p align="center">
  <img src="https://img.shields.io/badge/mIRC-Script-blue?logo=windows" alt="mIRC Script" />
  <img src="https://img.shields.io/badge/Version-2.0-success" alt="Version 2.0" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" />
  <img src="https://img.shields.io/badge/Auteur-Paradoxe80-orange" alt="Author" />
</p>

---

## 🌟 Présentation

**Advanced Highlights** est un système de surbrillance (HL) complet, moderne et performant pour le client IRC **mIRC**. 

Il permet de ne manquer aucun message important sur vos salons IRC grâce à des alertes intelligentes, une détection souple (mot entier, partiel, expressions régulières), une journalisation interactive et une interface graphique ergonomique.

---

## ✨ Fonctionnalités Principales

### 1. 🎯 Routage & Affichage Intelligent
- **Salon d'origine garanti :** Le message est **toujours affiché dans son salon d'origine**, avec le mot clé mis en valeur en rouge vif et en gras.
- **Avertissement en fenêtre active :** Si vous êtes sur un autre canal, en message privé (PV) ou sur la fenêtre Status, vous recevez instantanément un avertissement dans votre fenêtre active courante :  
  `[HH:nn:ss] [#salon] <Pseudo> Message avec le mot surligné`
- **3 modes de destination configurables par mot :**
  - **Fenêtre active uniquement :** Affichage salon + avertissement dans la fenêtre active.
  - **Fenêtre @Highlights uniquement :** Affichage salon + archivage dans la fenêtre dédiée `@Highlights`.
  - **Les deux :** Affichage salon + avertissement actif **ET** archivage dans `@Highlights`.

### 2. 🛡️ Contrôle Anti-Doublon & Enregistrement Sécurisé
- Empêche automatiquement l'ajout de doublons (insensible à la casse).
- En cas de saisie d'un mot déjà existant, l'interface sélectionne automatiquement la ligne existante pour mise à jour rapide.
- Feedback visuel instantané avec confirmation d'enregistrement.

### 3. 🧪 Assistant d'Expressions Régulières (Regex)
- Bouton interactif **`? Exemples Regex`** ouvrant une modale avec 10 expressions régulières prêtes à l'emploi :
  - Variantes de pseudo, préfixes, diminutifs
  - Questions orientées
  - Salutations et adieux
  - Détection d'adresses IPv4, URLs / liens web
  - Mots clés d'urgence et d'assistance
- Un clic ou double-clic insère immédiatement le motif et active automatiquement le mode Regex.

### 4. 🔄 Détection Bidirectionnelle & Testeur Intégré
- Détecte les messages entrants des autres utilisateurs (`on TEXT` et `on ACTION`).
- Détecte vos propres saisies (`on INPUT`) pour tester et vérifier vos surbrillances en direct.
- Commande rapide `/hl test <mot ou phrase>` pour tester immédiatement le déclenchement de vos règles.

### 5. 📜 Fenêtre Dédiée `@Highlights` Interactive
- Journalisation complète horodatée : `[HH:nn:ss] [#salon] <Pseudo> Message`.
- **Double-clic sur une ligne :** Bascule immédiatement sur le salon correspondant et vous positionne précisément sur la ligne du HL (avec surbrillance).
- **Menu contextuel (clic-droit) :** Rejoindre le salon et localiser, ouvrir un PV avec l'auteur, vider l'historique, etc.

### 6. 🔔 Alertes Visuelles & Sonores
- Mise en valeur visuelle avec balise `[HL]` et coloration distincte.
- Clignotement de l'icône mIRC dans la barre des tâches Windows (`Flash`).
- Sélecteur de fichiers sons (WAV, MP3...) avec bouton de pré-écoute et contrôle individuel par mot.

---

## 🚀 Installation

### Méthode 1 : Git Clone (Recommandée)
```bash
git clone https://github.com/daviddespark/Advanced_Highligts.git
```
Déposez ensuite le dossier dans votre répertoire mIRC (ou sous-dossier `scripts\`).

### Méthode 2 : Téléchargement Direct
Téléchargez l'archive ZIP via le bouton vert **`Code > Download ZIP`** sur GitHub et extrayez-la.

### Chargement dans mIRC
Dans la ligne de commande de votre client **mIRC**, tapez :
```mirc
/load -rs scripts\highlight.mrc
```
*(Ou `/load -rs highlight.mrc` si le script est placé à la racine de votre dossier mIRC)*.

Pour recharger le script après une mise à jour :
```mirc
/reload -rs highlight.mrc
```

---

## ⌨️ Commandes Console

| Commande | Description |
| :--- | :--- |
| `/hl` | Ouvre le panneau de configuration graphique (GUI) |
| `/hl test <phrase>` | Teste immédiatement la détection et la surbrillance d'une phrase |
| `/hl on` | Active le système global de Highlights |
| `/hl off` | Désactive le système global de Highlights |
| `/hl toggle` | Bascule l'état (Actif / Inactif) |
| `/hl win` | Ouvre ou affiche la fenêtre dédiée `@Highlights` |
| `/hl list` | Liste tous les mots et motifs configurés dans la console Status |
| `/hl add <mot> [active\|fenetre\|both] [son]` | Ajout rapide en ligne de commande avec anti-doublon |
| `/hl del <mot_ou_index>` | Supprime un highlight par son mot clé ou son numéro d'index |
| `/hl clear` | Vide l'historique de la fenêtre `@Highlights` |

---

## 🖱️ Menus & Raccourcis Clic-Droit

- **Barre de Menus mIRC (`menubar`) :** Entrée `Highlights` pour configurer, afficher `@Highlights` ou basculer l'état.
- **Salons & Requêtes privées (`channel, query`) :** Clic droit ➔ `Highlights` ➔ Ajouter un mot ou tester.
- **Liste des pseudos (`nicklist`) :** Clic droit sur un pseudo ➔ `Highlights` ➔ Ajouter `<Pseudo>` en Highlight (Les deux / Fenêtre active / @Highlights).
- **Fenêtre `@Highlights` :** Double-clic pour naviguer vers le salon ; clic droit pour accéder aux actions rapides.

---

## 📄 Licence

Ce projet est distribué sous licence Open Source **MIT**. Consultez le fichier [LICENSE](LICENSE) pour plus d'informations.

---

## 👤 Auteur

- **Paradoxe80** (GitHub : [@daviddespark](https://github.com/daviddespark))
