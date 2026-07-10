-- ═══════════════════════════════════════════════════════════
--  ZKILLER // SOUTH BRONX: THE TRENCHES
--  by the invisible man
--  Key: Zkiller
--  PlaceId: 10179538382
-- ═══════════════════════════════════════════════════════════

-- Load Rayfield UI
local RayfieldLoadSuccess, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not RayfieldLoadSuccess then
    warn("[ZKILLER] Failed to load Rayfield UI. Trying backup...")
    RayfieldLoadSuccess, Rayfield = pcall(function()
        return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
    end)
    if not RayfieldLoadSuccess then
        error("[ZKILLER] Could not load Rayfield UI. Check your executor.")
        return
    end
end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- State
local ZK = {
    SelectedPlayer = nil,
    Spectating = false,
    OriginalCameraSubject = nil,
    Aimbot = {Enabled = false, Part = "Head", FOV = 150, Smoothness = 3},
    SilentAim = {Enabled = false, FOV = 200, HitChance = 100},
    GunMods = {Wallbang = false, InfiniteAmmo = false, RapidFire = false},
    Money = {Farming = false, Duping = false},
    AntiCheat = {Enabled = true},
    Remotes = {Scanned = false, Money = nil, Damage = nil, Items = nil, Jobs = nil},
    Items = {
        "Glock17", "Glock18", "DesertEagle", "BerettaM9", "AK47", "AR15",
        "MP5", "Uzi", "Mac10", "PumpShotgun", "SawedOff", "Knife",
        "BaseballBat", "Crowbar", "BrassKnuckles", "Phone", "Wallet",
        "Key", "Bandage", "Burger", "Pizza", "Soda", "Water"
    }
}

-- ═══════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function Notify(title, message, duration)
    Rayfield:Notify({
        Title = title,
        Content = message,
        Duration = duration or 4,
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
        if plr.Name == name then
            return plr
        end
    end
    return nil
end

local function TweenToPosition(cframe, speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local distance = (hrp.Position - cframe.Position).Magnitude
    local tweenTime = math.min(distance / (speed or 200), 3)
    
    local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        CFrame = cframe
    })
    tween:Play()
    return tween
end

local function SafeTeleport(cframe)
    -- Anti-cheat safe teleport with tween
    TweenToPosition(cframe, 300)
end

-- ═══════════════════════════════════════════════════════════
--  REMOTE SCANNER
-- ═══════════════════════════════════════════════════════════

local function ScanRemotes()
    if ZK.Remotes.Scanned then return end
    
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            
            if name:find("money") or name:find("cash") or name:find("bank") or name:find("pay") or name:find("salary") or name:find("job") then
                ZK.Remotes.Money = obj
            end
            
            if name:find("damage") or name:find("hit") or name:find("shoot") or name:find("fire") or name:find("attack") then
                ZK.Remotes.Damage = obj
            end
            
            if name:find("item") or name:find("give") or name:find("tool") or name:find("weapon") or name:find("inventory") then
                ZK.Remotes.Items = obj
            end
            
            if name:find("job") or name:find("work") or name:find("task") or name:find("construction") then
                ZK.Remotes.Jobs = obj
            end
        end
    end
    
    ZK.Remotes.Scanned = true
    Notify("Remote Scanner", "Scan complete. Found " .. (ZK.Remotes.Money and "Money " or "") .. (ZK.Remotes.Damage and "Damage " or "") .. (ZK.Remotes.Items and "Items " or "") .. (ZK.Remotes.Jobs and "Jobs" or "") .. " remotes.", 5)
end

-- ═══════════════════════════════════════════════════════════
--  ANTI-CHEAT BYPASS
-- ═══════════════════════════════════════════════════════════

local function InitACBypass()
    if not ZK.AntiCheat.Enabled then return end
    
    -- Hook kick
    local oldKick
    pcall(function()
        oldKick = hookfunction(LocalPlayer.Kick, function(self, ...)
            if self == LocalPlayer then
                Notify("AC Bypass", "Blocked kick attempt", 3)
                return
            end
            return oldKick(self, ...)
        end)
    end)
    
    -- Neutralize anti-cheat scripts
    task.spawn(function()
        while ZK.AntiCheat.Enabled do
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local name = obj.Name:lower()
                    if name:find("anticheat") or name:find("anti-cheat") or name:find("ac_") or name:find("detect") or name:find("ban") or name:find("exploit") or name:find("cheat") then
                        pcall(function()
                            obj.Disabled = true
                        end)
                    end
                end
            end
            task.wait(3)
        end
    end)
    
    -- Spoof memory
    pcall(function()
        local stats = game:GetService("Stats")
        hookfunction(stats.GetTotalMemoryUsageMb, function()
            return math.random(800, 1200)
        end)
    end)
    
    Notify("AC Bypass", "Anti-cheat bypass initialized", 3)
end

-- ═══════════════════════════════════════════════════════════
--  AIMBOT & SILENT AIM
-- ═══════════════════════════════════════════════════════════

local function GetClosestPlayerToMouse(fov, targetPart)
    local closest = nil
    local closestDist = fov or math.huge
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

local AimbotConnection = nil
local SilentAimConnection = nil
local FOVCircle = nil
local SilentFOVCircle = nil

local function ToggleAimbot(enabled)
    ZK.Aimbot.Enabled = enabled
    
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end
    
    if not enabled then
        if AimbotConnection then
            AimbotConnection:Disconnect()
            AimbotConnection = nil
        end
        return
    end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = true
    FOVCircle.Thickness = 1.5
    FOVCircle.Color = Color3.fromRGB(59, 130, 246)
    FOVCircle.Transparency = 0.7
    FOVCircle.Filled = false
    FOVCircle.NumSides = 64
    FOVCircle.Radius = ZK.Aimbot.FOV
    
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not FOVCircle then return end
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        FOVCircle.Radius = ZK.Aimbot.FOV
        
        local target = GetClosestPlayerToMouse(ZK.Aimbot.FOV, ZK.Aimbot.Part)
        if target then
            local targetPos = Camera:WorldToViewportPoint(target.Position)
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local targetVec = Vector2.new(targetPos.X, targetPos.Y)
            local diff = (targetVec - mousePos) / ZK.Aimbot.Smoothness
            mousemoverel(diff.X, diff.Y)
            FOVCircle.Color = Color3.fromRGB(34, 197, 94)
        else
            FOVCircle.Color = Color3.fromRGB(59, 130, 246)
        end
    end)
