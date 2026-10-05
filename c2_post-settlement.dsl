// c2_post-settlement.dsl — Post-Settlement Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'postSettlement'.
// All external systems and most people are declared in c1.dsl.

// ---------- People (new in this fragment) ----------
coApprover = person "Finance Supervisor (Approver)" "Approves or rejects corrections. Must be a different person than the one who proposed it."

// ---------- Relationships: people ----------
coFinance -> portal "Investigates differences and proposes corrections using" "HTTPS"
coApprover -> portal "Approves or rejects corrections using" "HTTPS"
coCompliance -> portal "Reviews history and reports using" "HTTPS"
cuOps -> portal "Downloads statements and reports using" "HTTPS"

// ---------- Relationships: entry points ----------
portal -> api "Requests data and actions from" "HTTPS/JSON"
portal -> identity "Signs users in with" "OpenID Connect"
api -> identity "Validates tokens with" "OpenID Connect"
api -> db "Reads results and saves cases and approvals in" "SQL"
api -> archive "Reads reports from" "HTTPS"
api -> coLedger "Sends approved correcting entries to" "HTTPS/JSON"

// ---------- Relationships: collecting ----------
collector -> fedServices "Downloads account statements from" "HTTPS / SFTP"
collector -> rtpNetwork "Downloads settlement reports from" "HTTPS / SFTP"
collector -> platform "Reads payment records from" "HTTPS/JSON"
collector -> coLedger "Reads entries and balances from" "HTTPS/JSON"
collector -> db "Stores normalized data in" "SQL"
collector -> archive "Stores original files in" "HTTPS"

// ---------- Relationships: comparing ----------
reconEngine -> db "Reads normalized data and stores matches and breaks in" "SQL"

// ---------- Relationships: reporting ----------
reportGenerator -> db "Reads the snapshot and stores report records in" "SQL"
reportGenerator -> archive "Stores generated reports in" "HTTPS"
reportGenerator -> cuCore "Sends statements and activity reports to" "HTTPS / SFTP"
reportGenerator -> regulator "Submits regulatory reports to" "HTTPS / SFTP"

// ---------- Relationships: accounting ----------
accountingExporter -> db "Reads daily totals from" "SQL"
accountingExporter -> coGL "Sends summarized entries to" "HTTPS/JSON"
