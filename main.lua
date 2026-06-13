-- XenoExecutor — FRONTLINES edition (FIXED FOR CUSTOM MODELS)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local cam = workspace.CurrentCamera
local lp = Players.LocalPlayer
local lpGui = lp:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────
local espEnabled = false
local aimbotEnabled = false
local smoothness = 0.3
local fovRadius = 150
local targetPart = "Head"
local teamCheck = false
local stickyAim = false
local espLoop = nil
local aimbotConnection = nil
local lockedTarget = nil
local aimLevel = "Head"

-- ── ScreenGui ─────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name = "XenoExec"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = lpGui

-- ── Frontlines Custom Model Detection ────────────────────────
-- Finds ALL player models in Workspace (e.g., Workspace.Live, Workspace.Characters)
local function findPlayerModels()
    local models = {}
    local function scan(obj)
        if obj:IsA("Model") then
            -- Check if this model has a Humanoid (likely a player)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum then
                -- Try to match to a player by name
                for _, plr in ipairs(Players:GetPlayers()) do
                    if obj.Name:find(plr.Name) or obj.Name:find(plr.DisplayName) then
                        models[plr] = obj
                        break
                    end
                end
                -- If no name match, check if it's the local player's model
                if not models[lp] and hum == lp.Character and lp.Character then
                    models[lp] = lp.Character
                end
            end
        end
        -- Recursively scan children
        for _, child in ipairs(obj:GetChildren()) do
            scan(child)
        end
    end
    -- Start scanning from Workspace
    scan(workspace)
    return models
end

-- Gets all BaseParts in a model (recursively)
local function getAllParts(model)
    local parts = {}
    local function scan(obj)
        if obj:IsA("BasePart") then
            parts[#parts + 1] = obj
        end
        for _, child in ipairs(obj:GetChildren()) do
            scan(child)
        end
    end
    scan(model)
    return parts
end

-- Finds Humanoid in a model (recursively)
local function findHumanoid(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then return hum end
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("Humanoid") then
            return child
        end
    end
    return nil
end

-- Finds Head in a model (recursively)
local function findHead(model)
    local head = model:FindFirstChild("Head", true)
    if head and head:IsA("BasePart") then return head end
    -- Fallback: HumanoidRootPart or UpperTorso
    local root = model:FindFirstChild("HumanoidRootPart", true)
    if root and root:IsA("BasePart") then return root end
    local torso = model:FindFirstChild("UpperTorso", true)
    if torso and torso:IsA("BasePart") then return torso end
    return nil
end

-- Finds HumanoidRootPart in a model (recursively)
local function findRootPart(model)
    local root = model:FindFirstChild("HumanoidRootPart", true)
    if root and root:IsA("BasePart") then return root end
    return nil
end

-- Checks if a player is alive (works with custom models)
local function isAlive(plr)
    local playerModels = findPlayerModels()
    local model = playerModels[plr] or plr.Character
    if not model then return false end
    local hum = findHumanoid(model)
    if not hum then return false end
    if hum.Health <= 0 then return false end
    local root = findRootPart(model)
    if not root then return false end
    return true
end

-- Checks if two players are on the same team
local function sameTeam(a, b)
    if a.Team and b.Team and a.Team == b.Team then return true end
    if a.TeamColor and b.TeamColor and a.TeamColor == b.TeamColor then return true end
    return false
end

-- ── ESP ───────────────────────────────────────────────────────
local espData = {}

local function removeESP(plr)
    if espData[plr] then
        for _, v in pairs(espData[plr]) do
            if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
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

    local top = edge(box)
    top.Size = UDim2.new(1, 0, 0, 1)
    top.Position = UDim2.new(0, 0, 0, 0)

    local bot = edge(box)
    bot.Size = UDim2.new(1, 0, 0, 1)
    bot.Position = UDim2.new(0, 0, 1, -1)

    local lft = edge(box)
    lft.Size = UDim2.new(0, 1, 1, 0)
    lft.Position = UDim2.new(0, 0, 0, 0)

    local rgt = edge(box)
    rgt.Size = UDim2.new(0, 1, 1, 0)
    rgt.Position = UDim2.new(1, -1, 0, 0)

    local hpBg = Instance.new("Frame", sg)
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hpBg.BorderSizePixel = 0
    hpBg.Visible = false

    local hp = Instance.new("Frame", hpBg)
    hp.BackgroundColor3 = Color3.fromRGB(0, 220, 60)
    hp.BorderSizePixel = 0
    hp.AnchorPoint = Vector2.new(0, 1)
    hp.Position = UDim2.new(0, 0, 1, 0)
    hp.Size = UDim2.new(1, 0, 1, 0)

    local lbl = Instance.new("TextLabel", sg)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.Text = plr.DisplayName
    lbl.Visible = false

    espData[plr] = {box = box, hpBg = hpBg, hp = hp, lbl = lbl}
end

-- Gets bounding box for ANY model (not just Character)
local function getBox(model)
    local parts = getAllParts(model)
    if #parts == 0 then return nil end
    local mnX, mnY = math.huge, math.huge
    local mxX, mxY = -math.huge, -math.huge
    local hit = false
    for _, p in ipairs(parts) do
        local s, on = cam:WorldToViewportPoint(p.Position)
        if on then
            hit = true
            mnX = math.min(mnX, s.X)
            mnY = math.min(mnY, s.Y)
            mxX = math.max(mxX, s.X)
            mxY = math.max(mxY, s.Y)
        end
    end
    if not hit then return nil end
    return mnX - 4, mnY - 4, mxX + 4, mxY + 4
end

-- Updated ESP loop to use custom model detection
local function runESP()
    local playerModels = findPlayerModels()
    for plr, model in pairs(playerModels) do
        if plr ~= lp and isAlive(plr) then
            createESPFor(plr)
            local d = espData[plr]
            if d then
                local x1, y1, x2, y2 = getBox(model)
                if x1 then
                    local w, h = x2 - x1, y2 - y1
                    d.box.Position = UDim2.new(0, x1, 0, y1)
                    d.box.Size = UDim2.new(0, w, 0, h)
                    d.box.Visible = true
                    if lockedTarget and lockedTarget.Parent == model then
                        d.box.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        d.box.BackgroundTransparency = 0.55
                    else
                        d.box.BackgroundTransparency = 1
                    end
                    local hum = findHumanoid(model)
                    if hum then
                        local pct = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 1
                        d.hpBg.Position = UDim2.new(0, x1 - 7, 0, y1)
                        d.hpBg.Size = UDim2.new(0, 4, 0, h)
                        d.hpBg.Visible = true
                        d.hp.Size = UDim2.new(1, 0, pct, 0)
                    end
                    d.lbl.Position = UDim2.new(0, x1, 0, y1 - 15)
                    d.lbl.Size = UDim2.new(0, w, 0, 14)
                    d.lbl.Visible = true
                else
                    d.box.Visible = false
                    d.hpBg.Visible = false
                    d.lbl.Visible = false
                end
            end
        else
            removeESP(plr)
        end
    end
end

-- ── FOV Circle ────────────────────────────────────────────────
local fovFrame
