Integrations = {
    billing = {
        esx_billing = {
            event = 'esx_billing:paidBill',
            repType = 'business',
            formula = function(amount)
                return math.floor((tonumber(amount) or 0) / 100)
            end
        },
        okokBilling = {
            event = 'okokBilling:billPaid',
            repType = 'business',
            formula = function(amount)
                return math.floor((tonumber(amount) or 0) / 125)
            end
        }
    },
    drugs = {
        esx_drugs = {
            event = 'esx_drugs:sold',
            repType = 'crime',
            amount = 5
        }
    }
}
