// c2_clearing.dsl — Clearing Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'platform'.

// ---------- People (MVP demo roles) ----------
// Note: 'viewer' is a demo stand-in for coOps in the MVP environment.
// In production, coOps (declared in c1.dsl) uses the same API with proper RBAC.
// Tagged as a test persona, not a production role.
viewer = person "Operations Viewer (Demo)" "Demo persona for MVP. Views payments, their status, and available funds. Superseded by coOps in production with proper per-credit-union RBAC." "Test Tool"

// ---------- Test tools (MVP only — replaced by real systems in production) ----------
coreSim = softwareSystem "Credit Union Core Simulator" "Test tool. Plays both sender (submits outbound payment requests, sends duplicates) and receiver (accepts inbound credit notifications and return notifications via webhook) roles of a credit union core." "Test Tool"
networkSim = softwareSystem "Payment Network Simulator" "Test tool that simulates FedNow. Accepts, rejects, delays, or ignores payments, generates return messages (pacs.004), and can send duplicate answers to test idempotency." "Test Tool"
screeningStub = softwareSystem "Sanctions Screening Stub" "Test tool that rejects payments for a small hardcoded list of names. Returns a block response to simulate the real screening service being unavailable." "Test Tool"

// ---------- Relationships: people ----------
viewer -> apim "Views payments and available funds using" "HTTPS"
cuOps -> apim "Tracks payments and resolves exceptions using" "HTTPS"
cuTreasury -> apim "Reads available funds and settlement positions using" "HTTPS"
coOps -> apim "Monitors all payment activity across all credit unions using" "HTTPS"

// ---------- Relationships: API Gateway ----------
apim -> orchestratorApi "Routes payment requests and read operations to" "HTTPS"
apim -> identity "Validates staff tokens with" "OpenID Connect"

// ---------- Relationships: incoming from credit unions ----------
coreSim -> apim "Submits outbound payment requests to" "HTTPS/JSON"

// ---------- Relationships: incoming from networks (outbound confirmation + inbound credits + returns) ----------
networkSim -> apim "Sends payment confirmations, inbound credits, and return messages (pacs.004) to" "Webhooks/HTTPS"

// ---------- Relationships: inside the platform ----------
orchestratorApi -> platformDb "Saves payments, idempotency keys, and work items in one transaction" "SQL"
paymentWorker -> platformDb "Picks up work items, updates payment state, and writes to dead-letter on unrecoverable failure" "SQL"
paymentWorker -> isoService "Builds and parses ISO 20022 messages (pacs.008, pacs.004, pacs.002) via" "gRPC"
paymentWorker -> keyVault "Retrieves network certificates and API secrets from" "HTTPS"
orchestratorApi -> keyVault "Retrieves API secrets from" "HTTPS"

// ---------- Relationships: outgoing (outbound payment flow) ----------
paymentWorker -> screeningStub "Screens payment against OFAC list via" "HTTPS/JSON"
paymentWorker -> ledgerService "Reserves funds before sending, posts final entries on confirmation, releases holds on failure or return" "HTTPS/JSON, OAuth2 client credentials"
paymentWorker -> networkSim "Sends outbound FedNow payment messages to" "HTTPS (ISO 20022 pacs.008 / mTLS simulated)"

// ---------- Relationships: inbound credit and return flow ----------
// When networkSim delivers an inbound credit or return, paymentWorker handles it:
paymentWorker -> coreSim "Notifies of payment results, inbound credits, and return outcomes via" "Webhooks/HTTPS"

// ---------- Relationships: operations read path ----------
orchestratorApi -> ledgerService "Reads available funds per credit union from" "HTTPS/JSON, OAuth2 client credentials"

// ---------- Downstream consumers ----------
postSettlement -> orchestratorApi "Reads payment records as of cut-off time from" "HTTPS/JSON, OAuth2 client credentials"
