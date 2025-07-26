sudo mkdir -p /exu && sudo chown -R $USER:$USER /exu

# Créer un lien symbolique vers exegol dans /usr/local/bin/ si nécessaire
if ! command -v exegol &> /dev/null; then
    echo "Exegol n'est pas trouvé dans le PATH"
    exit 1
fi

EXEGOL_PATH=$(which exegol)
if [[ ! -L /usr/local/bin/exegol ]] || [[ "$(readlink /usr/local/bin/exegol)" != "$EXEGOL_PATH" ]]; then
    echo "Création du lien symbolique vers exegol dans /usr/local/bin/"
    sudo ln -sf "$EXEGOL_PATH" /usr/local/bin/exegol
    echo "Lien créé : /usr/local/bin/exegol -> $EXEGOL_PATH"
else
    echo "Le lien symbolique vers exegol existe déjà dans /usr/local/bin/"
fi
