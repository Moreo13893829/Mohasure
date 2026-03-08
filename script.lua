-- ╔══════════════════════════════════════════════════════════╗
-- ║               PRESSURE PREMIUM ESP SCRIPT                ║
-- ║         Interface Fluent UI, Optimisé & Sécurisé         ║
-- ║         Fix des fuites de mémoire et crash CoreGui       ║
-- ╚══════════════════════════════════════════════════════════╝

-- Prévention pour éviter de dupliquer l'UI
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
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- [AJOUT MOKZ : Détection Mobile]
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ==========================================
-- SÉCURISATION COREGUI
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
-- GESTION DE LA MÉMOIRE & CACHES (Fix Lag)
-- ==========================================
local ESP_Cache = {}
local Connections = {}
local NotifiedEntities = {}
local Prompt_Cache = {}
local DangerousEntitiesPresent = {}
local SafezoneSavedCFrame = nil
local IsInSafezone = false

local Toggles = {
    EntityESP = false,
    ItemESP = false,
    LockerESP = false,
    PlayerESP = false,
    DoorESP = false,
    CodeESP = false,
    Notifications = false,
    Fullbright = false,
    NoFog = false,
    AutoInteract = false,
    AutoLoot = false,
    AntiVoid = false,
    AutoSafezone = false,
    CFrameSpeed = false,
    SpeedSurface = 1,
    SpeedWater = 1,
    InWater = false,
    MinimizeKeyBind = Enum.KeyCode.RightControl,
    
    -- [AJOUT MOKZ : Variables God Mode]
    AutoPandemonium = false,
    AutoCables = false,
    ForceUnlock = false,
    PlayerAura = false
}

-- ==========================================
-- CHARGEMENT DE L'INTERFACE GRAPHIQUE
-- ==========================================
local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not success or not Fluent then
    LocalPlayer:Kick("Erreur: Impossible de charger l'interface Fluent.")
    return
end

local Window = Fluent:CreateWindow({
    Title = "Pressure Script",
    SubTitle = "par Moha - Premium Edition V3.0",
    TabWidth = 160,
    -- [AJOUT MOKZ : Taille adaptative Mobile/PC]
    Size = isMobile and UDim2.fromOffset(450, 300) or UDim2.fromOffset(630, 520),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Toggles.MinimizeKeyBind
})

