-- ╔══════════════════════════════════════════════════════════╗
-- ║               MOHA HUB v2.0 (PRESSURE)                   ║
-- ║       Smart Room Engine, Anti-Doublons & Godmode         ║
-- ╚══════════════════════════════════════════════════════════╝

if getgenv().MohaPressure_Loaded then
    if type(getgenv().MohaPressure_Unload) == "function" then getgenv().MohaPressure_Unload() end
end
getgenv().MohaPressure_Loaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local isMobile = UIS.TouchEnabled and not UIS.MouseEnabled

-- ══════════════════════════════════
--     COULEURS & THÈME
-- ══════════════════════════════════
local Colors = {
    Bg = Color3.fromRGB(10, 15, 20), Sidebar = Color3.fromRGB(15, 20, 30),
    Accent = Color3.fromRGB(0, 200, 255), AccentGlow = Color3.fromRGB(50, 220, 255),
    CardBg = Color3.fromRGB(20, 25, 35), Text = Color3.fromRGB(255, 255, 255),
    Monster = Color3.fromRGB(255, 50, 50), Item = Color3.fromRGB(50, 255, 100),
    Door = Color3.fromRGB(255, 200, 50), Currency = Color3.fromRGB(255, 215, 0),
    Delete = Color3.fromRGB(255, 60, 100)
}

local Toggles = {
    ESPItems = false, ESPDoors = false, ESPLockers = false, ESPCurrency = false,
    InstantInteract = false, Fullbright = false, AutoLoot = false, AlarmEnabled = true,
    Ent_Angler = true, Ent_Pinkie = true, Ent_Blitz = true, Ent_Chainsmoker = true,
    Ent_Froger = true, Ent_Pandemonium = true, Ent_Eyefestation = false, Ent_WallDweller = true,
    Del_Eyefestation = false, Del_EnragedEyefestation = false, Del_Searchlights = false,
    Del_ChaseSteam = false, Del_ChaseFan = false, Del_Fish = false, Del_Abomination = false,
    Del_Pipsqueak = false, Del_Baldi = false, Del_Bouncer = false, Del_Turret = false,
    Del_Pandemonium = false, Del_Statue = false, Del_BiggerStatue = false, Del_DiVine = false,
    Del_Skeleipede = false, Del_Parasite = false
}

local function create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local MainSize = isMobile and UDim2.new(0, 480, 0, 300) or UDim2.new(0, 680, 0, 440)
local MainPos = isMobile and UDim2.new(0.5, -240, 0.5, -150) or UDim2.new(0.5, -340, 0.5, -220)
local SidebarWidth = isMobile and 140 or 170

-- ══════════════════════════════════
--     NOTIFICATIONS CUSTOM
-- ══════════════════════════════════
local ScreenGui = create("ScreenGui", { Name = "MohaPressure", ResetOnSpawn = false, Parent = (gethui and gethui()) or CoreGui })
local NotifContainer = create("Frame", { Size = UDim2.new(0, 250, 0, 400), Position = UDim2.new(1, -20, 1, -20), AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, Parent = ScreenGui })
create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 10), Parent = NotifContainer })

