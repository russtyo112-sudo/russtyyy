-- Xeno Executor Script for Roblox
-- Created by DeepHat

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

-- Create UI container
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

-- Aimbot settings
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

-- Aimbot toggle
local aimbotToggle = Instance.new("TextButton")
aimbotToggle.Text = "Aimbot On"
aimbotToggle.Font = Enum.Font.SourceSansBold
aimbotToggle.TextSize = 12
aimbotToggle.BackgroundTransparency = 0
aimbotToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
aimbotToggle.Size = UDim2.new(0, 80, 0, 20)
aimbotToggle.Position = UDim2.new(0.5, -40, 0, 30)
aimbotToggle.MouseButton1Click:Connect(function()
    local currentText = aimbotToggle.Text
    if currentText == "Aimbot On" then
        aimbotToggle.Text = "Aimbot Off"
        aimbotEnabled = false
    else
        aimbotToggle.Text = "Aimbot On"
        aimbotEnabled = true
    end
end)
aimbotToggle.Parent = aimbotSection

-- Aimbot settings
local sensitivitySlider = Instance.new("Slider")
sensitivitySlider.Name = "SensitivitySlider"
sensitivitySlider.Value = 0.5
sensitivitySlider.Size = UDim2.new(0, 200, 0, 20)
sensitivitySlider.Position = UDim2.new(0.5, -100, 0, 60)
sensitivitySlider.Parent = aimbotSection

local sensitivityLabel = Instance.new("TextLabel")
sensitivityLabel.Text = "Sensitivity: " .. sensitivitySlider.Value
sensitivityLabel.Font = Enum.Font.SourceSans
sensitivityLabel.TextSize = 12
sensitivityLabel.BackgroundTransparency = 1
sensitivityLabel.Size = UDim2.new(0, 100, 0, 20)
sensitivityLabel.Position = UDim2.new(0, 50, 0, 60)
sensitivityLabel.Parent = aimbotSection

-- Update sensitivity label when slider changes
sensitivitySlider.ValueChanged:Connect(function(value)
    sensitivityLabel.Text = "Sensitivity: " .. value
    sensitivity = value
end)

-- ESP settings
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

-- ESP toggle
local espToggle = Instance.new("TextButton")
espToggle.Text = "ESP On"
espToggle.Font = Enum.Font.SourceSansBold
espToggle.TextSize = 12
espToggle.BackgroundTransparency = 0
espToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
espToggle.Size = UDim2.new(0, 80, 0, 20)
espToggle.Position = UDim2.new(0.5, -40, 0, 30)
espToggle.MouseButton1Click:Connect(function()
    local currentText = espToggle.Text
    if currentText == "ESP On" then
        espToggle.Text = "ESP Off"
        espEnabled = false
    else
        espToggle.Text = "ESP On"
        espEnabled = true
    end
end)
espToggle.Parent = espSection

-- ESP settings
local boxColorPicker = Instance.new("ColorPicker")
boxColorPicker.Name = "BoxColorPicker"
boxColorPicker.Color = Color3.fromRGB(255, 0, 0)
boxColorPicker.Size = UDim2.new(0, 100, 0, 20)
boxColorPicker.Position = UDim2.new(0.5, -50, 0, 60)
boxColorPicker.Parent = espSection

local boxColorLabel = Instance.new("TextLabel")
boxColorLabel.Text = "Box Color:"
boxColorLabel.Font = Enum.Font.SourceSans
boxColorLabel.TextSize = 12
boxColorLabel.BackgroundTransparency = 1
boxColorLabel.Size = UDim2.new(0, 80, 0, 20)
boxColorLabel.Position = UDim2.new(0, 20, 0, 60)
boxColorLabel.Parent = espSection

-- Global variables
local aimbotEnabled = false
local espEnabled = true
local sensitivity = 0.5

-- Create overlay for ESP
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BorderSizePixel = 0
overlay.Position = UDim2.new(0, 0, 0, 0)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.Visible = false
overlay.Parent = gui

