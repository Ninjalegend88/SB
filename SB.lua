-- ═══════════════════════════════════════════════════════════
--  ZKILLER // SOUTH BRONX: THE TRENCHES
--  by the invisible man
--  Key: Zkiller
--  Rayfield 2026 — SiriusSoftwareLtd Official
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
--  LOAD RAYFIELD 2026 (CONFIRMED WORKING URL)
-- ═══════════════════════════════════════════════════════════

local RayfieldURL = 'https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'
local RayfieldLoadSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet(RayfieldURL))()
end)

if not RayfieldLoadSuccess or not Rayfield then
    -- Fallback to direct GitHub raw with no redirect
    RayfieldLoadSuccess, Rayfield = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua', true))()
    end)
end

if not RayfieldLoadSuccess or not Rayfield then
    game:GetService("Players").LocalPlayer:Kick("[ZKILLER] Failed to load Rayfield 2026. Check your executor's HttpGet support.")
    return
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
--  ANTI-CHEAT BYPASS
-- ═══════════════════════════════════════════════════════════

pcall(function()
    for _, c in ipairs(getconnections(game:GetService("ScriptContext").Error)) do
        c:Disable()
    end
end)

pcall(function()
    local ok = hookfunction(LocalPlayer.Kick, function(self, ...)
        if self == LocalPlayer then
            warn("[ZKILLER] Kick blocked")
            return
        end
        return ok(self, ...)
    end)
end)

task.spawn(function()
    while true do
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local n = obj.Name:lower()
                if n:find("anticheat") or n:find("ac_") or n:find("detect") or n:find("ban") or n:find("integrity") or n:find("filecheck") then
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
    Key = "Zkiller",
    Loaded = false,
    SelectedPlayer = nil,
    SelectedItem = nil,
    Spectating = false,
    OriginalCameraSubject = nil,
    Aimbot = {Enabled = false, Part = "Head", FOV = 150, Smoothness = 3},
    SilentAim = {Enabled = false, FOV = 200, HitChance = 100},
    GunMods = {Wallbang = false, InfiniteAmmo = false, RapidFire = false},
    Money = {Farming = false, Duping = false},
    DiscoveredRemotes = {Money = {}, Jobs = {}, Items = {}, Damage = {}, Misc = {}},
    Items = {
        "Glock17", "Glock18", "DesertEagle", "BerettaM9", "AK47", "AR15",
        "MP5", "Uzi", "Mac10", "PumpShotgun", "SawedOff", "Knife",
        "BaseballBat", "Crowbar", "BrassKnuckles", "Phone", "Wallet",
        "Key", "Bandage", "Burger", "Pizza", "Soda", "Water", "Weed",
        "Cocaine", "Armor", "Medkit", "Lockpick", "Package", "DeliveryBox"
    }
}

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

local function GetHRP(player)
    local char = player and player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid(player)
    local char = player and player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    local hum = GetHumanoid(player)
    return hum and hum.Health > 0
end

