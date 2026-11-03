local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Economy)
local World = require(script.Parent.World)
local Costume = require(script.Parent.Costume)
local ProfileStore = require(script.Parent.ProfileStore)

local remotes = Instance.new("Folder")
remotes.Name = "TycoonRemotes"
remotes.Parent = ReplicatedStorage
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes
local noticeEvent = Instance.new("RemoteEvent")
noticeEvent.Name = "Notice"
noticeEvent.Parent = remotes
local getState = Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = remotes

local world = World.build(Config)
local states = {}
local plotOwners = {}
local closing = false
local leavingSaves = 0

local function notice(player, message, kind)
    if player.Parent == Players then
        noticeEvent:FireClient(player, message, kind or "info")
    end
end

local function snapshot(state)
    local grills = {}
    for index, grill in ipairs(state.grills) do
        grills[index] = {
            stage = grill.stage,
            remaining = math.max(0, (grill.readyAt or 0) - os.clock()),
        }
    end
    return {
        cash = state.profile.cash,
        burgersServed = state.profile.burgersServed,
        burgerValue = Economy.burgerValue(Config, state.profile),
        upgrades = table.clone(state.profile.upgrades),
        plotIndex = state.plot and state.plot.index or nil,
        carrying = state.carrying,
        grills = grills,
        persistence = state.persistent,
    }
end

local function publish(state)
    if state.player.Parent ~= Players then return end
    local stats = state.player:FindFirstChild("leaderstats")
    if stats then
        stats.Cash.Value = state.profile.cash
        stats.Burgers.Value = state.profile.burgersServed
    end
    stateEvent:FireClient(state.player, snapshot(state))
end

local function updateGrill(state, index)
    local plot = state.plot
    if not plot then return end
    local station = plot.grills[index]
    local grill = state.grills[index]
    local stage = grill.stage
    local descriptions = {
        Empty = { "Start cooking", "Ready for a fresh patty" },
        Cooking = { "Cooking…", "First side is sizzling…" },
        Flip = { "Flip burger", "Time to flip!" },
        Finishing = { "Cooking…", "Finishing the second side…" },
        Ready = { "Pick up burger", "Order up! Take it to the counter" },
        Locked = { "Buy second grill", "Unlock the second grill" },
    }
    station.prompt.ActionText = descriptions[stage][1]
    station.prompt.ObjectText = "Grill " .. tostring(index)
    station.prompt.Enabled = stage == "Empty" or stage == "Flip" or stage == "Ready"
    station.indicator.Text = descriptions[stage][2]
    World.setBurger(station, stage ~= "Empty" and stage ~= "Locked", stage == "Ready")
end

local function updatePlot(state)
    if not state.plot then return end
    World.updatePlot(state.plot, state.player.DisplayName, state.profile.upgrades, Config)
    if state.profile.upgrades.secondGrill and state.grills[2].stage == "Locked" then
        state.grills[2].stage = "Empty"
    end
    for index in ipairs(state.grills) do
        updateGrill(state, index)
    end
    state.plot.servePrompt.Enabled = true
end

local function aliveAndNear(player, part, distance)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return humanoid and humanoid.Health > 0 and root
        and (root.Position - part.Position).Magnitude <= distance
end

local function validatePrompt(player, plot, prompt)
    local state = states[player]
    if not state or state.leaving or state.plot ~= plot or plotOwners[plot.index] ~= state then
        notice(player, "Find your own restaurant plot to cook or buy upgrades.", "error")
        return nil
    end
    if not prompt.Enabled or not aliveAndNear(player, prompt.Parent, prompt.MaxActivationDistance + 3) then
        return nil
    end
    if os.clock() - state.lastAction < 0.2 then return nil end
    state.lastAction = os.clock()
    return state
end

local function clearCarriedBurger(state)
    if state.carriedTool then state.carriedTool:Destroy() end
    state.carriedTool = nil
    state.carrying = false
end

