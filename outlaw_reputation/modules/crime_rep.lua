CrimeRep = {}

function CrimeRep.addCrime(playerId, amount, reason)
    return OutlawRep.addRep(playerId, 'crime', amount, reason or 'activité criminelle', 0)
end

function CrimeRep.snapshotToPolice(playerId)
    local identifier = ESX.GetPlayerFromId(playerId)
    if not identifier then
        return false
    end
    local crime = OutlawRep.getRep(playerId, 'crime')
    OutlawDB.updatePoliceRecord(identifier.getIdentifier(), crime)
    return true
end
