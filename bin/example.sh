#!/bin/bash
set -e
rm -rf output/*
./gen_root_ca.sh
./gen_node_cert.sh 0 example.com
./gen_client_node_cert.sh admin
rm -f ./*tmp*