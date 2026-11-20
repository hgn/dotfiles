#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, re, sys, ssl, json, imaplib, argparse, urllib.request, shutil, textwrap, unicodedata
from urllib.parse import urlparse
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Dict, Tuple
from collections import Counter
from email.parser import BytesParser
from email.policy import default as email_policy
from email.header import decode_header
from email.utils import parseaddr, parsedate_to_datetime
from email.message import Message

# ---------- Farben ----------
# Styles
RESET = "\033[0m"
BOLD  = "\033[1m"
DIM   = "\033[2m"
ITALIC= "\033[3m"
UNDER = "\033[4m"

# Normal (30–37)
BLACK   = "\033[30m"
RED     = "\033[31m"
GREEN   = "\033[32m"
YELLOW  = "\033[33m"
BLUE    = "\033[34m"
MAGENTA = "\033[35m"
CYAN    = "\033[36m"
WHITE   = "\033[37m"

# Bright (90–97)
BRIGHT_BLACK   = "\033[90m"
BRIGHT_RED     = "\033[91m"
BRIGHT_GREEN   = "\033[92m"
BRIGHT_YELLOW  = "\033[93m"  # <- bright yellow
BRIGHT_BLUE    = "\033[94m"
BRIGHT_MAGENTA = "\033[95m"
BRIGHT_CYAN    = "\033[96m"
BRIGHT_WHITE   = "\033[97m"

ALARM = "\033[1;97;41m"
OK    = "\033[1;30;102m"
WARN  = "\033[1;30;103m"
INFO  = "\033[1;97;44m"

# ---------- Limits ----------
MAX_EMAILS_PER_CLUSTER=500
MAX_CHARS_PER_EMAIL=80000
MAX_CLUSTER_CHARS=600000

# ---------- Utils ----------
def env(n, d=None, req=False):
    v=os.environ.get(n,d)
    if req and not v: sys.stderr.write(f"ERROR: {n} not set\n"); sys.exit(2)
    return v

def parse_imap_target(host_env:str, port_env:Optional[str])->Tuple[str,int,bool,bool]:
    h=host_env.strip()
    if "://" in h:
        u=urlparse(h); sch=(u.scheme or "").lower()
        if not u.hostname: raise ValueError("IMAP_HOST missing hostname")
        if sch in ("imaps","imap+ssl","ssl"): return u.hostname, (u.port or 993), True, False
        if sch in ("imap","imap+starttls"):   return u.hostname, (u.port or 143), False, True
        raise ValueError(f"bad scheme {sch}")
    if ":" in h and h.count(":")==1:
        host, p = h.split(":",1); return host.strip(), int(p.strip()), True, False
    return h, int(port_env) if port_env else 993, True, False

def decode_mime_header_value(v: Optional[str]) -> str:
    if not v: return ""
    parts=decode_header(v); out=[]
    for txt,enc in parts:
        if isinstance(txt,bytes):
            try: out.append(txt.decode(enc or "utf-8","replace"))
            except LookupError: out.append(txt.decode("utf-8","replace"))
        else: out.append(txt)
    return "".join(out).strip()

def parse_from(addr_hdr: Optional[str])->Tuple[str,str]:
    name, addr = parseaddr(addr_hdr or ""); name=decode_mime_header_value(name)
    return (name or ""), (addr or "")

def parse_date_header(date_hdr: Optional[str])->Optional[datetime]:
    if not date_hdr: return None
    try:
        dt=parsedate_to_datetime(date_hdr)
        if not dt: return None
        if dt.tzinfo is None: dt=dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception: return None

def strip_html(html:str)->str:
    html=re.sub(r"(?is)<(script|style).*?>.*?(</\1>)","",html)
    html=re.sub(r"(?is)<br\s*/?>","\n",html)
    html=re.sub(r"(?is)</p>","\n\n",html)
    html=re.sub(r"(?is)<.*?>","",html)
    html=re.sub(r"[ \t\u00A0]+"," ",html)
    html=re.sub(r"\n{3,}","\n\n",html)
    return html.strip()

