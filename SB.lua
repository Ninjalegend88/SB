-- ═══════════════════════════════════════════════════════════
--  ZKILLER // SOUTH BRONX: THE TRENCHES
--  by the invisible man
--  Key: Zkiller
--  ZERO EXTERNAL DEPENDENCIES — PURE LUA
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

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
    Remotes = {},
    DrawingObjects = {},
    Connections = {},
    Theme = {
        BG = Color3.fromRGB(8, 8, 18),
        Panel = Color3.fromRGB(18, 18, 38),
        Accent = Color3.fromRGB(59, 130, 246),
        AccentDark = Color3.fromRGB(37, 99, 235),
        Text = Color3.fromRGB(240, 240, 255),
        SubText = Color3.fromRGB(147, 153, 170),
        Success = Color3.fromRGB(34, 197, 94),
        Error = Color3.fromRGB(239, 68, 68)
    },
    Items = {"Glock17","Glock18","DesertEagle","AK47","AR15","MP5","Uzi","Mac10","PumpShotgun","SawedOff","Knife","BaseballBat","Crowbar","BrassKnuckles","Phone","Wallet","Key","Bandage","Burger","Pizza","Soda","Water","Weed","Armor","Medkit","Lockpick"}
}

-- ═══════════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════════

local function Notify(title, text)
    local notif = Instance.new("ScreenGui")
    notif.Name = "ZK_N"..tostring(math.random(100000,999999))
    notif.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 70)
    frame.Position = UDim2.new(1, 20, 0, 80)
    frame.BackgroundColor3 = ZK.Theme.Panel
    frame.BorderSizePixel = 0
    frame.Parent = notif
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = ZK.Theme.Accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = frame
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = ZK.Theme.Accent
    bar.BorderSizePixel = 0
    bar.Parent = frame
    
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, -20, 0, 22)
    t1.Position = UDim2.new(0, 15, 0, 8)
    t1.BackgroundTransparency = 1
    t1.Text = title
    t1.TextColor3 = ZK.Theme.Text
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 14
    t1.TextXAlignment = Enum.TextXAlignment.Left
    t1.Parent = frame
    
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, -20, 0, 30)
    t2.Position = UDim2.new(0, 15, 0, 30)
    t2.BackgroundTransparency = 1
    t2.Text = text
    t2.TextColor3 = ZK.Theme.SubText
    t2.Font = Enum.Font.Gotham
    t2.TextSize = 12
    t2.TextXAlignment = Enum.TextXAlignment.Left
    t2.TextWrapped = true
    t2.Parent = frame
    
    TweenService:Create(frame, TweenInfo.new(0.5), {Position = UDim2.new(1, -300, 0, 80)}):Play()
    
    task.delay(3, function()
        TweenService:Create(frame, TweenInfo.new(0.4), {Position = UDim2.new(1, 20, 0, 80)}):Play()
        task.wait(0.4)
        notif:Destroy()
    end)
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

-- ═══════════════════════════════════════════════════════════
--  ANTI-CHEAT
-- ═══════════════════════════════════════════════════════════

pcall(function()
    for _, c in ipairs(getconnections(game:GetService("ScriptContext").Error)) do c:Disable() end
end)

pcall(function()
    local ok = hookfunction(LocalPlayer.Kick, function(self, ...)
        if self == LocalPlayer then Notify("AC", "Kick blocked") return end
        return ok(self, ...)
    end)
end)

