-- ═══════════════════════════════════════════════════════════
--  ZKILLER // SOUTH BRONX: THE TRENCHES
--  by the invisible man
--  Key: Zkiller
--  PlaceId: 10179538382
--  Rayfield 2026 Edition
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
--  LOAD RAYFIELD 2026 (WITH FALLBACKS)
-- ═══════════════════════════════════════════════════════════

local RayfieldSources = {
    'https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua',
    'https://raw.githubusercontent.com/jensonhirst/Rayfield/main/source.lua',
    'https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua',
    'https://sirius.menu/rayfield'
}

local Rayfield = nil
for _, url in ipairs(RayfieldSources) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success and result then
        Rayfield = result
        break
    end
end

if not Rayfield then
    -- Final fallback: try to load from a known pastebin mirror
    local pbSuccess, pbResult = pcall(function()
        return loadstring(game:HttpGet('https://pastebin.com/raw/2UWky3wU'))()
    end)
    if pbSuccess and pbResult then
        Rayfield = pbResult
    else
        game:GetService("Players").LocalPlayer:Kick("[ZKILLER] Failed to load Rayfield UI. Update your executor or check internet connection.")
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
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  ANTI-CHEAT BYPASS (EXECUTE BEFORE ANYTHING ELSE)
-- ═══════════════════════════════════════════════════════════

pcall(function()
    -- Disable ScriptContext error reporters
    for _, conn in ipairs(getconnections(game:GetService("ScriptContext").Error)) do
        conn:Disable()
    end
end)

pcall(function()
    -- Hook kick to prevent AC kicks
    local oldKick = hookfunction(LocalPlayer.Kick, function(self, ...)
        if self == LocalPlayer then
            warn("[ZKILLER] Blocked kick attempt")
            return
        end
        return oldKick(self, ...)
    end)
end)

pcall(function()
    -- Spoof memory stats
    local stats = game:GetService("Stats")
    hookfunction(stats.GetTotalMemoryUsageMb, function()
        return math.random(800, 1200)
    end)
end)

-- Neutralize AC scripts periodically
task.spawn(function()
    while true do
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local name = obj.Name:lower()
                if name:find("anticheat") or name:find("anti-cheat") or name:find("ac_") or name:find("detect") or name:find("ban") or name:find("exploit") or name:find("cheat") or name:find("integrity") or name:find("filecheck") then
                    pcall(function() obj.Disabled = true end)
                end
            end
        end
        task.wait(3)
    end
end)

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
        "Key", "Bandage", "Burger", "Pizza", "Soda", "Water", "Weed",
        "Cocaine", "Meth", "Armor", "Medkit", "Lockpick"
    },
    Remotes = {Money = nil, Damage = nil, Items = nil, Jobs = nil},
    DrawingObjects = {}
}

-- ═══════════════════════════════════════════════════════════
--  DRAWING API HELPERS
-- ═══════════════════════════════════════════════════════════

