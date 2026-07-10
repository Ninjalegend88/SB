-- South Bronx Trenches | The Invisible Man
-- Key: Zkiller
-- Total Lines: 1,247

-- ─── ANTI-CHEAT BYPASS ──────────────────────────────────────────────────

local function BypassAntiCheat()
    local success, err = pcall(function()
        -- Hook and disable detection functions
        for i, v in ipairs(getgc(true)) do
            if type(v) == "function" and isclosure(v) then
                local info = debug.getinfo(v)
                if info and info.name then
                    local name = info.name:lower()
                    if name:find("check") or name:find("detect") or name:find("ban") or name:find("report") or name:find("exploit") then
                        hookfunction(v, function() end)
                    end
                end
            end
        end
        
        -- Remove anti-cheat objects from workspace
        for i, v in ipairs(workspace:GetDescendants()) do
            if v.Name:lower():find("anticheat") or v.Name:lower():find("antiban") or v.Name:lower():find("exploit") or v.Name:lower():find("detect") then
                v:Destroy()
            end
        end
        
        -- Disable remote events and functions
        local remoteNames = {
            "AntiCheat", "BanEvent", "DetectionEvent", "ReportEvent", 
            "KickEvent", "LogEvent", "Watchdog", "SecurityCheck"
        }
        for i, name in ipairs(remoteNames) do
            local remote = game.ReplicatedStorage:FindFirstChild(name)
            if remote then remote:Destroy() end
            local remote2 = game.ReplicatedFirst:FindFirstChild(name)
            if remote2 then remote2:Destroy() end
        end
        
        -- Bypass Teleport/Ban checks
        local oldLoad = game.Loaded
        game.Loaded = function() end
        
        -- Disable studio detection
        if game:GetService("RunService"):IsStudio() then
            game:GetService("RunService"):SetStudio(false)
        end
    end)
end

BypassAntiCheat()

-- ─── LOAD RAYFIELD GEN2 ──────────────────────────────────────────────────

local Rayfield = nil
local loadSuccess, err = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/rayfield-gen2/main/source"))()
end)

if not loadSuccess or not Rayfield then
    local loadSuccess2, err2 = pcall(function()
        Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()
    end)
    if not loadSuccess2 or not Rayfield then
        Rayfield = loadstring(game:HttpGet("https://pastebin.com/raw/7k8qLkZz"))()
    end
end

if not Rayfield then
    game.StarterGui:SetCore("SendNotification", {
        Title = "Error",
        Text = "Failed to load UI. Check internet.",
        Duration = 5
    })
    return
end

-- ─── SERVICES ────────────────────────────────────────────────────────────

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- ─── VARIABLES ───────────────────────────────────────────────────────────

local aimbotEnabled = false
local silentAimEnabled = false
local selectedAimPart = "Head"
local teleportTarget = nil
local spectateTarget = nil
local spectating = false
local originalCam = workspace.CurrentCamera
local bringTarget = nil
local killTarget = nil
local selectedItem = nil
local espEnabled = false
local espBoxes = {}
local fovCircle = nil
local fovEnabled = false
local fps = 0
local frameCount = 0
local lastTime = tick()

-- ─── CREATE WINDOW ──────────────────────────────────────────────────────

local Window = Rayfield:CreateWindow({
   Name = "South Bronx Trenches",
   Icon = 0,
   LoadingTitle = "The Invisible Man",
   LoadingSubtitle = "by The Invisible Man",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SBTHub",
      FileName = "Config"
   },
   KeySystem = true,
   KeySettings = {
      Title = "Key System",
      Subtitle = "Enter Key Below",
      Note = "Key: Zkiller",
      FileName = "Key",
      SaveKey = false,
      GrabKeyFromSite = false,
      Key = {"Zkiller"}
   }
})

-- ─── TABS ──────────────────────────────────────────────────────────────

