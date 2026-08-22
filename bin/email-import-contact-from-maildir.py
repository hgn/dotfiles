#!/usr/bin/env python3
"""Generate a mutt alias file from the keep maildir folder via notmuch.

Collects correspondents from the notmuch index: senders of kept mail plus
recipients of kept mail sent by myself. Addresses are processed newest-first,
so if a person used several addresses over time the most recent one wins.
Senders take precedence over recipients, since the address someone writes
from is more authoritative than the one I typed.
"""

import argparse
import os
import re
import subprocess
import sys
import time
import unicodedata
from dataclasses import dataclass
from email.utils import getaddresses
from pathlib import Path

SELF_NAME_RE = re.compile(r"hagen.*pfeifer|pfeifer.*hagen", re.IGNORECASE)


@dataclass
class Contact:
    name: str
    address: str


def notmuch_address(output: str, query: str) -> list[str]:
    cmd = ["notmuch", "address", "--sort=newest-first", "--deduplicate=no",
           f"--output={output}", query]
    env = dict(os.environ, LC_ALL="C")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, env=env, check=True)
    except FileNotFoundError:
        print("error: notmuch not found in PATH", file=sys.stderr)
        raise SystemExit(1)
    except subprocess.CalledProcessError as exc:
        print(f"error: {' '.join(cmd)} failed:\n{exc.stderr.strip()}", file=sys.stderr)
        raise SystemExit(1)
    return result.stdout.splitlines()


def is_self(name: str, addr: str, self_domains: frozenset[str]) -> bool:
    domain = addr.rsplit("@", 1)[-1]
    return domain in self_domains or bool(SELF_NAME_RE.search(name))


GERMAN_FOLD = str.maketrans({"ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss"})


def clean_name(name: str) -> str:
    return " ".join(name.split()).strip("'\" ")


def ascii_fold(text: str) -> str:
    text = text.lower().translate(GERMAN_FOLD)
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()


def person_key(name: str, addr: str) -> str:
    folded = ascii_fold(name)
    return folded if folded else addr


def alias_key(name: str, addr: str) -> str:
    base = name if name else addr.split("@", 1)[0]
    key = re.sub(r"[^a-z0-9]+", "-", ascii_fold(base)).strip("-")
    return key if key else re.sub(r"[^a-z0-9]+", "-", addr.lower()).strip("-")


def alias_line(key: str, contact: Contact) -> str:
    if contact.name:
        quoted = contact.name.replace("\\", "\\\\").replace('"', '\\"')
        return f'alias {key} "{quoted}" <{contact.address}>'
    return f"alias {key} <{contact.address}>"


def absorb(lines: list[str], contacts: dict[str, Contact], seen_addrs: set[str],
           self_domains: frozenset[str]) -> None:
    """Add addresses newest-first; the first occurrence of a person or address wins."""
    for line in lines:
        for raw_name, raw_addr in getaddresses([line]):
            name, addr = clean_name(raw_name), raw_addr.strip().lower()
            if "@" not in addr or addr in seen_addrs or is_self(name, addr, self_domains):
                continue
            seen_addrs.add(addr)
            contacts.setdefault(person_key(name, addr), Contact(name, addr))


def render(contacts: dict[str, Contact]) -> str:
    lines: list[str] = []
    used: set[str] = set()
    for contact in sorted(contacts.values(), key=lambda c: alias_key(c.name, c.address)):
        key = alias_key(contact.name, contact.address)
        candidate, serial = key, 2
        while candidate in used:
            candidate = f"{key}-{serial}"
            serial += 1
        used.add(candidate)
        lines.append(alias_line(candidate, contact))
    return "\n".join(lines) + "\n" if lines else ""


def main() -> int:
    argp = argparse.ArgumentParser(
        description="generate a mutt alias file from the keep folder via notmuch")
    argp.add_argument("-f", "--folder", default="keep",
                      help="maildir folder to scan (default: keep)")
    argp.add_argument("-o", "--output", default=str(Path.home() / ".mutt" / "aliases"),
                      help="output alias file, '-' for stdout (default: ~/.mutt/aliases)")
    argp.add_argument("--self-domain", action="append", default=["jauu.net"],
                      help="own mail domain to exclude (repeatable, default: jauu.net)")
    args = argp.parse_args()

    print("Starting email-import: generating mutt \033[32maliases\033[0m via notmuch...", file=sys.stderr)
    start = time.monotonic()
    self_domains = frozenset(args.self_domain)
    self_query = " or ".join(f"from:{d}" for d in self_domains)

    contacts: dict[str, Contact] = {}
    seen_addrs: set[str] = set()
    absorb(notmuch_address("sender", f"folder:{args.folder}"), contacts, seen_addrs,
           self_domains)
    absorb(notmuch_address("recipients", f"folder:{args.folder} and ({self_query})"),
           contacts, seen_addrs, self_domains)
    output = render(contacts)

    if args.output == "-":
        sys.stdout.write(output)
    else:
        target = Path(args.output)
        tmp = target.with_name(target.name + ".tmp")
        tmp.write_text(output, encoding="utf-8")
        tmp.rename(target)

    elapsed = time.monotonic() - start
    print(f"    completed in \033[36m{elapsed:.2f}\033[0m seconds (\033[36m{len(contacts)}\033[0m aliases)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
