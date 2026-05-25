# Cancellation / Timeout Spike Findings

**Date:** 2026-05-25

## What changed

Added an explicit request timeout option to the custom-store stack:

```swift
let stack = try RESTCoreDataStack(baseURL: baseURL, requestTimeout: 0.5)
```

The timeout is passed into the blocking REST bridge used by `RESTIncrementalStore`. Fetches, relationship faults, direct task-detail loads, saves, and pending-change flushes all go through that bridge, so a configured timeout applies to the blocking custom-store REST path.

When the timeout expires, the bridge cancels the in-flight `URLSessionTask` and throws:

```swift
RESTIncrementalStoreError.requestTimedOut(TimeInterval)
```

The error also bridges through `CustomNSError` with the existing store error domain and `TimeoutSeconds` user info.

## Test coverage

`testRESTIncrementalStoreConfiguredTimeoutTurnsSlowFetchIntoTypedFailure` configures embedded-server latency on `GET /projects`, creates a stack with a much shorter timeout, and verifies that `context.fetch(...)` fails quickly with `RESTIncrementalStoreError.requestTimedOut`.

## Cancellation limits

This does **not** make `NSIncrementalStore` truly cancellable. Core Data still calls `execute`, `newValuesForObject`, `newValue(forRelationship:)`, and save handling synchronously. Once a caller enters one of those hooks, it cannot receive cooperative Swift task cancellation until the hook returns.

The timeout is therefore a bounded-wait policy, not a full cancellation model:

- app code should still run REST-backed Core Data work on private-queue/background contexts;
- UI code should avoid direct relationship/property access that may fault over the network;
- cancellation at higher app layers can abandon waiting for an operation, but the synchronous store work can only stop at explicit timeout/check boundaries.

## Verdict

A configured timeout is a useful minimum safety valve for the spike: slow endpoints become typed failures instead of indefinite semaphore waits. True cancellation would require a higher-level async loader/writer API and carefully designed cooperative boundaries around synchronous Core Data calls.
