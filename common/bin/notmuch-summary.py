#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import os
import re
import shutil
import subprocess
import textwrap
import unicodedata
import urllib.request
from collections import Counter
from datetime import datetime, timezone
from email.header import decode_header
from email.message import Message
from email.parser import BytesParser
from email.policy import default as email_policy
from email.utils import parseaddr, parsedate_to_datetime
from typing import Dict, List, Optional, Tuple

RESET = "\033[0m"; BOLD = "\033[1m"; DIM = "\033[2m"; CYAN = "\033[36m"
BRIGHT_WHITE = "\033[97m"; BRIGHT_YELLOW = "\033[93m"; RED = "\033[31m"; GREY = "\033[90m"

MAX_EMAILS_PER_CLUSTER = 500
MAX_CHARS_PER_EMAIL = 80000
MAX_CLUSTER_CHARS = 600000


def env(name: str, default=None, required: bool = False):
    val = os.environ.get(name, default)
    if required and not val:
        sys_stderr(f"ERROR: {name} not set"); exit_code(2)
    return val


def sys_stderr(msg: str):
    import sys
    sys.stderr.write(msg + ("\n" if not msg.endswith("\n") else ""))


def exit_code(code: int):
    import sys
    sys.exit(code)


def decode_mime_header_value(val: Optional[str]) -> str:
    if not val:
        return ""
    parts = decode_header(val); out: List[str] = []
    for text, enc in parts:
        if isinstance(text, bytes):
            try:
                out.append(text.decode(enc or "utf-8", "replace"))
            except LookupError:
                out.append(text.decode("utf-8", "replace"))
        else:
            out.append(text)
    return "".join(out).strip()


def parse_from(addr_hdr: Optional[str]) -> Tuple[str, str]:
    name, addr = parseaddr(addr_hdr or "")
    return (decode_mime_header_value(name) or ""), (addr or "")


def parse_date_header(date_hdr: Optional[str]) -> Optional[datetime]:
    if not date_hdr:
        return None
    try:
        dt = parsedate_to_datetime(date_hdr)
        if not dt:
            return None
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None


def truncate(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: max(0, limit - 20)] + "\n...[truncated]"


def sanitize_subject_ascii(text: str) -> str:
    text = unicodedata.normalize("NFKD", text or "")
    text = "".join(ch for ch in text if 32 <= ord(ch) <= 126)
    return re.sub(r"\s+", " ", text).strip()


def human_delta(dt: Optional[datetime], now=None) -> str:
    if not dt:
        return "-"
    now = now or datetime.now(timezone.utc)
    secs = int((now - dt).total_seconds()); future = secs < 0; secs = abs(secs)
    d, rem = divmod(secs, 86400); h, rem = divmod(rem, 3600); m, _ = divmod(rem, 60)
    parts = []
    if d:
        parts.append(f"{d} Tag{'e' if d != 1 else ''}")
    if h:
        parts.append(f"{h} Stunde{'n' if h != 1 else ''}")
    if m and not d:
        parts.append(f"{m} Minute{'n' if m != 1 else ''}")
    if not parts:
        parts.append("weniger als 1 Minute")
    return ("in " if future else "vor ") + " ".join(parts)


def term_width() -> int:
    try:
        return max(40, shutil.get_terminal_size(fallback=(100, 20)).columns)
    except Exception:
        return 100


def separator_line() -> str:
    return "─" * term_width()


def run_subprocess(cmd: List[str], input_text: Optional[str] = None) -> str:
    try:
        r = subprocess.run(cmd, check=True, text=True, capture_output=True, input=input_text)
        return r.stdout
    except FileNotFoundError:
        sys_stderr(f"ERROR: {cmd[0]} not found"); exit_code(127)
    except subprocess.CalledProcessError as e:
        sys_stderr(e.stderr or f"ERROR running: {' '.join(cmd)}"); exit_code(e.returncode or 1)
    return ""


def lynx_html_to_text(html: str) -> str:
    try:
        return run_subprocess(["lynx", "-dump", "-nolist", "-stdin"], input_text=html)
    except SystemExit:
        return ""


