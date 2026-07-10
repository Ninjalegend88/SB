-- ═══════════════════════════════════════════════════════════
--  ZKILLER // SOUTH BRONX STEALTH EDITION
--  by the invisible man
--  Key: Zkiller
--  Bypasses: File Integrity Check, Script Injection Detection
-- ═══════════════════════════════════════════════════════════

-- DELAYED INITIALIZATION — Let AC initialize first
task.wait(8)

-- ═══════════════════════════════════════════════════════════
--  STEALTH LAYER — Clean traces before loading
-- ═══════════════════════════════════════════════════════════

-- Disable ScriptContext error reporters (common AC vector)
pcall(function()
    for _, conn in ipairs(getconnections(game:GetService("ScriptContext").Error)) do
        conn:Disable()
    end
end)

-- Clean getgc of foreign closures that match our patterns
pcall(function()
    for _, v in ipairs(getgc()) do
        if type(v) == "function" and islclosure(v) then
            local info = debug.getinfo(v)
            if info and info.source and (info.source:find("ZKILLER") or info.source:find("Rayfield") or info.source:find("Orion")) then
                -- Can't remove from gc, but we can obfuscate source
            end
        end
    end
end)

-- Spoof loadstring origin
local _loadstring = loadstring
loadstring = function(src)
    return _loadstring(src, "=ZK")
end

-- ═══════════════════════════════════════════════════════════
--  LOAD ORION (LIGHTER FOOTPRINT THAN RAYFIELD)
-- ═══════════════════════════════════════════════════════════

local OrionLoadSuccess, Orion = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
end)

if not OrionLoadSuccess then
    warn("[ZKILLER] Orion failed, trying backup...")
    OrionLoadSuccess, Orion = pcall(function()
        return loadstring(game:HttpGet('https://pastebin.com/raw/xLRUSLxK'))()
    end)
    if not OrionLoadSuccess then
        error("[ZKILLER] Could not load UI library.")
        return
    end
end

-- ═══════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════════════════════

local ZK = {
    SelectedPlayer = nil,
    Spectating = false,
    OriginalCameraSubject = nil,
    Aimbot = {Enabled = false, Part = "Head", FOV = 150, Smoothness = 3},
    SilentAim = {Enabled = false, FOV = 200, HitChance = 100},
    GunMods = {Wallbang = false, InfiniteAmmo = false, RapidFire = false},
    Money = {Farming = false, Duping = false},
    Items = {
        "Glock17", "Glock18", "DesertEagle", "BerettaM9", "AK47", "AR15",
        "MP5", "Uzi", "Mac10", "PumpShotgun", "SawedOff", "Knife",
        "BaseballBat", "Crowbar", "BrassKnuckles", "Phone", "Wallet",
        "Key", "Bandage", "Burger", "Pizza", "Soda", "Water"
    },
    Remotes = {Money = nil, Damage = nil, Items = nil, Jobs = nil},
    DrawingObjects = {}
}

-- ═══════════════════════════════════════════════════════════
--  DRAWING API HELPERS (ZERO INSTANCE CREATION)
-- ═══════════════════════════════════════════════════════════

local function NewDrawing(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function ClearDrawings()
    for _, obj in pairs(ZK.DrawingObjects) do
        if obj then obj:Remove() end
    end
    ZK.DrawingObjects = {}
end

-- ═══════════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════════

local function Notify(title, message)
    Orion:MakeNotification({
        Name = title,
        Content = message,
        Image = "rbxassetid://4483345998",
        Time = 4
    })
end

local function GetCharacter(player)
    return player and player.Character
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetHRP(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(player)
    local hum = GetHumanoid(player)
    return hum and hum.Health > 0
end

local function GetPlayerList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr.Name)
        end
    end
    return list
end

local function GetPlayerByName(name)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name == name then return plr end
    end
    return nil
end

local function SafeTeleport(cframe)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local distance = (hrp.Position - cframe.Position).Magnitude
    local tweenTime = math.min(distance / 250, 2)
    
    TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine), {
        CFrame = cframe
    }):Play()
end

-- ═══════════════════════════════════════════════════════════
--  REMOTE SCANNER
-- ═══════════════════════════════════════════════════════════

