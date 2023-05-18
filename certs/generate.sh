# https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates

root=ca
server=server


# root - key
openssl ecparam -out $root.key -name prime256v1 -genkey

# root - cert request
openssl req -new -sha256 -key $root.key -out $root.csr

# root - cert
openssl x509 -req -sha256 -days 365 -in $root.csr -signkey $root.key -out $root.crt

# root - export cer
openssl x509 -outform der -in $root.crt -out $root.cer

# server - key
openssl ecparam -out $server.key -name prime256v1 -genkey

# server - cert request - needs additional details to be valid for TLS
openssl req -new -sha256 -key $server.key -out $server.csr

# server - cert
openssl x509 -req -in $server.csr -CA  $root.crt -CAkey $root.key -CAcreateserial -out $server.crt -days 365 -sha256

# server - view cert
openssl x509 -in $server.crt -text -noout

# server - combine key and cert
openssl pkcs12 -export -out $server.pfx -inkey $server.key -in $server.crt