local function ShowCustomAlert(title, message, color)
    local card = create("Frame", { Size = UDim2.new(1, 50, 0, 60), BackgroundColor3 = Colors.CardBg, BackgroundTransparency = 1, Parent = NotifContainer })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = card })
    local stroke = create("UIStroke", { Color = color, Thickness = 2, Transparency = 1, Parent = card })
    local titleLbl = create("TextLabel", { Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Text = title, TextColor3 = color, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = card })
    local descLbl = create("TextLabel", { Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 30), BackgroundTransparency = 1, Text = message, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, Parent = card })

    TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 0.1 }):Play()
    TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 0 }):Play()
    TweenService:Create(titleLbl, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
    TweenService:Create(descLbl, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()

    task.spawn(function()
        task.wait(4.5)
        TweenService:Create(card, TweenInfo.new(0.4), { Size = UDim2.new(0, 0, 0, 60), BackgroundTransparency = 1 }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
        TweenService:Create(titleLbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        TweenService:Create(descLbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        task.wait(0.4); card:Destroy()
    end)
end

-- ══════════════════════════════════
--     CRÉATION DU MENU PRINCIPAL
-- ══════════════════════════════════
local Main = create("Frame", { Size = MainSize, Position = MainPos, BackgroundColor3 = Colors.Bg, Parent = ScreenGui, Active = true, Draggable = true })
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Main })
create("UIStroke", { Color = Colors.Accent, Thickness = 1.5, Parent = Main })

local Sidebar = create("Frame", { Size = UDim2.new(0, SidebarWidth, 1, 0), BackgroundColor3 = Colors.Sidebar, Parent = Main })
create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Sidebar })
create("Frame", { Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Colors.Sidebar, BorderSizePixel = 0, Parent = Sidebar })
create("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Text = "MOHA HUB\n[PRESSURE]", TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = isMobile and 14 or 18, Parent = Sidebar })

local PagesFolder = create("Folder", { Parent = Main })
local tabsData = {}

local function CreateTab(name, icon, yPos)
    local btn = create("TextButton", { Size = UDim2.new(0, SidebarWidth - 20, 0, 35), Position = UDim2.new(0, 10, 0, yPos), BackgroundColor3 = Colors.CardBg, Text = "", AutoButtonColor = false, Parent = Sidebar })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    local stroke = create("UIStroke", { Color = Colors.Accent, Thickness = 1, Transparency = 1, Parent = btn })
    create("TextLabel", { Size = UDim2.new(0, 25, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = icon, TextColor3 = Colors.Text, Font = Enum.Font.Gotham, TextSize = 16, Parent = btn })
    create("TextLabel", { Size = UDim2.new(1, -35, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = isMobile and 11 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })

    local page = create("ScrollingFrame", { Size = UDim2.new(1, -(SidebarWidth + 20), 1, -20), Position = UDim2.new(0, SidebarWidth + 10, 0, 10), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Colors.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, Parent = PagesFolder })
    create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = page })
    table.insert(tabsData, { Button = btn, Page = page, Stroke = stroke })

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabsData) do t.Page.Visible = false; t.Stroke.Transparency = 1; t.Button.BackgroundColor3 = Colors.CardBg end
        page.Visible = true; stroke.Transparency = 0; btn.BackgroundColor3 = Color3.fromRGB(25, 35, 50)
    end)
    return page
end

local function CreateToggle(parent, text, key, callback, customColor)
    local frame = create("Frame", { Size = UDim2.new(1, -10, 0, 40), BackgroundColor3 = Colors.CardBg, Parent = parent })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
    create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Colors.Text, Font = Enum.Font.GothamBold, TextSize = isMobile and 11 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    
    local activeColor = customColor or Colors.Accent
    local btn = create("TextButton", { Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -50, 0.5, -10), BackgroundColor3 = Toggles[key] and activeColor or Color3.fromRGB(40, 45, 50), Text = "", Parent = frame })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
    local circle = create("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(Toggles[key] and 1 or 0, Toggles[key] and -18 or 2, 0.5, -8), BackgroundColor3 = Colors.Text, Parent = btn })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })

    btn.MouseButton1Click:Connect(function()
        Toggles[key] = not Toggles[key]
        TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Toggles[key] and activeColor or Color3.fromRGB(40, 45, 50) }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), { Position = UDim2.new(Toggles[key] and 1 or 0, Toggles[key] and -18 or 2, 0.5, -8) }):Play()
        if callback then callback(Toggles[key]) end
    end)
end

local TabScanner  = CreateTab("Scanner (ESP)", "👁️", 70)
local TabFilters  = CreateTab("Filtres ESP", "🐙", 115)
local TabDeleter  = CreateTab("Godmode Deleter", "🗑️", 160)
local TabCheats   = CreateTab("Exploits & Auto", "⚡", 205)

tabsData[1].Button.BackgroundColor3 = Color3.fromRGB(25, 35, 50); tabsData[1].Stroke.Transparency = 0; tabsData[1].Page.Visible = true

