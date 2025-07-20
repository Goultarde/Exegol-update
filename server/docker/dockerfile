FROM nginx:alpine

# Création du répertoire de destination dans le conteneur
RUN mkdir -p /exu/exegol-update-server/exu-tars

# Copie du fichier de configuration Nginx personnalisé
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Point de montage pour les archives Exegol
VOLUME ["/exu/exegol-update-server/exu-tars"]

# Expose le port HTTP standard
EXPOSE 80
