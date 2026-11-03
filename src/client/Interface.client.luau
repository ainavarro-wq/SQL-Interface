-- Presentation only: money, cooking, and purchases are all decided by the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("TycoonRemotes")

local colors = {
    ink = Color3.fromRGB(53, 54, 47),
    muted = Color3.fromRGB(109, 111, 96),
    paper = Color3.fromRGB(255, 251, 228),
    white = Color3.fromRGB(255, 255, 250),
    yellow = Color3.fromRGB(255, 214, 78),
    teal = Color3.fromRGB(25, 129, 135),
    green = Color3.fromRGB(48, 135, 83),
    red = Color3.fromRGB(186, 70, 52),
    border = Color3.fromRGB(224, 215, 170),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BurgerTycoonHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function create(className, properties, parent)
    local item = Instance.new(className)
    for key, value in pairs(properties) do
        item[key] = value
    end
    item.Parent = parent
    return item
end

local function round(item, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 14) }, item)
end

local function outline(item, color)
    create("UIStroke", { Color = color or colors.border, Thickness = 1.5 }, item)
end

local function panel(name, parent)
    local item = create("Frame", {
        Name = name,
        BackgroundColor3 = colors.paper,
        BorderSizePixel = 0,
    }, parent or gui)
    round(item)
    outline(item)
    return item
end

local function text(parent, content, size, color, bold)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Text = content,
        TextSize = size,
        TextColor3 = color or colors.ink,
        Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        BorderSizePixel = 0,
    }, parent)
end

local function button(parent, title)
    local item = create("TextButton", {
        Text = title,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextColor3 = colors.white,
        BackgroundColor3 = colors.teal,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Selectable = true,
    }, parent)
    round(item, 10)
    return item
end

local function money(amount)
    local value = tostring(math.floor(tonumber(amount) or 0))
    return "$" .. string.reverse(string.reverse(value):gsub("(%d%d%d)", "%1,")):gsub("^,", "")
end

local header = panel("Header")
header.Position = UDim2.fromOffset(14, 10)
header.Size = UDim2.new(1, -28, 0, 82)
local title = text(header, "KRUSTY KRAB", 22, colors.teal, true)
title.Position = UDim2.fromOffset(16, 9)
title.Size = UDim2.fromOffset(280, 28)
local subtitle = text(header, "BURGER TYCOON  /  YOUR FIRST SHIFT", 10, colors.muted, true)
subtitle.Position = UDim2.fromOffset(17, 40)
subtitle.Size = UDim2.fromOffset(300, 16)
local saving = text(header, "Session only · progress resets when you leave", 10, colors.muted)
saving.Position = UDim2.fromOffset(17, 59)
saving.Size = UDim2.fromOffset(340, 14)

local stats = create("Frame", { BackgroundTransparency = 1 }, header)
local cash = text(stats, "$50", 28, colors.green, true)
cash.Size = UDim2.fromOffset(160, 35)
local served = text(stats, "0 burgers served", 11, colors.muted)
served.Position = UDim2.fromOffset(0, 37)
served.Size = UDim2.fromOffset(165, 18)
local payout = text(stats, "$25 / burger", 12, colors.ink, true)
payout.Position = UDim2.fromOffset(172, 8)
payout.Size = UDim2.fromOffset(140, 24)
local plotLabel = text(stats, "Finding your restaurant…", 10, colors.muted)
plotLabel.Position = UDim2.fromOffset(172, 35)
plotLabel.Size = UDim2.fromOffset(150, 23)

local helpButton = button(header, "How to play")
local upgradeButton = button(header, "Upgrades")

local objective = panel("Objective")
local objectiveTag = text(objective, "ON THE MENU", 10, colors.teal, true)
objectiveTag.Position = UDim2.fromOffset(15, 12)
objectiveTag.Size = UDim2.new(1, -30, 0, 14)
local objectiveTitle = text(objective, "Welcome to your first shift!", 17, colors.ink, true)
objectiveTitle.Position = UDim2.fromOffset(15, 31)
objectiveTitle.Size = UDim2.new(1, -30, 0, 44)
local objectiveDescription = text(objective, "Your restaurant will be ready in a moment.", 12, colors.muted)
objectiveDescription.Position = UDim2.fromOffset(15, 79)
objectiveDescription.Size = UDim2.new(1, -30, 0, 47)
local controls = text(objective, "Use E, tap a prompt, or use your controller.", 10, colors.teal)
controls.Position = UDim2.fromOffset(15, 131)
controls.Size = UDim2.new(1, -30, 0, 25)

