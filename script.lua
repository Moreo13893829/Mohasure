-- ╔══════════════════════════════════════════════════════════╗
-- ║               PRESSURE PREMIUM ESP SCRIPT                ║
-- ║         Interface Fluent UI, Optimisé & Sécurisé         ║
-- ║         + FIX ESP (Limite Roblox 31) & TABS ORGANISÉS    ║
-- ╚══════════════════════════════════════════════════════════╝

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
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ON FORCE LE MODE MOBILE POUR QUE LE BOUTON APPARAISSE À 100%
local isMobile = true 

local guiParent = (gethui and gethui()) or CoreGui
local ESP_Folder = Instance.new("Folder", guiParent)
ESP_Folder.Name = "Pressure_ESP_Premium_Folder"

-- ==========================================
-- GESTION MÉMOIRE & TOGGLES
-- ==========================================
local ESP_Cache = {}
local Connections = {}
local NotifiedEntities = {}
local Prompt_Cache = {}
local DangerousEntitiesPresent = {}
local SafezoneSavedCFrame = nil
local IsInSafezone = false

local Toggles = {
    EntityESP = false, ItemESP = false, LockerESP = false, DoorESP = false, CodeESP = false,
    Notifications = false, Fullbright = false, NoFog = false, AutoInteract = false, AutoLoot = false, AntiVoid = true,
    AutoSafezone = false, CFrameSpeed = false, SpeedSurface = 1, SpeedWater = 1, InWater = false,
    MinimizeKeyBind = Enum.KeyCode.RightControl,
    
    -- Addons God Mode
    AutoPandemonium = false, AutoCables = false, ForceUnlock = false, PlayerAura = false
}

-- ==========================================
-- INTERFACE FLUENT UI
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
    SubTitle = "Premium Edition + Fix ESP",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 320), -- Taille optimisée
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Toggles.MinimizeKeyBind
})

local Tabs = {
    Main = Window:AddTab({ Title = "Accueil & Sécurité", Icon = "shield" }),
    Minigames = Window:AddTab({ Title = "Mini-Jeux (God)", Icon = "gamepad-2" }),
    Mods = Window:AddTab({ Title = "Mods & Bypass", Icon = "zap" }),
    Visuals = Window:AddTab({ Title = "Visuels & ESP", Icon = "eye" }), -- TOUT L'ESP EST ICI MAINTENANT
    Settings = Window:AddTab({ Title = "Paramètres", Icon = "settings" })
}

-- ==========================================
-- FONCTIONS ESP (CORRIGÉES POUR NE PLUS CRASH)
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
    
    -- FIX: On ne met le Highlight QUE sur les Monstres et Objets pour ne pas dépasser la limite de 31 de Roblox
    local highlight = nil
    if typeESP == "Entity" or typeESP == "Item" or typeESP == "Code" then
        highlight = Instance.new("Highlight", ESP_Folder)
        highlight.Name = name .. "_ESP"; highlight.FillColor = color; highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.5; highlight.OutlineTransparency = 0.1; highlight.Adornee = entity
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Enabled = false
    end
    
    local billboard = Instance.new("BillboardGui", ESP_Folder)
    billboard.Name = "Tag"; billboard.Adornee = entity; billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.StudsOffset = Vector3.new(0, (typeESP == "Item" and 1.5) or 3, 0); billboard.AlwaysOnTop = true; billboard.Enabled = false
    
    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = name; label.TextColor3 = color
    label.Font = Enum.Font.GothamBold; label.TextStrokeTransparency = 0; label.TextStrokeColor3 = Color3.new(0, 0, 0); label.TextSize = 13
    
    ESP_Cache[entity] = { Highlight = highlight, Billboard = billboard, Label = label, Type = typeESP, DisplayName = name }
end

local function notifyUser(title, text)
    if Toggles.Notifications then Fluent:Notify({Title = title, Content = text, Duration = 5}) end
end

local function getEntityPosition(entity)
    if not entity or not entity.Parent then return nil end
    if entity:IsA("Model") then return entity.PrimaryPart and entity.PrimaryPart.Position or (entity:FindFirstChildWhichIsA("BasePart", true) and entity:FindFirstChildWhichIsA("BasePart", true).Position) end
    if entity:IsA("BasePart") then return entity.Position end
    return nil
end