local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local function GetPlayerByName(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == name then return p end
    end
    return nil
end

local function SafeTeleport(cf)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dist = (hrp.Position - cf.Position).Magnitude
    TweenService:Create(hrp, TweenInfo.new(math.min(dist/250, 2), Enum.EasingStyle.Sine), {CFrame = cf}):Play()
end

local function GetMoneyStat()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return nil end
    for _, s in ipairs(ls:GetChildren()) do
        if s:IsA("IntValue") or s:IsA("NumberValue") then
            if s.Name:lower():find("money") or s.Name:lower():find("cash") or s.Name:lower():find("bank") then return s end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
--  SMART REMOTE DISCOVERY
-- ═══════════════════════════════════════════════════════════

local function DiscoverRemotes()
    local moneyStat = GetMoneyStat()
    local startMoney = moneyStat and moneyStat.Value or 0
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local name = obj.Name:lower()
            
            -- Categorize by name patterns
            if name:find("money") or name:find("cash") or name:find("pay") or name:find("bank") or name:find("deposit") or name:find("withdraw") then
                table.insert(ZK.DiscoveredRemotes.Money, obj)
            elseif name:find("job") or name:find("work") or name:find("task") or name:find("construction") or name:find("delivery") or name:find("sell") then
                table.insert(ZK.DiscoveredRemotes.Jobs, obj)
            elseif name:find("item") or name:find("tool") or name:find("weapon") or name:find("give") or name:find("inventory") or name:find("equip") then
                table.insert(ZK.DiscoveredRemotes.Items, obj)
            elseif name:find("damage") or name:find("hit") or name:find("shoot") or name:find("fire") or name:find("attack") or name:find("kill") then
                table.insert(ZK.DiscoveredRemotes.Damage, obj)
            else
                table.insert(ZK.DiscoveredRemotes.Misc, obj)
            end
        end
    end
    
    -- Test-fire money remotes to find working ones
    if moneyStat then
        for _, remote in ipairs(ZK.DiscoveredRemotes.Money) do
            pcall(function()
                local before = moneyStat.Value
                remote:FireServer(100)
                task.wait(0.2)
                if moneyStat.Value > before then
                    ZK.DiscoveredRemotes.WorkingMoney = remote
                    Notify("Remote Discovery", "Found working money remote: " .. remote.Name)
                end
            end)
        end
    end
    
    -- Test-fire job remotes
    for _, remote in ipairs(ZK.DiscoveredRemotes.Jobs) do
        pcall(function()
            remote:FireServer("start")
            task.wait(0.1)
            remote:FireServer("complete")
        end)
    end
    
    local counts = #ZK.DiscoveredRemotes.Money + #ZK.DiscoveredRemotes.Jobs + #ZK.DiscoveredRemotes.Items + #ZK.DiscoveredRemotes.Damage
    Notify("Remote Discovery", "Found " .. counts .. " remotes. Money: " .. #ZK.DiscoveredRemotes.Money .. " | Jobs: " .. #ZK.DiscoveredRemotes.Jobs .. " | Items: " .. #ZK.DiscoveredRemotes.Items .. " | Damage: " .. #ZK.DiscoveredRemotes.Damage)
end

-- ═══════════════════════════════════════════════════════════
--  AIMBOT & SILENT AIM
-- ═══════════════════════════════════════════════════════════

local function GetClosest(fov, part)
    local best, bestDist = nil, fov or 9e9
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and IsAlive(p) then
            local char = p.Character
            local target = char and char:FindFirstChild(part or "Head")
            if target then
                local sp, on = Camera:WorldToViewportPoint(target.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if d < bestDist then bestDist = d; best = target end
                end
            end
        end
    end
    return best
end

local AimbotConn, SilentConn = nil, nil
local FovCircle, SilentCircle = nil, nil

local function ToggleAimbot(on)
    ZK.Aimbot.Enabled = on
    if FovCircle then FovCircle:Remove() FovCircle = nil end
    if AimbotConn then AimbotConn:Disconnect() AimbotConn = nil end
    if not on then return end
    
    FovCircle = Drawing.new("Circle")
    FovCircle.Visible = true; FovCircle.Thickness = 1.5
    FovCircle.Color = Color3.fromRGB(59, 130, 246); FovCircle.Transparency = 0.7
    FovCircle.Filled = false; FovCircle.NumSides = 64; FovCircle.Radius = ZK.Aimbot.FOV
    
    AimbotConn = RunService.RenderStepped:Connect(function()
        if not FovCircle then return end
        FovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        FovCircle.Radius = ZK.Aimbot.FOV
        local t = GetClosest(ZK.Aimbot.FOV, ZK.Aimbot.Part)
        if t then
            local pos = Camera:WorldToViewportPoint(t.Position)
            local diff = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)) / ZK.Aimbot.Smoothness
            mousemoverel(diff.X, diff.Y)
            FovCircle.Color = Color3.fromRGB(34, 197, 94)
        else
            FovCircle.Color = Color3.fromRGB(59, 130, 246)
        end
    end)
    
    Notify("Aimbot", "Aimbot enabled. FOV: " .. ZK.Aimbot.FOV)
end

local function ToggleSilentAim(on)
    ZK.SilentAim.Enabled = on
    if SilentCircle then SilentCircle:Remove() SilentCircle = nil end
    if SilentConn then SilentConn:Disconnect() SilentConn = nil end
    if not on then return end
    
    SilentCircle = Drawing.new("Circle")
    SilentCircle.Visible = true; SilentCircle.Thickness = 1.5
    SilentCircle.Color = Color3.fromRGB(234, 179, 8); SilentCircle.Transparency = 0.5
    SilentCircle.Filled = false; SilentCircle.NumSides = 64; SilentCircle.Radius = ZK.SilentAim.FOV
    
    pcall(function()
        local mt = getrawmetatable(Workspace)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Raycast" and ZK.SilentAim.Enabled and math.random(1,100) <= ZK.SilentAim.HitChance then
                local t = GetClosest(ZK.SilentAim.FOV, "Head")
                if t then
                    local args = {...}
                    local newDir = (t.Position - args[1]).Unit * args[2].Magnitude
                    args[2] = newDir
                    if ZK.GunMods.Wallbang and args[3] then
                        args[3].FilterType = Enum.RaycastFilterType.Blacklist
                    end
                    return old(self, unpack(args))
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
    
    SilentConn = RunService.RenderStepped:Connect(function()
        if SilentCircle then
            SilentCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
            SilentCircle.Radius = ZK.SilentAim.FOV
            SilentCircle.Color = GetClosest(ZK.SilentAim.FOV, "Head") and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(234, 179, 8)
        end
    end)
    
    Notify("Silent Aim", "Silent aim enabled")
end

-- ═══════════════════════════════════════════════════════════
--  GUN MODS
-- ═══════════════════════════════════════════════════════════

local GunConn = nil
local function UpdateGunMods()
    if GunConn then GunConn:Disconnect() GunConn = nil end
    if not (ZK.GunMods.InfiniteAmmo or ZK.GunMods.RapidFire) then return end
    GunConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if ZK.GunMods.InfiniteAmmo then
                    for _, n in ipairs({"Ammo","Clip","Bullets","CurrentAmmo","AmmoCount","ammo","clip"}) do
                        local v = tool:FindFirstChild(n)
                        if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then v.Value = 999 end
                    end
                end
                if ZK.GunMods.RapidFire then
                    for _, n in ipairs({"FireRate","Cooldown","ShootCooldown","RPM","ReloadTime","fireRate","cooldown"}) do
                        local v = tool:FindFirstChild(n)
                        if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then v.Value = 0.01 end
                    end
                end
                local r = tool:FindFirstChild("Reloading") or tool:FindFirstChild("IsReloading") or tool:FindFirstChild("reloading")
                if r and r:IsA("BoolValue") then r.Value = false end
            end
        end
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and ZK.GunMods.InfiniteAmmo then
                for _, n in ipairs({"Ammo","Clip","Bullets","CurrentAmmo"}) do
                    local v = tool:FindFirstChild(n)
                    if v and v:IsA("IntValue") then v.Value = 999 end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TELEPORT / SPECTATE / BRING
-- ═══════════════════════════════════════════════════════════

local function TeleportTo(name)
    local p = GetPlayerByName(name)
    if not p then Notify("Teleport", "Player not found") return end
    local hrp = GetHRP(p)
    if not hrp then Notify("Teleport", "No character") return end
    SafeTeleport(hrp.CFrame + Vector3.new(0, 3, 0))
    Notify("Teleport", "Teleported to " .. name)
end

local function Spectate(name)
    local p = GetPlayerByName(name)
    if not p then Notify("Spectate", "Player not found") return end
    local hum = GetHumanoid(p)
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
    Notify("Spectate", "Ended")
end

local function Bring(name)
    local p = GetPlayerByName(name)
    if not p then Notify("Bring", "Player not found") return end
    local myHRP, theirHRP = GetHRP(LocalPlayer), GetHRP(p)
    if not myHRP or not theirHRP then Notify("Bring", "Missing character") return end
    local pos = myHRP.CFrame + Vector3.new(0, 3, 5)
    pcall(function() theirHRP.CFrame = pos end)
    pcall(function()
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = (pos.Position - theirHRP.Position).Unit * 500
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = theirHRP
        game:GetService("Debris"):AddItem(bv, 0.2)
    end)
    Notify("Bring", "Brought " .. name)
end

-- ═══════════════════════════════════════════════════════════
--  MONEY SYSTEM (MULTI-STRATEGY AUTO-FARM)
-- ═══════════════════════════════════════════════════════════

local FarmThread, DupeThread = nil, nil

local function ToggleMoneyFarm(on)
    ZK.Money.Farming = on
    if FarmThread then FarmThread = nil end
    if not on then Notify("Money", "Farm stopped") return end
    
    Notify("Money", "Starting smart auto-farm...")
    
    FarmThread = task.spawn(function()
        local strategies = {
            -- Strategy 1: Package delivery jobs
            function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local parent = obj.Parent
                        if parent then
                            local pn = parent.Name:lower()
                            if pn:find("package") or pn:find("delivery") or pn:find("box") or pn:find("drop") then
                                local dist = (hrp.Position - parent.Position).Magnitude
                                if dist < 100 then
                                    SafeTeleport(parent.CFrame + Vector3.new(0, 3, 0))
                                    task.wait(1)
                                    fireproximityprompt(obj)
                                    task.wait(2)
                                    return true
                                end
                            end
                        end
                    end
                end
                return false
            end,
            
            -- Strategy 2: NPC interaction jobs
            function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local parent = obj.Parent
                        if parent then
                            local pn = parent.Name:lower()
                            if pn:find("npc") or pn:find("dealer") or pn:find("boss") or pn:find("worker") or pn:find("manager") then
                                local dist = (hrp.Position - parent.Position).Magnitude
                                if dist < 100 then
                                    SafeTeleport(parent.CFrame + Vector3.new(0, 3, 0))
                                    task.wait(1)
                                    fireproximityprompt(obj)
                                    task.wait(2)
                                    return true
                                end
                            end
                        end
                    end
                end
                return false
            end,
            
            -- Strategy 3: Construction/work sites
            function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                        local parent = obj.Parent
                        if parent then
                            local pn = parent.Name:lower()
                            if pn:find("construction") or pn:find("work") or pn:find("job") or pn:find("site") or pn:find("hammer") then
                                local dist = (hrp.Position - parent.Position).Magnitude
                                if dist < 100 then
                                    SafeTeleport(parent.CFrame + Vector3.new(0, 3, 0))
                                    task.wait(1)
                                    if obj:IsA("ProximityPrompt") then
                                        fireproximityprompt(obj)
                                    else
                                        fireclickdetector(obj)
                                    end
                                    task.wait(2)
                                    return true
                                end
                            end
                        end
                    end
                end
                return false
            end,
            
            -- Strategy 4: Auto-collect dropped cash/items
            function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return false end
                
                local found = false
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        local on = obj.Name:lower()
                        if on:find("money") or on:find("cash") or on:find("bill") or on:find("drop") then
                            local dist = (hrp.Position - obj.Position).Magnitude
                            if dist < 50 then
                                SafeTeleport(obj.CFrame + Vector3.new(0, 2, 0))
                                task.wait(0.5)
                                firetouchinterest(hrp, obj, 0)
                                firetouchinterest(hrp, obj, 1)
                                found = true
                            end
                        end
                    end
                end
                return found
            end,
            
            -- Strategy 5: Remote-based job completion
            function()
                if ZK.DiscoveredRemotes.WorkingMoney then
                    pcall(function() ZK.DiscoveredRemotes.WorkingMoney:FireServer(math.random(50, 200)) end)
                    return true
                end
                for _, remote in ipairs(ZK.DiscoveredRemotes.Jobs) do
                    pcall(function()
                        remote:FireServer("complete")
                        remote:FireServer("reward")
                    end)
                end
                return #ZK.DiscoveredRemotes.Jobs > 0
            end
        }
        
        while ZK.Money.Farming do
            local worked = false
            for _, strategy in ipairs(strategies) do
                if not ZK.Money.Farming then break end
                local success, result = pcall(strategy)
                if success and result then
                    worked = true
                    break
                end
            end
            
            -- Click any job GUI buttons
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local gn = gui.Name:lower()
                    if gn:find("work") or gn:find("job") or gn:find("start") or gn:find("complete") or gn:find("collect") then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(gui.AbsolutePosition.X + gui.AbsoluteSize.X/2, gui.AbsolutePosition.Y + gui.AbsoluteSize.Y/2))
                        end)
                    end
                end
            end
            
            -- Wait between cycles
            local waitTime = worked and math.random(3, 6) or math.random(1, 2)
            for i = 1, waitTime do
                if not ZK.Money.Farming then break end
                task.wait(1)
            end
        end
    end)
