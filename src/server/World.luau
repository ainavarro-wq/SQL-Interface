-- Procedural seaside restaurant town. No Toolbox models or external asset IDs.
local World = {}
local TweenService = game:GetService("TweenService")

local colors = {
    sand = Color3.fromRGB(242, 220, 157),
    path = Color3.fromRGB(224, 198, 140),
    wood = Color3.fromRGB(145, 88, 45),
    plank = Color3.fromRGB(188, 131, 73),
    darkWood = Color3.fromRGB(94, 58, 40),
    roof = Color3.fromRGB(178, 60, 48),
    turquoise = Color3.fromRGB(55, 179, 179),
    blue = Color3.fromRGB(43, 116, 150),
    sponge = Color3.fromRGB(255, 222, 61),
    coral = Color3.fromRGB(255, 143, 143),
    mint = Color3.fromRGB(87, 221, 171),
    gold = Color3.fromRGB(255, 193, 62),
}

local function model(parent, name)
    local result = Instance.new("Model")
    result.Name = name
    result.Parent = parent
    return result
end

local function part(parent, name, size, transform, color, material)
    local result = Instance.new("Part")
    result.Name = name
    result.Size = size
    result.CFrame = transform
    result.Color = color
    result.Material = material or Enum.Material.SmoothPlastic
    result.Anchored = true
    result.TopSurface = Enum.SurfaceType.Smooth
    result.BottomSurface = Enum.SurfaceType.Smooth
    result.Parent = parent
    return result
end

local function ball(parent, name, size, transform, color, material)
    local result = part(parent, name, size, transform, color, material)
    result.Shape = Enum.PartType.Ball
    return result
end

local function disc(parent, name, diameter, thickness, transform, color, material)
    local result = part(parent, name, Vector3.new(thickness, diameter, diameter),
        transform * CFrame.Angles(0, 0, math.rad(90)), color, material)
    result.Shape = Enum.PartType.Cylinder
    return result
end

local function billboard(parent, text, width, height, offset, color)
    local gui = Instance.new("BillboardGui")
    gui.Name = "WorldLabel"
    gui.Size = UDim2.fromOffset(width, height)
    gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 100
    gui.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(22, 65, 74)
    label.BackgroundTransparency = 0.12
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.PaddingLeft = UDim.new(0, 9)
    padding.PaddingRight = UDim.new(0, 9)
    padding.Parent = label
    return label
end

local function surface(parent, text, color)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "SignText"
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 36
    gui.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = gui
    return label
end

local function prompt(parent, action, object)
    local result = Instance.new("ProximityPrompt")
    result.Name = "Interact"
    result.ActionText = action
    result.ObjectText = object
    result.KeyboardKeyCode = Enum.KeyCode.E
    result.GamepadKeyCode = Enum.KeyCode.ButtonX
    result.HoldDuration = 0.12
    result.MaxActivationDistance = 10
    result.RequiresLineOfSight = false
    result.Parent = parent
    return result
end