local Tabs = {
    Main = Window:AddTab({ Title = "ESP & Entités", Icon = "radar" }),
    Players = Window:AddTab({ Title = "Joueurs", Icon = "users" }),
    Items = Window:AddTab({ Title = "Objets & Codes", Icon = "box" }),
    Mods = Window:AddTab({ Title = "Mods & Bypass", Icon = "zap" }),
    -- [AJOUT MOKZ : Nouvel onglet God Mode]
    Minigames = Window:AddTab({ Title = "Mini-Jeux (God)", Icon = "gamepad-2" }),
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
    highlight.Enabled = false
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Tag"
    billboard.Adornee = entity
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.StudsOffset = Vector3.new(0, (typeESP == "Item" and 1.5) or 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = ESP_Folder
    billboard.Enabled = false
    
    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
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
    Fluent:Notify({Title = title, Content = text, Duration = 5})
end

-- ==========================================
-- LISTES ET FILTRES
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

local PasswordList = {
    ["terminal"] = Color3.fromRGB(200, 200, 200),
    ["station"] = Color3.fromRGB(200, 200, 200),
    ["keypad"] = Color3.fromRGB(200, 200, 200),
    ["password"] = Color3.fromRGB(200, 200, 200)
}

local function getEntityPosition(entity)
    if not entity or not entity.Parent then return nil end
    if entity:IsA("Model") then
        local primary = entity.PrimaryPart
        if primary then return primary.Position end
        local part = entity:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    elseif entity:IsA("BasePart") then
        return entity.Position
    end
    return nil
end

local function firePrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + 0.01)
        prompt:InputHoldEnd()
    end
end

-- ==========================================
-- CORE LOGIC : DETECTION & CACHE
-- ==========================================
local function checkEntity(obj)
    if not obj or not obj.Parent then return end
    local objName = string.lower(obj.Name)

    -- Instant Interact
    if obj:IsA("ProximityPrompt") then
        if not Prompt_Cache[obj] then Prompt_Cache[obj] = true end
        obj.HoldDuration = 0
        return
    end

    -- Protection Anti-Void (Casiers piégés)
    if Toggles.AntiVoid and string.find(objName, "void") then
        local p = obj.Parent
        if p and (string.find(string.lower(p.Name), "locker") or string.find(string.lower(p.Name), "wardrobe")) then
            removeESP(p)
            local prompt = p:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then prompt.Enabled = false end
            return
        end
    end

    -- ESP Portes
    if objName == "normaldoor" or objName == "nextdoor" or (obj:IsA("Model") and string.find(objName, "door") and obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then
        if not ESP_Cache[obj] then createESP(obj, "🚪 Porte", Color3.new(1,1,1), "Door") end
        return
    end

    -- ESP Password / Codes
    for pw, col in pairs(PasswordList) do
        if string.find(objName, pw) then
            if not ESP_Cache[obj] then createESP(obj, "🔑 Password", col, "Code") end
            return
        end
    end

    -- ESP Entités
    for ent, col in pairs(EntityList) do
        if string.find(objName, ent) then
            -- Fix Searchlight (Caméras)
            if ent == "searchlight" and string.find(objName, "camera") then continue end
            -- Fix Eyefestation (Si endormie)
            if ent == "eyefestation" and obj:IsA("Model") and not obj:FindFirstChild("Eye") then continue end

            if not ESP_Cache[obj] then
                createESP(obj, ent:gsub("^%l", string.upper), col, "Entity")
                if table.find({"angler", "pinkie", "blitz", "froger", "chainsmoker", "pandemonium"}, ent) then
                    DangerousEntitiesPresent[obj] = true
                end
                if not NotifiedEntities[obj] then
                    NotifiedEntities[obj] = true
                    notifyUser("🚨 " .. ent:upper(), "Cachez-vous vite !")
                end
            end
            return
        end
    end

    -- ESP Items & Auto-Loot
    for item, col in pairs(ItemList) do
        if string.find(objName, item) then
            if not ESP_Cache[obj] and obj:FindFirstChildWhichIsA("ProximityPrompt", true) then
                createESP(obj, item:gsub("^%l", string.upper), col, "Item")
            end
            return
        end
    end

    -- ESP Casiers (Safe Only)
    if string.find(objName, "locker") or string.find(objName, "wardrobe") then
        if string.find(objName, "foot") or string.find(objName, "desk") then return end
        if not ESP_Cache[obj] then
            local isVoid = false
            for _, c in ipairs(obj:GetDescendants()) do if string.find(string.lower(c.Name), "void") then isVoid = true break end end
            if not isVoid then createESP(obj, "Cachette", Color3.fromRGB(0, 255, 127), "Locker") end
        end
    end
end

local function scanMap()
    for _, v in ipairs(Workspace:GetDescendants()) do task.spawn(checkEntity, v) end
end

-- ==========================================
-- BOUCLE DE RENDU ET BYPASS
-- ==========================================
Connections["DescendantAdded"] = Workspace.DescendantAdded:Connect(function(v)
    checkEntity(v)
    if v:IsA("ProximityPrompt") and v.Parent then checkEntity(v.Parent) end
end)

Connections["Update"] = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myPos = char.HumanoidRootPart.Position
    local hum = char:FindFirstChildOfClass("Humanoid")

    -- Detect Water
    Toggles.InWater = (hum and hum:GetState() == Enum.HumanoidStateType.Swimming)

    -- Speed Bypass
    if Toggles.CFrameSpeed and hum and hum.MoveDirection.Magnitude > 0 and not IsInSafezone then
        local spd = Toggles.InWater and Toggles.SpeedWater or Toggles.SpeedSurface
        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + (hum.MoveDirection * (spd / 10))
    end

    -- No Fog
    if Toggles.NoFog then
        for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") or v:IsA("FogEnd") then pcall(function() v.Parent = nil end) end end
        Lighting.FogEnd = 100000
    end

    -- Auto Safezone (Repaired)
    if Toggles.AutoSafezone then
        local hasDanger = false
        for ent, _ in pairs(DangerousEntitiesPresent) do
            if ent and ent.Parent then hasDanger = true break else DangerousEntitiesPresent[ent] = nil end
        end

        if hasDanger and not IsInSafezone then
            local targetLocker = nil
            local dist = 500
            for ent, data in pairs(ESP_Cache) do
                if data.Type == "Locker" and ent.Parent then
                    local p = getEntityPosition(ent)
                    if p and (myPos - p).Magnitude < dist then dist = (myPos - p).Magnitude targetLocker = ent end
                end
            end
            if targetLocker then
                SafezoneSavedCFrame = char.HumanoidRootPart.CFrame
                IsInSafezone = true
                char.HumanoidRootPart.CFrame = targetLocker.PrimaryPart and targetLocker.PrimaryPart.CFrame or CFrame.new(getEntityPosition(targetLocker))
                task.wait(0.1)
                firePrompt(targetLocker:FindFirstChildWhichIsA("ProximityPrompt", true))
            end
        elseif not hasDanger and IsInSafezone then
            IsInSafezone = false
            char.HumanoidRootPart.CFrame = SafezoneSavedCFrame
            SafezoneSavedCFrame = nil
        end
    end

    -- ESP Rendering & Auto-Loot
    for ent, data in pairs(ESP_Cache) do
        if ent and ent.Parent then
            local p = getEntityPosition(ent)
            if p then
                local d = (myPos - p).Magnitude
                local show = Toggles[data.Type .. "ESP"] or (data.Type == "Code" and Toggles.CodeESP)
                
                -- Auto Loot (Items & Gold)
                if Toggles.AutoLoot and d < 15 and data.Type == "Item" then
                    local pr = ent:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pr and pr.Enabled then firePrompt(pr) end
                end

                if show and d < (data.Type == "Door" and 300 or 2000) then
                    data.Highlight.Enabled, data.Billboard.Enabled = true, true
                    data.Label.Text = string.format("%s\n[%dm]", data.DisplayName, math.floor(d))
                else
                    data.Highlight.Enabled, data.Billboard.Enabled = false, false
                end
            end
        else removeESP(ent) end
    end
end)

-- [AJOUT MOKZ : LOGIQUE GOD MODE / MINI-JEUX]
local auraPart = nil
Connections["GodMode"] = RunService.RenderStepped:Connect(function()
    -- Auto Pandemonium
    if Toggles.AutoPandemonium then
        pcall(function()
            local minigameGui = LocalPlayer.PlayerGui:FindFirstChild("PandemoniumMinigame") or LocalPlayer.PlayerGui:FindFirstChild("Minigame")
            if minigameGui and minigameGui.Enabled then
                local slider = minigameGui:FindFirstChild("Slider", true)
                local target = minigameGui:FindFirstChild("Target", true)
                if slider and target then
                    slider.Position = target.Position
                end
            end
        end)
    end

    -- Auto Cables & Force Unlock
    if (Toggles.AutoCables or Toggles.ForceUnlock) and LocalPlayer.Character then
        pcall(function()
            local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local dist = (root.Position - obj.Parent.WorldPosition).Magnitude
                        if dist < 15 then
                            if Toggles.AutoCables and (string.find(string.lower(obj.Parent.Name), "cable") or string.find(string.lower(obj.Parent.Name), "generator")) then
                                obj.HoldDuration = 0
                                firePrompt(obj)
                            end
                            if Toggles.ForceUnlock and string.find(string.lower(obj.Parent.Name), "lock") then
                                obj.HoldDuration = 0
                                firePrompt(obj)
                            end
                        end
                    end
                end
            end
        end)
    end

    -- Player Aura
    if Toggles.PlayerAura and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if not auraPart then
            auraPart = Instance.new("Part")
            auraPart.Size = Vector3.new(5, 0.1, 5)
            auraPart.Anchored = true
            auraPart.CanCollide = false
            auraPart.Material = Enum.Material.Neon
            auraPart.Color = Color3.fromRGB(0, 255, 255)
            auraPart.Parent = Workspace
            Instance.new("CylinderMesh", auraPart)
        end
        local pos = LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(0, 3, 0)
        auraPart.CFrame = CFrame.new(pos) * CFrame.Angles(0, tick() * 2, 0)
    else
        if auraPart then auraPart:Destroy(); auraPart = nil end
    end
end)

-- ==========================================
-- INTERFACE (ONGLETS)
-- ==========================================
Tabs.Main:AddToggle("EntityESP", {Title = "Entity ESP", Default = false}):OnChanged(function(v) Toggles.EntityESP = v end)
Tabs.Main:AddToggle("Notifs", {Title = "Notifications", Default = false}):OnChanged(function(v) Toggles.Notifications = v end)
Tabs.Main:AddToggle("Safezone", {Title = "Auto Safezone", Default = false}):OnChanged(function(v) Toggles.AutoSafezone = v end)

Tabs.Items:AddToggle("ItemESP", {Title = "Item ESP", Default = false}):OnChanged(function(v) Toggles.ItemESP = v end)
Tabs.Items:AddToggle("DoorESP", {Title = "Door ESP", Default = false}):OnChanged(function(v) Toggles.DoorESP = v end)
Tabs.Items:AddToggle("CodeESP", {Title = "Code/Password ESP", Default = false}):OnChanged(function(v) Toggles.CodeESP = v end)
Tabs.Items:AddToggle("Loot", {Title = "Auto-Loot Aura", Default = false}):OnChanged(function(v) Toggles.AutoLoot = v end)

-- [AJOUT MOKZ : REMPLISSAGE NOUVEL ONGLET]
Tabs.Minigames:AddParagraph({Title = "Assistance Avancée", Content = "Ces fonctions automatisent les mécaniques complexes du jeu."})
Tabs.Minigames:AddToggle("AutoPande", {Title = "Auto-Pandemonium (Casier)", Default = false}):OnChanged(function(v) Toggles.AutoPandemonium = v end)
Tabs.Minigames:AddToggle("AutoCable", {Title = "Auto-Répare Câbles/Générateurs", Default = false}):OnChanged(function(v) Toggles.AutoCables = v end)
Tabs.Minigames:AddToggle("ForceDoor", {Title = "Forcer Portes Verrouillées", Default = false}):OnChanged(function(v) Toggles.ForceUnlock = v end)

Tabs.Mods:AddToggle("CFSpeed", {Title = "Vitesse CFrame", Default = false}):OnChanged(function(v) Toggles.CFrameSpeed = v end)
Tabs.Mods:AddSlider("SurfSpeed", {Title = "Vitesse Surface", Min = 1, Max = 10, Default = 1, Callback = function(v) Toggles.SpeedSurface = v end})
Tabs.Mods:AddSlider("WatSpeed", {Title = "Vitesse Eaux", Min = 1, Max = 10, Default = 1, Callback = function(v) Toggles.SpeedWater = v end})
Tabs.Mods:AddToggle("AVoid", {Title = "Anti-Void Mass", Default = true}):OnChanged(function(v) Toggles.AntiVoid = v end)

Tabs.Visuals:AddToggle("Fullbright", {Title = "Fullbright", Default = false}):OnChanged(function(v) Toggles.Fullbright = v end)
Tabs.Visuals:AddToggle("NoFog", {Title = "No Fog / Steam", Default = false}):OnChanged(function(v) Toggles.NoFog = v end)
Tabs.Visuals:AddToggle("Aura", {Title = "Aura Céleste", Default = false}):OnChanged(function(v) Toggles.PlayerAura = v end) -- [AJOUT MOKZ]

Tabs.Settings:AddKeybind("MenuKey", {Title = "Touche Menu", Default = "RightControl", ChangedCallback = function(v) Window.MinimizeKey = v end})
Tabs.Settings:AddButton({Title = "Unload Script", Callback = function() getgenv().PressurePremium_Unload() end})

-- [AJOUT MOKZ : BOUTON FLOTTANT MOBILE]
local MobileGui = nil
if isMobile then
    MobileGui = Instance.new("ScreenGui", guiParent)
    MobileGui.Name = "MokzMobileToggle"
    MobileGui.ResetOnSpawn = false

    local ToggleBtn = Instance.new("TextButton", MobileGui)
    ToggleBtn.Size = UDim2.new(0, 45, 0, 45); ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20); ToggleBtn.Text = "🌊"; ToggleBtn.TextSize = 20
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
    local Stroke = Instance.new("UIStroke", ToggleBtn); Stroke.Color = Color3.fromRGB(0, 255, 255); Stroke.Thickness = 2

    ToggleBtn.MouseButton1Click:Connect(function()
        -- Simule l'appui de la touche pour ouvrir/fermer FluentUI
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Toggles.MinimizeKeyBind, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Toggles.MinimizeKeyBind, false, game)
    end)

    local drag, dStart, sPos
    ToggleBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then drag = true dStart = i.Position sPos = ToggleBtn.Position end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.Touch then local delta = i.Position - dStart; ToggleBtn.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

-- ==========================================
-- UNLOAD
-- ==========================================
getgenv().PressurePremium_Unload = function()
    for _, c in pairs(Connections) do pcall(function() c:Disconnect() end) end
    for e, _ in pairs(ESP_Cache) do removeESP(e) end
    if ESP_Folder then ESP_Folder:Destroy() end
    -- [AJOUT MOKZ : Nettoyage Aura et Bouton Mobile]
    if auraPart then auraPart:Destroy() end
    if MobileGui then MobileGui:Destroy() end
    
    Window:Destroy()
    getgenv().PressurePremium_Loaded = false
end

scanMap()
Fluent:Notify({Title = "Pressure Premium V3", Content = "Script Chargé ! " .. (isMobile and "Bouton mobile activé 🌊" or "Touche: RightControl"), Duration = 5})
