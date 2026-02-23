FROM nginx:alpine

# Creation of destination directory in container
RUN mkdir -p /exu/exegol-update-server/exu-tars

# Copying the custom Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Mount point for Exegol archives
VOLUME ["/exu/exegol-update-server/exu-tars"]

# Expose the standard HTTP port
EXPOSE 80
