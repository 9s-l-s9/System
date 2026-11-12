---
name: todo-calendar
description: >
  Record concrete tasks, deadlines, promised replies and follow-ups for Samuel
  in his calendar when they arise in a conversation, mail, meeting or transcript,
  without waiting for a separate reminder request. Applies to actual pending
  commitments, not examples, historical mentions or the agent's implementation steps.
---

# To-dos in the calendar

Samuel wants concrete future obligations recorded, not merely offered as
reminders. Use the existing [calendar skill](../calendar/SKILL.md) for all
notyet commands, event types, synchronization and invitation rules.

1. Identify who must do what, by when, and the source. Record Samuel's action
   when it depends on someone else (for example, obtain a signature). If the
   task or date is ambiguous, ask for the missing fact; do not invent a deadline.
2. Search by subject and date before creating anything. Inspect a possible
   match and keep it when it already covers the obligation.
3. Use **Frist** for a hard deadline, all-day when no time was specified.
   Use **Nachhaken** for a promised reply or follow-up. Preserve source times;
   when only its day is known, use 09:00 in the configured calendar timezone
   and explicitly report that chosen reminder time. Undated tasks need a date
   before they can be entered.
4. Put the context in `--desc`: mail Message-ID, file path, meeting name or
   conversation context, plus the action and responsible person.
5. Report the actual line returned by notyet. If creation or synchronization
   fails, say what was saved locally and what remains unresolved; never claim
   a reminder exists based only on an intention to create it.

This standing instruction authorizes creating these reminders. It does not
authorize moving or deleting existing events, changing invitations, accepting
commitments on Samuel's behalf, or contacting third parties. Those require
the corresponding user request. Do not create real events while testing a skill.