def truncate(s:str, lim:int)->str:
    return s if len(s)<=lim else s[:max(0,lim-20)]+"\n...[truncated]"

def sanitize_subject_ascii(s:str)->str:
    s=unicodedata.normalize("NFKD", s or "")
    s="".join(ch for ch in s if 32<=ord(ch)<=126)
    return re.sub(r"\s+"," ",s).strip()

def human_delta(dt:Optional[datetime], now=None)->str:
    if not dt: return "-"
    now = now or datetime.now(timezone.utc)
    secs=int((now-dt).total_seconds()); future=secs<0; secs=abs(secs)
    d,rem=divmod(secs,86400); h,rem=divmod(rem,3600); m,_=divmod(rem,60)
    parts=[]
    if d: parts.append(f"{d} Tag{'e' if d!=1 else ''}")
    if h: parts.append(f"{h} Stunde{'n' if h!=1 else ''}")
    if m and not d: parts.append(f"{m} Minute{'n' if m!=1 else ''}")
    if not parts: parts.append("weniger als 1 Minute")
    return ("in " if future else "vor ")+" ".join(parts)

def term_width()->int:
    try: return max(40, shutil.get_terminal_size(fallback=(100,20)).columns)
    except Exception: return 100

def separator_line()->str:
    return "─"*term_width()

# ---------- IMAP ----------
HDR_SPEC='(BODY.PEEK[HEADER.FIELDS (DATE FROM SUBJECT MESSAGE-ID IN-REPLY-TO REFERENCES)] INTERNALDATE UID)'
RE_UID=re.compile(rb'UID\s+(\d+)', re.IGNORECASE)
RE_INTERNAL=re.compile(rb'INTERNALDATE\s+"([^"]+)"', re.IGNORECASE)

def parse_internaldate_str(s:str)->Optional[datetime]:
    try: return datetime.strptime(s,"%d-%b-%Y %H:%M:%S %z").astimezone(timezone.utc)
    except Exception: return None

def uid_fetch_batch(conn:imaplib.IMAP4, uid_list:List[str]):
    if not uid_list: return []
    typ,data=conn.uid("fetch", ",".join(uid_list), HDR_SPEC)
    if typ!="OK" or not data: return []
    out=[]
    for item in data:
        if not isinstance(item,tuple) or len(item)!=2: continue
        meta, hdr = item
        if not isinstance(meta,(bytes,bytearray)): continue
        m_uid=RE_UID.search(meta); m_int=RE_INTERNAL.search(meta)
        if not m_uid: continue
        uid=int(m_uid.group(1))
        internal=parse_internaldate_str(m_int.group(1).decode("ascii","replace")) if m_int else None
        out.append((uid, hdr or b"", internal))
    return out

def uid_fetch_full(conn:imaplib.IMAP4, uid_list:List[int])->Dict[int,Message]:
    res={}
    if not uid_list: return res
    parser=BytesParser(policy=email_policy)
    for i in range(0,len(uid_list),200):
        seq=",".join(str(u) for u in uid_list[i:i+200])
        typ,data=conn.uid("fetch", seq, "(RFC822 UID)")
        if typ!="OK" or not data: continue
        for item in data:
            if not isinstance(item,tuple) or len(item)!=2: continue
            meta, raw = item
            if not isinstance(meta,(bytes,bytearray)): continue
            m_uid=RE_UID.search(meta)
            if not m_uid: continue
            uid=int(m_uid.group(1))
            try: res[uid]=parser.parsebytes(raw or b"")
            except Exception: pass
    return res

def extract_text(msg:Message)->str:
    def dec(p:Message)->str:
        b=p.get_payload(decode=True) or b""
        cs=(p.get_content_charset() or "utf-8").strip().lower()
        try: return b.decode(cs,"replace")
        except Exception: return b.decode("utf-8","replace")
    if msg.is_multipart():
        for p in msg.walk():
            if p.get_content_type().lower()=="text/plain" and "attachment" not in (p.get("Content-Disposition") or "").lower():
                return dec(p).strip()
        for p in msg.walk():
            if p.get_content_type().lower()=="text/html" and "attachment" not in (p.get("Content-Disposition") or "").lower():
                return strip_html(dec(p)).strip()
        return ""
    ct=msg.get_content_type().lower()
    if ct=="text/plain": return dec(msg).strip()
    if ct=="text/html":  return strip_html(dec(msg)).strip()
    return ""

