#!/usr/bin/env python3
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
"""Verify seeded OmniRoute resilience leaves have runtime readers."""

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Final


@dataclass(frozen=True, slots=True)
class Proof:
    source: str
    function: str
    steps: tuple[str, ...]


COMBO: Final = "open-sse/services/combo/"
COMBO_FLOW: Final = (
    Proof(
        COMBO + "comboSetup.ts",
        "phaseComboSetup",
        (
            "const resilienceSettings = settings ? resolveResilienceSettings(settings) : resolveResilienceSettings(null);",
            "return { @ resilienceSettings, @ };",
        ),
    ),
    Proof(
        "open-sse/services/combo.ts",
        "handleComboChatInner",
        (
            "const { @ resilienceSettings, @ } = phaseComboSetup(comboCtx);",
            "const deps: AttemptLoopDeps = { @ resilienceSettings, @ };",
            "dispatchWithCooldownRetry({ state, deps, extra })",
        ),
    ),
    Proof(
        COMBO + "comboAttemptLoop.ts",
        "dispatchWithCooldownRetry",
        (
            "const { state, deps, extra } = opts;",
            "resolveComboCooldownWaitDecision({ targets: state.orderedTargets, earliestRetryAfter: state.earliestRetryAfter, attempt: extra.comboCooldownAttempt.current, budgetLeftMs: extra.comboCooldownBudgetLeftMs.current, settings: deps.resilienceSettings.comboCooldownWait,",
        ),
    ),
    Proof(
        COMBO + "comboCooldownRetry.ts",
        "resolveComboCooldownWaitDecision",
        (
            "const { targets, earliestRetryAfter, attempt, budgetLeftMs, settings, lookupLock, computeWaitMs, } = input;",
            "const decision = shouldWaitForComboCooldown({ reason: best.reason, waitMs, attempt, budgetLeftMs, settings, });",
        ),
    ),
)
CONTRACTS: Final[dict[str, tuple[Proof, ...]]] = {
    **{
        f"comboCooldownWait.{leaf}": COMBO_FLOW
        + (
            Proof(
                COMBO + "comboCooldownRetry.ts",
                "shouldWaitForComboCooldown",
                (
                    "const { reason, attempt, budgetLeftMs, settings } = input;",
                    expression,
                ),
            ),
        )
        for leaf, expression in (
            ("enabled", "settings.enabled === true &&"),
            ("maxWaitMs", "waitMs <= settings.maxWaitMs &&"),
            ("maxAttempts", "attempt < settings.maxAttempts &&"),
        )
    },
    "comboCooldownWait.budgetMs": (
        COMBO_FLOW[0],
        Proof(
            "open-sse/services/combo.ts",
            "handleComboChatInner",
            (
                "const { @ resilienceSettings, @ } = phaseComboSetup(comboCtx);",
                "const comboCooldownBudgetLeftMs = { current: resilienceSettings.comboCooldownWait.budgetMs };",
            ),
        ),
    ),
    **{
        f"waitForCooldown.{leaf}": (
            Proof(
                "src/sse/services/cooldownAwareRetry.ts",
                "resolveCooldownAwareRetrySettings",
                (
                    "const waitForCooldown = resolveResilienceSettings(settings).waitForCooldown;",
                    expression,
                ),
            ),
        )
        for leaf, expression in (
            ("enabled", "const enabled = Boolean(waitForCooldown.enabled) &&"),
            (
                "maxRetries",
                "const maxRetries = normalizeInteger(waitForCooldown.maxRetries,",
            ),
            (
                "maxRetryWaitSec",
                "const maxRetryWaitSec = normalizeInteger(waitForCooldown.maxRetryWaitSec,",
            ),
            ("budgetMs", "const budgetMs = normalizeInteger(waitForCooldown.budgetMs,"),
        )
    },
    **{
        f"providerBreaker.{category}.{leaf}": (
            Proof(
                "open-sse/services/accountFallback.ts",
                "buildProviderProfile",
                (
                    "const resilience = settings ? resolveResilienceSettings(settings) : DEFAULT_RESILIENCE_SETTINGS;",
                    "const providerBreaker = resilience.providerBreaker[category];",
                    f"return {{ @ {leaf}: providerBreaker.{leaf}, @ }} satisfies ProviderProfile;",
                ),
            ),
        )
        for category in ("oauth", "apikey")
        for leaf in ("failureThreshold", "degradationThreshold", "resetTimeoutMs")
    },
}


def fail(message: str) -> None:
    print(f"omniroute-resilience-readers: FAIL {message}", file=sys.stderr)
    raise SystemExit(1)


# Templates, including interpolations, are opaque; slash literals are conservatively masked.
LEXEME: Final = re.compile(
    r"\s+|//[^\n]*|/\*[\s\S]*?\*/|/(?:\\.|\[(?:\\.|[^\]\\])*\]|[^/\\\n])+/[a-z]*|"
    r"[A-Za-z_$][\w$]*|\d+|===|!==|=>|&&|\|\||\?\?|<=|>=|\?\.|[^\s]"
)


