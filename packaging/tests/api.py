"""A stand-in for the GitHub API, for install.sh's test (#879).

The first path segment picks the answer, so one server covers every case:

  /ok/...      200 and the release lists below
  /nofit/...   200, but libc370 lists only 1.0.0, whose range excludes cc370
  /limit/...   403 with the rate-limit headers GitHub sends
  /e500/...    500
  /token/...   200 only with "Authorization: Bearer tok", else 401

Prints the port it listens on, then serves until killed.
"""
import http.server
import json
import sys
import time


def rels(*tags):
    return json.dumps([{"tag_name": "v" + t} for t in tags]).encode()


class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body=b"{}", hdrs=()):
        self.send_response(code)
        for k, v in hdrs:
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        mode, _, rest = self.path.lstrip("/").partition("/")
        if mode == "limit":
            reset = str(int(time.time()) + 600)
            return self.send(403, b'{"message":"API rate limit exceeded"}',
                             [("x-ratelimit-remaining", "0"),
                              ("x-ratelimit-reset", reset)])
        if mode == "e500":
            return self.send(500)
        if mode == "token" and self.headers.get("Authorization") != "Bearer tok":
            return self.send(401)
        if rest.startswith("repos/mvslovers/cc370/releases/latest"):
            return self.send(200, json.dumps({"tag_name": "v9.9.9"}).encode())
        if rest.startswith("repos/mvslovers/libc370/releases"):
            return self.send(200, rels("1.0.0") if mode == "nofit"
                             else rels("2.0.0", "1.0.0"))
        return self.send(404)


s = http.server.HTTPServer(("127.0.0.1", 0), H)
print(s.server_address[1], flush=True)
sys.stdout.close()
s.serve_forever()
