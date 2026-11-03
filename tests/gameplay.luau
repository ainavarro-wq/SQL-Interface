-- Server-flow checks using real Roblox DOM instances and deterministic service stubs.
-- This exercises game logic, not Roblox physics, rendering, replication, or Studio.
local fs = require('@lune/fs')
local roblox = require('@lune/roblox')
local Instance, Vector3, CFrame = roblox.Instance, roblox.Vector3, roblox.CFrame
local now, queue = 1, {}
local function resume(thread, ...)
    local ok, delay = coroutine.resume(thread, ...)
    assert(ok, delay)
    if coroutine.status(thread) == 'suspended' then
        table.insert(queue, { at = now + (delay or 0), thread = thread })
    end
end
local tasks = {}
function tasks.spawn(callback, ...) resume(coroutine.create(callback), ...) end
function tasks.delay(seconds, callback)
    table.insert(queue, { at = now + seconds, thread = coroutine.create(callback) })
end
function tasks.wait(seconds) return coroutine.yield(seconds) end
local function advance(seconds)
    local target = now + seconds
    while true do
        local selected
        for index, item in ipairs(queue) do
            if item.at <= target and (not selected or item.at < queue[selected].at) then selected = index end
        end
        if not selected then break end
        local item = table.remove(queue, selected)
        now = item.at
        resume(item.thread)
    end
    now = target
end
local signals = {}
local function signal(instance, name)
    signals[instance] = signals[instance] or {}
    if not signals[instance][name] then
        local event = { callbacks = {} }
        function event:Connect(callback)
            table.insert(self.callbacks, callback)
            return { Disconnect = function() end }
        end
        function event:Fire(...)
            for _, callback in ipairs(self.callbacks) do callback(...) end
        end
        signals[instance][name] = event
    end
    return signals[instance][name]
end
for className, names in pairs({
    Players = { 'PlayerAdded', 'PlayerRemoving' },
    Player = { 'CharacterAdded', 'CharacterAppearanceLoaded' },
    ProximityPrompt = { 'Triggered' }, BasePart = { 'Touched' },
    Humanoid = { 'Died' }, NumberValue = { 'Changed' },
}) do
    for _, name in ipairs(names) do
        roblox.implementProperty(className, name, function(instance) return signal(instance, name) end)
    end
end
local invoke = {}
roblox.implementProperty('RemoteFunction', 'OnServerInvoke',
    function(instance) return invoke[instance] end,
    function(instance, callback) invoke[instance] = callback end)
local published = {}
roblox.implementMethod('RemoteEvent', 'FireClient', function(instance, player, payload)
    if instance.Name == 'State' then published[player] = payload end
end)
roblox.implementMethod('Instance', 'WaitForChild', function(instance, name)
    return instance:FindFirstChild(name)
end)
roblox.implementMethod('Model', 'GetPivot', function(instance)
    local part = instance:FindFirstChildWhichIsA('BasePart', true)
    return if part then part.CFrame else CFrame.identity
end)
roblox.implementMethod('Model', 'PivotTo', function(instance, transform)
    local root = instance:FindFirstChild('HumanoidRootPart')
    if root then root.Position = transform.Position; root.CFrame = transform end
end)
roblox.implementMethod('Humanoid', 'EquipTool', function(instance, tool) tool.Parent = instance.Parent end)
local services = {}
for _, name in ipairs({ 'Players', 'ReplicatedStorage', 'ServerScriptService' }) do
    services[name] = Instance.new(name)
