---
type: architecture
title: Copy & Translation
description: Where user-facing copy lives, which layer owns it, and how it gets translated.
tags: [i18n, gettext, copy, translation, ui]
timestamp: 2026-09-04T00:00:00Z
---

Every string a user reads is translatable, and the layer that produces it decides how. Copy is never assembled from fragments, and operator-configured values are never translated.

## The boundary

| Where the string is | What it looks like | Who translates it |
|---|---|---|
| Web layer — templates, flashes, page titles, component labels | wrapped at the call site | the `default` translation domain |
| Core layer — validation and change error messages | a static template plus its values, kept apart | the `errors` translation domain, at render time |
| Operator configuration — the condition list, currency, category names | left exactly as configured | nobody |

The core layer never reaches for the web layer's translation backend. It emits a message template with placeholders and the values to fill them, and the web layer translates that template when it renders the error. This keeps the dependency pointing one way — web depends on core, never the reverse — and is why an error message is the one kind of copy not wrapped where it is written.

## Web copy

Wrap the string where it is written, with a literal. A translation is extracted by reading the source, so anything the extractor cannot see as a literal string never reaches a translator:

- A label held in a module attribute, a map, or a `@doc` is invisible to extraction. Where a component maps a value to a label — a status to its badge wording — give each value its own clause returning a wrapped literal, rather than a lookup table built at compile time.
- Interpolation goes through named bindings, never string interpolation. The name is what a translator moves around the sentence.

## Where unwrapped copy hides

A bare literal the user reads is a defect, wherever it sits. The places it slips through are the ones that do not look like copy:

- Attributes: `aria-label`, `placeholder`, `title`, `alt`, and a component's `label` or `title` attr.
- Short labels: badge text, button text, tab and count labels, a table column header.
- Empty states, helper lines, and captions under a control.
- Flash messages built in an event handler, and page titles set in `mount`.
- A default in a component's `attr` declaration.

Before finishing a change to the web layer, read every literal in the template and the module and ask whether a user sees it. If yes, wrap it.

## Never assemble a sentence

A sentence built by joining a fragment to a subject only reads correctly in the language it was written for; word order, agreement, and article all change elsewhere. Write each outcome as one whole message, even when that repeats most of the words:

- Right: two complete messages, chosen between.
- Wrong: one message with a verb phrase interpolated into it.

The same rule covers a sentence split across two HEEx elements for styling — the copy is still one sentence, so it is one message, with the markup carried by bindings.

What a binding may carry is a *value*, not a clause: a name, a count, a date, a already-whole phrase like a relative time or a status word. The test is whether the thing being substituted could be a noun in the sentence. A verb phrase, a predicate, or anything that has to agree with what surrounds it is a clause, and belongs inside the message.

A count and the noun it counts are one message, chosen by the count, so a language that inflects the noun to match the number can do so.

## Error messages in the core layer

A validation returns the message with placeholders intact and its values alongside, rather than a finished string. Substituting the value at the point the error is raised produces a different string for every value, none of which a translator can ever match.

Placeholders use the same `%{name}` form the translation layer uses, so the message needs no rewriting between the two.

These messages are the one thing extraction cannot find. It reads the web layer, and a core-layer message only reaches translation as a value at render time, so it never appears as a literal for the extractor to see. The error translation file therefore carries them by hand, under a note saying why. Adding or rewording one means editing that file in the same change — nothing will report it missing, and an untranslated message silently falls back to its English template.

## Configuration is not copy

Values an operator sets for their own marketplace — the list of conditions a listing may be in, the currency, the category catalog — are data, not source text. They are rendered as configured. Translating them would mean shipping translations for words this codebase does not know, and would overwrite what the operator deliberately chose.

## Locales

English is the only locale, and it is the default. The translation files carry every extractable string, so adding a language is a matter of translating them and choosing a locale per request — no template changes.

## Keeping translations current

Extraction is a command, not something to maintain by hand — see [cli-commands.md](cli-commands.md). Run it after changing copy and commit the result with the change that caused it, the same way a migration is committed with the schema change that needs it.

Extraction is deliberately not a CI gate. It would fail on every legitimate copy change, which teaches everyone to ignore it.