local function visible(group, enabled)
    for _, descendant in ipairs(group:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Transparency = if enabled then (descendant:GetAttribute("VisibleTransparency") or 0) else 1
            descendant.CanCollide = enabled and descendant:GetAttribute("Solid") == true
        elseif descendant:IsA("SurfaceGui") or descendant:IsA("BillboardGui") then
            descendant.Enabled = enabled
        elseif descendant:IsA("Light") then
            descendant.Enabled = enabled
        end
    end
end

local function prepareGroup(group)
    for _, descendant in ipairs(group:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant:SetAttribute("VisibleTransparency", descendant.Transparency)
            descendant:SetAttribute("Solid", descendant.CanCollide)
        end
    end
end

local function spongeCustomer(parent, origin, shirtColor)
    local customer = model(parent, "Hungry customer")
    part(customer, "Sponge", Vector3.new(3.2, 3, 1.4), origin * CFrame.new(0, 4.1, 0), colors.sponge)
    part(customer, "Shirt", Vector3.new(3.2, 0.65, 1.4), origin * CFrame.new(0, 2.5, 0), shirtColor)
    part(customer, "Shorts", Vector3.new(3.2, 0.8, 1.4), origin * CFrame.new(0, 1.8, 0), colors.wood)
    for _, side in ipairs({ -1, 1 }) do
        part(customer, "Leg", Vector3.new(0.5, 1.2, 0.5), origin * CFrame.new(side * 0.8, 1, 0), colors.sponge)
        part(customer, "Shoe", Vector3.new(1, 0.5, 1.6), origin * CFrame.new(side * 0.8, 0.35, -0.2), colors.darkWood)
        ball(customer, "Eye", Vector3.new(0.95, 1, 0.3), origin * CFrame.new(side * 0.62, 4.55, -0.8), Color3.new(1, 1, 1))
        ball(customer, "Iris", Vector3.new(0.4, 0.5, 0.16), origin * CFrame.new(side * 0.62, 4.55, -0.98), colors.blue)
        ball(customer, "Pupil", Vector3.new(0.2, 0.3, 0.1), origin * CFrame.new(side * 0.62, 4.55, -1.08), Color3.fromRGB(25, 36, 42))
    end
    part(customer, "Smile", Vector3.new(1.25, 0.16, 0.15), origin * CFrame.new(0, 3.7, -0.78), colors.darkWood)
    for _, side in ipairs({ -1, 1 }) do
        part(customer, "Tooth", Vector3.new(0.3, 0.38, 0.16), origin * CFrame.new(side * 0.2, 3.6, -0.9), Color3.new(1, 1, 1))
    end
    for _, descendant in ipairs(customer:GetDescendants()) do
        if descendant:IsA("BasePart") then descendant.CanCollide = false end
    end
    return customer
end

local function grill(parent, origin, number)
    local group = model(parent, "Grill " .. tostring(number))
    local base = part(group, "Grill base", Vector3.new(9, 3.5, 6), origin * CFrame.new(0, 2.75, 0), Color3.fromRGB(85, 103, 105), Enum.Material.Metal)
    local top = part(group, "Cooking surface", Vector3.new(9.5, 0.35, 6.5), origin * CFrame.new(0, 4.7, 0), Color3.fromRGB(40, 49, 53), Enum.Material.Metal)
    for index = -3, 3 do
        part(group, "Grill stripe", Vector3.new(0.1, 0.06, 5.6), origin * CFrame.new(index * 1.2, 4.92, 0), Color3.fromRGB(115, 124, 124), Enum.Material.Metal)
    end
    for _, side in ipairs({ -1, 1 }) do
        local knob = ball(group, "Heat control", Vector3.new(0.7, 0.7, 0.35), origin * CFrame.new(side * 2, 2.9, -3.12), colors.roof)
        knob.CanCollide = false
    end
    local burger = model(group, "Burger")
    disc(burger, "Patty", 2.6, 0.45, origin * CFrame.new(0, 5.25, 0), Color3.fromRGB(193, 99, 91))
    local bun = disc(burger, "Top bun", 2.9, 0.7, origin * CFrame.new(0, 5.9, 0), Color3.fromRGB(234, 172, 74))
    bun:SetAttribute("CookedOnly", true)
    local lettuce = disc(burger, "Lettuce", 3, 0.15, origin * CFrame.new(0, 5.53, 0), colors.mint)
    lettuce:SetAttribute("CookedOnly", true)
    for _, descendant in ipairs(burger:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.Transparency = 1
        end
    end
    local stationPrompt = prompt(top, "Start burger", "Grill " .. tostring(number))
    local indicator = billboard(top, "GRILL " .. tostring(number) .. "\nReady to cook", 180, 52, Vector3.new(0, 3.8, 0))
    prepareGroup(group)
    return { model = group, part = base, prompt = stationPrompt, burger = burger, indicator = indicator }
end

local function tableSet(parent, origin)
    local group = model(parent, "Table and seats")
    disc(group, "Table top", 5.5, 0.5, origin * CFrame.new(0, 3.7, 0), colors.plank, Enum.Material.Wood)
    part(group, "Table leg", Vector3.new(0.6, 3.2, 0.6), origin * CFrame.new(0, 1.8, 0), colors.darkWood, Enum.Material.Wood)
    for _, side in ipairs({ -1, 1 }) do
        part(group, "Seat", Vector3.new(3.4, 0.5, 2.1), origin * CFrame.new(side * 4, 2.15, 0), colors.coral)
        part(group, "Seat leg", Vector3.new(0.6, 1.8, 0.6), origin * CFrame.new(side * 4, 1.05, 0), colors.darkWood)
    end
end

local function jellyfish(parent, origin, color)
    local cap = ball(parent, "Jellyfish bell", Vector3.new(3.8, 2.7, 3.8), origin, color, Enum.Material.Neon)
    cap.CanCollide = false
    cap.Transparency = 0.18
    for index = 1, 4 do
        local angle = index * math.pi * 0.5
        local tentacle = part(parent, "Jellyfish tentacle", Vector3.new(0.18, 3.4, 0.18),
            origin * CFrame.new(math.cos(angle), -2.4, math.sin(angle)) * CFrame.Angles(0, 0, math.rad(12)), color, Enum.Material.Neon)
        tentacle.CanCollide = false
    end
end

local function plot(parent, origin, index, config)
    local group = model(parent, "Restaurant plot " .. tostring(index))
    local deck = part(group, "Restaurant deck", Vector3.new(54, 1.4, 42), origin * CFrame.new(0, 0.8, 2), colors.plank, Enum.Material.WoodPlanks)
    part(group, "Back wall", Vector3.new(54, 11, 1), origin * CFrame.new(0, 6.4, 23), colors.wood, Enum.Material.WoodPlanks)
    for _, side in ipairs({ -1, 1 }) do
        part(group, "Low side wall", Vector3.new(1, 3, 42), origin * CFrame.new(side * 27, 2.8, 2), colors.wood, Enum.Material.WoodPlanks)
        for _, depth in ipairs({ -18, 22 }) do
            part(group, "Roof post", Vector3.new(1.2, 11, 1.2), origin * CFrame.new(side * 26, 6.4, depth), colors.darkWood, Enum.Material.Wood)
        end
        -- A cutaway roof leaves the cooking area visible to the third-person camera.
        local roof = part(group, "Roof wing", Vector3.new(14, 1.2, 43),
            origin * CFrame.new(side * 21, 12.2, 2) * CFrame.Angles(0, 0, math.rad(side * 12)), colors.roof, Enum.Material.WoodPlanks)
        roof.CanCollide = false
        part(group, "Round window rim", Vector3.new(9, 7, 0.4), origin * CFrame.new(side * 16, 7.7, 22.35), colors.darkWood)
        local glass = part(group, "Blue window", Vector3.new(7.5, 5.5, 0.5), origin * CFrame.new(side * 16, 7.7, 22), colors.turquoise, Enum.Material.Glass)
        glass.Transparency = 0.35
    end
    local sign = part(group, "Restaurant sign", Vector3.new(29, 5.2, 0.8), origin * CFrame.new(0, 11.4, -18.7), colors.darkWood, Enum.Material.Wood)
    surface(sign, "THE KRUSTY KRAB", colors.gold)
    local ownerAnchor = part(group, "Owner name anchor", Vector3.new(1, 1, 1), origin * CFrame.new(0, 13.5, -20), colors.darkWood)
    ownerAnchor.Transparency = 1
    ownerAnchor.CanCollide = false
    local ownerLabel = billboard(ownerAnchor, "UNCLAIMED RESTAURANT", 280, 36, Vector3.new(0, 2, 0), colors.gold)
    local counter = part(group, "Order counter", Vector3.new(16, 3.7, 3.6), origin * CFrame.new(0, 3.1, -13.5), colors.turquoise, Enum.Material.Wood)
    part(group, "Counter top", Vector3.new(17, 0.45, 4), origin * CFrame.new(0, 5.2, -13.5), colors.gold)
    local servePrompt = prompt(counter, "Serve burger", "Hungry customer · $25+")
    billboard(counter, "ORDER PICKUP\nBring a cooked burger here", 220, 52, Vector3.new(0, 5.6, 0))
    spongeCustomer(group, origin * CFrame.new(-5, 0, -24) * CFrame.Angles(0, math.pi, 0), Color3.new(1, 1, 1))
    spongeCustomer(group, origin * CFrame.new(5, 0, -27) * CFrame.Angles(0, math.pi, 0), colors.coral)
    local grills = {
        grill(group, origin * CFrame.new(-13, 0, 8), 1),
        grill(group, origin * CFrame.new(13, 0, 8), 2),
    }

    local upgradeGroups = {}
    local dining = model(group, "Dining room upgrade")
    tableSet(dining, origin * CFrame.new(-15, 0, -4))
    tableSet(dining, origin * CFrame.new(15, 0, -4))
    upgradeGroups.diningRoom = dining

    local neon = model(group, "Neon sign upgrade")
    local neonBoard = part(neon, "Neon board", Vector3.new(23, 3.4, 0.5), origin * CFrame.new(0, 16, -18.8), colors.turquoise, Enum.Material.Neon)
    neonBoard.CanCollide = false
    surface(neonBoard, "FRESH PATTIES • BIG SMILES", Color3.new(1, 1, 1))
    local light = Instance.new("PointLight")
    light.Color = colors.turquoise
    light.Brightness = 1.5
    light.Range = 20
    light.Parent = neonBoard
    upgradeGroups.neonSign = neon

    local garden = model(group, "Jellyfish garden upgrade")
    disc(garden, "Garden sand", 17, 0.45, origin * CFrame.new(36, 0.35, 4), Color3.fromRGB(231, 205, 173), Enum.Material.Sand)
    jellyfish(garden, origin * CFrame.new(33, 7, 1), colors.coral)
    jellyfish(garden, origin * CFrame.new(39, 9, 7), Color3.fromRGB(211, 147, 247))
    upgradeGroups.jellyfishGarden = garden

    local gold = model(group, "Golden spatula upgrade")
    part(gold, "Trophy pedestal", Vector3.new(3, 2, 3), origin * CFrame.new(0, 2.4, 18), colors.darkWood)
    local handle = part(gold, "Golden handle", Vector3.new(0.45, 5, 0.45), origin * CFrame.new(0, 5.5, 18), colors.gold, Enum.Material.Metal)
    handle.CanCollide = false
    part(gold, "Spatula blade", Vector3.new(2.8, 2.4, 0.35), origin * CFrame.new(0, 9, 18), colors.gold, Enum.Material.Metal)
    billboard(handle, "MASTER FRY COOK", 190, 32, Vector3.new(0, 5.7, 0), colors.gold)
    upgradeGroups.goldenSpatula = gold

    local sauce = model(group, "Secret sauce upgrade")
    local bottle = part(sauce, "Sauce bottle", Vector3.new(1.1, 2.1, 1.1), origin * CFrame.new(-7, 6.5, -13.5), colors.roof)
    bottle.CanCollide = false
    part(sauce, "Bottle cap", Vector3.new(0.55, 0.45, 0.55), origin * CFrame.new(-7, 7.8, -13.5), colors.gold).CanCollide = false
    upgradeGroups.secretSauce = sauce

    local speedy = model(group, "Fast grill upgrade")
    local badge = part(speedy, "Turbo grill badge", Vector3.new(8, 1.6, 0.25), origin * CFrame.new(0, 8, 22), colors.gold, Enum.Material.Neon)
    badge.CanCollide = false
    surface(badge, "QUICK FLIP", colors.darkWood)
    upgradeGroups.speedyGrill = speedy

    local upgradePrompts = {}
    local upgradePads = {}
    for position, upgrade in ipairs(config.Upgrades) do
        -- All purchases share one spot; only the next available pad is shown.
        local padGroup = model(group, upgrade.name .. " purchase pad")
        local pad = disc(padGroup, "Upgrade pad", 7, 0.3, origin * CFrame.new(35, 0.6, -15), colors.mint, Enum.Material.Neon)
        local anchor = part(padGroup, "Prompt anchor", Vector3.new(1, 1, 1), origin * CFrame.new(35, 2.4, -15), colors.mint)
        anchor.Transparency = 1
        anchor.CanCollide = false
        billboard(anchor, upgrade.name .. "\n$" .. tostring(upgrade.cost), 190, 55, Vector3.new(0, 3, 0), colors.gold)
        local purchasePrompt = prompt(anchor, "Buy · $" .. tostring(upgrade.cost), upgrade.name)
        purchasePrompt:SetAttribute("UpgradeId", upgrade.id)
        purchasePrompt:SetAttribute("Order", position)
        upgradePrompts[upgrade.id] = purchasePrompt
        prepareGroup(padGroup)
        upgradePads[upgrade.id] = padGroup
    end
    for _, groupToPrepare in pairs(upgradeGroups) do prepareGroup(groupToPrepare) end

    local result = {
        index = index,
        origin = origin,
        model = group,
        spawn = origin * CFrame.new(0, 5, -7),
        grills = grills,
        servePrompt = servePrompt,
        upgradePrompts = upgradePrompts,
        ownerLabel = ownerLabel,
        upgradeGroups = upgradeGroups,
        upgradePads = upgradePads,
        deck = deck,
    }
    World.updatePlot(result, nil, {}, config)
    return result
end

function World.setBurger(station, enabled, cooked)
    for _, descendant in ipairs(station.burger:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Transparency = if enabled and (cooked or not descendant:GetAttribute("CookedOnly")) then 0 else 1
            descendant:SetAttribute("VisibleTransparency", descendant.Transparency)
            if descendant.Name == "Patty" then
                descendant.Color = if cooked then Color3.fromRGB(104, 58, 35) else Color3.fromRGB(193, 99, 91)
            end
        end
    end
end

function World.flipBurger(station)
    local burger = station.burger
    local start = burger:GetPivot()
    local progress = Instance.new("NumberValue")
    progress.Value = 0
    local changed = progress.Changed:Connect(function(alpha)
        if burger.Parent then
            burger:PivotTo(start * CFrame.new(0, math.sin(alpha * math.pi) * 2.6, 0)
                * CFrame.Angles(alpha * math.pi * 2, 0, 0))
        end
    end)
    local tween = TweenService:Create(progress, TweenInfo.new(0.5, Enum.EasingStyle.Linear), { Value = 1 })
    tween.Completed:Connect(function()
        changed:Disconnect()
        progress:Destroy()
        if burger.Parent then burger:PivotTo(start) end
    end)
    tween:Play()
end

function World.updatePlot(restaurant, playerName, upgrades, config)
    restaurant.ownerLabel.Text = if playerName then string.upper(playerName) .. "'S KRUSTY KRAB" else "UNCLAIMED RESTAURANT"
    for id, group in pairs(restaurant.upgradeGroups) do
        visible(group, playerName ~= nil and upgrades[id] == true)
    end
    visible(restaurant.grills[2].model, playerName ~= nil and upgrades.secondGrill == true)
    restaurant.grills[1].prompt.Enabled = playerName ~= nil
    restaurant.grills[2].prompt.Enabled = playerName ~= nil and upgrades.secondGrill == true
    restaurant.servePrompt.Enabled = playerName ~= nil
    for _, upgrade in ipairs(config.Upgrades) do
        local available = playerName ~= nil and not upgrades[upgrade.id]
            and (not upgrade.requires or upgrades[upgrade.requires] == true)
        visible(restaurant.upgradePads[upgrade.id], available)
        restaurant.upgradePrompts[upgrade.id].Enabled = available
    end
end

local function coral(parent, transform, color)
    for index = -1, 1 do
        local branch = part(parent, "Coral branch", Vector3.new(1.3, 5 + index, 1.3),
            transform * CFrame.new(index * 1.5, (5 + index) / 2, 0) * CFrame.Angles(0, 0, math.rad(index * -18)), color)
        branch.CanCollide = false
        ball(parent, "Coral tip", Vector3.new(2, 2, 2), transform * CFrame.new(index * 2, 5 + index, 0), color).CanCollide = false
    end
end

local function pineapple(parent, origin)
    local home = model(parent, "Pineapple home")
    ball(home, "Pineapple", Vector3.new(20, 27, 20), origin * CFrame.new(0, 13, 0), Color3.fromRGB(238, 164, 45))
    for index = 0, 7 do
        local angle = index * math.pi / 4
        local leaf = part(home, "Pineapple leaf", Vector3.new(3, 13, 2),
            origin * CFrame.new(math.cos(angle) * 3, 30, math.sin(angle) * 3) * CFrame.Angles(math.sin(angle) * 0.5, angle, math.cos(angle) * 0.5), Color3.fromRGB(80, 158, 73))
        leaf.CanCollide = false
    end
    part(home, "Front door", Vector3.new(5, 8, 1), origin * CFrame.new(0, 4.5, -9.5), colors.blue)
    ball(home, "Porthole window", Vector3.new(5, 5, 1), origin * CFrame.new(5, 13, -8), colors.turquoise)
    for height = 5, 22, 5 do
        local ring = disc(home, "Pineapple groove", 19.5 - math.abs(height - 13) * 0.3, 0.18, origin * CFrame.new(0, height, 0), Color3.fromRGB(202, 126, 38))
        ring.CanCollide = false
    end
    billboard(home.PrimaryPart or home:FindFirstChild("Pineapple"), "HOME SWEET PINEAPPLE", 240, 35, Vector3.new(0, 24, 0), colors.gold)
end

function World.build(config)
    local existing = workspace:FindFirstChild("BurgerTown")
    if existing then existing:Destroy() end
    local root = model(workspace, "BurgerTown")
    part(root, "Ocean floor", Vector3.new(440, 4, 440), CFrame.new(0, -2, 0), colors.sand, Enum.Material.Sand)
    part(root, "Main promenade", Vector3.new(22, 0.12, 300), CFrame.new(0, 0.08, 0), colors.path, Enum.Material.Sand)
    part(root, "Cross promenade", Vector3.new(300, 0.12, 20), CFrame.new(0, 0.1, 0), colors.path, Enum.Material.Sand)
    disc(root, "Central plaza", 39, 0.25, CFrame.new(0, 0.22, 0), colors.turquoise, Enum.Material.SmoothPlastic)
    local welcome = part(root, "Welcome sign", Vector3.new(19, 5, 0.8), CFrame.new(0, 7, -18), colors.darkWood, Enum.Material.Wood)
    surface(welcome, "BIKINI BOTTOM\nCOOK • FLIP • UPGRADE", colors.gold)
    for _, side in ipairs({ -1, 1 }) do
        part(root, "Welcome sign post", Vector3.new(0.9, 7, 0.9), CFrame.new(side * 8, 3.7, -18), colors.wood, Enum.Material.Wood)
    end
    local spawnPoint = Instance.new("SpawnLocation")
    spawnPoint.Name = "Town spawn"
    spawnPoint.Size = Vector3.new(10, 0.4, 10)
    spawnPoint.CFrame = CFrame.new(0, 0.7, 6)
    spawnPoint.Anchored = true
    spawnPoint.Neutral = true
    spawnPoint.Duration = 0
    spawnPoint.Transparency = 1
    spawnPoint.Parent = root

    local plots = {}
    local origins = {
        CFrame.new(-65, 0, 65), CFrame.new(65, 0, 65),
        CFrame.new(-65, 0, -65) * CFrame.Angles(0, math.pi, 0),
        CFrame.new(65, 0, -65) * CFrame.Angles(0, math.pi, 0),
    }
    for index = 1, math.min(config.MaxPlots, #origins) do
        plots[index] = plot(root, origins[index], index, config)
        local origin = origins[index]
        part(root, "Restaurant walkway", Vector3.new(12, 0.15, 26), origin * CFrame.new(0, 0.12, -34), colors.path, Enum.Material.Sand)
    end

    pineapple(root, CFrame.new(-105, 0, 0))
    local rockHome = ball(root, "Rock home", Vector3.new(23, 15, 20), CFrame.new(108, 3, 0), Color3.fromRGB(155, 119, 109), Enum.Material.Rock)
    billboard(rockHome, "THE NEIGHBORHOOD", 190, 30, Vector3.new(0, 14, 0), colors.gold)
    for index = 1, 24 do
        local angle = index * math.pi * 2 / 24
        local distance = 145 + (index % 3) * 12
        coral(root, CFrame.new(math.cos(angle) * distance, 0, math.sin(angle) * distance),
            if index % 2 == 0 then colors.coral else Color3.fromRGB(166, 139, 213))
    end
    for index = 1, 12 do
        local angle = index * math.pi * 2 / 12
        local bubble = ball(root, "Ocean bubble", Vector3.new(4, 4, 4),
            CFrame.new(math.cos(angle) * 128, 25 + (index % 4) * 9, math.sin(angle) * 128), Color3.fromRGB(193, 247, 248), Enum.Material.Glass)
        bubble.Transparency = 0.65
        bubble.CanCollide = false
    end

    -- Broad stepping stones form an optional free-roam park, with no death traps.
    for index = 1, 7 do
        disc(root, "Jellyfish stepping stone", 9, 2,
            CFrame.new(-30 + index * 9, 1 + (index % 3) * 1.5, 123 + math.sin(index) * 7),
            if index % 2 == 0 then colors.coral else colors.turquoise)
    end
    jellyfish(root, CFrame.new(-25, 12, 140), colors.coral)
    jellyfish(root, CFrame.new(25, 15, 140), Color3.fromRGB(205, 145, 243))

    local coins = {}
    local coinPositions = {
        Vector3.new(-22, 3, 0), Vector3.new(22, 3, 0),
        Vector3.new(0, 3, 34), Vector3.new(0, 3, -34),
        Vector3.new(-110, 3, -20), Vector3.new(110, 3, 20),
        Vector3.new(-21, 7, 129), Vector3.new(6, 7, 118), Vector3.new(33, 7, 128),
        Vector3.new(0, 3, -135),
    }
    for index, position in ipairs(coinPositions) do
        local coin = disc(root, "Sand dollar " .. tostring(index), 3.3, 0.55,
            CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0), colors.gold, Enum.Material.Neon)
        coin.CanCollide = false
        coin.CanTouch = true
        billboard(coin, "+$" .. tostring(config.CollectibleCash), 72, 27, Vector3.new(0, 2.8, 0), colors.gold)
        table.insert(coins, coin)
    end

    return { model = root, plots = plots, spawn = CFrame.new(0, 4, 6), coins = coins }
end

return World