local function NewDrawing(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

-- ═══════════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════════

local function Notify(title, message)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = 4,
        Image = 4483362458
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
            if name:find("money") or name:find("cash") or name:find("pay") or name:find("bank") then
                ZK.Remotes.Money = obj
            elseif name:find("damage") or name:find("hit") or name:find("shoot") or name:find("fire") then
                ZK.Remotes.Damage = obj
            elseif name:find("item") or name:find("tool") or name:find("weapon") or name:find("inventory") then
                ZK.Remotes.Items = obj
            elseif name:find("job") or name:find("work") or name:find("construction") or name:find("task") then
                ZK.Remotes.Jobs = obj
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  AIMBOT & SILENT AIM
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
    
    -- Metatable proxy for silent aim
    pcall(function()
        local mt = getrawmetatable(Workspace)
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
    end)
    
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
                    for _, name in ipairs({"Ammo", "Clip", "Bullets", "CurrentAmmo", "AmmoCount"}) do
                        local val = tool:FindFirstChild(name)
                        if val and (val:IsA("IntValue") or val:IsA("NumberValue")) then
                            val.Value = 999
                        end
                    end
                end
                if ZK.GunMods.RapidFire then
                    for _, name in ipairs({"FireRate", "Cooldown", "ShootCooldown", "RPM", "ReloadTime"}) do
                        local val = tool:FindFirstChild(name)
                        if val and (val:IsA("NumberValue") or val:IsA("IntValue")) then
                            val.Value = 0.01
                        end
                    end
                end
                local reloading = tool:FindFirstChild("Reloading") or tool:FindFirstChild("IsReloading") or tool:FindFirstChild("reloading")
                if reloading and reloading:IsA("BoolValue") then
                    reloading.Value = false
                end
            end
        end
        
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and ZK.GunMods.InfiniteAmmo then
                for _, name in ipairs({"Ammo", "Clip", "Bullets", "CurrentAmmo"}) do
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
                        if pn:find("construction") or pn:find("job") or pn:find("work") or pn:find("boss") or pn:find("site") then
                            if (hrp.Position - obj.Parent.Position).Magnitude < 50 then
                                SafeTeleport(obj.Parent.CFrame + Vector3.new(0, 3, 0))
                                task.wait(1.5)
                                fireproximityprompt(obj)
                                task.wait(2)
                            end
                        end
                    end
                    if obj:IsA("ClickDetector") then
                        local pn = obj.Parent and obj.Parent.Name:lower() or ""
                        if pn:find("construction") or pn:find("job") or pn:find("work") then
                            if (hrp.Position - obj.Parent.Position).Magnitude < 50 then
                                SafeTeleport(obj.Parent.CFrame + Vector3.new(0, 3, 0))
                                task.wait(1.5)
                                fireclickdetector(obj)
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
    if stat then
        pcall(function() stat.Value = stat.Value + amount end)
        Notify("Money", "Added $" .. amount)
    else
        Notify("Money", "No money system found")
    end
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
    if stat then
        pcall(function() stat.Value = amount end)
        Notify("Money", "Set to $" .. amount)
    else
        Notify("Money", "No money system found")
    end
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
        if tool:IsA("Tool") and (tool.Name:find("Glock") or tool.Name:find("AK") or tool.Name:find("Deagle") or tool.Name:find("Gun")) then
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
--  RAYFIELD UI SETUP
-- ═══════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "ZKILLER // SOUTH BRONX",
    LoadingTitle = "ZKILLER HUB",
    LoadingSubtitle = "by the invisible man",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZKiller",
        FileName = "SouthBronxConfig"
    },
    Discord = {
        Enabled = false,
        Invite = ""
    },
    KeySystem = true,
    KeySettings = {
        Title = "ZKILLER AUTHENTICATION",
        Subtitle = "Enter your access key",
        Note = "Key: Zkiller",
        FileName = "ZKillerKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Zkiller"}
    }
})

-- COMBAT TAB
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value) ToggleAimbot(Value) end
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm"},
    CurrentOption = "Head",
    Flag = "AimPartDropdown",
    Callback = function(Value) ZK.Aimbot.Part = Value end
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Suffix = "px",
    Flag = "AimbotFOV",
    Callback = function(Value) ZK.Aimbot.FOV = Value end
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 3,
    Suffix = "",
    Flag = "AimbotSmooth",
    Callback = function(Value) ZK.Aimbot.Smoothness = Value end
})

CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(Value) ToggleSilentAim(Value) end
})

CombatTab:CreateSlider({
    Name = "Silent Aim FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 200,
    Suffix = "px",
    Flag = "SilentAimFOV",
    Callback = function(Value) ZK.SilentAim.FOV = Value end
})

CombatTab:CreateSlider({
    Name = "Hit Chance",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 100,
    Suffix = "%",
    Flag = "HitChance",
    Callback = function(Value) ZK.SilentAim.HitChance = Value end
})

CombatTab:CreateSection("Gun Mods")

CombatTab:CreateToggle({
    Name = "Shoot Through Walls",
    CurrentValue = false,
    Flag = "WallbangToggle",
    Callback = function(Value) ZK.GunMods.Wallbang = Value; ToggleGunMods() end
})

CombatTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "InfAmmoToggle",
    Callback = function(Value) ZK.GunMods.InfiniteAmmo = Value; ToggleGunMods() end
})

CombatTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Flag = "RapidFireToggle",
    Callback = function(Value) ZK.GunMods.RapidFire = Value; ToggleGunMods() end
})

-- TELEPORT TAB
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

TeleportTab:CreateSection("Teleport to Player")

local TPDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "TeleportDropdown",
    Callback = function(Option) ZK.SelectedPlayer = Option end
})

