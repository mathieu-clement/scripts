#!/bin/sh

# Suppose you have a website running with Flask / Wordpress / CherryPi on port 1234
# and that you want to make available at mysite.mydomain.tld.
# You can just run this script like so: ./generate-transparent-ssl-proxy.sh mysite.mydomain.tld 1234
# and it will automatically create the required configuration files and provision a certificate from
# Let's Encrypt through certbot.

set -eu

dir=$(dirname $0)
cd $dir

if ! [ -x "$(command -v certbot)" ]; then
    echo 'Error: certbot is not installed.' >&2
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 domain port" >&2
    exit 1
fi

DOMAIN=$1
PORT=$2

echo "Creating virtual host config..."

echo "
server {
    server_name $DOMAIN;

    location / {
        proxy_set_header   X-Forwarded-For "\$"remote_addr;
        proxy_set_header   Host "\$"http_host;
        proxy_pass         "http://127.0.0.1:$PORT";
    }

    listen 80;
    listen [::]:80;
}
" > $DOMAIN.conf

echo "Creating sites-enabled symlink..."
cd ../sites-enabled
ln -fs ../sites-available/$DOMAIN.conf ./


echo "Reloading nginx..."
systemctl reload nginx
sleep 5

echo "Obtaining SSL/TLS certicates..."
certbot --nginx -d $DOMAIN

echo "Reloading nginx..."
sleep 5
systemctl reload nginx
