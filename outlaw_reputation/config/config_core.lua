Config = Config or {}

Config.Debug = false
Config.CommandName = 'outlawrep'
Config.DefaultRep = 0

Config.AntiAbuse = {
    dailyCaps = {
        business = 250,
        crime = 200,
        police = 100,
        gang = 180
    },
    interactionLimit = {
        maxPerSourceTarget = 10,
        windowSeconds = 3600
    },
    decay = {
        enabled = true,
        threshold = 5,
        factor = 0.85
    }
}

Config.RequestTimeout = 25
Config.LeaderboardLimit = 20
Config.CompanyJobs = {
    mechanic = true,
    taxi = true,
    police = true,
    ambulance = true
}
