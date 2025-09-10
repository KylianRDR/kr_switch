local allCharacters = {}
local archivedCharacters = {}
local lib = exports['ox_lib']

RegisterNetEvent('character_archive:openMenu')
AddEventHandler('character_archive:openMenu', function()
    local options = {
        {
            title = 'Liste des Personnages Actifs',
            description = 'Voir tous les personnages actifs',
            icon = 'users',
            onSelect = function()
                TriggerServerEvent('character_archive:getAllCharacters')
            end
        },
        {
            title = 'Personnages ArchivÃ©s',
            description = 'GÃ©rer les personnages archivÃ©s',
            icon = 'archive',
            onSelect = function()
                TriggerServerEvent('character_archive:getArchivedCharacters')
            end
        }
    }

    lib:registerContext({
        id = 'character_archive_main',
        title = 'Gestion des Personnages',
        options = options
    })
    lib:showContext('character_archive_main')
end)

RegisterNetEvent('character_archive:receiveAllCharacters')
AddEventHandler('character_archive:receiveAllCharacters', function(characters)
    if not characters or type(characters) ~= 'table' then
        characters = {}
    end
    
    allCharacters = characters
    
    local options = {}
    
    for i = 1, #characters do
        local char = characters[i]
        if char and type(char) == 'table' and char.firstname and char.lastname and char.identifier then
            local accounts = {}
            if char.accounts and type(char.accounts) == 'string' and char.accounts ~= '' then
                local success, decoded = pcall(json.decode, char.accounts)
                if success and type(decoded) == 'table' then
                    accounts = decoded
                end
            end
            local money = accounts.money or 0
            
            table.insert(options, {
                title = tostring(char.firstname) .. ' ' .. tostring(char.lastname),
                description = 'Job: ' .. tostring(char.job or 'Inconnu') .. ' | Argent: $' .. tostring(money) .. ' | ID: ' .. tostring(char.identifier),
                icon = 'user',
                onSelect = function()
                    showCharacterActions(char)
                end
            })
        end
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'Aucun personnage trouvÃ©',
            description = 'Aucun personnage actif dans la base de donnÃ©es',
            icon = 'exclamation-triangle',
            disabled = true
        })
    end
    
    table.insert(options, {
        title = 'Retour',
        description = 'Retourner au menu principal',
        icon = 'arrow-left',
        onSelect = function()
            TriggerEvent('character_archive:openMenu')
        end
    })
    
    if #options > 0 then
        lib:registerContext({
            id = 'character_list',
            title = 'Personnages Actifs (' .. tostring(#characters) .. ')',
            options = options
        })
        lib:showContext('character_list')
    end
end)