local function giveBurger(state)
    local tool = Instance.new("Tool")
    tool.Name = "Krabby Patty"
    tool.CanBeDropped = false
    tool.ToolTip = "Carry this burger to your restaurant counter."
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Shape = Enum.PartType.Ball
    handle.Size = Vector3.new(1.5, 0.55, 1.5)
    handle.Color = Color3.fromRGB(232, 169, 72)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool
    local layers = {
        { -0.26, 0.16, Color3.fromRGB(90, 170, 58) },
        { -0.38, 0.15, Color3.fromRGB(234, 192, 54) },
        { -0.50, 0.23, Color3.fromRGB(108, 57, 31) },
        { -0.67, 0.28, Color3.fromRGB(217, 148, 62) },
    }
    for _, layer in ipairs(layers) do
        local part = Instance.new("Part")
        part.Name = "BurgerLayer"
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(1.4, layer[2], 1.4)
        part.Color = layer[3]
        part.CFrame = handle.CFrame * CFrame.new(0, layer[1], 0)
        part.CanCollide = false
        part.CanTouch = false
        part.Massless = true
        part.Parent = tool
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = part
        weld.Parent = part
    end
    state.carriedTool = tool
    state.carrying = true
    tool.Parent = state.player:FindFirstChildOfClass("Backpack") or state.player.Character
    local humanoid = state.player.Character and state.player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:EquipTool(tool) end
end

local function later(state, grill, seconds, callback)
    grill.token += 1
    local token = grill.token
    grill.readyAt = os.clock() + seconds
    task.delay(seconds, function()
        if states[state.player] == state and not state.leaving and grill.token == token then
            grill.readyAt = nil
            callback()
        end
    end)
end

local function useGrill(player, plot, index)
    local state = validatePrompt(player, plot, plot.grills[index].prompt)
    if not state then return end
    local grill = state.grills[index]
    if grill.stage == "Empty" then
        grill.stage = "Cooking"
        later(state, grill, Config.CookSeconds * Economy.cookMultiplier(state.profile), function()
            grill.stage = "Flip"
            updateGrill(state, index)
            publish(state)
            notice(player, "Grill " .. index .. ": time to flip your burger!")
        end)
        notice(player, "Patty on the grill! Wait for the flip cue.")
    elseif grill.stage == "Flip" then
        grill.stage = "Finishing"
        if World.flipBurger then World.flipBurger(plot.grills[index]) end
        later(state, grill, Config.FinishSeconds * Economy.cookMultiplier(state.profile), function()
            grill.stage = "Ready"
            updateGrill(state, index)
            publish(state)
            notice(player, "Order up! Pick up the burger from grill " .. index .. ".", "success")
        end)
        notice(player, "Nice flip! Let the other side cook.", "success")
    elseif grill.stage == "Ready" then
        if state.carrying then
            notice(player, "Serve the burger you're holding before picking up another.", "error")
            return
        end
        giveBurger(state)
        grill.stage = "Empty"
        notice(player, "Take your Krabby Patty to the front counter.")
    else
        return
    end
    updateGrill(state, index)
    publish(state)
end

local function serve(player, plot)
    local state = validatePrompt(player, plot, plot.servePrompt)
    if not state then return end
    if not state.carrying or not state.carriedTool or not state.carriedTool.Parent then
        clearCarriedBurger(state)
        publish(state)
        notice(player, "Cook, flip, and pick up a burger first.", "error")
        return
    end
    clearCarriedBurger(state)
    local earned = Economy.serve(Config, state.profile)
    publish(state)
    notice(player, "Happy customer! +$" .. earned .. ". Save up for your next upgrade!", "success")
end

local function buy(player, plot, id)
    local prompt = plot.upgradePrompts[id]
    local state = validatePrompt(player, plot, prompt)
    if not state then return end
    local success, message = Economy.purchase(Config, state.profile, id)
    if success then
        updatePlot(state)
        publish(state)
    end
    notice(player, message, if success then "success" else "error")
end

