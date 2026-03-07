Config = Config or {}

Config.ViewPermissions = {
    mechanic_boss = {
        job = 'mechanic',
        grade = 4,
        canSee = { 'business' }
    },
    gang_leader = {
        job = 'gang',
        grade = 3,
        canSee = { 'crime' }
    },
    police_chief = {
        job = 'police',
        grade = 5,
        canSee = { 'crime', 'police' }
    }
}
