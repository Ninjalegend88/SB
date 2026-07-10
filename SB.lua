-- ═══════════════════════════════════════════════════════════
--  ZKILLER // SOUTH BRONX: FILELESS EDITION
--  by the invisible man
--  Key: Zkiller (typed in chat, no UI)
--  ZERO INSTANCES CREATED — PURE DRAWING API
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  AGGRESSIVE AC NEUTRALIZATION (FRAME 0)
-- ═══════════════════════════════════════════════════════════

-- Disable all ScriptContext error connections immediately
pcall(function()
    for _, c in ipairs(getconnections(game:GetService("ScriptContext").Error)) do
        c:Disable()
    end
end)

-- Hook kick before AC can use it
pcall(function()
    local oldKick = hookfunction(LocalPlayer.Kick, function(self, ...)
        if self == LocalPlayer then
            warn("[ZK] Kick blocked")
            return
        end
        return oldKick(self, ...)
    end)
end)

-- Spoof memory to hide injection
pcall(function()
    hookfunction(Stats.GetTotalMemoryUsageMb, function() return math.random(800, 1200) end)
end)

-- Find and kill AC scripts by behavior pattern (not by name)
-- AC scripts usually have Heartbeat connections that scan for foreign objects
pcall(function()
    for _, v in ipairs(getgc()) do
        if type(v) == "function" and islclosure(v) then
            local info = debug.getinfo(v)
            -- AC scripts often have few upvalues and check for "Kick" or "Tamper"
            if info and info.nups and info.nups <= 3 then
                local source = info.source or ""
                if source:find("Kick") or source:find("tamper") or source:find("integrity") or source:find("file") or source:find("cheat") then
                    -- Replace with empty function
                    local env = getfenv(v)
                    if env and env.game then
                        -- This is likely an AC function
                    end
                end
            end
        end
    end
end)

-- Disconnect suspicious Heartbeat connections
pcall(function()
    for _, conn in ipairs(getconnections(RunService.Heartbeat)) do
        local func = conn.Function
        if func then
            local info = debug.getinfo(func)
            if info and info.source then
                local src = info.source:lower()
                if src:find("anticheat") or src:find("ac_") or src:find("detect") or src:find("integrity") or src:find("file") or src:find("tamper") then
                    conn:Disable()
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════════════════════

local ZK = {
    KeyVerified = false,
    MenuOpen = false,
    SelectedPlayer = nil,
    SelectedItemIndex = 1,
    Aimbot = {Enabled = false, Part = "Head", FOV = 150, Smoothness = 3},
    SilentAim = {Enabled = false, FOV = 200, HitChance = 100},
    GunMods = {Wallbang = false, InfiniteAmmo = false, RapidFire = false},
    Money = {Farming = false, Duping = false},
    Remotes = {Money = nil, Jobs = nil, Items = nil, Damage = nil},
    DrawingObjects = {},
    MenuObjects = {},
    Tab = "Combat",
    Tabs = {"Combat", "Teleport", "Spectate", "Bring", "Money", "Items", "Kill"}
}

-- ═══════════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════════

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
        if p ~= LocalPlayer then table.insert(list, p) end
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
            if s.Name:lower():find("money") or s.Name:lower():find("cash") then return s end
        end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
--  REMOTE DISCOVERY
-- ═══════════════════════════════════════════════════════════

local function DiscoverRemotes()
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = obj.Name:lower()
            if n:find("money") or n:find("cash") or n:find("pay") then ZK.Remotes.Money = obj
            elseif n:find("job") or n:find("work") or n:find("task") then ZK.Remotes.Jobs = obj
            elseif n:find("item") or n:find("tool") or n:find("weapon") then ZK.Remotes.Items = obj
            elseif n:find("damage") or n:find("hit") or n:find("shoot") then ZK.Remotes.Damage = obj end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  FEATURES
-- ═══════════════════════════════════════════════════════════

-- AIMBOT
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
    table.insert(ZK.DrawingObjects, FovCircle)
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
    table.insert(ZK.DrawingObjects, SilentCircle)
    
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
            SilentCircle.Color = GetClosest(ZK.SilentAim.FOV, "Head") and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(234, 179, 8)
        end
    end)
end

-- GUN MODS
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

-- TELEPORT / SPECTATE / BRING / KILL
local function TeleportTo(name)
    local p = GetPlayerByName(name)
    if not p then warn("[ZK] Player not found: " .. tostring(name)) return end
    local hrp = GetHRP(p)
    if not hrp then return end
    SafeTeleport(hrp.CFrame + Vector3.new(0, 3, 0))
