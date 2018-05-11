#! /bin/bash -e

LEAF_CERT_NAME=${1:-"leaf"}
# Time in days
LEAF_CERT_LIFESPAN=${2:-"90"}

echo "Note: This script is only for generating simple certs. Does not support Subject Alternative Names."

cd ${HOME}/ca
openssl genrsa -out intermediate/private/${LEAF_CERT_NAME}-key.pem 2048
chmod 400 intermediate/private/${LEAF_CERT_NAME}-key.pem

openssl req -config intermediate/openssl.cnf \
  -key intermediate/private/${LEAF_CERT_NAME}-key.pem \
  -new -sha256 -out intermediate/csr/${LEAF_CERT_NAME}-csr.pem

openssl ca -config intermediate/openssl.cnf \
  -extensions server_cert -days ${LEAF_CERT_LIFESPAN} -notext -md sha256 \
  -in intermediate/csr/${LEAF_CERT_NAME}-csr.pem \
  -out intermediate/certs/${LEAF_CERT_NAME}.pem
chmod 444 intermediate/certs/${LEAF_CERT_NAME}.pem

openssl verify -CAfile intermediate/certs/ca-chain.pem \
  intermediate/certs/${LEAF_CERT_NAME}.pem
