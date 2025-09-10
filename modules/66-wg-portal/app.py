#!/usr/bin/env python3
import os, argparse, sqlite3, time, json
from flask import Flask, request, jsonify

DB=os.environ.get("WG_DB_PATH","/var/lib/wg-portal/db.sqlite")
NTFY=os.environ.get("NTFY_WG_ISSUE_URL","")
ADMIN=os.environ.get("WG_PORTAL_ADMIN_KEY","")
REQ_TOKEN=os.environ.get("WG_REQUEST_TOKEN","")

app=Flask(__name__)
os.makedirs(os.path.dirname(DB), exist_ok=True)

def db():
    con=sqlite3.connect(DB); con.row_factory=sqlite3.Row; return con
with db() as c:
    c.execute("CREATE TABLE IF NOT EXISTS requests(id INTEGER PRIMARY KEY, created INTEGER, name TEXT, email TEXT, purpose TEXT)")
    c.commit()

def ntfy(title,msg):
    import urllib.request
    if not NTFY: return
    req=urllib.request.Request(NTFY, data=msg.encode(), headers={"Title":title})
    try: urllib.request.urlopen(req, timeout=5)
    except Exception: pass

@app.post("/wg/request")
def wg_request():
    if REQ_TOKEN and request.args.get("t","")!=REQ_TOKEN: return ("forbidden",403)
    data = request.get_json(force=True, silent=True) or {}
    name=data.get("name",""); email=data.get("email",""); purpose=data.get("purpose","")
    with db() as c:
        c.execute("INSERT INTO requests(created,name,email,purpose) VALUES (?,?,?,?)",(int(time.time()),name,email,purpose)); c.commit()
    ntfy("wg-request", f"name={name} email={email} purpose={purpose}")
    return jsonify({"ok":True})

@app.get("/wg/requests")
def wg_list():
    if ADMIN and request.headers.get("X-Admin-Key","")!=ADMIN: return ("forbidden",403)
    with db() as c:
        rows=[dict(r) for r in c.execute("SELECT * FROM requests ORDER BY created DESC")]
    return jsonify(rows)

if __name__=="__main__":
    ap=argparse.ArgumentParser()
    ap.add_argument("--host", default=os.environ.get("WG_PORTAL_BIND","0.0.0.0"))
    ap.add_argument("--port", default=int(os.environ.get("WG_PORTAL_PORT","8088")))
    ap.add_argument("--db", default=DB)
    args=ap.parse_args()
    app.run(host=args.host, port=args.port)
