-- Constants and setup
local gui = Instance.new("ScreenGui")
gui.Name = "XenoExecutor"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.IgnoreGuiInset = true

-- Parent to PlayerGui
local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
gui.Parent = playerGui

-- Main panel
local mainPanel = Instance.new("Frame", gui)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainPanel.Size = UDim2.new(0, 300, 0, 300)
mainPanel.Position = UDim2.new(0.5, -150, 0.5, -150)
mainPanel.Draggable = true
mainPanel.Active = true
mainPanel.Visible = true

-- Title bar
local titleBar = Instance.new("Frame", mainPanel)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Size = UDim2.new(1, 0, 0, 30)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Text = "Xeno Executor"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1

-- Toggle button
local toggleBtn = Instance.new("TextButton", mainPanel)
toggleBtn.Text = "Toggle"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
toggleBtn.Size = UDim2.new(0, 50, 0, 30)
toggleBtn.Position = UDim2.new(1, -60, 0, 5)
toggleBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = not mainPanel.Visible
end)

-- Sections
local espSection = Instance.new("Frame", mainPanel)
espSection.Name = "ESP"
espSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
espSection.Size = UDim2.new(1, 0, 0, 100)
espSection.Position = UDim2.new(0, 0, 0, 35)

local aimbotSection = Instance.new("Frame", mainPanel)
aimbotSection.Name = "AIMBOT"
aimbotSection.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
aimbotSection.Size = UDim2.new(1, 0, 0, 100)
aimbotSection.Position = UDim2.new(0, 0, 0, 140)

-- ESP objects storage
local espObjects = {}

-- Aimbot state
local aimbotEnabled = false
local targetPlayer = nil
local smoothness = 0.1
local fovRadius = 100
local targetPart = "Head"
local teamCheck = true

-- RenderStepped handlers
local renderLoop = nil
local espUpdate = nil

-- Initialize ESP
function initESP(player)
    local char = player.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            if typeof(obj) == "Instance" then
                pcall(function() obj:Destroy() end)
            end
        end
        if espObjects[player].billboard then
            pcall(function() espObjects[player].billboard:Destroy() end)
        end
        espObjects[player] = nil
    end

    espObjects[player] = {}

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Adornee = root
    billboardGui.Parent = char
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 20)
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)

    local healthBar = Instance.new("Frame", billboardGui)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.Size = UDim2.new(1, 0, 0, 10)
    healthBar.Position = UDim2.new(0, 0, -0.1, 0)
    healthBar.BorderSizePixel = 0

    local parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm",
                   "RightUpperArm", "LeftUpperLeg", "RightUpperLeg",
                   "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}

    for _, partName in ipairs(parts) do
        local part = char:FindFirstChild(partName)
        local root = char:FindFirstChild("HumanoidRootPart")
        if part and root then
            local a0 = Instance.new("Attachment")
            a0.Parent = root
            local a1 = Instance.new("Attachment")
            a1.Parent = part
            local line = Instance.new("LineHandleAdornment")
            line.Attachment0 = a0
            line.Attachment1 = a1
            line.Length = 0
            line.Width = 2
            line.Color3 = Color3.fromRGB(255, 0, 255)
            line.Parent = workspace
            table.insert(espObjects[player], line)
            table.insert(espObjects[player], a0)
            table.insert(espObjects[player], a1)
        end
    end

    espObjects[player].billboard = billboardGui
    espObjects[player].healthBar = healthBar
end

-- Update ESP
function updateESP()
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local char = player.Character
            if char then
                local rootPart = char:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid and espObjects[player] and espObjects[player].healthBar then
                        espObjects[player].healthBar.Size = UDim2.new(
                            humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                    end
                end
            end
        end
    end
end

-- Player removal cleanup
game.Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then
        for _, obj in ipairs(espObjects[player]) do
            if typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
        if espObjects[player].billboard then
            espObjects[player].billboard:Destroy()
        end
        espObjects[player] = nil
    end
end)

-- Character added
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5) -- wait for character parts to load
        task.spawn(initESP, player)
    end)
end)