local grillPanel = panel("GrillStatus")
local grillTitle = text(grillPanel, "YOUR GRILLS", 10, colors.teal, true)
grillTitle.Position = UDim2.fromOffset(14, 10)
grillTitle.Size = UDim2.new(1, -28, 0, 15)
local grillLines = text(grillPanel, "Waiting for your restaurant…", 12, colors.ink)
grillLines.Position = UDim2.fromOffset(14, 31)
grillLines.Size = UDim2.new(1, -28, 0, 46)

local upgradesPanel = panel("RestaurantUpgrades")
local upgradesTitle = text(upgradesPanel, "A BIGGER, BETTER KRAB", 14, colors.teal, true)
upgradesTitle.Position = UDim2.fromOffset(15, 12)
upgradesTitle.Size = UDim2.new(1, -30, 0, 24)
local upgradeHelp = text(upgradesPanel, "Buy at the glowing pads beside your restaurant.", 11, colors.muted)
upgradeHelp.Position = UDim2.fromOffset(15, 40)
upgradeHelp.Size = UDim2.new(1, -30, 0, 33)
local upgradeList = create("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 82),
    Size = UDim2.new(1, -24, 1, -94),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = colors.teal,
    CanvasSize = UDim2.fromOffset(0, #Config.Upgrades * 66),
}, upgradesPanel)
local upgradeRows = {}
for index, upgrade in ipairs(Config.Upgrades) do
    local row = create("Frame", {
        Position = UDim2.fromOffset(0, (index - 1) * 66),
        Size = UDim2.new(1, -7, 0, 59),
        BackgroundColor3 = colors.white,
        BorderSizePixel = 0,
    }, upgradeList)
    round(row, 9)
    local name = text(row, upgrade.name, 12, colors.ink, true)
    name.Position = UDim2.fromOffset(10, 7)
    name.Size = UDim2.new(1, -76, 0, 20)
    local price = text(row, money(upgrade.cost), 12, colors.teal, true)
    price.TextXAlignment = Enum.TextXAlignment.Right
    price.Position = UDim2.new(1, -72, 0, 7)
    price.Size = UDim2.fromOffset(62, 20)
    local description = text(row, upgrade.description, 10, colors.muted)
    description.Position = UDim2.fromOffset(10, 28)
    description.Size = UDim2.new(1, -20, 0, 26)
    upgradeRows[upgrade.id] = { row = row, name = name, price = price, description = description }
end

local toast = panel("Toast")
toast.Visible = false
toast.ZIndex = 20
toast.AnchorPoint = Vector2.new(0.5, 0)
local toastText = text(toast, "", 13, colors.white, true)
toastText.Position = UDim2.fromOffset(14, 8)
toastText.Size = UDim2.new(1, -28, 1, -16)
toastText.TextXAlignment = Enum.TextXAlignment.Center
toastText.ZIndex = 21

