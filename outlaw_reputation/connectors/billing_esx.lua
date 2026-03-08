CreateThread(function()
    if GetResourceState('esx_billing') ~= 'started' then
        return
    end

    local cfg = Integrations.billing.esx_billing
    if not cfg then
        return
    end

    print('[outlaw_reputation] Connecteur esx_billing activé')

    RegisterNetEvent(cfg.event, function(amount)
        local src = source
        local rep = cfg.formula and cfg.formula(amount) or 0
        if rep > 0 then
            TriggerEvent('outlaw_rep:add', src, cfg.repType, rep, 'facture ESX payée')
        end
    end)
end)