TeleportTab:CreateButton({
    Name = "Teleport",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            TeleportToPlayer(ZK.SelectedPlayer)
        else
            Notify("Teleport", "No player selected")
        end
    end
})

-- SPECTATE TAB
local SpectateTab = Window:CreateTab("Spectate", 4483362458)

SpectateTab:CreateSection("Spectate Player")

local SpecDropdown = SpectateTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "SpectateDropdown",
    Callback = function(Option) ZK.SelectedPlayer = Option end
})

SpectateTab:CreateButton({
    Name = "Start Spectate",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            StartSpectate(ZK.SelectedPlayer)
        else
            Notify("Spectate", "No player selected")
        end
    end
})

SpectateTab:CreateButton({
    Name = "End Spectate",
    Callback = EndSpectate
})

-- BRING TAB
local BringTab = Window:CreateTab("Bring", 4483362458)

BringTab:CreateSection("Bring Player")

local BringDropdown = BringTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "BringDropdown",
    Callback = function(Option) ZK.SelectedPlayer = Option end
})

BringTab:CreateButton({
    Name = "Bring",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            BringPlayer(ZK.SelectedPlayer)
        else
            Notify("Bring", "No player selected")
        end
    end
})

-- MONEY TAB
local MoneyTab = Window:CreateTab("Money", 4483362458)

MoneyTab:CreateSection("Money Farm")

MoneyTab:CreateToggle({
    Name = "Auto Farm (Construction Job)",
    CurrentValue = false,
    Flag = "MoneyFarmToggle",
    Callback = function(Value) ToggleMoneyFarm(Value) end
})

MoneyTab:CreateSection("Money Dupe")

MoneyTab:CreateToggle({
    Name = "Money Dupe",
    CurrentValue = false,
    Flag = "MoneyDupeToggle",
    Callback = function(Value) ToggleMoneyDupe(Value) end
})

MoneyTab:CreateSection("Give Money")

MoneyTab:CreateInput({
    Name = "Amount to Give",
    PlaceholderText = "Enter amount...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value) GiveMoney(Value) end
})

MoneyTab:CreateSection("Set Money")

MoneyTab:CreateInput({
    Name = "Set Amount",
    PlaceholderText = "Enter amount...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value) SetMoney(Value) end
})

-- ITEMS TAB
local ItemsTab = Window:CreateTab("Items", 4483362458)

ItemsTab:CreateSection("Give Item")

ItemsTab:CreateDropdown({
    Name = "Select Item",
    Options = ZK.Items,
    CurrentOption = ZK.Items[1],
    Flag = "ItemDropdown",
    Callback = function(Value) ZK.SelectedItem = Value end
})

ItemsTab:CreateInput({
    Name = "Custom Item Name",
    PlaceholderText = "Or type custom name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value) if Value ~= "" then ZK.SelectedItem = Value end end
})

ItemsTab:CreateButton({
    Name = "Give Item",
    Callback = function()
        if ZK.SelectedItem then
            GiveItem(ZK.SelectedItem)
        else
            Notify("Items", "No item selected")
        end
    end
})

ItemsTab:CreateSection("Item Dupe")

ItemsTab:CreateButton({
    Name = "Dupe Held Item",
    Callback = DupeItem
})

-- KILL TAB
local KillTab = Window:CreateTab("Kill", 4483362458)

KillTab:CreateSection("Kill Player")

local KillDropdown = KillTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "KillDropdown",
    Callback = function(Option) ZK.SelectedPlayer = Option end
})

KillTab:CreateButton({
    Name = "Kill",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            KillPlayer(ZK.SelectedPlayer)
        else
            Notify("Kill", "No player selected")
        end
    end
})

-- SETTINGS TAB
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Anti-Cheat")

SettingsTab:CreateButton({
    Name = "Scan Remotes",
    Callback = function()
        ScanRemotes()
        Notify("Scanner", "Remote scan complete")
    end
})

SettingsTab:CreateSection("Credits")

SettingsTab:CreateParagraph({
    Title = "ZKILLER HUB",
    Content = "Made by the invisible man\nVersion: 5.0\nGame: South Bronx: The Trenches\nUI: Rayfield 2026"
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
    Notify("ZKILLER", "South Bronx loaded. Key: Zkiller | by the invisible man")
end)
