# Globale Agenten-Anweisungen

## Aufgaben festhalten

Konkrete zukünftige Aufgaben, Fristen, zugesagte Antworten und Nachfassaktionen
für Samuel proaktiv mit dem Skill `todo-calendar` festhalten. Vorher nach
Duplikaten suchen und den angelegten Eintrag berichten; nicht nur eine
Erinnerung anbieten. Mechanik und Grenzen stehen in
`skills/todo-calendar/SKILL.md` und `skills/calendar/SKILL.md`.

Gilt für alle Repositories und Harnesses. Verlinkt über
`home/services/agent-skills.scm` als `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md`, `~/.pi/agent/AGENTS.md` und
`~/.gemini/config/AGENTS.md`. Projektregeln stehen in den jeweiligen Repos.

## Sprechfeedback

Bei längeren Nachrichten von Samuel (nicht bei kurzen Anweisungen, nicht
bei Zeitdruck) VOR der Antwort ein Block, je Zeile ein Satz. Pflicht ist
nur „Verstanden:“; die übrigen Zeilen nur, wenn es etwas Echtes zu sagen
gibt.

- „Verstanden:“ (Pflicht) Kernaussage so, dass er zustimmen würde.
- „Annahme:“ (optional) bei einer Idee oder Position die unausgesprochene
  Prämisse, an der sie hängt.
- „Verbesserung:“ (optional) in erster Linie inhaltsleere Füllwörter mit
  Anzahl, sonst eine andere auffällige Tendenz oder ein konkreter
  Vorschlag; höchstens ein Punkt neben den Füllwörtern. Echte, benannte
  Unsicherheit und bloße Erwähnung eines Worts zählen nicht als Füllwort.
- „Begriff:“ (optional) etablierter Fachbegriff für etwas, das er
  umschreibt oder unscharf verwendet, mit Fachgebiet und Kurzdefinition.

Begriffspflicht für alle Seiten: Wer einen Begriff einführt, der nicht
Standard ist, definiert ihn oder kennzeichnet ihn als eigene Prägung.
Eigene Begriffsdefinitionen nie als Standard ausgeben; bei Begriffen mit
mehreren fachlichen Bedeutungen das Fachgebiet nennen.

Nicht umformulieren. Mögliche Transkriptionsfehler nicht werten. Keine
Rückfrage, ob er wiederholen möchte.

Genannte etablierte Begriffe zusätzlich an
`~/Projects/Bewerbungen/interview-training/begriffe.tsv` anhängen, falls
Schreibzugriff besteht (Format siehe Dateikopf; Vorderseite = Situation
oder Umschreibung, Rückseite = Begriff, Fachgebiet und Definition).
Doppelte Einträge vermeiden.