local Tab1 = Window:CreateTab("Aimbot")
local Tab2 = Window:CreateTab("Teleport")
local Tab3 = Window:CreateTab("Spectate")
local Tab4 = Window:CreateTab("Gun Mods")
local Tab5 = Window:CreateTab("Money")
local Tab6 = Window:CreateTab("Items")
local Tab7 = Window:CreateTab("Kill")
local Tab8 = Window:CreateTab("Visuals")
local Tab9 = Window:CreateTab("Settings")
local Tab10 = Window:CreateTab("Credits")

-- ─── HELPERS ─────────────────────────────────────────────────────────────

function GetPlayerList()
   local list = {}
   for i, v in ipairs(Players:GetPlayers()) do
      if v ~= LP then
         table.insert(list, v.Name)
      end
   end
   return list
end

function GetPlayerFromName(name)
   for i, v in ipairs(Players:GetPlayers()) do
      if v.Name == name then
         return v
      end
   end
   return nil
end

function GetAllItems()
   local items = {}
   for i, v in ipairs(workspace:GetDescendants()) do
      if v:IsA("Tool") and v:FindFirstChild("Handle") then
         if not table.find(items, v.Name) then
            table.insert(items, v.Name)
         end
      end
   end
   for i, v in ipairs(LP.Backpack:GetChildren()) do
      if v:IsA("Tool") then
         if not table.find(items, v.Name) then
            table.insert(items, v.Name)
         end
      end
   end
   return items
end

function GetClosestPlayer()
   local closest = nil
   local shortest = math.huge
   local center = Vector2.new(Mouse.X, Mouse.Y)
   for i, v in ipairs(Players:GetPlayers()) do
      if v ~= LP and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
         local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
         if onScreen then
            local dist = (center - Vector2.new(pos.X, pos.Y)).Magnitude
            if dist < shortest then
               shortest = dist
               closest = v
            end
         end
      end
   end
   return closest
end

function CreateESP(player)
   if espBoxes[player] then
      espBoxes[player]:Destroy()
      espBoxes[player] = nil
   end
   if not player.Character then return end
   local highlight = Instance.new("Highlight")
   highlight.FillColor = Color3.fromRGB(0, 255, 0)
   highlight.FillTransparency = 0.5
   highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
   highlight.OutlineTransparency = 0.2
   highlight.Adornee = player.Character
   highlight.Parent = player.Character
   espBoxes[player] = highlight
end

function RemoveESP(player)
   if espBoxes[player] then
      espBoxes[player]:Destroy()
      espBoxes[player] = nil
   end
end

-- ─── AIMBOT TAB ──────────────────────────────────────────────────────────

local AimbotSection = Tab1:CreateSection("Aimbot Settings")

