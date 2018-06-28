#! /bin/bash -e

usage() {
  echo -e '\nUsage: ./gen_leaf.sh [options]
    Options:
      -n, --name: Name of the cert file (default: "leaf")
      -d, --days: Lifespan of the cert in days (default: 90)
      -b, --bits: Bit strength to use for generating the leaf cert (Default: 2048)
      --ca-cert: Path to the ca cert to use (if dir structure from gen_ca.sh or gen_intermediate.sh does not exist)
      --ca-key: Path to the key associated with the cert in --ca-cert
      --dns: DNS subject alternative name(s) for the cert. Can be a space delimited list (in quotes) or single values
      --ip: IP subject alternative name(s) for the cert. Can be a space delimited list (in quotes) or single values
      -h, --help: This ;P

    Ex:
      ./gen_leaf.sh -n mycert -d 180 --dns "my.dns.com other.dns.com" --ip 127.0.0.1
  '
}

LEAF_CERT_NAME="leaf"
LEAF_CERT_LIFESPAN="90"
BIT_STRENGTH=2048
CA_CERT=""
CA_KEY=""
DNS_SANS=""
IP_SANS=""

while [ "$1" != "" ]; do
  case $1 in
    -n | --name )       
                  shift
                  LEAF_CERT_NAME=$1
                  ;;
    -d | --days )       
                  shift
                  LEAF_CERT_LIFESPAN=$1
                  ;;
    -b | --bits )
                  shift
                  BIT_STRENGTH=$1
                  ;;
    --ca-cert )
                  shift
                  CA_CERT=$1
                  ;;
    --ca-key )
                  shift
                  CA_KEY=$1
                  ;;
    --dns )             
                  shift
                  DNS_SANS="$DNS_SANS $1"
                  ;;
    --ip )              
                  shift
                  IP_SANS="$IP_SANS $1"
                  ;;
    -h | --help )       
                  usage
                  exit 0
                  ;;
    * )                 
                  echo "Error: Unkown option \"$1\""
                  usage
                  exit 1
                  ;;
  esac
  shift
done

if [ "$CA_CERT" ]; then
  if [ "$CA_KEY" == "" ]; then
    echo "Error: Must provide the key associated with the CA certificate"
    usage
    exit 1
  fi
  mv ${HOME}/ca ${HOME}/ca_prev || echo "No previous cert dir found"

  CA_PATH=${HOME}/ca
  INT_PATH=${CA_PATH}/intermediate

  # Root dir struct
  mkdir ${CA_PATH}
  ./config/root_openssl.sh > ${CA_PATH}/openssl.cnf
  mkdir ${CA_PATH}/certs ${CA_PATH}/crl ${CA_PATH}/newcerts ${CA_PATH}/private
  chmod 700 ${CA_PATH}/private
  touch ${CA_PATH}/index.txt
  echo 1000 > ${CA_PATH}/serial

  # Intermediate dir struct
  mkdir ${INT_PATH}
  mkdir ${INT_PATH}/certs ${INT_PATH}/crl ${INT_PATH}/csr ${INT_PATH}/newcerts ${INT_PATH}/private
  chmod 700 ${INT_PATH}/private
  touch ${INT_PATH}/index.txt
  echo "unique_subject = yes" > ${INT_PATH}/index.txt.attr
  echo 1000 > ${INT_PATH}/serial
  echo 1000 > ${INT_PATH}/crlnumber

  cp $CA_CERT $INT_PATH/certs/
  cp $CA_KEY $INT_PATH/private/
fi

./config/intermediate_openssl.sh "$DNS_SANS" "$IP_SANS" > ${HOME}/ca/intermediate/openssl.cnf
cd ${HOME}/ca

openssl genrsa -out intermediate/private/${LEAF_CERT_NAME}-key.pem ${BIT_STRENGTH}
chmod 400 intermediate/private/${LEAF_CERT_NAME}-key.pem

openssl req -config intermediate/openssl.cnf \
  -key intermediate/private/${LEAF_CERT_NAME}-key.pem \
  -new -sha256 -out intermediate/csr/${LEAF_CERT_NAME}-csr.pem

openssl ca -config intermediate/openssl.cnf \
  -extensions server_cert -days ${LEAF_CERT_LIFESPAN} -notext -md sha512 \
  -in intermediate/csr/${LEAF_CERT_NAME}-csr.pem \
  -out intermediate/certs/${LEAF_CERT_NAME}.pem
chmod 444 intermediate/certs/${LEAF_CERT_NAME}.pem

if [ -f "intermediate/certs/ca-chain.pem" ]; then
  openssl verify -CAfile intermediate/certs/ca-chain.pem intermediate/certs/${LEAF_CERT_NAME}.pem
else
  echo "No ca-chain.pem found, unable to run openssl verify on the new cert"
fi

echo -e "\n====================NEW CERTS====================
Key: ${HOME}/ca/intermediate/private/${LEAF_CERT_NAME}.pem
Cert: ${HOME}/ca/intermediate/certs/${LEAF_CERT_NAME}-key.pem"
