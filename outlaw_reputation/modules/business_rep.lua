BusinessRep = {}

function BusinessRep.addForPlayer(playerId, amount, reason)
    return OutlawRep.addRep(playerId, 'business', amount, reason or 'action business', 0)
end

function BusinessRep.getCompanyLeaderboard(limit)
    return OutlawDB.getLeaderboard('business', limit or Config.LeaderboardLimit)
end
