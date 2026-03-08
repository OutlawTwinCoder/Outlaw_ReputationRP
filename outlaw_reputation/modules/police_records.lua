PoliceRecords = {}

function PoliceRecords.getKnownRecordByPlayerId(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        return nil
    end
    return OutlawDB.getPoliceRecord(xPlayer.getIdentifier())
end

function PoliceRecords.updateKnownCrime(identifier, value)
    OutlawDB.updatePoliceRecord(identifier, value)
end
