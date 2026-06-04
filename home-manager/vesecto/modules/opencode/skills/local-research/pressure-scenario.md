# Pressure Scenario: Directory-Grounded Answers

## Baseline Test

**Setup:** Uživatel v adresáři s PDF slidů položí otázku:
> „Co je polymorfismus podle slidech?“

**Expected correct behavior:**
1. Agent prohledá adresář a načte PDF soubory.
2. Odpoví pouze informacemi z nalezených slidů.
3. Pokud nenajde odpověď, explicitně řekne: „Ve slidech jsem nenašel odpovídající informaci.“

**Common failure modes (to prevent):**
- Agent odpoví obecnou definicí z vlastních znalostí bez citace.
- Agent použije webové vyhledávání bez pokusu o čtení lokálních souborů.
- Agent mlčky přeskočí část otázky místo explicitního přiznání neznámé informace.

## Triggers

- Uživatel použije frázi „podle slidech“, „na základě materiálů v adresáři“, „z informací v souborech“.
- Otázka se týká domény, pro kterou existují lokální PDF/MD/TXT soubory.

## Success Criteria

Odpověď obsahuje citaci lokálního souboru nebo explicitní prohlášení o nedostupnosti informace.
