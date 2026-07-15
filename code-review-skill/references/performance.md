# Performance Rules

When reviewing code for performance issues, look for:
- Inefficient algorithms (e.g., O(N^2) where O(N) is possible).
- Unnecessary network requests or database queries (N+1 queries).
- Blocking synchronous operations in async contexts.
- Unnecessary memory allocations or lack of caching/memoization.
- Suboptimal data structures for the task.
