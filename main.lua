-- XenoExecutor Script
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local cam           = workspace.CurrentCamera

local localPlayer   = Players.LocalPlayer
local playerGui     = localPlayer:WaitForChild("PlayerGui")

-- ── ScreenGui ─────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name          = "XenoExecutor"
gui.ResetOnSpawn  = false
gui.Enabled       = true
gui.IgnoreGuiInset = true
gui.Parent        = playerGui

-- ── State ─────────────────────────────────────────────────────
local espEnabled    = false
local aimbotEnabled = false
local smoothness    = 0.15
local fovRadius     = 150       -- pixels, adjustable via slider
local targetPart    = "Head"
local teamCheck     = true
local renderLoop    = nil
local espLoop       = nil

-- ── ESP storage: per-player 2D box frames ─────────────────────
-- Each entry: { box=Frame, hpBg=Frame, hp=Frame, label=TextLabel }
local espData = {}

-- ── Wall check ────────────────────────────────────────────────
local function canSee(targetPos)
    local origin = cam.CFrame.Position
    local direction = (targetPos - origin)
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.FilterDescendantsInstances = {localPlayer.Character or workspace}
    local result = workspace:Raycast(origin, direction, ray)
    if result then
        -- hit something before reaching target = blocked
        local hitDist   = result.Distance
        local totalDist = direction.Magnitude
        return hitDist >= totalDist * 0.95
    end
    return true
end

-- ── 2D box helper ─────────────────────────────────────────────
-- Returns screen-space bounding box of a character
local function getCharBox(char)
    local parts = {"Head","HumanoidRootPart","UpperTorso","LowerTorso",
                   "Torso","LeftUpperArm","RightUpperArm",
                   "LeftUpperLeg","RightUpperLeg",
                   "LeftLowerLeg","RightLowerLeg",
                   "Left Arm","Right Arm","Left Leg","Right Leg"}
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local anyOnScreen = false
    for _, name in ipairs(parts) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            local screen, onScreen = cam:WorldToViewportPoint(p.Position)
            if onScreen then
                anyOnScreen = true
                if screen.X < minX then minX = screen.X end
                if screen.Y < minY then minY = screen.Y end
                if screen.X > maxX then maxX = screen.X end
                if screen.Y > maxY then maxY = screen.Y end
            end
        end
    end
    if not anyOnScreen then return nil end
    -- pad slightly
    local pad = 6
    return minX-pad, minY-pad, maxX+pad, maxY+pad
end

-- ── Create ESP UI for a player ────────────────────────────────
local function createESP(plr)
    if espData[plr] then return end -- already exists

    -- outer box frame (white outline, transparent fill)
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.ZIndex = 5

    -- top edge
    local top = Instance.new("Frame", box)
    top.BackgroundColor3 = Color3.fromRGB(255,255,255)
    top.BorderSizePixel = 0
    top.Size = UDim2.new(1,0,0,1)
    top.Position = UDim2.new(0,0,0,0)
    top.ZIndex = 5

    -- bottom edge
    local bot = Instance.new("Frame", box)
    bot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    bot.BorderSizePixel = 0
    bot.Size = UDim2.new(1,0,0,1)
    bot.Position = UDim2.new(0,0,1,-1)
    bot.ZIndex = 5

    -- left edge
    local lft = Instance.new("Frame", box)
    lft.BackgroundColor3 = Color3.fromRGB(255,255,255)
    lft.BorderSizePixel = 0
    lft.Size = UDim2.new(0,1,1,0)
    lft.Position = UDim2.new(0,0,0,0)
    lft.ZIndex = 5

    -- right edge
    local rgt = Instance.new("Frame", box)
    rgt.BackgroundColor3 = Color3.fromRGB(255,255,255)
    rgt.BorderSizePixel = 0
    rgt.Size = UDim2.new(0,1,1,0)
    rgt.Position = UDim2.new(1,-1,0,0)
    rgt.ZIndex = 5

    box.Parent = gui

    -- vertical health bar (left side, 4px wide)
    local hpBg = Instance.new("Frame")
    hpBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    hpBg.BorderSizePixel = 0
    hpBg.Size = UDim2.new(0,4,0,1)   -- height set per frame
    hpBg.ZIndex = 5
    hpBg.Parent = gui

    local hp = Instance.new("Frame", hpBg)
    hp.BackgroundColor3 = Color3.fromRGB(0,220,60)
    hp.BorderSizePixel = 0
    hp.Size = UDim2.new(1,0,1,0)
    hp.AnchorPoint = Vector2.new(0,1)
    hp.Position = UDim2.new(0,0,1,0)
    hp.ZIndex = 5

    -- name label above box
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Text = plr.DisplayName
    lbl.ZIndex = 5
    lbl.Parent = gui

    espData[plr] = {box=box, hpBg=hpBg, hp=hp, lbl=lbl}
end

local function removeESP(plr)
    local d = espData[plr]
    if d then
        pcall(function() d.box:Destroy() end)
        pcall(function() d.hpBg:Destroy() end)
        pcall(function() d.lbl:Destroy() end)
        espData[plr] = nil
    end
