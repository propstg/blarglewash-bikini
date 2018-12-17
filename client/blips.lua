print "here?"
Blips = {}

function Blips.InitBlips()
    for i = 1, #Config.Locations do
        local coords = Config.Locations[i]
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 100)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(_U('carwash_name'))
        EndTextCommandSetBlipName(blip)
    end
end
