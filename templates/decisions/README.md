# Decisions

Architecture decision records. Each file answers **why the code is the way it is, what was
rejected, and what that costs** — the one question no other document answers.

[ROADMAP.md](../ROADMAP.md) says what and in what order. [ARCHITECTURE.md](../ARCHITECTURE.md)
says how the code works. These say why.

## Two rules

**1. An accepted record is never edited in place.** To change a decision, write a new record and
set the old one's `status: superseded-by-NNNN`. One in-place edit makes the whole archive
untrustworthy, because a reader can no longer tell whether a record reflects the reasoning that
was actually applied.

Typo and link fixes are fine. Changes to context, decision, alternatives or consequences are not.

**2. A record nobody reads at implementation time is a diary entry.** `/architect` cites the
records its design rests on; `/dispatch` surfaces the records covering a job's `touches` files.
If these stop being read, they stop being worth writing.

## What earns a record

A decision that closes off alternatives and would otherwise be re-argued: a technology choice, a
rejected approach, an accepted risk, a scope boundary. Not: a parameter value, a naming
convention, anything a reader can infer from the code in a minute.

Record a decision you **rejected** as readily as one you took. "We considered X and didn't,
because Y" is the most useful thing in this folder.

## Format

See `decision-template.md`. Use `status: proposed` for a decision recommended but not yet
taken — a proposed record still stops the question being re-derived.

## Current records

<!-- One row per record. Mirror this as a one-line index in ROADMAP.md so the overview stays
     there while the reasoning lives here. -->

| ID | Decision | Status |
|---|---|---|

Cross-cutting constraints that apply to *every* job, rather than to one decision, belong in
ROADMAP and [CLAUDE.md](../CLAUDE.md) — a per-decision file is the wrong shape for a universal
rule.