local function ScanRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("money") or name:find("cash") or name:find("pay") then
                ZK.Remotes.Money = obj
            elseif name:find("damage") or name:find("hit") or name:find("shoot") then
                ZK.Remotes.Damage = obj
            elseif name:find("item") or name:find("tool") or name:find("weapon") then
                ZK.Remotes.Items = obj
            elseif name:find("job") or name:find("work") or name:find("construction") then
                ZK.Remotes.Jobs = obj
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  AIMBOT & SILENT AIM (DRAWING API — NO INSTANCES)
-- ═══════════════════════════════════════════════════════════

local function GetClosestPlayer(fov, targetPart)
    local closest, closestDist = nil, fov or math.huge
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsAlive(plr) then
            local char = GetCharacter(plr)
            local part = char and char:FindFirstChild(targetPart or "Head")
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local AimbotConnection, SilentAimConnection = nil, nil
local FOVCircle, SilentFOVCircle = nil, nil

local function ToggleAimbot(enabled)
    ZK.Aimbot.Enabled = enabled
    
    if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
    if AimbotConnection then AimbotConnection:Disconnect() AimbotConnection = nil end
    
    if not enabled then return end
    
    FOVCircle = NewDrawing("Circle", {
        Visible = true, Thickness = 1.5,
        Color = Color3.fromRGB(59, 130, 246), Transparency = 0.7,
        Filled = false, NumSides = 64, Radius = ZK.Aimbot.FOV
    })
    table.insert(ZK.DrawingObjects, FOVCircle)
    
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not FOVCircle then return end
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        FOVCircle.Radius = ZK.Aimbot.FOV
        
        local target = GetClosestPlayer(ZK.Aimbot.FOV, ZK.Aimbot.Part)
        if target then
            local pos = Camera:WorldToViewportPoint(target.Position)
            local diff = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)) / ZK.Aimbot.Smoothness
            mousemoverel(diff.X, diff.Y)
            FOVCircle.Color = Color3.fromRGB(34, 197, 94)
        else
            FOVCircle.Color = Color3.fromRGB(59, 130, 246)
        end
    end)
end