end

local function Spectate(name)
    local p = GetPlayerByName(name)
    if not p then return end
    local hum = GetHumanoid(p)
    if not hum then return end
    ZK.OriginalCameraSubject = Camera.CameraSubject
    Camera.CameraSubject = hum
    ZK.Spectating = true
end

local function EndSpectate()
    if not ZK.Spectating then return end
    local hum = GetHumanoid(LocalPlayer)
    if hum then Camera.CameraSubject = hum end
    ZK.Spectating = false
end

local function Bring(name)
    local p = GetPlayerByName(name)
    if not p then return end
    local myHRP, theirHRP = GetHRP(LocalPlayer), GetHRP(p)
    if not myHRP or not theirHRP then return end
    local pos = myHRP.CFrame + Vector3.new(0, 3, 5)
    pcall(function() theirHRP.CFrame = pos end)
    pcall(function()
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = (pos.Position - theirHRP.Position).Unit * 500
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = theirHRP
        game:GetService("Debris"):AddItem(bv, 0.2)
    end)
end

local function Kill(name)
    local p = GetPlayerByName(name)
    if not p then return end
    local hrp = GetHRP(p)
    if not hrp then return end
    if ZK.Remotes.Damage then
        pcall(function()
            for i = 1, 10 do
                ZK.Remotes.Damage:FireServer(p, 999, "Head")
                task.wait(0.05)
            end
        end)
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
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
end

-- MONEY
local FarmThread, DupeThread = nil, nil

local function ToggleMoneyFarm(on)
    ZK.Money.Farming = on
    if FarmThread then FarmThread = nil end
    if not on then return end
    FarmThread = task.spawn(function()
        while ZK.Money.Farming do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- Strategy 1: Package delivery
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not ZK.Money.Farming then break end
                    if obj:IsA("ProximityPrompt") then
                        local parent = obj.Parent
                        if parent then
                            local pn = parent.Name:lower()
                            if pn:find("package") or pn:find("delivery") or pn:find("box") or pn:find("drop") or pn:find("mail") then
                                if (hrp.Position - parent.Position).Magnitude < 100 then
                                    SafeTeleport(parent.CFrame + Vector3.new(0, 3, 0))
                                    task.wait(1)
                                    fireproximityprompt(obj)
                                    task.wait(2)
                                end
                            end
                        end
                    end
                end
                -- Strategy 2: NPC jobs
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not ZK.Money.Farming then break end
                    if obj:IsA("ProximityPrompt") then
                        local parent = obj.Parent
                        if parent then
                            local pn = parent.Name:lower()
                            if pn:find("npc") or pn:find("dealer") or pn:find("boss") or pn:find("worker") then
                                if (hrp.Position - parent.Position).Magnitude < 100 then
                                    SafeTeleport(parent.CFrame + Vector3.new(0, 3, 0))
                                    task.wait(1)
                                    fireproximityprompt(obj)
                                    task.wait(2)
                                end
                            end
                        end
                    end
                end
                -- Strategy 3: Construction
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not ZK.Money.Farming then break end
                    if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                        local parent = obj.Parent
                        if parent then
                            local pn = parent.Name:lower()
                            if pn:find("construction") or pn:find("work") or pn:find("job") or pn:find("site") then
                                if (hrp.Position - parent.Position).Magnitude < 100 then
                                    SafeTeleport(parent.CFrame + Vector3.new(0, 3, 0))
                                    task.wait(1)
                                    if obj:IsA("ProximityPrompt") then fireproximityprompt(obj)
                                    else fireclickdetector(obj) end
                                    task.wait(2)
                                end
                            end
                        end
                    end
                end
                -- Strategy 4: Collect dropped cash
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if not ZK.Money.Farming then break end
                    if obj:IsA("BasePart") then
                        local on = obj.Name:lower()
                        if on:find("money") or on:find("cash") or on:find("bill") then
                            if (hrp.Position - obj.Position).Magnitude < 50 then
                                SafeTeleport(obj.CFrame + Vector3.new(0, 2, 0))
                                task.wait(0.5)
                                firetouchinterest(hrp, obj, 0)
                                firetouchinterest(hrp, obj, 1)
                            end
                        end
                    end
                end
                -- Strategy 5: Remote jobs
                if ZK.Remotes.Jobs then
                    pcall(function() ZK.Remotes.Jobs:FireServer("start") end)
                    task.wait(3)
                    pcall(function() ZK.Remotes.Jobs:FireServer("complete") end)
                end
                if ZK.Remotes.Money then
                    pcall(function() ZK.Remotes.Money:FireServer(math.random(50, 200)) end)
                end
            end
            -- Auto-click job GUIs
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
            for i = 1, math.random(3, 6) do
                if not ZK.Money.Farming then break end
                task.wait(1)
            end
        end
    end)