# ---------- Model ----------
class MailNode:
    __slots__=("uid","msgid","from_name","from_addr","subject","date_hdr","internaldate","in_reply_to","references")
    def __init__(self, uid:int, msg, internaldate:Optional[datetime]):
        self.uid=uid
        self.msgid=(msg.get("Message-ID") or "").strip()
        self.from_name,self.from_addr=parse_from(msg.get("From"))
        self.subject=decode_mime_header_value(msg.get("Subject") or "")
        self.date_hdr=parse_date_header(msg.get("Date"))
        self.internaldate=internaldate
        self.in_reply_to=(msg.get("In-Reply-To") or "").strip()
        refs_raw=msg.get("References") or ""
        self.references=[x.strip() for x in refs_raw.split() if x.strip()]

def build_threads(nodes_by_id:Dict[str,MailNode]):
    children:Dict[str,List[str]]={}; parents={}
    for mid,n in nodes_by_id.items():
        p=None
        if n.in_reply_to and n.in_reply_to in nodes_by_id: p=n.in_reply_to
        elif n.references:
            for ref in reversed(n.references):
                if ref in nodes_by_id: p=ref; break
        parents[mid]=p
        if p: children.setdefault(p,[]).append(mid)

    def node_dt(mid:str)->datetime:
        n=nodes_by_id[mid]
        return n.date_hdr or n.internaldate or datetime.min.replace(tzinfo=timezone.utc)

    for pid,lst in children.items(): lst.sort(key=node_dt)
    roots=[mid for mid,p in parents.items() if p is None]

    def subtree_last(mid:str)->datetime:
        last=node_dt(mid)
        for c in children.get(mid,[]):
            cd=subtree_last(c);
            if cd>last: last=cd
        return last

    roots.sort(key=subtree_last, reverse=True)
    return children, roots

# ---------- OpenAI HTTP ----------
SYSTEM_PROMPT_JSON = """Du bekommst eine E-Mail-Konversation (chronologisch, älteste zuerst) als Liste von Objekten:
- date (lokal formatiert), from_name, from_email, subject, body.

Gib EIN JSON-Objekt mit GENAU diesen Feldern zurück:
{
  "summary": "<konkreter deutscher Absatz (1–3 Sätze), NICHT leer, keine Floskeln>",
  "tasks": ["<ToDo, das Hagen Pfeifer (hagen@jauu.net) betrifft>", ...],
  "priority": "normal" | "high"
}

Anforderungen an "summary":
- Muss 1–4 Sätze enthalten und inhaltlich konkret sein.
- Vermeide generische Phrasen wie: "Kurzfassung auf Basis der gelieferten E-Mails", "Zusammenfassung nicht verfügbar", "keine Details", "nicht genug Kontext".
- Nutze Betreff/Inhalt, um Thema, Ziel/Problem und ggf. nächsten Schritt zusammenzufassen.
- Wenn es (technisch) komplex ist, bitte 1-2 Sätze zusätzlich für eine verständliche Beschreibung nutzen. Bei einfachen, verständlichen Aspekten bitte kompakt bleiben.

Anforderung an "tasks":
- Diese sind aus der Email abzuleiten wenn diese an Hagen (Paul) Pfeifer (hagen@jauu.net) direkt addresiert sind.
- Aufgaben, wenn diese an die gesamte Gruppe gerichtet sind.
- Tasks bitte kompakt beschreiben.

Priorität:
- "high" bei klarer Dringlichkeit (Frist, wiederholte Erinnerung/„ping“, explizit eilig, unmittelbarer Handlungsbedarf), sonst "normal".

Keine anderen Felder ausgeben. Keine Inhalte erfinden; nur mit gelieferten E-Mails arbeiten.
"""

