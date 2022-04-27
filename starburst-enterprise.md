## Starburst Enterprise
Note this is a single worker node combined with coordinator node. Usually they should be a cluster of nodes each. This is only for PoC

### aws market place
https://aws.amazon.com/marketplace/pp/prodview-pwnl3c6p2jycg

### starburst ui
http://{ip}:8080/ui/insights

### connector to sql server
https://docs.starburst.io/starburst-enterprise/try/catalog.html

### marketplace EC2 start up scripts
```
sudo su

# catalog setup - https://docs.starburst.io/latest/connector/starburst-sqlserver.html
echo 'connector.name=sqlserver
connection-url=jdbc:sqlserver://{rds-endpoint}:1433;database={dbname}
connection-user={username}
connection-password={password}' > /etc/starburst/catalog/{catalog}.properties

# https setup - https://docs.starburst.io/latest/security/tls.html
echo 'http-server.process-forwarded=true' >> /etc/starburst/config.properties

# auth setup - https://docs.starburst.io/latest/security/oauth2-providers.html; https://docs.starburst.io/latest/security/password-file.html
echo 'http-server.authentication.type=OAUTH2,PASSWORD
http-server.authentication.oauth2.issuer=https://{oauth-idp-server-urls}
http-server.authentication.oauth2.auth-url=https://{oauth-idp-server-urls}/authorize
http-server.authentication.oauth2.token-url=https:/{oauth-idp-server-urls}/token
http-server.authentication.oauth2.jwks-url=https://{oauth-idp-server-urls}/keys
http-server.authentication.oauth2.client-id={oauth-clientid}
http-server.authentication.oauth2.client-secret={oauth-clientsecret}
web-ui.authentication.type=OAUTH2' >> /etc/starburst/config.properties

echo 'password-authenticator.name=file
file.password-file=/etc/starburst/password.db' > /etc/starburst/password-authenticator.properties
yum install httpd-tools -y
touch /etc/starburst/password.db
htpasswd -B -C 10 -b password.db {service-user} {service-user-password}

# debug SSO (optional), logs in /var/log/starburst/server.log
# echo 'io.trino.server.security.oauth2=DEBUG' >> /etc/starburst/log.properties

source /etc/starburst/run-starburst.sh restart
```
