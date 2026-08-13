-- ⚠️ IMPORTANT: Put this code at the VERY TOP of your Main Script (before obfuscating) ⚠️

local ProtectionConfig = {
    -- 🔴 CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "test",
    
    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "FLICK"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end

-------------------------------------------------------------------------------
-- 👇 YOUR MAIN SCRIPT CODE STARTS HERE 👇
-------------------------------------------------------------------------------

print(ProtectionConfig.HubName .. " Loaded Successfully!")


local Settings = {
    AimbotEnabled = true,
    FOV = 150,
    Smoothness = 0.5,
    WallhackEnabled = true,
    TargetPart = "Head",
    VisibleCheck = true
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- ==========================================
-- VALIDASI GAME
-- ==========================================
local TARGET_PLACE_ID = 136801880565837

local function checkGame()
    if game.PlaceId ~= TARGET_PLACE_ID then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "⚠️ WRONG GAME",
                Text = "Script hanya untuk game Flick!",
                Duration = 3
            })
        end)
        task.wait(2)
        game:Shutdown()
        return false
    end
    return true
end

if not checkGame() then return end

-- ==========================================
-- NOTIFIKASI
-- ==========================================
local function sendNotification(title, text, duration)
    spawn(function()
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title or "🚀 FlickAimPro",
                Text = text,
                Duration = duration or 4
            })
        end)
    end)
end

-- ==========================================
-- CONFIG LOAD & SAVE
-- ==========================================
local configFile = "FlickAimPro_Config.json"

if isfile(configFile) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if success and data then
        for k, v in pairs(data) do
            if Settings[k] ~= nil then
                Settings[k] = v
            end
        end
    end
end

local function saveConfig()
    pcall(function()
        writefile(configFile, HttpService:JSONEncode({
            AimbotEnabled = Settings.AimbotEnabled,
            FOV = Settings.FOV,
            Smoothness = Settings.Smoothness,
            WallhackEnabled = Settings.WallhackEnabled,
            TargetPart = Settings.TargetPart,
            VisibleCheck = Settings.VisibleCheck
        }))
    end)
end

-- ==========================================
-- AIMBOT LOGIC
-- ==========================================
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(targetCharacter)
    if not Settings.VisibleCheck then return true end
    local targetPart = targetCharacter:FindFirstChild(Settings.TargetPart)
    if not targetPart then return false end
    
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    local result = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position), raycastParams)
    return result == nil
end

local function getClosestPlayer()
    local closest, shortest = nil, Settings.FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then continue end
        
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        
        if dist < shortest and isVisible(char) then
            shortest = dist
            closest = player
        end
    end
    return closest
end

-- ==========================================
-- ESP HIGHLIGHT
-- ==========================================
local function applyHighlight(player)
    if player == LocalPlayer then return end
    local function setup(char)
        if not char then return end
        char:WaitForChild("HumanoidRootPart", 3)
        if char:FindFirstChild("DeltaWH") then char.DeltaWH:Destroy() end
        if Settings.WallhackEnabled then
            local hl = Instance.new("Highlight")
            hl.Name = "DeltaWH"
            hl.FillColor = Color3.fromRGB(255, 0, 0)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.Adornee = char
            hl.Parent = char
        end
    end
    if player.Character then setup(player.Character) end
    player.CharacterAdded:Connect(setup)
end

for _, p in ipairs(Players:GetPlayers()) do applyHighlight(p) end
Players.PlayerAdded:Connect(applyHighlight)

local function updateAllWH()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then
            if Settings.WallhackEnabled then
                applyHighlight(p)
            elseif p.Character:FindFirstChild("DeltaWH") then
                p.Character.DeltaWH:Destroy()
            end
        end
    end
end

-- ==========================================
-- SILENT AIM LOADER
-- ==========================================
local silentAimLoaded = false

local function loadSilentAim(btn)
    if silentAimLoaded then
        sendNotification("Silent Aim", "⚠️ Already loaded!", 2)
        return
    end
    
    local success, err = pcall(function()
        getgenv().sneeky_silent_aim = true
        getgenv().sneeky_fov_size = 300
        loadstring(game:HttpGet("https://sneekysscripts.uk/Scripts/FPS_Flick/main.luau"))()
    end)
    
    if success then
        silentAimLoaded = true
        if btn then
            btn.Text = "✅ Silent Aim Loaded"
            btn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
            btn.Active = false
            btn.AutoButtonColor = false
        end
        sendNotification("Silent Aim", "✅ Loaded! FOV: 300", 4)
    else
        sendNotification("Silent Aim", "❌ Failed! " .. tostring(err), 5)
    end
