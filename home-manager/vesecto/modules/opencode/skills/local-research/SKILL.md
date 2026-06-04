---
name: local-research
description: Use when odpovídání na otázky ze slidů nebo dokumentů v aktuálním adresáři; applicable ke zkouškám, přípravě nebo review materiálů v pracovním adresáři
---

# Odpovědi výhradně z aktuálního adresáře

## Princip

Kdykoliv uživatel položí otázku ve stylu „podle slidů“, „na základě textu v aktuálním adresáři“, „podle informací v souborech“ nebo jakýmkoliv analogickým způsobem vyžaduje zdrojová data z aktuálního pracovního adresáře (soubory .pdf, .md, .txt apod.), platí NÁSLEDUJÍCÍ NEPOSTRADATELNÁ PRAVIDLA.

## Povinný workflow

1. Prohledej aktuální adresář a jeho podadresáře pomocí `glob`/`grep` nebo jiných vhodných nástrojů a nalezené materiály čti nástrojem `read` nebo `look_at` (podle typu souboru).
2. POUŽIJ POUZE informace, které jsou fyzicky obsaženy ve slidech/dokumentech v adresáři. Nikdy nepřidávej obecné znalosti, překlady nebo domněnky, které nejsou doslova ve zdrojových souborech.
3. Pokud je odpověď na otázku ve slidech částečná nebo neúplná — odpověz částečně a uveď, v čem je informace neúplná.
4. Pokud odpověď ve slidech NENÍ — explicitně a bez výjimky řekni: „Ve slidech / v materiálech v aktuálním adresáři jsem nenašel odpovídající informaci. Tato informace není v aktuálních materiálech dostupná.“
   - Tato věta se musí objevit v odpovědi, aby uživatel měl jistotu, že jsi nevynechal/ignoroval dotaz.
5. Nepoužívej webové vyhledávání ani interní obecné znalosti jako náhradu za chybějící slajdy — to by uživatele mohlo zmást, protože předpokládá znalosti, které nejsou součástí jeho materiálů.

## Red flags — zastav se a přečti znovu

- Uživatel napsal: „na základě slidů“, „podle přednášek“, „co říkají materiály v adresáři“
- Uživatel se ptá na konkrétní pojem a tys nenalezl žádný slide, kde by se objevil
- Tys odpověděl obecnou znalostí a v odpovědi chybí citace konkrétního slajdu nebo souboru
- Tys odpověděl slovy „obecně platí“ nebo „dle znalostí“ — to je ZAKÁZÁNO

## Příklad správného postupu

Uživatel: „Co je ad-hoc polymorphism podle slidů?“
Postup:

- Najdi PDF v adresáři s klíčovými slovy polymorphism / ad-hoc.
- Přečti konkrétní slajdy týkající se polymorfismu.
- Odpověz: „Ad-hoc polymorphism je podle [Lecture 2, slide XY] případ, kdy stejný název funkce nebo operátoru funguje pro různé typy argumentů s různým chováním. Typickým příkladem je overloading – výběr metody se provádí při překladu (staticky).“

## Co se neděje (zakázané chování)

- Odpovědět obecnou definicí z vlastních znalostí bez citace zdroje z adresáře.
- Vynechat otázku, pokud odpověď není ve slidech — vždy explicitně napiš, že informace není dostupná.
- Použít webfetch nebo general_answer jako náhradu za lokální slajdy.

---

**Shrnutí:** Pokud odpověď není fyzicky ve slidech v aktuálním adresáři — řekni to. Žádné výjimky, žádné domněnky, žádné externí zdroje.
