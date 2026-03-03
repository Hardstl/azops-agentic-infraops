---
agent: ask
description: Verify Microsoft SDK/API methods, signatures, and sample usage from official references.
---

You are validating Microsoft SDK/API correctness before coding.

## Validation workflow

1. Verify method/type/package existence with `microsoft_docs_search`.
2. Fetch full API docs with `microsoft_docs_fetch` when overloads or signatures are unclear.
3. Find working examples with `microsoft_code_sample_search`.

## Output contract

Return:

- Verified API/method/class names
- Package names and versions (if documented)
- Minimal known-good usage pattern
- Common pitfalls or deprecated alternatives
- URLs used for verification

## Rules

- Do not invent APIs.
- Flag uncertain signatures as unverified.
- Prefer stable, current patterns unless user requests legacy compatibility.
