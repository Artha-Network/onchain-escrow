# Events

All events are declared in `programs/onchain_escrow/src/events.rs` and emitted from instructions.

## List
- DealInitiated { deal_id }
- DealFunded { deal_id, amount }
- EvidenceSubmitted { deal_id, cid }
- DealDisputed { deal_id }
- DealResolved { deal_id, action }
- DealReleased { deal_id }
- DealRefunded { deal_id }

### Updates
- v1.0.0 — Initial creation

