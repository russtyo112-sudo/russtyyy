-- XenoExecutor (Silent Aim + ESP + Offsets for The Armory)
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local cam        = workspace.CurrentCamera
local lp         = Players.LocalPlayer
local lpGui      = lp:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────
local espEnabled    = false
local aimbotEnabled = false
local smoothness    = 0.3
local fovRadius     = 150
local targetPart    = "Head"
local teamCheck     = false
local espLoop       = nil
local aimbotConnection = nil
local xOffset       = 0  -- New: X offset for silent aim
local yOffset       = 0  -- New: Y offset for silent aim

-- ── ScreenGui ─────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "XenoExec"
sg.ResetOnSpawn   = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent         = lpGui

-- ── ESP box storage ───────────────────────────────────────────
local espData = {}

local function removeESP(plr)
    local d = espData[plr]
    if not d then return end
    for _, v in pairs(d) do
        if typeof(v) == "Instance" then
            pcall(function() v:Destroy() end)
        end
    end
    espData[plr] = nil
end

local function hideESP(plr)
    local d = espData[plr]
    if not d then return end
    if d.box  then d.box.Visible  = false end
    if d.hpBg then d.hpBg.Visible = false end
    if d.lbl  then d.lbl.Visible  = false end
end

local function createESPFor(plr)
    if espData[plr] then return end

    local box = Instance.new("Frame", sg)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false

    local function edge(parent)
        local f = Instance.new("Frame", parent)
        f.BackgroundColor3 = Color3.fromRGB(255,255,255)
        f.BorderSizePixel  = 0
        return f
    end

    local top = edge(box); top.Size = UDim2.new(1,0,0,1); top.Position = UDim2.new(0,0,0,0)
    local bot = edge(box); bot.Size = UDim2.new(1,0,0,1); bot.Position = UDim2.new(0,0,1,-1)
    local lft = edge(box); lft.Size = UDim2.new(0,1,1,0); lft.Position = UDim2.new(0,0,0,0)
    local rgt = edge(box); rgt.Size = UDim2.new(0,1,1,0); rgt.Position = UDim2.new(1,-1,0,0)

    local hpBg = Instance.new("Frame", sg)
    hpBg.BackgroundColor3 = Color3.fromRGB(40,40,40)
    hpBg.BorderSizePixel  = 0
    hpBg.Visible = false

    local hp = Instance.new("Frame", hpBg)
    hp.BackgroundColor3 = Color3.fromRGB(0,220,60)
    hp.BorderSizePixel  = 0
    hp.AnchorPoint      = Vector2.new(0,1)
    hp.Position         = UDim2.new(0,0,1,0)
    hp.Size             = UDim2.new(1,0,1,0)

    local lbl = Instance.new("TextLabel", sg)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = Color3.fromRGB(255,255,255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3       = Color3.fromRGB(0,0,0)
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 11
    lbl.Text                   = plr.DisplayName
    lbl.Visible                = false

    espData[plr] = {box=box, top=top, bot=bot, lft=lft, rgt=rgt, hpBg=hpBg, hp=hp, lbl=lbl}
end

local function getBox(char)
    local mn = Vector2.new(math.huge, math.huge)
    local mx = Vector2.new(-math.huge, -math.huge)
    local hit = false
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            local s, on = cam:WorldToViewportPoint(p.Position)
            if on then
                hit = true
                if s.X < mn.X then mn = Vector2.new(s.X, mn.Y) end
                if s.Y < mn.Y then mn = Vector2.new(mn.X, s.Y) end
                if s.X > mx.X then mx = Vector2.new(s.X, mx.Y) end
                if s.Y > mx.Y then mx = Vector2.new(mx.X, s.Y) end
            end
        end
    end
    if not hit then return nil end
    return mn.X-4, mn.Y-4, mx.X+4, mx.Y+4
end

-- ── ESP update loop ───────────────────────────────────────────
local function runESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local char = plr.Character
            local hum  = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            if char and hum and root and hum.Health > 0 then
                createESPFor(plr)
                local d = espData[plr]
                if d then
                    local x1,y1,x2,y2 = getBox(char)
                    if x1 then
                        local w = x2-x1; local h = y2-y1
                        d.box.Position = UDim2.new(0,x1,0,y1)
                        d.box.Size     = UDim2.new(0,w,0,h)
                        d.box.Visible  = true

                        local pct = hum.Health/hum.MaxHealth
                        d.hpBg.Position = UDim2.new(0,x1-7,0,y1)
                        d.hpBg.Size     = UDim2.new(0,4,0,h)
                        d.hpBg.Visible  = true
                        d.hp.Size       = UDim2.new(1,0,pct,0)

                        d.lbl.Position = UDim2.new(0,x1,0,y1-15)
                        d.lbl.Size     = UDim2.new(0,w,0,14)
                        d.lbl.Visible  = true
                    else
                        hideESP(plr)
                    end
                end
            else
                hideESP(plr)
            end
        end
    end
end

-- ── FOV circle ────────────────────────────────────────────────
local fovFrame = Instance.new("Frame", sg)
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel = 0
fovFrame.Visible = false

local fovCorner = Instance.new("UICorner", fovFrame)
fovCorner.CornerRadius = UDim.new(1, 0)

local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Color     = Color3.fromRGB(120,40,200)
fovStroke.Thickness = 2

local function updateFOV()
    local vp = cam.ViewportSize
    fovFrame.Position = UDim2.new(0, vp.X/2 - fovRadius, 0, vp.Y/2 - fovRadius)
    fovFrame.Size     = UDim2.new(0, fovRadius*2, 0, fovRadius*2)
end

-- ── Silent Aim Logic ─────────────────────────────────────────
local function getClosestPlayer()
    local closest, closestDist = nil, math.huge
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp then
            local skip = teamCheck and (plr.Team == lp.Team)
            if not skip then
                local char = plr.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if char and hum and hum.Health > 0 then
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
        -- Apply X and Y offsets
        screenPos = Vector2.new(screenPos.X + xOffset, screenPos.Y + yOffset)
        local currentPos = Vector2.new(mouse.X, mouse.Y)
        local delta = (screenPos - currentPos) * smoothness
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
end

-- ── Main Panel ────────────────────────────────────────────────
local mainPanel = Instance.new("Frame", sg)
mainPanel.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainPanel.Size     = UDim2.new(0,300,0,400)  -- Slightly taller for new sliders
mainPanel.Position = UDim2.new(0.5,-150,0.5,-200)
mainPanel.Draggable   = true
mainPanel.Active      = true
mainPanel.Visible     = true
mainPanel.BorderSizePixel = 0

local mc = Instance.new("UICorner", mainPanel)
mc.CornerRadius = UDim.new(0,8)

-- title
local titleBar = Instance.new("Frame", mainPanel)
titleBar.BackgroundColor3 = Color3.fromRGB(120,40,200)
titleBar.Size = UDim2.new(1,0,0,32)
titleBar.BorderSizePixel = 0
local tc = Instance.new("UICorner", titleBar); tc.CornerRadius = UDim.new(0,8)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Text = "  Xeno Executor"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 14
titleLbl.TextColor3 = Color3.fromRGB(255,255,255)
titleLbl.BackgroundTransparency = 1
titleLbl.Size = UDim2.new(1,-40,1,0)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- reopen button
local reopenBtn = Instance.new("TextButton", sg)
reopenBtn.Text = "☰"
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 18
reopenBtn.TextColor3 = Color3.fromRGB(255,255,255)
reopenBtn.BackgroundColor3 = Color3.fromRGB(120,40,200)
reopenBtn.Size = UDim2.new(0,36,0,36)
reopenBtn.Position = UDim2.new(1,-46,0,10)
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
local rc = Instance.new("UICorner", reopenBtn); rc.CornerRadius = UDim.new(0,6)
reopenBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = true
    reopenBtn.Visible = false
end)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0,32,1,0)
closeBtn.Position = UDim2.new(1,-32,0,0)
closeBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = false
    reopenBtn.Visible = true
