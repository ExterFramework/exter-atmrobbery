local state = {
    playerCooldown = {},
    playerSpam = {},
    atmCooldown = {},
    activePull = {}
}

local function nowSec()
    return os.time()
end

local function nowMs()
    return GetGameTimer()
end

local function vectorKey(v)
    if not v then return 'unknown' end
    return ('%.1f:%.1f:%.1f'):format(v.x or 0.0, v.y or 0.0, v.z or 0.0)
end

local function antiSpam(src, action)
    local key = ('%s:%s'):format(src, action)
    local stamp = state.playerSpam[key] or 0
    local current = nowMs()
    if current - stamp < Config.Timers.antiSpamMs then
        return false
    end
    state.playerSpam[key] = current
    return true
end

local function playerIdentifier(src)
    local ids = GetPlayerIdentifiers(src)
    return ids[1] or ('src:%s'):format(src)
end

local function hasAllowedJob(src)
    local fw = FrameworkBridge.GetName()
    if #Config.Security.allowedJobs == 0 and #Config.Security.blockedJobs == 0 then
        return true
    end

    local core = FrameworkBridge.GetCore()
    local jobName
    if fw == 'qb-core' and core then
        local player = core.Functions.GetPlayer(src)
        jobName = player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name
    elseif fw == 'es_extended' and core then
        local player = core.GetPlayerFromId(src)
        local job = player and player.getJob and player.getJob()
        jobName = job and job.name
    end

    if not jobName then
        return #Config.Security.allowedJobs == 0
    end

    for _, blocked in ipairs(Config.Security.blockedJobs) do
        if blocked == jobName then return false end
    end

    if #Config.Security.allowedJobs == 0 then
        return true
    end

    for _, allowed in ipairs(Config.Security.allowedJobs) do
        if allowed == jobName then return true end
    end

    return false
end

local function isPlayerOnCooldown(src)
    local id = playerIdentifier(src)
    local untilTime = state.playerCooldown[id] or 0
    return untilTime > nowSec(), untilTime
end

local function setPlayerCooldown(src)
    state.playerCooldown[playerIdentifier(src)] = nowSec() + Config.Timers.playerCooldownSec
end

local function isATMOnCooldown(coords)
    local key = vectorKey(coords)
    local untilTime = state.atmCooldown[key] or 0
    return untilTime > nowSec()
end

local function setATMCooldown(coords)
    state.atmCooldown[vectorKey(coords)] = nowSec() + Config.Timers.atmCooldownSec
end

local function distanceOK(src, coords, maxDist)
    if not coords then return false end
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local p = GetEntityCoords(ped)
    local dist = #(p - vector3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0))
    return dist <= maxDist
end

local function secureLog(message)
    print(('[exter-atmrobbery] %s'):format(message))
end

RegisterNetEvent('exter_atmrobbery:server:requestUseRope', function(netAtm, claimedCoords)
    local src = source
    if not antiSpam(src, 'requestUseRope') then return end
    if not hasAllowedJob(src) then
        FrameworkBridge.Notify(src, Config.Locale.invalidJob, 'error')
        return
    end

    local cooldown, untilTime = isPlayerOnCooldown(src)
    if cooldown then
        FrameworkBridge.Notify(src, ('%s (%ss)'):format(Config.Locale.cooldown, untilTime - nowSec()), 'error')
        return
    end

    if isATMOnCooldown(claimedCoords) then
        FrameworkBridge.Notify(src, Config.Locale.cooldown, 'error')
        return
    end

    if not distanceOK(src, claimedCoords, Config.Security.maxAttachDistance) then
        FrameworkBridge.Notify(src, Config.Locale.exploitBlocked, 'error')
        secureLog(('Blocked attach attempt from %s (distance)'):format(src))
        return
    end

    if not InventoryBridge.HasItem(src, Config.Items.rope, Config.Items.ropeConsumeCount) then
        FrameworkBridge.Notify(src, Config.Locale.noRope, 'error')
        return
    end

    if not InventoryBridge.RemoveItem(src, Config.Items.rope, Config.Items.ropeConsumeCount) then
        FrameworkBridge.Notify(src, Config.Locale.noRope, 'error')
        return
    end

    state.activePull[src] = { netAtm = netAtm, coords = claimedCoords }
    FrameworkBridge.Notify(src, Config.Locale.ropeUsed, 'success')

    TriggerClientEvent('exter_atmrobbery:client:beginAttach', src)
    TriggerClientEvent('exter_atmrobbery:client:dispatchAlert', -1, claimedCoords)
end)

