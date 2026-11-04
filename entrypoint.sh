#!/bin/sh
set -e

DATA_DIR=/var/lib/pg-node
CERT_DIR="$DATA_DIR/certs"
CERT="$CERT_DIR/ssl_cert.pem"
KEY="$CERT_DIR/ssl_key.pem"
CERT_HOST_FILE="$CERT_DIR/cert_hostname.txt"
KEY_FILE="$DATA_DIR/api_key.txt"

mkdir -p "$CERT_DIR"

# دامنه عمومی Railway؛ باید در Settings > Networking ساخته شده باشد.
HOSTNAME_FOR_CERT="${RAILWAY_PUBLIC_DOMAIN:-}"

if [ -z "$HOSTNAME_FOR_CERT" ]; then
  echo "خطا: RAILWAY_PUBLIC_DOMAIN خالی است. برای سرویس در Railway یک Public Domain بساز."
  exit 1
fi

SAVED_CERT_HOST=""
if [ -f "$CERT_HOST_FILE" ]; then
  SAVED_CERT_HOST=$(cat "$CERT_HOST_FILE")
fi

if [ ! -s "$CERT" ]  [ ! -s "$KEY" ]  [ "$SAVED_CERT_HOST" != "$HOSTNAME_FOR_CERT" ]; then
  echo ">> در حال ساخت گواهی SSL برای دامنه عمومی $HOSTNAME_FOR_CERT..."

  cat > /tmp/node_ext.cnf << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = ${HOSTNAME_FOR_CERT}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOSTNAME_FOR_CERT}
EOF

  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$KEY" -out "$CERT" \
    -config /tmp/node_ext.cnf -extensions v3_req 2>/dev/null

  rm -f /tmp/node_ext.cnf
  printf '%s\n' "$HOSTNAME_FOR_CERT" > "$CERT_HOST_FILE"
fi

# اگر API_KEY از Variables تنظیم نشده باشد، از مقدار ذخیره‌شده یا مقدار جدید استفاده می‌شود.
if [ -z "${API_KEY:-}" ]; then
  if [ -f "$KEY_FILE" ]; then
    API_KEY=$(cat "$KEY_FILE")
  else
    API_KEY=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || openssl rand -hex 16)
    echo "$API_KEY" > "$KEY_FILE"
  fi
  export API_KEY
fi

echo "================================================================"
echo "این اطلاعات را برای اضافه‌کردن نود در پنل لازم داری:"
echo "  Address : $HOSTNAME_FOR_CERT"
echo "  Port    : ${SERVICE_PORT:-${PORT:-}}"
echo "  API Key : $API_KEY"
echo ""
echo "این متن را در فیلد Certificate پنل وارد کن:"
cat "$CERT"
echo "================================================================"

exec ./main
