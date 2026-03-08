local pendingRequests = {}
local interactionBuffer = {}
local dailyBuffer = {}
local myRepCooldown = {}

local function debugLog(msg)
    if Config.Debug then
        print(('[outlaw_reputation][CORE] %s'):format(msg))
    end
end

local function todayKey()
    return os.date('%Y-%m-%d')
end

local function getIdentifier(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license and license ~= '' then
        return license
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return nil
    end

    return xPlayer.getIdentifier()
end

local function isValidRepType(repType)
    return Config.ReputationTypes[repType] ~= nil
end

local function checkDailyCap(identifier, repType, amount)
    local cap = Config.AntiAbuse.dailyCaps[repType]
    if not cap then
        return true, amount
    end

    local key = ('%s:%s:%s'):format(todayKey(), identifier, repType)
    dailyBuffer[key] = dailyBuffer[key] or 0

    if dailyBuffer[key] >= cap then
        return false, 0
    end

    local allowed = math.min(amount, cap - dailyBuffer[key])
    dailyBuffer[key] = dailyBuffer[key] + allowed

    return allowed > 0, allowed
end

local function checkInteractionLimit(sourceIdentifier, targetIdentifier)
    local limitCfg = Config.AntiAbuse.interactionLimit
    local key = ('%s->%s'):format(sourceIdentifier, targetIdentifier)
    local now = os.time()
    local data = interactionBuffer[key]

    if not data or now - data.windowStart > limitCfg.windowSeconds then
        interactionBuffer[key] = { count = 1, windowStart = now }
        return true
    end

    if data.count >= limitCfg.maxPerSourceTarget then
        return false
    end

    data.count = data.count + 1
    return true
end

local function computeDecay(sourceIdentifier, targetIdentifier, amount)
    local key = ('%s->%s'):format(sourceIdentifier, targetIdentifier)
    local data = interactionBuffer[key]
    if not Config.AntiAbuse.decay.enabled or not data then
        return amount
    end

    if data.count <= Config.AntiAbuse.decay.threshold then
        return amount
    end

    local reduced = math.floor(amount * Config.AntiAbuse.decay.factor)
    return math.max(reduced, 1)
end

local function hasPermissionForType(source, repType)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false
    end

    local job = xPlayer.job
    for _, rule in pairs(Config.ViewPermissions) do
        if job and job.name == rule.job and (job.grade or 0) >= rule.grade then
            for _, allowedType in ipairs(rule.canSee) do
                if allowedType == repType then
                    return true
                end
            end
        end
    end
    return false
end

OutlawRep = OutlawRep or {}

function OutlawRep.addRep(playerId, repType, amount, reason, sourcePlayer)
    if not isValidRepType(repType) then
        return false, 'Type de réputation invalide'
    end

    local identifier = getIdentifier(playerId)
    if not identifier then
        return false, 'Joueur introuvable'
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then
        return false, 'Montant nul'
    end

    if sourcePlayer and sourcePlayer > 0 then
        local sourceIdentifier = getIdentifier(sourcePlayer)
        if sourceIdentifier and not checkInteractionLimit(sourceIdentifier, identifier) then
            return false, 'Limite d’interactions atteinte'
        end

        if sourceIdentifier then
            amount = computeDecay(sourceIdentifier, identifier, amount)
        end
    end

    local ok, allowedAmount = checkDailyCap(identifier, repType, amount)
    if not ok then
        return false, 'Cap quotidien atteint'
    end

    OutlawDB.addPlayerRep(identifier, repType, allowedAmount)

    local xTarget = ESX.GetPlayerFromId(playerId)
    if xTarget and xTarget.job and Config.CompanyJobs[xTarget.job.name] then
        OutlawDB.addBusinessRep(xTarget.job.name, allowedAmount)
        OutlawDB.addContribution(identifier, xTarget.job.name, allowedAmount)
    end

    if repType == 'crime' then
        local crimeRep = OutlawDB.fetchPlayerRep(identifier, 'crime')
        OutlawDB.updatePoliceRecord(identifier, crimeRep)
    end

    TriggerClientEvent('outlaw_reputation:client:repUpdated', playerId, repType, allowedAmount, reason or 'mise à jour')
    return true, allowedAmount
end

function OutlawRep.getRep(playerId, repType)
    local identifier = getIdentifier(playerId)
    if not identifier then
        return Config.DefaultRep
    end
    return OutlawDB.fetchPlayerRep(identifier, repType)
end

function OutlawRep.setRep(playerId, repType, value)
    if not isValidRepType(repType) then
        return false
    end

    local identifier = getIdentifier(playerId)
    if not identifier then
        return false
    end

    OutlawDB.setPlayerRep(identifier, repType, math.floor(tonumber(value) or 0))
    return true
end

exports('addRep', function(playerId, repType, amount, reason)
    local ok = OutlawRep.addRep(playerId, repType, amount, reason, 0)
    return ok
end)

exports('getRep', function(playerId, repType)
    return OutlawRep.getRep(playerId, repType)
end)

exports('setRep', function(playerId, repType, value)
    return OutlawRep.setRep(playerId, repType, value)
end)

AddEventHandler('outlaw_rep:add', function(playerId, repType, amount, reason)
    local src = source
    local ok, message = OutlawRep.addRep(playerId, repType, amount, reason, src)
    if not ok then
        debugLog(('Refus addRep (%s)'):format(message))
    end
end)

RegisterCommand(Config.CommandName, function(source, args)
    local target = tonumber(args[1])
    local repType = args[2] or 'business'

    if not target or not GetPlayerName(target) then
        TriggerClientEvent('esx:showNotification', source, 'ID cible invalide')
        return
    end

    if not isValidRepType(repType) then
        TriggerClientEvent('esx:showNotification', source, 'Type de réputation invalide')
        return
    end

    if not hasPermissionForType(source, repType) then
        TriggerClientEvent('esx:showNotification', source, 'Permission insuffisante')
        return
    end

    local reqId = ('%s:%s:%s:%s'):format(source, target, repType, os.time())
    pendingRequests[reqId] = {
        requester = source,
        target = target,
        repType = repType,
        expiresAt = os.time() + Config.RequestTimeout
    }

    local xRequester = ESX.GetPlayerFromId(source)
    local jobLabel = xRequester and xRequester.job and xRequester.job.label or 'Un employé'

    TriggerClientEvent('outlaw_reputation:client:requestPopup', target, {
        requestId = reqId,
        message = ('[%s] veut voir votre réputation %s'):format(jobLabel, repType),
        timeout = Config.RequestTimeout
    })

    TriggerClientEvent('esx:showNotification', source, 'Demande envoyée')
end)

RegisterCommand('myrep', function(source)
    if source == 0 then
        return
    end

    local now = os.time()
    local lastOpen = myRepCooldown[source] or 0
    if now - lastOpen < 2 then
        return
    end
    myRepCooldown[source] = now

    local identifier = getIdentifier(source)
    if not identifier then
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local business = xPlayer and xPlayer.job and xPlayer.job.name or nil

    local payload = {
        targetName = GetPlayerName(source),
        repType = 'self',
        reputations = OutlawDB.getAllReputations(identifier),
        company = {
            name = business,
            rep = business and OutlawDB.getBusinessRep(business) or 0,
            contributions = business and OutlawDB.getCompanyContributions(business) or {}
        },
        policeRecord = OutlawDB.getPoliceRecord(identifier),
        leaderboard = OutlawDB.getLeaderboard('business', Config.LeaderboardLimit),
        repTypes = Config.ReputationTypes
    }

    TriggerClientEvent('outlaw_reputation:client:openNuiForViewer', source, payload)
end, false)

RegisterNetEvent('outlaw_reputation:server:requestResponse', function(requestId, accepted)
    local src = source
    local request = pendingRequests[requestId]
    if not request then
        return
    end

    if request.target ~= src then
        return
    end

    if os.time() > request.expiresAt then
        pendingRequests[requestId] = nil
        TriggerClientEvent('esx:showNotification', request.requester, 'Demande expirée')
        return
    end

    pendingRequests[requestId] = nil

    if not accepted then
        TriggerClientEvent('esx:showNotification', request.requester, 'Demande refusée')
        return
    end

    local identifier = getIdentifier(src)
    if not identifier then
        return
    end

    local repData = OutlawDB.getAllReputations(identifier)
    local xTarget = ESX.GetPlayerFromId(src)
    local business = xTarget and xTarget.job and xTarget.job.name or nil
    local companyRep = business and OutlawDB.getBusinessRep(business) or 0
    local contributions = business and OutlawDB.getCompanyContributions(business) or {}
    local policeRecord = OutlawDB.getPoliceRecord(identifier)
    local leaderboard = OutlawDB.getLeaderboard(request.repType, Config.LeaderboardLimit)

    TriggerClientEvent('outlaw_reputation:client:openNuiForViewer', request.requester, {
        targetName = GetPlayerName(src),
        repType = request.repType,
        reputations = repData,
        company = {
            name = business,
            rep = companyRep,
            contributions = contributions
        },
        policeRecord = policeRecord,
        leaderboard = leaderboard,
        repTypes = Config.ReputationTypes
    })
end)

ESX.RegisterServerCallback('outlaw_reputation:cb:getOwnDashboard', function(source, cb)
    local identifier = getIdentifier(source)
    if not identifier then
        cb(nil)
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local business = xPlayer and xPlayer.job and xPlayer.job.name or nil

    cb({
        reputations = OutlawDB.getAllReputations(identifier),
        company = {
            name = business,
            rep = business and OutlawDB.getBusinessRep(business) or 0,
            contributions = business and OutlawDB.getCompanyContributions(business) or {}
        },
        policeRecord = OutlawDB.getPoliceRecord(identifier),
        leaderboard = OutlawDB.getLeaderboard('business', Config.LeaderboardLimit),
        repTypes = Config.ReputationTypes
    })
end)

CreateThread(function()
    while true do
        Wait(300000)
        OutlawDB.processCustomBillingRows(CustomBilling)
    end
end)
