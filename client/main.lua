ESX = nil

Blips.InitBlips()

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while true do
        Citizen.Wait(10)

        if not Wash.IsWashing() then
            local playerPed = PlayerPedId()

            if IsPedInAnyVehicle(playerPed, true) then
                for i = 1, #Config.Locations do
                    handleLocation(i, playerPed)
                end
            else
                Citizen.Wait(1000)
            end
        end
    end
end)

function handleLocation(locationIndex, playerPed)
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local coords = Config.Locations[locationIndex];
    
    if GetDistanceBetweenCoords(GetEntityCoords(playerPed), coords.x, coords.y, coords.z, true) < Config.DistanceFromSpawnLocation then
        if Config.Price > 0 then
            ESX.ShowHelpNotification(_U('hint_fee', Config.Price))
        else
            ESX.ShowHelpNotification(_U('hint_free'))
        end

        if IsControlJustPressed(1, 86) then
            purchaseWash(locationIndex, vehicle)
        end
    end
end

function purchaseWash(locationIndex, vehicle)
    ESX.TriggerServerCallback('blarglebikini:purchaseWash', function(isPurchaseSuccessful)
        if isPurchaseSuccessful then
            Wash.DoWash(locationIndex, vehicle)
        else
            ESX.ShowNotification(_U('not_enough_money'))
        end
    end)
end