end

local function ToggleSilentAim(enabled)
    ZK.SilentAim.Enabled = enabled
    
    if SilentFOVCircle then
        SilentFOVCircle:Remove()
        SilentFOVCircle = nil
    end
    
    if not enabled then
        if SilentAimConnection then
            SilentAimConnection:Disconnect()
            SilentAimConnection = nil
        end
        return
    end
    
    SilentFOVCircle = Drawing.new("Circle")
    SilentFOVCircle.Visible = true
    SilentFOVCircle.Thickness = 1.5
    SilentFOVCircle.Color = Color3.fromRGB(234, 179, 8)
    SilentFOVCircle.Transparency = 0.5
    SilentFOVCircle.Filled = false
    SilentFOVCircle.NumSides = 64
    SilentFOVCircle.Radius = ZK.SilentAim.FOV
    
    -- Hook raycast for wallbang/silent aim
    local oldRaycast
    pcall(function()
        oldRaycast = hookfunction(Workspace.Raycast, function(self, origin, direction, params, ...)
            if ZK.SilentAim.Enabled and math.random(1, 100) <= ZK.SilentAim.HitChance then
                local target = GetClosestPlayerToMouse(ZK.SilentAim.FOV, "Head")
                if target then
                    local newDirection = (target.Position - origin).Unit * direction.Magnitude
                    if ZK.GunMods.Wallbang and params then
                        params.FilterType = Enum.RaycastFilterType.Blacklist
                        local filter = params.FilterDescendantsInstances or {}
                        table.insert(filter, Workspace:FindFirstChild("Map") or Workspace)
                        params.FilterDescendantsInstances = filter
                    end
                    return oldRaycast(self, origin, newDirection, params, ...)
                end
            end
            return oldRaycast(self, origin, direction, params, ...)
        end)
    end)
    
    SilentAimConnection = RunService.RenderStepped:Connect(function()
        if not SilentFOVCircle then return end
        SilentFOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        SilentFOVCircle.Radius = ZK.SilentAim.FOV
        
        local target = GetClosestPlayerToMouse(ZK.SilentAim.FOV, "Head")
        if target then
            SilentFOVCircle.Color = Color3.fromRGB(34, 197, 94)
        else
            SilentFOVCircle.Color = Color3.fromRGB(234, 179, 8)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  GUN MODS
-- ═══════════════════════════════════════════════════════════

local GunModConnection = nil

local function ToggleGunMods()
    if GunModConnection then
        GunModConnection:Disconnect()
        GunModConnection = nil
    end
    
    if not (ZK.GunMods.InfiniteAmmo or ZK.GunMods.RapidFire) then return end
    
    GunModConnection = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                -- Infinite Ammo
                if ZK.GunMods.InfiniteAmmo then
                    local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip") or tool:FindFirstChild("Bullets") or tool:FindFirstChild("CurrentAmmo")
                    if ammo and ammo:IsA("IntValue") then
                        ammo.Value = 999
                    end
                    if ammo and ammo:IsA("NumberValue") then
                        ammo.Value = 999
                    end
                end
                
                -- Rapid Fire
                if ZK.GunMods.RapidFire then
                    local fireRate = tool:FindFirstChild("FireRate") or tool:FindFirstChild("Cooldown") or tool:FindFirstChild("ShootCooldown") or tool:FindFirstChild("RPM")
                    if fireRate and (fireRate:IsA("NumberValue") or fireRate:IsA("IntValue")) then
                        fireRate.Value = 0.01
                    end
                end
                
                -- No Reload
                local reloading = tool:FindFirstChild("Reloading") or tool:FindFirstChild("IsReloading")
                if reloading and reloading:IsA("BoolValue") then
                    reloading.Value = false
                end
            end
        end
        
        -- Also check backpack
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and ZK.GunMods.InfiniteAmmo then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip") or tool:FindFirstChild("Bullets") or tool:FindFirstChild("CurrentAmmo")
                if ammo and ammo:IsA("IntValue") then
                    ammo.Value = 999
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TELEPORT & SPECTATE & BRING
-- ═══════════════════════════════════════════════════════════

local SpectateConnection = nil

local function StartSpectate(playerName)
    local target = GetPlayerByName(playerName)
    if not target then
        Notify("Spectate", "Player not found", 3)
        return
    end
    
    local hum = GetHumanoid(target)
    if not hum then
        Notify("Spectate", "Player has no humanoid", 3)
        return
    end
    
    ZK.OriginalCameraSubject = Camera.CameraSubject
    Camera.CameraSubject = hum
    ZK.Spectating = true
    ZK.SelectedPlayer = target
    
    Notify("Spectate", "Now spectating " .. target.Name, 3)
end

local function EndSpectate()
    if not ZK.Spectating then return end
    
    local myHum = GetHumanoid(LocalPlayer)
    if myHum then
        Camera.CameraSubject = myHum
    end
    
    ZK.Spectating = false
    ZK.OriginalCameraSubject = nil
    Notify("Spectate", "Spectate ended", 3)
end

local function TeleportToPlayer(playerName)
    local target = GetPlayerByName(playerName)
    if not target then
        Notify("Teleport", "Player not found", 3)
        return
    end
    
    local targetHRP = GetHRP(target)
    if not targetHRP then
        Notify("Teleport", "Player has no character", 3)
        return
    end
    
    SafeTeleport(targetHRP.CFrame + Vector3.new(0, 3, 0))
    Notify("Teleport", "Teleported to " .. target.Name, 3)
end

local function BringPlayer(playerName)
    local target = GetPlayerByName(playerName)
    if not target then
        Notify("Bring", "Player not found", 3)
        return
    end
    
    local myHRP = GetHRP(LocalPlayer)
    local targetHRP = GetHRP(target)
    if not myHRP or not targetHRP then
        Notify("Bring", "Character not found", 3)
        return
    end
    
    -- Try to bring using velocity fling (safer than setting CFrame directly on others)
    local bringPos = myHRP.CFrame + Vector3.new(0, 3, 5)
    
    -- Try to set CFrame if we have network ownership
    pcall(function()
        targetHRP.CFrame = bringPos
    end)
    
    -- Fallback: velocity push
    pcall(function()
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = (bringPos.Position - targetHRP.Position).Unit * 500
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Parent = targetHRP
        game:GetService("Debris"):AddItem(bodyVelocity, 0.2)
    end)
    
    Notify("Bring", "Attempted to bring " .. target.Name, 3)
end

-- ═══════════════════════════════════════════════════════════
--  MONEY SYSTEM
-- ═══════════════════════════════════════════════════════════

local MoneyFarmConnection = nil
local MoneyDupeConnection = nil

local function GetMoneyStat()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if not leaderstats then return nil end
    for _, stat in ipairs(leaderstats:GetChildren()) do
        if stat:IsA("IntValue") or stat:IsA("NumberValue") then
            if stat.Name:lower():find("money") or stat.Name:lower():find("cash") then
                return stat
            end
        end
    end
    return nil
end

local function ToggleMoneyFarm(enabled)
    ZK.Money.Farming = enabled
    
    if MoneyFarmConnection then
        MoneyFarmConnection:Disconnect()
        MoneyFarmConnection = nil
    end
    
    if not enabled then
        Notify("Money Farm", "Auto-farm stopped", 3)
        return
    end
    
    Notify("Money Farm", "Starting construction job auto-farm...", 4)
    
    MoneyFarmConnection = task.spawn(function()
        while ZK.Money.Farming do
            local char = LocalPlayer.Character
            if not char then task.wait(2) continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(2) continue end
            
            -- Scan for construction job interactables
            local foundJob = false
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if ZK.Money.Farming == false then break end
                
                -- Look for job NPCs or interactables
                if obj:IsA("ProximityPrompt") then
                    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                    if parentName:find("construction") or parentName:find("job") or parentName:find("work") or parentName:find("boss") then
                        local dist = (hrp.Position - obj.Parent.Position).Magnitude
                        if dist < 50 then
                            foundJob = true
                            SafeTeleport(obj.Parent.CFrame + Vector3.new(0, 3, 0))
                            task.wait(1.5)
                            fireproximityprompt(obj)
                            task.wait(2)
                        end
                    end
                end
                
                if obj:IsA("ClickDetector") then
                    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                    if parentName:find("construction") or parentName:find("job") or parentName:find("work") then
                        local dist = (hrp.Position - obj.Parent.Position).Magnitude
                        if dist < 50 then
                            foundJob = true
                            SafeTeleport(obj.Parent.CFrame + Vector3.new(0, 3, 0))
                            task.wait(1.5)
                            fireclickdetector(obj)
                            task.wait(2)
                        end
                    end
                end
            end
            
            -- Auto-click any job-related GUI buttons
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                    local name = gui.Name:lower()
                    if name:find("work") or name:find("job") or name:find("start") or name:find("construction") then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(gui.AbsolutePosition.X + gui.AbsoluteSize.X/2, gui.AbsolutePosition.Y + gui.AbsoluteSize.Y/2))
                        end)
                        task.wait(1)
                    end
                end
            end
            
            -- If job remote found, fire it
            if ZK.Remotes.Jobs then
                pcall(function()
                    ZK.Remotes.Jobs:FireServer("start", "construction")
                end)
                task.wait(3)
                pcall(function()
                    ZK.Remotes.Jobs:FireServer("complete")
                end)
            end
            
            -- Wait before next cycle (anti-detection)
            local waitTime = foundJob and math.random(5, 8) or math.random(3, 5)
            for i = 1, waitTime do
                if not ZK.Money.Farming then break end
                task.wait(1)
            end
        end
    end)
