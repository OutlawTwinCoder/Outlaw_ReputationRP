CustomBilling = {
    enabled = true,
    table = 'custom_bills',
    amountColumn = 'price',
    paidColumn = 'paid',
    playerColumn = 'identifier',
    processedColumn = 'rep_processed'
}

CustomIntegrations = {
    -- Exemple d’intégration personnalisée simple par événement
    {
        enabled = false,
        event = 'mon_script:venteValidee',
        repType = 'business',
        amount = 10
    }
}