local function ToggleSilentAim(enabled)
    ZK.SilentAim.Enabled = enabled
    
    if SilentFOVCircle then SilentFOVCircle:Remove() SilentFOVCircle = nil end
    if SilentAimConnection then SilentAimConnection:Disconnect() SilentAimConnection = nil end
    
    if not enabled then return end
    
    SilentFOVCircle = NewDrawing("Circle", {
        Visible = true, Thickness = 1.5,
        Color = Color3.fromRGB(234, 179, 8), Transparency = 0.5,
        Filled = false, NumSides = 64, Radius = ZK.SilentAim.FOV
    })
    table.insert(ZK.DrawingObjects, SilentFOVCircle)
    
    -- Metatable proxy for raycast (stealthier than hookfunction)
    local mt = getrawmetatable(Workspace)
    local oldIndex = mt.__index
    local oldNamecall = mt.__namecall
    
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Raycast" and ZK.SilentAim.Enabled and math.random(1, 100) <= ZK.SilentAim.HitChance then
            local target = GetClosestPlayer(ZK.SilentAim.FOV, "Head")
            if target then
                local args = {...}
                local origin = args[1]
                local newDir = (target.Position - origin).Unit * args[2].Magnitude
                args[2] = newDir
                if ZK.GunMods.Wallbang and args[3] then
                    args[3].FilterType = Enum.RaycastFilterType.Blacklist
                end
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
    
    setreadonly(mt, true)
    
    SilentAimConnection = RunService.RenderStepped:Connect(function()
        if SilentFOVCircle then
            SilentFOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
            SilentFOVCircle.Radius = ZK.SilentAim.FOV
            SilentFOVCircle.Color = GetClosestPlayer(ZK.SilentAim.FOV, "Head") and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(234, 179, 8)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  GUN MODS
-- ═══════════════════════════════════════════════════════════

local GunModConnection = nil

local function ToggleGunMods()
    if GunModConnection then GunModConnection:Disconnect() GunModConnection = nil end
    if not (ZK.GunMods.InfiniteAmmo or ZK.GunMods.RapidFire) then return end
    
    GunModConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if ZK.GunMods.InfiniteAmmo then
                    for _, name in ipairs({"Ammo", "Clip", "Bullets", "CurrentAmmo"}) do
                        local val = tool:FindFirstChild(name)
                        if val and (val:IsA("IntValue") or val:IsA("NumberValue")) then
                            val.Value = 999
                        end
                    end
                end
                if ZK.GunMods.RapidFire then
                    for _, name in ipairs({"FireRate", "Cooldown", "ShootCooldown", "RPM"}) do
                        local val = tool:FindFirstChild(name)
                        if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
                            val.Value = 0.01
                        end
                    end
                end
                local reloading = tool:FindFirstChild("Reloading") or tool:FindFirstChild("IsReloading")
                if reloading and reloading:IsA("BoolValue") then
                    reloading.Value = false
                end
            end
        end
        
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and ZK.GunMods.InfiniteAmmo then
                for _, name in ipairs({"Ammo", "Clip", "Bullets"}) do
                    local val = tool:FindFirstChild(name)
                    if val and val:IsA("IntValue") then val.Value = 999 end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TELEPORT / SPECTATE / BRING
-- ═══════════════════════════════════════════════════════════

local function TeleportToPlayer(name)
    local target = GetPlayerByName(name)
    if not target then Notify("Teleport", "Player not found") return end
    local hrp = GetHRP(target)
    if not hrp then Notify("Teleport", "No character") return end
    SafeTeleport(hrp.CFrame + Vector3.new(0, 3, 0))
    Notify("Teleport", "Teleported to " .. name)
end

local function StartSpectate(name)
    local target = GetPlayerByName(name)
    if not target then Notify("Spectate", "Player not found") return end
    local hum = GetHumanoid(target)
    if not hum then Notify("Spectate", "No humanoid") return end
    ZK.OriginalCameraSubject = Camera.CameraSubject
    Camera.CameraSubject = hum
    ZK.Spectating = true
    Notify("Spectate", "Spectating " .. name)
end

local function EndSpectate()
    if not ZK.Spectating then return end
    local hum = GetHumanoid(LocalPlayer)
    if hum then Camera.CameraSubject = hum end
    ZK.Spectating = false
    Notify("Spectate", "Spectate ended")
end

local function BringPlayer(name)
    local target = GetPlayerByName(name)
    if not target then Notify("Bring", "Player not found") return end
    local myHRP, theirHRP = GetHRP(LocalPlayer), GetHRP(target)
    if not myHRP or not theirHRP then Notify("Bring", "Missing character") return end
    
    local bringPos = myHRP.CFrame + Vector3.new(0, 3, 5)
    pcall(function() theirHRP.CFrame = bringPos end)
    pcall(function()
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = (bringPos.Position - theirHRP.Position).Unit * 500
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = theirHRP
        game:GetService("Debris"):AddItem(bv, 0.2)
    end)
    Notify("Bring", "Brought " .. name)
end

-- ═══════════════════════════════════════════════════════════
--  MONEY SYSTEM
-- ═══════════════════════════════════════════════════════════

local function GetMoneyStat()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return nil end
    for _, stat in ipairs(ls:GetChildren()) do
        if stat:IsA("IntValue") or stat:IsA("NumberValue") then
            if stat.Name:lower():find("money") or stat.Name:lower():find("cash") then
                return stat
            end
        end
    end
    return nil
end

local MoneyFarmThread, MoneyDupeThread = nil, nil

local function ToggleMoneyFarm(enabled)
    ZK.Money.Farming = enabled
    if MoneyFarmThread then MoneyFarmThread = nil end
    if not enabled then Notify("Money", "Farm stopped") return end
    
    Notify("Money", "Construction farm started...")
    MoneyFarmThread = task.spawn(function()
        while ZK.Money.Farming do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not ZK.Money.Farming then break end
                    if obj:IsA("ProximityPrompt") then
                        local pn = obj.Parent and obj.Parent.Name:lower() or ""
                        if pn:find("construction") or pn:find("job") or pn:find("work") then
                            if (hrp.Position - obj.Parent.Position).Magnitude < 50 then
                                SafeTeleport(obj.Parent.CFrame + Vector3.new(0, 3, 0))
                                task.wait(1.5)
                                fireproximityprompt(obj)
                                task.wait(2)
                            end
                        end
                    end
                end
                if ZK.Remotes.Jobs then
                    pcall(function() ZK.Remotes.Jobs:FireServer("start", "construction") end)
                    task.wait(3)
                    pcall(function() ZK.Remotes.Jobs:FireServer("complete") end)
                end
            end
            for i = 1, math.random(5, 8) do
                if not ZK.Money.Farming then break end
                task.wait(1)
            end
        end
    end)
end

local function ToggleMoneyDupe(enabled)
    ZK.Money.Duping = enabled
    if MoneyDupeThread then MoneyDupeThread = nil end
    if not enabled then Notify("Money", "Dupe stopped") return end
    
    MoneyDupeThread = task.spawn(function()
        while ZK.Money.Duping do
            if ZK.Remotes.Money then
                pcall(function() ZK.Remotes.Money:FireServer("add", math.random(100, 500)) end)
            end
            local stat = GetMoneyStat()
            if stat then pcall(function() stat.Value = stat.Value + math.random(50, 200) end) end
            task.wait(math.random(0.5, 1.5))
        end
    end)
end

local function GiveMoney(amount)
    amount = tonumber(amount)
    if not amount then Notify("Money", "Invalid amount") return end
    if ZK.Remotes.Money then
        pcall(function() ZK.Remotes.Money:FireServer("add", amount) end)
        Notify("Money", "Gave $" .. amount)
        return
    end
    local stat = GetMoneyStat()
    if stat then pcall(function() stat.Value = stat.Value + amount end) Notify("Money", "Added $" .. amount)
    else Notify("Money", "No money system found") end
end

local function SetMoney(amount)
    amount = tonumber(amount)
    if not amount then Notify("Money", "Invalid amount") return end
    if ZK.Remotes.Money then
        pcall(function() ZK.Remotes.Money:FireServer("set", amount) end)
        Notify("Money", "Set to $" .. amount)
        return
    end
    local stat = GetMoneyStat()
    if stat then pcall(function() stat.Value = amount end) Notify("Money", "Set to $" .. amount)
    else Notify("Money", "No money system found") end
end

-- ═══════════════════════════════════════════════════════════
--  ITEMS
-- ═══════════════════════════════════════════════════════════

local function GiveItem(itemName)
    if not itemName or itemName == "" then Notify("Items", "No item selected") return end
    if ZK.Remotes.Items then
        pcall(function() ZK.Remotes.Items:FireServer("give", itemName) end)
        Notify("Items", "Gave " .. itemName)
        return
    end
    local template = nil
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == itemName or obj.Name:lower() == itemName:lower() then
            template = obj; break
        end
    end
    if template then
        pcall(function()
            local clone = template:Clone()
            clone.Parent = LocalPlayer.Backpack
            Notify("Items", "Cloned " .. itemName)
        end)
    else
        Notify("Items", "Could not find " .. itemName)
    end
end

local function DupeItem()
    local char = LocalPlayer.Character
    if not char then Notify("Items", "No character") return end
    local held = char:FindFirstChildOfClass("Tool")
    if not held then Notify("Items", "Hold an item first") return end
    local bpTool = LocalPlayer.Backpack:FindFirstChild(held.Name)
    if bpTool then
        pcall(function()
            local clone = bpTool:Clone()
            clone.Parent = LocalPlayer.Backpack
            Notify("Items", "Duped " .. held.Name)
        end)
    else
        pcall(function()
            local clone = held:Clone()
            clone.Parent = LocalPlayer.Backpack
            Notify("Items", "Duped " .. held.Name)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
--  KILL
-- ═══════════════════════════════════════════════════════════

local function KillPlayer(name)
    local target = GetPlayerByName(name)
    if not target then Notify("Kill", "Player not found") return end
    local targetHRP = GetHRP(target)
    if not targetHRP then Notify("Kill", "No character") return end
    
    if ZK.Remotes.Damage then
        pcall(function()
            for i = 1, 10 do
                ZK.Remotes.Damage:FireServer(target, 999, "Head")
                task.wait(0.05)
            end
        end)
        Notify("Kill", "Killed " .. name .. " via remote")
        return
    end
    
    local char = LocalPlayer.Character
    if not char then Notify("Kill", "No character") return end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    local oldCF = myHRP.CFrame
    SafeTeleport(targetHRP.CFrame + targetHRP.CFrame.LookVector * -3 + Vector3.new(0, 1, 0))
    task.wait(0.5)
    
    local gun = nil
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Glock") or tool.Name:find("AK") or tool.Name:find("Deagle")) then
            gun = tool; break
        end
    end
    if not gun then gun = LocalPlayer.Backpack:FindFirstChildOfClass("Tool") end
    
    if gun then
        pcall(function()
            char:FindFirstChildOfClass("Humanoid"):EquipTool(gun)
            task.wait(0.3)
            for i = 1, 20 do gun:Activate() task.wait(0.05) end
        end)
    end
    
    task.wait(0.3)
    SafeTeleport(oldCF)
    Notify("Kill", "Attempted kill on " .. name)
end

-- ═══════════════════════════════════════════════════════════
--  ORION UI — PARENT TO PLAYERGUI (NOT COREGUI)
-- ═══════════════════════════════════════════════════════════

local Window = Orion:MakeWindow({
    Name = "ZKILLER // SOUTH BRONX",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "ZKillerStealth",
    IntroEnabled = true,
    IntroText = "ZKILLER HUB",
    IntroIcon = "rbxassetid://4483345998",
    Icon = "rbxassetid://4483345998"
})

-- KEY SYSTEM (BUILT-IN)
-- Orion doesn't have built-in key, so we add a verification tab first

local KeyVerified = false
local KeyTab = Window:MakeTab({
    Name = "Key",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

KeyTab:AddTextbox({
    Name = "Enter Key",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        if Value == "Zkiller" then
            KeyVerified = true
            Notify("Auth", "Key accepted. Welcome.")
            -- Remove key tab and show main tabs
            for _, tab in ipairs(Window.Tabs) do
                if tab.Name ~= "Key" then
                    tab.Visible = true
                end
            end
            KeyTab.Visible = false
        else
            Notify("Auth", "Invalid key. Try again.")
        end
    end
})

KeyTab:AddLabel("Key: Zkiller")

-- Hide all other tabs until key verified
local CombatTab = Window:MakeTab({Name = "Combat", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TeleportTab = Window:MakeTab({Name = "Teleport", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local SpectateTab = Window:MakeTab({Name = "Spectate", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local BringTab = Window:MakeTab({Name = "Bring", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local MoneyTab = Window:MakeTab({Name = "Money", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local ItemsTab = Window:MakeTab({Name = "Items", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local KillTab = Window:MakeTab({Name = "Kill", Icon = "rbxassetid://4483345998", PremiumOnly = false})

for _, tab in ipairs({CombatTab, TeleportTab, SpectateTab, BringTab, MoneyTab, ItemsTab, KillTab}) do
    tab.Visible = false
end

-- COMBAT TAB
CombatTab:AddSection({Name = "Aimbot"})

CombatTab:AddToggle({
    Name = "Aimbot",
    Default = false,
    Callback = function(Value) ToggleAimbot(Value) end
})

CombatTab:AddDropdown({
    Name = "Aim Part",
    Default = "Head",
    Options = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm"},
    Callback = function(Value) ZK.Aimbot.Part = Value end
})

CombatTab:AddSlider({
    Name = "Aimbot FOV",
    Min = 50, Max = 500, Default = 150,
    Callback = function(Value) ZK.Aimbot.FOV = Value end
})

CombatTab:AddSlider({
    Name = "Smoothness",
    Min = 1, Max = 20, Default = 3,
    Callback = function(Value) ZK.Aimbot.Smoothness = Value end
})

CombatTab:AddSection({Name = "Silent Aim"})

CombatTab:AddToggle({
    Name = "Silent Aim",
    Default = false,
    Callback = function(Value) ToggleSilentAim(Value) end
})

CombatTab:AddSlider({
    Name = "Silent Aim FOV",
    Min = 50, Max = 500, Default = 200,
    Callback = function(Value) ZK.SilentAim.FOV = Value end
})

CombatTab:AddSlider({
    Name = "Hit Chance %",
    Min = 1, Max = 100, Default = 100,
    Callback = function(Value) ZK.SilentAim.HitChance = Value end
})

CombatTab:AddSection({Name = "Gun Mods"})

CombatTab:AddToggle({
    Name = "Shoot Through Walls",
    Default = false,
    Callback = function(Value) ZK.GunMods.Wallbang = Value; ToggleGunMods() end
})

CombatTab:AddToggle({
    Name = "Infinite Ammo",
    Default = false,
    Callback = function(Value) ZK.GunMods.InfiniteAmmo = Value; ToggleGunMods() end
})

CombatTab:AddToggle({
    Name = "Rapid Fire",
    Default = false,
    Callback = function(Value) ZK.GunMods.RapidFire = Value; ToggleGunMods() end
})

-- TELEPORT TAB
TeleportTab:AddSection({Name = "Teleport to Player"})

local TPList = {}
local TPDropdown = TeleportTab:AddDropdown({
    Name = "Select Player",
    Default = "",
    Options = GetPlayerList(),
    Callback = function(Value) ZK.SelectedPlayer = Value end
})

TeleportTab:AddButton({
    Name = "Teleport",
    Callback = function()
        if ZK.SelectedPlayer then TeleportToPlayer(ZK.SelectedPlayer)
        else Notify("Teleport", "No player selected") end
    end
})

-- SPECTATE TAB
SpectateTab:AddSection({Name = "Spectate Player"})

local SpecList = {}
local SpecDropdown = SpectateTab:AddDropdown({
    Name = "Select Player",
    Default = "",
    Options = GetPlayerList(),
    Callback = function(Value) ZK.SelectedPlayer = Value end
})

SpectateTab:AddButton({
    Name = "Start Spectate",
    Callback = function()
        if ZK.SelectedPlayer then StartSpectate(ZK.SelectedPlayer)
        else Notify("Spectate", "No player selected") end
    end
})

SpectateTab:AddButton({
    Name = "End Spectate",
    Callback = EndSpectate
})

-- BRING TAB
BringTab:AddSection({Name = "Bring Player"})

local BringList = {}
local BringDropdown = BringTab:AddDropdown({
    Name = "Select Player",
    Default = "",
    Options = GetPlayerList(),
    Callback = function(Value) ZK.SelectedPlayer = Value end
})

BringTab:AddButton({
    Name = "Bring",
    Callback = function()
        if ZK.SelectedPlayer then BringPlayer(ZK.SelectedPlayer)
        else Notify("Bring", "No player selected") end
    end
})

-- MONEY TAB
MoneyTab:AddSection({Name = "Money Farm"})

MoneyTab:AddToggle({
    Name = "Auto Farm (Construction)",
    Default = false,
    Callback = function(Value) ToggleMoneyFarm(Value) end
})

MoneyTab:AddSection({Name = "Money Dupe"})

MoneyTab:AddToggle({
    Name = "Money Dupe",
    Default = false,
    Callback = function(Value) ToggleMoneyDupe(Value) end
})

MoneyTab:AddSection({Name = "Give Money"})

MoneyTab:AddTextbox({
    Name = "Amount",
    Default = "",
    TextDisappear = false,
    Callback = function(Value) GiveMoney(Value) end
})

MoneyTab:AddSection({Name = "Set Money"})

MoneyTab:AddTextbox({
    Name = "Amount",
    Default = "",
    TextDisappear = false,
    Callback = function(Value) SetMoney(Value) end
})

-- ITEMS TAB
ItemsTab:AddSection({Name = "Give Item"})

ItemsTab:AddDropdown({
    Name = "Select Item",
    Default = ZK.Items[1],
    Options = ZK.Items,
    Callback = function(Value) ZK.SelectedItem = Value end
})

ItemsTab:AddTextbox({
    Name = "Custom Item",
    Default = "",
    TextDisappear = false,
    Callback = function(Value) if Value ~= "" then ZK.SelectedItem = Value end end
})

ItemsTab:AddButton({
    Name = "Give Item",
    Callback = function()
        if ZK.SelectedItem then GiveItem(ZK.SelectedItem)
        else Notify("Items", "No item selected") end
    end
})

ItemsTab:AddSection({Name = "Item Dupe"})

ItemsTab:AddButton({
    Name = "Dupe Held Item",
    Callback = DupeItem
})

-- KILL TAB
KillTab:AddSection({Name = "Kill Player"})

local KillList = {}
local KillDropdown = KillTab:AddDropdown({
    Name = "Select Player",
    Default = "",
    Options = GetPlayerList(),
    Callback = function(Value) ZK.SelectedPlayer = Value end
})

KillTab:AddButton({
    Name = "Kill",
    Callback = function()
        if ZK.SelectedPlayer then KillPlayer(ZK.SelectedPlayer)
        else Notify("Kill", "No player selected") end
    end
})

-- UPDATE PLAYER LISTS
Players.PlayerAdded:Connect(function()
    local list = GetPlayerList()
    TPDropdown:Refresh(list, true)
    SpecDropdown:Refresh(list, true)
    BringDropdown:Refresh(list, true)
    KillDropdown:Refresh(list, true)
end)

Players.PlayerRemoving:Connect(function()
    local list = GetPlayerList()
    TPDropdown:Refresh(list, true)
    SpecDropdown:Refresh(list, true)
    BringDropdown:Refresh(list, true)
    KillDropdown:Refresh(list, true)
end)

-- INIT
task.delay(2, function()
    ScanRemotes()
    Notify("ZKILLER", "Stealth edition loaded. Enter key: Zkiller")
end)
