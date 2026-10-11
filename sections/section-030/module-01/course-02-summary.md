---
draft: true
exam_objectives:
- Understanding Prometheus Limitations
---
# Summary

Prometheus provides operational metric evidence within its collection and retention boundaries. It cannot reconstruct events never exposed or scraped, and aggregate counters are not a complete financial or transaction ledger.

Cardinality, query scope and storage retention require capacity planning. Remote storage and replicas add separate reliability contracts; monitoring the collector itself is necessary to interpret apparent application silence and missing history.