-- ══════════════════════════════════
--     LOGIQUE DELETER ULTIME
-- ══════════════════════════════════
local function SweepEntities()
    for _, obj in pairs(workspace:GetDescendants()) do
        if not obj or not obj.Parent then continue end
        local name = obj.Name:lower()

        if Toggles.Del_Eyefestation and name:find("eyefestation") and not name:find("enraged") then obj:Destroy() end
        if Toggles.Del_EnragedEyefestation and name:find("enraged") and name:find("eyefestation") then obj:Destroy() end
        if Toggles.Del_Searchlights and name:find("searchlight") then obj:Destroy() end
        if Toggles.Del_ChaseSteam and name:find("steam") then obj:Destroy() end
        if Toggles.Del_ChaseFan and name:find("fan") then obj:Destroy() end
        if Toggles.Del_Fish and name:find("fish") then obj:Destroy() end
        if Toggles.Del_Abomination and name:find("abomination") then obj:Destroy() end
        if Toggles.Del_Pipsqueak and name:find("pipsqueak") then obj:Destroy() end
        if Toggles.Del_Baldi and name:find("baldi") then obj:Destroy() end
        if Toggles.Del_Bouncer and name:find("bouncer") then obj:Destroy() end
        if Toggles.Del_Turret and name:find("turret") then obj:Destroy() end
        if Toggles.Del_Pandemonium and name:find("pandemonium") then obj:Destroy() end
        if Toggles.Del_Statue and name:find("statue") and not name:find("bigger") then obj:Destroy() end
        if Toggles.Del_BiggerStatue and name:find("bigger") and name:find("statue") then obj:Destroy() end
        if Toggles.Del_DiVine and name:find("divine") then obj:Destroy() end
        if Toggles.Del_Skeleipede and (name:find("skelepede") or name:find("skeleipede")) then obj:Destroy() end
        if Toggles.Del_Parasite and name:find("parasite") then obj:Destroy() end
    end
end
task.spawn(function() while task.wait(0.3) do SweepEntities() end end)

create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = " Supprimer Principaux :", TextColor3 = Colors.Delete, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabDeleter })
CreateToggle(TabDeleter, "🗑️ Remove Eyefestation", "Del_Eyefestation", nil, Colors.Delete)
CreateToggle(TabDeleter, "🗑️ Remove Enraged Eyefestation", "Del_EnragedEyefestation", nil, Colors.Delete)
CreateToggle(TabDeleter, "🗑️ Remove Pandemonium", "Del_Pandemonium", nil, Colors.Delete)
CreateToggle(TabDeleter, "🗑️ Remove Searchlights", "Del_Searchlights", nil, Colors.Delete)
CreateToggle(TabDeleter, "🗑️ Remove Chase Steam/Fan", "Del_ChaseSteam", nil, Colors.Delete)
CreateToggle(TabDeleter, "🗑️ Remove Turret", "Del_Turret", nil, Colors.Delete)
CreateToggle(TabDeleter, "🗑️ Remove Fish/Baldi/Bouncer...", "Del_Fish", nil, Colors.Delete)
TabDeleter.CanvasSize = UDim2.new(0,0,0, 450)

-- ══════════════════════════════════
--     LOGIQUE DU SCANNER V2.0 (ANTI-DOUBLONS & SMART DOORS)
-- ══════════════════════════════════
local ESPFolder = create("Folder", { Name = "MohaESP", Parent = CoreGui })
local function ClearESP() for _, child in pairs(ESPFolder:GetChildren()) do child:Destroy() end end

local function CreateESP(obj, text, color)
    if not obj or not obj.Parent then return end
    local hl = create("Highlight", { Parent = ESPFolder, Adornee = obj, FillColor = color, OutlineColor = color, FillTransparency = 0.75, OutlineTransparency = 0.2, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop })
    local bb = create("BillboardGui", { Parent = ESPFolder, Adornee = obj, Size = UDim2.new(0, 200, 0, 50), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 2, 0) })
    create("TextLabel", { Parent = bb, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = color, Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = 0 })
end

