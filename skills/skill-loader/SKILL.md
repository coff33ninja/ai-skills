---
name: skill-loader
description: When a skill is loaded, also loads all skills it cross-references, ensuring related instruction sets compose together automatically. Prevents gaps where a skill references another but that skill is never activated.
---

# Skill Loader

## Problem it solves

Skills are activated individually. But skills reference each other in their `## Cross-references` sections. When skill A tells you to follow the protocol from skill B, but skill B isn't loaded, you miss half the instructions. The cross-reference system only works if both sides are actually in context.

## Protocol

### 1. On skill load, inspect cross-references

Whenever you call the `skill` tool to load a skill, immediately read its `## Cross-references` section. Identify every skill name listed there (the bolded name in each bullet).

### 2. Load all referenced skills

For each referenced skill that is not already loaded in the current conversation:

```
skill name="<referenced-skill>"
```

This ensures both sides of every cross-reference are active.

### 3. Detect transitive loading

If a referenced skill has its own cross-references, load those too — but only one level deep. Prevent infinite loops by keeping a set of already-loaded skills.

```
loaded = {initial_skill}
for each ref in cross_references(initial_skill):
    if ref not in loaded:
        load(ref)
        loaded.add(ref)
```

Do NOT recurse beyond one hop. Two levels (initial + direct refs) is sufficient.

### 4. When no cross-references exist

Some skills have `## When NOT to use` but no cross-references. No additional loading needed.

### 5. Deduplication

If multiple loaded skills all reference the same target skill, load it once.

## Detection triggers

Activate automatically whenever you call the `skill` tool to load a skill. This is a companion protocol that runs after every skill load.

## When NOT to use

- The loaded skill has no `## Cross-references` section
- The user explicitly asks you to load only one skill
- You're in the middle of a task and loading more skills would bloat context — use judgment

## Cross-references

- **dont-kill-tokens** — Loading multiple skills consumes context. Be selective: only load cross-references that are actually relevant to the current task. If a cross-referenced skill is tangential, skip it.
- **anti-tool-sprawl** — Each skill load is a tool call. Batch them. Don't load 10 skills one at a time.
- **self-validate** — After loading a skill and its cross-references, validate that the combined instruction set is consistent and doesn't contradict itself.
- **follow-existing-patterns** — Cross-referenced skills may have their own patterns. Follow the most specific one for the current subtask.
