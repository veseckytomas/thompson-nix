#!/usr/bin/env bash
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
set -euo pipefail

verifier="${1:-$(dirname "$0")/verify-omniroute-resilience-readers.py}"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/package/open-sse/services/combo" "$fixture/package/src/sse/services" "$fixture/package/open-sse/services"
cat >"$fixture/resilience-defaults.sh" <<'EOF'
desired='{
  "comboCooldownWait": {"enabled": true, "maxWaitMs": 15000, "maxAttempts": 2, "budgetMs": 30000},
  "waitForCooldown": {"enabled": false, "maxRetries": 10, "maxRetryWaitSec": 300, "budgetMs": 300000},
  "providerBreaker": {
    "oauth": {"failureThreshold": 24, "degradationThreshold": 12, "resetTimeoutMs": 15000},
    "apikey": {"failureThreshold": 4, "degradationThreshold": 2, "resetTimeoutMs": 60000}
  }
}'
EOF
cat >"$fixture/package/open-sse/services/combo/comboSetup.ts" <<'EOF'
function phaseComboSetup(ctx: ComboContext): ComboSetup {
  const { settings } = ctx;
  const resilienceSettings = settings ? resolveResilienceSettings(settings) : resolveResilienceSettings(null);
  return { strategy, resilienceSettings, config };
}
EOF
cat >"$fixture/package/open-sse/services/combo.ts" <<'EOF'
async function handleComboChatInner(options: Options): Promise<Response> {
  const { strategy, resilienceSettings, config } = phaseComboSetup(comboCtx);
  const comboCooldownBudgetLeftMs = { current: resilienceSettings.comboCooldownWait.budgetMs };
  const deps: AttemptLoopDeps = { strategy, resilienceSettings, config };
  return dispatchWithCooldownRetry({ state, deps, extra });
}
EOF
cat >"$fixture/package/open-sse/services/combo/comboAttemptLoop.ts" <<'EOF'
async function dispatchWithCooldownRetry(opts: Options): Promise<Response> {
  const { state, deps, extra } = opts;
  return resolveComboCooldownWaitDecision({
    targets: state.orderedTargets, earliestRetryAfter: state.earliestRetryAfter,
    attempt: extra.comboCooldownAttempt.current,
    budgetLeftMs: extra.comboCooldownBudgetLeftMs.current,
    settings: deps.resilienceSettings.comboCooldownWait,
    lookupLock, computeWaitMs,
  });
}
EOF
cat >"$fixture/package/open-sse/services/combo/comboCooldownRetry.ts" <<'EOF'
function resolveComboCooldownWaitDecision(input: Input): Result {
  const { targets, earliestRetryAfter, attempt, budgetLeftMs, settings, lookupLock, computeWaitMs, } = input;
  const decision = shouldWaitForComboCooldown({ reason: best.reason, waitMs, attempt, budgetLeftMs, settings, });
  return decision;
}
function shouldWaitForComboCooldown(input: Input): Result {
  const { reason, attempt, budgetLeftMs, settings } = input;
  const wait = settings.enabled === true && waitMs <= settings.maxWaitMs && attempt < settings.maxAttempts && budgetLeftMs >= waitMs;
  return { wait, waitMs };
}
EOF
cat >"$fixture/package/src/sse/services/cooldownAwareRetry.ts" <<'EOF'
function resolveCooldownAwareRetrySettings(settings: Settings): Result {
  const waitForCooldown = resolveResilienceSettings(settings).waitForCooldown;
  const maxRetries = normalizeInteger(waitForCooldown.maxRetries, 10);
  const maxRetryWaitSec = normalizeInteger(waitForCooldown.maxRetryWaitSec, 300);
  const budgetMs = normalizeInteger(waitForCooldown.budgetMs, 300000);
  const enabled = Boolean(waitForCooldown.enabled) && maxRetries > 0;
  return { enabled, maxRetries, maxRetryWaitSec, budgetMs };
}
EOF
cat >"$fixture/package/open-sse/services/accountFallback.ts" <<'EOF'
function buildProviderProfile(category: "oauth" | "apikey", settings: Settings) {
  const resilience = settings ? resolveResilienceSettings(settings) : DEFAULT_RESILIENCE_SETTINGS;
  const providerBreaker = resilience.providerBreaker[category];
  return {
    baseCooldownMs: 0,
    failureThreshold: providerBreaker.failureThreshold,
    degradationThreshold: providerBreaker.degradationThreshold,
    resetTimeoutMs: providerBreaker.resetTimeoutMs,
    maxBackoffSteps: 0,
  } satisfies ProviderProfile;
}
EOF

python3 "$verifier" --package-root "$fixture/package" --resilience-script "$fixture/resilience-defaults.sh" --version fixture

python3 - "$verifier" "$fixture" <<'PY'
import subprocess
import sys
from pathlib import Path

