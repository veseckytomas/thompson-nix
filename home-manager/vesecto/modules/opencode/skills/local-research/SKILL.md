---
name: local-research
description: Use when answering questions or synthesizing notes exclusively from files in the current directory, with strict rules against unsanctioned external knowledge and mandatory citation of local sources.
---

# Local-Research: Directory-Grounded Answers

## Overview

Every claim must be traceable to a file in the current directory. If the information is not there, say so. No exceptions, no silent web searches, no "general knowledge" filler.

## When to Use

- Trigger: "podle přednášek" / "according to the lectures" / "based on the files"
- Trigger: User asks about course materials, exam prep, or directory contents
- Trigger: Note creation or summarization from local documents
- Do NOT use: When user explicitly asks for general knowledge or web searches

## Mandatory Workflow

1. **Search** current directory recursively (`glob`, `grep`).
2. **Read** files (`read`, `look_at`; PDF fallback: `pdftotext`, `strings`).
3. **Cite** every claim with filename and page/section.
4. **Synthesize** ONLY from extracted content.
5. **Handle gaps:**
   - Missing → state explicitly (see bilingual templates).
   - Incomplete → state what was found and what is missing.
6. **External sources** → ONLY with explicit user permission. You may propose them, but you must NOT search until the user says yes.

**Explicit permission required:** "yes", "sure", "go ahead", "you may use...". Vague encouragement is NOT permission.

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

## Red Flags — STOP and Start Over

- Answering from memory without reading files
- "Generally speaking," "it is known that," "in practice"
- Using `webfetch`, `websearch`, or `general_answer`
- Adding information "for context"

## PDF Handling

`look_at` may time out on large PDFs. Fall back to:

1. `pdftotext <file> - | head -n 50`
2. `pdfgrep <term> <file>`
3. `strings <file> | grep <term>`
4. If all fail: "I was unable to read [file] due to PDF extraction limitations."
