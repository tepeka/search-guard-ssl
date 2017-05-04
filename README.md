# About

The intened use of this repository is to create Java Keystore and Truststore necessary for the elastic search-guard plugin as easily as possible. It is based on the PKI scripts of <https://github.com/floragunncom/search-guard-ssl>. Its content is for experimental purpose only.

# How To

## Generate Basic Certificate Set
The default container command creates a root certificate authority with an intermediate singing CA, a certificate for a given node, and a certificate for a given client node user. The secrets and client certificate fields will be asked during runtime.

`docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl`

The directory `/etc` contains the default root and signing certificate configuration which is also part of the docker image. You can adapt the configuration and overlay the directory at runtime with `-v <path-to-etc-dir>:/workdir/etc`:

`docker run --rm -it -v <path-to-output-dir>:/workdir/output -v <path-to-etc-dir>:/workdir/etc tepeka/search-guard-ssl`

You can use the [KeyStore Explorer](http://keystore-explorer.org) to analyze the generated Keystore and Truststore.

## Generate Single Certificates
It is also possible to execute the single scripts individually.

### Generate Root CA and Signing CA
Use this command to create a root certificate with an intermediate signing certificate. You have to provide two parameters:
- `$CA_PASS`: Secret of the root certificate and the signing certificate.
- `$TS_PASS`: Secret of the Java Truststore where the generated certificates are stored.

`docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl ./gen_root_ca.sh $CA_PASS $TS_PASS`

### Generate Node Certificate / Client Node Certificate
Use these two commands to create a node certificate or a client node certificate with a given signing CA. You have to provide the following parameters:
- `$CA_PASS`: Secret of the provided signing certificate.
- `$CRT_C`: X.509 certificate field for the country.
- `$CRT_O`: X.509 certificate field for the organisation.
- `$CRT_OU`: X.509 certificate field for the organisational unit.
- `$CRT_ST`: X.509 certificate field for the state or province name.

The used signing CA configuration and its files have to be provided in the output directory.

- Create node certificate:

  `docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl ./gen_node_cert.sh $CA_PASS $CRT_C $CRT_O $CRT_OU $CRT_ST `

- Create client node certificate:

  `docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl ./gen_client_node_cert.sh $CA_PASS $CRT_C $CRT_O $CRT_OU $CRT_ST`

