// workspace.dsl — MVP workspace
// Composes the system-context model (c1), payment MVP (c2_payment_mvp),
// and settlement MVP (c2_settlement_mvp) into a single Structurizr workspace.

workspace "CorporateOne MVP" "Payment Orchestration and Settlement Accounts — MVP demo." {

    model {
        !include c1.dsl
        !include c2_payment_mvp.dsl
        !include c2_settlement_mvp.dsl
    }

    views {

        // 1. C1 — System context (only real systems, no MVP test tools)
        systemContext platform "SystemContext" {
            include platform
            include member cuOps cuTreasury coOps
            include cuDigital cuCore coLedger
            include fedServices rtpNetwork screening
            autoLayout lr
            title "CorporateOne Payment Orchestration — System Context"
            description "Who and what interacts directly with the Payment Orchestration Platform."
        }

        // 2. C2 — Payment platform containers
        container platform "PaymentContainers" {
            include *
            autoLayout lr
            title "Payment Orchestration MVP — Containers"
        }

        // 3. C2 — Settlement ledger containers
        container coLedger "SettlementContainers" {
            include *
            autoLayout lr
            title "Settlement Accounts MVP — Containers"
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
                color #ffffff
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
            relationship "Relationship" {
                color #707070
            }
        }
    }
}