local function RefreshESP()
    ClearESP()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local espCache = {} -- Dictionnaire pour éviter de cibler 2 fois le même objet
    
    -- 1. SMART ROOM ENGINE (Trouver la vraie dernière salle générée)
    local latestRoom = nil
    local highestNum = -1
    
    -- Pressure génère les salles dans le Workspace avec des numéros (1, 2, 3...)
    local roomContainers = {workspace}
    if workspace:FindFirstChild("Rooms") then table.insert(roomContainers, workspace.Rooms) end
    
    for _, container in ipairs(roomContainers) do
        for _, room in pairs(container:GetChildren()) do
            local num = tonumber(room.Name)
            if num and num > highestNum then
                highestNum = num
                latestRoom = room
            end
        end
    end

    -- 2. DÉTECTION DES MONSTRES ET CASIERS (Par modèles complets)
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not espCache[obj] then
            local name = obj.Name:lower()
            
            -- Monstres
            if name:find("angler") and Toggles.Ent_Angler then CreateESP(obj, "⚠️ Angler", Colors.Monster); espCache[obj] = true
            elseif name:find("pinkie") and Toggles.Ent_Pinkie then CreateESP(obj, "⚠️ Pinkie", Colors.Monster); espCache[obj] = true
            elseif name:find("blitz") and Toggles.Ent_Blitz then CreateESP(obj, "⚠️ Blitz", Colors.Monster); espCache[obj] = true
            elseif name:find("chainsmoker") and Toggles.Ent_Chainsmoker then CreateESP(obj, "⚠️ Chainsmoker", Colors.Monster); espCache[obj] = true
            elseif name:find("froger") and Toggles.Ent_Froger then CreateESP(obj, "⚠️ Froger", Colors.Monster); espCache[obj] = true
            elseif name:find("pandemonium") and Toggles.Ent_Pandemonium then CreateESP(obj, "⚠️ Pandemonium", Colors.Monster); espCache[obj] = true
            elseif name:find("eyefestation") and Toggles.Ent_Eyefestation then CreateESP(obj, "👁️ Eyefestation", Color3.fromRGB(150, 0, 255)); espCache[obj] = true
            elseif name:find("walldweller") and Toggles.Ent_WallDweller then CreateESP(obj, "👀 Wall Dweller", Color3.fromRGB(200, 100, 100)); espCache[obj] = true
            end

            -- Casiers
            if Toggles.ESPLockers and not espCache[obj] then
                local isLocker = name:find("locker") or name:find("wardrobe") or name:find("closet")
                if isLocker and not (name:find("drawer") or name:find("shelf") or name:find("desk") or name:find("table")) then
                    local isTrapped = false
                    for _, child in pairs(obj:GetChildren()) do if child.Name:lower():find("void") then isTrapped = true break end end
                    if not isTrapped then CreateESP(obj, "🗄️ Cachette", Color3.fromRGB(150, 150, 150)); espCache[obj] = true end
                end
            end
        end
    end

    -- 3. DÉTECTION INTERACTIVE STRICTE (Items, Monnaie, Portes) -> On cherche SEULEMENT les boutons "E"
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local obj = prompt.Parent
            if not obj or espCache[obj] then continue end
            local name = obj.Name:lower()

            -- ESP Items & Passwords
            if Toggles.ESPItems then
                if name:find("keycard") or name:find("key") then CreateESP(obj, "🔑 " .. obj.Name, Colors.Door); espCache[obj] = true
                elseif name:find("medkit") or name:find("battery") or name:find("flashlight") or name:find("breacher") then CreateESP(obj, "📦 " .. obj.Name, Colors.Item); espCache[obj] = true
                elseif name:find("code") or name:find("paper") or name:find("folder") or name:find("password") or name:find("document") then CreateESP(obj, "📝 Info", Colors.Door); espCache[obj] = true
                end
            end

            -- ESP Currency
            if Toggles.ESPCurrency and not espCache[obj] then
                if name:find("kroner") or name:find("coin") or name:find("currency") or name:find("gold") then 
                    CreateESP(obj, "💰 Monnaie", Colors.Currency); espCache[obj] = true 
                end
            end

            -- ESP Vraie Porte (Smart Logic)
            if Toggles.ESPDoors and not espCache[obj] then
                if name:find("door") or name:find("nextroom") or name:find("entrance") then
                    if not (name:find("fake") or name:find("trick") or name:find("mimic") or name:find("dupe")) then
                        -- MAGIE : On vérifie si cette porte fait partie de la salle la plus avancée du jeu !
                        if latestRoom and obj:IsDescendantOf(latestRoom) then
                            CreateESP(obj, "🚪 VRAIE PROCHAINE PORTE", Colors.Accent)
                            espCache[obj] = true
                        end
                    end
                end
            end
        end
    end
end
task.spawn(function() while task.wait(1) do RefreshESP() end end)

create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = " Scanner des objets et zones :", TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = isMobile and 11 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabScanner })
CreateToggle(TabScanner, "💰 Monnaie/Kroner (Doré)", "ESPCurrency")
CreateToggle(TabScanner, "📦 Vrais Objets & Passwords (Vert)", "ESPItems")
CreateToggle(TabScanner, "🚪 Vraie Porte Principale (Anti-Retour)", "ESPDoors")
CreateToggle(TabScanner, "🗄️ Cachettes Sûres (Gris)", "ESPLockers")
TabScanner.CanvasSize = UDim2.new(0,0,0, 250)

