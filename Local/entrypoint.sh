#!/bin/bash

set -x 

HTTPS=${HTTPS:-'true'}
JWT_SECRET=${JWT_SECRET:-'testtesttesttest'}
ip=$(ifconfig | grep eno -A1 | grep inet | awk '{print $2}')
ORIGIN=${ORIGIN:-$ip}

# Creation of certificates
if [[ "$HTTPS" == "true" ]]; then
    if [[ -e "./server.pem" && -e "./server.key" ]]; then
        echo "Already created ./server.pem and ./server.key"
    else
        openssl req -nodes -newkey rsa:4096 -keyout ./server.key -out ./server.csr  -subj "/CN=OWASP-SKF"
        openssl x509 -req -days 365 -in ./server.csr  -signkey ./server.key -out ./server.pem
        rm ./server.csr
    fi
fi

if [[ "$JWT_SECRET" != "changeme" ]]; then
    perl -pi -e "s/JWT_SECRET = ''/JWT_SECRET = '$JWT_SECRET'/" ../skf/settings.py
else
    echo 'You need to select a JWT_SECRET'
    exit
fi

if [[ "$ORIGIN" != "" ]]; then
    perl -pi -e "s/\*/https:\/\/$ORIGIN/" ../skf/settings.py
    perl -pi -e "s/0.0.0.0/$ORIGIN/" ../Angular/package.json
    perl -pi -e "s/localhost/$ORIGIN/" ../Angular/src/environments/environment.prod.ts

    if [[ "$HTTPS" == "true" ]]; then
        perl -pi -e "s/http:\/\/localhost:4200/https:\/\/$ORIGIN/" ../Angular/package.json
        cp site-tls.conf.default site-tls.conf
	perl -pi -e "s/localhost/$ORIGIN/g" site-tls.conf
	cd ../Angular
	root=$(pwd)
        root=$(echo $root | sed -r s/[/]/'\\\/'/g)
	cd ../Local
	perl -pi -e "s/pwd/$root/g" site-tls.conf
    else
        perl -pi -e "s/localhost:4200/$ORIGIN/" ../Angular/package.json
    fi
else
    echo 'You need to select a ORIGIN location'
    exit
fi

if [[ "$HTTPS" == "true" ]]; then
    cp server.key /etc/nginx
    cp server.pem /etc/nginx
    cp site-tls.conf /etc/nginx/nginx.conf
    rm site-tls.conf
else
    cp site.conf /etc/nginx/nginx.conf
fi

# Start nginx
sleep 5
nginx

# Start SKF services
bash wrapper.sh