local modalShade = create("TextButton", {
    Name = "HelpModal",
    Text = "",
    AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(9, 50, 64),
    BackgroundTransparency = 0.22,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    ZIndex = 30,
    Modal = true,
}, gui)
local helpCard = panel("HelpCard", modalShade)
helpCard.AnchorPoint = Vector2.new(0.5, 0.5)
helpCard.Position = UDim2.fromScale(0.5, 0.5)
helpCard.ZIndex = 31
local helpTitle = text(helpCard, "READY, CHEF?", 29, colors.teal, true)
helpTitle.Position = UDim2.fromOffset(24, 20)
helpTitle.Size = UDim2.new(1, -48, 0, 39)
helpTitle.ZIndex = 32
local helpSubtitle = text(helpCard, "Your own little restaurant under the sea.", 13, colors.muted)
helpSubtitle.Position = UDim2.fromOffset(24, 62)
helpSubtitle.Size = UDim2.new(1, -48, 0, 32)
helpSubtitle.ZIndex = 32
local steps = {
    "1. Go to a grill in YOUR restaurant and start a burger.",
    "2. Wait, flip it, then pick up the finished burger.",
    "3. Take it to the counter and serve your customer.",
    "4. Spend your earnings at the upgrade pads.",
    "Explore the town and collect sand dollars for bonus cash!",
}
local helpSteps = text(helpCard, table.concat(steps, "\n\n"), 13, colors.ink)
helpSteps.Position = UDim2.fromOffset(24, 105)
helpSteps.Size = UDim2.new(1, -48, 0, 215)
helpSteps.TextYAlignment = Enum.TextYAlignment.Top
helpSteps.ZIndex = 32
local disclaimer = text(helpCard, "Fan-made prototype · handmade shapes · session-only progress", 10, colors.muted)
disclaimer.Position = UDim2.new(0, 24, 1, -91)
disclaimer.Size = UDim2.new(1, -48, 0, 28)
disclaimer.TextXAlignment = Enum.TextXAlignment.Center
disclaimer.ZIndex = 32
local playButton = button(helpCard, "LET'S MAKE BURGERS!")
playButton.Position = UDim2.new(0, 24, 1, -57)
playButton.Size = UDim2.new(1, -48, 0, 38)
playButton.ZIndex = 32

local latestState = nil
local stateReceivedAt = os.clock()
local mobile = false
local panelWasToggled = false
local toastSequence = 0

