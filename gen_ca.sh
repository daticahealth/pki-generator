#! /bin/bash -e

# Time in days
ROOT_CA_LIFESPAN=${1:-"7300"}

echo -e "Generating Root CA.\nIf this is production PKI, turn off WiFi and remove any other external connections to ensure your Root CA key is air-gapped."
read -n 1 -p "Ready to proceed? (y/n) " proceed
echo -e "\n"
if [ "$(echo ${proceed} | awk '{print tolower($0)}')" != "y" ]; then
  exit 0
fi

mkdir ${HOME}/ca
./config/root_openssl.sh > ${HOME}/ca/openssl.cnf
cd ${HOME}/ca
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

openssl genrsa -out private/ca-key.pem 4096
chmod 400 private/ca-key.pem

openssl req -config openssl.cnf \
  -key private/ca-key.pem \
  -new -x509 -days ${ROOT_CA_LIFESPAN} -sha256 -extensions v3_ca \
  -out certs/ca.pem
chmod 444 certs/ca.pem

echo -e "
Key: ${HOME}/ca/private/ca-key.pem
Cert: ${HOME}/ca/certs/ca.pem

--------------IMPORTANT--------------
Store the Root CA cert and key on a flash drive. This should be kept in a secure location, like a bank vault.
If you are NOT generating an intermediate CA, delete the Root CA key from your computer before restoring internet access (for production PKI).
------------------------------------\n"
