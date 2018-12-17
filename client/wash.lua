Wash = {}

Wash.isWashing = false
Wash.peds = {}

function Wash.DoWash(locationIndex, vehicle)
    Citizen.CreateThread(function()
        Wash.isWashing = true

        local location = Config.Locations[locationIndex]
        
        Wash.peds = Wash.InitPeds()
        Wash.LoadCarWashAttendentModel()
        Wash.LoadAnimation()

        SetVehicleEngineOn(vehicle, false, false, true)

        Wash.CreatePedsAndWalkToPositionsAsync(location, vehicle)
        Wash.WaitForWashAttendantsToArrive()

        Wash.WashCar(vehicle)

        SetVehicleEngineOn(vehicle, true, false, true)

        Wash.WalkBackToBaseAndDeletePedsAsync(location)
        Wash.WaitForWashAttendantsToArrive()

        Wash.isWashing = false
    end)
end

function Wash.InitPeds()
    local newPeds = {}

    for _, pedName in pairs(Config.PedNames) do
        newPeds[pedName] = Wash.InitPedData()
    end

    return newPeds
end

function Wash.InitPedData()
    return {arrived = false, ped = nil, rag = nil}
end

function Wash.LoadCarWashAttendentModel()
    RequestModel(GetHashKey(Config.PedModel))
    while not HasModelLoaded(GetHashKey(Config.PedModel)) do
        RequestModel(GetHashKey(Config.PedModel))
        Citizen.Wait(1000)
    end
end

function Wash.LoadAnimation()
    RequestAnimDict(Config.PedAnimationDict)
    while not HasAnimDictLoaded(Config.PedAnimationDict) do
        Citizen.Wait(0)
    end
end

function Wash.CreatePedsAndWalkToPositionsAsync(location, vehicle)
    for _, pedName in pairs(Config.PedNames) do
        Wash.CreatePedAndWalkToPositionAsync(location, vehicle, pedName)
    end
end

function Wash.CreatePedAndWalkToPositionAsync(location, vehicle, sideName)
    Citizen.CreateThread(function()
        local ped = Wash.CreateCarWashAttendant(location)
        local initX, initY, initZ = table.unpack(GetEntityCoords(ped))

        Wash.peds[sideName].ped = ped
        Wash.peds[sideName].arrived = false

        local prop = CreateObject(GetHashKey(Config.RagPropName), initX, initY, initZ + 0.2, true, true, true)
        Wash.peds[sideName].rag = prop

        local boneIndex = GetPedBoneIndex(ped, 57005)
        AttachEntityToEntity(prop, ped, boneIndex, 0.12, 0.028, -0.040, 10.0, 175.0, 0.0, true, true, false, true, 1, true)

        local doorX, doorY, doorZ = table.unpack(Wash.GetDoorPosition(vehicle, sideName))
        Wash.WalkPedToCoords(sideName, doorX, doorY, doorZ, 2.5)
        Wash.FaceCoords(ped, doorX, doorY, doorZ)
    end)
end

function Wash.CreateCarWashAttendant(location)
    return CreatePed(4, Config.PedModel, location.x, location.y, location.z, location.heading, true, false)
end

function Wash.GetDoorPosition(vehicle, sideName)
    return GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, Config.BoneNames[sideName]))
end

function Wash.FaceCoords(ped, x, y, z)
    ClearPedTasks(ped)
    local p = GetEntityCoords(ped, true)
    local dx = x - p.x
    local dy = y - p.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(ped, heading)
end

function Wash.WaitForWashAttendantsToArrive()
    while not (Wash.peds.leftSide.arrived and Wash.peds.rightSide.arrived and Wash.peds.middle.arrived) do
        Citizen.Wait(100)
    end
end

function Wash.WashCar(vehicle)
    Wash.PlayWashAnimations()

    local dirtInterval = GetVehicleDirtLevel(vehicle) / 10.0

    for i = 0, 10 do
        Wash.ActuallyWashCar(vehicle, dirtInterval)
        Citizen.Wait(1000)
    end
end

function Wash.PlayWashAnimations()
    for _, ped in pairs(Wash.peds) do
        TaskPlayAnim(ped.ped, Config.PedAnimationDict, Config.PedAnimation, 1.0, -1.0, -1, 1, 1, true, true, true)
    end
end

function Wash.ActuallyWashCar(vehicle, amountToClean)
    WashDecalsFromVehicle(vehicle, 0.1)
    SetVehicleDirtLevel(vehicle, GetVehicleDirtLevel(vehicle) - amountToClean)
end

function Wash.WalkBackToBaseAndDeletePedsAsync(location)
    for _, pedName in pairs(Config.PedNames) do
        Wash.peds[pedName].arrived = false
        Wash.WalkBackToBaseAndDeletePedAsync(location, pedName)
    end
end

function Wash.WalkBackToBaseAndDeletePedAsync(location, sideName)
    Citizen.CreateThread(function()
        Wash.WalkPedToCoords(sideName, location.x, location.y, location.z, 1.0)
        DeletePed(Wash.peds[sideName].ped)
        DeleteObject(Wash.peds[sideName].rag)
    end)
end

function Wash.WalkPedToCoords(sideName, x, y, z, allowedDistance)
    local ped = Wash.peds[sideName].ped
    TaskGoToCoordAnyMeans(ped, x, y, z, 1.0, 0, 0, 786603, 1.0)

    local lastDistance = 1000
    local timesAtLastDistance = 0

    while true do
        Citizen.Wait(100)
        local coords = GetEntityCoords(ped, true)
        local dist = Vdist2(coords.x, coords.y, coords.z, x, y, z)

        if (lastDistance == dist) then
            timesAtLastDistance = timesAtLastDistance + 1
        end

        if (dist < allowedDistance -- legit arrived
            or (timesAtLastDistance > 10 and lastDistance < 5.0) -- stuck close to the end point
            or IsPedFleeing(ped)
            or IsPedDeadOrDying(ped, 1)
           ) then
            break
        end

        lastDistance = dist
    end

    Wash.peds[sideName].arrived = true
end

function Wash.IsWashing()
    return Wash.isWashing
end
