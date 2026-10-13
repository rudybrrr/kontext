#!/usr/bin/env python3
"""Generate Evals/captures.json and Evals/search_queries.json (synthetic labelled fixtures)."""
from __future__ import annotations

import json
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TZ = timezone(timedelta(hours=8))
REF_BASE = datetime(2025, 10, 8, 9, 0, 0, tzinfo=TZ)


def iso(dt: datetime) -> str:
    return dt.isoformat()


def ref(day_offset: int = 0, hour: int = 9) -> str:
    return iso(REF_BASE + timedelta(days=day_offset, hours=hour - 9))


def action(kind: str, keywords: list[str], start=None, end=None, due=None, all_day=False, location=None):
    return {
        "kind": kind,
        "titleKeywords": keywords,
        "startISO": iso(start) if start else None,
        "endISO": iso(end) if end else None,
        "dueISO": iso(due) if due else None,
        "isAllDay": all_day,
        "location": location,
    }


def cap(cid, kind, text, reference_date, expected, **extra):
    row = {
        "id": cid,
        "kind": kind,
        "referenceDateISO": reference_date,
        "text": text,
        "negative": len(expected) == 0,
        "expectedActions": expected,
    }
    row.update(extra)
    return row


def build_captures() -> list[dict]:
    items: list[dict] = []
    n = 0

    def add(kind, text, expected, rdate=ref(), **kw):
        nonlocal n
        n += 1
        items.append(cap(f"cap-{n:03d}", kind, text, rdate, expected, **kw))

    # --- Text captures (40) ---
    add(
        "text",
        "Team standup next Fri 10am at WeWork Beach Road.",
        [action("event", ["standup", "team"], REF_BASE.replace(hour=10) + timedelta(days=4), location="WeWork Beach Road")],
    )
    add("text", "Dinner with Priya 12/10/2025 7:30pm at Lau Pa Sat.", [
        action("event", ["dinner", "priya"], datetime(2025, 10, 12, 19, 30, tzinfo=TZ), location="Lau Pa Sat")
    ])
    add("text", "Client workshop 3-5pm tomorrow.", [
        action("event", ["workshop", "client"], REF_BASE.replace(hour=15) + timedelta(days=1),
         end=REF_BASE.replace(hour=17) + timedelta(days=1))
    ])
    add("text", "Sat 12 Oct brunch 11am Holland V.", [
        action("event", ["brunch"], datetime(2025, 10, 12, 11, 0, tzinfo=TZ), location="Holland V")
    ])
    add("text", "Remind me to pay utilities next Mon 9am.", [
        action("reminder", ["utilities", "pay"], due=REF_BASE.replace(hour=9) + timedelta(days=3))
    ])
    add("text", "Dentist 15/10/2025 14:00 Raffles Medical.", [
        action("event", ["dentist"], datetime(2025, 10, 15, 14, 0, tzinfo=TZ), location="Raffles Medical")
    ])
    add("text", "Flight SQ305 departs 18 Oct 8:05pm Changi T3.", [
        action("event", ["flight", "sq305"], datetime(2025, 10, 18, 20, 5, tzinfo=TZ), location="Changi T3")
    ])
    add("text", "School holiday 20 Oct all day — no meetings.", [
        action("event", ["school", "holiday"], datetime(2025, 10, 20, 0, 0, tzinfo=TZ), all_day=True)
    ])
    add("text", "[WhatsApp] Mum: 吃饭 Sunday 6:30pm 金沙", [
        action("event", ["吃饭", "dinner"], datetime(2025, 10, 12, 18, 30, tzinfo=TZ), location="金沙")
    ])
    add("text", "[Telegram] Hackathon briefing Fri 4-6pm Block 71.", [
        action("event", ["hackathon", "briefing"], REF_BASE.replace(hour=16) + timedelta(days=4),
         end=REF_BASE.replace(hour=18) + timedelta(days=4), location="Block 71")
    ])
    add("text", "Email subject: Confirmed — Product review 9 Oct 3pm Zoom.", [
        action("event", ["product", "review"], datetime(2025, 10, 9, 15, 0, tzinfo=TZ))
    ])
    add("text", "National Day parade watch party 9 Aug 7pm (cancelled last year).", [])
    add("text", "Meeting was yesterday 3pm — moved to next week.", [])
    add("text", "Two sessions: UX critique Tue 2pm and eng sync Tue 4:30pm.", [
        action("event", ["ux", "critique"], REF_BASE.replace(hour=14) + timedelta(days=1)),
        action("event", ["eng", "sync"], REF_BASE.replace(hour=16, minute=30) + timedelta(days=1)),
    ])
    add("text", "Pasir Ris park run Sat 7am.", [
        action("event", ["park", "run"], datetime(2025, 10, 11, 7, 0, tzinfo=TZ), location="Pasir Ris")
    ])
    add("text", "Jemakan makan tengah hari Jumaat 12:30 tengah hari.", [
        action("event", ["makan"], REF_BASE.replace(hour=12, minute=30) + timedelta(days=4))
    ])
    add("text", "Notes on Swift actors — no schedule here.", [])
    add("text", "Remember to buy milk tonight.", [
        action("reminder", ["milk"], due=REF_BASE.replace(hour=20))
    ])
    add("text", "1-to-1 with Alex next Wed 11:15am.", [
        action("event", ["alex", "1-to-1"], REF_BASE.replace(hour=11, minute=15) + timedelta(days=2))
    ])
    add("text", "Piano lesson 13/10 5pm Buona Vista.", [
        action("event", ["piano"], datetime(2025, 10, 13, 17, 0, tzinfo=TZ), location="Buona Vista")
    ])
    add("text", "Community centre blood drive 25 Oct 9am-12pm.", [
        action("event", ["blood", "drive"], datetime(2025, 10, 25, 9, 0, tzinfo=TZ),
         end=datetime(2025, 10, 25, 12, 0, tzinfo=TZ))
    ])
    add("text", "Random bookmark about typography.", [])
    add("text", "NTUC receipt total $42.80.", [])
    add("text", "Hawker promo flyer: Free coffee 11 Oct 8-10am Tiong Bahru.", [
        action("event", ["coffee", "promo"], datetime(2025, 10, 11, 8, 0, tzinfo=TZ),
         end=datetime(2025, 10, 11, 10, 0, tzinfo=TZ), location="Tiong Bahru")
    ])
    add("text", "Gym 6am daily habit (not a calendar invite).", [])
    add("text", "Send deck to investor before Thu 5pm.", [
        action("reminder", ["deck", "investor"], due=REF_BASE.replace(hour=17) + timedelta(days=2))
    ])
    add("text", "Lunch 明天 12pm 莱佛士坊.", [
        action("event", ["lunch"], REF_BASE.replace(hour=12) + timedelta(days=1), location="莱佛士坊")
    ])
    add("text", "Board meeting 30/09/2025 9am MBFC Tower 3.", [
        action("event", ["board", "meeting"], datetime(2025, 9, 30, 9, 0, tzinfo=TZ), location="MBFC Tower 3")
    ])
    add("text", "Quote: 'Time is a flat circle.'", [])
    add("text", "Pickup passport ICA 17 Oct 2:15pm.", [
        action("event", ["passport", "ica"], datetime(2025, 10, 17, 14, 15, tzinfo=TZ))
    ])
    add("text", "Webinar replay link only — no date.", [])
    add("text", "House viewing Sun 19 Oct 4-5:30pm Serangoon.", [
        action("event", ["house", "viewing"], datetime(2025, 10, 19, 16, 0, tzinfo=TZ),
         end=datetime(2025, 10, 19, 17, 30, tzinfo=TZ), location="Serangoon")
    ])
    add("text", "Paylah transfer to Jason $15.", [])
    add("text", "Volunteer shift 22/10 18:00-21:00 Food Bank.", [
        action("event", ["volunteer", "food bank"], datetime(2025, 10, 22, 18, 0, tzinfo=TZ),
         end=datetime(2025, 10, 22, 21, 0, tzinfo=TZ))
    ])
    add("text", "Kids science camp 14 Oct all day.", [
        action("event", ["science", "camp"], datetime(2025, 10, 14, 0, 0, tzinfo=TZ), all_day=True)
    ])
    add("text", "Architecture notes from lecture.", [])
    add("text", "Call plumber Tue 8am.", [
        action("event", ["plumber", "call"], REF_BASE.replace(hour=8) + timedelta(days=1))
    ])
    add("text", "Reminder: submit claims by 31/10 23:59.", [
        action("reminder", ["claims", "submit"], due=datetime(2025, 10, 31, 23, 59, tzinfo=TZ))
    ])
    add("text", "Meeting invite declined — conflict.", [])

    # Pad to 40 text if needed
    while sum(1 for i in items if i["kind"] == "text") < 40:
        add("text", f"Misc note {len(items)} about caching.", [])

    # --- Screenshot-style (30) ---
    for i in range(30):
        idx = len(items) + 1
        cid = f"cap-{idx:03d}"
        img = f"Evals/fixtures/screenshots/{cid}.png"
        if i % 7 == 0:
            items.append(cap(cid, "screenshot", "Screenshot: MRT map legend only.", ref(), [], imagePath=img))
        elif i % 7 == 1:
            items.append(cap(cid, "screenshot", "Flyer: Zumba class 16 Oct 7pm Bishan CC.", ref(), [
                action("event", ["zumba"], datetime(2025, 10, 16, 19, 0, tzinfo=TZ), location="Bishan CC")
            ], imagePath=img))
        elif i % 7 == 2:
            items.append(cap(cid, "screenshot", "Chat screenshot — meet 10 Oct 1pm Starbucks Raffles.", ref(), [
                action("event", ["meet", "starbucks"], datetime(2025, 10, 10, 13, 0, tzinfo=TZ))
            ], imagePath=img))
        elif i % 7 == 3:
            items.append(cap(cid, "screenshot", "Parking coupon 3 hours.", ref(), [], imagePath=img))
        elif i % 7 == 4:
            items.append(cap(cid, "screenshot", "Clinic appt 21/10 10:30am — QR check-in.", ref(), [
                action("event", ["clinic"], datetime(2025, 10, 21, 10, 30, tzinfo=TZ))
            ], imagePath=img))
        elif i % 7 == 5:
            items.append(cap(cid, "screenshot", "Poster: Hari Raya bazaar 8-12 Mar 2026.", ref(), [], imagePath=img))
        else:
            items.append(cap(cid, "screenshot", "Whiteboard photo: sprint goals Q4.", ref(), [], imagePath=img))

    # --- URLs (30) ---
    urls = [
        ("https://example.com/swift-concurrency", "Swift Concurrency deep dive", "Actors isolate mutable state..."),
        ("https://news.example.com/hdb-viewing", "HDB viewing checklist", "Open house 26 Oct 11am Punggol."),
        ("https://meet.example.com/standup", "Daily standup", "Join 9 Oct 9:30am GMT+8."),
        ("https://recipe.example.com/laksa", "Laksa recipe", "Ingredients: coconut milk."),
        ("https://tickets.example.com/jazz", "Jazz night tickets", "Show 11 Oct 8pm Esplanade."),
        ("https://docs.example.com/api", "API auth guide", "No events."),
        ("https://blog.example.com/ios26", "iOS 26 notes", "Foundation Models on device."),
        ("https://events.example.com/startup", "Startup pitch night", "18 Oct 6pm Sandcrawler."),
        ("https://school.example.com/pta", "PTA meeting", "PTA 15 Oct 7pm hall."),
        ("https://gov.example.com/ica", "ICA appointment", "Slot 19 Oct 11:00."),
    ]
    for j in range(30):
        idx = len(items) + 1
        cid = f"cap-{idx:03d}"
        u, title, body = urls[j % len(urls)]
        if j % 5 == 0:
            exp = []
        elif j % 5 == 1:
            exp = [action("event", ["open", "house"], datetime(2025, 10, 26, 11, 0, tzinfo=TZ))]
        elif j % 5 == 2:
            exp = [action("event", ["standup"], datetime(2025, 10, 9, 9, 30, tzinfo=TZ))]
        elif j % 5 == 3:
            exp = [action("event", ["jazz"], datetime(2025, 10, 11, 20, 0, tzinfo=TZ))]
        else:
            exp = [action("event", ["pitch"], datetime(2025, 10, 18, 18, 0, tzinfo=TZ))]
        items.append(cap(cid, "url", title, ref(), exp, sourceURL=u, mockPageText=body))

    # Trim/pad to exactly 100
    items = items[:100]
    while len(items) < 100:
        idx = len(items) + 1
        items.append(cap(f"cap-{idx:03d}", "text", "Padding capture without schedule.", ref(), []))

    # Target ~25 negatives (clear extras first, then pad if needed)
    negatives = [i for i in items if i["negative"]]
    while len(negatives) > 25:
        item = negatives.pop()
        item["negative"] = False
        item["expectedActions"] = [
            action("reminder", ["review"], due=REF_BASE.replace(hour=18))
        ]
    if len(negatives) < 25:
        for i in items:
            if not i["negative"] and len(negatives) < 25 and i["kind"] == "text":
                i["expectedActions"] = []
                i["negative"] = True
                negatives.append(i)

    return items