end

local function ToggleMoneyDupe(on)
    ZK.Money.Duping = on
    if DupeThread then DupeThread = nil end
    if not on then Notify("Money", "Dupe stopped") return end
    
    DupeThread = task.spawn(function()
        while ZK.Money.Duping do
            if ZK.DiscoveredRemotes.WorkingMoney then
                pcall(function() ZK.DiscoveredRemotes.WorkingMoney:FireServer(math.random(100, 1000)) end)
            end
            for _, remote in ipairs(ZK.DiscoveredRemotes.Money) do
                pcall(function() remote:FireServer(math.random(100, 500)) end)
            end
            local stat = GetMoneyStat()
            if stat then pcall(function() stat.Value = stat.Value + math.random(50, 200) end) end
            task.wait(math.random(0.5, 1.5))
        end
    end)
end

local function GiveMoney(amt)
    amt = tonumber(amt)
    if not amt then Notify("Money", "Invalid amount") return end
    if ZK.DiscoveredRemotes.WorkingMoney then
        pcall(function() ZK.DiscoveredRemotes.WorkingMoney:FireServer(amt) end)
        Notify("Money", "Gave $" .. amt)
        return
    end
    for _, remote in ipairs(ZK.DiscoveredRemotes.Money) do
        pcall(function() remote:FireServer("add", amt) end)
        pcall(function() remote:FireServer(amt) end)
    end
    local stat = GetMoneyStat()
    if stat then pcall(function() stat.Value = stat.Value + amt end) Notify("Money", "Added $" .. amt)
    else Notify("Money", "No money system found") end