end

-- ==========================================
-- UI
-- ==========================================
local UI = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
UI.Name = "FlickAimProUI"
UI.ResetOnSpawn = false

-- FOV Circle (Aimbot - MERAH)
local FOVFrame = Instance.new("Frame", UI)
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Size = UDim2.new(0, Settings.FOV * 2, 0, Settings.FOV * 2)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Visible = Settings.AimbotEnabled

local UICorner = Instance.new("UICorner", FOVFrame)
UICorner.CornerRadius = UDim.new(1, 0)

local UIStroke = Instance.new("UIStroke", FOVFrame)
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 1.5
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Toggle Button
local ToggleBtn = Instance.new("TextButton", UI)
ToggleBtn.Size = UDim2.new(0, 60, 0, 40)
ToggleBtn.Position = UDim2.new(0.85, 0, 0.15, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "MENU"
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.Active = true
ToggleBtn.Draggable = true 

-- Main Frame
local MainFrame = Instance.new("Frame", UI)
MainFrame.Size = UDim2.new(0, 230, 0, 295)
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -147)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Button Creator
local function CreateBtn(name, key, posY, cb)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
    btn.BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    
    btn.MouseButton1Click:Connect(function()
        Settings[key] = not Settings[key]
        btn.Text = name .. ": " .. (Settings[key] and "ON" or "OFF")
        btn.BackgroundColor3 = Settings[key] and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
        if key == "AimbotEnabled" then
            FOVFrame.Visible = Settings.AimbotEnabled
        end
        if cb then cb() end
        saveConfig()
        sendNotification("FlickAimPro", name .. " " .. (Settings[key] and "ON" or "OFF"), 3)
    end)
    return btn
end

CreateBtn("Aimbot", "AimbotEnabled", 10)
CreateBtn("WallCheck", "VisibleCheck", 55)
CreateBtn("Wallhack (ESP)", "WallhackEnabled", 100, updateAllWH)

-- Silent Aim Load Button
local silentBtn = Instance.new("TextButton", MainFrame)
silentBtn.Name = "SilentAimBtn"
silentBtn.Size = UDim2.new(0.9, 0, 0, 35)
silentBtn.Position = UDim2.new(0.05, 0, 0, 145)
silentBtn.Text = "🔇 Load Silent Aim"
silentBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 30)
silentBtn.TextColor3 = Color3.new(1,1,1)
silentBtn.Font = Enum.Font.SourceSansBold
silentBtn.TextSize = 14

silentBtn.MouseButton1Click:Connect(function()
    loadSilentAim(silentBtn)
end)

-- TextBox Creator
local function CreateTextBox(placeholder, defaultVal, posY, cb)
    local box = Instance.new("TextBox", MainFrame)
    box.Size = UDim2.new(0.9, 0, 0, 35)
    box.Position = UDim2.new(0.05, 0, 0, posY)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    box.TextColor3 = Color3.new(1,1,1)
    box.Text = placeholder .. ": " .. tostring(defaultVal)
    box.Font = Enum.Font.SourceSansBold
    
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text:match("%d+%.?%d*"))
        if val then
            cb(val)
            box.Text = placeholder .. ": " .. tostring(val)
            saveConfig()
            sendNotification("FlickAimPro", placeholder .. " set to " .. tostring(val), 3)
        else
            box.Text = placeholder .. ": " .. tostring(defaultVal)
        end
    end)
    return box
end

CreateTextBox("FOV Size", Settings.FOV, 190, function(v)
    Settings.FOV = v
    FOVFrame.Size = UDim2.new(0, v * 2, 0, v * 2)
end)

CreateTextBox("Smooth (0-1)", Settings.Smoothness, 235, function(v)
    Settings.Smoothness = math.clamp(v, 0, 1)
end)

-- ==========================================
-- LOOP AIMBOT
-- ==========================================
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(Settings.TargetPart) then
            local targetPos = target.Character[Settings.TargetPart].Position
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - Settings.Smoothness)
        end
    end
    FOVFrame.Visible = Settings.AimbotEnabled
end)

sendNotification("FlickAimPro", "✅ Script loaded! Enjoy.", 4)
