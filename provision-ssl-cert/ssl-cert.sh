#!/bin/sh
# This script will configure an Apache virtual host with SSL for a provided domain.

# Fetch domain to use from first provided parameter,
DOMAIN="<DOMAIN_NAME>" 

# Ensure a domain was provided otherwise display
# an error message and stop the script
if [ -z "$DOMAIN" ]; then
  >&2 echo 'ERROR: A domain must be provided to run this script'
  exit 1
fi

# Install core system packages
apt update
apt install -y apache2 certbot python3-certbot-apache

# Set up Apache virtual host
cat >/etc/apache2/sites-available/${DOMAIN}.conf <<EOL
<VirtualHost *:80>
    ServerName ${DOMAIN}

    # Redirect all HTTP requests to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

    ErrorLog ${APACHE_LOG_DIR}/error-${DOMAIN}.log
    CustomLog ${APACHE_LOG_DIR}/access-${DOMAIN}.log combined
</VirtualHost>

<VirtualHost *:443>
    ServerName ${DOMAIN}

    # # Enable SSL
    # SSLEngine on
    # SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    # SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem
    # Include /etc/letsencrypt/options-ssl-apache.conf
    # SSLOpenSSLConfCmd DHParameters /etc/letsencrypt/ssl-dhparams.pem

    # Proxy settings for ${DOMAIN}
    ProxyPreserveHost On
    ProxyPass / http://localhost:8080/
    ProxyPassReverse / http://localhost:8080/

    # Proxy headers
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "443"
    ProxyPassReverseCookiePath / /
    ProxyPassReverseCookieDomain localhost ${DOMAIN}

    ErrorLog ${APACHE_LOG_DIR}/error-${DOMAIN}.log
    CustomLog ${APACHE_LOG_DIR}/access-${DOMAIN}.log combined
</VirtualHost>
EOL

# Enable the new virtual host and required modules
a2enmod proxy
a2enmod proxy_http
sudo apache2ctl configtest
a2dissite 000-default.conf
a2ensite ${DOMAIN}.conf
a2enmod rewrite ssl headers proxy proxy_http

# Restart Apache to apply changes
systemctl restart apache2

# Obtain SSL certificate using Certbot
certbot --apache -d $DOMAIN --non-interactive --agree-tos --email admin@${DOMAIN}

# Set up automatic SSL certificate renewal
echo "0 0 * * * certbot renew --quiet" | crontab -

echo ""
echo "SSL has been configured for the domain: https://$DOMAIN/"