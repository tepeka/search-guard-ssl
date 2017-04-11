#!/bin/bash
set -e
rm -rf output/ca output/certs* output/crl output/*.jks

if [ -z "$2" ] ; then
  unset CA_PASS TS_PASS
  echo enter root CA secrets
  read -p "1) CA pass: " -s CA_PASS ; echo
  read -p "2) Truststore pass: " -s TS_PASS ; echo
 else
  CA_PASS=$1
  TS_PASS=$2
fi

mkdir -p output/ca/root-ca/private output/ca/root-ca/db output/crl output/certs
chmod 700 output/ca/root-ca/private

cp /dev/null output/ca/root-ca/db/root-ca.db
cp /dev/null output/ca/root-ca/db/root-ca.db.attr
echo 01 > output/ca/root-ca/db/root-ca.crt.srl
echo 01 > output/ca/root-ca/db/root-ca.crl.srl

openssl req -new \
    -config etc/root-ca.conf \
    -out output/ca/root-ca.csr \
    -keyout output/ca/root-ca/private/root-ca.key \
	-batch \
	-passout pass:$CA_PASS
	

openssl ca -selfsign \
    -config etc/root-ca.conf \
    -in output/ca/root-ca.csr \
    -out output/ca/root-ca.crt \
    -extensions root_ca_ext \
	-batch \
	-passin pass:$CA_PASS
	
echo Root CA generated
	
mkdir -p output/ca/signing-ca/private output/ca/signing-ca/db output/crl output/certs
chmod 700 output/ca/signing-ca/private

cp /dev/null output/ca/signing-ca/db/signing-ca.db
cp /dev/null output/ca/signing-ca/db/signing-ca.db.attr
echo 01 > output/ca/signing-ca/db/signing-ca.crt.srl
echo 01 > output/ca/signing-ca/db/signing-ca.crl.srl

openssl req -new \
    -config etc/signing-ca.conf \
    -out output/ca/signing-ca.csr \
    -keyout output/ca/signing-ca/private/signing-ca.key \
	-batch \
	-passout pass:$CA_PASS
	
openssl ca \
    -config etc/root-ca.conf \
    -in output/ca/signing-ca.csr \
    -out output/ca/signing-ca.crt \
    -extensions signing_ca_ext \
	-batch \
	-passin pass:$CA_PASS
	
echo Signing CA generated

openssl x509 -in output/ca/root-ca.crt -out output/ca/root-ca.pem -outform PEM
openssl x509 -in output/ca/signing-ca.crt -out output/ca/signing-ca.pem -outform PEM
cat output/ca/signing-ca.pem output/ca/root-ca.pem > output/ca/chain-ca.pem

#http://stackoverflow.com/questions/652916/converting-a-java-keystore-into-pem-format

BIN_PATH="keytool"

if [ ! -z "$JAVA_HOME" ]; then
    BIN_PATH="$JAVA_HOME/bin/keytool"
fi

cat output/ca/root-ca.pem | "$BIN_PATH" \
    -import \
    -v \
    -keystore output/truststore.jks   \
    -storepass $TS_PASS  \
    -noprompt -alias root-ca-chain