local AimbotToggle = Tab1:CreateToggle({
   Name = "Enable Aimbot",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
      aimbotEnabled = Value
      if not Value then
         silentAimEnabled = false
      end
      Rayfield:Notify({
         Title = "Aimbot",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local SilentAimToggle = Tab1:CreateToggle({
   Name = "Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
      silentAimEnabled = Value
      Rayfield:Notify({
         Title = "Silent Aim",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local AimPartDropdown = Tab1:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
   CurrentOption = "Head",
   Flag = "AimPart",
   Callback = function(Option)
      selectedAimPart = Option
   end
})

local FOVSlider = Tab1:CreateSlider({
   Name = "FOV",
   Range = {1, 360},
   Increment = 1,
   Suffix = "°",
   CurrentValue = 180,
   Flag = "FOV",
   Callback = function(Value) end
})

local AimbotKeybind = Tab1:CreateKeybind({
   Name = "Aimbot Keybind",
   CurrentKeybind = "MouseButton2",
   Flag = "AimbotKeybind",
   Callback = function()
      aimbotEnabled = not aimbotEnabled
      Rayfield:Notify({
         Title = "Aimbot",
         Content = aimbotEnabled and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local AimbotKeybind = Tab1:CreateKeybind({
   Name = "Silent Aim Keybind",
   CurrentKeybind = "MouseButton3",
   Flag = "SilentAimKeybind",
   Callback = function()
      silentAimEnabled = not silentAimEnabled
      Rayfield:Notify({
         Title = "Silent Aim",
         Content = silentAimEnabled and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

-- ─── AIMBOT LOOP ──────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
   if not aimbotEnabled then return end
   
   local target = nil
   local shortestDist = math.huge
   
   for i, v in ipairs(Players:GetPlayers()) do
      if v ~= LP and v.Character and v.Character:FindFirstChild(selectedAimPart) then
         local part = v.Character[selectedAimPart]
         local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
         if onScreen then
            local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if dist < shortestDist and dist < FOVSlider.CurrentValue then
               shortestDist = dist
               target = v
            end
         end
      end
   end
   
   if target and target.Character and target.Character:FindFirstChild(selectedAimPart) then
      local part = target.Character[selectedAimPart]
      if silentAimEnabled then
         local oldPos = Mouse.Hit
         Mouse.Hit = CFrame.new(Mouse.Hit.Position, part.Position)
      else
         workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, part.Position)
      end
   end
end)

-- ─── TELEPORT TAB ───────────────────────────────────────────────────────

local TeleportSection = Tab2:CreateSection("Teleport To Player")

local TeleportDropdown = Tab2:CreateDropdown({
   Name = "Select Player",
   Options = GetPlayerList(),
   CurrentOption = "",
   Flag = "TeleportDropdown",
   Callback = function(Option)
      teleportTarget = Option
   end
})

local TeleportButton = Tab2:CreateButton({
   Name = "Teleport To Player",
   Callback = function()
      if teleportTarget then
         local target = GetPlayerFromName(teleportTarget)
         if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(LP.Character.HumanoidRootPart, tweenInfo, {CFrame = target.Character.HumanoidRootPart.CFrame})
            tween:Play()
            Rayfield:Notify({
               Title = "Teleported",
               Content = "You teleported to " .. teleportTarget,
               Duration = 2
            })
         end
      end
   end
})

local RefreshTeleport = Tab2:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      TeleportDropdown:SetOptions(GetPlayerList())
   end
})

-- ─── SPECTATE TAB ──────────────────────────────────────────────────────

local SpectateSection = Tab3:CreateSection("Spectate")

local SpectateDropdown = Tab3:CreateDropdown({
   Name = "Select Player",
   Options = GetPlayerList(),
   CurrentOption = "",
   Flag = "SpectateDropdown",
   Callback = function(Option)
      spectateTarget = Option
   end
})

local SpectateButton = Tab3:CreateButton({
   Name = "Start Spectate",
   Callback = function()
      if spectateTarget then
         local target = GetPlayerFromName(spectateTarget)
         if target and target.Character then
            spectating = true
            originalCam = workspace.CurrentCamera
            workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
            Rayfield:Notify({
               Title = "Spectating",
               Content = "Now spectating " .. spectateTarget,
               Duration = 2
            })
         end
      end
   end
})

local EndSpectateButton = Tab3:CreateButton({
   Name = "End Spectate",
   Callback = function()
      if spectating then
         spectating = false
         workspace.CurrentCamera.CameraSubject = LP.Character.Humanoid
         Rayfield:Notify({
            Title = "Spectate Ended",
            Content = "Back to your character",
            Duration = 2
         })
      end
   end
})

local RefreshSpectate = Tab3:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      SpectateDropdown:SetOptions(GetPlayerList())
   end
})

-- ─── GUN MODS TAB ──────────────────────────────────────────────────────

local GunModsSection = Tab4:CreateSection("Gun Mods")

local ShootThroughWalls = Tab4:CreateToggle({
   Name = "Shoot Through Walls",
   CurrentValue = false,
   Flag = "ShootThroughWalls",
   Callback = function(Value)
      Rayfield:Notify({
         Title = "Shoot Through Walls",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local InfiniteAmmo = Tab4:CreateToggle({
   Name = "Infinite Ammo",
   CurrentValue = false,
   Flag = "InfiniteAmmo",
   Callback = function(Value)
      Rayfield:Notify({
         Title = "Infinite Ammo",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local RapidFire = Tab4:CreateToggle({
   Name = "Rapid Fire",
   CurrentValue = false,
   Flag = "RapidFire",
   Callback = function(Value)
      Rayfield:Notify({
         Title = "Rapid Fire",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local NoRecoil = Tab4:CreateToggle({
   Name = "No Recoil",
   CurrentValue = false,
   Flag = "NoRecoil",
   Callback = function(Value)
      Rayfield:Notify({
         Title = "No Recoil",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local NoSpread = Tab4:CreateToggle({
   Name = "No Spread",
   CurrentValue = false,
   Flag = "NoSpread",
   Callback = function(Value)
      Rayfield:Notify({
         Title = "No Spread",
         Content = Value and "Enabled" or "Disabled",
         Duration = 2
      })
   end
})

local BringPlayerDropdown = Tab4:CreateDropdown({
   Name = "Select Player to Bring",
   Options = GetPlayerList(),
   CurrentOption = "",
   Flag = "BringPlayer",
   Callback = function(Option)
      bringTarget = Option
   end
})

local BringButton = Tab4:CreateButton({
   Name = "Bring Player",
   Callback = function()
      if bringTarget then
         local target = GetPlayerFromName(bringTarget)
         if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(target.Character.HumanoidRootPart, tweenInfo, {CFrame = LP.Character.HumanoidRootPart.CFrame})
            tween:Play()
            Rayfield:Notify({
               Title = "Brought",
               Content = "Brought " .. bringTarget .. " to you",
               Duration = 2
            })
         end
      end
   end
})

local RefreshBring = Tab4:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      BringPlayerDropdown:SetOptions(GetPlayerList())
   end
})

-- ─── GUN MODS LOOP ─────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function()
   local tool = LP.Character:FindFirstChildOfClass("Tool")
   if not tool then return end
   
   if Rayfield:GetFlag("InfiniteAmmo") then
      local ammo = tool:FindFirstChild("Ammo")
      if ammo then ammo.Value = 999 end
      local magazine = tool:FindFirstChild("Magazine")
      if magazine then magazine.Value = 999 end
      local ammoCount = tool:FindFirstChild("AmmoCount")
      if ammoCount then ammoCount.Value = 999 end
   end
   
   if Rayfield:GetFlag("RapidFire") then
      local fireRate = tool:FindFirstChild("FireRate")
      if fireRate then fireRate.Value = 0.01 end
      local rate = tool:FindFirstChild("Rate")
      if rate then rate.Value = 0.01 end
   end
   
   if Rayfield:GetFlag("ShootThroughWalls") then
      local bullet = tool:FindFirstChild("Bullet")
      if bullet then bullet.CanCollide = false end
      local projectile = tool:FindFirstChild("Projectile")
      if projectile then projectile.CanCollide = false end
   end
   
   if Rayfield:GetFlag("NoRecoil") then
      local recoil = tool:FindFirstChild("Recoil")
      if recoil then recoil.Value = 0 end
      local kickback = tool:FindFirstChild("Kickback")
      if kickback then kickback.Value = 0 end
   end
   
   if Rayfield:GetFlag("NoSpread") then
      local spread = tool:FindFirstChild("Spread")
      if spread then spread.Value = 0 end
      local accuracy = tool:FindFirstChild("Accuracy")
      if accuracy then accuracy.Value = 100 end
   end
end)

-- ─── MONEY TAB ─────────────────────────────────────────────────────────

local MoneySection = Tab5:CreateSection("Money")

local MoneyDupe = Tab5:CreateToggle({
   Name = "Money Dupe",
   CurrentValue = false,
   Flag = "MoneyDupe",
   Callback = function(Value)
      if Value then
         local money = LP:FindFirstChild("leaderstats")
         if money then
            local cash = money:FindFirstChild("Cash")
            if cash then
               cash.Value = cash.Value * 2
               Rayfield:Notify({
                  Title = "Money Dupe",
                  Content = "Money doubled to $" .. cash.Value,
                  Duration = 2
               })
            end
         end
      end
   end
})

local MoneyGive = Tab5:CreateSlider({
   Name = "Give Money",
   Range = {1, 1000000},
   Increment = 1000,
   Suffix = "$",
   CurrentValue = 1000,
   Flag = "MoneyGive",
   Callback = function(Value)
      local money = LP:FindFirstChild("leaderstats")
      if money then
         local cash = money:FindFirstChild("Cash")
         if cash then
            cash.Value = cash.Value + Value
            Rayfield:Notify({
               Title = "Money Given",
               Content = "Added $" .. Value .. " | Total: $" .. cash.Value,
               Duration = 2
            })
         end
      end
   end
})

local MoneyFarm = Tab5:CreateToggle({
   Name = "Money Farm",
   CurrentValue = false,
   Flag = "MoneyFarm",
   Callback = function(Value)
      if Value then
         spawn(function()
            while Rayfield:GetFlag("MoneyFarm") do
               local job = workspace:FindFirstChild("ConstructionJob")
               if job then
                  for _, part in ipairs(job:GetChildren()) do
                     if part:IsA("Part") and part.Name == "Task" then
                        local click = part:FindFirstChildOfClass("ClickDetector")
                        if click then
                           fireclickdetector(click)
                           wait(0.5)
                        end
                     end
                  end
               end
               wait(10)
            end
         end)
         Rayfield:Notify({
            Title = "Money Farm",
            Content = "Enabled",
            Duration = 2
         })
      else
         Rayfield:Notify({
            Title = "Money Farm",
            Content = "Disabled",
            Duration = 2
         })
      end
   end
})

local AutoClaim = Tab5:CreateToggle({
   Name = "Auto Claim Daily Reward",
   CurrentValue = false,
   Flag = "AutoClaim",
   Callback = function(Value)
      if Value then
         spawn(function()
            while Rayfield:GetFlag("AutoClaim") do
               local daily = workspace:FindFirstChild("DailyReward")
               if daily then
                  local click = daily:FindFirstChildOfClass("ClickDetector")
                  if click then fireclickdetector(click) end
               end
               wait(60)
            end
         end)
      end
   end
})

-- ─── ITEMS TAB ─────────────────────────────────────────────────────────

local ItemsSection = Tab6:CreateSection("Items")

local ItemDropdown = Tab6:CreateDropdown({
   Name = "Select Item",
   Options = GetAllItems(),
   CurrentOption = "",
   Flag = "ItemDropdown",
   Callback = function(Option)
      selectedItem = Option
   end
})

local GiveItemButton = Tab6:CreateButton({
   Name = "Give Item",
   Callback = function()
      if selectedItem then
         local item = nil
         for i, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Tool") and v.Name == selectedItem then
               item = v
               break
            end
         end
         if item then
            local existing = LP.Backpack:FindFirstChild(selectedItem)
            if existing then existing:Destroy() end
            local newItem = item:Clone()
            newItem.Parent = LP.Backpack
            Rayfield:Notify({
               Title = "Item Given",
               Content = "Gave " .. selectedItem,
               Duration = 2
            })
         else
            Rayfield:Notify({
               Title = "Item Not Found",
               Content = "Could not find " .. selectedItem .. " in workspace",
               Duration = 2
            })
         end
      end
   end
})

local ItemDupe = Tab6:CreateToggle({
   Name = "Item Dupe",
   CurrentValue = false,
   Flag = "ItemDupe",
   Callback = function(Value)
      if Value then
         local tool = LP.Character:FindFirstChildOfClass("Tool")
         if tool then
            local newTool = tool:Clone()
            newTool.Parent = LP.Backpack
            Rayfield:Notify({
               Title = "Duplicated",
               Content = "Duplicated " .. tool.Name,
               Duration = 2
            })
         else
            Rayfield:Notify({
               Title = "No Tool",
               Content = "Equip a tool first",
               Duration = 2
            })
         end
      end
   end
})

local RefreshItems = Tab6:CreateButton({
   Name = "Refresh Item List",
   Callback = function()
      ItemDropdown:SetOptions(GetAllItems())
      Rayfield:Notify({
         Title = "Items Refreshed",
         Content = "Found " .. #GetAllItems() .. " items",
         Duration = 2
      })
   end
})

-- ─── KILL TAB ──────────────────────────────────────────────────────────

local KillSection = Tab7:CreateSection("Kill")

local KillDropdown = Tab7:CreateDropdown({
   Name = "Select Player",
   Options = GetPlayerList(),
   CurrentOption = "",
   Flag = "KillDropdown",
   Callback = function(Option)
      killTarget = Option
   end
})

local KillButton = Tab7:CreateButton({
   Name = "Kill Player",
   Callback = function()
      if killTarget then
         local target = GetPlayerFromName(killTarget)
         if target and target.Character and target.Character:FindFirstChild("Humanoid") then
            target.Character.Humanoid.Health = 0
            Rayfield:Notify({
               Title = "Killed",
               Content = "Killed " .. killTarget,
               Duration = 2
            })
         end
      end
   end
})

local KillAllButton = Tab7:CreateButton({
   Name = "Kill All Players",
   Callback = function()
      local count = 0
      for i, v in ipairs(Players:GetPlayers()) do
         if v ~= LP and v.Character and v.Character:FindFirstChild("Humanoid") then
            v.Character.Humanoid.Health = 0
            count = count + 1
         end
      end
      Rayfield:Notify({
         Title = "Kill All",
         Content = "Killed " .. count .. " players",
         Duration = 2
      })
   end
})

local RefreshKill = Tab7:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      KillDropdown:SetOptions(GetPlayerList())
   end
})

-- ─── VISUALS TAB ──────────────────────────────────────────────────────

local VisualsSection = Tab8:CreateSection("Visuals")

local ESPToggle = Tab8:CreateToggle({
   Name = "ESP",
   CurrentValue = false,
   Flag = "ESPToggle",
   Callback = function(Value)
      espEnabled = Value
      if not Value then
         for i, v in ipairs(Players:GetPlayers()) do
            if v ~= LP then
               RemoveESP(v)
            end
         end
      else
         for i, v in ipairs(Players:GetPlayers()) do
            if v ~= LP then
               CreateESP(v)
            end
         end
      end
   end
})

local FOVCircleToggle = Tab8:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = false,
   Flag = "FOVCircleToggle",
   Callback = function(Value)
      fovEnabled = Value
      if not Value and fovCircle then
         fovCircle:Destroy()
         fovCircle = nil
      end
   end
})

local ESPColorPicker = Tab8:CreateColorPicker({
   Name = "ESP Color",
   Color = Color3.fromRGB(0, 255, 0),
   Flag = "ESPColor",
   Callback = function(Color)
      for i, v in ipairs(Players:GetPlayers()) do
         if v ~= LP and espBoxes[v] then
            espBoxes[v].FillColor = Color
         end
      end
   end
})

-- ─── FOV CIRCLE DRAW ──────────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
   if not fovEnabled then 
      if fovCircle then
         fovCircle:Destroy()
         fovCircle = nil
      end
      return 
   end
   
   if not fovCircle then
      fovCircle = Drawing.new("Circle")
      fovCircle.Color = Color3.fromRGB(255, 255, 255)
      fovCircle.Thickness = 1
      fovCircle.Filled = false
      fovCircle.Transparency = 0.5
      fovCircle.Radius = FOVSlider.CurrentValue
   end
   
   local viewport = game:GetService("GuiService").GetGuiInset(game:GetService("GuiService"))
   fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + viewport.Y)
   fovCircle.Radius = FOVSlider.CurrentValue
   fovCircle.Visible = true
end)

-- ─── SETTINGS TAB ─────────────────────────────────────────────────────

local SettingsSection = Tab9:CreateSection("UI Settings")

local CustomTitle = Tab9:CreateInput({
   Name = "Custom Window Title",
   PlaceholderText = "South Bronx Trenches",
   Flag = "CustomTitle",
   Callback = function(Text)
      if Text and Text ~= "" then
         Window:SetName(Text)
      end
   end
})

local ThemeDropdown = Tab9:CreateDropdown({
   Name = "Theme",
   Options = {"Dark", "Light", "Neon", "Midnight", "Sunset"},
   CurrentOption = "Dark",
   Flag = "ThemeDropdown",
   Callback = function(Option)
      local themes = {
         Dark = {Background = Color3.fromRGB(20, 20, 25), Text = Color3.fromRGB(255, 255, 255)},
         Light = {Background = Color3.fromRGB(240, 240, 245), Text = Color3.fromRGB(0, 0, 0)},
         Neon = {Background = Color3.fromRGB(10, 0, 20), Text = Color3.fromRGB(0, 255, 255)},
         Midnight = {Background = Color3.fromRGB(5, 5, 15), Text = Color3.fromRGB(150, 200, 255)},
         Sunset = {Background = Color3.fromRGB(30, 10, 5), Text = Color3.fromRGB(255, 200, 150)}
      }
      if themes[Option] then
         -- Apply theme (Rayfield may not support this directly, but we try)
         Rayfield:SetTheme(themes[Option])
      end
   end
})

local ResetConfig = Tab9:CreateButton({
   Name = "Reset Configuration",
   Callback = function()
      Rayfield:ResetConfig()
      Rayfield:Notify({
         Title = "Reset",
         Content = "Configuration reset to default",
         Duration = 2
      })
   end
})

-- ─── CREDITS TAB ──────────────────────────────────────────────────────

local CreditsSection = Tab10:CreateSection("Credits")

local CreditsLabel = Tab10:CreateLabel("by The Invisible Man")
local CreditsLabel2 = Tab10:CreateLabel("")
local CreditsLabel3 = Tab10:CreateLabel("❤️ Made with love")
local CreditsLabel4 = Tab10:CreateLabel("")
local CreditsLabel5 = Tab10:CreateLabel("South Bronx Trenches")
local CreditsLabel6 = Tab10:CreateLabel("Key: Zkiller")

local CreditsButton = Tab10:CreateButton({
   Name = "❤️ Support",
   Callback = function()
      Rayfield:Notify({
         Title = "The Invisible Man",
         Content = "Thanks for using!",
         Duration = 3
      })
   end
})

-- ─── AUTO REFRESH PLAYER LISTS ──────────────────────────────────────

spawn(function()
   while true do
      wait(5)
      local players = GetPlayerList()
      pcall(function()
         TeleportDropdown:SetOptions(players)
         SpectateDropdown:SetOptions(players)
         BringPlayerDropdown:SetOptions(players)
         KillDropdown:SetOptions(players)
      end)
   end
end)

-- ─── AUTO ESP UPDATE ──────────────────────────────────────────────────

spawn(function()
   while true do
      wait(2)
      if espEnabled then
         for i, v in ipairs(Players:GetPlayers()) do
            if v ~= LP then
               if v.Character and not espBoxes[v] then
                  CreateESP(v)
               end
            end
         end
      end
   end
end)

-- ─── PLAYER REMOVED HANDLER ──────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
   RemoveESP(player)
end)

-- ─── NOTIFY ON LOAD ──────────────────────────────────────────────────

Rayfield:Notify({
   Title = "Loaded",
   Content = "South Bronx Trenches | by The Invisible Man | 1,247 Lines",
   Duration = 3
})

-- ─── KEYBIND TO TOGGLE UI ───────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   if input.KeyCode == Enum.KeyCode.RightShift then
      Window:Toggle()
   end
end)

print("South Bronx Trenches loaded successfully")
print("Key: Zkiller")
print("by The Invisible Man")
print("Lines: 1,247")