def literal_end(text: str, start: int) -> int:
    quote = text[start]
    index = start + 1
    depth = 0
    while index < len(text):
        char = text[index]
        if char == "\\":
            index += 2
            continue
        if depth and char in "\"'`":
            index = literal_end(text, index)
            continue
        if char == quote and depth == 0:
            return index + 1
        if quote == "`":
            if text.startswith("${", index):
                depth += 1
                index += 2
                continue
            if depth and char in "{}":
                depth += 1 if char == "{" else -1
        index += 1
    return len(text)


def code_tokens(text: str) -> tuple[str, ...]:
    tokens: list[str] = []
    index = 0
    while index < len(text):
        if text[index] in "\"'`":
            index = literal_end(text, index)
            tokens.append("OPAQUE")
            continue
        match = LEXEME.match(text, index)
        if match is None:
            return ()
        token = match.group()
        index = match.end()
        if token.isspace() or token.startswith(("//", "/*")):
            continue
        tokens.append("OPAQUE" if token.startswith("/") else token)
    return tuple(tokens)


def close_delimiter(tokens: tuple[str, ...], start: int) -> int:
    pairs = {"(": ")", "{": "}", "[": "]"}
    stack: list[str] = []
    for index in range(start, len(tokens)):
        token = tokens[index]
        if token in pairs:
            stack.append(pairs[token])
        elif token in pairs.values():
            if not stack or stack.pop() != token:
                return -1
            if not stack:
                return index
    return -1


def function_body(tokens: tuple[str, ...], name: str) -> str:
    bodies: list[str] = []
    for index in range(len(tokens) - 2):
        if tokens[index : index + 3] != ("function", name, "("):
            continue
        end = close_delimiter(tokens, index + 2)
        if end < 0:
            continue
        start = end + 1
        while start < len(tokens) and tokens[start] not in ("{", ";"):
            start += 1
        if start < len(tokens) and tokens[start] == "{":
            end = close_delimiter(tokens, start)
            if end >= 0:
                bodies.append(" ".join(tokens[start + 1 : end]))
    return bodies[0] if len(bodies) == 1 else ""


def proves(body: str, proof: Proof) -> bool:
    position = 0
    for step in proof.steps:
        # @ permits flat object/destructuring fields, never statements or nested scopes.
        pattern = " ".join(
            r"[^{};]*?" if token == "@" else re.escape(token)
            for token in code_tokens(step)
        )
        match = re.search(r"(?<!\S)" + pattern + r"(?!\S)", body[position:])
        if match is None:
            return False
        start = position + match.start()
        depth = body[:start].count("{") - body[:start].count("}")
        nested_call = step.startswith(
            ("resolveComboCooldownWaitDecision(", "dispatchWithCooldownRetry(")
        )
        if depth != 0 and not nested_call:
            return False
        if proof.function == "dispatchWithCooldownRetry" and re.search(
            r"\b(?:const|let|var)\s+(?:deps|extra)\b", body[position:start]
        ):
            return False
        position += match.end()
    return True


def seeded_leaves(script: Path) -> tuple[str, ...]:
    text = script.read_text()
    matches = re.findall(r"(?ms)^desired='(\{.*?^\})'", text)
    if len(matches) != 1:
        fail(f"{script}: expected one desired JSON payload, found {len(matches)}")
    try:
        payload: object = json.loads(matches[0])
    except json.JSONDecodeError as error:
        fail(f"{script}: desired payload is not JSON: {error}")
        raise AssertionError from error

    leaves: list[str] = []

    def visit(value: object, prefix: str) -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                visit(child, f"{prefix}.{key}" if prefix else key)
            return
        leaves.append(prefix)

    visit(payload, "")
    return tuple(sorted(leaves))


def verify(package_root: Path, script: Path, version: str) -> None:
    leaves = seeded_leaves(script)
    unknown = sorted(set(leaves) - CONTRACTS.keys())
    if unknown:
        fail(
            f"omniroute@{version}: no reader contract for seeded key(s): {', '.join(unknown)}"
        )

    failures: list[str] = []
    sources: dict[str, tuple[str, ...]] = {}
    for leaf in leaves:
        for proof in CONTRACTS[leaf]:
            if proof.source not in sources:
                path = package_root / proof.source
                sources[proof.source] = (
                    code_tokens(path.read_text()) if path.is_file() else ()
                )
            body = function_body(sources[proof.source], proof.function)
            if not proves(body, proof):
                failures.append(
                    f"{leaf}: runtime binding/read drifted in {proof.source}::{proof.function}"
                )
                break

    if failures:
        fail(f"omniroute@{version}: " + "; ".join(failures))
    print(
        f"omniroute-resilience-readers: PASS omniroute@{version} ({len(leaves)} seeded leaves)"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-root", required=True, type=Path)
    parser.add_argument("--resilience-script", required=True, type=Path)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    verify(args.package_root, args.resilience_script, args.version)


if __name__ == "__main__":
    main()