task.spawn(function()
    while true do
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local n = obj.Name:lower()
                if n:find("anticheat") or n:find("ac_") or n:find("detect") or n:find("ban") or n:find("integrity") then
                    pcall(function() obj.Disabled = true end)
                end
            end
        end
        task.wait(3)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  REMOTE SCANNER
-- ═══════════════════════════════════════════════════════════

local function ScanRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("money") or n:find("cash") or n:find("pay") then ZK.Remotes.Money = obj
            elseif n:find("damage") or n:find("hit") or n:find("shoot") then ZK.Remotes.Damage = obj
            elseif n:find("item") or n:find("tool") or n:find("weapon") then ZK.Remotes.Items = obj
            elseif n:find("job") or n:find("work") or n:find("construction") then ZK.Remotes.Jobs = obj end
        end
    end
    Notify("Scanner", "Remotes scanned")
end

-- ═══════════════════════════════════════════════════════════
--  AIMBOT / SILENT AIM
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
    FovCircle.Color = ZK.Theme.Accent; FovCircle.Transparency = 0.7
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
            FovCircle.Color = ZK.Theme.Success
        else
            FovCircle.Color = ZK.Theme.Accent
        end
    end)
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
                    if ZK.GunMods.Wallbang and args[3] then args[3].FilterType = Enum.RaycastFilterType.Blacklist end
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
            SilentCircle.Color = GetClosest(ZK.SilentAim.FOV, "Head") and ZK.Theme.Success or Color3.fromRGB(234, 179, 8)
        end
    end)
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
                    for _, n in ipairs({"Ammo","Clip","Bullets","CurrentAmmo"}) do
                        local v = tool:FindFirstChild(n)
                        if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then v.Value = 999 end
                    end
                end
                if ZK.GunMods.RapidFire then
                    for _, n in ipairs({"FireRate","Cooldown","ShootCooldown","RPM"}) do
                        local v = tool:FindFirstChild(n)
                        if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then v.Value = 0.01 end
                    end
                end
                local r = tool:FindFirstChild("Reloading") or tool:FindFirstChild("IsReloading")
                if r and r:IsA("BoolValue") then r.Value = false end
            end
        end
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and ZK.GunMods.InfiniteAmmo then
                for _, n in ipairs({"Ammo","Clip","Bullets"}) do
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
    if not p then Notify("Teleport", "Not found") return end
    local hrp = GetHRP(p)
    if not hrp then Notify("Teleport", "No character") return end
    SafeTeleport(hrp.CFrame + Vector3.new(0, 3, 0))
    Notify("Teleport", "Teleported to " .. name)
end

local function Spectate(name)
    local p = GetPlayerByName(name)
    if not p then Notify("Spectate", "Not found") return end
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
    if not p then Notify("Bring", "Not found") return end
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
--  MONEY
-- ═══════════════════════════════════════════════════════════

local function GetMoneyStat()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if not ls then return nil end
    for _, s in ipairs(ls:GetChildren()) do
        if s:IsA("IntValue") or s:IsA("NumberValue") then
            if s.Name:lower():find("money") or s.Name:lower():find("cash") then return s end
        end
    end
    return nil
end

local FarmThread, DupeThread = nil, nil