-- Input handling
local UIS = game:GetService("UserInputService")
local espActive = false

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainPanel.Visible = not mainPanel.Visible
    end
    if input.KeyCode == Enum.KeyCode.V then
        espActive = true
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr ~= game.Players.LocalPlayer and plr.Character then
                task.spawn(initESP, plr)
            end
        end
        if not espUpdate then
            espUpdate = game:GetService("RunService").Heartbeat:Connect(updateESP)
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        espActive = false
        if espUpdate then
            espUpdate:Disconnect()
            espUpdate = nil
        end
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if espObjects[plr] then
                for _, obj in ipairs(espObjects[plr]) do
                    if typeof(obj) == "Instance" then
                        pcall(function() obj:Destroy() end)
                    end
                end
                if espObjects[plr].billboard then
                    pcall(function() espObjects[plr].billboard:Destroy() end)
                end
                espObjects[plr] = nil
            end
        end
    end
end)

-- Setup aimbot loop
function setupAimbot()
    if aimbotEnabled then return end
    aimbotEnabled = true

    renderLoop = game:GetService("RunService").RenderStepped:Connect(function()
        local screenCenter = Vector2.new(
            workspace.CurrentCamera.ViewportSize.X / 2,
            workspace.CurrentCamera.ViewportSize.Y / 2)
        local minDistance = math.huge
        targetPlayer = nil

        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                local eligible = true
                if teamCheck then
                    if player.Team == game.Players.LocalPlayer.Team then
                        eligible = false
                    end
                end
                if eligible then
                    local char = player.Character
                    if char then
                        local head = char:FindFirstChild("Head")
                        if head then
                            local headPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                            if onScreen then
                                local screenPos = Vector2.new(headPos.X, headPos.Y)
                                local dist = (screenPos - screenCenter).Magnitude
                                if dist < minDistance then
                                    minDistance = dist
                                    targetPlayer = player
                                end
                            end
                        end
                    end
                end
            end
        end

        if targetPlayer and targetPlayer.Character then
            local targetChar = targetPlayer.Character
            local part = targetChar:FindFirstChild(targetPart)
            if part then
                local targetPos = part.Position
                local targetScreenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(targetPos)
                if onScreen then
                    local targetCFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, targetPos)
                        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                        workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(targetCFrame, smoothness)
                end
            end
        end
    end)
end