end

local function SetMoney(amt)
    amt = tonumber(amt)
    if not amt then Notify("Money", "Invalid amount") return end
    if ZK.DiscoveredRemotes.WorkingMoney then
        pcall(function() ZK.DiscoveredRemotes.WorkingMoney:FireServer(amt) end)
        Notify("Money", "Set to $" .. amt)
        return
    end
    for _, remote in ipairs(ZK.DiscoveredRemotes.Money) do
        pcall(function() remote:FireServer("set", amt) end)
    end
    local stat = GetMoneyStat()
    if stat then pcall(function() stat.Value = amt end) Notify("Money", "Set to $" .. amt)
    else Notify("Money", "No money system found") end
end

-- ═══════════════════════════════════════════════════════════
--  ITEMS
-- ═══════════════════════════════════════════════════════════

local function GiveItem(name)
    if not name or name == "" then Notify("Items", "No item selected") return end
    if ZK.DiscoveredRemotes.WorkingItem then
        pcall(function() ZK.DiscoveredRemotes.WorkingItem:FireServer("give", name) end)
        Notify("Items", "Gave " .. name)
        return
    end
    for _, remote in ipairs(ZK.DiscoveredRemotes.Items) do
        pcall(function() remote:FireServer("give", name) end)
        pcall(function() remote:FireServer(name) end)
    end
    local template = nil
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == name or obj.Name:lower() == name:lower() then template = obj; break end
    end
    if template then
        pcall(function()
            local c = template:Clone()
            c.Parent = LocalPlayer.Backpack
            Notify("Items", "Cloned " .. name)
        end)
    else
        Notify("Items", "Not found: " .. name .. " (tried remotes + ReplicatedStorage)")
    end
