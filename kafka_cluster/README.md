
**Kafka Core concepts**:

- Storage: Topic / Partition / Offset / Page cache / Hot Cold Tier
- Clustering: Broker / Replication / ISR Set / Cluster Controller / Partition Leader
- Clients: Producer / Consumer / Consumer group / Group Coordinator


Design:

                  ┌────────────────────────────────────────────────┐
                  │              Kafka Cluster                     │
                  │  (KRaft Controller Quorum: Nodes 1,2,3)        │
                  └────┬───────────────┬──────────────────────┬────┘
                       │               │                      │
            ┌──────────▼───┐       ┌───▼──────────┐       ┌───▼──────────┐
            │   Broker 1   │       │   Broker 2   │       │   Broker 3   │
            ├──────────────┤       ├──────────────┤       ├──────────────┤
            │  Topic:      │       │  Topic:      │       │  Topic:      │
            │  clickstream │       │  clickstream │       │  clickstream │
            │  P0 (Leader) │       │  P0 (Follow) │       │  P0 (Follow) │
            │  P1 (Follow) │       │  P1 (Leader) │       │  P1 (Follow) │
            │  P2 (Follow) │       │  P2 (Follow) │       │  P2 (Leader) │
            └──────────────┘       └──────────────┘       └──────────────┘