end
local workspace = Instance.new('Workspace')
roblox.implementMethod('Players', 'GetPlayers', function(instance) return instance:GetChildren() end)
roblox.implementMethod('Players', 'GetPlayerFromCharacter', function(instance, character)
    for _, player in ipairs(instance:GetChildren()) do if player.Character == character then return player end end
    return nil
end)
services.TweenService = { Create = function(_, object, _, goals)
    local completed = signal(object, 'Completed')
    return { Completed = completed, Play = function()
        object.Value = goals.Value
        signal(object, 'Changed'):Fire(goals.Value)
        completed:Fire()
    end }
end }
local closeCallback
local game = {
    GetService = function(_, name) assert(services[name], 'Unexpected service ' .. name); return services[name] end,
    BindToClose = function(_, callback) closeCallback = callback end,
}
local moduleFolder = Instance.new('Folder'); moduleFolder.Name = 'Game'; moduleFolder.Parent = services.ServerScriptService
local shared = Instance.new('Folder'); shared.Name = 'Shared'; shared.Parent = services.ReplicatedStorage
local modules = {}
local environment = setmetatable({
    game = game, workspace = workspace, Instance = Instance, task = tasks,
    os = setmetatable({ clock = function() return now end }, { __index = os }),
    TweenInfo = { new = function() return {} end },
}, { __index = getfenv() })
for _, name in ipairs({ 'Enum', 'Vector3', 'CFrame', 'Color3', 'UDim', 'UDim2', 'Vector2' }) do
    environment[name] = roblox[name]
end
local function load(path)
    local chunk, problem = loadstring(fs.readFile(path), path)
    assert(chunk, problem)
    setfenv(chunk, environment)
    return chunk()
end
environment.require = function(module)
    assert(modules[module] ~= nil, 'Unexpected module ' .. tostring(module))
    return modules[module]
end
local function register(parent, name, value)
    local marker = Instance.new('ModuleScript'); marker.Name = name; marker.Parent = parent
    modules[marker] = value
end
local config = load('src/shared/Config.luau')
local economy = load('src/shared/Economy.luau')
local world = load('src/server/World.luau')
local originalBuild = world.build
local town
world.build = function(settings)
    town = originalBuild(settings)
    -- Lune stores CFrame/Position separately; Roblox derives Position at runtime.
    for _, part in ipairs(town.model:GetDescendants()) do
        if part:IsA('BasePart') then part.Position = part.CFrame.Position end
    end
    return town
end
register(shared, 'Config', config); register(shared, 'Economy', economy)
register(moduleFolder, 'World', world)
register(moduleFolder, 'Costume', load('src/server/Costume.luau'))
register(moduleFolder, 'ProfileStore', load('src/server/ProfileStore.luau'))
local script = Instance.new('Script'); script.Name = 'Game'; script.Parent = moduleFolder
local characterCounter = 0
local function addPlayer()
    characterCounter += 1
    local player = Instance.new('Player'); player.Name = 'Chef' .. characterCounter
    player.UserId = characterCounter; player.DisplayName = player.Name
    player.Parent = services.Players
    local character = Instance.new('Model'); character.Name = player.Name; character.Parent = workspace
    for _, name in ipairs({ 'HumanoidRootPart', 'Torso', 'Head', 'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg' }) do
        local part = Instance.new('Part'); part.Name = name; part.Size = Vector3.new(2, 2, 1)
        part.Position = Vector3.zero; part.Parent = character
    end
    local humanoid = Instance.new('Humanoid'); humanoid.Health = 100; humanoid.Parent = character
    local backpack = Instance.new('Backpack'); backpack.Parent = player
    player.Character = character
    signal(services.Players, 'PlayerAdded'):Fire(player)
    return player
end
local function trigger(player, prompt)
    advance(0.25)
    player.Character.HumanoidRootPart.Position = prompt.Parent.Position
    signal(prompt, 'Triggered'):Fire(player)
end
local function snapshot(player)
    return invoke[services.ReplicatedStorage.TycoonRemotes.GetState](player)
end
environment.script = script
load('src/server/Game.server.luau')
local player = addPlayer()
local other = addPlayer()
local plot = town.plots[1]
assert(snapshot(player).plotIndex == 1 and snapshot(other).plotIndex == 2)
assert(snapshot(player).cash == config.StartingCash)
advance(0.5)
assert(player.Character:FindFirstChild('SpongeChefCostume'))
print('PASS players get separate plots, starter money, and sponge costumes')

