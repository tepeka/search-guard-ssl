#!/bin/bash
#########################
# 'dname' and 'ext san' have to specified on two location in this file  
# For the meaning of oid:1.2.3.4.5.5 see:
#    https://github.com/floragunncom/search-guard-docs/blob/master/architecture.md
#    https://github.com/floragunncom/search-guard-docs/blob/master/installation.md
#########################

set -e
NODE_NAME=node-$1
DOMAIN=$2

if [ -z "$4" ] ; then
  unset CA_PASS KS_PASS
  echo enter node cert secrets
  read -p "1) CA pass: " -s CA_PASS ; echo
  read -p "2) Keystore pass: " -s KS_PASS ; echo
 else
  KS_PASS=$3
  CA_PASS=$4
fi

rm -f output/$NODE_NAME-keystore.jks
rm -f output/$NODE_NAME.csr
rm -f output/$NODE_NAME-signed.pem

BIN_PATH="keytool"

if [ ! -z "$JAVA_HOME" ]; then
    BIN_PATH="$JAVA_HOME/bin/keytool"
fi

echo Generating keystore and certificate for node $NODE_NAME

"$BIN_PATH" -genkey \
        -alias     $NODE_NAME \
        -keystore  output/$NODE_NAME-keystore.jks \
        -keyalg    RSA \
        -keysize   2048 \
        -validity  712 \
        -sigalg SHA256withRSA \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$NODE_NAME.$DOMAIN, OU=SSL, O=Test, L=Test, C=DE" \
        -ext san=dns:$NODE_NAME.$DOMAIN,dns:localhost,ip:127.0.0.1,oid:1.2.3.4.5.5 
        
#oid:1.2.3.4.5.5 denote this a server node certificate for search guard

echo Generating certificate signing request for node $NODE_NAME

"$BIN_PATH" -certreq \
        -alias      $NODE_NAME \
        -keystore   output/$NODE_NAME-keystore.jks \
        -file       output/$NODE_NAME.csr \
        -keyalg     rsa \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$NODE_NAME.$DOMAIN, OU=SSL, O=Test, L=Test, C=DE" \
        -ext san=dns:$NODE_NAME.$DOMAIN,dns:localhost,ip:127.0.0.1,oid:1.2.3.4.5.5
        
#oid:1.2.3.4.5.5 denote this a server node certificate for search guard

echo Sign certificate request with CA
openssl ca \
    -in output/$NODE_NAME.csr \
    -notext \
    -out output/$NODE_NAME-signed.pem \
    -config etc/signing-ca.conf \
    -extensions v3_req \
    -batch \
	-passin pass:$CA_PASS \
	-extensions server_ext 

echo "Import back to keystore (including CA chain)"

cat output/ca/chain-ca.pem output/$NODE_NAME-signed.pem | "$BIN_PATH" \
    -importcert \
    -keystore output/$NODE_NAME-keystore.jks \
    -storepass $KS_PASS \
    -noprompt \
    -alias $NODE_NAME
    
"$BIN_PATH" -importkeystore -srckeystore output/$NODE_NAME-keystore.jks -srcstorepass $KS_PASS -srcstoretype JKS -deststoretype PKCS12 -deststorepass $KS_PASS -destkeystore output/$NODE_NAME-keystore.p12

openssl pkcs12 -in "output/$NODE_NAME-keystore.p12" -out "output/$NODE_NAME.key.pem" -nocerts -nodes -passin pass:$KS_PASS
openssl pkcs12 -in "output/$NODE_NAME-keystore.p12" -out "output/$NODE_NAME.crt.pem" -nokeys -passin pass:$KS_PASS

echo All done for $NODE_NAME
	
