#!/bin/bash
# Rendre exu-client accessible à tous les utilisateurs
sudo cp $(dirname "$0")/exu-client /usr/local/bin/exu-client
sudo chmod +x /usr/local/bin/exu-client
