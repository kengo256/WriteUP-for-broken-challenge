# 軽量なPythonイメージを使用
FROM python:3.9-slim

WORKDIR /app

# サーバーコードと、生成した攻撃ファイルをコピー
# ※ exploit.sxg と cert.cbor はローカルで生成してここに置く
COPY server.py .
COPY exploit.sxg .
COPY cert.cbor .

# サーバー起動
CMD ["python", "server.py"]