local function ToggleMoneyFarm(on)
    ZK.Money.Farming = on
    if FarmThread then FarmThread = nil end
    if not on then Notify("Money", "Farm stopped") return end
    Notify("Money", "Farm started...")
    FarmThread = task.spawn(function()
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

local function ToggleMoneyDupe(on)
    ZK.Money.Duping = on
    if DupeThread then DupeThread = nil end
    if not on then Notify("Money", "Dupe stopped") return end
    DupeThread = task.spawn(function()
        while ZK.Money.Duping do
            if ZK.Remotes.Money then pcall(function() ZK.Remotes.Money:FireServer("add", math.random(100, 500)) end) end
            local s = GetMoneyStat()
            if s then pcall(function() s.Value = s.Value + math.random(50, 200) end) end
            task.wait(math.random(0.5, 1.5))
        end
    end)
end

local function GiveMoney(amt)
    amt = tonumber(amt)
    if not amt then Notify("Money", "Invalid") return end
    if ZK.Remotes.Money then
        pcall(function() ZK.Remotes.Money:FireServer("add", amt) end)
        Notify("Money", "Gave $" .. amt)
        return
    end
    local s = GetMoneyStat()
    if s then pcall(function() s.Value = s.Value + amt end) Notify("Money", "Added $" .. amt)
    else Notify("Money", "No money system") end
end

local function SetMoney(amt)
    amt = tonumber(amt)
    if not amt then Notify("Money", "Invalid") return end
    if ZK.Remotes.Money then
        pcall(function() ZK.Remotes.Money:FireServer("set", amt) end)
        Notify("Money", "Set to $" .. amt)
        return
    end
    local s = GetMoneyStat()
    if s then pcall(function() s.Value = amt end) Notify("Money", "Set to $" .. amt)
    else Notify("Money", "No money system") end
end

-- ═══════════════════════════════════════════════════════════
--  ITEMS
-- ═══════════════════════════════════════════════════════════

local function GiveItem(name)
    if not name or name == "" then Notify("Items", "No item") return end
    if ZK.Remotes.Items then
        pcall(function() ZK.Remotes.Items:FireServer("give", name) end)
        Notify("Items", "Gave " .. name)
        return
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
        Notify("Items", "Not found: " .. name)
    end
end

local function DupeItem()
    local char = LocalPlayer.Character
    if not char then Notify("Items", "No character") return end
    local held = char:FindFirstChildOfClass("Tool")
    if not held then Notify("Items", "Hold an item") return end
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
    if not p then Notify("Kill", "Not found") return end
    local hrp = GetHRP(p)
    if not hrp then Notify("Kill", "No character") return end
    
    if ZK.Remotes.Damage then
        pcall(function()
            for i = 1, 10 do
                ZK.Remotes.Damage:FireServer(p, 999, "Head")
                task.wait(0.05)
            end
        end)
        Notify("Kill", "Killed " .. name)
        return
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
        if t:IsA("Tool") and (t.Name:find("Glock") or t.Name:find("AK") or t.Name:find("Deagle")) then gun = t; break end
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
--  CUSTOM UI FRAMEWORK (NO EXTERNAL LIBRARIES)
-- ═══════════════════════════════════════════════════════════

local UI = {}
UI.ScreenGui = nil
UI.MainFrame = nil
UI.ContentFrame = nil
UI.Tabs = {}
UI.CurrentTab = nil

function UI:Create(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if parent then obj.Parent = parent end
    return obj
end

function UI:Init()
    self.ScreenGui = self:Create("ScreenGui", {Name = "ZKillerHub", ResetOnSpawn = false}, CoreGui)
    
    -- Shadow
    local shadow = self:Create("ImageLabel", {
        Size = UDim2.new(0, 770, 0, 500),
        Position = UDim2.new(0.5, -385, 0.5, -250),
        BackgroundTransparency = 1,
        Image = "rbxassetid://13160452137",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.6,
        ZIndex = -1
    }, self.ScreenGui)
    
    -- Main frame
    self.MainFrame = self:Create("Frame", {
        Size = UDim2.new(0, 750, 0, 480),
        Position = UDim2.new(0.5, -375, 0.5, -240),
        BackgroundColor3 = ZK.Theme.BG,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true
    }, self.ScreenGui)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 12)}, self.MainFrame)
    self:Create("UIStroke", {Color = ZK.Theme.Accent, Thickness = 1, Transparency = 0.4}, self.MainFrame)
    
    -- Title bar
    local titleBar = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ZK.Theme.Panel,
        BorderSizePixel = 0
    }, self.MainFrame)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 12)}, titleBar)
    self:Create("Frame", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = ZK.Theme.Panel, BorderSizePixel = 0}, titleBar)
    
    self:Create("TextLabel", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = "ZKILLER // SOUTH BRONX",
        TextColor3 = ZK.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    }, titleBar)
    
    self:Create("TextLabel", {
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(1, -260, 0, 0),
        BackgroundTransparency = 1,
        Text = "by the invisible man",
        TextColor3 = ZK.Theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right
    }, titleBar)
    
    -- Close button
    local closeBtn = self:Create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = ZK.Theme.Error,
        Text = "×",
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        BorderSizePixel = 0
    }, titleBar)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, closeBtn)
    closeBtn.MouseButton1Click:Connect(function() self.ScreenGui:Destroy() end)
    
    -- Minimize
    local minBtn = self:Create("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0, 5),
        BackgroundColor3 = Color3.fromRGB(234, 179, 8),
        Text = "−",
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        BorderSizePixel = 0
    }, titleBar)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, minBtn)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(self.MainFrame, TweenInfo.new(0.3), {
            Size = minimized and UDim2.new(0, 750, 0, 40) or UDim2.new(0, 750, 0, 480)
        }):Play()
    end)
    
    -- Sidebar
    local sidebar = self:Create("Frame", {
        Size = UDim2.new(0, 160, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = ZK.Theme.Panel,
        BorderSizePixel = 0
    }, self.MainFrame)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 12)}, sidebar)
    self:Create("Frame", {Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundColor3 = ZK.Theme.Panel, BorderSizePixel = 0}, sidebar)
    
    -- Content area
    self.ContentFrame = self:Create("Frame", {
        Size = UDim2.new(1, -170, 1, -50),
        Position = UDim2.new(0, 165, 0, 45),
        BackgroundColor3 = ZK.Theme.BG,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, self.MainFrame)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 8)}, self.ContentFrame)
    
    -- Tab container
    self.TabContainer = self:Create("ScrollingFrame", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = ZK.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    }, sidebar)
    self:Create("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, self.TabContainer)
    
    self.TabButtons = {}
    self.TabContents = {}
end

function UI:CreateTab(name, icon)
    local btn = self:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = ZK.Theme.BG,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = #self.TabContents + 1
    }, self.TabContainer)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    
    self:Create("TextLabel", {
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 8, 0, 5),
        BackgroundTransparency = 1,
        Text = icon or "◆",
        TextColor3 = ZK.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }, btn)
    
    local nameLabel = self:Create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 35, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = ZK.Theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, btn)
    
    local content = self:Create("ScrollingFrame", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = ZK.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false
    }, self.ContentFrame)
    self:Create("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    
    table.insert(self.TabContents, content)
    
    btn.MouseButton1Click:Connect(function()
        for _, c in ipairs(self.TabContents) do c.Visible = false end
        for _, b in ipairs(self.TabButtons) do
            b.BackgroundColor3 = ZK.Theme.BG
            b:FindFirstChildOfClass("TextLabel").TextColor3 = ZK.Theme.SubText
        end
        content.Visible = true
        btn.BackgroundColor3 = ZK.Theme.Accent
        nameLabel.TextColor3 = ZK.Theme.Text
        self.CurrentTab = content
    end)
    
    table.insert(self.TabButtons, btn)
    
    if #self.TabContents == 1 then
        btn.BackgroundColor3 = ZK.Theme.Accent
        nameLabel.TextColor3 = ZK.Theme.Text
        content.Visible = true
        self.CurrentTab = content
    end
    
    return content
end

function UI:CreateSection(parent, text)
    local label = self:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "═══ " .. text .. " ═══",
        TextColor3 = ZK.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }, parent)
    return label
