-- Xeno Executor Script for Roblox
-- Created by DeepHat

-- Setup variables
local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false -- Prevent automatic cleanup

-- Create overlay for ESP
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Visible = false
overlay.Parent = gui

-- State variables
local aimbotEnabled = false
local espEnabled = true
local sensitivity = 0.5
local boxColor = Color3.fromRGB(255, 0, 0)
local trackedElements = {} -- Pool of UI elements
local trackedPlayers = {} -- Map of players to their tracked elements
local lastFramePlayers = {} -- Track players from last frame to avoid rebuilding

-- Wait for camera with timeout
local camera = workspace.CurrentCamera
local attempt = 0
while not camera and attempt < 100 do
    game:GetService("RunService").Heartbeat:Wait()
    camera = workspace.CurrentCamera
    attempt = attempt + 1
end

if not camera then
    warn("No camera found after waiting, exiting")
    return
end

-- Create UI
local uiContainer = Instance.new("Frame")
uiContainer.Name = "XenoUI"
uiContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
uiContainer.BorderSizePixel = 0
uiContainer.Position = UDim2.new(0, 0, 0, 0)
uiContainer.Size = UDim2.new(1, 0, 1, 0)
uiContainer.Visible = false
uiContainer.Parent = gui

-- Create main panel
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
panel.BorderSizePixel = 2
panel.BorderColor3 = Color3.fromRGB(80, 80, 80)
panel.Position = UDim2.new(0.5, -200, 0.5, -150)
panel.Size = UDim2.new(0, 400, 0, 300)
panel.Parent = uiContainer

-- UI Elements
local title = Instance.new("TextLabel")
title.Text = "Xeno Executor | ESP & Aimbot"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.Parent = panel

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Text = "Close [ESC]"
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 14
closeButton.BackgroundTransparency = 0
closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
closeButton.Size = UDim2.new(0, 80, 0, 30)
closeButton.Position = UDim2.new(1, -90, 0, 0)
closeButton.MouseButton1Click:Connect(function()
    uiContainer.Visible = false
end)
closeButton.Parent = panel

-- Aimbot section
local aimbotSection = Instance.new("Frame")
aimbotSection.Name = "AimbotSection"
aimbotSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aimbotSection.BorderSizePixel = 0
aimbotSection.Position = UDim2.new(0, 0, 0, 30)
aimbotSection.Size = UDim2.new(1, 0, 0, 100)
aimbotSection.Parent = panel

local aimbotLabel = Instance.new("TextLabel")
aimbotLabel.Text = "Aimbot Settings"
aimbotLabel.Font = Enum.Font.SourceSansBold
aimbotLabel.TextSize = 14
aimbotLabel.BackgroundTransparency = 1
aimbotLabel.Size = UDim2.new(1, 0, 0, 20)
aimbotLabel.Position = UDim2.new(0, 0, 0, 0)
aimbotLabel.Parent = aimbotSection

local aimbotToggle = Instance.new("TextButton")
aimbotToggle.Text = "Aimbot Off"
aimbotToggle.Font = Enum.Font.SourceSansBold
aimbotToggle.TextSize = 12
aimbotToggle.BackgroundTransparency = 0
aimbotToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
aimbotToggle.Size = UDim2.new(0, 80, 0, 20)
aimbotToggle.Position = UDim2.new(0.5, -40, 0, 30)
aimbotToggle.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotToggle.Text = aimbotEnabled and "Aimbot On" or "Aimbot Off"
end)
aimbotToggle.Parent = aimbotSection

-- Sensitivity controls
local sensitivityLabel = Instance.new("TextLabel")
sensitivityLabel.Text = "Sensitivity: 0.5"
sensitivityLabel.Font = Enum.Font.SourceSans
sensitivityLabel.TextSize = 12
sensitivityLabel.BackgroundTransparency = 1
sensitivityLabel.Size = UDim2.new(0, 100, 0, 20)
sensitivityLabel.Position = UDim2.new(0, 50, 0, 60)
sensitivityLabel.Parent = aimbotSection

-- ESP section
local espSection = Instance.new("Frame")
espSection.Name = "ESPSection"
espSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
espSection.BorderSizePixel = 0
espSection.Position = UDim2.new(0, 0, 0, 130)
espSection.Size = UDim2.new(1, 0, 0, 120)
espSection.Parent = panel

