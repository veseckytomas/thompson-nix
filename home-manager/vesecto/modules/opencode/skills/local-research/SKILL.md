---
name: local-research
description: Use when answering questions or synthesizing notes from files in the current directory (plus any sources whitelisted in SOURCES.txt), with strict rules against unsanctioned external knowledge and mandatory citation of every source.
---

# Local-Research: Directory-Grounded Answers

## Overview

Every claim must be traceable to a file in the current directory — or to a source explicitly listed in `SOURCES.txt`. If the information is not there, say so. No exceptions, no silent web searches, no "general knowledge" filler.

## When to Use

- Trigger: "podle přednášek" / "according to the lectures" / "based on the files"
- Trigger: User asks about course materials, exam prep, or directory contents
- Trigger: Note creation or summarization from local documents
- Do NOT use: When user explicitly asks for general knowledge or web searches

## Mandatory Workflow

1. **Check** for `SOURCES.txt` in the current directory. If present, every line is a pre-approved source (see **Pre-Approved Sources: SOURCES.txt** below).
2. **Search** current directory recursively (`glob`, `grep`).
3. **Read** files (`read`, `look_at`; PDF fallback: `pdftotext`, `strings`). You may also read/fetch any source listed in `SOURCES.txt`.
4. **Cite** every claim with filename/URL and page/section.
5. **Synthesize** ONLY from content you actually extracted (current-directory files + sources read from `SOURCES.txt`).
6. **Handle gaps:**
   - Missing → state explicitly (see bilingual templates).
   - Incomplete → state what was found and what is missing.
7. **Other external sources** (anything NOT in `SOURCES.txt`) → ONLY with explicit user permission. You may propose them, but you must NOT search until the user says yes.

**Explicit permission required:** "yes", "sure", "go ahead", "you may use...". Vague encouragement is NOT permission.

## Pre-Approved Sources: SOURCES.txt

If — and ONLY if — a file named `SOURCES.txt` exists in the current directory, treat each non-empty line as ONE **pre-approved source** you may use WITHOUT asking permission:

- A line is either an **external local path** (resolved relative to the current directory, e.g. `../shared/notes.md`) or a **web URL** (e.g. `https://example.com/page`).
- **No permission prompt** — being listed IS the permission. Read the local path or `webfetch` the URL directly.
- **Citation still mandatory.** Cite the exact listed source you used (path/URL + section/page), exactly as for local files.
- **Access, not memory.** A listing authorizes you to OPEN that source — never to answer from general knowledge about its topic. Actually read/fetch it, then cite it.
- **Exact listings only.** Sources not listed — and topics merely "related" to a listing — still require explicit user permission.
- A listed **directory** covers files inside it; a listed **file or URL** covers only that file or page.

**No `SOURCES.txt`, or it is empty/unreadable → the strict directory-only rules above apply unchanged.**

## Bilingual Response Templates

| Situation         | English                                                                              | Czech                                                                   |
| ----------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| Missing info      | "The required information is not present in the current directory materials."        | "Požadovaná informace se v materiálech v aktuálním adresáři nenachází." |
| Incomplete info   | "The materials in [file] mention [topic] but do not provide a complete explanation." | "Materiály v [soubor] zmiňují [téma], ale neobsahují úplné vysvětlení." |
| Source suggestion | "The current materials do not cover this. Shall I check [source]?"                   | "Aktuální materiály toto neobsahují. Mám vyhledat ve [zdroj]?"          |

## Rationalization Table

| Excuse                              | Reality                                           |
| ----------------------------------- | ------------------------------------------------- |
| "I already know this."              | External knowledge without citation is forbidden. |
| "The files are incomplete."         | State it is incomplete. Do not supplement.        |
| "The user wants a complete answer." | Completeness without citation is misinformation.  |
| "It's faster to search the web."    | Speed does not override the source rule.          |
| "`SOURCES.txt` lists a site on this topic, so I know the answer." | Listing grants ACCESS, not memory. Open the source and cite it. |
| "This source is basically the same as a listed one." | Only exact listings are pre-approved. Otherwise ask permission. |

## Red Flags — STOP and Start Over

- Answering from memory without reading files
- "Generally speaking," "it is known that," "in practice"
- Using `webfetch`/`websearch` on anything NOT listed in `SOURCES.txt` (listed URLs are allowed); using `general_answer`
- Adding information "for context"

## PDF Handling

`look_at` may time out on large PDFs. Fall back to:

1. `pdftotext <file> - | head -n 50`
2. `pdfgrep <term> <file>`
3. `strings <file> | grep <term>`
4. If all fail: "I was unable to read [file] due to PDF extraction limitations."
