# Create private key and self-signed root CA
openssl ecparam -name prime256v1 -genkey -out root.key
openssl req -new -key root.key -x509 -sha256 -days 365 -out root.crt

# Create private key, signing request for intermediary CA, and sign with root CA
# the Basic Constraints specified in the inermediary_cert.extensions file are
# necessary in order for clients to successfully validate certificate chains containing the
# intermediary certificate
openssl ecparam -name prime256v1 -genkey -out inter.key
openssl req -new -key inter.key -sha256 -out inter.csr
openssl x509 -sha256 -req -in inter.csr -CA root.crt -CAkey root.key -out inter.crt -days 365 -CAcreateserial -extfile intermediary_cert.extensions

# Import root CA into Java's trusted CAs
# This step is REQUIRED in order for the import of the client and server
# certificates created in the next steps to successfully establish the
# certificate chain (via the intermediary to the root CA) in the keystore 
keytool -importcert -alias californium -file root.crt -keystore "$JAVA_HOME/jre/lib/security/cacerts"

# Import root CA into portable trust store
keytool -importcert -alias root -file root.crt -keystore trustStore.jks

# Create client CA and import certificate chain into key store
keytool -genkeypair -alias client -keyalg EC -keystore keyStore.jks -sigalg SHA256withECDSA -validity 365
keytool -certreq -alias client -keystore keyStore.jks -file client.csr
openssl x509 -req -in client.csr -CA inter.crt -CAkey inter.key -out client.crt -sha256 -days 365 -CAcreateserial
keytool -importcert -alias inter -file inter.crt -keystore keyStore.jks -trustcacerts
keytool -importcert -alias client -file client.crt -keystore keyStore.jks -trustcacerts

# Create server CA and import certificate chain into key store
keytool -genkeypair -alias server -keyalg EC -keystore keyStore.jks -sigalg SHA256withECDSA -validity 365
keytool -certreq -alias server -keystore keyStore.jks -file server.csr
openssl x509 -req -in server.csr -CA inter.crt -CAkey inter.key -out server.crt -sha256 -days 365 -CAcreateserial
keytool -importcert -alias server -file server.crt -keystore keyStore.jks -trustcacerts

# List certificate chain in key store
keytool -list -v -keystore keyStore.jks