end

function UI:CreateToggle(parent, text, callback)
    local frame = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = ZK.Theme.Panel,
        BorderSizePixel = 0
    }, parent)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    
    self:Create("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    
    local toggleBtn = self:Create("TextButton", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = ZK.Theme.BG,
        Text = "",
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, frame)
    self:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, toggleBtn)
    
    local knob = self:Create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = ZK.Theme.SubText,
        BorderSizePixel = 0
    }, toggleBtn)
    self:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    
    local enabled = false
    toggleBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = ZK.Theme.Accent}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8), BackgroundColor3 = ZK.Theme.Text}):Play()
        else
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = ZK.Theme.BG}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = ZK.Theme.SubText}):Play()
        end
        callback(enabled)
    end)
    
    return frame
end

function UI:CreateSlider(parent, text, min, max, default, callback)
    local frame = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = ZK.Theme.Panel,
        BorderSizePixel = 0
    }, parent)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    
    local valueLabel = self:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = text .. ": " .. default,
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    
    local track = self:Create("Frame", {
        Size = UDim2.new(1, -20, 0, 4),
        Position = UDim2.new(0, 10, 0, 32),
        BackgroundColor3 = ZK.Theme.BG,
        BorderSizePixel = 0
    }, frame)
    self:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
    
    local fill = self:Create("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = ZK.Theme.Accent,
        BorderSizePixel = 0
    }, track)
    self:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
    
    local knob = self:Create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
        BackgroundColor3 = ZK.Theme.Text,
        BorderSizePixel = 0
    }, track)
    self:Create("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    
    local dragging = false
    local value = default
    
    local function update(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (pos * (max - min)))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        knob.Position = UDim2.new(pos, -6, 0.5, -6)
        valueLabel.Text = text .. ": " .. value
        callback(value)
    end
    
    knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then update(input) end end)
    
    return frame
end