verifier, root_arg = sys.argv[1:]
root = Path(root_arg)
sources = tuple((root / "package").rglob("*.ts"))
originals = {path: path.read_text() for path in sources}
failures = []
for case in ("comments", "line-comments", "strings", "quoted-strings",
             "unbound-combo", "unrelated-object", "missing-binding", "declarations",
             "cross-scope", "shadowed-binding", "missing-budget", "missing-combo-argument",
             "quoted-binding", "regex", "template-braces"):
    for path, source in originals.items():
        match case:
            case "comments":
                decoy = "/*\n" + source + "\n*/\n"
            case "line-comments":
                decoy = "\n".join("// " + line for line in source.splitlines())
            case "strings":
                decoy = "const documentation = `" + source + "`;\n"
            case "quoted-strings":
                decoy = "const documentation = " + repr(source) + ";\n"
            case "quoted-binding":
                decoy = source.replace("  const waitForCooldown = resolveResilienceSettings(settings).waitForCooldown;",
                                       "  const doc = 'const waitForCooldown = resolveResilienceSettings(settings).waitForCooldown;';")
            case "regex":
                decoy = "const documentation = /" + source.replace("\n", " ") + "/;"
            case "template-braces":
                decoy = "const documentation = `unmatched { // prose\n" + source + "`;"
            case "unbound-combo":
                decoy = source.replace("const { reason, attempt, budgetLeftMs, settings } = input;",
                                       "const settings = unrelated;")
            case "unrelated-object":
                decoy = source.replace("resolveResilienceSettings(settings).waitForCooldown", "unrelated.waitForCooldown").replace("resilience.providerBreaker[category]", "unrelated.providerBreaker[category]")
            case "missing-binding":
                decoy = source.replace("const waitForCooldown = resolveResilienceSettings(settings).waitForCooldown;", "")
            case "declarations":
                decoy = "interface Defaults { enabled: true; maxRetries: 10; budgetMs: 300000; }"
            case "cross-scope":
                decoy = source.replace("  const maxRetries =", "}\nfunction unrelated(waitForCooldown: Settings) {\n  const maxRetries =")
            case "shadowed-binding":
                decoy = source.replace("  const maxRetries =", "  { const waitForCooldown = unrelated;\n  const maxRetries =").replace("  return { enabled, maxRetries, maxRetryWaitSec, budgetMs };", "  return { enabled, maxRetries, maxRetryWaitSec, budgetMs }; }")
            case "missing-budget":
                decoy = source.replace("resilienceSettings.comboCooldownWait.budgetMs", "30000")
            case "missing-combo-argument":
                decoy = source.replace("settings: deps.resilienceSettings.comboCooldownWait", "settings: unrelated")
            case _:
                raise AssertionError(case)
        path.write_text(decoy)
    result = subprocess.run(
        [sys.executable, verifier, "--package-root", str(root / "package"),
         "--resilience-script", str(root / "resilience-defaults.sh"), "--version", case],
        capture_output=True, text=True, check=False,
    )
    if result.returncode == 0:
        failures.append(case)
        print(f"FAIL: accepted {case}: {result.stdout.strip()}")
    else:
        print(f"PASS: rejected {case}")
for path, source in originals.items():
    path.write_text(source)
for access, leaf in (
    ("settings.enabled", "comboCooldownWait.enabled"),
    ("settings.maxWaitMs", "comboCooldownWait.maxWaitMs"),
    ("settings.maxAttempts", "comboCooldownWait.maxAttempts"),
    ("resilienceSettings.comboCooldownWait.budgetMs", "comboCooldownWait.budgetMs"),
    ("waitForCooldown.enabled", "waitForCooldown.enabled"),
    ("waitForCooldown.maxRetries", "waitForCooldown.maxRetries"),
    ("waitForCooldown.maxRetryWaitSec", "waitForCooldown.maxRetryWaitSec"),
    ("waitForCooldown.budgetMs", "waitForCooldown.budgetMs"),
    ("providerBreaker.failureThreshold", "providerBreaker.oauth.failureThreshold"),
    ("providerBreaker.degradationThreshold", "providerBreaker.oauth.degradationThreshold"),
    ("providerBreaker.resetTimeoutMs", "providerBreaker.oauth.resetTimeoutMs"),
):
    for path, source in originals.items():
        path.write_text(source.replace(access, "unrelated.value"))
    result = subprocess.run(
        [sys.executable, verifier, "--package-root", str(root / "package"),
         "--resilience-script", str(root / "resilience-defaults.sh"), "--version", leaf],
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 1 and leaf in result.stderr, (leaf, result.stdout, result.stderr)
    if leaf.startswith("providerBreaker."):
        assert leaf.replace(".oauth.", ".apikey.") in result.stderr
    print(f"PASS: missing read rejected for {leaf}")
for path, source in originals.items():
    path.write_text(source)
assert not failures, f"false runtime readers accepted: {failures}"
PY

mv "$fixture/package/open-sse/services/accountFallback.ts" "$fixture/accountFallback.ts"
if python3 "$verifier" --package-root "$fixture/package" --resilience-script "$fixture/resilience-defaults.sh" --version readerless; then
  printf 'FAIL: readerless seeded key passed\n' >&2
  exit 1
fi
printf 'PASS: readerless seeded key fails\n'

mv "$fixture/accountFallback.ts" "$fixture/package/open-sse/services/accountFallback.ts"
python3 - "$fixture/resilience-defaults.sh" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
path.write_text(path.read_text().replace('"enabled": true,', '"enabled": true, "futureKey": 1,'))
PY
if python3 "$verifier" --package-root "$fixture/package" --resilience-script "$fixture/resilience-defaults.sh" --version unknown; then
  printf 'FAIL: unknown seeded key passed\n' >&2
  exit 1
fi
printf 'PASS: unknown seeded key fails\n'

repo_root="$(GIT_MASTER=1 git -C "$(dirname "$0")" rev-parse --show-toplevel)"
python3 - "$repo_root/modules/common/packages/nixos-run/nixos-run.sh" "$repo_root/modules/common/packages/nixos-run/default.nix" <<'PY'
import sys
from pathlib import Path

update_script = Path(sys.argv[1]).read_text()
package = Path(sys.argv[2]).read_text()
update = update_script.index('run bash "@updateOpencodeNpmPluginsScript@"')
verify = update_script.index("verify_omniroute_resilience_readers", update)
flake = update_script.index('hdr "Updating LibreWolf ..."', update)
assert update < verify < flake
assert "@verifyOmnirouteResilienceReadersScript@" in package
assert "nodejs" in package
assert "gnutar" in package
PY
printf 'PASS: update preflight is wired before later update/build work\n'
