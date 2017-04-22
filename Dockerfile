FROM java:8

RUN \
  apt-get update && \
  apt-get install -y openssl && \
  rm -rf /var/lib/apt/lists/*

ENV wd /workdir
ENV output ${wd}/output

WORKDIR ${wd}
RUN mkdir ${output}

COPY bin ${wd}
COPY etc ${wd}/etc

CMD ["./generate.sh"]