end)

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        local showing = not mainPanel.Visible
        mainPanel.Visible = showing
        reopenBtn.Visible = not showing
    end
end)

-- helper: row label
local function rowLabel(y, txt)
    local l = Instance.new("TextLabel", mainPanel)
    l.Text = txt
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextColor3 = Color3.fromRGB(120,40,200)
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1,-20,0,16)
    l.Position = UDim2.new(0,10,0,y)
    l.TextXAlignment = Enum.TextXAlignment.Left
end

-- helper: toggle button
local function toggleBtn(y, offTxt, onTxt, initOn, onChange)
    local btn = Instance.new("TextButton", mainPanel)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Size = UDim2.new(1,-20,0,28)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BorderSizePixel = 0
    local bc = Instance.new("UICorner",btn); bc.CornerRadius = UDim.new(0,6)

    local on = initOn
    local function refresh()
        btn.Text = on and onTxt or offTxt
        btn.BackgroundColor3 = on and Color3.fromRGB(120,40,200) or Color3.fromRGB(70,70,70)
    end
    refresh()
    btn.MouseButton1Click:Connect(function()
        on = not on
        refresh()
        onChange(on)
    end)
    return btn
end

-- helper: slider
local function makeSlider(y, labelTxt, mn, mx, init, onChange)
    local valRef = {v = init}

    local lbl = Instance.new("TextLabel", mainPanel)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,-20,0,16)
    lbl.Position = UDim2.new(0,10,0,y)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelTxt..": "..tostring(init)

    local track = Instance.new("Frame", mainPanel)
    track.BackgroundColor3 = Color3.fromRGB(50,50,50)
    track.BorderSizePixel = 0
    track.Size = UDim2.new(1,-20,0,8)
    track.Position = UDim2.new(0,10,0,y+18)
    local trc = Instance.new("UICorner",track); trc.CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(120,40,200)
    fill.BorderSizePixel = 0
    local frc = Instance.new("UICorner",fill); frc.CornerRadius = UDim.new(1,0)

    local handle = Instance.new("TextButton", track)
    handle.Text = ""
    handle.BackgroundColor3 = Color3.fromRGB(180,80,255)
    handle.BorderSizePixel = 0
    handle.Size = UDim2.new(0,14,0,14)
    local hrc = Instance.new("UICorner",handle); hrc.CornerRadius = UDim.new(1,0)

    local function setVal(frac)
        frac = math.clamp(frac,0,1)
        local val = math.floor(mn + frac*(mx-mn))
        fill.Size = UDim2.new(frac,0,1,0)
        handle.Position = UDim2.new(frac,0,0.5,-7)
        lbl.Text = labelTxt..": "..tostring(val)
        valRef.v = val
        onChange(val)
    end

    setVal((init-mn)/(mx-mn))

    local dragging = false
    handle.MouseButton1Down:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging then
            local mouse = lp:GetMouse()
            local ap = track.AbsolutePosition.X
            local aw = track.AbsoluteSize.X
            if aw > 0 then
                setVal((mouse.X - ap) / aw)
            end
        end
    end)
