-- South Bronx Trenches | The Invisible Man
-- Key: Zkiller
-- Rayfield Gen2 Required

-- Load Rayfield Gen2
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/rayfield-gen2/main/source"))()

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()
local Mouse = LP:GetMouse()
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

-- Variables
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

-- Create Window
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

-- Create Tabs
local Tab1 = Window:CreateTab("Aimbot")
local Tab2 = Window:CreateTab("Teleport")
local Tab3 = Window:CreateTab("Spectate")
local Tab4 = Window:CreateTab("Gun Mods")
local Tab5 = Window:CreateTab("Money")
local Tab6 = Window:CreateTab("Items")
local Tab7 = Window:CreateTab("Kill")
local Tab8 = Window:CreateTab("Credits")

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
         table.insert(items, v.Name)
      end
   end
   for i, v in ipairs(LP.Backpack:GetChildren()) do
      if v:IsA("Tool") then
         table.insert(items, v.Name)
      end
   end
   return items
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
   end
})

local SilentAimToggle = Tab1:CreateToggle({
   Name = "Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
      silentAimEnabled = Value
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

-- Aimbot Loop
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
            LP.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
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
      if Value then
         local tool = LP.Character:FindFirstChildOfClass("Tool")
         if tool then
            tool.GripPos = Vector3.new(0, 0, 0)
         end
      end
   end
})

local InfiniteAmmo = Tab4:CreateToggle({
   Name = "Infinite Ammo",
   CurrentValue = false,
   Flag = "InfiniteAmmo",
   Callback = function(Value) end
})

local RapidFire = Tab4:CreateToggle({
   Name = "Rapid Fire",
   CurrentValue = false,
   Flag = "RapidFire",
   Callback = function(Value) end
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
            target.Character.HumanoidRootPart.CFrame = LP.Character.HumanoidRootPart.CFrame
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

-- Gun Mods Loop
RunService.Heartbeat:Connect(function()
   local tool = LP.Character:FindFirstChildOfClass("Tool")
   if not tool then return end
   
   if Rayfield:GetFlag("InfiniteAmmo") then
      local ammo = tool:FindFirstChild("Ammo")
      if ammo then ammo.Value = 999 end
      local magazine = tool:FindFirstChild("Magazine")
      if magazine then magazine.Value = 999 end
   end
   
   if Rayfield:GetFlag("RapidFire") then
      local fireRate = tool:FindFirstChild("FireRate")
      if fireRate then fireRate.Value = 0.01 end
   end
   
   if Rayfield:GetFlag("ShootThroughWalls") then
      local bullet = tool:FindFirstChild("Bullet")
      if bullet then bullet.CanCollide = false end
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
            end
         end
      end
   end
})

local MoneyGive = Tab5:CreateSlider({
   Name = "Give Money",
   Range = {1, 100000},
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
         end
      end
      Rayfield:Notify({
         Title = "Money Given",
         Content = "Added $" .. Value,
         Duration = 2
      })
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
                        fireclickdetector(part:FindFirstChild("ClickDetector"))
                        wait(1)
                     end
                  end
               end
               wait(10)
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
         end
      end
   end
})

local RefreshItems = Tab6:CreateButton({
   Name = "Refresh Item List",
   Callback = function()
      ItemDropdown:SetOptions(GetAllItems())
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

local RefreshKill = Tab7:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      KillDropdown:SetOptions(GetPlayerList())
   end
})

-- ─── CREDITS TAB ──────────────────────────────────────────────────────

local CreditsSection = Tab8:CreateSection("Credits")

local CreditsLabel = Tab8:CreateLabel("by The Invisible Man")

local CreditsButton = Tab8:CreateButton({
   Name = "❤️ Made with love",
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
      TeleportDropdown:SetOptions(players)
      SpectateDropdown:SetOptions(players)
      BringPlayerDropdown:SetOptions(players)
      KillDropdown:SetOptions(players)
   end
end)

-- ─── NOTIFY ON LOAD ──────────────────────────────────────────────────

Rayfield:Notify({
   Title = "Loaded",
   Content = "South Bronx Trenches | by The Invisible Man",
   Duration = 3
})