local function firePrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if fireproximityprompt then fireproximityprompt(prompt) else prompt:InputHoldBegin() task.wait(prompt.HoldDuration + 0.01) prompt:InputHoldEnd() end
end

-- ==========================================
-- BOUCLE PRINCIPALE DE DÉTECTION
-- ==========================================
local auraPart = nil

local EntityList = {
    ["pandemonium"] = Color3.fromRGB(255, 0, 0), ["angler"] = Color3.fromRGB(0, 255, 0),
    ["pinkie"] = Color3.fromRGB(255, 105, 180), ["blitz"] = Color3.fromRGB(0, 255, 255),
    ["froger"] = Color3.fromRGB(0, 128, 0), ["chainsmoker"] = Color3.fromRGB(128, 128, 128),
    ["eyefestation"] = Color3.fromRGB(173, 255, 47), ["searchlight"] = Color3.fromRGB(255, 255, 0),
    ["wall dweller"] = Color3.fromRGB(139, 69, 19), ["good boy"] = Color3.fromRGB(255, 215, 0),
    ["squiddles"] = Color3.fromRGB(128, 0, 128)
}

local ItemList = {
    ["keycard"] = Color3.fromRGB(0, 191, 255), ["medkit"] = Color3.fromRGB(255, 20, 147),
    ["battery"] = Color3.fromRGB(255, 255, 0), ["flashlight"] = Color3.fromRGB(255, 255, 255),
    ["code breaker"] = Color3.fromRGB(138, 43, 226), ["gold"] = Color3.fromRGB(255, 215, 0),
    ["currency"] = Color3.fromRGB(255, 215, 0)
}

local PasswordList = { ["terminal"] = Color3.fromRGB(200, 200, 200), ["station"] = Color3.fromRGB(200, 200, 200), ["keypad"] = Color3.fromRGB(200, 200, 200), ["password"] = Color3.fromRGB(200, 200, 200) }

local function checkEntity(obj)
    if not obj or not obj.Parent then return end
    local objName = string.lower(obj.Name)

    if obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 return end

    if Toggles.AntiVoid and string.find(objName, "void") then
        local p = obj.Parent
        if p and (string.find(string.lower(p.Name), "locker") or string.find(string.lower(p.Name), "wardrobe")) then
            removeESP(p); local prompt = p:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then prompt.Enabled = false end return
        end
    end

    if objName == "normaldoor" or objName == "nextdoor" or (obj:IsA("Model") and string.find(objName, "door") and obj:FindFirstChildWhichIsA("ProximityPrompt", true)) then
        if not ESP_Cache[obj] then createESP(obj, "🚪 Porte", Color3.new(1,1,1), "Door") end return
    end

    for pw, col in pairs(PasswordList) do
        if string.find(objName, pw) then if not ESP_Cache[obj] then createESP(obj, "🔑 Password", col, "Code") end return end
    end

    for ent, col in pairs(EntityList) do
        if string.find(objName, ent) then
            if ent == "searchlight" and string.find(objName, "camera") then continue end
            if ent == "eyefestation" and obj:IsA("Model") and not obj:FindFirstChild("Eye") then continue end
            if not ESP_Cache[obj] then
                createESP(obj, ent:gsub("^%l", string.upper), col, "Entity")
                if table.find({"angler", "pinkie", "blitz", "froger", "chainsmoker", "pandemonium"}, ent) then DangerousEntitiesPresent[obj] = true end
                if not NotifiedEntities[obj] then NotifiedEntities[obj] = true notifyUser("🚨 " .. ent:upper(), "Cachez-vous vite !") end
            end
            return
        end
    end

    for item, col in pairs(ItemList) do
        if string.find(objName, item) then
            if not ESP_Cache[obj] and obj:FindFirstChildWhichIsA("ProximityPrompt", true) then createESP(obj, item:gsub("^%l", string.upper), col, "Item") end return
        end
    end

    if string.find(objName, "locker") or string.find(objName, "wardrobe") then
        if not string.find(objName, "foot") and not string.find(objName, "desk") and not ESP_Cache[obj] then
            createESP(obj, "Cachette", Color3.fromRGB(0, 255, 127), "Locker")
        end
    end
end

