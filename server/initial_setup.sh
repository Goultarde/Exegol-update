#!/bin/bash
# Rendre exu-client accessible à tous les utilisateurs
sudo cp $(dirname "$0")/exu-server /usr/local/bin/exu-server
sudo chmod +x /usr/local/bin/exu-client