function UI:CreateDropdown(parent, text, options, callback)
    local frame = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = ZK.Theme.Panel,
        BorderSizePixel = 0
    }, parent)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    
    self:Create("TextLabel", {
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    
    local selected = self:Create("TextButton", {
        Size = UDim2.new(0, 120, 0, 25),
        Position = UDim2.new(1, -130, 0.5, -12),
        BackgroundColor3 = ZK.Theme.BG,
        Text = options[1] or "Select",
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        BorderSizePixel = 0
    }, frame)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, selected)
    
    local open = false
    local optionFrame = self:Create("Frame", {
        Size = UDim2.new(0, 120, 0, 0),
        Position = UDim2.new(1, -130, 0, 35),
        BackgroundColor3 = ZK.Theme.BG,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 10
    }, frame)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, optionFrame)
    
    for i, opt in ipairs(options) do
        local optBtn = self:Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, (i-1) * 25),
            BackgroundTransparency = 1,
            Text = opt,
            TextColor3 = ZK.Theme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            BorderSizePixel = 0,
            ZIndex = 10
        }, optionFrame)
        optBtn.MouseButton1Click:Connect(function()
            selected.Text = opt
            callback(opt)
            open = false
            optionFrame.Visible = false
            optionFrame.Size = UDim2.new(0, 120, 0, 0)
        end)
    end
    
    selected.MouseButton1Click:Connect(function()
        open = not open
        optionFrame.Visible = open
        optionFrame.Size = open and UDim2.new(0, 120, 0, #options * 25) or UDim2.new(0, 120, 0, 0)
    end)
    
    return {Frame = frame, Set = function(newOptions)
        for _, child in ipairs(optionFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for i, opt in ipairs(newOptions) do
            local optBtn = self:Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 25),
                Position = UDim2.new(0, 0, 0, (i-1) * 25),
                BackgroundTransparency = 1,
                Text = opt,
                TextColor3 = ZK.Theme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                BorderSizePixel = 0,
                ZIndex = 10
            }, optionFrame)
            optBtn.MouseButton1Click:Connect(function()
                selected.Text = opt
                callback(opt)
                open = false
                optionFrame.Visible = false
                optionFrame.Size = UDim2.new(0, 120, 0, 0)
            end)
        end
        selected.Text = newOptions[1] or "Select"
    end}
end

function UI:CreateButton(parent, text, callback)
    local btn = self:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = ZK.Theme.Accent,
        Text = text,
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
        AutoButtonColor = false
    }, parent)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, btn)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = ZK.Theme.AccentDark}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = ZK.Theme.Accent}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    
    return btn
end

function UI:CreateInput(parent, text, placeholder, callback)
    local frame = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 65),
        BackgroundColor3 = ZK.Theme.Panel,
        BorderSizePixel = 0
    }, parent)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 6)}, frame)
    
    self:Create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = ZK.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)
    
    local input = self:Create("TextBox", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 28),
        BackgroundColor3 = ZK.Theme.BG,
        Text = "",
        PlaceholderText = placeholder,
        TextColor3 = ZK.Theme.Text,
        PlaceholderColor3 = ZK.Theme.SubText,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        BorderSizePixel = 0
    }, frame)
    self:Create("UICorner", {CornerRadius = UDim.new(0, 4)}, input)
    
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then callback(input.Text) end
    end)
    
    return frame
end

-- ═══════════════════════════════════════════════════════════
--  KEY SYSTEM
-- ═══════════════════════════════════════════════════════════