-- ══════════════════════════════════
--     ONGLET FILTRES ESP
-- ══════════════════════════════════
create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = " Voir les monstres (ESP) :", TextColor3 = Colors.Monster, Font = Enum.Font.GothamBold, TextSize = isMobile and 11 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabFilters })
CreateToggle(TabFilters, "⚠️ Angler", "Ent_Angler")
CreateToggle(TabFilters, "⚠️ Pinkie", "Ent_Pinkie")
CreateToggle(TabFilters, "⚠️ Blitz", "Ent_Blitz")
CreateToggle(TabFilters, "⚠️ Chainsmoker", "Ent_Chainsmoker")
CreateToggle(TabFilters, "⚠️ Froger", "Ent_Froger")
CreateToggle(TabFilters, "⚠️ Pandemonium", "Ent_Pandemonium")
CreateToggle(TabFilters, "👁️ Eyefestation", "Ent_Eyefestation")
CreateToggle(TabFilters, "👀 Wall Dweller", "Ent_WallDweller")
TabFilters.CanvasSize = UDim2.new(0,0,0, 420)

-- ══════════════════════════════════
--     LOGIQUE DES EXPLOITS & AUTO
-- ══════════════════════════════════
create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = " Automatisation :", TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = isMobile and 11 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabCheats })

CreateToggle(TabCheats, "✨ Auto-Loot Total (Monnaie, Passwords, etc)", "AutoLoot")
CreateToggle(TabCheats, "⚡ Instant Interact Infaillible", "InstantInteract")

RunService.RenderStepped:Connect(function()
    if Toggles.InstantInteract then
        for _, prompt in pairs(workspace:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if Toggles.AutoLoot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrpPos = LocalPlayer.Character.HumanoidRootPart.Position
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Parent then
                    local name = prompt.Parent.Name:lower()
                    if name:find("key") or name:find("kroner") or name:find("coin") or name:find("medkit") or name:find("battery") or name:find("code") or name:find("paper") or name:find("folder") or name:find("crystal") then
                        if (prompt.Parent:GetPivot().Position - hrpPos).Magnitude < 16 then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
    end
end)

create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = " Survie :", TextColor3 = Colors.Accent, Font = Enum.Font.GothamBold, TextSize = isMobile and 11 or 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabCheats })
CreateToggle(TabCheats, "💡 Fullbright (Vision nocturne)", "Fullbright", function(state)
    if state then
        getgenv().LightingConn = RunService.RenderStepped:Connect(function()
            Lighting.Ambient = Color3.new(1, 1, 1); Lighting.Brightness = 3; Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
        end)
    else
        if getgenv().LightingConn then getgenv().LightingConn:Disconnect() end
        Lighting.GlobalShadows = true; Lighting.FogEnd = 250
    end
end)

CreateToggle(TabCheats, "🔔 Activer l'Alarme Custom (Bas-Droite)", "AlarmEnabled")
workspace.ChildAdded:Connect(function(obj)
    if Toggles.AlarmEnabled then
        local name = obj.Name:lower()
        if (name:find("angler") and Toggles.Ent_Angler) or (name:find("pinkie") and Toggles.Ent_Pinkie) or 
           (name:find("chainsmoker") and Toggles.Ent_Chainsmoker) or (name:find("blitz") and Toggles.Ent_Blitz) or 
           (name:find("froger") and Toggles.Ent_Froger) or (name:find("pandemonium") and Toggles.Ent_Pandemonium) then
            ShowCustomAlert("⚠️ MONSTRE DÉTECTÉ", "Un " .. obj.Name .. " arrive ! Cherche un casier !", Colors.Monster)
        end
    end
end)

TabCheats.CanvasSize = UDim2.new(0,0,0, 250)

-- ══════════════════════════════════
--     BOUTON MOBILE FLOTTANT
-- ══════════════════════════════════
if isMobile then
    local MobileBtn = create("TextButton", { Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0, 10, 0, 10), BackgroundColor3 = Colors.Bg, Text = "🌊", TextColor3 = Colors.AccentGlow, Font = Enum.Font.GothamBold, TextSize = 22, Parent = ScreenGui })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MobileBtn })
    create("UIStroke", { Color = Colors.Accent, Thickness = 2, Parent = MobileBtn })
    MobileBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)
    local drag, start, pos
    MobileBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then drag = true start = i.Position pos = MobileBtn.Position end end)
    UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.Touch then local delta = i.Position - start; MobileBtn.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y) end end)
    UIS.InputEnded:Connect(function() drag = false end)
end

getgenv().MohaPressure_Unload = function() ScreenGui:Destroy(); ClearESP(); getgenv().MohaPressure_Loaded = false end
print("🌊 MOHA HUB V2.0 [PRESSURE] - MOTEUR DE SALLES INTELLIGENT CHARGÉ !")