local function layout()
    local camera = workspace.CurrentCamera
    local viewport = if camera then camera.ViewportSize else Vector2.new(1280, 720)
    mobile = viewport.X < 1050
    header.Size = UDim2.new(1, -28, 0, if mobile then 140 else 82)
    if mobile then
        title.TextSize = 19
        title.Size = UDim2.new(1, -145, 0, 28)
        subtitle.Text = "BURGER TYCOON"
        subtitle.Size = UDim2.new(1, -145, 0, 16)
        saving.Position = UDim2.fromOffset(16, 119)
        saving.Size = UDim2.new(1, -30, 0, 14)
        stats.Position = UDim2.fromOffset(16, 64)
        stats.Size = UDim2.new(1, -32, 0, 53)
        cash.TextSize = 23
        cash.Size = UDim2.new(0.48, -4, 0, 30)
        served.Position = UDim2.fromOffset(0, 30)
        served.Size = UDim2.new(0.48, -4, 0, 18)
        payout.Position = UDim2.new(0.5, 0, 0, 0)
        payout.Size = UDim2.new(0.5, 0, 0, 24)
        plotLabel.Position = UDim2.new(0.5, 0, 0, 27)
        plotLabel.Size = UDim2.new(0.5, 0, 0, 23)
        helpButton.Position = UDim2.new(1, -124, 0, 10)
        helpButton.Size = UDim2.fromOffset(110, 29)
        upgradeButton.Position = UDim2.new(1, -124, 0, 43)
        upgradeButton.Size = UDim2.fromOffset(110, 29)
        objective.Position = UDim2.fromOffset(14, 162)
        objective.Size = UDim2.new(1, -28, 0, 129)
        objectiveTitle.Position = UDim2.fromOffset(15, 30)
        objectiveTitle.Size = UDim2.new(1, -30, 0, 33)
        objectiveTitle.TextSize = 15
        objectiveDescription.Position = UDim2.fromOffset(15, 64)
        objectiveDescription.Size = UDim2.new(1, -30, 0, 35)
        objectiveDescription.TextSize = 11
        controls.Position = UDim2.fromOffset(15, 102)
        controls.Size = UDim2.new(1, -30, 0, 18)
        grillPanel.AnchorPoint = Vector2.new(0.5, 1)
        grillPanel.Position = UDim2.new(0.5, 0, 1, -15)
        grillPanel.Size = UDim2.fromOffset(math.min(310, viewport.X - 130), 83)
        upgradesPanel.Position = UDim2.fromOffset(14, 162)
        upgradesPanel.Size = UDim2.new(1, -28, 0, math.min(410, math.max(240, viewport.Y - 190)))
        toast.Position = UDim2.new(0.5, 0, 0, 301)
    else
        title.TextSize = 22
        title.Size = UDim2.fromOffset(280, 28)
        subtitle.Text = "BURGER TYCOON  /  YOUR FIRST SHIFT"
        subtitle.Size = UDim2.fromOffset(300, 16)
        saving.Position = UDim2.fromOffset(17, 59)
        saving.Size = UDim2.fromOffset(340, 14)
        stats.Position = UDim2.new(0.48, 0, 0, 10)
        stats.Size = UDim2.fromOffset(330, 62)
        cash.TextSize = 28
        cash.Size = UDim2.fromOffset(160, 35)
        served.Position = UDim2.fromOffset(0, 37)
        served.Size = UDim2.fromOffset(165, 18)
        payout.Position = UDim2.fromOffset(172, 8)
        payout.Size = UDim2.fromOffset(140, 24)
        plotLabel.Position = UDim2.fromOffset(172, 35)
        plotLabel.Size = UDim2.fromOffset(150, 23)
        helpButton.Position = UDim2.new(1, -132, 0, 12)
        helpButton.Size = UDim2.fromOffset(116, 26)
        upgradeButton.Position = UDim2.new(1, -132, 0, 44)
        upgradeButton.Size = UDim2.fromOffset(116, 26)
        objective.Position = UDim2.fromOffset(14, 106)
        objective.Size = UDim2.fromOffset(330, 169)
        objectiveTitle.Position = UDim2.fromOffset(15, 31)
        objectiveTitle.Size = UDim2.new(1, -30, 0, 44)
        objectiveTitle.TextSize = 17
        objectiveDescription.Position = UDim2.fromOffset(15, 79)
        objectiveDescription.Size = UDim2.new(1, -30, 0, 47)
        objectiveDescription.TextSize = 12
        controls.Position = UDim2.fromOffset(15, 131)
        controls.Size = UDim2.new(1, -30, 0, 25)
        grillPanel.AnchorPoint = Vector2.new(0, 0)
        grillPanel.Position = UDim2.fromOffset(14, 287)
        grillPanel.Size = UDim2.fromOffset(330, 89)
        upgradesPanel.Position = UDim2.new(1, -294, 0, 106)
        upgradesPanel.Size = UDim2.fromOffset(280, math.min(535, math.max(300, viewport.Y - 130)))
        toast.Position = UDim2.new(0.5, 0, 0, 106)
    end
    if not panelWasToggled then upgradesPanel.Visible = not mobile end
    toast.Size = UDim2.fromOffset(math.min(440, viewport.X - 40), 57)
    helpCard.Size = UDim2.fromOffset(math.min(470, viewport.X - 28), math.min(440, viewport.Y - 30))
    if viewport.Y < 470 then
        helpSteps.TextSize = 11
        helpSteps.Position = UDim2.fromOffset(24, 94)
        helpSteps.Size = UDim2.new(1, -48, 1, -193)
        helpSteps.Text = table.concat(steps, "\n")
    else
        helpSteps.TextSize = 13
        helpSteps.Position = UDim2.fromOffset(24, 105)
        helpSteps.Size = UDim2.new(1, -48, 1, -205)
        helpSteps.Text = table.concat(steps, "\n\n")
    end
end

local function notify(message, kind)
    toastSequence += 1
    local sequence = toastSequence
    toast.BackgroundColor3 = if kind == "error" then colors.red elseif kind == "success" then colors.green else colors.teal
    toastText.Text = tostring(message)
    toast.Visible = true
    toast.BackgroundTransparency = 0
    task.delay(3.5, function()
        if sequence ~= toastSequence then return end
        local tween = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
        tween:Play()
        tween.Completed:Wait()
        if sequence == toastSequence then toast.Visible = false end
    end)
end

local function stageLabel(grill, elapsed)
    local remaining = math.max(0, (grill.remaining or 0) - elapsed)
    if grill.stage == "Cooking" then return "First side · " .. string.format("%.1fs", remaining) end
    if grill.stage == "Finishing" then return "Second side · " .. string.format("%.1fs", remaining) end
    if grill.stage == "Flip" then return "FLIP NOW!" end
    if grill.stage == "Ready" then return "Ready to pick up!" end
    if grill.stage == "Locked" then return "Buy the second-grill upgrade" end
    return "Ready to start cooking"
end

