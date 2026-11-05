---
name: calendar
description: >
  Read and change the user's Mailfence calendar with notyet (notmuch-style
  search, no IDs): agenda, find events, add interviews/deadlines/focus blocks,
  move or tag events, follow-up reminders that arrive as e-mail. Use when the
  user says "Kalender", "Termin", "agenda", "was steht an", "trag ein",
  "verschieb", "erinnere mich in N Tagen", or when a mail contains a date that
  belongs in the calendar.
---

# Calendar

The Mailfence calendar is mirrored to `~/Calendar/mailfence/events` (one
`.ics` per event) by vdirsyncer, both ways, every five minutes. **notyet**
(`~/Projects/notyet`, on PATH as `notyet`) searches and edits that mirror and
syncs to the server right after every change. Setup: `home/services/calendar.scm`.

## Reading

```
notyet agenda            # next 7 days;  notyet agenda 14
notyet search acme date:2026-11         # one line per occurrence
notyet show ref:2026-11-06/bewerbung     # all details incl. description
notyet search tag:Frist date:future --format json
```

Each line ends with `[DATE/slug]`, a readable reference; use it as
`ref:DATE/slug` (prefix is enough) in the next command. Never use UIDs or
file names.

Terms (AND by default; `or`, `not`, `-x`, parentheses): words (case and
umlauts ignored), `title:` `loc:` `desc:` `with:` `organizer:` `tag:`
`type:`, `date:today` `date:2026-11` `date:mo..fr` `date:today..+7d`
`date:this-week` `date:past`, `is:allday` `is:invite` `is:recurring`
`has:reminder`. Full list: `notyet help`.

Without notyet: `~/Calendar/text/agenda.txt` (next 60 days) and
`~/Calendar/text/<YYYY>/<date>_<time>_<slug>.txt` (one file per event, same
fields as `notyet show`), rebuilt after every sync — fine for `rg`.

## Types

`notyet types` lists them: **Gespräch** (interview/call, reminder 1 day
before), **Frist** (deadline, all-day, reminder 2 days before), **Fokus**
(work block, 2 h), **Uni** (thesis/supervisor), **Nachhaken** (follow-up,
e-mail reminder at the time), **Privat**. Always give `--type`; the type is
stored as a Mailfence tag and picks the colour.

## Changing

Only when the user asked for it, or as part of a task they gave (e.g. "trag
die Interviews aus den Mails ein"). Report every change with the line notyet
prints.

```
notyet new "Globex: Videointerview (Alex M.)" --type Gespräch --start "2026-11-12 14:00" --for 45m --location Teams --desc "Link: Mail vom 29.10., Message-ID <...>"
notyet new "Frist Initech Online-Test" --type Frist --start 2026-11-12
notyet new "Nachhaken: Antwort Acme?" --type Nachhaken --start "+5d 9:00" --desc "Message-ID <...>"
notyet edit acme date:fr --start 10:00 --for 90m     # also --shift +1d, --title, --tag/--untag
notyet tag +Bewerbung -- globex date:2026-11
notyet rm ref:2026-11-06/bewerbung-acme               # dry run; add --confirm
```

Rules:

1. **Times come from the source** (the mail's `Calendar-DTSTART` or text),
   never estimated. Unknown time → ask, or make it all-day and say so.
2. **Search first** (`notyet search … date:…`) so you don't add a duplicate;
   invitations accepted in Mailfence are already there.
3. **Invitations from others are read-only** (`is:invite`). Don't `--force`
   edits or deletes; tell the user to change them in Mailfence. Tagging
   them is fine.
4. **Deleting** needs the user's explicit request for that event; run the
   dry run, show it, then `--confirm`.
5. `edit` and `rm` refuse when the search matches several events: narrow
   with `date:` or `ref:`, never loop over candidates.
6. Put the mail's `Message-ID` into `--desc` when an event comes from a
   mail, so the source can be found again (see the mail skill).
7. Follow-up instead of "remind me in N days": a **Nachhaken** event; Mailfence
   sends the reminder e-mail at that time.

## Colours

CalDAV cannot set Mailfence colours, so notyet keeps a pool of coloured
placeholders (`notyet-pool: TYPE`, on 2000-01-01, hidden from searches).
`notyet new --type X` turns one into the new event and says how many are
left. When it reports none left, tell the user: `notyet pool` shows the
counts; `notyet pool add Fokus 5` creates placeholders, which the user then
colours once in the web calendar (open, Farbe, Speichern). Without a
placeholder the event still works, it just shows the default colour.

## Sync

Timer `calendar-sync` (vdirsyncer, then `notyet export`). `herd trigger
calendar-sync` syncs now; `notyet sync` does the same in the foreground.
notyet syncs after each change itself; if that sync fails it says so, the
change stays local and goes out with the next timer run.