end

local function hideESP(plr)
    local d = espData[plr]
    if d then
        d.box.Visible = false
        d.hpBg.Visible = false
        d.lbl.Visible = false
    end
end

-- ── Update ESP each frame ─────────────────────────────────────
local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == localPlayer then continue end

        local char = plr.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if not char or not hum or not root or hum.Health <= 0 then
            hideESP(plr)
        else
            -- wall check
            if not canSee(root.Position) then
                hideESP(plr)
            else
                createESP(plr)
                local d = espData[plr]
                if not d then continue end

                local x1,y1,x2,y2 = getCharBox(char)
                if not x1 then
                    hideESP(plr)
                    continue
                end

                local w = x2-x1
                local h = y2-y1

                -- position box
                d.box.Position = UDim2.new(0,x1,0,y1)
                d.box.Size = UDim2.new(0,w,0,h)
                d.box.Visible = true

                -- health bar left of box, same height
                local hpPct = hum.Health / hum.MaxHealth
                d.hpBg.Position = UDim2.new(0,x1-6,0,y1)
                d.hpBg.Size = UDim2.new(0,4,0,h)
                d.hpBg.Visible = true
                d.hp.Size = UDim2.new(1,0,hpPct,0)

                -- label above box
                d.lbl.Position = UDim2.new(0,x1,0,y1-14)
                d.lbl.Size = UDim2.new(0,w,0,14)
                d.lbl.Visible = true
            end
        end
    end
end

-- ── FOV circle ────────────────────────────────────────────────
local fovCircle = Instance.new("Frame")
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.ZIndex = 10
fovCircle.Visible = false
fovCircle.Parent = gui

-- draw circle using a UIStroke on a circular frame
local fovCorner = Instance.new("UICorner", fovCircle)
fovCorner.CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Color = Color3.fromRGB(120, 40, 200)
fovStroke.Thickness = 2

local function updateFOVCircle()
    local vp = cam.ViewportSize
    local cx = vp.X / 2
    local cy = vp.Y / 2
    local r  = fovRadius
    fovCircle.Position = UDim2.new(0, cx-r, 0, cy-r)
    fovCircle.Size = UDim2.new(0, r*2, 0, r*2)
end

-- ── Aimbot ────────────────────────────────────────────────────
local function setupAimbot()
    if aimbotEnabled then return end
    aimbotEnabled = true
    fovCircle.Visible = true
    updateFOVCircle()

    renderLoop = RunService.RenderStepped:Connect(function()
        updateFOVCircle()
        local vp = cam.ViewportSize
        local screenCenter = Vector2.new(vp.X/2, vp.Y/2)
        local minDist = math.huge
        local target  = nil

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == localPlayer then continue end
            if teamCheck and plr.Team == localPlayer.Team then continue end

            local char = plr.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            if not char or not hum or hum.Health <= 0 then continue end

            local head = char:FindFirstChild("Head")
            if not head then continue end

            local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
            if not onScreen then continue end

            local sv = Vector2.new(screenPos.X, screenPos.Y)
            local dist = (sv - screenCenter).Magnitude
            if dist < fovRadius and dist < minDist then
                minDist = dist
                target  = plr
            end
        end

        if target and target.Character then
            local part = target.Character:FindFirstChild(targetPart)
            if part then
                local _, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local cf = CFrame.lookAt(cam.CFrame.Position, part.Position)
                    cam.CameraType = Enum.CameraType.Scriptable
                    cam.CFrame = cam.CFrame:Lerp(cf, smoothness)
                end
            end
        end
    end)
end

local function cleanupAimbot()
    if not aimbotEnabled then return end
    aimbotEnabled = false
    fovCircle.Visible = false
    if renderLoop then
        renderLoop:Disconnect()
        renderLoop = nil
    end
    cam.CameraType = Enum.CameraType.Custom
end

-- ── Input ─────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainPanel.Visible = not mainPanel.Visible
    end
    if input.KeyCode == Enum.KeyCode.V then
        setupAimbot()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.V then
        cleanupAimbot()
    end
end)

-- ── Main Panel UI ─────────────────────────────────────────────
local mainPanel = Instance.new("Frame", gui)
mainPanel.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainPanel.Size = UDim2.new(0,300,0,380)
mainPanel.Position = UDim2.new(0.5,-150,0.5,-190)
mainPanel.Draggable = true
mainPanel.Active = true
mainPanel.Visible = true
mainPanel.ZIndex = 2

local corner = Instance.new("UICorner", mainPanel)
corner.CornerRadius = UDim.new(0,8)

local titleBar = Instance.new("Frame", mainPanel)
titleBar.BackgroundColor3 = Color3.fromRGB(120,40,200)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 3

local tcorner = Instance.new("UICorner", titleBar)
tcorner.CornerRadius = UDim.new(0,8)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Text = "Xeno Executor"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.Size = UDim2.new(1,0,1,0)
titleLabel.BackgroundTransparency = 1
titleLabel.ZIndex = 3

