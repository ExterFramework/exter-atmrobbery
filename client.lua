local state = {
    rope = nil,
    vehicle = nil,
    attachActive = false,
    targetResource = nil
}

local function loadModel(name)
    local hash = joaat(name)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasModelLoaded(hash)
end

local function loadAnim(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 10000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function showHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, Config.Timers.subtitleLengthMs)
end

local function getClosestEntityByModels(models, radius)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for _, model in ipairs(models) do
        local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, joaat(model), false, false, false)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity, model
        end
    end
    return nil, nil
end

local function detectTarget()
    if Config.Target ~= 'auto' then return Config.Target end
    if GetResourceState('qb-target') == 'started' then return 'qb-target' end
    if GetResourceState('ox_target') == 'started' then return 'ox_target' end
    return 'none'
end

local function addTargetZones()
    state.targetResource = detectTarget()
    if Config.InteractionMode ~= 'target' or state.targetResource == 'none' then return end

    local worldModels, crackedModels = {}, {}
    for _, m in ipairs(Config.ATM.worldModels) do
        worldModels[#worldModels + 1] = joaat(m)
    end
    for _, modelData in pairs(Config.ATM.robbedModels) do
        crackedModels[#crackedModels + 1] = joaat(modelData.console)
    end

    if state.targetResource == 'qb-target' then
        exports['qb-target']:AddTargetModel(worldModels, {
            options = {
                {
                    label = Config.Locale.attachRope,
                    icon = Config.TargetOptions.icon,
                    action = function(entity)
                        TriggerServerEvent('exter_atmrobbery:server:requestUseRope', ObjToNet(entity), GetEntityCoords(PlayerPedId()))
                    end
                }
            },
            distance = Config.TargetOptions.distance
        })
        exports['qb-target']:AddTargetModel(crackedModels, {
            options = {
                {
                    label = Config.Locale.crack,
                    icon = Config.TargetOptions.icon,
                    action = function(entity)
                        TriggerEvent('exter_atmrobbery:client:startCrack', entity)
                    end
                }
            },
            distance = Config.TargetOptions.distance
        })
    elseif state.targetResource == 'ox_target' then
        exports.ox_target:addModel(worldModels, {
            {
                name = 'exter_atm_attach',
                icon = Config.TargetOptions.icon,
                label = Config.Locale.attachRope,
                distance = Config.TargetOptions.distance,
                onSelect = function(data)
                    TriggerServerEvent('exter_atmrobbery:server:requestUseRope', ObjToNet(data.entity), GetEntityCoords(PlayerPedId()))
                end
            }
        })
        exports.ox_target:addModel(crackedModels, {
            {
                name = 'exter_atm_crack',
                icon = Config.TargetOptions.icon,
                label = Config.Locale.crack,
                distance = Config.TargetOptions.distance,
                onSelect = function(data)
                    TriggerEvent('exter_atmrobbery:client:startCrack', data.entity)
                end
            }
        })
    end
end

local function createRope()
    RopeLoadTextures()
    state.rope = AddRope(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.0, 1, 7.0, 1.0, false, false, false, 1.0, false, 0)
    return state.rope ~= nil
end

RegisterNetEvent('exter_atmrobbery:client:beginAttach', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        vehicle = GetClosestVehicle(GetEntityCoords(ped), Config.Security.maxVehicleDistance, 0, 70)
    end
    if vehicle == 0 then return end

    state.vehicle = vehicle
    if not loadAnim('mini@repair') then return end
    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 2.0, 2.0, Config.Timers.attachProgressMs, 1, 0.0, false, false, false)

    Wait(Config.Timers.attachProgressMs)
    ClearPedTasks(ped)

    createRope()
    state.attachActive = true

    TriggerServerEvent('exter_atmrobbery:server:attachToVehicle', VehToNet(vehicle), GetEntityCoords(ped))

    CreateThread(function()
        while state.attachActive do
            Wait(0)
            if Config.InteractionMode == 'drawtext' then
                showHelpText(Config.Locale.pullHint)
            end

            if IsControlJustPressed(0, 73) then
                state.attachActive = false
                TriggerServerEvent('exter_atmrobbery:server:cancelAttach')
            elseif IsControlJustPressed(0, 38) then
                state.attachActive = false
                TriggerServerEvent('exter_atmrobbery:server:pullATM')
            end
        end
    end)
end)

RegisterNetEvent('exter_atmrobbery:client:syncAttachRope', function(netVeh, netPed)
    if not state.rope then createRope() end
    local veh = NetToEnt(netVeh)
    local ped = NetToPed(netPed)
    if veh == 0 or ped == 0 then return end

    AttachEntitiesToRope(
        state.rope,
        veh,
        ped,
        GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.3, 0.5),
        GetPedBoneCoords(ped, 6286, 0.0, 0.0, 0.0),
        7.0,
        false,
        false,
        nil,
        nil
    )
end)

RegisterNetEvent('exter_atmrobbery:client:syncPulledATM', function(netVeh, netProp)
    if not state.rope then return end
    local veh = NetToEnt(netVeh)
    local prop = NetToObj(netProp)
    if veh == 0 or prop == 0 then return end
    local propCoords = GetEntityCoords(prop)
    AttachEntitiesToRope(
        state.rope,
        veh,
        prop,
        GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.3, 0.5),
        propCoords.x,
        propCoords.y,
        propCoords.z + 1.0,
        7.0,
        false,
        false,
        nil,
        nil
    )
end)

RegisterNetEvent('exter_atmrobbery:client:releaseProp', function(netProp)
    local prop = NetToObj(netProp)
    if prop ~= 0 then
        FreezeEntityPosition(prop, false)
        SetObjectPhysicsParams(prop, 170.0, -1.0, 30.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0)
    end
end)

RegisterNetEvent('exter_atmrobbery:client:removeRope', function()
    if state.rope then
        DeleteRope(state.rope)
        state.rope = nil
    end
end)

RegisterNetEvent('exter_atmrobbery:client:startCrack', function(explicitEntity)
    local atmEntity = explicitEntity
    if not atmEntity or atmEntity == 0 then
        atmEntity = getClosestEntityByModels({ 'loq_fleeca_atm_console', 'loq_atm_02_console', 'loq_atm_03_console' }, 4.0)
    end
    if not atmEntity or atmEntity == 0 then return end

    local ped = PlayerPedId()
    if not loadAnim('mini@repair') then return end
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 2.0, 2.0, Config.Timers.crackProgressMs, 1, 0.0, false, false, false)
    Wait(Config.Timers.crackProgressMs)
    ClearPedTasks(ped)

    TriggerServerEvent('exter_atmrobbery:server:finishCrack', ObjToNet(atmEntity), GetEntityCoords(ped))
end)

RegisterNetEvent('exter_atmrobbery:client:dispatchAlert', function(coords)
    DispatchBridge.SendClientAlert(coords)
end)

CreateThread(function()
    for _, modelData in pairs(Config.ATM.robbedModels) do
        loadModel(modelData.shell)
        loadModel(modelData.console)
    end

    addTargetZones()

    if Config.InteractionMode == 'drawtext' then
        CreateThread(function()
            while true do
                local sleep = 1000
                local entity = getClosestEntityByModels(Config.ATM.worldModels, 2.0)
                if entity then
                    sleep = 0
                    showHelpText(('%s [%s]'):format(Config.Locale.attachRope, 'E'))
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('exter_atmrobbery:server:requestUseRope', ObjToNet(entity), GetEntityCoords(PlayerPedId()))
                    end
                end
                Wait(sleep)
            end
        end)
    end
end)
