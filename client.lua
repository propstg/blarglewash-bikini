--config
local boneNames = {leftSide = 'seat_dside_f', rightSide = 'seat_pside_f', middle = 'bonnet'}
local model = "s_f_y_hooker_01"
local animation = 'amb@world_human_maid_clean@idle_a'
local an = 'idle_b'
local base = {x = 1981.5738, y = 3058.1286, z = 47.1975, heading = 310.71}
local DICT = 'core'
local ropePos = {x = 1985.5, y = 3062.5, z = 46.75}

--variables
local peds = {
    leftSide = {
        arrived = false, 
	ped = nil,
	rag = nil
    },
    rightSide = {
        arrived = false, 
	ped = nil,
	rag = nil
    },
    middle = {
        arrived = false, 
	ped = nil,
	rag = nil,
	rope = nil
    }
}
local rope = nil

RegisterCommand('rope', function (source, args)
    TriggerEvent('chatMessage', source, "test", "test")
    	local ped = GetPlayerPed(PlayerId())
	local pedPos = GetEntityCoords(ped, false)
	RopeLoadTextures()
	local rope = AddRope(pedPos.x, pedPos.y, pedPos.z, 0.0, 0.0, 0.0, 10.0, 2, 10.0, 1.0, 0, 0, 0, 0, 0, 0, 0)
	AttachRopeToEntity(rope, ped, pedPos.x, pedPos.y, pedPos.z, 1)
    Citizen.Wait(5000)
    DeleteRope(rope)

end)

Citizen.CreateThread(function()
    initBaseSpray()
    UseParticleFxAssetNextCall(DICT)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x + 2, base.y, base.z, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x, base.y, base.z, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x - 2, base.y, base.z, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x, base.y + 2, base.z, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x, base.y - 2, base.z, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x, base.y, base.z + 2, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_splash_plane_trail_mist', base.x, base.y, base.z - 2, 90.0, 0.0, 0.0, 1.0, false, false, false, false)
    --StartParticleFxLoopedAtCoord('water_cannon_spray', base.x, base.y, base.z, 0.0, 0.0, 0.0, 1.5, false, false, false, false)
end)

RegisterCommand('wash', function (source, args)
    TriggerEvent('chatMessage', source, "test", "test")

    Citizen.CreateThread(function()
	    peds.leftSide.arrived = false
	    peds.rightSide.arrived = false
	    peds.middle.arrived = false

	    local vehicle = GetVehiclePedIsUsing(PlayerPedId())
	    SetVehicleEngineOn(vehicle, false, false, true)

	    loadCarWashAttendentModel()
	    loadAnimation()

	    createPedAndWalkToPosition(vehicle, 'leftSide')
	    createPedAndWalkToPosition(vehicle, 'rightSide')
	    createPedAndWalkToPosition(vehicle, 'middle')
	    waitForWashAttendantsToArrive()

	    washCar(vehicle)

	    SetVehicleEngineOn(vehicle, true, false, true)

	    walkBackToBaseAndDeletePed('leftSide')
	    walkBackToBaseAndDeletePed('rightSide')
	    walkBackToBaseAndDeletePed('middle')
    end)
end, false)

function initBaseSpray()
    RequestNamedPtfxAsset(DICT)
    while not HasNamedPtfxAssetLoaded(DICT) do
        Citizen.Wait(0)
    end
end

function loadCarWashAttendentModel()
    RequestModel(GetHashKey(model))
    while not HasModelLoaded(GetHashKey(model)) do
        RequestModel(GetHashKey(model))
        Citizen.Wait(1000)
    end
end

function loadAnimation()
    RequestAnimDict(animation)
    while not HasAnimDictLoaded(animation) do
        Citizen.Wait(0)
    end
end

