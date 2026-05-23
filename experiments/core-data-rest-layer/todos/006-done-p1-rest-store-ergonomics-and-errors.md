---
status: done
priority: p1
issue_id: "006"
tags: [core-data, custom-store, errors, ergonomics]
dependencies: ["005"]
---

# REST Store Ergonomics and Error Policy

Make the custom `NSIncrementalStore` path less toy-like without reverting to projection sync.

Done: non-conflict HTTP errors are tested for fetch/fault/save paths, store errors conform to `CustomNSError`, background-context execution is documented and lightly supported, and completeness metadata options are evaluated.

## Acceptance Criteria

- Add tests for non-conflict HTTP errors from fetch, relationship fault, and save paths.
- Decide whether store errors should be Swift enum errors, `NSError` with Core Data domains/userInfo, or a wrapper preserving HTTP details.
- Add a recommended execution policy for app code (background contexts, explicit prefetch APIs if needed, cancellation story if possible).
- Evaluate whether pagination/completeness metadata can be represented as store metadata, managed entities, or external state while still using relationship faults.