local espLabel = Instance.new("TextLabel")
espLabel.Text = "ESP Settings"
espLabel.Font = Enum.Font.SourceSansBold
espLabel.TextSize = 14
espLabel.BackgroundTransparency = 1
espLabel.Size = UDim2.new(1, 0, 0, 20)
espLabel.Position = UDim2.new(0, 0, 0, 0)
espLabel.Parent = espSection

local espToggle = Instance.new("TextButton")
espToggle.Text = "ESP On"
espToggle.Font = Enum.Font.SourceSansBold
espToggle.TextSize = 12
espToggle.BackgroundTransparency = 0
espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
espToggle.Size = UDim2.new(0, 80, 0, 20)
espToggle.Position = UDim2.new(0.5, -40, 0, 30)
espToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espToggle.Text = espEnabled and "ESP On" or "ESP Off"
    overlay.Visible = espEnabled
end)
espToggle.Parent = espSection

-- Box color selector
local boxColorLabel = Instance.new("TextLabel")
boxColorLabel.Text = "Box Color:"
boxColorLabel.Font = Enum.Font.SourceSans
boxColorLabel.TextSize = 12
boxColorLabel.BackgroundTransparency = 1
boxColorLabel.Size = UDim2.new(0, 80, 0, 20)
boxColorLabel.Position = UDim2.new(0, 20, 0, 60)
boxColorLabel.Parent = espSection

local boxColorDisplay = Instance.new("Frame")
boxColorDisplay.BackgroundColor3 = boxColor
boxColorDisplay.BorderSizePixel = 1
boxColorDisplay.BorderColor3 = Color3.fromRGB(255, 255, 255)
boxColorDisplay.Size = UDim2.new(0, 20, 0, 20)
boxColorDisplay.Position = UDim2.new(0, 100, 0, 60)
boxColorDisplay.Parent = espSection

-- Keybind handler
userInputService.InputBegan:Connect(function(input, processed)
    if processed then return end -- Ignore already processed inputs
    
    if input.KeyCode == Enum.KeyCode.RightShift then
        uiContainer.Visible = not uiContainer.Visible
    elseif input.KeyCode == Enum.KeyCode.V then
        aimbotEnabled = not aimbotEnabled
        aimbotToggle.Text = aimbotEnabled and "Aimbot On" or "Aimbot Off"
    elseif input.KeyCode == Enum.KeyCode.Escape then
        uiContainer.Visible = false
    end
end)

-- Get valid players for aimbot/ESP
local function getValidPlayers()
    local players = {}
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player 
            and plr.Character 
            and plr.Character:FindFirstChild("Humanoid") 
            and plr.Character.Humanoid.Health > 0 
            and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(players, plr)
        end
    end
    return players
end

-- Get character parts (handles both R6 and R15)
local function getCharacterParts(character)
    local parts = {}
    
    -- Check for R15 (no Body folder)
    local upperTorso = character:FindFirstChild("UpperTorso")
    if upperTorso then
        parts = {
            Head = character:FindFirstChild("Head"),
            Torso = upperTorso,
            LeftArm = character:FindFirstChild("LeftUpperArm"),  -- R15 uses different limb names
            RightArm = character:FindFirstChild("RightUpperArm"),
            LeftLeg = character:FindFirstChild("LeftUpperLeg"),
            RightLeg = character:FindFirstChild("RightUpperLeg")
        }
    else
        -- Fall back to R6
        parts = {
            Head = character:FindFirstChild("Head"),
            Torso = character:FindFirstChild("Torso"),
            LeftArm = character:FindFirstChild("Left Arm"),
            RightArm = character:FindFirstChild("Right Arm"),
            LeftLeg = character:FindFirstChild("Left Leg"),
            RightLeg = character:FindFirstChild("Right Leg")
        }
    end
    
    -- Validate all parts exist
    for name, part in pairs(parts) do
        if not part then
            parts[name] = nil
        end
    end
    
    return parts
end

-- Create a new UI element of type typeName
local function createUIElement(typeName)
    local newElem = Instance.new(typeName)
    newElem.Visible = false
    newElem.Parent = overlay
    table.insert(trackedElements, newElem)
    return newElem
end

-- Get a UI element of type typeName from the pool
local function getUIElement(typeName)
    for _, elem in ipairs(trackedElements) do
        if elem:IsA(typeName) and not elem.Visible then
            elem.Visible = true
            return elem
        end
    end
    
    -- Create new element if none available
    return createUIElement(typeName)
end

