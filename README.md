# ⚠️ AVERTISSEMENT : Projet en version bêta !

Ce projet est en cours de développement. 
- L'intégration crontab n'a pas encore été testée en profondeur : son comportement peut varier selon les environnements. Utilisez avec précaution en production.

# Exegol-update

## Présentation

Exegol-update est un outil facilitant la gestion, la distribution et le chargement automatisé d'images Docker Exegol, via une architecture client-serveur moderne basée sur Docker et Nginx.

## Prérequis

- Système Linux avec droits administrateur (root)
- [Exegol](https://github.com/ThePorgs/Exegol) installé sur le serveur (utilisé pour le build des images)
- [Docker](https://docs.docker.com/get-docker/) et [Docker Compose](https://docs.docker.com/compose/install/) installés

## Installation

### 1. Installer Exegol (sur le serveur)

```bash
sudo pipx install exegol
```

### 2. Cloner ce dépôt

```bash
sudo git clone git@github.com:Goultarde/Exegol-update.git /opt/Exegol-update && sudo chown $USER:$USER /opt/Exegol-update && cd /opt/Exegol-update
```

### 3. Installer Docker et Docker Compose

```bash
sudo apt update
sudo apt install docker docker-compose
```

## Utilisation

### Initialisation des dossiers

Lancez le script d'initialisation pour préparer l'environnement :

```bash
./exu.sh
```

### Déploiement du serveur

Depuis le dossier `server/` :

```bash
cd server
./setup.sh
```

Ce script :
- Prépare les dossiers nécessaires
- Déploie un serveur Nginx dans un conteneur Docker pour exposer les images `.tar`
- Ajoute une tâche cron pour automatiser la gestion des images

### Utilisation du client

Depuis le dossier `client/` :

```bash
cd client
./exu-client [options]
```

#### Options principales

- `--list, -l` : Liste les images disponibles sur le serveur
- `--force, -f` : Force le téléchargement même si le fichier existe déjà
- `--load-only` : Charge une image locale sans contacter le serveur
- `--tag=[nom:tag||tag]` : Re-tag l'image après chargement (formats valides : `nom:tag` ou `tag` seul). Par défaut, le tag est "FreeNightly" (modifiable dans le code).
- `--auto, -a` : Mode automatique (aucune interaction requise)
- `-h, --help` : Affiche l'aide détaillée

## Architecture

- **Serveur** : Expose les images Docker via Nginx dans un conteneur, avec gestion automatisée par cron.
- **Client** : Télécharge, charge et re-tag les images Docker de façon interactive ou automatisée.

## Script serveur : exu-server

Le script `exu-server` (présent dans le dossier `server/`) automatise les étapes suivantes :
- Clonage ou mise à jour du dépôt d'images Exegol
- Construction de l'image Docker selon le profil défini
- Export de l'image au format `.tar` dans le dossier partagé
- Journalisation des opérations dans un fichier de log

### Options disponibles

- `--debug` : Utilise le dépôt Goultarde, branche main, profil light (mode test)
- `-h, --help` : Affiche l'aide et quitte le script

Ce script est normalement lancé automatiquement via une tâche cron (voir la section "Déploiement du serveur").

**Il peut également être exécuté manuellement à tout moment pour forcer une mise à jour immédiate :**

```bash
cd server
./exu-server
```

Cela permet de déclencher la reconstruction et l'export de l'image sans attendre la prochaine exécution planifiée.

