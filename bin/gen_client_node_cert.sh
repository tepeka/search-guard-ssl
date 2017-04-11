#!/bin/bash
set -e
CLIENT_NAME=$1

if [ -z "$3" ] ; then
  unset CA_PASS KS_PASS
  echo enter client node cert secrets
  read -p "1) CA pass: " -s CA_PASS ; echo
  read -p "2) Keystore pass: " -s KS_PASS ; echo
 else
  KS_PASS=$2
  CA_PASS=$3
fi

BIN_PATH="keytool"

if [ ! -z "$JAVA_HOME" ]; then
    BIN_PATH="$JAVA_HOME/bin/keytool"
fi

rm -f output/$CLIENT_NAME-keystore.jks
rm -f output/$CLIENT_NAME.csr
rm -f output/$CLIENT_NAME-signed.pem

echo Generating keystore and certificate for node $CLIENT_NAME

"$BIN_PATH" -genkey \
        -alias     $CLIENT_NAME \
        -keystore  output/$CLIENT_NAME-keystore.jks \
        -keyalg    RSA \
        -keysize   2048 \
        -sigalg SHA256withRSA \
        -validity  712 \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$CLIENT_NAME, OU=client, O=client, L=Test, C=DE"

echo Generating certificate signing request for node $CLIENT_NAME

"$BIN_PATH" -certreq \
        -alias      $CLIENT_NAME \
        -keystore   output/$CLIENT_NAME-keystore.jks \
        -file       output/$CLIENT_NAME.csr \
        -keyalg     rsa \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$CLIENT_NAME, OU=client, O=client, L=Test, C=DE"

echo Sign certificate request with CA
openssl ca \
    -in output/$CLIENT_NAME.csr \
    -notext \
    -out output/$CLIENT_NAME-signed.pem \
    -config etc/signing-ca.conf \
    -extensions v3_req \
    -batch \
	-passin pass:$CA_PASS \
	-extensions server_ext 

echo "Import back to keystore (including CA chain)"

cat output/ca/chain-ca.pem output/$CLIENT_NAME-signed.pem | "$BIN_PATH" \
    -importcert \
    -keystore output/$CLIENT_NAME-keystore.jks \
    -storepass $KS_PASS \
    -noprompt \
    -alias $CLIENT_NAME

"$BIN_PATH" -importkeystore -srckeystore output/$CLIENT_NAME-keystore.jks -srcstorepass $KS_PASS -srcstoretype JKS -deststoretype PKCS12 -deststorepass $KS_PASS -destkeystore output/$CLIENT_NAME-keystore.p12

openssl pkcs12 -in "output/$CLIENT_NAME-keystore.p12" -out "output/$CLIENT_NAME.all.pem" -nodes -passin "pass:$KS_PASS"
openssl pkcs12 -in "output/$CLIENT_NAME-keystore.p12" -out "output/$CLIENT_NAME.key.pem" -nocerts -nodes -passin pass:$KS_PASS
openssl pkcs12 -in "output/$CLIENT_NAME-keystore.p12" -out "output/$CLIENT_NAME.crt.pem" -clcerts -nokeys -passin pass:$KS_PASS
cat "output/$CLIENT_NAME.crt.pem" output/ca/chain-ca.pem  > "output/$CLIENT_NAME.crtfull.pem"

echo All done for $CLIENT_NAME
	