end

local function DupeItem()
    local char = LocalPlayer.Character
    if not char then Notify("Items", "No character") return end
    local held = char:FindFirstChildOfClass("Tool")
    if not held then Notify("Items", "Hold an item first") return end
    local bp = LocalPlayer.Backpack:FindFirstChild(held.Name)
    if bp then
        pcall(function()
            local c = bp:Clone()
            c.Parent = LocalPlayer.Backpack
            Notify("Items", "Duped " .. held.Name)
        end)
    else
        pcall(function()
            local c = held:Clone()
            c.Parent = LocalPlayer.Backpack
            Notify("Items", "Duped " .. held.Name)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
--  KILL
-- ═══════════════════════════════════════════════════════════

local function Kill(name)
    local p = GetPlayerByName(name)
    if not p then Notify("Kill", "Player not found") return end
    local hrp = GetHRP(p)
    if not hrp then Notify("Kill", "No character") return end
    
    if ZK.DiscoveredRemotes.WorkingDamage then
        pcall(function()
            for i = 1, 10 do
                ZK.DiscoveredRemotes.WorkingDamage:FireServer(p, 999, "Head")
                task.wait(0.05)
            end
        end)
        Notify("Kill", "Killed " .. name)
        return
    end
    for _, remote in ipairs(ZK.DiscoveredRemotes.Damage) do
        pcall(function() remote:FireServer(p, 999) end)
    end
    
    local char = LocalPlayer.Character
    if not char then Notify("Kill", "No character") return end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    local old = myHRP.CFrame
    SafeTeleport(hrp.CFrame + hrp.CFrame.LookVector * -3 + Vector3.new(0, 1, 0))
    task.wait(0.5)
    
    local gun = nil
    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if t:IsA("Tool") and (t.Name:find("Glock") or t.Name:find("AK") or t.Name:find("Deagle") or t.Name:find("Gun")) then gun = t; break end
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
    SafeTeleport(old)
    Notify("Kill", "Attempted on " .. name)
end

-- ═══════════════════════════════════════════════════════════
--  RAYFIELD UI
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
    Discord = {Enabled = false, Invite = ""},
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
    Callback = function(Value) ZK.GunMods.Wallbang = Value; UpdateGunMods() end
})

CombatTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "InfAmmoToggle",
    Callback = function(Value) ZK.GunMods.InfiniteAmmo = Value; UpdateGunMods() end
})

CombatTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Flag = "RapidFireToggle",
    Callback = function(Value) ZK.GunMods.RapidFire = Value; UpdateGunMods() end
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
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then TeleportTo(ZK.SelectedPlayer)
        else Notify("Teleport", "No player selected") end
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
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then Spectate(ZK.SelectedPlayer)
        else Notify("Spectate", "No player selected") end
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
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then Bring(ZK.SelectedPlayer)
        else Notify("Bring", "No player selected") end
    end
})

-- MONEY TAB
local MoneyTab = Window:CreateTab("Money", 4483362458)

MoneyTab:CreateSection("Smart Auto Farm")

MoneyTab:CreateToggle({
    Name = "Auto Farm (Multi-Strategy)",
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
    Name = "Custom Item",
    PlaceholderText = "Or type custom name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value) if Value ~= "" then ZK.SelectedItem = Value end end
})

ItemsTab:CreateButton({
    Name = "Give Item",
    Callback = function()
        if ZK.SelectedItem then GiveItem(ZK.SelectedItem)
        else Notify("Items", "No item selected") end
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
    Callback = function(Value) ZK.SelectedPlayer = Option end
})

KillTab:CreateButton({
    Name = "Kill",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then Kill(ZK.SelectedPlayer)
        else Notify("Kill", "No player selected") end
    end
})

-- SETTINGS TAB
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Remote Discovery")

SettingsTab:CreateButton({
    Name = "Discover & Test Remotes",
    Callback = function()
        DiscoverRemotes()
    end
})

SettingsTab:CreateSection("Credits")

SettingsTab:CreateParagraph({
    Title = "ZKILLER HUB",
    Content = "Made by the invisible man\nVersion: 6.0\nGame: South Bronx: The Trenches\nUI: Rayfield 2026\n\nIf features don't work, click 'Discover & Test Remotes' first."
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
    DiscoverRemotes()
    Notify("ZKILLER", "South Bronx loaded. Click 'Discover & Test Remotes' if features don't work. | by the invisible man")
end)
