local nuiOpen = false

local function toggleNui(state, payload)
    nuiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and 'open' or 'close',
        data = payload
    })
end

RegisterNetEvent('outlaw_reputation:client:requestPopup', function(data)
    SendNUIMessage({
        action = 'request',
        data = data
    })
end)

RegisterNetEvent('outlaw_reputation:client:openNuiForViewer', function(data)
    toggleNui(true, data)
end)

RegisterNetEvent('outlaw_reputation:client:repUpdated', function(repType, amount, reason)
    local message = ('Réputation %s %+d (%s)'):format(repType, amount, reason or 'mise à jour')
    TriggerEvent('esx:showNotification', message)
end)

RegisterNUICallback('respondRequest', function(data, cb)
    TriggerServerEvent('outlaw_reputation:server:requestResponse', data.requestId, data.accepted)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    toggleNui(false)
    cb({ ok = true })
end)
