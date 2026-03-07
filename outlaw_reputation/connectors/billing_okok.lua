CreateThread(function()
    if GetResourceState('okokBilling') ~= 'started' then
        return
    end

    local cfg = Integrations.billing.okokBilling
    if not cfg then
        return
    end

    print('[outlaw_reputation] Connecteur okokBilling activé')

    RegisterNetEvent(cfg.event, function(amount)
        local src = source
        local rep = cfg.formula and cfg.formula(amount) or 0
        if rep > 0 then
            TriggerEvent('outlaw_rep:add', src, cfg.repType, rep, 'facture okok payée')
        end
    end)
end)
