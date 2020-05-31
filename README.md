# certbot-safedns-authenticator

certbot auth file for performing manual dns auth validation.   
based on certbot example - https://certbot.eff.org/docs/using.html?highlight=dns#pre-and-post-validation-hooks

### issue new cert

```bash
# certbot certonly --manual \
--preferred-challenges=dns \
--manual-auth-hook /etc/letsencrypt/safedns-authenticator.sh \
--manual-cleanup-hook /etc/letsencrypt/safedns-authenticator.sh \
--manual-public-ip-logging-ok \
-d gavtaylor.uk -d *.gavtaylor.uk
```

### verify cert

```bash
# certbot certificates
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: gavtaylor.uk
    Serial Number: 3d0eceebd15c5fed908d55682395cc924d8
    Domains: gavtaylor.uk *.gavtaylor.uk
    Expiry Date: 2020-08-29 15:25:12+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/gavtaylor.uk/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/gavtaylor.uk/privkey.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

### renew cert

```bash
# certbot renew
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/gavtaylor.uk.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Cert not yet due for renewal

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

The following certs are not due for renewal yet:
  /etc/letsencrypt/live/gavtaylor.uk/fullchain.pem expires on 2020-08-29 (skipped)
No renewals were attempted.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

```
