-- XenoExecutor (Silent Aim for The Armory)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local cam = workspace.CurrentCamera
local lp = Players.LocalPlayer
local lpGui = lp:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────
local aimbotEnabled = false
local fovRadius = 150
local targetPart = "Head"
local teamCheck = false
local smoothness = 0.3  -- Lower = smoother, less detectable
local aimbotConnection = nil

-- ── ScreenGui ─────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "XenoExec"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = lpGui

-- ── FOV Circle ────────────────────────────────────────────────
local fovFrame = Instance.new("Frame", sg)
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel = 0
fovFrame.Visible = false

local fovCorner = Instance.new("UICorner", fovFrame)
fovCorner.CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Color = Color3.fromRGB(120, 40, 200)
fovStroke.Thickness = 2

local function updateFOV()
    local vp = cam.ViewportSize
    fovFrame.Position = UDim2.new(0, vp.X/2 - fovRadius, 0, vp.Y/2 - fovRadius)
    fovFrame.Size = UDim2.new(0, fovRadius*2, 0, fovRadius*2)
end

-- ── Silent Aim Logic ─────────────────────────────────────────
local function getClosestPlayer()
    local closest, closestDist = nil, math.huge
    local mouse = lp:GetMouse()
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local skip = teamCheck and (plr.Team == lp.Team)
            if not skip then
                local char = plr.Character
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local head = char:FindFirstChild(targetPart) or char:FindFirstChild("Head")
                    if head then
                        local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist < fovRadius and dist < closestDist then
                                closestDist = dist
                                closest = head
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function silentAim(target)
    if not target then return end
    local mouse = lp:GetMouse()
    local screenPos, onScreen = cam:WorldToViewportPoint(target.Position)
    if onScreen then
        -- Smoothly move mouse toward target (less detectable)
        local currentPos = Vector2.new(mouse.X, mouse.Y)
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        local delta = (targetPos - currentPos) * smoothness
        mousemoverel(delta.X, delta.Y)
    end
end

local function runAimbot()
    local target = getClosestPlayer()
    if target then
        silentAim(target)
    end
end

-- ── Input Handling ────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.V then
        aimbotEnabled = true
        fovFrame.Visible = true
        if not aimbotConnection then
            aimbotConnection = RunService.RenderStepped:Connect(function()
                if aimbotEnabled then
                    updateFOV()
                    runAimbot()
                end
            end)
        end
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.V then
        aimbotEnabled = false
        fovFrame.Visible = false
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end)

-- ── Main Panel (Minimal UI) ──────────────────────────────────
local mainPanel = Instance.new("Frame", sg)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainPanel.Size = UDim2.new(0, 200, 0, 100)
mainPanel.Position = UDim2.new(0.5, -100, 0.5, -50)
mainPanel.Draggable = true
mainPanel.Active = true
mainPanel.Visible = false
mainPanel.BorderSizePixel = 0

local mc = Instance.new("UICorner", mainPanel)
mc.CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame", mainPanel)
titleBar.BackgroundColor3 = Color3.fromRGB(120, 40, 200)
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BorderSizePixel = 0
local tc = Instance.new("UICorner", titleBar)
tc.CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Text = "  Xeno Silent Aim"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.BackgroundTransparency = 1
titleLbl.Size = UDim2.new(1, -40, 1, 0)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0, 32, 1, 0)
closeBtn.Position = UDim2.new(1, -32, 0, 0)
closeBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = false
end)

-- Toggle menu with RightShift
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        mainPanel.Visible = not mainPanel.Visible
    end
end)

-- ── Player Events ─────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(plr)
    -- Cleanup if needed
end)