RegisterNetEvent('character_archive:receiveArchivedCharacters')
AddEventHandler('character_archive:receiveArchivedCharacters', function(characters)
    if not characters or type(characters) ~= 'table' then
        characters = {}
    end
    
    archivedCharacters = characters
    
    local options = {}
    
    for i = 1, #characters do
        local char = characters[i]
        if char and type(char) == 'table' and char.firstname and char.lastname then
            local accounts = {}
            if char.accounts and type(char.accounts) == 'string' and char.accounts ~= '' then
                local success, decoded = pcall(json.decode, char.accounts)
                if success and type(decoded) == 'table' then
                    accounts = decoded
                end
            end
            local money = accounts.money or 0
            
            table.insert(options, {
                title = tostring(char.firstname) .. ' ' .. tostring(char.lastname),
                description = 'ArchivÃ© le: ' .. tostring(char.archived_date or 'Inconnu') .. ' | Argent: $' .. tostring(money),
                icon = 'archive',
                onSelect = function()
                    showArchivedCharacterActions(char)
                end
            })
        end
    end
    
    if #options == 0 then
        table.insert(options, {
            title = 'Aucun personnage archivÃ©',
            description = 'Aucun personnage archivÃ© trouvÃ©',
            icon = 'exclamation-triangle',
            disabled = true
        })
    end
    
    table.insert(options, {
        title = 'Retour',
        description = 'Retourner au menu principal',
        icon = 'arrow-left',
        onSelect = function()
            TriggerEvent('character_archive:openMenu')
        end
    })
    
    if #options > 0 then
        lib:registerContext({
            id = 'archived_character_list',
            title = 'Personnages ArchivÃ©s (' .. tostring(#characters) .. ')',
            options = options
        })
        lib:showContext('archived_character_list')
    end
end)

function showCharacterActions(character)
    if not character or type(character) ~= 'table' or not character.firstname or not character.lastname or not character.identifier then
        lib:notify({
            title = 'Erreur',
            description = 'Données du personnage invalides',
            type = 'error'
        })
        return
    end
    
    local options = {
        {
            title = 'Informations',
            description = 'ID: ' .. tostring(character.identifier) .. '\nJob: ' .. tostring(character.job or 'Inconnu') .. ' (Grade: ' .. tostring(character.job_grade or '0') .. ')\nGroupe: ' .. tostring(character.group or 'user'),
            icon = 'info-circle',
            disabled = true
        },
        {
            title = 'Archiver le Personnage',
            description = 'Archiver ce personnage (le joueur ne pourra plus l\'utiliser)',
            icon = 'archive',
            onSelect = function()
                local alert = lib:alertDialog({
                    header = 'Confirmation',
                    content = 'ÃŠtes-vous sÃ»r de vouloir archiver le personnage ' .. tostring(character.firstname) .. ' ' .. tostring(character.lastname) .. ' ?',
                    centered = true,
                    cancel = true
                })
                
                if alert == 'confirm' then
                    TriggerServerEvent('character_archive:archiveCharacter', character.identifier)
                end
            end
        },
        {
            title = 'Retour',
            description = 'Retourner Ã  la liste',
            icon = 'arrow-left',
            onSelect = function()
                TriggerServerEvent('character_archive:getAllCharacters')
            end
        }
    }
    
    lib:registerContext({
        id = 'character_actions',
        title = tostring(character.firstname) .. ' ' .. tostring(character.lastname),
        options = options
    })
    lib:showContext('character_actions')
end

function showArchivedCharacterActions(character)
    if not character or type(character) ~= 'table' or not character.firstname or not character.lastname or not character.identifier then
        lib:notify({
            title = 'Erreur',
            description = 'Données du personnage invalides',
            type = 'error'
        })
        return
    end
    
    local options = {
        {
            title = 'Informations',
            description = 'ID: ' .. tostring(character.identifier) .. '\nJob: ' .. tostring(character.job or 'Inconnu') .. ' (Grade: ' .. tostring(character.job_grade or '0') .. ')\nDernière connexion: ' .. tostring(character.last_seen or 'Inconnu'),
            icon = 'info-circle',
            disabled = true
        },
        {
            title = 'RÃ©assigner le Personnage',
            description = 'RÃ©assigner ce personnage Ã  une nouvelle licence',
            icon = 'user-plus',
            onSelect = function()
                local input = lib:inputDialog('RÃ©assigner Personnage', {
                    {
                        type = 'input',
                        label = 'Nouvelle Licence',
                        description = 'Entrez la nouvelle licence (sans char1:, char2:, etc.)',
                        placeholder = 'd7b09bf3a327b7d1e195adf8b656e4abf1f58082',
                        required = true,
                        min = 10,
                        max = 50
                    }
                })
                
                if input and input[1] then
                    local newLicense = tostring(input[1]):gsub('%s+', ''):gsub('[^%w]', '')
                    if #newLicense >= 10 and #newLicense <= 50 then
                        TriggerServerEvent('character_archive:reassignCharacter', character.identifier, newLicense)
                    else
                        lib:notify({
                            title = 'Erreur',
                            description = 'La licence doit contenir entre 10 et 50 caractères alphanumériques',
                            type = 'error'
                        })
                    end
                end
            end
        },
        {
            title = 'Retour',
            description = 'Retourner Ã  la liste des archivÃ©s',
            icon = 'arrow-left',
            onSelect = function()
                TriggerServerEvent('character_archive:getArchivedCharacters')
            end
        }
    }
    
    lib:registerContext({
        id = 'archived_character_actions',
        title = tostring(character.firstname) .. ' ' .. tostring(character.lastname),
        options = options
    })
    lib:showContext('archived_character_actions')
end