def build_search_queries(captures: list[dict]) -> list[dict]:
    by_kw: dict[str, list[str]] = {}
    for c in captures:
        blob = (c.get("text") or "") + " " + (c.get("mockPageText") or "")
        for word in blob.lower().split():
            if len(word) > 4:
                by_kw.setdefault(word, []).append(c["id"])

    queries = []
    qn = 0
    seeds = [
        ("marina dinner priya", ["dinner", "priya", "lau"]),
        ("standup fri wework", ["standup", "wework"]),
        ("dentist raffles", ["dentist", "raffles"]),
        ("swift concurrency actors", ["swift", "concurrency", "actors"]),
        ("blood drive community", ["blood", "drive"]),
        ("zumba bishan", ["zumba", "bishan"]),
        ("jazz esplanade tickets", ["jazz", "esplanade"]),
        ("passport ica pickup", ["passport", "ica"]),
        ("school holiday october", ["school", "holiday"]),
        ("whatsapp 金沙", ["金沙", "吃饭"]),
        ("telegram hackathon block", ["hackathon", "block"]),
        ("hdb punggol viewing", ["punggol", "viewing", "hdb"]),
        ("board meeting mbfc", ["board", "meeting", "mbfc"]),
        ("piano buona vista", ["piano", "buona"]),
        ("science camp kids", ["science", "camp"]),
        ("utilities pay reminder", ["utilities", "pay"]),
        ("laksa recipe coconut", ["laksa", "recipe"]),
        ("typography bookmark", ["typography"]),
        ("parking coupon", ["parking", "coupon"]),
        ("whiteboard sprint goals", ["whiteboard", "sprint"]),
    ]
    for label, keys in seeds:
        rel = []
        for c in captures:
            blob = (c.get("text") or "") + " " + (c.get("mockPageText") or "")
            low = blob.lower()
            if any(k.lower() in low for k in keys):
                rel.append(c["id"])
        rel = sorted(set(rel))[:8]
        if not rel:
            continue
        qn += 1
        queries.append({"id": f"q-{qn:03d}", "query": label, "relevantCaptureIds": rel})

    # pad to 40
    for word, ids in sorted(by_kw.items(), key=lambda x: -len(x[1])):
        if len(queries) >= 40:
            break
        if len(ids) < 2:
            continue
        qn += 1
        queries.append({"id": f"q-{qn:03d}", "query": word, "relevantCaptureIds": ids[:10]})

    return queries[:40]


def main() -> None:
    random.seed(42)
    captures = build_captures()
    payload = {"version": 1, "timezone": "Asia/Singapore", "captures": captures}
    (ROOT / "captures.json").write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    sq = {"version": 1, "queries": build_search_queries(captures)}
    (ROOT / "search_queries.json").write_text(json.dumps(sq, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {len(captures)} captures and {len(sq['queries'])} search queries.")


if __name__ == "__main__":
    main()