trigger(other, plot.grills[1].prompt)
assert(snapshot(player).grills[1].stage == 'Empty')
trigger(other, plot.upgradePrompts.secondGrill)
assert(not snapshot(player).upgrades.secondGrill and snapshot(other).cash == config.StartingCash)
print('PASS another player cannot use the owner grill or purchase pad')

local function cook(index)
    local station = plot.grills[index]
    trigger(player, station.prompt)
    assert(snapshot(player).grills[index].stage == 'Cooking')
    advance(config.CookSeconds)
    assert(snapshot(player).grills[index].stage == 'Flip')
    trigger(player, station.prompt)
    assert(snapshot(player).grills[index].stage == 'Finishing')
    advance(config.FinishSeconds)
    assert(snapshot(player).grills[index].stage == 'Ready')
end
cook(1)
trigger(player, plot.grills[1].prompt)
assert(snapshot(player).carrying and snapshot(player).grills[1].stage == 'Empty')
assert(player.Character:FindFirstChild('Krabby Patty'))
local cash = snapshot(player).cash
trigger(player, plot.servePrompt)
assert(not snapshot(player).carrying and snapshot(player).cash == cash + config.BaseBurgerValue)
assert(snapshot(player).burgersServed == 1 and not player.Character:FindFirstChild('Krabby Patty'))
trigger(player, plot.servePrompt)
assert(snapshot(player).cash == cash + config.BaseBurgerValue)
print('PASS cook, flip, finish, pickup, and serve pays exactly once')

-- Serve a second burger, then collect two $10 rewards to reach exactly $120.
cook(1)
trigger(player, plot.grills[1].prompt)
trigger(player, plot.servePrompt)
assert(snapshot(player).cash == 100)
local coin = town.coins[1]
for _ = 1, 2 do
    player.Character.HumanoidRootPart.Position = coin.Position
    signal(coin, 'Touched'):Fire(player.Character.HumanoidRootPart)
    local afterReward = snapshot(player).cash
    signal(coin, 'Touched'):Fire(player.Character.HumanoidRootPart)
    assert(snapshot(player).cash == afterReward)
    advance(config.CollectibleCooldown)
end
assert(snapshot(player).cash == config.Upgrades[1].cost)
print('PASS sand-dollar contact pays once per player cooldown')
trigger(player, plot.upgradePrompts.secondGrill)
assert(snapshot(player).cash == 0 and snapshot(player).upgrades.secondGrill)
assert(snapshot(player).grills[2].stage == 'Empty')
trigger(player, plot.upgradePrompts.secondGrill)
assert(snapshot(player).cash == 0)
print('PASS exact-funds purchase unlocks second grill without duplicate charge')

cook(1); cook(2)
trigger(player, plot.grills[1].prompt)
trigger(player, plot.grills[2].prompt)
assert(snapshot(player).carrying and snapshot(player).grills[2].stage == 'Ready')
local tools = 0
for _, child in ipairs(player.Character:GetChildren()) do if child:IsA('Tool') then tools += 1 end end
assert(tools == 1)
print('PASS carrying limit prevents duplicate pickups and preserves ready burger')

trigger(player, plot.servePrompt)
trigger(player, plot.grills[1].prompt)
assert(snapshot(player).grills[1].stage == 'Cooking')
trigger(player, plot.grills[2].prompt)
assert(snapshot(player).carrying and player.Character:FindFirstChild('Krabby Patty'))
local waiting
for _ = 1, 3 do waiting = addPlayer() end
assert(snapshot(waiting).plotIndex == nil)
signal(services.Players, 'PlayerRemoving'):Fire(player)
player.Parent = nil
assert(snapshot(player) == nil and snapshot(waiting).plotIndex == 1)
advance(config.CookSeconds + 1)
assert(snapshot(waiting).grills[1].stage == 'Empty')
assert(plot.grills[1].prompt.Enabled)
assert(not player.Character:FindFirstChild('Krabby Patty'))
print('PASS leaving clears held tools, transfers plot, and invalidates old cook timers')
assert(type(closeCallback) == 'function')
print('7 server-flow checks passed (mock services; not an engine playtest)')
