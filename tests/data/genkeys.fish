openssl req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes -keyout client-rsa.key -out client-rsa.cert -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=tests.nats.zig"
openssl req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes -keyout server-rsa.key -out server-rsa.cert -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=tests.nats.zig"
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days 36500 -nodes -keyout client-ecc.key -out client-ecc.cert -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=tests.nats.zig"
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:secp384r1 -days 36500 -nodes -keyout server-ecc.key -out server-ecc.cert -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=tests.nats.zig"
