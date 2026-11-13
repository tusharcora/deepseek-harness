---
description: "Records a persistence type transition and its compatibility acknowledgement."
kind: persistence-change
---

# 2026-11-06-crew-improve-message-source

English | [中文](2026-11-06-crew-improve-message-source.zh.md)

## Summary

Adds a crew-improve variant to the persisted message source union. crew-improve labels the input of its reflection request with it. The Session format version is unchanged.

## Table of Contents

- [Declaration](#declaration)
- [Compatibility](#compatibility)
- [Verification](#verification)
- [Dev Note](#dev-note)

<a id="declaration"></a>
## Declaration

```yaml persistence-change
schemaVersion: 1
id: 2026-11-06-crew-improve-message-source
baseline: false
changes:
  - root: "event:agent/inbox/spliced"
    previous: "2026-10-27-retry-control-input"
    after: "a5e39f8b73792635623995f027c9a212cd206aae6c421e081b68876e7a9022e8"
    decision: same-version
  - root: "event:developer/message"
    previous: "2026-10-27-retry-control-input"
    after: "d33f5e50fb31bb8196d77d30b2b6d2fb4e864b6cb3bfb7c30c5b5b3fc758cf9a"
    decision: same-version
  - root: "event:session/title-llm-request"
    previous: "2026-10-27-retry-control-input"
    after: "47afce5c771e1f35fe39d681bd00db7a091fb5da7734d5400a194926cffe676d"
    decision: same-version
  - root: "event:user/message"
    previous: "2026-10-27-retry-control-input"
    after: "a5417b556dbfe59735a09ffbb9e97eb6581250c11a115fd168f1180f43a40978"
    decision: same-version
```

<a id="compatibility"></a>
## Compatibility

The change widens a union and changes no existing variant. Existing user, developer, agent inbox and title-request records keep their current source kinds, so every Session written before this change reads as before. A message carries source kind crew-improve only when the experimental crew-improve plugin sends its reflection request. A reader without crew-improve sees an unknown source kind on those records and treats it as it treats other plugin-declared kinds; the message content and role are unchanged. No header, event envelope or existing value type changes, and no adjacent migration is required.

<a id="verification"></a>
## Verification

pnpm exec vitest run packages/experimental/crew-improve scripts/persistence-changes.spec.ts scripts/persistence-schema.spec.ts passed 178 tests across 3 files. The persistence preview classified only the added crew-improve variant on the four message-source roots and required no version bump.

<a id="dev-note"></a>
## Dev Note

None.