local function renderGrills()
    if not latestState then return end
    local lines = {}
    local elapsed = os.clock() - stateReceivedAt
    for index, grill in ipairs(latestState.grills or {}) do
        table.insert(lines, "Grill " .. tostring(index) .. "  /  " .. stageLabel(grill, elapsed))
    end
    grillLines.Text = if #lines > 0 then table.concat(lines, "\n") else "Waiting for an available restaurant…"
end

local function renderState(state)
    if type(state) ~= "table" then return end
    latestState = state
    stateReceivedAt = os.clock()
    cash.Text = money(state.cash)
    served.Text = tostring(state.burgersServed or 0) .. " burgers served"
    payout.Text = money(state.burgerValue) .. " / burger"
    plotLabel.Text = if state.plotIndex then "Your restaurant · #" .. tostring(state.plotIndex) else "Waiting for a restaurant"
    saving.Text = if state.persistence then "Progress saving is enabled" else "Session only · progress resets when you leave"
    disclaimer.Text = if state.persistence then "Fan-made prototype · handmade shapes · progress saving enabled" else "Fan-made prototype · handmade shapes · session-only progress"
    local upgrades = state.upgrades or {}
    for _, upgrade in ipairs(Config.Upgrades) do
        local owned = upgrades[upgrade.id] == true
        local available = not upgrade.requires or upgrades[upgrade.requires]
        local row = upgradeRows[upgrade.id]
        row.row.BackgroundColor3 = if owned then Color3.fromRGB(224, 242, 219) else colors.white
        row.price.Text = if owned then "OWNED" else money(upgrade.cost)
        row.price.TextColor3 = if owned then colors.green elseif available and (state.cash or 0) >= upgrade.cost then colors.teal else colors.muted
        row.name.TextColor3 = if owned or available then colors.ink else colors.muted
    end
    if not state.plotIndex then
        objectiveTitle.Text = "Take a little ocean stroll"
        objectiveDescription.Text = "Waiting for a free restaurant. Explore town and collect sand dollars meanwhile."
    elseif state.carrying then
        objectiveTitle.Text = "One burger, coming right up!"
        objectiveDescription.Text = "Take your finished burger to YOUR restaurant's service counter and serve it for " .. money(state.burgerValue) .. "."
    else
        local flip = false
        local ready = false
        local cooking = false
        for _, grill in ipairs(state.grills or {}) do
            flip = flip or grill.stage == "Flip"
            ready = ready or grill.stage == "Ready"
            cooking = cooking or grill.stage == "Cooking" or grill.stage == "Finishing"
        end
        if ready then
            objectiveTitle.Text = "Order up! Grab that burger"
            objectiveDescription.Text = "Your burger is cooked. Pick it up at the grill, then head to the service counter."
        elseif flip then
            objectiveTitle.Text = "It's flipping time!"
            objectiveDescription.Text = "Go back to your grill and flip the patty to cook the other side."
        elseif cooking then
            objectiveTitle.Text = "A little sizzle, a little patience"
            objectiveDescription.Text = "Watch your grill status. Get ready to flip or pick up your finished burger."
        else
            objectiveTitle.Text = "Fire up the grill, chef!"
            objectiveDescription.Text = "Walk to a grill inside YOUR restaurant and start a burger. Serve burgers to earn upgrades."
        end
    end
    renderGrills()
end

playButton.Activated:Connect(function()
    modalShade.Visible = false
end)
helpButton.Activated:Connect(function()
    modalShade.Visible = not modalShade.Visible
end)
upgradeButton.Activated:Connect(function()
    panelWasToggled = true
    upgradesPanel.Visible = not upgradesPanel.Visible
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.H then
        modalShade.Visible = not modalShade.Visible
    end
end)

remotes:WaitForChild("State").OnClientEvent:Connect(renderState)
remotes:WaitForChild("Notice").OnClientEvent:Connect(notify)
task.spawn(function()
    local getter = remotes:WaitForChild("GetState")
    for _ = 1, 30 do
        local ok, state = pcall(function() return getter:InvokeServer() end)
        if ok and state then
            renderState(state)
            return
        end
        task.wait(1)
    end
    notify("Still waiting for your restaurant. Try rejoining if the server is full.", "info")
end)

local function watchCamera()
    local camera = workspace.CurrentCamera
    if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
    layout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
task.spawn(function()
    while gui.Parent do
        task.wait(0.2)
        renderGrills()
    end
end)