function createPedAndWalkToPosition(vehicle, sideName)
    Citizen.CreateThread(function()
        local ped = createCarWashAttendant()
        peds[sideName].ped = ped
	peds[sideName].arrived = false

        local initX, initY, initZ = table.unpack(GetEntityCoords(ped))

	if (sideName == 'middle') then
		print ('creating rope')
            RopeLoadTextures()

            local dx = initX - ropePos.x
            local dy = initY - ropePos.y

            peds.middle.rope = AddRope(ropePos.x, ropePos.y, ropePos.z-5.0, 0.0, 0.0, 0.0, 15.0, 2, 15.0, 1.0, 0, 0, 0, 0, 0, 0, 0) 
            AttachRopeToEntity(peds.middle.rope, ped, initX, initY, initZ, false)
	    local vertexCount = GetRopeVertexCount(peds.middle.rope) - 1
	    PinRopeVertex(peds.middle.rope, vertexCount, ropePos.x, ropePos.y, ropePos.z)
	    ActivatePhysics(peds.middle.rope)
	end

        local prop = CreateObject(GetHashKey('prop_rag_01'), initX, initY, initZ + 0.2, true, true, true)
	peds[sideName].rag = prop

        local boneIndex = GetPedBoneIndex(ped, 57005)
        AttachEntityToEntity(prop, ped, boneIndex, 0.12, 0.028, -0.040, 10.0, 175.0, 0.0, true, true, false, true, 1, true)

        local x, y, z = table.unpack(getDoorPosition(vehicle, sideName))
	walkPedToCoords(ped, x, y, z, 2.5)
	faceCoords(ped, x, y, z)

        peds[sideName].arrived = true
    end)
end

function createCarWashAttendant()
    return CreatePed(4, model, base.x, base.y, base.z, base.heading, true, false)
end

function getDoorPosition(vehicle, sideName)
    local boneName = boneNames[sideName]
    local vehicleDoor = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, boneName))
    return vehicleDoor
end

function faceCoords(ped, x, y, z)
    ClearPedTasks(ped)
    local p = GetEntityCoords(ped, true)

    local dx = x - p.x
    local dy = y - p.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(ped, heading )
end

function waitForWashAttendantsToArrive()
    while not (peds.leftSide.arrived and peds.rightSide.arrived and peds.middle.arrived) do
        Citizen.Wait(100)
    end
end

function washCar(vehicle)
    playWashAnimations()

    local dirtLevel = GetVehicleDirtLevel(vehicle)
    local dirtInterval = dirtLevel / 10.0

    local i = 0
    while i < 10 do
	actuallyWashCar(vehicle, dirtInterval)

        Citizen.Wait(1000)
        i = i + 1
    end
end

function playWashAnimations()
    TaskPlayAnim(peds.leftSide.ped, animation, an, 1.0, -1.0, -1, 1, 1, true, true, true)
    TaskPlayAnim(peds.rightSide.ped, animation, an, 1.0, -1.0, -1, 1, 1, true, true, true)
    TaskPlayAnim(peds.middle.ped, animation, an, 1.0, -1.0, -1, 1, 1, true, true, true)
end

function actuallyWashCar(vehicle, amountToClean)
    WashDecalsFromVehicle(vehicle, 0.1)

    local dirtLevel = GetVehicleDirtLevel(vehicle)
    SetVehicleDirtLevel(vehicle, dirtLevel - amountToClean)
end

function walkBackToBaseAndDeletePed(sideName)
    Citizen.CreateThread(function()
        walkPedToCoords(peds[sideName].ped, base.x, base.y, base.z, 1.0)
        DeletePed(peds[sideName].ped)
	DeleteObject(peds[sideName].rag)

	if (sideName == 'middle') then
		print('deleting rope')
	    RopeUnloadTextures()
	    DeleteRope(peds[sideName].rope)
	    peds[sideName].rope = nil
	end
    end)
end

function walkPedToCoords(ped, x, y, z, allowedDistance)
    SetPedMovementClipset(ped, 'MOVE_M@FEMME@', 0.0)
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