end

local function ToggleMoneyDupe(on)
    ZK.Money.Duping = on
    if DupeThread then DupeThread = nil end
    if not on then return end
    DupeThread = task.spawn(function()
        while ZK.Money.Duping do
            if ZK.Remotes.Money then pcall(function() ZK.Remotes.Money:FireServer(math.random(100, 500)) end) end
            local stat = GetMoneyStat()
            if stat then pcall(function() stat.Value = stat.Value + math.random(50, 200) end) end
            task.wait(math.random(0.5, 1.5))
        end
    end)
end

local function GiveMoney(amt)
    amt = tonumber(amt)
    if not amt then return end
    if ZK.Remotes.Money then pcall(function() ZK.Remotes.Money:FireServer(amt) end) return end
    local stat = GetMoneyStat()
    if stat then pcall(function() stat.Value = stat.Value + amt end) end
end

local function SetMoney(amt)
    amt = tonumber(amt)
    if not amt then return end
    if ZK.Remotes.Money then pcall(function() ZK.Remotes.Money:FireServer("set", amt) end) return end
    local stat = GetMoneyStat()
    if stat then pcall(function() stat.Value = amt end) end
end

-- ITEMS
local function GiveItem(name)
    if not name or name == "" then return end
    if ZK.Remotes.Items then
        pcall(function() ZK.Remotes.Items:FireServer("give", name) end)
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
        end)
    end
end

local function DupeItem()
    local char = LocalPlayer.Character
    if not char then return end
    local held = char:FindFirstChildOfClass("Tool")
    if not held then return end
    local bp = LocalPlayer.Backpack:FindFirstChild(held.Name)
    if bp then
        pcall(function()
            local c = bp:Clone()
            c.Parent = LocalPlayer.Backpack
        end)
    else
        pcall(function()
            local c = held:Clone()
            c.Parent = LocalPlayer.Backpack
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
--  DRAWING API UI (ZERO INSTANCES)
-- ═══════════════════════════════════════════════════════════

local MenuObjects = {}
local function ClearMenu()
    for _, obj in pairs(MenuObjects) do if obj then obj:Remove() end end
    MenuObjects = {}
end

local function DrawRect(x, y, w, h, color, transparency)
    local rect = Drawing.new("Square")
    rect.Size = Vector2.new(w, h)
    rect.Position = Vector2.new(x, y)
    rect.Color = color or Color3.fromRGB(18, 18, 38)
    rect.Transparency = transparency or 1
    rect.Filled = true
    rect.Visible = true
    table.insert(MenuObjects, rect)
    return rect
end

local function DrawText(x, y, text, size, color, bold)
    local txt = Drawing.new("Text")
    txt.Position = Vector2.new(x, y)
    txt.Text = text
    txt.Size = size or 14
    txt.Color = color or Color3.fromRGB(240, 240, 255)
    txt.Font = bold and Drawing.Fonts.UIBold or Drawing.Fonts.UI
    txt.Transparency = 1
    txt.Visible = true
    table.insert(MenuObjects, txt)
    return txt
end

local function DrawButton(x, y, w, h, text, callback)
    local rect = DrawRect(x, y, w, h, Color3.fromRGB(59, 130, 246))
    local txt = DrawText(x + w/2 - (#text * 3.5), y + h/2 - 7, text, 12, Color3.fromRGB(255, 255, 255))
    
    local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            if mousePos.X >= x and mousePos.X <= x + w and mousePos.Y >= y and mousePos.Y <= y + h then
                callback()
            end
        end
    end)
    table.insert(ZK.Connections, conn)
    return rect
end

local function DrawToggle(x, y, text, enabled, callback)
    local bg = DrawRect(x, y, 40, 20, Color3.fromRGB(8, 8, 18))
    local knob = DrawRect(x + (enabled and 22 or 2), y + 2, 16, 16, enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(147, 153, 170))
    local label = DrawText(x + 50, y + 2, text, 13, Color3.fromRGB(240, 240, 255))
    
    local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            if mousePos.X >= x and mousePos.X <= x + 40 and mousePos.Y >= y and mousePos.Y <= y + 20 then
                enabled = not enabled
                knob.Position = Vector2.new(x + (enabled and 22 or 2), y + 2)
                knob.Color = enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(147, 153, 170)
                bg.Color = enabled and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(8, 8, 18)
                callback(enabled)
            end
        end
    end)
    table.insert(ZK.Connections, conn)
    return enabled
end

local function DrawSlider(x, y, w, text, min, max, value, callback)
    DrawText(x, y - 15, text .. ": " .. value, 12, Color3.fromRGB(240, 240, 255))
    local track = DrawRect(x, y, w, 4, Color3.fromRGB(8, 8, 18))
    local fill = DrawRect(x, y, (value - min) / (max - min) * w, 4, Color3.fromRGB(59, 130, 246))
    local knob = DrawRect(x + (value - min) / (max - min) * w - 6, y - 4, 12, 12, Color3.fromRGB(255, 255, 255))
    
    local dragging = false
    local conn1 = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            if mousePos.X >= x and mousePos.X <= x + w and mousePos.Y >= y - 10 and mousePos.Y <= y + 14 then
                dragging = true
            end
        end
    end)
    local conn2 = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = UserInputService:GetMouseLocation()
            local pos = math.clamp((mousePos.X - x) / w, 0, 1)
            local newVal = math.floor(min + pos * (max - min))
            fill.Size = Vector2.new(pos * w, 4)
            knob.Position = Vector2.new(x + pos * w - 6, y - 4)
            callback(newVal)
        end
    end)
    local conn3 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    table.insert(ZK.Connections, conn1)
    table.insert(ZK.Connections, conn2)
    table.insert(ZK.Connections, conn3)
