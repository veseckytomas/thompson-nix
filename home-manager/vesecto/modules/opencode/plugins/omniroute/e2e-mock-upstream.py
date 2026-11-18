#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
#
# OpenAI-compatible stand-in for e-infra / the next chain member, steered over /__ctl by omniroute-e2e.
import json
import sys
import threading
import time
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

port, name, models = int(sys.argv[1]), sys.argv[2], sys.argv[3].split(",")
lock = threading.Lock()
stats = {
    "inflight": 0,
    "max_inflight": 0,
    "served": 0,
    "rejected429": 0,
    "by_model": {},
}
ctl = {"hold": False, "fail429": 0}
release = threading.Event()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *args):
        pass

    def reply(self, code, obj, headers=None):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/__stats":
            with lock:
                return self.reply(200, dict(stats, **ctl))
        if self.path.endswith("/models"):
            return self.reply(
                200,
                {
                    "object": "list",
                    "data": [
                        {"id": m, "object": "model", "owned_by": name} for m in models
                    ],
                },
            )
        self.reply(404, {"error": "not found"})

    def do_POST(self):
        global release
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}"
        body = json.loads(raw)
        if self.path == "/__ctl":
            with lock:
                if body.get("reset"):
                    stats.update(
                        max_inflight=stats["inflight"],
                        served=0,
                        rejected429=0,
                        by_model={},
                    )
                ctl["fail429"] = int(body.get("fail429", ctl["fail429"]))
                if "hold" in body:
                    ctl["hold"] = bool(body["hold"])
                    if not ctl["hold"]:
                        release.set()
                        release = threading.Event()
            return self.reply(200, ctl)
        if not self.path.endswith("/chat/completions"):
            return self.reply(404, {"error": "not found"})
        model = body.get("model", "?")
        with lock:
            if ctl["fail429"] > 0:
                ctl["fail429"] -= 1
                stats["rejected429"] += 1
                resets = (datetime.now(timezone.utc) + timedelta(hours=5)).strftime(
                    "%Y-%m-%d %H:%M:%S"
                )
                message = (
                    "Rate limit exceeded for api_key: sk-e2e. Limit type: max_parallel_requests. "
                    f"Current limit: 4, Remaining: 0. Limit resets at: {resets} UTC"
                )
                return self.reply(
                    429,
                    {
                        "error": {
                            "message": message,
                            "type": "None",
                            "param": "None",
                            "code": "429",
                        }
                    },
                    {"retry-after": "18000"},
                )
            stats["inflight"] += 1
            stats["served"] += 1
            stats["by_model"][model] = stats["by_model"].get(model, 0) + 1
            stats["max_inflight"] = max(stats["max_inflight"], stats["inflight"])
            hold, gate = ctl["hold"], release
        try:
            chunk = {
                "id": "e2e",
                "object": "chat.completion.chunk",
                "created": int(time.time()),
                "model": model,
                "choices": [
                    {
                        "index": 0,
                        "delta": {"role": "assistant", "content": f"from {name}"},
                        "finish_reason": None,
                    }
                ],
            }
            done = dict(
                chunk,
                choices=[{"index": 0, "delta": {}, "finish_reason": "stop"}],
                usage={"prompt_tokens": 3, "completion_tokens": 3, "total_tokens": 6},
            )
            if body.get("stream"):
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.send_header("Connection", "close")
                self.end_headers()
                self.wfile.write(f"data: {json.dumps(chunk)}\n\n".encode())
                self.wfile.flush()
                if hold:
                    gate.wait(300)
                self.wfile.write(
                    f"data: {json.dumps(done)}\n\ndata: [DONE]\n\n".encode()
                )
                self.wfile.flush()
                self.close_connection = True
            else:
                if hold:
                    gate.wait(300)
                self.reply(
                    200,
                    {
                        "id": "e2e",
                        "object": "chat.completion",
                        "created": int(time.time()),
                        "model": model,
                        "choices": [
                            {
                                "index": 0,
                                "message": {
                                    "role": "assistant",
                                    "content": f"from {name}",
                                },
                                "finish_reason": "stop",
                            }
                        ],
                        "usage": {
                            "prompt_tokens": 3,
                            "completion_tokens": 3,
                            "total_tokens": 6,
                        },
                    },
                )
        finally:
            with lock:
                stats["inflight"] -= 1


ThreadingHTTPServer.daemon_threads = True
ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