Connections["DescendantAdded"] = Workspace.DescendantAdded:Connect(function(v)
    checkEntity(v)
    if v:IsA("ProximityPrompt") and v.Parent then checkEntity(v.Parent) end
end)

Connections["Update"] = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local myPos = char.HumanoidRootPart.Position

    -- God Mode : Câbles & Portes
    if (Toggles.AutoCables or Toggles.ForceUnlock) then
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and (char.HumanoidRootPart.Position - obj.Parent.WorldPosition).Magnitude < 15 then
                    if Toggles.AutoCables and (string.find(string.lower(obj.Parent.Name), "cable") or string.find(string.lower(obj.Parent.Name), "generator")) then obj.HoldDuration = 0; firePrompt(obj) end
                    if Toggles.ForceUnlock and string.find(string.lower(obj.Parent.Name), "lock") then obj.HoldDuration = 0; firePrompt(obj) end
                end
            end
        end)
    end

    -- God Mode : Pandemonium
    if Toggles.AutoPandemonium then
        pcall(function()
            local mg = LocalPlayer.PlayerGui:FindFirstChild("PandemoniumMinigame") or LocalPlayer.PlayerGui:FindFirstChild("Minigame")
            if mg and mg.Enabled then
                local s, t = mg:FindFirstChild("Slider", true), mg:FindFirstChild("Target", true)
                if s and t then s.Position = t.Position end
            end
        end)
    end

    -- Aura
    if Toggles.PlayerAura then
        if not auraPart then
            auraPart = Instance.new("Part", Workspace); auraPart.Size = Vector3.new(5, 0.1, 5); auraPart.Anchored = true
            auraPart.CanCollide = false; auraPart.Material = Enum.Material.Neon; auraPart.Color = Color3.fromRGB(0, 255, 255)
            Instance.new("CylinderMesh", auraPart)
        end
        auraPart.CFrame = CFrame.new(char.HumanoidRootPart.Position - Vector3.new(0, 3, 0)) * CFrame.Angles(0, tick() * 2, 0)
    else
        if auraPart then auraPart:Destroy() auraPart = nil end
    end

    -- Render ESP Fixé
    for ent, data in pairs(ESP_Cache) do
        if ent and ent.Parent then
            local p = getEntityPosition(ent)
            if p then
                local d = (myPos - p).Magnitude
                local show = Toggles[data.Type .. "ESP"] or (data.Type == "Code" and Toggles.CodeESP)
                
                if Toggles.AutoLoot and d < 15 and data.Type == "Item" then
                    local pr = ent:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pr and pr.Enabled then firePrompt(pr) end
                end

                if show and d < 2000 then
                    if data.Highlight then data.Highlight.Enabled = true end
                    data.Billboard.Enabled = true
                    data.Label.Text = string.format("%s\n[%dm]", data.DisplayName, math.floor(d))
                else
                    if data.Highlight then data.Highlight.Enabled = false end
                    data.Billboard.Enabled = false
                end
            end
        else removeESP(ent) end
    end
end)

-- ==========================================
-- BOUTON FLOTTANT MOBILE (FORCÉ)
-- ==========================================
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
        VirtualInputManager:SendKeyEvent(true, Toggles.MinimizeKeyBind, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Toggles.MinimizeKeyBind, false, game)
    end)

    local drag, dStart, sPos
    ToggleBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then drag = true dStart = i.Position sPos = ToggleBtn.Position end end)
    UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.Touch then local delta = i.Position - dStart; ToggleBtn.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then drag = false end end)
end

-- ==========================================
-- ONGLETS FLUENT UI ORGANISÉS
-- ==========================================
-- TAB 1 : MAIN
Tabs.Main:AddToggle("Notifs", {Title = "Notifications Entités", Default = false}):OnChanged(function(v) Toggles.Notifications = v end)
Tabs.Main:AddToggle("Safezone", {Title = "Auto Safezone (Cachette)", Default = false}):OnChanged(function(v) Toggles.AutoSafezone = v end)
Tabs.Main:AddToggle("Loot", {Title = "Auto-Loot (Ramassage auto)", Default = false}):OnChanged(function(v) Toggles.AutoLoot = v end)