end

-- ── Build UI layout ───────────────────────────────────────────
rowLabel(38, "── ESP ──────────────────────────────")
toggleBtn(56, "ESP: OFF", "ESP: ON", false, function(on)
    espEnabled = on
    if on then
        if not espLoop then
            espLoop = RunService.Heartbeat:Connect(runESP)
        end
    else
        if espLoop then espLoop:Disconnect(); espLoop = nil end
        for _, plr in ipairs(Players:GetPlayers()) do
            removeESP(plr)
        end
    end
end)

rowLabel(96, "── AIMBOT ───────────────────────────")

makeSlider(114, "Smoothness", 1, 100, 30, function(v)
    smoothness = v / 100
end)

makeSlider(148, "FOV Radius", 30, 500, fovRadius, function(v)
    fovRadius = v
end)

-- New: X and Y Offset Sliders
makeSlider(182, "X Offset", -100, 100, xOffset, function(v)
    xOffset = v
end)

makeSlider(216, "Y Offset", -100, 100, yOffset, function(v)
    yOffset = v
end)

toggleBtn(250, "Team Check: OFF", "Team Check: ON", false, function(on)
    teamCheck = on
end)

rowLabel(286, "───────────────────────────────────")
local hint = Instance.new("TextLabel", mainPanel)
hint.Text = "Hold V = Silent Aim   RightShift = Menu"
hint.Font = Enum.Font.Gotham
hint.TextSize = 10
hint.TextColor3 = Color3.fromRGB(120,120,120)
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1,-20,0,14)
hint.Position = UDim2.new(0,10,0,302)

-- ── Player events ─────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        removeESP(plr)
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= lp then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            removeESP(plr)
        end)
    end
end
