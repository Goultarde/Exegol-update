# ⚠️ AVERTISSEMENT : Projet en version bêta !

Ce projet est en cours de développement. 
- L'intégration crontab n'a pas encore été testée en profondeur. Utilisez avec précaution.

# Exegol-update

## Présentation

Exegol-update est un outil facilitant la gestion, la distribution et le chargement automatisé d'images Docker Exegol, via une architecture client-serveur moderne basée sur Docker et Nginx.

## Prérequis

- Système Linux avec droits administrateur (root)
- [Exegol](https://github.com/ThePorgs/Exegol) installé sur le serveur (utilisé pour le build des images)
- [Docker](https://docs.docker.com/get-docker/) et [Docker Compose](https://docs.docker.com/compose/install/) installés

## Installation

### 1. Installer Cronie, Docker, Docker Compose et ce rajouter dans le groupe docker
```bash
sudo usermod -aG docker $USER
newgrp docker # temportaire, il vaut mieux redémarer la session
sudo systemctl enable docker --now
```

### 2. Installer Exegol (sur le serveur)

```bash
pipx install exegol
pipx ensurepath
exec [bash|zsh|...]
exegol info --accept-eula
```

### 3. Cloner ce dépôt

```bash
git clone https://github.com/Goultarde/Exegol-update.git  && cd Exegol-update
```




## Utilisation

### Initialisation des dossiers

Lancez le script d'initialisation pour préparer l'environnement :

```bash
./exu.sh
#ou : sudo mkdir -p /exu && sudo chown -R $USER:$USER /exu
```

### Déploiement du serveur

Depuis le dossier `./server` :

```bash
cd server
./setup.sh [--now] # --now permet de démarer directement un premier build
# contrab -e :  pour supprimer ou modifier le crontab crée.
```

Ce script :
- Prépare les dossiers nécessaires pour stocker les images et les logs.
- Déploie un serveur Nginx dans un conteneur Docker pour exposer les images `.tar`
- Ajoute une tâche cron pour automatiser la gestion des images

#### Options disponibles

- `--now` : Lance immédiatement `exu-server` après le setup pour construire et exporter une image (utile pour un premier déploiement)
- `-h, --help` : Affiche l'aide du script

### Utilisation du client

Depuis le dossier `client/` :

```bash
cd client
./initial_setup.sh
exu-client [options]
```
`initial_setup.sh` = rend l'executable exu-client global.

Si aucune option n'est fournie, exu-client télécharge et charge automatiquement la dernière image .tar disponible sur le serveur, sauf si elle est déjà présente localement. Une confirmation sera demandée avant chaque action importante, sauf si les mode --auto et ou --force sont activé.

#### Options principales

- `--list, -l` : Liste les images disponibles sur le serveur
- `--force, -f` : Force le téléchargement même si le fichier existe déjà
- `--load-only` : Charge une image locale sans contacter le serveur
- `--tag=[nom:tag||tag]` : Re-tag l'image après chargement (formats valides : `nom:tag` ou `tag` seul). Par défaut, le tag est "FreeNightly" (modifiable dans le code).
- `--auto, -a` : Mode automatique (aucune interaction requise)
- `--server=[URL]` : Change l'URL du serveur (format : `http://HOST:PORT` ou `https://HOST:PORT`)
- `--check-commit` : Vérifie et affiche s'il y a un nouveau commit disponible (basé sur le hash Git)
- `-h, --help` : Affiche l'aide détaillée

#### Exemples d'utilisation

```bash
# Utilisation basique (serveur local par défaut)
exu-client

# Connexion à un serveur distant
exu-client --server=http://192.168.1.100:9000
exu-client --server=https://exegol-server.local:8443

# Vérification des nouveaux commits
exu-client --check-commit
exu-client --server=http://192.168.1.100:9000 --check-commit

# Combinaison d'options
exu-client --server=http://exegol.example.com:9000 --auto --force
exu-client --server=https://exu-prod.internal:8443 --list
```

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
- `--force` : Force le build même sans nouveau commit détecté
- `-h, --help` : Affiche l'aide et quitte le script

Ce script est normalement lancé automatiquement via une tâche cron (voir la section "Déploiement du serveur").

**Il peut également être exécuté manuellement à tout moment pour forcer une mise à jour immédiate :**

```bash
cd server
./exu-server
```

Cela permet de déclencher la reconstruction et l'export de l'image sans attendre la prochaine exécution planifiée.

### Vérification des nouveaux commits

Le client `exu-client` peut vérifier rapidement s'il y a de nouveaux commits disponibles sans télécharger d'images :

```bash
exu-client --check-commit
```

Cette commande :
- Récupère le hash du dernier commit depuis le serveur (`latest_commit.hash`)
- Compare avec le hash local stocké
- Affiche `[+] Nouveau commit disponible` ou `[-] Pas de nouveau commit`

Cette fonctionnalité est utile pour :
- Vérifier rapidement l'état des mises à jour
- Automatiser les vérifications dans des scripts
- Éviter les téléchargements inutiles