-- close button
local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0,30,1,0)
closeBtn.Position = UDim2.new(1,-30,0,0)
closeBtn.ZIndex = 4
closeBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = false
end)

-- ── Section header helper ─────────────────────────────────────
local function sectionLabel(parent, text, yPos)
    local f = Instance.new("TextLabel", parent)
    f.Text = text
    f.Font = Enum.Font.GothamBold
    f.TextSize = 11
    f.TextColor3 = Color3.fromRGB(120,40,200)
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1,-20,0,18)
    f.Position = UDim2.new(0,10,0,yPos)
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.ZIndex = 3
    return f
end

-- ── Button helper ─────────────────────────────────────────────
local function makeBtn(parent, text, yPos, onClick)
    local btn = Instance.new("TextButton", parent)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn.Size = UDim2.new(1,-20,0,28)
    btn.Position = UDim2.new(0,10,0,yPos)
    btn.BorderSizePixel = 0
    btn.ZIndex = 3
    local bc = Instance.new("UICorner", btn)
    bc.CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- ── Slider helper ─────────────────────────────────────────────
local function makeSlider(parent, labelText, yPos, minVal, maxVal, initVal, onChange)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Text = labelText .. ": " .. tostring(initVal)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,-20,0,16)
    lbl.Position = UDim2.new(0,10,0,yPos)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3

    local track = Instance.new("Frame", parent)
    track.BackgroundColor3 = Color3.fromRGB(50,50,50)
    track.Size = UDim2.new(1,-20,0,8)
    track.Position = UDim2.new(0,10,0,yPos+18)
    track.BorderSizePixel = 0
    track.ZIndex = 3
    local tc = Instance.new("UICorner", track)
    tc.CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(120,40,200)
    fill.Size = UDim2.new((initVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BorderSizePixel = 0
    fill.ZIndex = 3
    local fc = Instance.new("UICorner", fill)
    fc.CornerRadius = UDim.new(1,0)

    local handle = Instance.new("TextButton", track)
    handle.Text = ""
    handle.BackgroundColor3 = Color3.fromRGB(160,60,255)
    handle.Size = UDim2.new(0,14,0,14)
    handle.Position = UDim2.new((initVal-minVal)/(maxVal-minVal),0,0.5,-7)
    handle.BorderSizePixel = 0
    handle.ZIndex = 4
    local hc = Instance.new("UICorner", handle)
    hc.CornerRadius = UDim.new(1,0)

    local dragging = false
    handle.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mouse = localPlayer:GetMouse()
            local trackPos = track.AbsolutePosition.X
            local trackW   = track.AbsoluteSize.X
            local rel = math.clamp((mouse.X - trackPos) / trackW, 0, 1)
            local val = math.floor(minVal + rel * (maxVal - minVal))
            fill.Size = UDim2.new(rel,0,1,0)
            handle.Position = UDim2.new(rel,0,0.5,-7)
            lbl.Text = labelText .. ": " .. tostring(val)
            onChange(val)
        end
    end)
end

-- ── Build UI ──────────────────────────────────────────────────
sectionLabel(mainPanel, "── ESP ──", 38)

local espBtn = makeBtn(mainPanel, "ESP: OFF", 58, function() end)
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        espBtn.Text = "ESP: ON"
        espBtn.BackgroundColor3 = Color3.fromRGB(120,40,200)
        if not espLoop then
            espLoop = RunService.Heartbeat:Connect(updateESP)
        end
    else
        espBtn.Text = "ESP: OFF"
        espBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
        if espLoop then espLoop:Disconnect(); espLoop = nil end
        for _, plr in ipairs(Players:GetPlayers()) do
            removeESP(plr)
        end
    end
end)

sectionLabel(mainPanel, "── AIMBOT ──", 100)

makeSlider(mainPanel, "Smoothness", 120, 1, 20, 3, function(v)
    smoothness = v / 100
end)

makeSlider(mainPanel, "FOV Radius", 150, 50, 400, fovRadius, function(v)
    fovRadius = v
end)

local teamBtn = makeBtn(mainPanel, "Team Check: ON", 190, function() end)
teamBtn.BackgroundColor3 = Color3.fromRGB(120,40,200)
teamBtn.MouseButton1Click:Connect(function()
    teamCheck = not teamCheck
    teamBtn.Text = "Team Check: " .. (teamCheck and "ON" or "OFF")
    teamBtn.BackgroundColor3 = teamCheck and Color3.fromRGB(120,40,200) or Color3.fromRGB(80,80,80)
end)

local partBtn = makeBtn(mainPanel, "Target: Head", 228, function() end)
partBtn.BackgroundColor3 = Color3.fromRGB(120,40,200)
partBtn.MouseButton1Click:Connect(function()
    targetPart = targetPart == "Head" and "HumanoidRootPart" or "Head"
    partBtn.Text = "Target: " .. targetPart
end)

sectionLabel(mainPanel, "Hold V = Aimbot  ·  RightShift = Menu", 268)

-- ── Player cleanup ────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then
            createESP(plr)
        end
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= localPlayer then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            if espEnabled then createESP(plr) end
        end)
    end
end