-- TAB 2 : MINI-JEUX
Tabs.Minigames:AddParagraph({Title = "Assistance Avancée", Content = "Ces fonctions automatisent les mécaniques complexes du jeu."})
Tabs.Minigames:AddToggle("AutoPande", {Title = "Auto-Pandemonium", Default = false}):OnChanged(function(v) Toggles.AutoPandemonium = v end)
Tabs.Minigames:AddToggle("AutoCable", {Title = "Auto-Câbles/Générateurs", Default = false}):OnChanged(function(v) Toggles.AutoCables = v end)
Tabs.Minigames:AddToggle("ForceDoor", {Title = "Forcer Portes Verrouillées", Default = false}):OnChanged(function(v) Toggles.ForceUnlock = v end)

-- TAB 3 : VISUELS & ESP (TOUT EST ICI MAINTENANT)
Tabs.Visuals:AddParagraph({Title = "Système ESP", Content = "Active la vision à travers les murs."})
Tabs.Visuals:AddToggle("EntityESP", {Title = "ESP Monstres / Entités", Default = false}):OnChanged(function(v) Toggles.EntityESP = v end)
Tabs.Visuals:AddToggle("ItemESP", {Title = "ESP Objets (Clés, Piles...)", Default = false}):OnChanged(function(v) Toggles.ItemESP = v end)
Tabs.Visuals:AddToggle("DoorESP", {Title = "ESP Portes", Default = false}):OnChanged(function(v) Toggles.DoorESP = v end)
Tabs.Visuals:AddToggle("CodeESP", {Title = "ESP Codes / Terminaux", Default = false}):OnChanged(function(v) Toggles.CodeESP = v end)
Tabs.Visuals:AddToggle("LockerESP", {Title = "ESP Casiers Sécurisés", Default = false}):OnChanged(function(v) Toggles.LockerESP = v end)

Tabs.Visuals:AddParagraph({Title = "Modifications d'Écran", Content = "Améliore la visibilité globale."})
Tabs.Visuals:AddToggle("Fullbright", {Title = "Fullbright (Lumière max)", Default = false}):OnChanged(function(v) Toggles.Fullbright = v Lighting.Brightness = v and 2 or 1 Lighting.Ambient = v and Color3.new(1,1,1) or Color3.new(0,0,0) end)
Tabs.Visuals:AddToggle("NoFog", {Title = "Retirer le Brouillard", Default = false}):OnChanged(function(v) Toggles.NoFog = v end)
Tabs.Visuals:AddToggle("Aura", {Title = "Aura Joueur Céleste", Default = false}):OnChanged(function(v) Toggles.PlayerAura = v end)

-- TAB 4 : MODS
Tabs.Mods:AddToggle("CFSpeed", {Title = "Vitesse CFrame", Default = false}):OnChanged(function(v) Toggles.CFrameSpeed = v end)
Tabs.Mods:AddSlider("SurfSpeed", {Title = "Vitesse Surface", Min = 1, Max = 10, Default = 1, Callback = function(v) Toggles.SpeedSurface = v end})
Tabs.Mods:AddSlider("WatSpeed", {Title = "Vitesse Eaux", Min = 1, Max = 10, Default = 1, Callback = function(v) Toggles.SpeedWater = v end})
Tabs.Mods:AddToggle("AVoid", {Title = "Anti-Void Mass", Default = true}):OnChanged(function(v) Toggles.AntiVoid = v end)

-- TAB 5 : SETTINGS
Tabs.Settings:AddKeybind("MenuKey", {Title = "Touche Menu", Default = "RightControl", ChangedCallback = function(v) Window.MinimizeKey = v end})
Tabs.Settings:AddButton({Title = "Unload Script (Détruire)", Callback = function() getgenv().PressurePremium_Unload() end})

-- ==========================================
-- UNLOAD
-- ==========================================
getgenv().PressurePremium_Unload = function()
    for _, c in pairs(Connections) do pcall(function() c:Disconnect() end) end
    for e, _ in pairs(ESP_Cache) do removeESP(e) end
    if ESP_Folder then ESP_Folder:Destroy() end
    if auraPart then auraPart:Destroy() end
    if MobileGui then MobileGui:Destroy() end
    Window:Destroy()
    getgenv().PressurePremium_Loaded = false
end

for _, v in ipairs(Workspace:GetDescendants()) do task.spawn(checkEntity, v) end
Fluent:Notify({Title = "Pressure Premium", Content = "Script Chargé ! Bouton mobile activé 🌊", Duration = 5})