end

local function ToggleMoneyDupe(enabled)
    ZK.Money.Duping = enabled
    
    if MoneyDupeConnection then
        -- Stop dupe
        ZK.Money.Duping = false
        MoneyDupeConnection = nil
        Notify("Money Dupe", "Dupe stopped", 3)
        return
    end
    
    if not enabled then return end
    
    Notify("Money Dupe", "Starting money dupe...", 3)
    
    MoneyDupeConnection = task.spawn(function()
        while ZK.Money.Duping do
            -- Method 1: Rapid remote firing
            if ZK.Remotes.Money then
                pcall(function()
                    ZK.Remotes.Money:FireServer("add", math.random(100, 500))
                end)
            end
            
            -- Method 2: Leaderstat manipulation (visual only, may sync)
            local moneyStat = GetMoneyStat()
            if moneyStat then
                pcall(function()
                    moneyStat.Value = moneyStat.Value + math.random(50, 200)
                end)
            end
            
            -- Method 3: Job reward exploit
            if ZK.Remotes.Jobs then
                pcall(function()
                    ZK.Remotes.Jobs:FireServer("reward", math.random(100, 1000))
                end)
            end
            
            task.wait(math.random(0.5, 1.5))
        end
    end)
end

local function GiveMoney(amount)
    amount = tonumber(amount)
    if not amount then
        Notify("Give Money", "Invalid amount", 3)
        return
    end
    
    local moneyStat = GetMoneyStat()
    
    -- Try remote first
    if ZK.Remotes.Money then
        pcall(function()
            ZK.Remotes.Money:FireServer("add", amount)
            Notify("Give Money", "Gave $" .. amount .. " via remote", 3)
            return
        end)
    end
    
    -- Fallback: leaderstat
    if moneyStat then
        pcall(function()
            moneyStat.Value = moneyStat.Value + amount
            Notify("Give Money", "Added $" .. amount .. " to your balance", 3)
        end)
    else
        Notify("Give Money", "Could not find money system", 3)
    end