def _http_responses(body:dict)->str:
    key=env("OPENAI_API_KEY", req=True)
    req=urllib.request.Request(
        "https://api.openai.com/v1/responses",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type":"application/json","Authorization":f"Bearer {key}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as r:
        data=json.load(r)
    txt=data.get("output_text")
    if txt: return txt.strip()
    segs=[]
    for seg in data.get("output",[]):
        t=seg.get("text")
        if not t and isinstance(seg.get("content"),list) and seg["content"]:
            t=seg["content"][0].get("text")
        if t: segs.append(t)
    return "".join(segs).strip()

def _is_generic_or_empty(summary:str)->bool:
    s=(summary or "").strip().lower()
    if len(s)<20: return True
    bad = [
        "kurzfassung auf basis der gelieferten e-mails",
        "zusammenfassung nicht verfügbar",
        "keine details",
        "nicht genug kontext",
        "keine zusammenfassung",
        "n/a",
    ]
    return any(b in s for b in bad)

def _extract_json_object(txt) -> dict:
    # 0) Direktes Python-Objekt?
    if isinstance(txt, dict):
        return txt
    if isinstance(txt, list):
        # Manche Modelle liefern mal ein Array mit einem Objekt
        return txt[0] if txt and isinstance(txt[0], dict) else {}

    s = (str(txt) if txt is not None else "").strip()

    # 1) Direktes JSON
    try:
        obj = json.loads(s)
        if isinstance(obj, dict):
            return obj
    except Exception:
        pass

    # 2) Code-Fences ```json ... ```
    m = re.match(r"^```(?:json)?\s*(.*?)\s*```$", s, flags=re.DOTALL|re.IGNORECASE)
    if m:
        inner = m.group(1).strip()
        try:
            obj = json.loads(inner)
            if isinstance(obj, dict):
                return obj
        except Exception:
            pass

    # 3) Erste balancierte {...}-Sequenz
    start = s.find("{")
    while start != -1:
        depth = 0
        for i, ch in enumerate(s[start:], start):
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    chunk = s[start:i+1]
                    try:
                        obj = json.loads(chunk)
                        if isinstance(obj, dict):
                            return obj
                    except Exception:
                        break
        start = s.find("{", start + 1)

    # 4) Letzter Versuch: JSON nach Dquotes „reparieren“ (nur wenn wie ein dict aussieht)
    if s.startswith("{") and s.endswith("}"):
        try:
            repaired = re.sub(r"(['\"])\\?([a-zA-Z0-9_]+)\\?(['\"])\s*:", r'"\2":', s)  # Keys normalisieren
            obj = json.loads(repaired)
            if isinstance(obj, dict):
                return obj
        except Exception:
            pass

    return {}


def call_openai_json(messages:list, model:str)->dict:
    base={
        "model": model or "gpt-4o",
        "input":[
            {"role":"system","content":[{"type":"input_text","text":SYSTEM_PROMPT_JSON}]},
            {"role":"user","content":[
                {"type":"input_text","text":"Analysiere und liefere NUR JSON (summary 1–3 Sätze, nicht leer, keine Floskeln):"},
                {"type":"input_text","text":json.dumps(messages, ensure_ascii=False)}
            ]}
        ],
        "temperature":0.2
    }
    # Versuch 1
    try:
        txt=_http_responses({**base, "response_format":{"type":"json_object"}})
    except Exception:
        txt=_http_responses(base)

    obj = _extract_json_object(txt)
    if not isinstance(obj, dict) or not obj:
        obj = {"summary":"", "tasks":[], "priority":"normal"}

    # Wenn leer/zu generisch -> Versuch 2 mit extra Kontext (Betreff + Auszug)
    def last_snippet(ms: list) -> str:
        if not ms: return ""
        body=(ms[-1].get("body") or "")
        for ln in body.splitlines():
            s=ln.strip()
            if len(s)>=40:
                return s[:400]
        return body[:200]

    if _is_generic_or_empty(obj.get("summary","")):
        subj=(messages[0].get("subject") or "").strip()
        hint = (
            "Die Summary darf NICHT generisch sein. Fasse 2–5 Sätze präzise zusammen. "
            f"Betreff der ersten Mail: {subj!r}. "
            f"Auszug der letzten Mail: {last_snippet(messages)!r}."
        )
        stronger={
            **base,
            "input":[
                {"role":"system","content":[{"type":"input_text","text":SYSTEM_PROMPT_JSON}]},
                {"role":"user","content":[
                    {"type":"input_text","text":hint},
                    {"type":"input_text","text":json.dumps(messages, ensure_ascii=False)}
                ]}
            ]
        }
        try:
            txt2=_http_responses({**stronger, "response_format":{"type":"json_object"}})
        except Exception:
            txt2=_http_responses(stronger)

        obj2 = _extract_json_object(txt2)
        if isinstance(obj2, dict) and obj2:
            obj = obj2


    pr=str(obj.get("priority","normal")).strip().lower()
    if pr not in ("normal","high"): pr="normal"
    tasks=obj.get("tasks") or []
    if not isinstance(tasks,list): tasks=[]
    return {"summary":(obj.get("summary") or "").strip(), "tasks":tasks, "priority":pr}

# ---------- Ausgabe ----------
def wrap_summary(text:str)->str:
    return textwrap.fill((text or "").strip(), width=89,
                         initial_indent="  ", subsequent_indent="  ",
                         replace_whitespace=True, drop_whitespace=True)

def conv_line(names:List[str])->str:
    cnt=Counter(n or "(unknown)" for n in names)
    ordered=sorted(cnt.items(), key=lambda kv:(-kv[1], kv[0].lower()))
    parts=[f"\"{n}\" ({c}x)" for n,c in ordered]
    return f"{BOLD+CYAN}Konversation: {RESET}" + ", ".join(parts)

def _fw(s: str, w: int) -> str:
    s = (s or "").strip()
    return s[:w].ljust(w)

def _rel_abs_line(label: str, dt: datetime) -> str:
    rel = human_delta(dt)                      # z.B. "vor 2 Stunden"
    abs_s = dt.astimezone().strftime("%Y-%m-%d %H:%M")
    return (
        f"{BOLD+CYAN}{label:<20}{RESET}"
        f"{BRIGHT_WHITE}{_fw(rel, 30)}{RESET} "
        f"{DIM}({abs_s}){RESET}"
    )



def print_block(first_dt:datetime, last_dt:datetime, subject:str,
                names:List[str], summary:str, priority:str, tasks:List[str]):
    print(separator_line())
    if first_dt == last_dt:
        print(_rel_abs_line("Datum:", last_dt))
    else:
        print(_rel_abs_line("Datum letzte Email:", last_dt))
        print(_rel_abs_line("Datum erste Email:",  first_dt))

    print(f"{BOLD+CYAN}Betreffzeile: {RESET}{BRIGHT_YELLOW}{sanitize_subject_ascii(subject)}{RESET}")
    print(conv_line(names))
    print(f"{BOLD+CYAN}Summary:{RESET}")
    print(wrap_summary(summary if summary else "(keine Zusammenfassung vom Modell)"))
    if priority=="high":
        print(f"{BOLD+CYAN}Priorität: {RESET}{RED}high{RESET}")
    else:
        print(f"{BOLD+CYAN}Priorität: {RESET}normal")
    if tasks:
        print(f"{BOLD+RED}Aufgaben für mich:{RESET}")
        for t in tasks:
            t=(t or "").strip()
            if not t: continue
            print(textwrap.fill(t, width=89, initial_indent="- ", subsequent_indent="  "))

# ---------- Main ----------
def main()->int:
    ap=argparse.ArgumentParser(description="IMAP threads -> JSON-Summary pro Cluster")
    ap.add_argument("--hours", type=int, default=24)
    args=ap.parse_args()

    host_raw=env("IMAP_HOST", req=True); user=env("IMAP_USER", req=True); pwd=env("IMAP_PASS", req=True)
    folder=env("IMAP_FOLDER","INBOX"); port_raw=os.environ.get("IMAP_PORT")
    max_msg=int(os.environ.get("MAX_MSG")) if (os.environ.get("MAX_MSG","").isdigit()) else None
    model=os.environ.get("OPENAI_MODEL","gpt-4o")

    now_utc=datetime.now(timezone.utc); since_utc=now_utc - timedelta(hours=args.hours)
    host,port,use_ssl,use_starttls=parse_imap_target(host_raw, port_raw)
    ctx=ssl.create_default_context()
    if use_ssl: conn=imaplib.IMAP4_SSL(host, port, ssl_context=ctx)
    else: conn=imaplib.IMAP4(host, port);  (use_starttls and conn.starttls(ssl_context=ctx))

    parser=BytesParser(policy=email_policy)
    nodes:Dict[str,MailNode]={}

    with conn as im:
        im.login(user,pwd)
        typ,_=im.select(folder, readonly=True)
        if typ!="OK": sys.stderr.write(f"ERROR: cannot select {folder}\n"); return 3

        typ,data=im.uid("search", None, "ALL")
        if typ!="OK": sys.stderr.write("ERROR: UID SEARCH ALL\n"); return 4
        uids=[u.decode() for u in (data[0].split() if data and data[0] else [])]
        if not uids: return 0
        if max_msg and len(uids)>max_msg: uids=uids[-max_msg:]

        for i in range(0,len(uids),500):
            for uid, hdr, internal in uid_fetch_batch(im, uids[i:i+500]):
                if not hdr: continue
                msg=parser.parsebytes(hdr)
                node=MailNode(uid, msg, internal)
                if node.msgid and node.msgid not in nodes:
                    nodes[node.msgid]=node

        if not nodes: return 0

        children, roots = build_threads(nodes)

        def recent(n:MailNode)->bool: return bool(n.internaldate and n.internaldate>=since_utc)
        recent_ids={mid for mid,n in nodes.items() if recent(n)}
        if not recent_ids: return 0

        def subtree_has_recent(mid:str)->bool:
            if mid in recent_ids: return True
            for c in children.get(mid, []):
                if subtree_has_recent(c): return True
            return False

        selected=[r for r in roots if subtree_has_recent(r)]
        if not selected: return 0

        first_cluster=True
        for r in selected:
            order=[]
            def dfs(mid:str):
                order.append(mid)
                for c in children.get(mid, []): dfs(c)
            dfs(r)

            ordered_u=[nodes[mid].uid for mid in order][:MAX_EMAILS_PER_CLUSTER]
            full=uid_fetch_full(im, ordered_u)

            msgs=[]; names=[]; first_dt=None; last_dt=None; first_subject=None; total=0
            for mid in order:
                n=nodes[mid]
                dt=n.date_hdr or n.internaldate or datetime.min.replace(tzinfo=timezone.utc)
                if first_dt is None: first_dt, first_subject = dt, (n.subject or "(no subject)")
                last_dt=dt
                names.append(n.from_name or n.from_addr or "(unknown)")
                raw=full.get(n.uid); body=extract_text(raw) if raw is not None else ""
                body=truncate(body, MAX_CHARS_PER_EMAIL)
                obj={"date": dt.astimezone().strftime("%Y-%m-%d %H:%M"),
                     "from_name": n.from_name, "from_email": n.from_addr,
                     "subject": n.subject, "body": body}
                total += sum(len(obj[k] or "") for k in ("date","from_name","from_email","subject","body"))
                if total>MAX_CLUSTER_CHARS: break
                msgs.append(obj)

            if not msgs or first_dt is None or last_dt is None: continue

            ai=call_openai_json(msgs, model)
            summary=(ai.get("summary") or "").strip()
            tasks=[t for t in (ai.get("tasks") or []) if (t or "").strip()]
            priority=(ai.get("priority") or "normal").strip().lower()

            print_block(first_dt, last_dt, first_subject, names, summary, priority, tasks)

    return 0

if __name__ == "__main__":
    sys.exit(main())

