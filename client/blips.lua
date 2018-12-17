Blips = {}

function Blips.InitBlips()
    for _, coords in pairs(Config.Locations) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 100)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(_U('carwash_name'))
        EndTextCommandSetBlipName(blip)
    end
end