-- Cleanup aimbot
function cleanupAimbot()
    if not aimbotEnabled then return end
    aimbotEnabled = false
    if renderLoop then
        renderLoop:Disconnect()
        renderLoop = nil
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- Build GUI
function setupGUI()
    local toggleESP = Instance.new("TextButton", espSection)
    toggleESP.Text = "Toggle ESP"
    toggleESP.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleESP.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
    toggleESP.Size = UDim2.new(1, 0, 0, 30)
    toggleESP.Position = UDim2.new(0, 0, 0, 0)
    local espEnabled = false
    toggleESP.Text = "ESP: OFF"
    toggleESP.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

    toggleESP.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        if espEnabled then
            toggleESP.Text = "ESP: ON"
            toggleESP.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
            -- init ESP for all current players
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr ~= game.Players.LocalPlayer then
                    if plr.Character then
                        task.spawn(initESP, plr)
                    end
                end
            end
            -- ESP starts OFF, toggled by button
        else
            toggleESP.Text = "ESP: OFF"
            toggleESP.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            if espUpdate then
                espUpdate:Disconnect()
                espUpdate = nil
            end
            -- destroy all ESP objects
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if espObjects[plr] then
                    for _, obj in ipairs(espObjects[plr]) do
                        if typeof(obj) == "Instance" then
                            obj:Destroy()
                        end
                    end
                    if espObjects[plr].billboard then
                        espObjects[plr].billboard:Destroy()
                    end
                    espObjects[plr] = nil
                end
            end
        end
    end)

    local smoothnessSlider = Instance.new("Frame", aimbotSection)
    smoothnessSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    smoothnessSlider.Size = UDim2.new(1, 0, 0, 30)
    smoothnessSlider.Position = UDim2.new(0, 0, 0, 0)

    local smoothnessLabel = Instance.new("TextLabel", smoothnessSlider)
    smoothnessLabel.Text = "Smoothness:"
    smoothnessLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    smoothnessLabel.Size = UDim2.new(0, 80, 1, 0)
    smoothnessLabel.BackgroundTransparency = 1

    local smoothnessValue = Instance.new("TextLabel", smoothnessSlider)
    smoothnessValue.Text = tostring(smoothness)
    smoothnessValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    smoothnessValue.Size = UDim2.new(0, 40, 1, 0)
    smoothnessValue.Position = UDim2.new(1, -45, 0, 0)
    smoothnessValue.BackgroundTransparency = 1

    local smoothnessHandle = Instance.new("TextButton", smoothnessSlider)
    smoothnessHandle.Text = ""
    smoothnessHandle.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
    smoothnessHandle.Size = UDim2.new(0, 20, 1, 0)
    smoothnessHandle.Position = UDim2.new(0, 85, 0, 0)
    smoothnessHandle.MouseButton1Down:Connect(function()
        local mouse = game.Players.LocalPlayer:GetMouse()
        local startPos = mouse.X
        local startVal = smoothness
        local connection
        connection = mouse.Move:Connect(function()
            local delta = (mouse.X - startPos) / 100
            smoothness = math.clamp(startVal + delta, 0.01, 1.0)
            smoothnessValue.Text = string.format("%.2f", smoothness)
        end)
        mouse.Button1Up:Connect(function()
            connection:Disconnect()
        end)
    end)

    local partSelector = Instance.new("Frame", aimbotSection)
    partSelector.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    partSelector.Size = UDim2.new(1, 0, 0, 30)
    partSelector.Position = UDim2.new(0, 0, 0, 35)

    local partLabel = Instance.new("TextLabel", partSelector)
    partLabel.Text = "Target Part:"
    partLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    partLabel.Size = UDim2.new(0, 80, 1, 0)
    partLabel.BackgroundTransparency = 1

    local partDropdown = Instance.new("TextButton", partSelector)
    partDropdown.Text = targetPart
    partDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    partDropdown.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
    partDropdown.Size = UDim2.new(0, 80, 1, 0)
    partDropdown.Position = UDim2.new(1, -85, 0, 0)
    partDropdown.MouseButton1Click:Connect(function()
        local options = {"Head", "HumanoidRootPart"}
        local dropdown = Instance.new("Frame")
        dropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        dropdown.Size = UDim2.new(0, 100, 0, #options * 25)
        dropdown.Position = UDim2.new(0, 0, 0, 30)
        dropdown.ZIndex = 10
        for i, option in ipairs(options) do
            local btn = Instance.new("TextButton")
            btn.Text = option
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.Position = UDim2.new(0, 0, 0, (i - 1) * 25)
            btn.ZIndex = 10
            btn.MouseButton1Click:Connect(function()
                targetPart = option
                partDropdown.Text = option
                dropdown:Destroy()
            end)
            btn.Parent = dropdown
        end
        dropdown.Parent = partSelector
    end)

    local teamCheckToggle = Instance.new("Frame", aimbotSection)
    teamCheckToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    teamCheckToggle.Size = UDim2.new(1, 0, 0, 30)
    teamCheckToggle.Position = UDim2.new(0, 0, 0, 70)

    local teamCheckLabel = Instance.new("TextLabel", teamCheckToggle)
    teamCheckLabel.Text = "Team Check:"
    teamCheckLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamCheckLabel.Size = UDim2.new(0, 80, 1, 0)
    teamCheckLabel.BackgroundTransparency = 1

    local teamCheckValue = Instance.new("TextLabel", teamCheckToggle)
    teamCheckValue.Text = tostring(teamCheck)
    teamCheckValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    teamCheckValue.Size = UDim2.new(0, 40, 1, 0)
    teamCheckValue.Position = UDim2.new(1, -45, 0, 0)
    teamCheckValue.BackgroundTransparency = 1

    local teamCheckHandle = Instance.new("TextButton", teamCheckToggle)
    teamCheckHandle.Text = ""
    teamCheckHandle.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
    teamCheckHandle.Size = UDim2.new(0, 20, 1, 0)
    teamCheckHandle.Position = UDim2.new(0, 85, 0, 0)
    teamCheckHandle.MouseButton1Click:Connect(function()
        teamCheck = not teamCheck
        teamCheckValue.Text = tostring(teamCheck)
    end)

    local aimbotBtn = Instance.new("TextButton", aimbotSection)
    aimbotBtn.Text = "AIMBOT: OFF"
    aimbotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimbotBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    aimbotBtn.Size = UDim2.new(1, 0, 0, 30)
    aimbotBtn.Position = UDim2.new(0, 0, 0, 105)
    aimbotBtn.MouseButton1Click:Connect(function()
        if aimbotEnabled then
            cleanupAimbot()
            aimbotBtn.Text = "AIMBOT: OFF"
            aimbotBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        else
            setupAimbot()
            aimbotBtn.Text = "AIMBOT: ON"
            aimbotBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
        end
    end)
end

-- Run
setupGUI()

for _, plr in ipairs(game.Players:GetPlayers()) do
    if plr ~= game.Players.LocalPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            task.spawn(initESP, plr)
        end)
    end
end

espUpdate = game:GetService("RunService").Heartbeat:Connect(updateESP)
