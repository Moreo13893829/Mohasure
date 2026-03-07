-- ╔══════════════════════════════════════════════════════════╗
-- ║               PRESSURE PREMIUM ESP SCRIPT                ║
-- ║         Interface Fluent UI, Optimisé & Sécurisé         ║
-- ║         Fix des fuites de mémoire et crash CoreGui       ║
-- ╚══════════════════════════════════════════════════════════╝

-- Prévention pour éviter de dupliquer l'UI si tu réexécutes le script
if getgenv().PressurePremium_Loaded then
    if type(getgenv().PressurePremium_Unload) == "function" then
        getgenv().PressurePremium_Unload()
    end
end
getgenv().PressurePremium_Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- SÉCURISATION COREGUI (Prévention des Crashs)
-- ==========================================
local guiParent
if gethui then
    guiParent = gethui()
else
    local success = pcall(function() return CoreGui end)
    guiParent = success and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end

local ESP_Folder = Instance.new("Folder")
ESP_Folder.Name = "Pressure_ESP_Premium_Folder"
ESP_Folder.Parent = guiParent

-- ==========================================
-- GESTION DE LA MÉMOIRE & CONNEXIONS (Fix Lag)
-- ==========================================
local ESP_Cache = {}
local Connections = {}
local NotifiedEntities = {}
local interactDebounce = {}
local DangerousEntitiesPresent = {}
local SafezoneSavedCFrame = nil
local IsInSafezone = false

local Toggles = {
    EntityESP = false,
    ItemESP = false,
    LockerESP = false,
    PlayerESP = false,
    DoorESP = false,
    Notifications = false,
    Fullbright = false,
    AutoInteract = false,
    AutoSafezone = false,
    CFrameSpeed = false,
    CFrameSpeedValue = 1
}

-- ==========================================
-- CHARGEMENT DE L'INTERFACE GRAPHIQUE (FLUENT UI)
-- ==========================================
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not success or not Fluent then
    LocalPlayer:Kick("Erreur: Impossible de charger l'interface Fluent.")
    return
end