def read_mail_body_from_file(path: str) -> Tuple[str, str]:
    try:
        with open(path, "rb") as f:
            msg: Message = BytesParser(policy=email_policy).parse(f)
    except Exception:
        return "", ""
    plain_parts: List[str] = []; html_parts: List[str] = []
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_disposition() == "attachment":
                continue
            ctype = (part.get_content_type() or "").lower()
            try:
                if ctype == "text/plain":
                    plain_parts.append(part.get_content())
                elif ctype == "text/html":
                    html_parts.append(part.get_content())
            except Exception:
                pass
    else:
        ctype = (msg.get_content_type() or "").lower()
        try:
            if ctype == "text/plain":
                plain_parts.append(msg.get_content())
            elif ctype == "text/html":
                html_parts.append(msg.get_content())
        except Exception:
            pass
    plain = "\n".join(t for t in plain_parts if isinstance(t, str)).strip()
    html = "\n".join(h for h in html_parts if isinstance(h, str)).strip()
    return plain, html


def clean_subject_root(s: str) -> str:
    if not s:
        return ""
    s = s.strip()
    rx = re.compile(r"^\s*(?:re|aw|wg|sv|fw|fwd|tr|rv|res|enc)(?:\[\d+\])?\s*[:：]\s*", re.I)
    prev = None
    while s and s != prev and rx.match(s):
        prev = s; s = rx.sub("", s)
    s = re.sub(r"^\s*\[\s*(?:EXTERNAL|SPAM|VIRUS|JUNK)\s*\]\s*", "", s, flags=re.I)
    return s.strip()


def build_notmuch_query(folder: str, tag: Optional[str], raw_query: Optional[str], since_hours: int) -> str:
    base = (raw_query.strip() if raw_query else None)
    if not base:
        base = f"tag:{tag.strip()}" if tag else f"folder:{folder.strip()}"
    return f"{base} and date:{since_hours}hour.."


class EmailMessageLite:
    __slots__ = ("date_dt", "date_str", "from_name", "from_email", "subject", "body", "message_id")

    def __init__(self, date_dt: datetime, from_name: str, from_email: str, subject: str, body: str, message_id: str):
        self.date_dt = date_dt
        self.date_str = date_dt.astimezone().strftime("%Y-%m-%d %H:%M") if date_dt else ""
        self.from_name = from_name or ""
        self.from_email = from_email or ""
        self.subject = subject or ""
        self.body = body or ""
        self.message_id = message_id or ""


class Conversation:
    __slots__ = ("first_dt", "last_dt", "first_subject", "names", "messages", "last_message_id")

    def __init__(
        self,
        first_dt: datetime,
        last_dt: datetime,
        first_subject: str,
        names: List[str],
        messages: List[EmailMessageLite],
        last_message_id: str,
    ):
        self.first_dt = first_dt; self.last_dt = last_dt
        self.first_subject = first_subject
        self.names = names
        self.messages = messages
        self.last_message_id = last_message_id or ""


class MailBackend:
    def fetch_conversations(self, query: str, max_threads: Optional[int] = None) -> List[Conversation]:
        raise NotImplementedError


class NotmuchBackend(MailBackend):
    def _json(self, s: str):
        try:
            return json.loads(s or "[]")
        except Exception:
            return []

    def _nm_threads(self, query: str) -> List[str]:
        arr = self._json(run_subprocess(["notmuch", "search", "--format=json", "--output=threads", query]))
        return [t for t in arr if isinstance(t, str)]

    def _nm_show_thread(self, tid: str):
        return self._json(run_subprocess(["notmuch", "show", "--entire-thread=true", "--format=json", f"thread:{tid}"]))

    def _append_flat(self, node, out: List[dict]):
        if isinstance(node, list):
            for n in node:
                self._append_flat(n, out)
            return
        if not isinstance(node, dict):
            return
        h = node.get("headers") or {}
        fn = node.get("filename")
        path = fn[0] if isinstance(fn, list) and fn else (fn if isinstance(fn, str) else None)
        subj = decode_mime_header_value(h.get("Subject") or "")
        f_name, f_addr = parse_from(h.get("From"))
        dt = parse_date_header(h.get("Date"))
        mid = (node.get("id") or (h.get("Message-Id") or h.get("Message-ID") or "")).strip()
        body_text, body_html = ("", "")
        if path:
            body_text, body_html = read_mail_body_from_file(path)
        content = lynx_html_to_text(body_html) if body_html else body_text
        out.append(
            {
                "from_name": f_name,
                "from_email": f_addr,
                "subject": subj,
                "date_dt": dt,
                "content": content,
                "message_id": mid,
            }
        )
        if isinstance(node.get("replies"), list):
            self._append_flat(node["replies"], out)
        if isinstance(node.get("content"), list):
            self._append_flat(node["content"], out)

    def fetch_conversations(self, query: str, max_threads: Optional[int] = None) -> List[Conversation]:
        tids = self._nm_threads(query)
        if max_threads and len(tids) > max_threads:
            tids = tids[: max_threads]
        convs: List[Conversation] = []
        for tid in tids:
            show = self._nm_show_thread(tid); flat: List[dict] = []
            self._append_flat(show, flat)
            flat = [m for m in flat if m.get("date_dt") is not None]
            if not flat:
                continue
            flat.sort(key=lambda x: x["date_dt"])
            names: List[str] = []; msgs: List[EmailMessageLite] = []; total = 0
            first_dt = flat[0]["date_dt"]; last_dt = flat[-1]["date_dt"]
            first_subject = clean_subject_root(flat[0]["subject"] or "(no subject)")
            last_mid = flat[-1].get("message_id") or ""
            for m in flat[:MAX_EMAILS_PER_CLUSTER]:
                names.append(m.get("from_name") or m.get("from_email") or "(unknown)")
                body = truncate(m.get("content") or "", MAX_CHARS_PER_EMAIL)
                em = EmailMessageLite(
                    m["date_dt"], m.get("from_name") or "", m.get("from_email") or "", m.get("subject") or "", body, m.get("message_id") or ""
                )
                total += len(em.date_str) + len(em.from_name) + len(em.from_email) + len(em.subject) + len(em.body)
                if total > MAX_CLUSTER_CHARS:
                    break
                msgs.append(em)
            if msgs:
                convs.append(Conversation(first_dt, last_dt, first_subject, names, msgs, last_mid))
        return convs


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
- Tasks bitte kompakt beschreiben.

