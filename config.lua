Config = {}

-- auto | qb-core | es_extended | qbx_core | standalone
Config.Framework = 'auto'
-- auto | qb-inventory | qs-inventory | ox_inventory | esx_inventory | standalone
Config.Inventory = 'auto'
-- auto | ps-dispatch | cd_dispatch | exter-dispatch | standalone
Config.Dispatch = 'auto'
-- auto | qb-target | ox_target | none
Config.Target = 'auto'
-- target | drawtext
Config.InteractionMode = 'target'

Config.Debug = true
Config.Locale = {
    crack = 'Crack ATM',
    attachRope = 'Attach Rope To ATM',
    attachToCar = 'Attach Rope To Vehicle',
    removeRope = 'Remove Rope (X)',
    startPull = 'Start Pull (E)',
    pullHint = 'Press E to attach ATM | Press X to remove rope',
    crackProgress = 'Cracking ATM',
    noRope = 'You do not have rope',
    ropeUsed = 'You used rope',
    invalidJob = 'You cannot do this',
    cooldown = 'ATM is cooling down',
    exploitBlocked = 'Action blocked (security)',
    gotCash = 'You got $%s'
}

Config.ATM = {
    worldModels = {
        'prop_atm_02',
        'prop_atm_03',
        'prop_fleeca_atm'
    },
    robbedModels = {
        ['prop_atm_02'] = { shell = 'loq_atm_02_des', console = 'loq_atm_02_console', shellZ = 0.35, consoleZ = 0.55 },
        ['prop_atm_03'] = { shell = 'loq_atm_03_des', console = 'loq_atm_03_console', shellZ = 0.35, consoleZ = 0.65 },
        ['prop_fleeca_atm'] = { shell = 'loq_fleeca_atm_des', console = 'loq_fleeca_atm_console', shellZ = 0.35, consoleZ = 0.65 }
    }
}

Config.Reward = {
    normalCash = false,
    min = 5000,
    max = 10000,
    normalCashName = 'cash',
    blackMoneyName = 'black_money'
}

Config.Items = {
    rope = 'rope',
    ropeConsumeCount = 1
}

Config.Timers = {
    attachProgressMs = 7000,
    crackProgressMs = 7000,
    pullTravelMsMin = 25000,
    pullTravelMsMax = 45000,
    subtitleLengthMs = 2000,
    playerCooldownSec = 300,
    atmCooldownSec = 600,
    antiSpamMs = 1000
}

Config.Security = {
    requiredPolice = 0,
    allowedJobs = {}, -- empty = all except blockedJobs
    blockedJobs = {},
    maxAttachDistance = 8.0,
    maxCrackDistance = 4.5,
    maxVehicleDistance = 8.0,
    strictEntityOwnership = false
}

Config.TargetOptions = {
    icon = 'fas fa-recycle',
    distance = 2.5
}

Config.DispatchPayload = {
    title = 'ATM Robbery',
    message = 'Suspicious activity at ATM',
    code = '10-90'
}

Config.Logging = {
    enabled = true,
    webhook = '' -- optional
}
