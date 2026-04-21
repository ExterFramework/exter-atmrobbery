DispatchBridge = DispatchBridge or {}

local detectedDispatch

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectDispatch()
    if Config.Dispatch ~= 'auto' then
        return Config.Dispatch
    end

    if resourceStarted('ps-dispatch') then
        return 'ps-dispatch'
    elseif resourceStarted('cd_dispatch') then
        return 'cd_dispatch'
    elseif resourceStarted('exter-dispatch') then
        return 'exter-dispatch'
    end

    return 'standalone'
end

function DispatchBridge.GetName()
    if not detectedDispatch then
        detectedDispatch = detectDispatch()
    end
    return detectedDispatch
end

function DispatchBridge.SendClientAlert(coords)
    local name = DispatchBridge.GetName()
    if name == 'ps-dispatch' then
        exports['ps-dispatch']:ATMRobbery()
    elseif name == 'cd_dispatch' then
        TriggerEvent('cd_dispatch:AddNotification', {
            job_table = { 'police' },
            coords = coords,
            title = Config.DispatchPayload.title,
            message = Config.DispatchPayload.message,
            flash = 0,
            unique_id = tostring(math.random(100000, 999999))
        })
    elseif name == 'exter-dispatch' then
        TriggerEvent('exter-dispatch:client:sendAlert', {
            code = Config.DispatchPayload.code,
            title = Config.DispatchPayload.title,
            message = Config.DispatchPayload.message,
            coords = coords
        })
    end
end

return DispatchBridge
