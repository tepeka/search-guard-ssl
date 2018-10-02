#!/bin/bash
set -e

CA_PASS=$1
CRT_C=$2
CRT_O=$3
CRT_OU=$4 
CRT_ST=$5

echo
echo Enter Node-Keystore Secret
unset KS_PASS
read -p "- Keystore Secret: " -s KS_PASS ; echo

echo
echo "Enter Node-Certificate Name (CN will be Node-Name.Domain)"
unset CRT_NODE_NAME CRT_DOMAIN
read -p "- Node-Name (e.g. node-0): " CRT_NODE_NAME 
read -p "- Domain (e.g. example.com): " CRT_DOMAIN

rm -f output/$CRT_NODE_NAME-keystore.jks
rm -f output/$CRT_NODE_NAME.csr
rm -f output/$CRT_NODE_NAME-signed.pem

BIN_PATH="keytool"

if [ ! -z "$JAVA_HOME" ]; then
    BIN_PATH="$JAVA_HOME/bin/keytool"
fi

echo Generating keystore and certificate for node $CRT_NODE_NAME

"$BIN_PATH" -genkey \
        -alias     $CRT_NODE_NAME \
        -keystore  output/$CRT_NODE_NAME-keystore.jks \
        -keyalg    RSA \
        -keysize   2048 \
        -validity  712 \
        -sigalg SHA256withRSA \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$CRT_NODE_NAME.$CRT_DOMAIN, OU=$CRT_OU, O=$CRT_O, ST=$CRT_ST, C=$CRT_C" \
        -ext san=dns:$CRT_NODE_NAME.$CRT_DOMAIN,dns:localhost,dns:ip6-localhost,ip:127.0.0.1,ip:::1,oid:1.2.3.4.5.5 
        
#oid:1.2.3.4.5.5 denote this a server node certificate for search guard

echo Generating certificate signing request for node $CRT_NODE_NAME

"$BIN_PATH" -certreq \
        -alias      $CRT_NODE_NAME \
        -keystore   output/$CRT_NODE_NAME-keystore.jks \
        -file       output/$CRT_NODE_NAME.csr \
        -keyalg     rsa \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$CRT_NODE_NAME.$CRT_DOMAIN, OU=$CRT_OU, O=$CRT_O, ST=$CRT_ST, C=$CRT_C" \
        -ext san=dns:$CRT_NODE_NAME.$CRT_DOMAIN,dns:localhost,dns:ip6-localhost,ip:127.0.0.1,ip:::1,oid:1.2.3.4.5.5
        
#oid:1.2.3.4.5.5 denote this a server node certificate for search guard

echo Sign certificate request with CA
openssl ca \
    -in output/$CRT_NODE_NAME.csr \
    -notext \
    -out output/$CRT_NODE_NAME-signed.pem \
    -config etc/signing-ca.conf \
    -extensions v3_req \
    -batch \
	-passin pass:$CA_PASS \
	-extensions server_ext 

echo "Import back to keystore (including CA chain)"

cat output/ca/chain-ca.pem output/$CRT_NODE_NAME-signed.pem | "$BIN_PATH" \
    -importcert \
    -keystore output/$CRT_NODE_NAME-keystore.jks \
    -storepass $KS_PASS \
    -noprompt \
    -alias $CRT_NODE_NAME
    
"$BIN_PATH" -importkeystore -srckeystore output/$CRT_NODE_NAME-keystore.jks -srcstorepass $KS_PASS -srcstoretype JKS -deststoretype PKCS12 -deststorepass $KS_PASS -destkeystore output/$CRT_NODE_NAME-keystore.p12

openssl pkcs12 -in "output/$CRT_NODE_NAME-keystore.p12" -out "output/$CRT_NODE_NAME.key.pem" -nocerts -nodes -passin pass:$KS_PASS
openssl pkcs12 -in "output/$CRT_NODE_NAME-keystore.p12" -out "output/$CRT_NODE_NAME.crt.pem" -nokeys -passin pass:$KS_PASS

echo All done for $CRT_NODE_NAME
	
