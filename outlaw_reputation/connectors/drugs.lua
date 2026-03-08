CreateThread(function()
    if GetResourceState('esx_drugs') ~= 'started' then
        return
    end

    local cfg = Integrations.drugs.esx_drugs
    if not cfg then
        return
    end

    print('[outlaw_reputation] Connecteur esx_drugs activé')

    RegisterNetEvent(cfg.event, function()
        local src = source
        local amount = cfg.amount or 1
        TriggerEvent('outlaw_rep:add', src, cfg.repType, amount, 'vente de drogue')
    end)
end)

for _, integration in ipairs(CustomIntegrations or {}) do
    if integration.enabled and integration.event then
        RegisterNetEvent(integration.event, function()
            local src = source
            TriggerEvent('outlaw_rep:add', src, integration.repType, integration.amount or 1, 'script custom')
        end)
    end
end
