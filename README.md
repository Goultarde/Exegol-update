# ⚠️ AVERTISSEMENT : Projet en version bêta !

Ce projet est en cours de développement. 
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
```

### 3. Cloner ce dépôt

```bash
git clone https://github.com/Goultarde/Exegol-update.git  && cd Exegol-update
```




## Utilisation

### Interface TUI de configuration

Exegol-update dispose d'une interface TUI (Terminal User Interface) pour simplifier la configuration :

```bash
./exu.sh
```

Cette interface vous permet de :

#### **Menu principal**
```
╔══════════════════════════════════════════════════════════════╗
║                    EXEGOL-UPDATE SETUP                       ║
╚══════════════════════════════════════════════════════════════╝

Choisissez une option :

  1 - Configuration du serveur
  2 - Configuration du client
  3 - Setup et vérification de l'environnement
  4 - Quitter

Utilisez les flèches ↑↓ ou les chiffres (1-4) pour naviguer
Appuyez sur 'q' pour quitter directement
```

#### **Options disponibles**

- **1 - Configuration du serveur** : Lance `server/setup.sh` avec option de build immédiat
- **2 - Configuration du client** : Lance `client/initial_setup.sh` pour configurer le client
- **3 - Setup et vérification de l'environnement** : Vérifie et configure automatiquement l'environnement
- **4 - Quitter** : Sortie propre de l'interface

#### **Navigation**
- **Flèches ↑↓** : Naviguer dans le menu
- **Chiffres 1-4** : Sélection directe
- **Entrée** : Confirmer la sélection
- **q** : Quitter rapidement

### Configuration automatique de l'environnement

L'option 3 (Setup et vérification de l'environnement) effectue automatiquement :

- ✅ Vérification d'Exegol, Docker et Docker Compose
- ✅ Création du dossier `/exu` avec les bonnes permissions
- ✅ Création du lien symbolique vers exegol dans `/usr/local/bin/`
- ✅ Acceptation automatique de l'EULA d'Exegol
- ✅ Vérification des dossiers serveur/client

### Fonctionnement du déploiement du serveur

Le déploiement du serveur se fait via l'interface TUI (option 1) qui lance automatiquement :

- Préparation des dossiers nécessaires pour stocker les images et les logs
- Déploiement d'un serveur Nginx dans un conteneur Docker pour exposer les images `.tar`
- Ajout d'une tâche cron pour automatiser la gestion des images
- Option de build immédiat pour un premier déploiement

### Utilisation du client

#### **Configuration automatique**
La configuration du client se fait via l'interface TUI (option 2) qui :

- Installe `exu-client` dans `/usr/local/bin/` (accessible globalement)
- Configure automatiquement le fichier `/etc/hosts` avec l'IP du serveur
- Crée l'entrée `exegol.update` pour faciliter la connexion

#### **Utilisation du client**
```bash
exu-client [options]
```

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

# Utilisation avec nom de domaine configuré
exu-client --server=http://exegol.update:9000

# Vérification des nouveaux commits
exu-client --check-commit
exu-client --server=http://192.168.1.100:9000 --check-commit

# Combinaison d'options
exu-client --server=http://exegol.example.com:9000 --auto --force --tag=Nightly
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

### Nettoyage automatique

Le script `exu-server` nettoie automatiquement les anciens fichiers `.tar` :
- Supprime tous les fichiers `.tar` avec le même préfixe avant de créer le nouveau
- Évite l'accumulation de fichiers anciens
- Garde seulement le fichier le plus récent par profil

Ce script est normalement lancé automatiquement via une tâche cron (voir la section "Déploiement du serveur").

**Il peut également être exécuté manuellement à tout moment pour forcer une mise à jour immédiate :**

```bash
cd server
./exu-server [--force] [--debug]
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

## Fonctionnalités avancées

### Gestion des ports par défaut

Le client `exu-client` supporte les URLs sans port spécifié :
- **HTTP** : Port 80 par défaut
- **HTTPS** : Port 443 par défaut

```bash
# Ces commandes sont équivalentes
exu-client --server=http://exegol.example.com:80
exu-client --server=http://exegol.example.com

# Ces commandes sont équivalentes
exu-client --server=https://exegol.example.com:443
exu-client --server=https://exegol.example.com
```

### Synchronisation automatique des hashes

Le client met automatiquement à jour son fichier `latest_commit.hash` local après chaque téléchargement réussi, garantissant des vérifications de commits précises lors des prochaines utilisations.