-- Cleanup elements for a player
local function cleanupPlayerElements(plr)
    if trackedPlayers[plr] then
        for _, elem in ipairs(trackedPlayers[plr]) do
            elem.Visible = false
        end
        trackedPlayers[plr] = nil
    end
end

-- Cleanup when player leaves
game.Players.PlayerRemoving:Connect(function(plr)
    cleanupPlayerElements(plr)
end)

-- Update camera reference periodically
workspace.ChildAdded:Connect(function(child)
    if child.Name == "CurrentCamera" then
        camera = child
    end
end)

-- Aimbot functionality
runService.RenderStepped:Connect(function()
    if aimbotEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local players = getValidPlayers()
        local closestPlayer = nil
        local closestDistance = math.huge
        
        for _, plr in ipairs(players) do
            local rootPart = plr.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local distance = (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = plr
                end
            end
        end
        
        if closestPlayer then
            local targetPart = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                -- Set camera focus to target part
                camera.Focus = CFrame.new(camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end)

-- ESP functionality with dynamic box sizing
runService.RenderStepped:Connect(function()
    if espEnabled then
        overlay.Visible = true
        
        -- Only rebuild tracking for players that changed since last frame
        local currentPlayers = {}
        for _, plr in ipairs(getValidPlayers()) do
            currentPlayers[plr] = true
        end
        
        -- Remove elements for players no longer in view
        for plr, _ in pairs(lastFramePlayers) do
            if not currentPlayers[plr] then
                cleanupPlayerElements(plr)
            end
        end
        
        -- Update elements for players in view
        for _, plr in ipairs(getValidPlayers()) do
            local character = plr.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head then
                    local screenPoint, onScreen = camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        -- Track this player
                        currentPlayers[plr] = true
                        
                        -- Calculate dynamic box size based on distance
                        local distance = (head.Position - camera.CFrame.Position).Magnitude
                        local baseSize = 100
                        local scale = math.min(1, math.max(0.1, 1000 / distance))  -- Cap at 1000 units
                        local width = baseSize * scale
                        local height = baseSize * scale
                        
                        -- Get or create box element
                        local box = getUIElement("Frame")
                        box.BackgroundColor3 = boxColor
                        box.BackgroundTransparency = 1  -- Transparent fill
                        box.BorderSizePixel = 1
                        box.BorderColor3 = Color3.fromRGB(255, 255, 255)
                        box.Position = UDim2.new(0, screenPoint.X - width/2, 0, screenPoint.Y - height/2)
                        box.Size = UDim2.new(0, width, 0, height)
                        
                        -- Track this element for this player
                        if not trackedPlayers[plr] then
                            trackedPlayers[plr] = {}
                        end
                        table.insert(trackedPlayers[plr], box)
                        
                        -- Draw skeleton lines
                        local parts = getCharacterParts(character)
                        if parts.Torso and parts.Head then
                            local headScreen, _ = camera:WorldToViewportPoint(parts.Head.Position)
                            local torsoScreen, _ = camera:WorldToViewportPoint(parts.Torso.Position)
                            
                            -- Create skeleton line between head and torso
                            local line = getUIElement("Frame")
                            line.BackgroundColor3 = boxColor
                            line.BorderSizePixel = 0
                            line.Size = UDim2.new(0, 2, 0, math.abs(torsoScreen.Y - headScreen.Y))
                            line.Position = UDim2.new(0, headScreen.X - 1, 0, headScreen.Y)
                            
                            -- Track this element for this player
                            table.insert(trackedPlayers[plr], line)
                        end
                        
                        -- Draw health bar
                        local healthBar = getUIElement("Frame")
                        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        healthBar.BorderSizePixel = 0
                        healthBar.Size = UDim2.new(0, width, 0, 10)
                        healthBar.Position = UDim2.new(0, screenPoint.X - width/2, 0, screenPoint.Y - height/2 - 15)
                        
                        -- Track this element for this player
                        table.insert(trackedPlayers[plr], healthBar)
                        
                        -- Health percentage (with safety check)
                        local human = plr.Character:FindFirstChild("Humanoid")
                        if human and human.MaxHealth > 0 then
                            healthBar.Size = UDim2.new(0, width * (human.Health / human.MaxHealth), 0, 10)
                        end
                    end
                end
            end
        end
        
        -- Store current players for next frame
        lastFramePlayers = currentPlayers
    else
        overlay.Visible = false
    end
end)

-- Initialize UI
uiContainer.Visible = false