Priorität:
- "high" bei klarer Dringlichkeit (Frist, wiederholte Erinnerung/„ping“, explizit eilig, unmittelbarer Handlungsbedarf), sonst "normal".

Keine anderen Felder ausgeben. Keine Inhalte erfinden; nur mit gelieferten E-Mails arbeiten.
"""


class Analyzer:
    def __init__(self, model: str):
        self.model = model or "gpt-4o"

    def _http_responses(self, body: dict) -> str:
        key = env("OPENAI_API_KEY", required=True)
        req = urllib.request.Request(
            "https://api.openai.com/v1/responses",
            data=json.dumps(body).encode("utf-8"),
            headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=120) as r:
            data = json.load(r)
        txt = data.get("output_text")
        if txt:
            return txt.strip()
        segs: List[str] = []
        for seg in data.get("output", []):
            t = seg.get("text")
            if not t and isinstance(seg.get("content"), list) and seg["content"]:
                t = seg["content"][0].get("text")
            if t:
                segs.append(t)
        return "".join(segs).strip()

    def _extract_json_object(self, txt):
        if isinstance(txt, dict):
            return txt
        if isinstance(txt, list):
            return txt[0] if txt and isinstance(txt[0], dict) else {}
        s = (str(txt) if txt is not None else "").strip()
        obj = self._parse_direct(s) or self._parse_codeblock(s) or self._parse_bruteforce(s) or self._parse_repaired(s)
        return obj or {}

    def _parse_direct(self, s: str):
        try:
            obj = json.loads(s)
            return obj if isinstance(obj, dict) else {}
        except Exception:
            return {}

    def _parse_codeblock(self, s: str):
        m = re.match(r"^```(?:json)?\s*(.*?)\s*```$", s, flags=re.S | re.I)
        if not m:
            return {}
        inner = m.group(1).strip()
        try:
            obj = json.loads(inner)
            return obj if isinstance(obj, dict) else {}
        except Exception:
            return {}

    def _parse_bruteforce(self, s: str):
        start = s.find("{")
        while start != -1:
            depth = 0
            for i, ch in enumerate(s[start:], start):
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        chunk = s[start : i + 1]
                        try:
                            obj = json.loads(chunk)
                            return obj if isinstance(obj, dict) else {}
                        except Exception:
                            break
            start = s.find("{", start + 1)
        return {}

    def _parse_repaired(self, s: str):
        if not (s.startswith("{") and s.endswith("}")):
            return {}
        try:
            repaired = re.sub(r"(['\"])\\?([a-zA-Z0-9_]+)\\?(['\"])\\s*:", r'"\2":', s)
            obj = json.loads(repaired)
            return obj if isinstance(obj, dict) else {}
        except Exception:
            return {}

    def _is_generic_or_empty(self, summary: str) -> bool:
        s = (summary or "").strip().lower()
        if len(s) < 20:
            return True
        bad = [
            "kurzfassung auf basis der gelieferten e-mails",
            "zusammenfassung nicht verfügbar",
            "keine details",
            "nicht genug kontext",
            "keine zusammenfassung",
            "n/a",
        ]
        return any(b in s for b in bad)

    def analyze(self, messages: list) -> dict:
        base = {
            "model": self.model,
            "input": [
                {"role": "system", "content": [{"type": "input_text", "text": SYSTEM_PROMPT_JSON}]},
                {
                    "role": "user",
                    "content": [
                        {"type": "input_text", "text": "Analysiere und liefere NUR JSON (summary 1–3 Sätze, nicht leer, keine Floskeln):"},
                        {"type": "input_text", "text": json.dumps(messages, ensure_ascii=False)},
                    ],
                },
            ],
            "temperature": 0.2,
        }
        try:
            txt = self._http_responses({**base, "response_format": {"type": "json_object"}})
        except Exception:
            txt = self._http_responses(base)
        obj = self._extract_json_object(txt) or {"summary": "", "tasks": [], "priority": "normal"}

        def last_snippet(ms: list) -> str:
            if not ms:
                return ""
            body = (ms[-1].get("body") or "")
            for ln in body.splitlines():
                s = ln.strip()
                if len(s) >= 40:
                    return s[:400]
            return body[:200]

        if self._is_generic_or_empty(obj.get("summary", "")) and messages:
            subj = (messages[0].get("subject") or "").strip()
            hint = (
                "Die Summary darf NICHT generisch sein. Fasse 2–5 Sätze präzise zusammen. "
                f"Betreff der ersten Mail: {subj!r}. "
                f"Auszug der letzten Mail: {last_snippet(messages)!r}."
            )
            stronger = {
                **base,
                "input": [
                    {"role": "system", "content": [{"type": "input_text", "text": SYSTEM_PROMPT_JSON}]},
                    {"role": "user", "content": [{"type": "input_text", "text": hint}, {"type": "input_text", "text": json.dumps(messages, ensure_ascii=False)}]},
                ],
            }
            try:
                txt2 = self._http_responses({**stronger, "response_format": {"type": "json_object"}})
            except Exception:
                txt2 = self._http_responses(stronger)
            obj2 = self._extract_json_object(txt2)
            if isinstance(obj2, dict) and obj2:
                obj = obj2

        pr = str(obj.get("priority", "normal")).strip().lower()
        if pr not in ("normal", "high"):
            pr = "normal"
        tasks = obj.get("tasks") or []
        if not isinstance(tasks, list):
            tasks = []
        return {"summary": (obj.get("summary") or "").strip(), "tasks": tasks, "priority": pr}


class Renderer:
    def __init__(self, maildir_path: str):
        self.maildir_path = maildir_path

    def wrap_summary(self, text: str) -> str:
        return textwrap.fill(
            (text or "").strip(), width=89, initial_indent="  ", subsequent_indent="  ", replace_whitespace=True, drop_whitespace=True
        )

    def conv_line(self, names: List[str]) -> str:
        cnt = Counter(n or "(unknown)" for n in names)
        ordered = sorted(cnt.items(), key=lambda kv: (-kv[1], kv[0].lower()))
        parts = [f"\"{n}\" ({c}x)" for n, c in ordered]
        return f"{BOLD+CYAN}Konversation: {RESET}" + ", ".join(parts)

    def _fw(self, s: str, w: int) -> str:
        s = (s or "").strip()
        return s[:w].ljust(w)

    def _rel_abs_line(self, label: str, dt: datetime) -> str:
        rel = human_delta(dt)
        abs_s = dt.astimezone().strftime("%Y-%m-%d %H:%M")
        return f"{BOLD+CYAN}{label:<20}{RESET}{BRIGHT_WHITE}{self._fw(rel, 30)}{RESET} {DIM}({abs_s}){RESET}"

    def reply_cmd(self, msgid: str) -> str:
        msgid = msgid or ""
        return f'Reply: mutt-offline -f {self.maildir_path} -e "push l~i{msgid}\\nr"'

    def print_block(self, conv: Conversation, summary: str, priority: str, tasks: List[str]):
        print(separator_line())
        if conv.first_dt == conv.last_dt:
            print(self._rel_abs_line("Datum:", conv.last_dt))
        else:
            print(self._rel_abs_line("Datum letzte Email:", conv.last_dt))
            print(self._rel_abs_line("Datum erste Email:", conv.first_dt))
        subj = sanitize_subject_ascii(conv.first_subject)
        print(f"{BOLD+CYAN}Betreffzeile: {RESET}{BRIGHT_YELLOW}{subj}{RESET}")
        print(self.conv_line(conv.names))
        print(f"{BOLD+CYAN}Summary:{RESET}")
        print(self.wrap_summary(summary if summary else "(keine Zusammenfassung vom Modell)"))
        if priority == "high":
            print(f"{BOLD+CYAN}Priorität: {RESET}{RED}high{RESET}")
        else:
            print(f"{BOLD+CYAN}Priorität: {RESET}normal")
        if tasks:
            print(f"{BOLD+RED}Aufgaben für mich:{RESET}")
            for t in tasks:
                t = (t or "").strip()
                if not t:
                    continue
                print(textwrap.fill(t, width=89, initial_indent="- ", subsequent_indent="  "))
        print(GREY + self.reply_cmd(conv.last_message_id) + RESET)


def convo_to_model_messages(conv: Conversation) -> List[dict]:
    return [
        {"date": m.date_str, "from_name": m.from_name, "from_email": m.from_email, "subject": m.subject, "body": m.body}
        for m in conv.messages
    ]


def compute_stats(convs: List[Conversation]) -> Dict[str, object]:
    emails = sum(len(c.messages) for c in convs)
    threads = len(convs)
    authors_all: List[str] = []
    for c in convs:
        for m in c.messages:
            authors_all.append(m.from_email or m.from_name or "(unknown)")
    unique_authors = len(set(a.lower() for a in authors_all if a))
    avg_len = (emails / threads) if threads else 0.0
    all_dates = [m.date_dt for c in convs for m in c.messages if m.date_dt]
    span = ""
    if all_dates:
        oldest = min(all_dates); newest = max(all_dates)
        span = f"{oldest.astimezone().strftime('%Y-%m-%d %H:%M')}  …  {newest.astimezone().strftime('%Y-%m-%d %H:%M')}"
    top = Counter(a or "(unknown)" for a in authors_all).most_common(3)
    return {"emails": emails, "threads": threads, "authors": unique_authors, "avg_thread_len": avg_len, "time_span": span, "top_authors": top}


def print_stats(stats: Dict[str, object]):
    print(f"- Emails: {stats['emails']}")
    print(f"- Threads: {stats['threads']}")
    print(f"- Authors: {stats['authors']}")
    if stats["avg_thread_len"]:
        print(f"- Avg/Thread: {stats['avg_thread_len']:.2f}")
    if stats["time_span"]:
        print(f"- Span: {stats['time_span']}")
    if stats["top_authors"]:
        tops = ", ".join(f"{name} ({cnt})" for name, cnt in stats["top_authors"])
        print(f"- Top Authors: {tops}")
    print(separator_line())


def main() -> int:
    ap = argparse.ArgumentParser(description="Maildir/Notmuch -> AI Summary je Thread (mit Reply-Zeile + Stats)")
    ap.add_argument("--hours", type=int, default=12)
    ap.add_argument("--folder", default="INBOX", help="Notmuch folder:… Filter (Default)")
    ap.add_argument("--tag", default=None, help="Notmuch tag:… Filter (Alternative zu --folder), linux-perf, linux-pm-intel, linux-trace, linux-bpf, ..")
    ap.add_argument("--query", default=None, help="Komplette Notmuch-Query; überschreibt --folder/--tag, z.b. tag:linux-perf and from:hagen@jauu.net")
    ap.add_argument("--max-threads", type=int, default=None)
    ap.add_argument(
        "--model",
        default=os.environ.get("OPENAI_MODEL", "gpt-4o"),
        choices=["gpt-4o", "gpt-4o-mini", "gpt-4.1", "gpt-4.1-mini", "gpt-3.5-turbo", "o1", "o4-mini"],
    )
    ap.add_argument("--maildir-path", default=env("MAILDIR_PATH", "/home/pfeifer/.mail/INBOX/"))
    args = ap.parse_args()

    nm_query = build_notmuch_query(args.folder, args.tag, args.query, args.hours)
    backend = NotmuchBackend(); analyzer = Analyzer(args.model); renderer = Renderer(args.maildir_path)

    convs = backend.fetch_conversations(query=nm_query, max_threads=args.max_threads)
    if not convs:
        print("- Emails: 0\n- Threads: 0\n- Authors: 0")
        return 0

    stats = compute_stats(convs); print_stats(stats)
    for conv in convs:
        ai = analyzer.analyze(convo_to_model_messages(conv))
        renderer.print_block(
            conv,
            ai.get("summary", "").strip(),
            (ai.get("priority") or "normal").strip().lower(),
            [t for t in (ai.get("tasks") or []) if (t or "").strip()],
        )
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())

