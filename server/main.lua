ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
    ESX = obj
end)

ESX.RegisterServerCallback('blarglebikini:purchaseWash', function(source, callback)
    if Config.Price > 0 then
        local player = ESX.GetPlayerFromId(source)

        if player.getMoney() < Config.Price then
            return callback(false)
        end
        
        player.removeMoney(Config.Price)
    end

    return callback(true)
end)
