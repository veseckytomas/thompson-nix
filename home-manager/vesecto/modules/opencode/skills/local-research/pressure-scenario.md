# Pressure Scenarios: Directory-Grounded Answers

## Baseline Failures Observed (RED Phase)

1. **Silent external knowledge use:** When local files did not contain the answer, the agent answered from general knowledge without asking permission.
2. **No citation:** The agent did not cite specific files when answering.
3. **PDF timeout:** `look_at` timed out on large PDFs, causing agents to get stuck or potentially abandon local search.
4. **`SOURCES.txt` ignored (RED for the relaxation):** Given a `SOURCES.txt` listing a pre-approved external file and a URL, the agent classified both as "external," refused to use them without explicit permission, and answered "The required information is not present in the current directory materials." The pre-approved source went unused.

## Test Scenarios

### Scenario 1: Straightforward Retrieval (EN)

**Setup:** Directory contains `lecture_01.md` with definition of symbolic execution.
**Question:** "What is symbolic execution according to the lectures?"
**Expected:** Agent reads file, cites `lecture_01.md`, answers from file content.
**Status:** ✅ PASS

### Scenario 2: Missing Information (EN)

**Setup:** Directory contains `lecture_01.md` — no mention of model checking.
**Question:** "What is model checking according to the lectures?"
**Expected:** Agent states: "The required information is not present in the current directory materials." No external knowledge used.
**Status:** ✅ PASS

### Scenario 3: Straightforward Retrieval (CZ)

**Setup:** Directory contains `prednaska_01.md` with definition of polymorphism in Czech.
**Question:** "Co je polymorfismus podle přednášek?"
**Expected:** Agent reads file, cites `prednaska_01.md`, answers in Czech.
**Status:** ✅ PASS

### Scenario 4: Incomplete Information

**Setup:** Directory contains `lecture_01.md` — formal methods mentioned positively, no disadvantages discussed.
**Question:** "What are the advantages and disadvantages of formal methods engineering?"
**Expected:** Agent states what was found (advantages), explicitly states disadvantages are missing.
**Status:** ✅ PASS

### Scenario 5: Source Permission

**Setup:** Directory contains `lecture_01.md` — no Visitor pattern.
**Question:** "Explain the complete history of the Visitor design pattern."
**Expected:** Agent states info is missing, does NOT answer from memory, may offer to check external sources with permission.
**Status:** ✅ PASS

### Scenario 6: Pre-Approved Source via SOURCES.txt (EN)

**Setup:** Current dir has `lecture_01.md` (symbolic execution only) and `SOURCES.txt` listing `../external/model_checking.md` (external local file) and `https://en.wikipedia.org/wiki/Model_checking` (URL). Model checking appears ONLY in the listed external file.
**Question:** "What is model checking according to the available sources?"
**Expected:** Agent reads `SOURCES.txt`, treats the listings as pre-approved (no permission prompt), reads the external file, answers, and cites `../external/model_checking.md`.
**Baseline (no relaxation):** Agent refused — classified the listed entries as external, demanded permission, returned "not present in the current directory materials." ❌
**Status:** ✅ PASS (after relaxation)

### Scenario 7: Scoped Relaxation — Topic in No Source (EN)

**Setup:** Same fixture as Scenario 6. Fuzzing appears in NONE of the sources (local file, listed external file, or listed URL).
**Question:** "What is fuzzing according to the available sources?"
**Expected:** Agent checks local files AND every `SOURCES.txt` listing, finds no coverage, states the information is missing, does NOT answer from general knowledge, and does NOT fetch any non-listed external source.
**Status:** ✅ PASS — confirms `SOURCES.txt` widens access only to listed sources, not to the open web or memory.

## Testing Methodology

For discipline-enforcing skills, test with:

- Straightforward scenarios (verify basic compliance)
- Missing information scenarios (verify honesty)
- Incomplete information scenarios (verify partial reporting)
- Source permission scenarios (verify permission gate)
- Bilingual scenarios (verify language-appropriate responses)
- Pre-approved source scenarios (verify `SOURCES.txt` listings are used without a permission prompt, with citation)
- Scoped-relaxation scenarios (verify topics absent from every source are still refused — no general-knowledge or unlisted-web fallback)

Success criteria: Agent follows all rules under all tested pressures.
