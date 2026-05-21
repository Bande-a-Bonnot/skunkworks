# Initial Questions — Core Data REST Layer

## Conceptual

- Where is the source of truth: server, local context, or a staged unit of work?
- Which Core Data features still make sense when data is remote?
- Which REST semantics cannot be safely hidden behind fetch requests?
- Is a custom persistent store worth the complexity, or is local projection the honest architecture?

## Core Data Surface Area to Test

- Object identity and temporary IDs
- Fetch requests and predicates
- Relationships and faulting
- Change tracking
- Validation
- Merge policies
- Undo/redo
- Batch updates/deletes
- Background contexts

## REST/API Surface Area to Test

- Pagination
- Partial responses / sparse fields
- Server-side filtering and sorting
- ETags or version fields
- Conflict responses
- Rate limits
- Latency and cancellation
- Eventually consistent reads

## Success Signals

- App/UI code becomes simpler without lying about network behavior.
- Conflict and loading states remain explicit enough to reason about.
- The abstraction does not require implementing half of SQL over HTTP.

## Failure Signals

- Every fetch request needs special-case REST translation.
- Relationship faults cause surprising network calls.
- Core Data caching hides stale remote state in dangerous ways.
- The implementation becomes a generic REST ORM.
