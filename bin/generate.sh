#!/bin/bash
set -e

# domain env var
domain="example.com"
if [ ! -z "$TEPEKA_DOMAIN" ]; then
  domain=$TEPEKA_DOMAIN
fi  

# node env var
node=0
if [ ! -z "$TEPEKA_NODE" ]; then
  node=$TEPEKA_NODE
fi  

# user env var
user="admin"
if [ ! -z "$TEPEKA_USER" ]; then
  user=$TEPEKA_USER
fi  

# execute scripts
rm -rf output/*
./gen_root_ca.sh
./gen_node_cert.sh $node $domain
./gen_client_node_cert.sh $user
rm -f ./*tmp*