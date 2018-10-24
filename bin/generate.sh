#!/bin/bash
set -e

echo
echo Enter Root-CA Secrets
unset CA_PASS TS_PASS
read -p "- Root-CA Secret: " -s CA_PASS ; echo
read -p "- Truststore Secret: " -s TS_PASS ; echo

rm -rf output/*
./gen_root_ca.sh $CA_PASS $TS_PASS

echo
echo Enter Node and Client Certificate Fields
unset CRT_C CRT_O CRT_OU CRT_ST
read -p "- Country Name (C): " CRT_C 
read -p "- Organisation (O): " CRT_O 
read -p "- Organisational Unit (OU): " CRT_OU 
read -p "- State or Province Name  (ST): " CRT_ST 

./gen_node_cert.sh $CA_PASS $CRT_C $CRT_O $CRT_OU $CRT_ST
./gen_client_node_cert.sh $CA_PASS $CRT_C $CRT_O $CRT_OU $CRT_ST

rm -f ./*tmp*