local function ShowKeyUI()
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "ZK_Key"
    keyGui.Parent = CoreGui
    keyGui.ResetOnSpawn = false
    
    local blur = Instance.new("Frame")
    blur.Size = UDim2.new(1, 0, 1, 0)
    blur.BackgroundColor3 = Color3.new(0, 0, 0)
    blur.BackgroundTransparency = 0.4
    blur.BorderSizePixel = 0
    blur.Parent = keyGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 220)
    frame.Position = UDim2.new(0.5, -175, 0.5, -110)
    frame.BackgroundColor3 = ZK.Theme.BG
    frame.BorderSizePixel = 0
    frame.Parent = keyGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = ZK.Theme.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    local t1 = Instance.new("TextLabel")
    t1.Size = UDim2.new(1, 0, 0, 30)
    t1.Position = UDim2.new(0, 0, 0, 15)
    t1.BackgroundTransparency = 1
    t1.Text = "ZKILLER HUB"
    t1.TextColor3 = ZK.Theme.Accent
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 20
    t1.Parent = frame
    
    local t2 = Instance.new("TextLabel")
    t2.Size = UDim2.new(1, 0, 0, 20)
    t2.Position = UDim2.new(0, 0, 0, 45)
    t2.BackgroundTransparency = 1
    t2.Text = "by the invisible man"
    t2.TextColor3 = ZK.Theme.SubText
    t2.Font = Enum.Font.Gotham
    t2.TextSize = 12
    t2.Parent = frame
    
    local t3 = Instance.new("TextLabel")
    t3.Size = UDim2.new(1, 0, 0, 20)
    t3.Position = UDim2.new(0, 0, 0, 70)
    t3.BackgroundTransparency = 1
    t3.Text = "Enter Key to Continue"
    t3.TextColor3 = ZK.Theme.SubText
    t3.Font = Enum.Font.Gotham
    t3.TextSize = 12
    t3.Parent = frame
    
    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(0, 280, 0, 35)
    keyInput.Position = UDim2.new(0.5, -140, 0, 100)
    keyInput.BackgroundColor3 = ZK.Theme.Panel
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter Key..."
    keyInput.TextColor3 = ZK.Theme.Text
    keyInput.PlaceholderColor3 = ZK.Theme.SubText
    keyInput.Font = Enum.Font.Gotham
    keyInput.TextSize = 13
    keyInput.BorderSizePixel = 0
    keyInput.Parent = frame
    Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 6)
    
    local submit = Instance.new("TextButton")
    submit.Size = UDim2.new(0, 280, 0, 35)
    submit.Position = UDim2.new(0.5, -140, 0, 145)
    submit.BackgroundColor3 = ZK.Theme.Accent
    submit.Text = "SUBMIT"
    submit.TextColor3 = ZK.Theme.Text
    submit.Font = Enum.Font.GothamBold
    submit.TextSize = 14
    submit.BorderSizePixel = 0
    submit.Parent = frame
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 6)
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 190)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = ZK.Theme.Error
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.Parent = frame
    
    local function tryKey()
        if keyInput.Text == ZK.Key then
            TweenService:Create(frame, TweenInfo.new(0.3), {Size = UDim2.new(0, 350, 0, 0)}):Play()
            task.wait(0.3)
            keyGui:Destroy()
            ZK.Loaded = true
            BuildHub()
            Notify("ZKILLER", "Welcome. Key accepted.", 3)
        else
            status.Text = "Invalid Key. Try again."
            TweenService:Create(keyInput, TweenInfo.new(0.1), {BackgroundColor3 = ZK.Theme.Error}):Play()
            task.wait(0.1)
            TweenService:Create(keyInput, TweenInfo.new(0.3), {BackgroundColor3 = ZK.Theme.Panel}):Play()
        end
    end
    
    submit.MouseButton1Click:Connect(tryKey)
    keyInput.FocusLost:Connect(function(ep) if ep then tryKey() end end)
end

-- ═══════════════════════════════════════════════════════════
--  BUILD HUB
-- ═══════════════════════════════════════════════════════════

