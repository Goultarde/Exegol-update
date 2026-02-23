FROM nginx:alpine

# Creation of destination directory in container
RUN mkdir -p /exu/exegol-update-server/exu-tars

# Copying the custom Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Point de montage pour les archives Exegol
VOLUME ["/exu/exegol-update-server/exu-tars"]

# Expose le port HTTP standard
EXPOSE 80
