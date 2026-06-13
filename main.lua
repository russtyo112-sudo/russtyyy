-- XenoExecutor (Lock-On Silent Aim + ESP for The Armory)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local cam = workspace.CurrentCamera
local lp = Players.LocalPlayer
local lpGui = lp:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────
local espEnabled       = false
local aimbotEnabled    = false
local smoothness       = 0.3
local fovRadius        = 150
local targetPart       = "Head"
local teamCheck        = false
local stickyAim        = false
local espLoop          = nil
local aimbotConnection = nil
local lockedTarget     = nil
local aimLevel         = "Head"

-- ── ScreenGui ─────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name            = "XenoExec"
sg.ResetOnSpawn    = false
sg.IgnoreGuiInset  = true
sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
sg.Parent          = lpGui

-- ── ESP ───────────────────────────────────────────────────────
local espData = {}

local function removeESP(plr)
    if espData[plr] then
        for _, v in pairs(espData[plr]) do
            if v and v:IsA("Instance") then v:Destroy() end
        end
        espData[plr] = nil
    end
end

local function createESPFor(plr)
    if espData[plr] then return end

    local box = Instance.new("Frame", sg)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false

    local function edge(parent)
        local f = Instance.new("Frame", parent)
        f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        f.BorderSizePixel = 0
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

    espData[plr] = {box=box, hpBg=hpBg, hp=hp, lbl=lbl}
end

local function getBox(char)
    if not char then return nil end
    local mn = Vector2.new(math.huge, math.huge)
    local mx = Vector2.new(-math.huge, -math.huge)
    local hit = false
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            local s, on = cam:WorldToViewportPoint(p.Position)
            if on then
                hit = true
                mn = Vector2.new(math.min(s.X,mn.X), math.min(s.Y,mn.Y))
                mx = Vector2.new(math.max(s.X,mx.X), math.max(s.Y,mx.Y))
            end
        end
    end
    if not hit then return nil end
    return mn.X-4, mn.Y-4, mx.X+4, mx.Y+4
end

local function runESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                createESPFor(plr)
                local d = espData[plr]
                if d then
                    local x1,y1,x2,y2 = getBox(plr.Character)
                    if x1 then
                        local w,h = x2-x1, y2-y1
                        d.box.Position  = UDim2.new(0,x1,0,y1)
                        d.box.Size      = UDim2.new(0,w,0,h)
                        d.box.Visible   = true
                        -- green tint if this is the locked target
                        if lockedTarget and lockedTarget.Parent == plr.Character then
                            d.box.BackgroundColor3    = Color3.fromRGB(0,255,0)
                            d.box.BackgroundTransparency = 0.55
                        else
                            d.box.BackgroundTransparency = 1
                        end
                        d.hpBg.Position = UDim2.new(0,x1-7,0,y1)
                        d.hpBg.Size     = UDim2.new(0,4,0,h)
                        d.hpBg.Visible  = true
                        d.hp.Size       = UDim2.new(1,0,hum.Health/hum.MaxHealth,0)
                        d.lbl.Position  = UDim2.new(0,x1,0,y1-15)
                        d.lbl.Size      = UDim2.new(0,w,0,14)
                        d.lbl.Visible   = true
                    else
                        d.box.Visible  = false
                        d.hpBg.Visible = false
                        d.lbl.Visible  = false
                    end
                end
            else
                removeESP(plr)
            end
        end
    end
end

-- ── FOV Circle ────────────────────────────────────────────────
local fovFrame = Instance.new("Frame", sg)
fovFrame.BackgroundTransparency = 1
fovFrame.BorderSizePixel        = 0
fovFrame.Visible                = true
Instance.new("UICorner", fovFrame).CornerRadius = UDim.new(1,0)
local fovStroke = Instance.new("UIStroke", fovFrame)
fovStroke.Color     = Color3.fromRGB(120,40,200)
fovStroke.Thickness = 2

local function updateFOV()
    local vp = cam.ViewportSize
    fovFrame.Position = UDim2.new(0, vp.X/2 - fovRadius, 0, vp.Y/2 - fovRadius)
    fovFrame.Size     = UDim2.new(0, fovRadius*2, 0, fovRadius*2)
end