end

local function SetMoney(amount)
    amount = tonumber(amount)
    if not amount then
        Notify("Set Money", "Invalid amount", 3)
        return
    end
    
    local moneyStat = GetMoneyStat()
    
    if ZK.Remotes.Money then
        pcall(function()
            ZK.Remotes.Money:FireServer("set", amount)
            Notify("Set Money", "Set money to $" .. amount, 3)
            return
        end)
    end
    
    if moneyStat then
        pcall(function()
            moneyStat.Value = amount
            Notify("Set Money", "Set money to $" .. amount, 3)
        end)
    else
        Notify("Set Money", "Could not find money system", 3)
    end
end

-- ═══════════════════════════════════════════════════════════
--  ITEMS SYSTEM
-- ═══════════════════════════════════════════════════════════

local function GiveItem(itemName)
    if not itemName or itemName == "" then
        Notify("Give Item", "No item selected", 3)
        return
    end
    
    -- Try remote first
    if ZK.Remotes.Items then
        pcall(function()
            ZK.Remotes.Items:FireServer("give", itemName)
            Notify("Give Item", "Gave " .. itemName, 3)
            return
        end)
    end
    
    -- Try to find item in ReplicatedStorage or Workspace
    local itemTemplate = nil
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == itemName or obj.Name:lower() == itemName:lower() then
            itemTemplate = obj
            break
        end
    end
    
    if itemTemplate then
        pcall(function()
            local clone = itemTemplate:Clone()
            clone.Parent = LocalPlayer.Backpack
            Notify("Give Item", "Cloned " .. itemName .. " to backpack", 3)
        end)
    else
        Notify("Give Item", "Could not find " .. itemName .. ". Try custom name.", 3)
    end
