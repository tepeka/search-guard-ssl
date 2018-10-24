#!/bin/bash
set -e

CA_PASS=$1
CRT_C=$2
CRT_O=$3
CRT_OU=$4 
CRT_ST=$5

echo
echo Enter Client-Keystore Secret
unset KS_PASS
read -p "- Keystore Secret: " -s KS_PASS ; echo

echo
echo Enter Client-Certificate Name
unset CRT_CN
read -p "- Common Name (CN): " CRT_CN

BIN_PATH="keytool"

if [ ! -z "$JAVA_HOME" ]; then
    BIN_PATH="$JAVA_HOME/bin/keytool"
fi

rm -f output/$CRT_CN-keystore.jks
rm -f output/$CRT_CN.csr
rm -f output/$CRT_CN-signed.pem

echo Generating keystore and certificate for node $CRT_CN

"$BIN_PATH" -genkey \
        -alias     $CRT_CN \
        -keystore  output/$CRT_CN-keystore.jks \
        -keyalg    RSA \
        -keysize   2048 \
        -sigalg SHA256withRSA \
        -validity  712 \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$CRT_CN, OU=$CRT_OU, O=$CRT_O, ST=$CRT_ST, C=$CRT_C"

echo Generating certificate signing request for node $CRT_CN

"$BIN_PATH" -certreq \
        -alias      $CRT_CN \
        -keystore   output/$CRT_CN-keystore.jks \
        -file       output/$CRT_CN.csr \
        -keyalg     rsa \
        -keypass $KS_PASS \
        -storepass $KS_PASS \
        -dname "CN=$CRT_CN, OU=$CRT_OU, O=$CRT_O, ST=$CRT_ST, C=$CRT_C"

echo Sign certificate request with CA
openssl ca \
    -in output/$CRT_CN.csr \
    -notext \
    -out output/$CRT_CN-signed.pem \
    -config etc/signing-ca.conf \
    -extensions v3_req \
    -batch \
	-passin pass:$CA_PASS \
	-extensions server_ext 

echo "Import back to keystore (including CA chain)"

cat output/ca/chain-ca.pem output/$CRT_CN-signed.pem | "$BIN_PATH" \
    -importcert \
    -keystore output/$CRT_CN-keystore.jks \
    -storepass $KS_PASS \
    -noprompt \
    -alias $CRT_CN

"$BIN_PATH" -importkeystore -srckeystore output/$CRT_CN-keystore.jks -srcstorepass $KS_PASS -srcstoretype JKS -deststoretype PKCS12 -deststorepass $KS_PASS -destkeystore output/$CRT_CN-keystore.p12

openssl pkcs12 -in "output/$CRT_CN-keystore.p12" -out "output/$CRT_CN.all.pem" -nodes -passin "pass:$KS_PASS"
openssl pkcs12 -in "output/$CRT_CN-keystore.p12" -out "output/$CRT_CN.key.pem" -nocerts -nodes -passin pass:$KS_PASS
openssl pkcs12 -in "output/$CRT_CN-keystore.p12" -out "output/$CRT_CN.crt.pem" -clcerts -nokeys -passin pass:$KS_PASS
cat "output/$CRT_CN.crt.pem" output/ca/chain-ca.pem  > "output/$CRT_CN.crtfull.pem"

echo All done for $CRT_CN
	
