OutlawDB = {}

local function debugLog(msg)
    if Config.Debug then
        print(('[outlaw_reputation][DB] %s'):format(msg))
    end
end

function OutlawDB.fetchPlayerRep(identifier, repType)
    local row = MySQL.single.await(
        'SELECT value FROM outlaw_reputation_players WHERE identifier = ? AND rep_type = ?',
        { identifier, repType }
    )
    return row and tonumber(row.value) or Config.DefaultRep
end

function OutlawDB.setPlayerRep(identifier, repType, value)
    MySQL.insert.await(
        [[
            INSERT INTO outlaw_reputation_players (identifier, rep_type, value)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE value = VALUES(value)
        ]],
        { identifier, repType, value }
    )
end

function OutlawDB.addPlayerRep(identifier, repType, amount)
    MySQL.insert.await(
        [[
            INSERT INTO outlaw_reputation_players (identifier, rep_type, value)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE value = value + VALUES(value)
        ]],
        { identifier, repType, amount }
    )
end

function OutlawDB.getAllReputations(identifier)
    local rows = MySQL.query.await('SELECT rep_type, value FROM outlaw_reputation_players WHERE identifier = ?', { identifier }) or {}
    local result = {}
    for _, row in ipairs(rows) do
        result[row.rep_type] = tonumber(row.value) or 0
    end
    return result
end

function OutlawDB.addBusinessRep(business, amount)
    MySQL.insert.await(
        [[
            INSERT INTO outlaw_reputation_business (business, rep)
            VALUES (?, ?)
            ON DUPLICATE KEY UPDATE rep = rep + VALUES(rep)
        ]],
        { business, amount }
    )
end

function OutlawDB.getBusinessRep(business)
    local row = MySQL.single.await('SELECT rep FROM outlaw_reputation_business WHERE business = ?', { business })
    return row and tonumber(row.rep) or 0
end

function OutlawDB.addContribution(identifier, business, amount)
    MySQL.insert.await(
        [[
            INSERT INTO outlaw_reputation_contribution (identifier, business, rep)
            VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE rep = rep + VALUES(rep)
        ]],
        { identifier, business, amount }
    )
end

function OutlawDB.getCompanyContributions(business)
    return MySQL.query.await(
        'SELECT identifier, rep FROM outlaw_reputation_contribution WHERE business = ? ORDER BY rep DESC LIMIT 50',
        { business }
    ) or {}
end

function OutlawDB.updatePoliceRecord(identifier, knownCrimeRep)
    MySQL.insert.await(
        [[
            INSERT INTO outlaw_police_records (identifier, known_crime_rep, last_update)
            VALUES (?, ?, NOW())
            ON DUPLICATE KEY UPDATE known_crime_rep = VALUES(known_crime_rep), last_update = NOW()
        ]],
        { identifier, knownCrimeRep }
    )
end

function OutlawDB.getPoliceRecord(identifier)
    return MySQL.single.await(
        'SELECT identifier, known_crime_rep, last_update FROM outlaw_police_records WHERE identifier = ?',
        { identifier }
    )
end

function OutlawDB.getLeaderboard(repType, limit)
    return MySQL.query.await(
        'SELECT identifier, value FROM outlaw_reputation_players WHERE rep_type = ? ORDER BY value DESC LIMIT ?',
        { repType, limit }
    ) or {}
end

function OutlawDB.processCustomBillingRows(customCfg)
    if not customCfg or not customCfg.enabled then
        return
    end

    local query = ('SELECT id, `%s` AS identifier, `%s` AS amount FROM `%s` WHERE `%s` = 1 AND (`%s` IS NULL OR `%s` = 0) LIMIT 100')
        :format(customCfg.playerColumn, customCfg.amountColumn, customCfg.table, customCfg.paidColumn, customCfg.processedColumn, customCfg.processedColumn)

    local rows = MySQL.query.await(query)
    if not rows then
        return
    end

    for _, row in ipairs(rows) do
        local rep = math.floor((tonumber(row.amount) or 0) / 100)
        if rep > 0 then
            local xPlayer = ESX.GetPlayerFromIdentifier(row.identifier)
            if xPlayer then
                TriggerEvent('outlaw_rep:add', xPlayer.source, 'business', rep, 'facture personnalisée payée')
            end
        end

        local update = ('UPDATE `%s` SET `%s` = 1 WHERE id = ?'):format(customCfg.table, customCfg.processedColumn)
        MySQL.update.await(update, { row.id })
    end

    debugLog(('Traitement custom billing: %s lignes'):format(#rows))
end
