// workspace.dsl
workspace {
    model {
        !include c1.dsl
        !include c2_payment_complete.dsl
        !include c2_settlement_complete.dsl
        # !include c2_settlement_mvp.dsl
        # !include c2_settlement_mvp2.dsl
        // relationships that cross systems can live here
    }

    views {
        systemLandscape {
            include *
            autoLayout
        }
        systemContext systemA {
            include *
            autoLayout
        }
        container systemA {
            include *
            autoLayout
        }
        // more views...
    }
}