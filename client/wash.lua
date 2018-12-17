Wash = {}

function Wash.InitPedData() return {arrived = false, ped = nil, rag = nil} end

Wash.peds = {
    leftSide = Wash.InitPedData(),
    rightSide = Wash.InitPedData(),
    middle = Wash.InitPedData(),
}

function Wash.DoWash()
    Citizen.CreateThread(function()
	    Wash.peds.leftSide.arrived = false
	    Wash.peds.rightSide.arrived = false
	    Wash.peds.middle.arrived = false

	    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
	    SetVehicleEngineOn(vehicle, false, false, true)

	    Wash.LoadCarWashAttendentModel()
	    Wash.LoadAnimation()

        for _, pedName in pairs(Config.PedNames) do
            Wash.CreatePedAndWalkToPosition(vehicle, pedName)
	    end
	     Wash.CreateCarWashAttendant()

	    washCar(vehicle)

	    SetVehicleEngineOn(vehicle, true, false, true)

        for _, pedName in pairs(Config.PedNames) do
            walkBackToBaseAndDeletePed(pedName)
	    end
    end)
end, false)

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

function Wash.CreatePedAndWalkToPosition(vehicle, sideName)
    Citizen.CreateThread(function()
        local ped = Wash.CreateCarWashAttendant()
        local initX, initY, initZ = table.unpack(GetEntityCoords(ped))

        Wash.peds[sideName].ped = ped
	    Wash.peds[sideName].arrived = false

        local prop = CreateObject(GetHashKey(Config.RagPropName), initX, initY, initZ + 0.2, true, true, true)
	    Wash.peds[sideName].rag = prop

        local boneIndex = GetPedBoneIndex(ped, 57005)
        AttachEntityToEntity(prop, ped, boneIndex, 0.12, 0.028, -0.040, 10.0, 175.0, 0.0, true, true, false, true, 1, true)

        local x, y, z = table.unpack(Wash.GetDoorPosition(vehicle, sideName))
        Wash.WalkPedToCoords(ped, x, y, z, 2.5)
        Wash.FaceCoords(ped, x, y, z)

        Wash.peds[sideName].arrived = true
    end)
end

function Wash.CreateCarWashAttendant()
    return CreatePed(4, Config.PedModel, Config.SpawnLocation.x, Config.SpawnLocation.y, Config.SpawnLocation.z, Config.SpawnLocation.heading, true, false)
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
    while not (peds.leftSide.arrived and peds.rightSide.arrived and peds.middle.arrived) do
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
    for _, ped in pairs(peds) do
        TaskPlayAnim(ped, Config.PedAnimationDict, Config.PedAnimation, 1.0, -1.0, -1, 1, 1, true, true, true)
    end
end

function Wash.ActuallyWashCar(vehicle, amountToClean)
    WashDecalsFromVehicle(vehicle, 0.1)
    SetVehicleDirtLevel(vehicle, GetVehicleDirtLevel(vehicle) - amountToClean)
end

function Wash.WalkBackToBaseAndDeletePed(sideName)
    Citizen.CreateThread(function()
        Wash.WalkPedToCoords(Wash.peds[sideName].ped, Config.SpawnLocation.x, Config.SpawnLocation.y, Config.SpawnLocation.z, 1.0)
        DeletePed(peds[sideName].ped)
        DeleteObject(peds[sideName].rag)
    end)
end

function Wash.WalkPedToCoords(ped, x, y, z, allowedDistance)
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

        if (dist < allowedDistance or (timesAtLastDistance > 10 and lastDistance < 5.0)) then
            break
        end

        lastDistance = dist
    end
end