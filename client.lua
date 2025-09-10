local playerHealth = 100
local lastHitTime = {}
local healthState = "normal"
local stateEndTime = 0
local timerPrinted = false
local bodyParts = {}

local function InitializeBodyParts()
    for partName, _ in pairs(Config.BodyParts) do
        bodyParts[partName] = {
            health = 100,
            weapons = {}
        }
    end
end

local function GetBoneZone(boneId)
    for _, headBone in ipairs(Config.BoneZones.head) do
        if boneId == headBone then
            return "head"
        end
    end
    
    for _, bodyBone in ipairs(Config.BoneZones.body) do
        if boneId == bodyBone then
            return "body"
        end
    end
    
    for _, limbBone in ipairs(Config.BoneZones.limbs) do
        if boneId == limbBone then
            return "limbs"
        end
    end
    
    return "body"
end

local function GetBodyPartFromBone(boneId)
    for partName, bones in pairs(Config.BodyParts) do
        for _, bone in ipairs(bones) do
            if bone == boneId then
                return partName
            end
        end
    end
    return "torse"
end

local function GetHitBone(victim)
    local hit, bone = GetPedLastDamageBone(victim)
    if hit then
        return bone
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local victimCoords = GetEntityCoords(victim)
    
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        playerCoords.x, playerCoords.y, playerCoords.z + 0.5,
        victimCoords.x, victimCoords.y, victimCoords.z + 1.0,
        -1, playerPed, 0
    )
    
    local _, rayHit, hitCoords = GetShapeTestResult(rayHandle)
    
    if rayHit == 1 then
        local closestBone = 24818
        local closestDistance = 999.0
        
        for boneId, boneName in pairs(Config.BoneNames) do
            local boneCoords = GetPedBoneCoords(victim, boneId, 0.0, 0.0, 0.0)
            local distance = #(hitCoords - boneCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestBone = boneId
            end
        end
        
        return closestBone
    end
    
    return 24818
end

local function CalculateDamage(weaponHash, boneId)
    local weaponConfig = Config.WeaponDamage[weaponHash]
    if not weaponConfig then
        return 10
    end
    
    local zone = GetBoneZone(boneId)
    
    if zone == "head" then
        return weaponConfig.headDamage
    elseif zone == "body" then
        return weaponConfig.bodyDamage
    else
        return weaponConfig.limbDamage
    end
end

local function UpdateBodyPartDamage(boneId, damage, weaponHash)
    local bodyPart = GetBodyPartFromBone(boneId)
    local weaponName = Config.WeaponNames[weaponHash] or "ARME_INCONNUE"
    
    if GetBoneZone(boneId) == "head" then
        bodyParts[bodyPart].health = 0
    else
        bodyParts[bodyPart].health = bodyParts[bodyPart].health - damage
        if bodyParts[bodyPart].health < 0 then
            bodyParts[bodyPart].health = 0
        end
    end
    
    local weaponFound = false
    for _, weapon in ipairs(bodyParts[bodyPart].weapons) do
        if weapon == weaponName then
            weaponFound = true
            break
        end
    end
    
    if not weaponFound then
        table.insert(bodyParts[bodyPart].weapons, weaponName)
    end
end

local function UpdateHealthState(damage)
    local totalDamage = 100 - playerHealth
    
    for stateName, stateConfig in pairs(Config.HealthStates) do
        if totalDamage >= stateConfig.minDamage and totalDamage <= stateConfig.maxDamage then
            if healthState ~= stateName then
                healthState = stateName
                stateEndTime = GetGameTimer() + stateConfig.duration
                timerPrinted = false
                print("ENTREE ETAT: " .. stateConfig.message .. " (Duree: " .. stateConfig.duration/1000 .. "s)")
                TriggerServerEvent('damageSystem:stateChanged', stateName, stateConfig.message)
                
                if stateName == "dead" then
                    SetEntityHealth(PlayerPedId(), 0)
                end
            else
                stateEndTime = GetGameTimer() + stateConfig.duration
                timerPrinted = false
            end
            break
        end
    end
end

local function ProcessDamage(damage, boneId, weaponHash)
    playerHealth = playerHealth - damage
    if playerHealth < 0 then
        playerHealth = 0
    end
    
    UpdateBodyPartDamage(boneId, damage, weaponHash)
    UpdateHealthState(damage)
end

RegisterNetEvent('damageSystem:openMedicalExam')
AddEventHandler('damageSystem:openMedicalExam', function(targetData)
    SendNUIMessage({
        action = 'openMedicalExam',
        bodyParts = targetData.bodyParts,
        playerName = targetData.playerName
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('closeMedicalExam', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

AddEventHandler('gameEventTriggered', function(name, data)
    if name == 'CEventNetworkEntityDamage' then
        local victim = data[1]
        local attacker = data[2]
        local weaponHash = data[3]
        local playerPed = PlayerPedId()
        
        if IsEntityAPed(victim) and IsEntityAPed(attacker) and IsPedAPlayer(victim) and IsPedAPlayer(attacker) then
            local currentTime = GetGameTimer()
            local hitId = tostring(attacker) .. "_" .. tostring(victim) .. "_" .. tostring(weaponHash) .. "_" .. tostring(currentTime)
            
            if not lastHitTime[hitId] then
                lastHitTime[hitId] = true
                
                Citizen.SetTimeout(100, function()
                    lastHitTime[hitId] = nil
                end)
                
                local bone = GetHitBone(victim)
                local boneName = Config.BoneNames[bone] or ("BONE_" .. tostring(bone))
                local damage = CalculateDamage(weaponHash, bone)
                
                if victim == playerPed then
                    local attackerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
                    local oldHealth = playerHealth
                    ProcessDamage(damage, bone, weaponHash)
                    print("IMPACT: " .. damage .. " degats recu de joueur " .. attackerId .. " sur " .. boneName .. " (Vie: " .. oldHealth .. " -> " .. playerHealth .. ")")
                    TriggerServerEvent('damageSystem:damageReceived', attackerId, GetPlayerServerId(PlayerId()), damage, boneName)
                    TriggerServerEvent('damageSystem:updateBodyParts', bodyParts)
                end
                
                if attacker == playerPed then
                    local victimId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(victim))
                    print("TIR REUSSI: " .. damage .. " degats inflige a joueur " .. victimId .. " sur " .. boneName)
                    TriggerServerEvent('damageSystem:damageDealt', GetPlayerServerId(PlayerId()), victimId, damage, boneName)
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        
        if healthState ~= "normal" and healthState ~= "dead" and stateEndTime > 0 and GetGameTimer() >= stateEndTime and not timerPrinted then
            timerPrinted = true
            print("TIMER FINI: Etat final " .. Config.HealthStates[healthState].message)
        end
    end
end)

AddEventHandler('playerSpawned', function()
    playerHealth = 100
    healthState = "normal"
    stateEndTime = 0
    timerPrinted = false
    InitializeBodyParts()
    TriggerServerEvent('damageSystem:updateBodyParts', bodyParts)
end)

Citizen.CreateThread(function()
    InitializeBodyParts()
    TriggerServerEvent('damageSystem:updateBodyParts', bodyParts)
end)