end

local function DupeItem()
    local char = LocalPlayer.Character
    if not char then
        Notify("Item Dupe", "No character", 3)
        return
    end
    
    local heldTool = char:FindFirstChildOfClass("Tool")
    if not heldTool then
        Notify("Item Dupe", "Hold an item to dupe", 3)
        return
    end
    
    -- Method 1: Clone from backpack
    local backpackTool = LocalPlayer.Backpack:FindFirstChild(heldTool.Name)
    if backpackTool then
        pcall(function()
            local clone = backpackTool:Clone()
            clone.Parent = LocalPlayer.Backpack
            Notify("Item Dupe", "Duped " .. heldTool.Name, 3)
        end)
        return
    end
    
    -- Method 2: Clone from character
    pcall(function()
        local clone = heldTool:Clone()
        clone.Parent = LocalPlayer.Backpack
        Notify("Item Dupe", "Duped " .. heldTool.Name, 3)
    end)
end

-- ═══════════════════════════════════════════════════════════
--  KILL SYSTEM
-- ═══════════════════════════════════════════════════════════

local function KillPlayer(playerName)
    local target = GetPlayerByName(playerName)
    if not target then
        Notify("Kill", "Player not found", 3)
        return
    end
    
    local targetHRP = GetHRP(target)
    if not targetHRP then
        Notify("Kill", "Target has no character", 3)
        return
    end
    
    -- Method 1: Damage remote
    if ZK.Remotes.Damage then
        pcall(function()
            for i = 1, 10 do
                ZK.Remotes.Damage:FireServer(target, 999, "Head")
                task.wait(0.05)
            end
            Notify("Kill", "Killed " .. target.Name .. " via remote", 3)
            return
        end)
    end
    
    -- Method 2: Teleport and gun exploit
    local myChar = LocalPlayer.Character
    if not myChar then
        Notify("Kill", "No character", 3)
        return
    end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then
        Notify("Kill", "No HRP", 3)
        return
    end
    
    -- Save position
    local oldCFrame = myHRP.CFrame
    
    -- Teleport behind target
    SafeTeleport(targetHRP.CFrame + targetHRP.CFrame.LookVector * -3 + Vector3.new(0, 1, 0))
    task.wait(0.5)
    
    -- Equip gun and fire rapidly
    local gun = nil
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:find("Glock") or tool.Name:find("AK") or tool.Name:find("Deagle") or tool.Name:find("Gun")) then
            gun = tool
            break
        end
    end
    
    if not gun then
        gun = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
    end
    
    if gun then
        pcall(function()
            LocalPlayer.Character.Humanoid:EquipTool(gun)
            task.wait(0.3)
            for i = 1, 20 do
                gun:Activate()
                task.wait(0.05)
            end
        end)
    end
    
    -- Teleport back
    task.wait(0.3)
    SafeTeleport(oldCFrame)
    
    Notify("Kill", "Attempted to kill " .. target.Name, 3)
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

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 4483362458)
CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        ToggleAimbot(Value)
    end
})

CombatTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm"},
    CurrentOption = "Head",
    Flag = "AimPartDropdown",
    Callback = function(Option)
        ZK.Aimbot.Part = Option
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "AimbotFOV",
    Callback = function(Value)
        ZK.Aimbot.FOV = Value
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 3,
    Flag = "AimbotSmooth",
    Callback = function(Value)
        ZK.Aimbot.Smoothness = Value
    end
})

CombatTab:CreateSection("Silent Aim")

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(Value)
        ToggleSilentAim(Value)
    end
})

CombatTab:CreateSlider({
    Name = "Silent Aim FOV",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 200,
    Flag = "SilentAimFOV",
    Callback = function(Value)
        ZK.SilentAim.FOV = Value
    end
})

CombatTab:CreateSlider({
    Name = "Hit Chance %",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 100,
    Flag = "HitChance",
    Callback = function(Value)
        ZK.SilentAim.HitChance = Value
    end
})

CombatTab:CreateSection("Gun Mods")

CombatTab:CreateToggle({
    Name = "Shoot Through Walls",
    CurrentValue = false,
    Flag = "WallbangToggle",
    Callback = function(Value)
        ZK.GunMods.Wallbang = Value
        ToggleGunMods()
    end
})

CombatTab:CreateToggle({
    Name = "Infinite Ammo",
    CurrentValue = false,
    Flag = "InfAmmoToggle",
    Callback = function(Value)
        ZK.GunMods.InfiniteAmmo = Value
        ToggleGunMods()
    end
})

CombatTab:CreateToggle({
    Name = "Rapid Fire",
    CurrentValue = false,
    Flag = "RapidFireToggle",
    Callback = function(Value)
        ZK.GunMods.RapidFire = Value
        ToggleGunMods()
    end
})

-- Teleport Tab
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
TeleportTab:CreateSection("Teleport to Player")

local TeleportDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "TeleportDropdown",
    Callback = function(Option)
        ZK.SelectedPlayer = Option
    end
})

TeleportTab:CreateButton({
    Name = "Teleport",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            TeleportToPlayer(ZK.SelectedPlayer)
        else
            Notify("Teleport", "No player selected", 3)
        end
    end
})

-- Spectate Tab
local SpectateTab = Window:CreateTab("Spectate", 4483362458)
SpectateTab:CreateSection("Spectate Player")

local SpectateDropdown = SpectateTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "SpectateDropdown",
    Callback = function(Option)
        ZK.SelectedPlayer = Option
    end
})

SpectateTab:CreateButton({
    Name = "Start Spectate",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            StartSpectate(ZK.SelectedPlayer)
        else
            Notify("Spectate", "No player selected", 3)
        end
    end
})

SpectateTab:CreateButton({
    Name = "End Spectate",
    Callback = function()
        EndSpectate()
    end
})

-- Bring Tab
local BringTab = Window:CreateTab("Bring", 4483362458)
BringTab:CreateSection("Bring Player")

