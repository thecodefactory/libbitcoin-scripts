#!/bin/bash
set -e

# libbitcoin-server TLS certs.
# wolfSSL is built with NO_RSA, so all keys must be EC (P-256) or Ed25519.
#
# the supported set is exactly: ECDSA or Ed25519, in — RSA, DSA, Ed448 and the PQC types out.

mkdir -p pki && cd pki

CN=${1:-$(hostname)}

# 1) Root CA.
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out libbitcoin-root-ca.key.pem

openssl req -x509 -new -nodes \
  -key libbitcoin-root-ca.key.pem \
  -sha256 -days 3650 \
  -subj "/C=LB/ST=LBTC/L=LBTC/O=Libbitcoin/OU=RootCA/CN=$(hostname)" \
  -out libbitcoin-root-ca.pem

# 2) Intermediate CA.
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out libbitcoin-intermediate-ca.key.pem

openssl req -new -key libbitcoin-intermediate-ca.key.pem -sha256 \
  -subj "/C=LB/ST=LBTC/L=LBTC/O=Libbitcoin/OU=IntermediateCA/CN=example-intermediate" \
  -out libbitcoin-intermediate-ca.csr.pem

cat > libbitcoin-intermediate-ca.ext <<'EOF'
basicConstraints=critical,CA:true,pathlen:0
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
EOF

openssl x509 -req -in libbitcoin-intermediate-ca.csr.pem \
  -CA libbitcoin-root-ca.pem -CAkey libbitcoin-root-ca.key.pem -CAcreateserial \
  -out libbitcoin-intermediate-ca.pem \
  -days 1825 -sha256 \
  -extfile libbitcoin-intermediate-ca.ext

# 3) Server leaf.
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out libbitcoin-server-key.pem

openssl req -new -key libbitcoin-server-key.pem -sha256 \
  -subj "/C=LB/ST=LBTC/L=LBTC/O=Libbitcoin/OU=ServerCertificate/CN=$CN" \
  -out libbitcoin-server.csr.pem

# keyEncipherment omitted: not applicable to EC keys or TLS 1.3.
cat > libbitcoin-server.ext <<EOF
basicConstraints=critical,CA:false
keyUsage=critical,digitalSignature
extendedKeyUsage=serverAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
subjectAltName=DNS:$CN
EOF

openssl x509 -req -in libbitcoin-server.csr.pem \
  -CA libbitcoin-intermediate-ca.pem -CAkey libbitcoin-intermediate-ca.key.pem -CAcreateserial \
  -out libbitcoin-server.pem \
  -days 825 -sha256 \
  -extfile libbitcoin-server.ext

# 4) Chain: leaf first, then intermediate(s). Root optional.
cat libbitcoin-server.pem libbitcoin-intermediate-ca.pem > libbitcoin-server-cert.pem

rm -f libbitcoin-intermediate-ca.ext libbitcoin-server.ext libbitcoin-intermediate-ca.csr.pem libbitcoin-server.csr.pem

# Verify: both algorithms must read EC, none may read RSA.
openssl crl2pkcs7 -nocrl -certfile libbitcoin-server-cert.pem \
  | openssl pkcs7 -print_certs -noout -text \
  | grep -E "Subject:|Signature Algorithm:|Public Key Algorithm:"

openssl verify -CAfile libbitcoin-root-ca.pem -untrusted libbitcoin-intermediate-ca.pem libbitcoin-server.pem

exit 0