function BuildHub()
    UI:Init()
    
    -- TABS
    local combatTab = UI:CreateTab("Combat", "⚔")
    local teleportTab = UI:CreateTab("Teleport", "↗")
    local spectateTab = UI:CreateTab("Spectate", "👁")
    local bringTab = UI:CreateTab("Bring", "↙")
    local moneyTab = UI:CreateTab("Money", "$")
    local itemsTab = UI:CreateTab("Items", "📦")
    local killTab = UI:CreateTab("Kill", "💀")
    
    -- COMBAT TAB
    UI:CreateSection(combatTab, "Aimbot")
    
    UI:CreateToggle(combatTab, "Aimbot", function(v) ToggleAimbot(v) end)
    
    UI:CreateDropdown(combatTab, "Aim Part", {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm"}, function(v)
        ZK.Aimbot.Part = v
    end)
    
    UI:CreateSlider(combatTab, "Aimbot FOV", 50, 500, 150, function(v) ZK.Aimbot.FOV = v end)
    UI:CreateSlider(combatTab, "Smoothness", 1, 20, 3, function(v) ZK.Aimbot.Smoothness = v end)
    
    UI:CreateSection(combatTab, "Silent Aim")
    
    UI:CreateToggle(combatTab, "Silent Aim", function(v) ToggleSilentAim(v) end)
    UI:CreateSlider(combatTab, "Silent Aim FOV", 50, 500, 200, function(v) ZK.SilentAim.FOV = v end)
    UI:CreateSlider(combatTab, "Hit Chance %", 1, 100, 100, function(v) ZK.SilentAim.HitChance = v end)
    
    UI:CreateSection(combatTab, "Gun Mods")
    
    UI:CreateToggle(combatTab, "Shoot Through Walls", function(v)
        ZK.GunMods.Wallbang = v
        UpdateGunMods()
    end)
    
    UI:CreateToggle(combatTab, "Infinite Ammo", function(v)
        ZK.GunMods.InfiniteAmmo = v
        UpdateGunMods()
    end)
    
    UI:CreateToggle(combatTab, "Rapid Fire", function(v)
        ZK.GunMods.RapidFire = v
        UpdateGunMods()
    end)
    
    -- TELEPORT TAB
    UI:CreateSection(teleportTab, "Teleport to Player")
    
    local tpDropdown = UI:CreateDropdown(teleportTab, "Select Player", GetPlayerList(), function(v)
        ZK.SelectedPlayer = v
    end)
    
    UI:CreateButton(teleportTab, "Teleport", function()
        if ZK.SelectedPlayer then TeleportTo(ZK.SelectedPlayer) else Notify("Teleport", "No player selected") end
    end)
    
    -- SPECTATE TAB
    UI:CreateSection(spectateTab, "Spectate Player")
    
    local specDropdown = UI:CreateDropdown(spectateTab, "Select Player", GetPlayerList(), function(v)
        ZK.SelectedPlayer = v
    end)
    
    UI:CreateButton(spectateTab, "Start Spectate", function()
        if ZK.SelectedPlayer then Spectate(ZK.SelectedPlayer) else Notify("Spectate", "No player selected") end
    end)
    
    UI:CreateButton(spectateTab, "End Spectate", EndSpectate)
    
    -- BRING TAB
    UI:CreateSection(bringTab, "Bring Player")
    
    local bringDropdown = UI:CreateDropdown(bringTab, "Select Player", GetPlayerList(), function(v)
        ZK.SelectedPlayer = v
    end)
    
    UI:CreateButton(bringTab, "Bring", function()
        if ZK.SelectedPlayer then Bring(ZK.SelectedPlayer) else Notify("Bring", "No player selected") end
    end)
    
    -- MONEY TAB
    UI:CreateSection(moneyTab, "Money Farm")
    
    UI:CreateToggle(moneyTab, "Auto Farm (Construction)", function(v) ToggleMoneyFarm(v) end)
    
    UI:CreateSection(moneyTab, "Money Dupe")
    
    UI:CreateToggle(moneyTab, "Money Dupe", function(v) ToggleMoneyDupe(v) end)
    
    UI:CreateSection(moneyTab, "Give Money")
    
    UI:CreateInput(moneyTab, "Amount to Give", "Enter amount...", function(v) GiveMoney(v) end)
    
    UI:CreateSection(moneyTab, "Set Money")
    
    UI:CreateInput(moneyTab, "Set Amount", "Enter amount...", function(v) SetMoney(v) end)
    
    -- ITEMS TAB
    UI:CreateSection(itemsTab, "Give Item")
    
    UI:CreateDropdown(itemsTab, "Select Item", ZK.Items, function(v)
        ZK.SelectedItem = v
    end)
    
    UI:CreateInput(itemsTab, "Custom Item", "Or type custom...", function(v)
        if v ~= "" then ZK.SelectedItem = v end
    end)
    
    UI:CreateButton(itemsTab, "Give Item", function()
        if ZK.SelectedItem then GiveItem(ZK.SelectedItem) else Notify("Items", "No item selected") end
    end)
    
    UI:CreateSection(itemsTab, "Item Dupe")
    
    UI:CreateButton(itemsTab, "Dupe Held Item", DupeItem)
    
    -- KILL TAB
    UI:CreateSection(killTab, "Kill Player")
    
    local killDropdown = UI:CreateDropdown(killTab, "Select Player", GetPlayerList(), function(v)
        ZK.SelectedPlayer = v
    end)
    
    UI:CreateButton(killTab, "Kill", function()
        if ZK.SelectedPlayer then Kill(ZK.SelectedPlayer) else Notify("Kill", "No player selected") end
    end)
    
    -- Update player lists
    Players.PlayerAdded:Connect(function()
        local list = GetPlayerList()
        tpDropdown.Set(list)
        specDropdown.Set(list)
        bringDropdown.Set(list)
        killDropdown.Set(list)
    end)
    
    Players.PlayerRemoving:Connect(function()
        local list = GetPlayerList()
        tpDropdown.Set(list)
        specDropdown.Set(list)
        bringDropdown.Set(list)
        killDropdown.Set(list)
    end)
    
    -- Update canvas sizes
    for _, tab in ipairs(UI.TabContents) do
        local layout = tab:FindFirstChildOfClass("UIListLayout")
        if layout then
            tab.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end
    
    Notify("ZKILLER", "South Bronx loaded. by the invisible man", 4)
end

-- ═══════════════════════════════════════════════════════════
--  START
-- ═══════════════════════════════════════════════════════════

ShowKeyUI()
task.delay(3, ScanRemotes)