-- ── Aimbot ────────────────────────────────────────────────────
local function getClosestPlayer()
    local closest, closestDist = nil, math.huge
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local sameTeam = teamCheck and plr.Team and lp.Team and plr.Team == lp.Team
            if not sameTeam then
                local hum = plr.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local part = plr.Character:FindFirstChild(targetPart)
                           or plr.Character:FindFirstChild("Head")
                    if part then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on then
                            local dist = (Vector2.new(sp.X,sp.Y) - center).Magnitude
                            if dist < fovRadius and dist < closestDist then
                                closestDist = dist
                                closest = part
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function isTargetValid(target)
    if not target or not target.Parent then return false end
    local plr = Players:GetPlayerFromCharacter(target.Parent)
    if not plr or plr == lp then return false end
    local sameTeam = teamCheck and plr.Team and lp.Team and plr.Team == lp.Team
    if sameTeam then return false end
    local hum = target.Parent:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local sp, on = cam:WorldToViewportPoint(target.Position)
    if not on then return false end
    -- sticky aim: only drop lock if target goes completely off screen
    -- no FOV check on locked target so mouse can never escape
    return true
end

local function runAimbot()
    -- sticky: once locked, NEVER switch, NEVER let go
    -- only drops if target dies or leaves
    if stickyAim then
        if lockedTarget and isTargetValid(lockedTarget) then
            -- aim at target position with offset for aim level
            local sp, on = cam:WorldToViewportPoint(lockedTarget.Position)
            if on then
                local yOff = (aimLevel == "Head") and -62 or -4
                local targetScreen = Vector2.new(sp.X, sp.Y + yOff)
                local mouse = lp:GetMouse()
                local cur = Vector2.new(mouse.X, mouse.Y)
                -- snap fully to target every frame — no escape
                local delta = targetScreen - cur
                -- use camera CFrame to aim (works without mousemoverel)
                local offsetPos = lockedTarget.Position
                        + Vector3.new(0, (aimLevel == "Head") and 0.3 or -0.5, 0)
                local goal = CFrame.lookAt(cam.CFrame.Position, offsetPos)
                cam.CFrame = goal
            end
            return
        else
            -- target gone — find new one
            lockedTarget = getClosestPlayer()
        end
        return
    end

    -- non-sticky: normal smooth aim, can switch targets
    if lockedTarget and isTargetValid(lockedTarget) then
        local sp, on = cam:WorldToViewportPoint(lockedTarget.Position)
        if on then
            local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
            local screenV = Vector2.new(sp.X, sp.Y)
            if (screenV - center).Magnitude > fovRadius then
                lockedTarget = nil
                return
            end
            local offsetPos = lockedTarget.Position
                    + Vector3.new(0, (aimLevel == "Head") and 0.3 or -0.5, 0)
            local goal = CFrame.lookAt(cam.CFrame.Position, offsetPos)
            cam.CFrame = cam.CFrame:Lerp(goal, smoothness)
        end
        return
    end

    lockedTarget = getClosestPlayer()
    if lockedTarget then
        local offsetPos = lockedTarget.Position
                + Vector3.new(0, (aimLevel == "Head") and 0.3 or -0.5, 0)
        local goal = CFrame.lookAt(cam.CFrame.Position, offsetPos)
        cam.CFrame = cam.CFrame:Lerp(goal, smoothness)
    end
end

-- ── Input ─────────────────────────────────────────────────────
local reopenBtn  -- forward declare so closeBtn can reference it

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.V then
        aimbotEnabled = true
        lockedTarget  = nil
        cam.CameraType = Enum.CameraType.Scriptable
        if not aimbotConnection then
            aimbotConnection = RunService.RenderStepped:Connect(function()
                if aimbotEnabled then updateFOV(); runAimbot() end
            end)
        end
    end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        mainPanel.Visible = not mainPanel.Visible
        reopenBtn.Visible = not mainPanel.Visible
    end
end)

UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.V then
        aimbotEnabled  = false
        lockedTarget   = nil
        cam.CameraType = Enum.CameraType.Custom
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end
end)

-- ── Main Panel ────────────────────────────────────────────────
local mainPanel = Instance.new("Frame", sg)
mainPanel.BackgroundColor3 = Color3.fromRGB(15,15,15)
mainPanel.Size             = UDim2.new(0,300,0,480)
mainPanel.Position         = UDim2.new(0.5,-150,0.5,-240)
mainPanel.Draggable        = true
mainPanel.Active           = true
mainPanel.Visible          = true
mainPanel.BorderSizePixel  = 0
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0,8)

