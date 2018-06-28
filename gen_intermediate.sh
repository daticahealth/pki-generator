#! /bin/bash -e

# Time in days
INTERMEDIATE_CA_LIFESPAN=${1:-"5475"}

echo -e "Generating Intermediate CA. Must have a Root CA key at '${HOME}/ca/private/ca-key.pem' and cert at '${HOME}/ca/certs/ca.pem'.\nIf this is production PKI, turn off WiFi and remove any other external connections to ensure your Root CA key is air-gapped."
read -n 1 -p "Ready to proceed? (y/n) " proceed
echo -e "\n"
if [ "$(echo ${proceed} | awk '{print tolower($0)}')" != "y" ]; then
  exit 0
fi

mkdir ${HOME}/ca/intermediate
./config/intermediate_openssl.sh > ${HOME}/ca/intermediate/openssl.cnf
cd ${HOME}/ca/intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

# ./dir_structure -i
# cd ca/intermediate

openssl genrsa -out private/intermediate-key.pem 4096
chmod 400 private/intermediate-key.pem

openssl req -config openssl.cnf -new -sha256 \
  -key private/intermediate-key.pem \
  -out csr/intermediate-csr.pem

cd ../
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
  -days ${INTERMEDIATE_CA_LIFESPAN} -notext -md sha256 \
  -in intermediate/csr/intermediate-csr.pem \
  -out intermediate/certs/intermediate.pem
chmod 444 intermediate/certs/intermediate.pem

openssl verify -CAfile certs/ca.pem intermediate/certs/intermediate.pem

cat intermediate/certs/intermediate.pem \
  certs/ca.pem > intermediate/certs/ca-chain.pem
chmod 444 intermediate/certs/ca-chain.pem

echo -e "
Key: ${HOME}/ca/intermediate/private/intermediate-key.pem
Cert: ${HOME}/ca/intermediate/certs/intermediate.pem

--------------IMPORTANT--------------
Delete the Root CA key from your computer before restoring internet access (for production PKI)
------------------------------------\n"
