#!/bin/bash 

COUNTRY="ES"
STATE="Barcelona"
LOCATION="Sabadell"
ORG="Universitat Autonoma de Barcelona"
OU="Campus de Sabadell"
HOSTNAME="hostname.domain.tld"
ALT_HOSTNAMES="hostname2.domain.tld hostname3.domain.tld"

SSL_KEY_BITS="4096"

CFG_FILENAME="./req.conf"
CSR_FILENAME="${HOSTNAME//./_}.csr"
KEY_FILENAME="${HOSTNAME//./_}.key"
VRF_FILENAME="${HOSTNAME//./_}_verify.sh"
LOCAL_SERVER_FILENAME="${HOSTNAME//./_}_server.sh"

# 
echo "Generate CSR KEY and util's for the next domains:"
for i in ${HOSTNAME} ${ALT_HOSTNAMES}
do
	echo "	- ${i}"
done
read -t 30 -p "Press <enter> to continue or wait 30 seconds"
# Generate config for the new CSR and KEY
cat <<EOF >${CFG_FILENAME}
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = ${COUNTRY}
ST = ${STATE}
L = ${LOCATION}
O = ${ORG}
OU = ${OU}
CN = ${HOSTNAME}
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
EOF

i=0
for name in ${ALT_HOSTNAMES}
do
	i=$( expr $i + 1 )
	echo "DNS.${i} = ${name}" >> ${CFG_FILENAME}
done

# Generate CSR & KEY
if [ -f ${KEY_FILENAME} ] || [ -f ${CSR_FILENAME} ]
then
	echo "ERROR: KEY or CSR Exists!!!"
	read -t 30 -p "Press <enter> to continue or wait 30 seconds"
else
	openssl req -new -out ${CSR_FILENAME} -newkey rsa:${SSL_KEY_BITS} \
		-nodes -sha256 -keyout ${KEY_FILENAME} -config ${CFG_FILENAME}
fi

# check CSR
openssl req -in ${CSR_FILENAME} -text | less

# check la key
openssl rsa -in ${KEY_FILENAME} -check

# Script to launch local server
cat <<EOF > ${LOCAL_SERVER_FILENAME}
if [ ! -Z $1 ]
then
	PORT=\$1
else
	PORT=3000
fi
openssl s_server -accept \${PORT} -key ${KEY_FILENAME} -cert ${CERT_FILENAME}
EOF
chmod a+x ${LOCAL_SERVER_FILENAME}

# Script to verify the install
cat <<EOF > ${VRF_FILENAME}
SERVER=""
if [ ! -Z $1 ]
then
	SERVER=\$1
else
	SERVER=${HOSTNAME}:443
fi

openssl s_client -connect \${SERVER} | openssl x509 -noout -dates
EOF
chmod a+x ${VRF_FILENAME}

