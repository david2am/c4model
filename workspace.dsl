// workspace.dsl — OnePlatform workspace
// Composes the system-context model (c1), Clearing Platform (c2_payment),
// Settlement Platform (c2_settlement), and Post-Settlement Platform (c2_post-settlement).

workspace "OnePlatform MVP" "Clearing and Settlement Accounts — MVP demo." {

    model {
        !include c1.dsl
        !include c2_payment.dsl
        !include c2_settlement.dsl
        !include c2_post-settlement.dsl
    }

    views {

        // 1. C1 — System context (only real systems, no MVP test tools)
        systemContext platform "SystemContext" {
            include platform
            include member cuOps cuTreasury coOps coFinance coCompliance
            include cuDigital cuCore coLedger postSettlement coGL
            include fedServices rtpNetwork screening regulator identity
            autoLayout lr
            title "OnePlatform — System Context"
            description "Who and what interacts directly with the Clearing Platform."
        }

        // 2. C2 — Payment platform containers
        container platform "PaymentContainers" {
            include *
            autoLayout lr
            title "Clearing Platform"
        }

        // 3. C2 — Settlement ledger containers
        container coLedger "SettlementContainers" {
            include *
            autoLayout lr
            title "Settlement Platform"
        }

        // 4. C2 — Post-Settlement Platform containers
        container postSettlement "PostSettlementContainers" {
            include *
            autoLayout lr
            title "Post-Settlement Platform"
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
            relationship "Relationship" {
                color #707070
            }
        }
    }
}