-- Création de la fenêtre
local Window = Fluent:CreateWindow({
    Title = "Pressure Script",
    SubTitle = "par Moha - Premium Edition V2.1",
    TabWidth = 160,
    Size = UDim2.fromOffset(630, 480),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Onglets
local Tabs = {
    Main = Window:AddTab({ Title = "ESP & Entités", Icon = "radar" }),
    Players = Window:AddTab({ Title = "Joueurs", Icon = "users" }),
    Items = Window:AddTab({ Title = "Objets & Portes", Icon = "box" }),
    Mods = Window:AddTab({ Title = "Mods Joueur (Bypass)", Icon = "zap" }),
    Visuals = Window:AddTab({ Title = "Visuels", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Paramètres", Icon = "settings" })
}

local Options = Fluent.Options

-- ==========================================
-- FONCTIONS ESP (Optimisation d'affichage)
-- ==========================================
local function removeESP(entity)
    if ESP_Cache[entity] then
        if ESP_Cache[entity].Highlight then ESP_Cache[entity].Highlight:Destroy() end
        if ESP_Cache[entity].Billboard then ESP_Cache[entity].Billboard:Destroy() end
        ESP_Cache[entity] = nil
    end
end

local function createESP(entity, name, color, typeESP)
    -- typeESP = "Entity", "Item", "Locker", "Player", "Door"
    if not entity or ESP_Cache[entity] then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = name .. "_ESP"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.1
    highlight.Adornee = entity
    highlight.Parent = ESP_Folder
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Tag"
    billboard.Adornee = entity
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.StudsOffset = Vector3.new(0, (typeESP == "Item" and 1.5) or 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ESP_Folder
    
    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextScaled = false
    label.TextSize = 13
    label.Parent = billboard
    
    ESP_Cache[entity] = { 
        Highlight = highlight, 
        Billboard = billboard, 
        Label = label,
        Type = typeESP,
        DisplayName = name 
    }
end

local function notifyUser(title, text)
    if not Toggles.Notifications then return end
    Fluent:Notify({
        Title = title,
        Content = text,
        Duration = 6
    })
end

-- ==========================================
-- DÉTECTION DES ENTITÉS ET OBJETS
-- ==========================================
local EntityList = {
    ["pandemonium"] = Color3.fromRGB(255, 0, 0),
    ["angler"] = Color3.fromRGB(0, 255, 0),
    ["pinkie"] = Color3.fromRGB(255, 105, 180),
    ["blitz"] = Color3.fromRGB(0, 255, 255),
    ["froger"] = Color3.fromRGB(0, 128, 0),
    ["chainsmoker"] = Color3.fromRGB(128, 128, 128),
    ["eyefestation"] = Color3.fromRGB(173, 255, 47),
    ["searchlight"] = Color3.fromRGB(255, 255, 0),
    ["wall dweller"] = Color3.fromRGB(139, 69, 19),
    ["good boy"] = Color3.fromRGB(255, 215, 0),
    ["squiddles"] = Color3.fromRGB(128, 0, 128)
}

local ItemList = {
    ["keycard"] = Color3.fromRGB(0, 191, 255),
    ["medkit"] = Color3.fromRGB(255, 20, 147),
    ["battery"] = Color3.fromRGB(255, 255, 0),
    ["flashlight"] = Color3.fromRGB(255, 255, 255),
    ["code breaker"] = Color3.fromRGB(138, 43, 226),
    ["gold"] = Color3.fromRGB(255, 215, 0),
    ["currency"] = Color3.fromRGB(255, 215, 0)
}

local LockerList = {
    ["locker"] = Color3.fromRGB(0, 255, 127),
    ["wardrobe"] = Color3.fromRGB(0, 255, 127)
}

local function formatName(str)
    return str:gsub("^%l", string.upper)
end

local function getEntityPosition(entity)
    if type(entity) == "table" then return nil end
    if not entity then return nil end
    if entity:IsA("Model") then
        if entity.PrimaryPart then
            return entity.PrimaryPart.Position
        else
            local part = entity:FindFirstChildWhichIsA("BasePart", true)
            return part and part.Position or nil
        end
    elseif entity:IsA("BasePart") then
        return entity.Position
    end
    return nil
end

local function firePrompt(prompt)
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        -- Fallback
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration)
        prompt:InputHoldEnd()
    end
end

-- Fonction pour bypass la vérification WalkSpeed en utilisant CFrame
local function applyCFrameSpeed()
    if Toggles.CFrameSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local humanoid = LocalPlayer.Character.Humanoid
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        if humanoid.MoveDirection.Magnitude > 0 and not IsInSafezone then
            rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (Toggles.CFrameSpeedValue / 10))
        end
    end
end

local function checkEntity(obj)
    pcall(function()
        if not obj then return end
        
        -- ESP Portes
        if obj.Name == "NormalDoor" or obj.Name == "NextDoor" or (obj:IsA("Model") and string.find(string.lower(obj.Name), "door") and obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then
            if not ESP_Cache[obj] then
                createESP(obj, "🚪 Porte", Color3.fromRGB(255, 255, 255), "Door")
            end
        end

        if obj:IsA("ProximityPrompt") and Options.Interact_Toggle and Options.Interact_Toggle.Value then
            obj.HoldDuration = 0
        end

        if obj:IsA("Model") or obj:IsA("BasePart") then
            local objName = string.lower(obj.Name)
            
            if string.find(objName, "void mass") or string.find(objName, "voidmass") then
                return
            end
            
            for entityName, color in pairs(EntityList) do
                if string.find(objName, entityName) then
                    if not ESP_Cache[obj] then
                        createESP(obj, formatName(entityName), color, "Entity")
                        
                        -- Tracking des dangers pour l'Auto Safezone
                        if entityName == "angler" or entityName == "pinkie" or entityName == "blitz" or entityName == "froger" or entityName == "chainsmoker" or entityName == "pandemonium" then
                            DangerousEntitiesPresent[obj] = true
                        end
                        
                        if not NotifiedEntities[obj] then
                            NotifiedEntities[obj] = true
                            
                            local action = "⚠️ CACHEZ-VOUS VITE !"
                            if entityName == "eyefestation" or entityName == "wall dweller" or entityName == "squiddles" or entityName == "good boy" then
                                action = "❌ NE VOUS CACHEZ SURTOUT PAS !"
                            end
                            
                            notifyUser("🚨 " .. formatName(entityName), action)
                        end
                    end
                    return
                end
            end
            
            for itemName, color in pairs(ItemList) do
                if string.find(objName, itemName) then
                    if not ESP_Cache[obj] then
                        if obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                            local avoidDouble = false
                            if obj.Parent and string.find(string.lower(obj.Parent.Name), itemName) then
                                avoidDouble = true
                            end
                            if not avoidDouble then
                                createESP(obj, formatName(itemName), color, "Item")
                            end
                        end
                    end
                    return
                end
            end
            
            for lockerName, color in pairs(LockerList) do
                if string.find(objName, lockerName) then
                    -- Exclusions élargies relatives aux tiroirs, étagères, etc
                    local isExclude = string.find(objName, "footlocker") or string.find(objName, "drawer") or string.find(objName, "shelf") or string.find(objName, "desk") or string.find(objName, "table") or string.find(objName, "box") or string.find(objName, "small") or string.find(objName, "mini") or string.find(objName, "casiers") or string.find(objName, "item")
                    if not isExclude then
                        if not ESP_Cache[obj] then
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt then
                                local avoidDouble = false
                                if obj.Parent and string.find(string.lower(obj.Parent.Name), lockerName) then
                                    avoidDouble = true
                                end
                                
                                local actionText = string.lower(prompt.ActionText or "")
                                if string.find(actionText, "open") or string.find(actionText, "search") or string.find(actionText, "loot") or string.find(actionText, "ouvrir") then
                                    avoidDouble = true -- On ignore les petits casiers lootables
                                end

                                if not avoidDouble then
                                    local safe = true
                                    for _, child in ipairs(obj:GetDescendants()) do
                                        if string.find(string.lower(child.Name), "void") then
                                            safe = false
                                            break
                                        end
                                    end
                                    if safe then
                                        createESP(obj, "Cachette", color, "Locker")
                                    end
                                end
                            end
                        end
                    end
                    return
                end
            end
        end
    end)
end

-- Player ESP Update
local function checkPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then
        if not ESP_Cache[player.Character] then
            createESP(player.Character, player.Name, Color3.fromRGB(0, 255, 255), "Player")
        end
    end
end

local function scanMap()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        checkEntity(obj)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        checkPlayer(player)
    end
end

-- ==========================================
-- BOUCLE PRINCIPALE (Fix Lag / Fuite Mémoire)
-- ==========================================
scanMap()
Connections["DescendantAdded"] = Workspace.DescendantAdded:Connect(checkEntity)

Connections["PlayerAdded"] = Players.PlayerAdded:Connect(function(player)
    Connections["PlayerChar_"..player.Name] = player.CharacterAdded:Connect(function(char)
        task.wait(1)
        checkPlayer(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        Connections["PlayerChar_"..player.Name] = player.CharacterAdded:Connect(function(char)
            task.wait(1)
            checkPlayer(player)
        end)
    end
end

Connections["UpdateLoop"] = RunService.Heartbeat:Connect(function()
    local myPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
    
    applyCFrameSpeed() -- Custom WalkSpeed Anti-Cheat Bypass
    
    -- Auto Safezone (TP Casier Automatique lors de danger)
    if Toggles.AutoSafezone then
        local hasDanger = false
        for ent, _ in pairs(DangerousEntitiesPresent) do
            if ent and ent.Parent then
                hasDanger = true
                break
            else
                DangerousEntitiesPresent[ent] = nil
            end
        end
        
        if hasDanger and not IsInSafezone then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local myPos = LocalPlayer.Character.HumanoidRootPart.Position
                local nearestLocker = nil
                local shortestDistance = math.huge
                
                for entity, data in pairs(ESP_Cache) do
                    if data.Type == "Locker" and typeof(entity) == "Instance" and entity.Parent then
                        local entPos = getEntityPosition(entity)
                        if entPos then
                            local dist = (myPos - entPos).Magnitude
                            if dist < shortestDistance and dist < 100 then -- Cherche dans un rayon de 100 studs
                                shortestDistance = dist
                                nearestLocker = entity
                            end
                        end
                    end
                end

                if nearestLocker then
                    local prompt = nearestLocker:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then 
                        SafezoneSavedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                        IsInSafezone = true
                        
                        -- TP devant le casier et interaction
                        LocalPlayer.Character.HumanoidRootPart.CFrame = nearestLocker.PrimaryPart and nearestLocker.PrimaryPart.CFrame or CFrame.new(getEntityPosition(nearestLocker))
                        task.wait(0.1)
                        firePrompt(prompt)
                        notifyUser("🛡️ Safezone", "Monstre en approche ! Caché dans le casier automatique.")
                    end
                else
                    -- Pas de casier proche, TP en hauteur en secours
                    SafezoneSavedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    IsInSafezone = true
                    -- On TP très loin horizontalement et légèrement en hauteur (Y = 50 max) pour éviter les barrières de kill
                    LocalPlayer.Character.HumanoidRootPart.CFrame = SafezoneSavedCFrame + Vector3.new(500, 50, 500)
                    LocalPlayer.Character.HumanoidRootPart.Anchored = true
                    notifyUser("🛡️ Safezone", "Aucun casier. TP d'urgence lointain actif.")
                end
            end
        elseif not hasDanger and IsInSafezone then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and SafezoneSavedCFrame then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
                
                -- Si on est caché dans le casier, on n'a plus besoin d'interagir (le monstre est parti, le joueur sortira manuellement ou sera tp)
                -- TP de retour à la position initiale
                LocalPlayer.Character.HumanoidRootPart.CFrame = SafezoneSavedCFrame
                IsInSafezone = false
                SafezoneSavedCFrame = nil
                notifyUser("🛡️ Safezone", "Zone claire ! Retour à la normale.")
            end
        end
    end

    -- Auto Interact Aura
    if Toggles.AutoInteract and myPos and not IsInSafezone then
        for _, prompt in ipairs(Workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                local objPos = getEntityPosition(prompt.Parent)
                if objPos and (myPos - objPos).Magnitude <= 12 then
                    local n = string.lower(prompt.Parent.Name)
                    -- Ignorer casiers, portes et lecteurs de keycard
                    if not string.find(n, "locker") and not string.find(n, "wardrobe") and not string.find(n, "door") and not string.find(n, "reader") and not string.find(n, "keycard") then
                        if not interactDebounce[prompt] then
                            interactDebounce[prompt] = true
                            task.spawn(function()
                                pcall(firePrompt, prompt)
                                task.wait(0.05) -- Délai grandement réduit pour ramasser super vite
                                if interactDebounce then interactDebounce[prompt] = nil end
                            end)
                        end
                    end
                end
            end
        end
    end
    
    for entity, data in pairs(ESP_Cache) do
        if entity and (typeof(entity) == "Instance" and entity.Parent) then
            local entPos = getEntityPosition(entity)
            if entPos and myPos then
                local shouldShow = false
                if data.Type == "Entity" and Toggles.EntityESP then shouldShow = true end
                if data.Type == "Item" and Toggles.ItemESP then shouldShow = true end
                if data.Type == "Locker" and Toggles.LockerESP then shouldShow = true end
                if data.Type == "Player" and Toggles.PlayerESP then shouldShow = true end
                if data.Type == "Door" and Toggles.DoorESP then shouldShow = true end
                
                if not shouldShow then
                    data.Highlight.Enabled = false
                    data.Billboard.Enabled = false
                else
                    data.Highlight.Enabled = true
                    data.Billboard.Enabled = true
                    
                    local dist = math.floor((myPos - entPos).Magnitude)
                    data.Label.Text = string.format("%s\n[%dm]", data.DisplayName, dist)
                end
            else
                data.Highlight.Enabled = false
                data.Billboard.Enabled = false
            end
        else
            removeESP(entity)
        end
    end
    
    if Toggles.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
    end
end)

-- ==========================================
-- ONGLET : ESP & ENTITÉS
-- ==========================================
Tabs.Main:AddParagraph({ Title = "ESP des Entités (Anti-Lag)", Content = "Suivez toutes les entités du jeu sans lag." })

local ToggleEntity = Tabs.Main:AddToggle("EntityESP_Toggle", {Title = "Activer l'Entity ESP", Default = false})
ToggleEntity:OnChanged(function() Toggles.EntityESP = Options.EntityESP_Toggle.Value end)

local ToggleNotifs = Tabs.Main:AddToggle("Notif_Toggle", {Title = "Notifications d'Approche", Default = false})
ToggleNotifs:OnChanged(function() Toggles.Notifications = Options.Notif_Toggle.Value end)

local ToggleLocker = Tabs.Main:AddToggle("LockerESP_Toggle", {Title = "ESP des Cachettes (Safe)", Default = false})
ToggleLocker:OnChanged(function() Toggles.LockerESP = Options.LockerESP_Toggle.Value end)

Tabs.Main:AddSection("Couleurs des Entités (Customisables)")
for entityName, color in pairs(EntityList) do
    Tabs.Main:AddColorpicker("Color_" .. entityName, { Title = formatName(entityName), Default = color }):OnChanged(function()
        EntityList[entityName] = Options["Color_" .. entityName].Value
        for entity, data in pairs(ESP_Cache) do
            if data.Type == "Entity" and string.find(string.lower(entity.Name), entityName) then
                data.Highlight.FillColor = EntityList[entityName]
                data.Label.TextColor3 = EntityList[entityName]
            end
        end
    end)
end

-- ==========================================
-- ONGLET : MODS JOUEUR (Bypass)
-- ==========================================
Tabs.Mods:AddParagraph({ Title = "Mods Joueur & Bypasses", Content = "Ces mods utilisent des méthodes qui évitent l'anti-cheat du jeu." })

local ToggleCFrameSpeed = Tabs.Mods:AddToggle("CFrameSpeed_Toggle", {Title = "Vitesse de Déplacement (CFrame Bypass)", Default = false})
ToggleCFrameSpeed:OnChanged(function() Toggles.CFrameSpeed = Options.CFrameSpeed_Toggle.Value end)

Tabs.Mods:AddSlider("CFrameSpeed_Value", {
    Title = "Multiplicateur de Vitesse",
    Description = "Attention: Ne le mettez pas trop haut pour éviter d'être téléporté en arrière.",
    Default = 1,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        Toggles.CFrameSpeedValue = Value
    end
})

local ToggleAutoInteract = Tabs.Mods:AddToggle("AutoInteract_Toggle", {Title = "Aura d'Interaction (Ramasse Auto)", Default = false})
ToggleAutoInteract:OnChanged(function() Toggles.AutoInteract = Options.AutoInteract_Toggle.Value end)

local ToggleSafezone = Tabs.Mods:AddToggle("AutoSafezone_Toggle", {Title = "Auto Safezone (Cache Automatique Casier)", Default = false})
ToggleSafezone:OnChanged(function() Toggles.AutoSafezone = Options.AutoSafezone_Toggle.Value end)

-- ==========================================
-- ONGLET : JOUEURS
-- ==========================================
Tabs.Players:AddParagraph({ Title = "ESP Joueurs", Content = "Voir les membres de votre groupe." })

local TogglePlayer = Tabs.Players:AddToggle("PlayerESP_Toggle", {Title = "Activer l'ESP Joueur", Default = false})
TogglePlayer:OnChanged(function() Toggles.PlayerESP = Options.PlayerESP_Toggle.Value end)

-- ==========================================
-- ONGLET : OBJETS & PORTES
-- ==========================================
Tabs.Items:AddParagraph({ Title = "ESP des Objets", Content = "Détectez les loots importants et portes." })

local ToggleItems = Tabs.Items:AddToggle("ItemESP_Toggle", {Title = "Activer l'Item ESP", Default = false})
ToggleItems:OnChanged(function() Toggles.ItemESP = Options.ItemESP_Toggle.Value end)

local ToggleDoors = Tabs.Items:AddToggle("DoorESP_Toggle", {Title = "ESP des Portes", Default = false})
ToggleDoors:OnChanged(function() Toggles.DoorESP = Options.DoorESP_Toggle.Value end)

Tabs.Items:AddSection("Couleurs des Objets")
for itemName, color in pairs(ItemList) do
    Tabs.Items:AddColorpicker("Color_" .. itemName, { Title = formatName(itemName), Default = color }):OnChanged(function()
        ItemList[itemName] = Options["Color_" .. itemName].Value
        for entity, data in pairs(ESP_Cache) do
            if data.Type == "Item" and string.find(string.lower(entity.Name), itemName) then
                data.Highlight.FillColor = ItemList[itemName]
                data.Label.TextColor3 = ItemList[itemName]
            end
        end
    end)
end

-- ==========================================
-- ONGLET : VISUELS
-- ==========================================
Tabs.Visuals:AddParagraph({ Title = "Améliorations Visuelles", Content = "Options pour la caméra et l'éclairage." })

local ToggleFullbright = Tabs.Visuals:AddToggle("Fullbright_Toggle", {Title = "Luminosité Max (Fullbright)", Default = false})
ToggleFullbright:OnChanged(function()
    Toggles.Fullbright = Options.Fullbright_Toggle.Value
    if not Toggles.Fullbright then
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    end
end)

-- ==========================================
-- ONGLET : PARAMÈTRES
-- ==========================================
Tabs.Settings:AddParagraph({ Title = "Utilitaires & Sécurité", Content = "Clean le script et hacks divers." })

local ToggleInteract = Tabs.Settings:AddToggle("Interact_Toggle", {Title = "Hold Duration à 0 Instantané", Default = false})
ToggleInteract:OnChanged(function()
    if Options.Interact_Toggle.Value then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                obj.HoldDuration = 0
            end
        end
    end
end)

Tabs.Settings:AddInput("Minimize_Input", {
    Title = "Touche du Menu (Nom en Anglais)",
    Description = "Exemple: RightControl, E, P, Insert, LeftAlt...",
    Default = "RightControl",
    Placeholder = "Tapez le nom de la touche ici",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        local success, key = pcall(function() return Enum.KeyCode[Value] end)
        if success and key then
            Window.MinimizeKey = key
            if Toggles.Notifications then
                Fluent:Notify({Title = "⚙️ Paramètres", Content = "Touche du menu modifiée sur : " .. Value, Duration = 3})
            end
        else
            if Toggles.Notifications then
                Fluent:Notify({Title = "❌ Erreur", Content = "Nom de touche invalide ! Vérifiez l'orthographe.", Duration = 3})
            end
        end
    end
})

Tabs.Settings:AddButton({
    Title = "Unload Script",
    Description = "Supprime toutes les traces VISUELLES et DÉCONNECTE le code de la mémoire vive.",
    Callback = function()
        if type(getgenv().PressurePremium_Unload) == "function" then
            getgenv().PressurePremium_Unload()
        end
    end
})

-- ==========================================
-- FONCTION UNLOAD TOTALE
-- ==========================================
getgenv().PressurePremium_Unload = function()
    for _, conn in pairs(Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(Connections)
    
    for entity, _ in pairs(ESP_Cache) do
        removeESP(entity)
    end
    table.clear(ESP_Cache)
    table.clear(DangerousEntitiesPresent)
    table.clear(interactDebounce)
    table.clear(NotifiedEntities)
    
    if ESP_Folder then
        ESP_Folder:Destroy()
    end
    
    if Lighting then
        Lighting.Ambient = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    end
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and IsInSafezone and SafezoneSavedCFrame then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
        LocalPlayer.Character.HumanoidRootPart.CFrame = SafezoneSavedCFrame
    end
    
    Window:Destroy()
    
    getgenv().PressurePremium_Loaded = false
end

-- ==========================================
-- FIN DE L'INITIALISATION
-- ==========================================
Window:SelectTab(1)
Fluent:Notify({
    Title = "⚡ Premium V2.1",
    Content = "Bugs fixés et Auto-Safezone ajouté !",
    Duration = 8
})