local titleBar = Instance.new("Frame", mainPanel)
titleBar.BackgroundColor3 = Color3.fromRGB(120,40,200)
titleBar.Size             = UDim2.new(1,0,0,32)
titleBar.BorderSizePixel  = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,8)

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Text           = "  Xeno Executor"
titleLbl.Font           = Enum.Font.GothamBold
titleLbl.TextSize       = 14
titleLbl.TextColor3     = Color3.fromRGB(255,255,255)
titleLbl.BackgroundTransparency = 1
titleLbl.Size           = UDim2.new(1,-40,1,0)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Reopen button (declared before closeBtn so it can be referenced)
reopenBtn = Instance.new("TextButton", sg)
reopenBtn.Text             = "☰"
reopenBtn.Font             = Enum.Font.GothamBold
reopenBtn.TextSize         = 18
reopenBtn.TextColor3       = Color3.fromRGB(255,255,255)
reopenBtn.BackgroundColor3 = Color3.fromRGB(120,40,200)
reopenBtn.Size             = UDim2.new(0,36,0,36)
reopenBtn.Position         = UDim2.new(1,-46,0,10)
reopenBtn.BorderSizePixel  = 0
reopenBtn.Visible          = false
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0,6)
reopenBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = true
    reopenBtn.Visible = false
end)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Text           = "✕"
closeBtn.Font           = Enum.Font.GothamBold
closeBtn.TextSize       = 14
closeBtn.TextColor3     = Color3.fromRGB(255,255,255)
closeBtn.BackgroundTransparency = 1
closeBtn.Size           = UDim2.new(0,32,1,0)
closeBtn.Position       = UDim2.new(1,-32,0,0)
closeBtn.MouseButton1Click:Connect(function()
    mainPanel.Visible = false
    reopenBtn.Visible = true
end)

-- ── UI helpers ────────────────────────────────────────────────
local function rowLabel(y, txt)
    local l = Instance.new("TextLabel", mainPanel)
    l.Text = txt; l.Font = Enum.Font.GothamBold; l.TextSize = 10
    l.TextColor3 = Color3.fromRGB(120,40,200); l.BackgroundTransparency = 1
    l.Size = UDim2.new(1,-20,0,16); l.Position = UDim2.new(0,10,0,y)
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function mkToggle(y, offT, onT, initOn, cb)
    local btn = Instance.new("TextButton", mainPanel)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Size = UDim2.new(1,-20,0,30); btn.Position = UDim2.new(0,10,0,y)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    local on = initOn
    local function ref()
        btn.Text = on and onT or offT
        btn.BackgroundColor3 = on and Color3.fromRGB(120,40,200) or Color3.fromRGB(70,70,70)
    end
    ref()
    btn.MouseButton1Click:Connect(function() on=not on; ref(); cb(on) end)
    return btn
end

