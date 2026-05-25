---
status: done
priority: p2
issue_id: "012"
tags: [core-data, custom-store, cancellation, timeouts]
dependencies: ["009"]
completed: 2026-05-25
---

# Spike Cancellation and Timeout Behavior

Add a narrow timeout policy around the blocking custom-store REST path.

## Acceptance Criteria

- [x] `RESTCoreDataStack` can configure a request timeout for the custom store.
- [x] Blocking REST requests stop waiting after the configured timeout and throw a typed store error.
- [x] Tests prove a slow REST endpoint becomes a typed timeout failure instead of an indefinite block.
- [x] Documentation states that true cancellation remains cooperative/limited by synchronous `NSIncrementalStore` hooks.

## Notes

This is a timeout spike, not full cancellation. The underlying `URLSessionTask` is cancelled on timeout, but Core Data still enters synchronous store hooks and callers only regain control after the timeout boundary.
