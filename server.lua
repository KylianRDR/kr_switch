local playerBodyParts = {}

RegisterServerEvent('damageSystem:damageReceived')
AddEventHandler('damageSystem:damageReceived', function(attackerId, victimId, damage, boneName)
    local attackerName = GetPlayerName(attackerId)
    local victimName = GetPlayerName(victimId)
    
    print("SERVEUR: " .. victimName .. " (" .. victimId .. ") a recu " .. damage .. " degats de " .. attackerName .. " (" .. attackerId .. ") sur " .. boneName)
end)

RegisterServerEvent('damageSystem:damageDealt')
AddEventHandler('damageSystem:damageDealt', function(attackerId, victimId, damage, boneName)
    local attackerName = GetPlayerName(attackerId)
    local victimName = GetPlayerName(victimId)
    
    print("SERVEUR: " .. attackerName .. " (" .. attackerId .. ") a inflige " .. damage .. " degats a " .. victimName .. " (" .. victimId .. ") sur " .. boneName)
end)

RegisterServerEvent('damageSystem:stateChanged')
AddEventHandler('damageSystem:stateChanged', function(state, message)
    local playerName = GetPlayerName(source)
    
    print("SERVEUR: " .. playerName .. " (" .. source .. ") est maintenant en etat: " .. message)
end)

RegisterServerEvent('damageSystem:updateBodyParts')
AddEventHandler('damageSystem:updateBodyParts', function(bodyParts)
    local playerId = source
    playerBodyParts[playerId] = bodyParts
end)

RegisterServerEvent('damageSystem:requestMedicalExam')
AddEventHandler('damageSystem:requestMedicalExam', function(targetId)
    local source = source
    local targetPlayer = GetPlayerName(targetId)
    
    if targetPlayer and playerBodyParts[targetId] then
        TriggerClientEvent('damageSystem:openMedicalExam', source, {
            bodyParts = playerBodyParts[targetId],
            playerName = targetPlayer
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"SYSTEME", "Impossible d'examiner ce joueur."}
        })
    end
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    if playerBodyParts[playerId] then
        playerBodyParts[playerId] = nil
    end
end)