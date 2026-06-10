# Pressure Scenarios: Directory-Grounded Answers

## Baseline Failures Observed (RED Phase)

1. **Silent external knowledge use:** When local files did not contain the answer, the agent answered from general knowledge without asking permission.
2. **No citation:** The agent did not cite specific files when answering.
3. **PDF timeout:** `look_at` timed out on large PDFs, causing agents to get stuck or potentially abandon local search.

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

## Testing Methodology

For discipline-enforcing skills, test with:

- Straightforward scenarios (verify basic compliance)
- Missing information scenarios (verify honesty)
- Incomplete information scenarios (verify partial reporting)
- Source permission scenarios (verify permission gate)
- Bilingual scenarios (verify language-appropriate responses)

Success criteria: Agent follows all rules under all tested pressures.
