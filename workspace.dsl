// workspace.dsl — OnePlatform workspace
// Composes the system-context model (c1), Clearing Platform (c2_clearing),
// Settlement Platform (c2_settlement), and Post-Settlement Platform (c2_post-settlement).

workspace "OnePlatform" "Payment clearing, settlement, and post-settlement for member credit unions." {

    model {
        !include src/c1.dsl
        !include src/mvp/c2_clearing.dsl
        !include src/mvp/c2_settlement.dsl
        !include src/mvp/c2_post-settlement.dsl
        !include src/mvp/c2_monitoring.dsl
    }

    views {

        // 0. System Landscape — all three platforms side by side
        systemLandscape "SystemLandscape-001" {
            include *
            autoLayout lr
            title "OnePlatform — System Landscape"
            description "All three platforms and every external system and person involved in the payment lifecycle."
        }

        // 2. C2 — Clearing Platform containers
        container platform "ClearingContainers" {
            include *
            autoLayout lr
            title "Clearing Platform"
            description "Containers of the Clearing Platform: API Gateway, Orchestrator, Payment Worker, ISO 20022 Service, Key Vault, and Platform Database."
        }

        // 3. C2 — Settlement Platform containers
        container settlement "SettlementContainers" {
            include *
            autoLayout lr
            title "Settlement Platform"
            description "Containers of the Settlement Platform: Ledger Service, Business Day Scheduler, Integrity Check Job, Event Publisher (stretch), and Ledger Database."
        }

        // 4. C2 — Post-Settlement Platform containers
        container postSettlement "PostSettlementContainers" {
            include *
            autoLayout lr
            title "Post-Settlement Platform"
            description "Containers of the Post-Settlement Platform (future): Back-Office Portal, API, Data Collector, Reconciliation Engine, Report Generator, Accounting Exporter, Database, and Archive."
        }

        // 5. C2 — Monitoring and Alerting Platform containers
        container monitoring "MonitoringContainers" {
            include *
            autoLayout lr
            title "Monitoring and Alerting Platform"
            description "Containers of the Monitoring and Alerting Platform: Metrics Collector, Log Aggregator, Trace Collector, Alert Manager, Dashboard Service, and Monitoring Database."
        }

        // 6. Dynamic — Outbound payment happy path (Clearing)
        dynamic platform "HappyPath" "How one outbound FedNow payment travels through the Clearing Platform end to end." {
            coreSim -> apim "1. Submits outbound payment request"
            apim -> orchestratorApi "2. Routes request after token validation"
            orchestratorApi -> platformDb "3. Checks idempotency key; saves payment + work item atomically"
            paymentWorker -> platformDb "4. Picks up work item"
            paymentWorker -> isoService "5. Requests ISO 20022 pacs.008 message"
            paymentWorker -> screeningStub "6. Screens payment (blocks if unavailable)"
            paymentWorker -> ledgerService "7. Reserves funds (hold)"
            paymentWorker -> networkSim "8. Sends pacs.008 to FedNow simulator"
            networkSim -> apim "9. Returns pacs.002 confirmation"
            apim -> orchestratorApi "10. Delivers confirmation"
            orchestratorApi -> platformDb "11. Records confirmation"
            paymentWorker -> platformDb "12. Picks up confirmation work item"
            paymentWorker -> ledgerService "13. Posts final settlement entries (converts hold to debit)"
            paymentWorker -> coreSim "14. Notifies credit union core of confirmed result"
            autoLayout lr
        }

        // 7. Dynamic — Reserve and post in the Settlement Platform
        dynamic settlement "ReserveAndPost" "How funds are held, then posted, for one outbound payment." {
            simulator -> ledgerService "1. Requests hold (reserve) for payment amount"
            ledgerService -> ledgerDb "2. Checks available funds; creates hold entry atomically"
            simulator -> ledgerService "3. On network confirmation, requests post"
            ledgerService -> ledgerDb "4. Converts hold into permanent debit; writes outbox event"
            eventPublisher -> ledgerDb "5. Reads new outbox entry (stretch)"
            eventPublisher -> settlementBus "6. Publishes balance-changed event (stretch)"
            autoLayout lr
        }

        // 8. Dynamic — Daily reconciliation (Post-Settlement)
        dynamic postSettlement "DailyReconciliation" "How the Post-Settlement Platform reconciles numbers after the daily cut-off." {
            cutoffScheduler -> ledgerDb "1. Writes end-of-day cut-off marker"
            collector -> orchestratorApi "2. Downloads payment records as of cut-off"
            collector -> ledgerService "3. Downloads ledger entries as of cut-off"
            collector -> fedServices "4. Downloads FedNow statement via FedLine API"
            collector -> rtpNetwork "5. Downloads RTP settlement report via SFTP"
            collector -> db "6. Stores normalized data"
            collector -> archive "7. Stores originals untouched"
            reconEngine -> db "8. Compares platform vs ledger vs network statements; writes breaks"
            autoLayout lr
        }

        // 9. Dynamic — End-to-end: inbound credit received from FedNow
        dynamic platform "EndToEnd" "How an inbound FedNow credit is received and credited to the member's account." {
            networkSim -> apim "1. Delivers inbound pacs.008 credit"
            apim -> orchestratorApi "2. Routes inbound credit"
            orchestratorApi -> platformDb "3. Checks idempotency; saves inbound payment + work item"
            paymentWorker -> platformDb "4. Picks up inbound work item"
            paymentWorker -> isoService "5. Parses ISO 20022 pacs.008"
            paymentWorker -> ledgerService "6. Posts credit to receiving credit union's account"
            paymentWorker -> coreSim "7. Notifies credit union core to credit member's account"
            autoLayout lr
        }

        // 10. Dynamic — Worker crash recovery (dead-letter scenario)
        dynamic platform "WorkerCrash" "What happens when a Payment Worker crashes mid-flight on a work item." {
            paymentWorker -> platformDb "1. Picks up work item; lease expires on crash"
            paymentWorker -> platformDb "2. On restart, picks up same item (lease reacquired)"
            paymentWorker -> ledgerService "3. Retries reserve — ledgerService ignores duplicate (idempotency key)"
            paymentWorker -> networkSim "4. Retries send — network sees duplicate; returns original answer"
            paymentWorker -> platformDb "5. Max retries exceeded — moves item to dead-letter table"
            coOps -> apim "6. Ops staff investigates dead-letter entry"
            autoLayout lr
        }

        // 11. Dynamic — Correction approval flow (Post-Settlement)
        dynamic postSettlement "CorrectionApproval" "How a two-person correction is proposed, approved, and applied to the ledger." {
            coFinance -> portal "1. Investigates break; proposes correcting entry"
            portal -> api "2. Submits proposed correction"
            api -> db "3. Saves correction in pending state"
            coApprover -> portal "4. Reviews and approves correction (must be different person)"
            portal -> api "5. Submits approval with approver identity"
            api -> db "6. Records approval"
            api -> ledgerService "7. Sends correcting entry with approver identity in payload"
            ledgerService -> ledgerDb "8. Posts idempotent correcting entry; records approver identity"
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "In Scope" {
                background #0b5394
                color #ffffff
            }
            element "Future" {
                background #6fa8dc
                color #000000
                border dashed
            }
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Test Tool" {
                background #bbbbbb
                color #000000
                border dashed
            }
            element "Container" {
                background #1168bd
                color #ffffff
            }
            element "Stretch" {
                background #85bbf0
                color #000000
                border dashed
            }
            element "Database" {
                shape Cylinder
                background #0078d4
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
                background #1168bd
                color #ffffff
            }
            element "Worker" {
                background #85bbf0
                color #000000
            }
            element "Archive" {
                shape Folder
                background #5c5c5c
                color #ffffff
            }
            element "Gateway" {
                background #0078d4
                color #ffffff
            }
            element "Queue" {
                shape Pipe
                background #0078d4
                color #ffffff
            }
            element "Vault" {
                background #5c5c5c
                color #ffffff
            }
            element "App" {
                background #1168bd
                color #ffffff
            }
            relationship "Relationship" {
                color #707070
            }
        }
    }
}