-- Keybind handler
player.CharacterAdded:Connect(function(char)
    -- Create keybind system
    local keys = {}
    mouse.KeyDown:Connect(function(key)
        if key == "RightShift" then
            uiContainer.Visible = true
        elseif key == "V" then
            aimbotEnabled = not aimbotEnabled
            if aimbotEnabled then
                aimbotToggle.Text = "Aimbot Off"
            else
                aimbotToggle.Text = "Aimbot On"
            end
        elseif key == "Escape" then
            uiContainer.Visible = false
        end
    end)
    
    -- Aimbot functionality
    game:GetService("RunService").RenderStepped:Connect(function()
        if aimbotEnabled then
            local closestPlayer = nil
            local closestDistance = math.huge
            
            for _, plr in pairs(player:GetChildren()) do
                if plr:IsA("Humanoid") and plr.Health > 0 then
                    local distance = (plr.RootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = plr
                    end
                end
            end
            
            if closestPlayer then
                local screenPoint, onScreen = camera:WorldToViewportPoint(closestPlayer.RootPart.Position)
                
                if onScreen then
                    mouse.TargetFilter = closestPlayer
                    mouse.Hit = Vector3.new(screenPoint.X, screenPoint.Y, 0)
                    
                    -- Apply sensitivity to aiming
                    local currentMousePos = Vector3.new(mouse.Hit.X, mouse.Hit.Y, 0)
                    local targetPos = Vector3.new(screenPoint.X, screenPoint.Y, 0)
                    
                    local delta = (targetPos - currentMousePos) * sensitivity
                    mouse.Hit = currentMousePos + delta
                end
            end
        end
    end)
    
    -- ESP functionality
    game:GetService("RunService").RenderStepped:Connect(function()
        if espEnabled then
            overlay.Visible = true
            
            for _, plr in pairs(player:GetChildren()) do
                if plr:IsA("Humanoid") and plr.Health > 0 then
                    local screenPoint, onScreen = camera:WorldToViewportPoint(plr.RootPart.Position)
                    
                    if onScreen then
                        -- Draw box around player
                        local box = Instance.new("Frame")
                        box.BackgroundColor3 = boxColorPicker.Color
                        box.BorderSizePixel = 1
                        box.BorderColor3 = Color3.fromRGB(255, 255, 255)
                        box.Position = UDim2.new(0, screenPoint.X - 25, 0, screenPoint.Y - 50)
                        box.Size = UDim2.new(0, 50, 0, 100)
                        box.Parent = overlay
                        
                        -- Draw skeleton lines
                        local head = plr.Head
                        local torso = plr.Torso
                        local leftArm = plr["Left Arm"]
                        local rightArm = plr["Right Arm"]
                        local leftLeg = plr["Left Leg"]
                        local rightLeg = plr["Right Leg"]
                        
                        if head and torso then
                            local headScreen, _ = camera:WorldToViewportPoint(head.Position)
                            local torsoScreen, _ = camera:WorldToViewportPoint(torso.Position)
                            
                            local line = Instance.new("Frame")
                            line.BackgroundColor3 = boxColorPicker.Color
                            line.BorderSizePixel = 0
                            line.Size = UDim2.new(0, 2, 0, 10)
                            line.Position = UDim2.new(0, headScreen.X - 1, 0, headScreen.Y)
                            line.Parent = overlay
                        end
                        
                        -- Draw health bar
                        local healthBar = Instance.new("Frame")
                        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        healthBar.BorderSizePixel = 0
                        healthBar.Size = UDim2.new(0, 50, 0, 10)
                        healthBar.Position = UDim2.new(0, screenPoint.X - 25, 0, screenPoint.Y - 60)
                        healthBar.Parent = overlay
                        
                        -- Health percentage
                        local healthPercentage = plr.Health / plr.MaxHealth
                        healthBar.Size = UDim2.new(0, 50 * healthPercentage, 0, 10)
                        
                        -- Clean up old elements
                        game:GetService("Debris"):AddItem(box, 0.1)
                        game:GetService("Debris"):AddItem(healthBar, 0.1)
                    end
                end
            end
        else
            overlay.Visible = false
        end
    end)
end)

-- Initialize UI
uiContainer.Visible = false
