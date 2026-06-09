-- Fixed Xeno Executor Script
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

-- UI Elements
local title = Instance.new("TextLabel")
title.Text = "Xeno Executor | ESP & Aimbot"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.Parent = uiContainer

-- Aimbot settings
local aimbotSection = Instance.new("Frame")
aimbotSection.Name = "AimbotSection"
aimbotSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aimbotSection.BorderSizePixel = 0
aimbotSection.Position = UDim2.new(0, 0, 0, 30)
aimbotSection.Size = UDim2.new(1, 0, 0, 100)
aimbotSection.Parent = uiContainer

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
espSection.Parent = uiContainer

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

-- Global variables
local aimbotEnabled = false
local espEnabled = true
local sensitivity = 0.5

-- Keybind handler
local function handleKeybinds()
    game:GetService("UserInputService").KeyDown:Connect(function(key)
        if key == "RightShift" then
            uiContainer.Visible = not uiContainer.Visible
        elseif key == "V" then
            aimbotEnabled = not aimbotEnabled
            aimbotToggle.Text = aimbotEnabled and "Aimbot Off" or "Aimbot On"
        elseif key == "Escape" then
            uiContainer.Visible = false
        end
    end)
end

-- Aimbot functionality
local function aimbot()
    game:GetService("RunService").RenderStepped:Connect(function()
        if aimbotEnabled then
            local closestPlayer = nil
            local closestDistance = math.huge
            
            for _, plr in pairs(game.Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (plr.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = plr
                    end
                end
            end
            
            if closestPlayer then
                local target = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
                if target then
                    -- Move camera toward target
                    local direction = (target.Position - camera.CFrame.Position).unit
                    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, target.Position)
                end
            end
        end
    end)
end

-- ESP functionality
local function esp()
    local overlay = Instance.new("Frame")
    overlay.Name = "Overlay"
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BorderSizePixel = 0
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Visible = false
    overlay.Parent = gui
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if espEnabled then
            overlay.Visible = true
            
            for _, plr in pairs(game.Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local screenPoint, onScreen = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                    
                    if onScreen then
                        -- Draw box
                        local box = Instance.new("Frame")
                        box.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        box.BorderSizePixel = 1
                        box.BorderColor3 = Color3.fromRGB(255, 255, 255)
                        box.Position = UDim2.new(0, screenPoint.X - 25, 0, screenPoint.Y - 50)
                        box.Size = UDim2.new(0, 50, 0, 100)
                        box.Parent = overlay
                        
                        -- Add to cleanup
                        game:GetService("Debris"):AddItem(box, 0.1)
                    end
                end
            end
        else
            overlay.Visible = false
        end
    end)
end

-- Initialize UI
handleKeybinds()
aimbot()
esp()
uiContainer.Visible = false
