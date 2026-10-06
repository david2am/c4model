// c2_clearing.dsl — Clearing Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'platform'.

// ---------- People (MVP demo roles) ----------
viewer = person "Operations Viewer (Demo: Manager)" "Views payments, their status, and the available funds of each credit union."
developer = person "Developer (Demo Presenter)" "Runs the simulators and triggers failure scenarios to show the platform recovers."

// ---------- Test tools ----------
coreSim = softwareSystem "Credit Union Core Simulator" "Test tool that plays the credit union core. Submits payment requests, sends duplicates, and receives status notifications." "Test Tool"
networkSim = softwareSystem "Payment Network Simulator" "Test tool that plays FedNow. Accepts, rejects, delays, or ignores payments, and can send duplicate answers." "Test Tool"
screeningStub = softwareSystem "Sanctions Screening Stub" "Test tool that rejects payments for names on a small test list." "Test Tool"

// ---------- Relationships: people ----------
viewer -> orchestratorApi "Views payments and funds using" "HTTPS"
cuOps -> orchestratorApi "Tracks payments and resolves exceptions using" "HTTPS"
cuTreasury -> orchestratorApi "Monitors liquidity and settlement position using" "HTTPS"
coOps -> orchestratorApi "Monitors all payment activity using" "HTTPS"
developer -> coreSim "Submits normal, duplicate, and failing payments with" "Command line"
developer -> networkSim "Chooses accept, reject, delay, or silence using" "Command line"
developer -> paymentWorker "Stops and restarts, to show recovery, on" "Command line"

// ---------- Relationships: incoming ----------
coreSim -> orchestratorApi "Submits payment requests to" "HTTPS/JSON"
networkSim -> orchestratorApi "Sends payment answers to" "Webhooks/HTTPS"

// ---------- Relationships: inside the platform ----------
orchestratorApi -> platformDb "Saves payments, idempotency keys, and work items in one transaction" "SQL"
paymentWorker -> platformDb "Picks up work items and updates payment state" "SQL"

// ---------- Relationships: outgoing ----------
paymentWorker -> screeningStub "Screens payments with" "HTTPS/JSON"
paymentWorker -> ledgerService "Reserves funds, posts entries, and releases holds with" "HTTPS/JSON, OAuth2 client credentials"
paymentWorker -> networkSim "Sends payment messages to" "HTTPS (ISO 20022 pacs.008)"
paymentWorker -> coreSim "Notifies payment results to" "Webhooks/HTTPS"
orchestratorApi -> ledgerService "Reads available funds from" "HTTPS/JSON, OAuth2 client credentials"

// ---------- Downstream consumers ----------
postSettlement -> orchestratorApi "Reads payment records from" "HTTPS/JSON, OAuth2 client credentials"
