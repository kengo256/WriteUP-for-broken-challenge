import os
from http.server import HTTPServer, SimpleHTTPRequestHandler

# Render.comは環境変数PORTでポートを指定してくるためそれを使う
PORT = int(os.environ.get("PORT", 10000))

class SXGHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # SXG配信に必須のヘッダー
        self.send_header("X-Content-Type-Options", "nosniff")
        # キャッシュ対策（任意ですが検証中はあったほうが良い）
        self.send_header("Cache-Control", "no-store")
        SimpleHTTPRequestHandler.end_headers(self)

    def guess_type(self, path):
        # 拡張子に応じて正しいContent-Typeを返す
        if path.endswith(".sxg"):
            return "application/signed-exchange;v=b3"
        if path.endswith(".cbor"):
            return "application/cert-chain+cbor"
        return SimpleHTTPRequestHandler.guess_type(self, path)

print(f"Starting server on port {PORT}...")
HTTPServer(("", PORT), SXGHandler).serve_forever()