local function mkSlider(y, lTxt, mn, mx, init, cb)
    local lbl = Instance.new("TextLabel", mainPanel)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11
    lbl.TextColor3 = Color3.fromRGB(200,200,200); lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,-20,0,16); lbl.Position = UDim2.new(0,10,0,y)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = lTxt..": "..tostring(init)

    local track = Instance.new("Frame", mainPanel)
    track.BackgroundColor3 = Color3.fromRGB(50,50,50); track.BorderSizePixel = 0
    track.Size = UDim2.new(1,-20,0,8); track.Position = UDim2.new(0,10,0,y+18)
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(120,40,200); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local handle = Instance.new("TextButton", track)
    handle.Text = ""; handle.BackgroundColor3 = Color3.fromRGB(180,80,255)
    handle.BorderSizePixel = 0; handle.Size = UDim2.new(0,14,0,14)
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1,0)

    local function setV(frac)
        frac = math.clamp(frac,0,1)
        local v = mn + frac*(mx-mn)
        fill.Size = UDim2.new(frac,0,1,0)
        handle.Position = UDim2.new(frac,0,0.5,-7)
        lbl.Text = lTxt..": "..string.format("%.1f",v)
        cb(v)
    end
    setV((init-mn)/(mx-mn))

    local drag = false
    handle.MouseButton1Down:Connect(function() drag=true end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
    RunService.Heartbeat:Connect(function()
        if drag then
            local m = lp:GetMouse()
            local aw = track.AbsoluteSize.X
            if aw > 0 then setV((m.X - track.AbsolutePosition.X)/aw) end
        end
    end)
end

-- Aim level selector — two side-by-side buttons, active = purple
local function mkAimLevel(y)
    local headBtn = Instance.new("TextButton", mainPanel)
    headBtn.Font = Enum.Font.GothamBold; headBtn.TextSize = 12
    headBtn.TextColor3 = Color3.fromRGB(255,255,255)
    headBtn.Text = "HEAD"
    headBtn.Size = UDim2.new(0.5,-14,0,30)
    headBtn.Position = UDim2.new(0,10,0,y)
    headBtn.BorderSizePixel = 0
    Instance.new("UICorner", headBtn).CornerRadius = UDim.new(0,6)

    local bodyBtn = Instance.new("TextButton", mainPanel)
    bodyBtn.Font = Enum.Font.GothamBold; bodyBtn.TextSize = 12
    bodyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    bodyBtn.Text = "BODY"
    bodyBtn.Size = UDim2.new(0.5,-14,0,30)
    bodyBtn.Position = UDim2.new(0.5,4,0,y)
    bodyBtn.BorderSizePixel = 0
    Instance.new("UICorner", bodyBtn).CornerRadius = UDim.new(0,6)

    local function refresh()
        headBtn.BackgroundColor3 = (aimLevel=="Head")
            and Color3.fromRGB(120,40,200) or Color3.fromRGB(70,70,70)
        bodyBtn.BackgroundColor3 = (aimLevel=="Body")
            and Color3.fromRGB(120,40,200) or Color3.fromRGB(70,70,70)
    end
    refresh()

    headBtn.MouseButton1Click:Connect(function()
        aimLevel = "Head"; targetPart = "Head"; refresh()
    end)
    bodyBtn.MouseButton1Click:Connect(function()
        aimLevel = "Body"; targetPart = "HumanoidRootPart"; refresh()
    end)
end

-- ── Build layout ──────────────────────────────────────────────
-- All y positions spread out with consistent 44px per control row
-- Sections: label(16) + control(30 or 8+18) + 8 gap = 44px per row

rowLabel(38, "── ESP ──────────────────────────────")
mkToggle(56, "ESP: OFF", "ESP: ON", false, function(on)
    espEnabled = on
    if on then
        if not espLoop then espLoop = RunService.Heartbeat:Connect(runESP) end
    else
        if espLoop then espLoop:Disconnect(); espLoop = nil end
        for _, p in ipairs(Players:GetPlayers()) do removeESP(p) end
    end
end)

rowLabel(100, "── AIMBOT ───────────────────────────")
mkSlider(118, "Smoothness", 1, 100, 30, function(v) smoothness = v/100 end)
-- 118 + 16 label + 8 track + 8 gap = 150
mkSlider(152, "FOV Radius", 30, 500, fovRadius, function(v)
    fovRadius = v; updateFOV()
end)

-- 152 + 16 + 8 + 8 = 184
rowLabel(190, "AIM LEVEL")
mkAimLevel(208)

-- 208 + 30 + 10 = 248
mkToggle(250, "Sticky Aim: OFF", "Sticky Aim: ON", false, function(on)
    stickyAim = on
    if not on then
        -- restore camera control when turning sticky off
        if not aimbotEnabled then
            cam.CameraType = Enum.CameraType.Custom
        end
    end
end)

mkToggle(292, "Team Check: OFF", "Team Check: ON", false, function(on)
    teamCheck = on
end)

rowLabel(336, "───────────────────────────────────")
local hint = Instance.new("TextLabel", mainPanel)
hint.Text = "Hold V = Aimbot   RightShift = Open/Close"
hint.Font = Enum.Font.Gotham; hint.TextSize = 10
hint.TextColor3 = Color3.fromRGB(100,100,100); hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1,-20,0,14); hint.Position = UDim2.new(0,10,0,354)

-- ── Player events ─────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(plr)
    removeESP(plr)
    if lockedTarget and lockedTarget.Parent == plr.Character then
        lockedTarget = nil
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(1); removeESP(plr) end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= lp then
        plr.CharacterAdded:Connect(function() task.wait(1); removeESP(plr) end)
    end
end

RunService.RenderStepped:Connect(updateFOV)