local function teleportToPlot(state, character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        character:PivotTo(if state.plot then state.plot.spawn else world.spawn)
    end
end

local function assignPlot(state)
    for _, plot in ipairs(world.plots) do
        if not plotOwners[plot.index] then
            plotOwners[plot.index] = state
            state.plot = plot
            state.grills = {
                { stage = "Empty", token = 0 },
                { stage = if state.profile.upgrades.secondGrill then "Empty" else "Locked", token = 0 },
            }
            updatePlot(state)
            if state.player.Character then teleportToPlot(state, state.player.Character) end
            publish(state)
            return true
        end
    end
    return false
end

for _, plot in ipairs(world.plots) do
    World.updatePlot(plot, nil, {}, Config)
    for index, grill in ipairs(plot.grills) do
        grill.prompt.Enabled = false
        grill.prompt.Triggered:Connect(function(player) useGrill(player, plot, index) end)
    end
    plot.servePrompt.Enabled = false
    plot.servePrompt.Triggered:Connect(function(player) serve(player, plot) end)
    for id, prompt in pairs(plot.upgradePrompts) do
        prompt.Enabled = false
        prompt.Triggered:Connect(function(player) buy(player, plot, id) end)
    end
end

for index, coin in ipairs(world.coins) do
    coin.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player and hit.Parent.Parent then
            player = Players:GetPlayerFromCharacter(hit.Parent.Parent)
        end
        local state = player and states[player]
        if not state or state.leaving or not aliveAndNear(player, coin, 8) then return end
        local now = os.clock()
        if now < (state.coinTimes[index] or 0) then return end
        state.coinTimes[index] = now + Config.CollectibleCooldown
        state.profile.cash += Config.CollectibleCash
        publish(state)
        notice(player, "Sand dollar! +$" .. Config.CollectibleCash .. " (returns in 30s)", "success")
    end)
end

getState.OnServerInvoke = function(player)
    local state = states[player]
    if state then return snapshot(state) end
    return nil
end

local function characterAdded(state, character)
    if not character:WaitForChild("HumanoidRootPart", 10) then return end
    if states[state.player] ~= state or state.player.Character ~= character then return end
    clearCarriedBurger(state)
    teleportToPlot(state, character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 20
        humanoid.Died:Connect(function()
            if states[state.player] == state then
                clearCarriedBurger(state)
                publish(state)
            end
        end)
    end
    task.delay(0.5, function()
        if character.Parent and state.player.Character == character then Costume.apply(character) end
    end)
    publish(state)
end

local function playerAdded(player)
    local stored = ProfileStore.load(player, Config, Economy)
    if closing or player.Parent ~= Players then
        ProfileStore.save(player, stored, true)
        return
    end
    local state = stored
    state.player = player
    state.grills = {}
    state.carrying = false
    state.coinTimes = {}
    state.lastAction = 0
    states[player] = state
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    stats.Parent = player
    for _, name in ipairs({ "Cash", "Burgers" }) do
        local value = Instance.new("IntValue")
        value.Name = name
        value.Parent = stats
    end
    player.CharacterAdded:Connect(function(character)
        task.spawn(characterAdded, state, character)
    end)
    player.CharacterAppearanceLoaded:Connect(function(character)
        if character.Parent and player.Character == character then Costume.apply(character) end
    end)
    if not assignPlot(state) then
        notice(player, "All four restaurants are busy. Explore and collect sand dollars while you wait.")
    end
    if player.Character then task.spawn(characterAdded, state, player.Character) end
    publish(state)
    if state.warning then
        task.delay(3, function() notice(player, state.warning, "error") end)
    end
end

local function playerRemoving(player)
    local state = states[player]
    if not state then return end
    state.leaving = true
    clearCarriedBurger(state)
    if state.plot then
        local plot = state.plot
        plotOwners[plot.index] = nil
        World.updatePlot(plot, nil, {}, Config)
        for _, grill in ipairs(plot.grills) do
            grill.prompt.Enabled = false
            World.setBurger(grill, false, false)
        end
        plot.servePrompt.Enabled = false
        for _, prompt in pairs(plot.upgradePrompts) do prompt.Enabled = false end
    end
    states[player] = nil
    if not closing then
        for _, waiting in pairs(states) do
            if not waiting.plot and not waiting.leaving then assignPlot(waiting) end
        end
    end
    leavingSaves += 1
    ProfileStore.save(player, state, true)
    leavingSaves -= 1
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(playerAdded, player) end

task.spawn(function()
    while not closing do
        task.wait(60)
        for player, state in pairs(states) do
            if state.persistent and not state.leaving then
                task.spawn(function()
                    ProfileStore.save(player, state, false)
                    publish(state)
                end)
            end
        end
    end
end)

game:BindToClose(function()
    closing = true
    local pending = 0
    for player, state in pairs(states) do
        if not state.leaving then
            state.leaving = true
            pending += 1
            task.spawn(function()
                ProfileStore.save(player, state, true)
                pending -= 1
            end)
        end
    end
    local deadline = os.clock() + 25
    while (pending > 0 or leavingSaves > 0) and os.clock() < deadline do task.wait(0.1) end
end)
