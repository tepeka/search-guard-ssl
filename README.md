# About

The intened use of this repository is to create Java Keystore and Truststore necessary for the elastic search-guard plugin as easily as possible. It is based on the PKI scripts of <https://github.com/floragunncom/search-guard-ssl>. Its content is for experimental purpose only.

# How To

## Execute Basic Certificate Set
The default container command creates a root certificate authority, a certificate for node 0, and a certificate for the client node user `admin`. The secrets and client certificate fields will be asked during runtime.

`docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl`

The directory `/etc` contains the default root and signing certificate configuration which is also part of the docker image. You can adapt the configuration and overlay the directory at runtime with `-v <path-to-etc-dir>:/workdir/etc`:

`docker run --rm -it -v <path-to-output-dir>:/workdir/output -v <path-to-etc-dir>:/workdir/etc tepeka/search-guard-ssl`



## Execute Single Certificates
It is also possible to execute the single scripts individually.

### Generate Root CA
Use this command to create a root certificate authority.

`docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl ./gen_root_ca.sh`

### Generate Node Certificate
Use this command to create a node certificate for node `3` and domain `example.com`.

`docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl ./gen_node_cert.sh 3 example.com`

### Generate Client Node Certificate
Use this command to create a client node certificate for user `klaus`.

`docker run --rm -it -v <path-to-output-dir>:/workdir/output tepeka/search-guard-ssl ./gen_client_node_cert.sh klaus`


