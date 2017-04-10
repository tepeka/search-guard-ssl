FROM java:8

RUN \
  apt-get update && \
  apt-get install -y \
    git \
    openssl && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /data

RUN \
  git clone https://github.com/floragunncom/search-guard-ssl.git && \
  mkdir /tmp/output

WORKDIR /data/search-guard-ssl/example-pki-scripts

ENTRYPOINT sh -c './example.sh && cp * /tmp/output'
