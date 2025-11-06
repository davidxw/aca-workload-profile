# https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates
# https://pki-tutorial.readthedocs.io/en/latest/simple/server.conf.html

root=ca
server=server
S
# root - key
openssl ecparam -out ./output/$root.key -name prime256v1 -genkey

# root - cert request
openssl req -new -sha256 -key ./output/$root.key -out ./output/$root.csr -config config.cnf

# root - cert
openssl x509 -req -sha256 -days 365 -in ./output/$root.csr -signkey ./output/$root.key -out ./output/$root.crt

# root - export cer
openssl x509 -outform der -in ./output/$root.crt -out ./output/$root.cer

# server - key
openssl ecparam -out ./output/$server.key -name prime256v1 -genkey

# server - cert request - needs additional details to be valid for TLS
openssl req -new -sha256 -key ./output/$server.key -out ./output/$server.csr  -config config.cnf

# server - cert
openssl x509 -req -in ./output/$server.csr -CA ./output/$root.crt -CAkey ./output/$root.key -CAcreateserial -out ./output/$server.crt -days 365 -sha256

# server - view cert
openssl x509 -in ./output/$server.crt -text -noout

# server - combine key and cert
openssl pkcs12 -export -out ./output/$server.pfx -inkey ./output/$server.key -in ./output/$server.crt

# copy the pfx to the root directory for bicep deployment
cp ./output/$server.pfx ../acatest.internal.com.pfx