local BringDropdown = BringTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "BringDropdown",
    Callback = function(Option)
        ZK.SelectedPlayer = Option
    end
})

BringTab:CreateButton({
    Name = "Bring",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            BringPlayer(ZK.SelectedPlayer)
        else
            Notify("Bring", "No player selected", 3)
        end
    end
})

-- Money Tab
local MoneyTab = Window:CreateTab("Money", 4483362458)
MoneyTab:CreateSection("Money Farm")

MoneyTab:CreateToggle({
    Name = "Auto Farm (Construction Job)",
    CurrentValue = false,
    Flag = "MoneyFarmToggle",
    Callback = function(Value)
        ToggleMoneyFarm(Value)
    end
})

MoneyTab:CreateSection("Money Dupe")

MoneyTab:CreateToggle({
    Name = "Money Dupe",
    CurrentValue = false,
    Flag = "MoneyDupeToggle",
    Callback = function(Value)
        ToggleMoneyDupe(Value)
    end
})

MoneyTab:CreateSection("Give Money")

MoneyTab:CreateInput({
    Name = "Amount to Give",
    PlaceholderText = "Enter amount...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        GiveMoney(Text)
    end
})

MoneyTab:CreateSection("Set Money")

MoneyTab:CreateInput({
    Name = "Set Amount",
    PlaceholderText = "Enter amount...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        SetMoney(Text)
    end
})

-- Items Tab
local ItemsTab = Window:CreateTab("Items", 4483362458)
ItemsTab:CreateSection("Give Item")

ItemsTab:CreateDropdown({
    Name = "Select Item",
    Options = ZK.Items,
    CurrentOption = ZK.Items[1],
    Flag = "ItemDropdown",
    Callback = function(Option)
        ZK.SelectedItem = Option
    end
})

ItemsTab:CreateInput({
    Name = "Custom Item Name",
    PlaceholderText = "Or type custom name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text and Text ~= "" then
            ZK.SelectedItem = Text
        end
    end
})

ItemsTab:CreateButton({
    Name = "Give Item",
    Callback = function()
        if ZK.SelectedItem then
            GiveItem(ZK.SelectedItem)
        else
            Notify("Items", "No item selected", 3)
        end
    end
})

ItemsTab:CreateSection("Item Dupe")

ItemsTab:CreateButton({
    Name = "Dupe Held Item",
    Callback = function()
        DupeItem()
    end
})

-- Kill Tab
local KillTab = Window:CreateTab("Kill", 4483362458)
KillTab:CreateSection("Kill Player")

local KillDropdown = KillTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "KillDropdown",
    Callback = function(Option)
        ZK.SelectedPlayer = Option
    end
})

KillTab:CreateButton({
    Name = "Kill",
    Callback = function()
        if ZK.SelectedPlayer and ZK.SelectedPlayer ~= "" then
            KillPlayer(ZK.SelectedPlayer)
        else
            Notify("Kill", "No player selected", 3)
        end
    end
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)
SettingsTab:CreateSection("Anti-Cheat")

SettingsTab:CreateToggle({
    Name = "Anti-Cheat Bypass",
    CurrentValue = true,
    Flag = "ACBypassToggle",
    Callback = function(Value)
        ZK.AntiCheat.Enabled = Value
        if Value then
            InitACBypass()
        end
    end
})

SettingsTab:CreateButton({
    Name = "Scan Remotes",
    Callback = function()
        ScanRemotes()
    end
})

SettingsTab:CreateSection("Credits")

SettingsTab:CreateParagraph({
    Title = "ZKILLER HUB",
    Content = "Made by the invisible man\nVersion: 5.0\nGame: South Bronx: The Trenches"
})

-- Update player lists when players join/leave
Players.PlayerAdded:Connect(function()
    local list = GetPlayerList()
    TeleportDropdown:Set(list)
    SpectateDropdown:Set(list)
    BringDropdown:Set(list)
    KillDropdown:Set(list)
end)

Players.PlayerRemoving:Connect(function()
    local list = GetPlayerList()
    TeleportDropdown:Set(list)
    SpectateDropdown:Set(list)
    BringDropdown:Set(list)
    KillDropdown:Set(list)
end)

-- Initial scan
task.delay(2, function()
    ScanRemotes()
    InitACBypass()
end)

Notify("ZKILLER", "South Bronx script loaded successfully. Key: Zkiller", 5)
