FrameworkBridge = FrameworkBridge or {}

local detectedFramework
local coreObject

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if resourceStarted('qb-core') then
        return 'qb-core'
    elseif resourceStarted('qbx_core') then
        return 'qbx_core'
    elseif resourceStarted('es_extended') then
        return 'es_extended'
    end

    return 'standalone'
end

function FrameworkBridge.GetName()
    if not detectedFramework then
        detectedFramework = detectFramework()
    end
    return detectedFramework
end

function FrameworkBridge.GetCore()
    if coreObject then
        return coreObject
    end

    local name = FrameworkBridge.GetName()
    if name == 'qb-core' and GetResourceState('qb-core') == 'started' then
        coreObject = exports['qb-core']:GetCoreObject()
    elseif name == 'qbx_core' and GetResourceState('qbx_core') == 'started' then
        coreObject = exports.qbx_core
    elseif name == 'es_extended' and GetResourceState('es_extended') == 'started' then
        coreObject = exports['es_extended']:getSharedObject()
    end

    return coreObject
end

function FrameworkBridge.Notify(src, message, msgType)
    if IsDuplicityVersion() then
        local fw = FrameworkBridge.GetName()
        if fw == 'qb-core' then
            TriggerClientEvent('QBCore:Notify', src, message, msgType or 'primary')
        elseif fw == 'es_extended' then
            TriggerClientEvent('esx:showNotification', src, message)
        else
            TriggerClientEvent('chat:addMessage', src, { args = { '^3ATM', message } })
        end
        return
    end

    -- client-side fallback
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

function FrameworkBridge.Debug(message)
    if Config.Debug then
        print(('[exter-atmrobbery] %s'):format(message))
    end
end

return FrameworkBridge
