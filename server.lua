ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('character_archive:getAllCharacters')
AddEventHandler('character_archive:getAllCharacters', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    MySQL.query('SELECT identifier, firstname, lastname, accounts, job, job_grade, `group` FROM users WHERE disabled IS NULL OR disabled = 0', {}, function(result)
        if not result then
            result = {}
        end
        TriggerClientEvent('character_archive:receiveAllCharacters', source, result)
    end)
end)

RegisterNetEvent('character_archive:getArchivedCharacters')
AddEventHandler('character_archive:getArchivedCharacters', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    MySQL.query('SELECT identifier, firstname, lastname, accounts, job, job_grade, last_seen FROM users WHERE disabled = 1', {}, function(result)
        if not result then
            result = {}
        end
        TriggerClientEvent('character_archive:receiveArchivedCharacters', source, result)
    end)
end)

RegisterNetEvent('character_archive:archiveCharacter')
AddEventHandler('character_archive:archiveCharacter', function(identifier)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    if not identifier or identifier == '' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Identifiant invalide',
            type = 'error'
        })
        return
    end
    
    local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if targetPlayer then
        DropPlayer(targetPlayer.source, 'Personnage archivé par un administrateur')
    end
    
    MySQL.update('UPDATE users SET disabled = 1 WHERE identifier = ?', {identifier}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Succès',
                description = 'Personnage archivé avec succès',
                type = 'success'
            })
            TriggerClientEvent('character_archive:getAllCharacters', source)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Erreur',
                description = 'Impossible d\'archiver le personnage',
                type = 'error'
            })
        end
    end)
end)

RegisterNetEvent('character_archive:reassignCharacter')
AddEventHandler('character_archive:reassignCharacter', function(oldIdentifier, newLicense)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    if not oldIdentifier or oldIdentifier == '' or not newLicense or newLicense == '' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Paramètres invalides',
            type = 'error'
        })
        return
    end
    
    local function findFreeSlot(license)
        for slot = 1, 10 do
            local testIdentifier = 'char' .. slot .. ':' .. license
            local count = MySQL.scalar.await('SELECT COUNT(*) as count FROM users WHERE identifier = ?', {testIdentifier})
            if count == 0 then
                return slot
            end
        end
        return nil
    end
    
    local freeSlot = findFreeSlot(newLicense)
    
    if not freeSlot then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Erreur',
            description = 'Cette licence a déjà le maximum de personnages',
            type = 'error'
        })
        return
    end
    
    local newIdentifier = 'char' .. freeSlot .. ':' .. newLicense
    
    MySQL.update('UPDATE users SET identifier = ?, disabled = 0 WHERE identifier = ?', {newIdentifier, oldIdentifier}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Succès',
                description = 'Personnage réassigné au slot ' .. freeSlot .. ' avec succès',
                type = 'success'
            })
            TriggerClientEvent('character_archive:getArchivedCharacters', source)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Erreur',
                description = 'Impossible de réassigner le personnage',
                type = 'error'
            })
        end
    end)
end)

RegisterCommand('chararchive', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    TriggerClientEvent('character_archive:openMenu', source)
end, false)