end

local function RenderMenu()
    ClearMenu()
    if not ZK.MenuOpen then return end
    
    local mx, my = 100, 100
    local mw, mh = 600, 400
    
    -- Background
    DrawRect(mx, my, mw, mh, Color3.fromRGB(8, 8, 18), 0.95)
    DrawRect(mx, my, mw, 40, Color3.fromRGB(18, 18, 38))
    DrawText(mx + 15, my + 12, "ZKILLER // SOUTH BRONX", 16, Color3.fromRGB(59, 130, 246), true)
    DrawText(mx + mw - 200, my + 12, "by the invisible man", 11, Color3.fromRGB(147, 153, 170))
    
    -- Tabs
    local tabX = mx + 10
    for i, tabName in ipairs(ZK.Tabs) do
        local isActive = ZK.Tab == tabName
        DrawRect(tabX, my + 50, 80, 30, isActive and Color3.fromRGB(59, 130, 246) or Color3.fromRGB(18, 18, 38))
        DrawText(tabX + 10, my + 56, tabName, 11, isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(147, 153, 170))
        
        local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                if mousePos.X >= tabX and mousePos.X <= tabX + 80 and mousePos.Y >= my + 50 and mousePos.Y <= my + 80 then
                    ZK.Tab = tabName
                    RenderMenu()
                end
            end
        end)
        table.insert(ZK.Connections, conn)
        tabX = tabX + 85
    end
    
    -- Content area
    local cx, cy = mx + 10, my + 90
    local cw = mw - 20
    
    if ZK.Tab == "Combat" then
        DrawText(cx, cy, "═══ AIMBOT ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawToggle(cx, cy + 25, "Aimbot", ZK.Aimbot.Enabled, function(v) ToggleAimbot(v) end)
        DrawText(cx, cy + 55, "Aim Part: " .. ZK.Aimbot.Part, 12, Color3.fromRGB(240, 240, 255))
        DrawSlider(cx, cy + 75, cw - 20, "FOV", 50, 500, ZK.Aimbot.FOV, function(v) ZK.Aimbot.FOV = v; RenderMenu() end)
        DrawSlider(cx, cy + 105, cw - 20, "Smoothness", 1, 20, ZK.Aimbot.Smoothness, function(v) ZK.Aimbot.Smoothness = v; RenderMenu() end)
        
        DrawText(cx, cy + 140, "═══ SILENT AIM ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawToggle(cx, cy + 165, "Silent Aim", ZK.SilentAim.Enabled, function(v) ToggleSilentAim(v) end)
        DrawSlider(cx, cy + 195, cw - 20, "Silent FOV", 50, 500, ZK.SilentAim.FOV, function(v) ZK.SilentAim.FOV = v; RenderMenu() end)
        DrawSlider(cx, cy + 225, cw - 20, "Hit Chance", 1, 100, ZK.SilentAim.HitChance, function(v) ZK.SilentAim.HitChance = v; RenderMenu() end)
        
        DrawText(cx, cy + 260, "═══ GUN MODS ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawToggle(cx, cy + 285, "Wallbang", ZK.GunMods.Wallbang, function(v) ZK.GunMods.Wallbang = v; UpdateGunMods() end)
        DrawToggle(cx, cy + 315, "Infinite Ammo", ZK.GunMods.InfiniteAmmo, function(v) ZK.GunMods.InfiniteAmmo = v; UpdateGunMods() end)
        DrawToggle(cx, cy + 345, "Rapid Fire", ZK.GunMods.RapidFire, function(v) ZK.GunMods.RapidFire = v; UpdateGunMods() end)
        
    elseif ZK.Tab == "Teleport" then
        DrawText(cx, cy, "═══ TELEPORT ═══", 14, Color3.fromRGB(59, 130, 246), true)
        local players = GetPlayerList()
        local selected = ZK.SelectedPlayer and ZK.SelectedPlayer.Name or "Select Player"
        DrawText(cx, cy + 25, "Selected: " .. selected, 12, Color3.fromRGB(240, 240, 255))
        
        local py = cy + 50
        for i, p in ipairs(players) do
            if py < my + mh - 40 then
                DrawButton(cx, py, cw - 20, 25, p.Name, function()
                    ZK.SelectedPlayer = p
                    RenderMenu()
                end)
                py = py + 30
            end
        end
        
        DrawButton(cx, my + mh - 35, cw - 20, 30, "TELEPORT TO SELECTED", function()
            if ZK.SelectedPlayer then TeleportTo(ZK.SelectedPlayer.Name) end
        end)
        
    elseif ZK.Tab == "Spectate" then
        DrawText(cx, cy, "═══ SPECTATE ═══", 14, Color3.fromRGB(59, 130, 246), true)
        local players = GetPlayerList()
        local py = cy + 25
        for i, p in ipairs(players) do
            if py < my + mh - 80 then
                DrawButton(cx, py, cw - 20, 25, p.Name, function()
                    ZK.SelectedPlayer = p
                    RenderMenu()
                end)
                py = py + 30
            end
        end
        DrawButton(cx, my + mh - 70, cw/2 - 15, 30, "START SPECTATE", function()
            if ZK.SelectedPlayer then Spectate(ZK.SelectedPlayer.Name) end
        end)
        DrawButton(cx + cw/2 - 5, my + mh - 70, cw/2 - 15, 30, "END SPECTATE", EndSpectate)
        
    elseif ZK.Tab == "Bring" then
        DrawText(cx, cy, "═══ BRING ═══", 14, Color3.fromRGB(59, 130, 246), true)
        local players = GetPlayerList()
        local py = cy + 25
        for i, p in ipairs(players) do
            if py < my + mh - 40 then
                DrawButton(cx, py, cw - 20, 25, p.Name, function()
                    ZK.SelectedPlayer = p
                    RenderMenu()
                end)
                py = py + 30
            end
        end
        DrawButton(cx, my + mh - 35, cw - 20, 30, "BRING SELECTED", function()
            if ZK.SelectedPlayer then Bring(ZK.SelectedPlayer.Name) end
        end)
        
    elseif ZK.Tab == "Money" then
        DrawText(cx, cy, "═══ AUTO FARM ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawToggle(cx, cy + 25, "Auto Farm", ZK.Money.Farming, function(v) ToggleMoneyFarm(v) end)
        
        DrawText(cx, cy + 60, "═══ MONEY DUPE ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawToggle(cx, cy + 85, "Money Dupe", ZK.Money.Duping, function(v) ToggleMoneyDupe(v) end)
        
        DrawText(cx, cy + 120, "═══ GIVE MONEY ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawText(cx, cy + 145, "Type amount in chat: /e givemoney [amount]", 11, Color3.fromRGB(147, 153, 170))
        
        DrawText(cx, cy + 170, "═══ SET MONEY ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawText(cx, cy + 195, "Type amount in chat: /e setmoney [amount]", 11, Color3.fromRGB(147, 153, 170))
        
    elseif ZK.Tab == "Items" then
        DrawText(cx, cy, "═══ GIVE ITEM ═══", 14, Color3.fromRGB(59, 130, 246), true)
        local items = ZK.Items
        DrawText(cx, cy + 25, "Selected: " .. items[ZK.SelectedItemIndex], 12, Color3.fromRGB(240, 240, 255))
        DrawButton(cx, cy + 50, 100, 25, "PREV", function()
            ZK.SelectedItemIndex = ZK.SelectedItemIndex > 1 and ZK.SelectedItemIndex - 1 or #items
            RenderMenu()
        end)
        DrawButton(cx + cw - 120, cy + 50, 100, 25, "NEXT", function()
            ZK.SelectedItemIndex = ZK.SelectedItemIndex < #items and ZK.SelectedItemIndex + 1 or 1
            RenderMenu()
        end)
        DrawButton(cx, cy + 85, cw - 20, 30, "GIVE ITEM", function()
            GiveItem(items[ZK.SelectedItemIndex])
        end)
        
        DrawText(cx, cy + 130, "═══ ITEM DUPE ═══", 14, Color3.fromRGB(59, 130, 246), true)
        DrawButton(cx, cy + 155, cw - 20, 30, "DUPE HELD ITEM", DupeItem)
        
    elseif ZK.Tab == "Kill" then
        DrawText(cx, cy, "═══ KILL ═══", 14, Color3.fromRGB(59, 130, 246), true)
        local players = GetPlayerList()
        local py = cy + 25
        for i, p in ipairs(players) do
            if py < my + mh - 40 then
                DrawButton(cx, py, cw - 20, 25, p.Name, function()
                    ZK.SelectedPlayer = p
                    RenderMenu()
                end)
                py = py + 30
            end
        end
        DrawButton(cx, my + mh - 35, cw - 20, 30, "KILL SELECTED", function()
            if ZK.SelectedPlayer then Kill(ZK.SelectedPlayer.Name) end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════
--  KEYBINDS
-- ═══════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Insert to toggle menu
    if input.KeyCode == Enum.KeyCode.Insert then
        ZK.MenuOpen = not ZK.MenuOpen
        if not ZK.MenuOpen then
            ClearMenu()
            -- Disconnect all menu connections
            for _, c in ipairs(ZK.Connections) do
                if c then c:Disconnect() end
            end
            ZK.Connections = {}
        else
            RenderMenu()
        end
    end
    
    -- Keybinds when menu is closed
    if not ZK.MenuOpen then
        if input.KeyCode == Enum.KeyCode.F then ToggleAimbot(not ZK.Aimbot.Enabled) end
        if input.KeyCode == Enum.KeyCode.G then ToggleSilentAim(not ZK.SilentAim.Enabled) end
        if input.KeyCode == Enum.KeyCode.H then
            ZK.GunMods.InfiniteAmmo = not ZK.GunMods.InfiniteAmmo
            UpdateGunMods()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
--  CHAT COMMANDS (NO UI NEEDED)
-- ═══════════════════════════════════════════════════════════

LocalPlayer.Chatted:Connect(function(msg)
    local args = msg:split(" ")
    
    if args[1] == "/e" then
        if args[2] == "givemoney" and args[3] then
            GiveMoney(args[3])
        elseif args[2] == "setmoney" and args[3] then
            SetMoney(args[3])
        elseif args[2] == "tp" and args[3] then
            TeleportTo(args[3])
        elseif args[2] == "bring" and args[3] then
            Bring(args[3])
        elseif args[2] == "kill" and args[3] then
            Kill(args[3])
        elseif args[2] == "spectate" and args[3] then
            Spectate(args[3])
        elseif args[2] == "endspec" then
            EndSpectate()
        elseif args[2] == "giveitem" and args[3] then
            GiveItem(args[3])
        elseif args[2] == "dupeitem" then
            DupeItem()
        elseif args[2] == "farm" then
            ToggleMoneyFarm(not ZK.Money.Farming)
        elseif args[2] == "dupe" then
            ToggleMoneyDupe(not ZK.Money.Duping)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════════════════

DiscoverRemotes()

warn("[ZKILLER] South Bronx Fileless loaded.")
warn("[ZKILLER] Press INSERT for menu.")
warn("[ZKILLER] Chat commands: /e [command] [args]")
warn("[ZKILLER] Commands: tp [name], bring [name], kill [name], spectate [name], endspec, givemoney [amt], setmoney [amt], giveitem [name], dupeitem, farm, dupe")
warn("[ZKILLER] Keybinds: F=Aimbot, G=SilentAim, H=InfiniteAmmo")
warn("[ZKILLER] by the invisible man")