RegisterNetEvent('exter_atmrobbery:server:attachToVehicle', function(netVeh, coords)
    local src = source
    if not antiSpam(src, 'attachToVehicle') then return end
    if not state.activePull[src] then return end

    local ped = GetPlayerPed(src)
    TriggerClientEvent('exter_atmrobbery:client:syncAttachRope', -1, netVeh, PedToNet(ped))
    state.activePull[src].netVeh = netVeh
    state.activePull[src].coords = coords or state.activePull[src].coords
end)

RegisterNetEvent('exter_atmrobbery:server:pullATM', function()
    local src = source
    if not antiSpam(src, 'pullATM') then return end

    local active = state.activePull[src]
    if not active or not active.netAtm or not active.netVeh then return end

    if not distanceOK(src, active.coords, Config.Security.maxAttachDistance) then
        FrameworkBridge.Notify(src, Config.Locale.exploitBlocked, 'error')
        return
    end

    local atm = NetToObj(active.netAtm)
    if atm == 0 then return end

    local atmCoords = GetEntityCoords(atm)
    local heading = GetEntityHeading(atm)
    local modelName

    for _, m in ipairs(Config.ATM.worldModels) do
        if GetEntityModel(atm) == joaat(m) then
            modelName = m
            break
        end
    end

    local map = modelName and Config.ATM.robbedModels[modelName]
    if not map then return end

    local shell = CreateObjectNoOffset(joaat(map.shell), atmCoords.x, atmCoords.y, atmCoords.z + map.shellZ, true, true, false)
    local console = CreateObjectNoOffset(joaat(map.console), atmCoords.x, atmCoords.y, atmCoords.z + map.consoleZ, true, true, false)
    if shell == 0 or console == 0 then return end

    SetEntityHeading(shell, heading)
    SetEntityHeading(console, heading)
    FreezeEntityPosition(shell, true)
    FreezeEntityPosition(console, true)

    SetEntityCoordsNoOffset(atm, atmCoords.x, atmCoords.y, atmCoords.z - 10.0, false, false, false)

    local netConsole = ObjToNet(console)
    TriggerClientEvent('exter_atmrobbery:client:syncPulledATM', -1, active.netVeh, netConsole)

    SetTimeout(math.random(Config.Timers.pullTravelMsMin, Config.Timers.pullTravelMsMax), function()
        TriggerClientEvent('exter_atmrobbery:client:releaseProp', -1, netConsole)
    end)

    state.activePull[src].netPulledAtm = netConsole
end)

RegisterNetEvent('exter_atmrobbery:server:finishCrack', function(netEntity, playerCoords)
    local src = source
    if not antiSpam(src, 'finishCrack') then return end
    if not distanceOK(src, playerCoords, Config.Security.maxCrackDistance) then
        FrameworkBridge.Notify(src, Config.Locale.exploitBlocked, 'error')
        secureLog(('Blocked crack attempt from %s (distance)'):format(src))
        return
    end

    local entity = NetToObj(netEntity)
    if entity == 0 then return end

    local amount = math.random(Config.Reward.min, Config.Reward.max)
    if not InventoryBridge.AddReward(src, amount) then
        FrameworkBridge.Notify(src, 'Reward failed, inventory full', 'error')
        return
    end

    setPlayerCooldown(src)
    setATMCooldown(GetEntityCoords(entity))

    DeleteEntity(entity)
    TriggerClientEvent('exter_atmrobbery:client:removeRope', -1)
    FrameworkBridge.Notify(src, Config.Locale.gotCash:format(amount), 'success')
end)

RegisterNetEvent('exter_atmrobbery:server:cancelAttach', function()
    local src = source
    state.activePull[src] = nil
    TriggerClientEvent('exter_atmrobbery:client:removeRope', -1)
end)

AddEventHandler('playerDropped', function()
    state.activePull[source] = nil
end)

CreateThread(function()
    FrameworkBridge.Debug(('Framework=%s, Inventory=%s, Dispatch=%s'):format(
        FrameworkBridge.GetName(),
        InventoryBridge.GetName(),
        DispatchBridge.GetName()
    ))
end)
