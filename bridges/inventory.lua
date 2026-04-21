InventoryBridge = InventoryBridge or {}

local detectedInventory

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectInventory()
    if Config.Inventory ~= 'auto' then
        return Config.Inventory
    end

    if resourceStarted('ox_inventory') then
        return 'ox_inventory'
    elseif resourceStarted('qb-inventory') then
        return 'qb-inventory'
    elseif resourceStarted('qs-inventory') then
        return 'qs-inventory'
    elseif resourceStarted('esx_inventory') then
        return 'esx_inventory'
    end

    return 'standalone'
end

function InventoryBridge.GetName()
    if not detectedInventory then
        detectedInventory = detectInventory()
    end
    return detectedInventory
end

function InventoryBridge.HasItem(src, item, count)
    count = count or 1
    local inv = InventoryBridge.GetName()

    if inv == 'ox_inventory' then
        local total = exports.ox_inventory:Search(src, 'count', item)
        return (total or 0) >= count
    elseif inv == 'qb-inventory' then
        local amount = exports['qb-inventory']:GetItemCount(src, item) or 0
        return amount >= count
    elseif inv == 'qs-inventory' then
        local amount = exports['qs-inventory']:GetItemTotalAmount(src, item) or 0
        return amount >= count
    end

    local fw = FrameworkBridge.GetName()
    local core = FrameworkBridge.GetCore()
    if fw == 'qb-core' and core then
        local player = core.Functions.GetPlayer(src)
        if not player then return false end
        local entry = player.Functions.GetItemByName(item)
        return entry and (entry.amount or 0) >= count
    elseif fw == 'es_extended' and core then
        local player = core.GetPlayerFromId(src)
        if not player then return false end
        local entry = player.getInventoryItem(item)
        return entry and (entry.count or 0) >= count
    end

    return true -- standalone fallback
end

function InventoryBridge.RemoveItem(src, item, count)
    count = count or 1
    local inv = InventoryBridge.GetName()

    if inv == 'ox_inventory' then
        return exports.ox_inventory:RemoveItem(src, item, count)
    elseif inv == 'qb-inventory' then
        return exports['qb-inventory']:RemoveItem(src, item, count, false, 'atm-robbery')
    elseif inv == 'qs-inventory' then
        return exports['qs-inventory']:RemoveItem(src, item, count)
    end

    local fw = FrameworkBridge.GetName()
    local core = FrameworkBridge.GetCore()
    if fw == 'qb-core' and core then
        local player = core.Functions.GetPlayer(src)
        return player and player.Functions.RemoveItem(item, count)
    elseif fw == 'es_extended' and core then
        local player = core.GetPlayerFromId(src)
        if not player then return false end
        player.removeInventoryItem(item, count)
        return true
    end

    return true
end

function InventoryBridge.AddReward(src, amount)
    local rewardItem = Config.Reward.normalCash and Config.Reward.normalCashName or Config.Reward.blackMoneyName
    local inv = InventoryBridge.GetName()

    if inv == 'ox_inventory' then
        return exports.ox_inventory:AddItem(src, rewardItem, amount)
    end

    local fw = FrameworkBridge.GetName()
    local core = FrameworkBridge.GetCore()
    if fw == 'qb-core' and core then
        local player = core.Functions.GetPlayer(src)
        return player and player.Functions.AddItem(rewardItem, amount)
    elseif fw == 'es_extended' and core then
        local player = core.GetPlayerFromId(src)
        if not player then return false end
        if Config.Reward.normalCash then
            player.addMoney(amount)
        else
            player.addAccountMoney('black_money', amount)
        end
        return true
    end

    return true
end

return InventoryBridge
