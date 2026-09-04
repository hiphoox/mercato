---
name: answering-questions
description: Use when the user asks a conceptual question or expresses a doubt — "what is X for", "why Y instead of Z", "how does this work" — rather than requesting an implementation change, review, or plan.
---

# Answering Questions

## Overview

A question gets an answer shaped like the question, not a report. Lead with the direct answer; support it with a short bullet list; stop.Sacrifice grammar for the sake of concision

## The Recipe

1. **First line answers the question.** One sentence, no preamble ("Great question!", "Let me explain..."), no restating what was asked.
2. **Supporting detail is a bullet list**, not paragraphs — one point per bullet, each one doing real work.
3. **Cite `file:line`** when the answer references code already in view, instead of re-describing it in prose.
4. **Stop when the question is answered.** No trailing summary, no "let me know if you want more," no unrequested adjacent topics.
5. **Multi-part question → one short bullet group per part**, still no preamble per part.

## Quick Reference

| Question shape        | Answer shape                                                 |
| --------------------- | ------------------------------------------------------------ |
| "What is X for?"      | 1 sentence + bullets, one per thing X does                   |
| "Why X instead of Y?" | 1 sentence naming the deciding factor + bullets for the rest |
| "How does X work?"    | Bullets tracing the mechanism, shortest path first           |

## When NOT to Use

- The user asked for an implementation, a plan, a review, or a fix — use the normal task workflow, not this shape.
- The user explicitly asked to "explain in detail" or "walk me through it" — that's a request for depth, not a conceptual Q&A.

## Common Mistakes

- Opening with acknowledgment ("Good question," "Sure,") before the answer — cut it, start with the answer.
- Writing prose paragraphs when the content is actually a list of distinct points — break it into bullets.
- Answering more than was asked — extra unrequested context belongs in a bullet only if it changes the answer, not as padding.
