-- Run from the repository root: lune run scripts/build.luau
-- Rojo assembles the scripts; Lune bakes the same procedural map used at runtime
-- so opening the place in Studio shows a town before Play is pressed.
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local Config = require("../src/shared/Config")

assert(fs.isFile("default.project.json"), "Run this script from the repository root.")
assert(fs.isFile("src/server/World.luau"), "The procedural world module is missing.")

local function findRojo()
    local candidates = {}
    if process.env.TYCOON_ROJO and process.env.TYCOON_ROJO ~= "" then
        table.insert(candidates, process.env.TYCOON_ROJO)
    end
    table.insert(candidates, "rojo")
    -- The onboarding installer uses this location; normal desktop installs can
    -- put Rojo on PATH or select an executable through TYCOON_ROJO instead.
    table.insert(candidates, "/workspace/.tools/rojo")
    for _, executable in ipairs(candidates) do
        local ok, result = pcall(process.exec, executable, { "--version" })
        if ok and result.ok then
            print((result.stdout:gsub("%s+$", "")))
            return executable
        end
    end
    error("Rojo was not found. Install it, add it to PATH, or set TYCOON_ROJO.")
end

local function verifyPlace(place)
    local town = place:GetService("Workspace"):FindFirstChild("BurgerTown")
    assert(town and town:IsA("Model"), "The baked town is missing.")
    for index = 1, Config.MaxPlots do
        assert(town:FindFirstChild("Restaurant plot " .. tostring(index)), "A restaurant plot is missing.")
    end
    local shared = place:GetService("ReplicatedStorage"):FindFirstChild("Shared")
    assert(shared, "Shared modules are missing.")
    for _, name in ipairs({ "Config", "Economy" }) do
        local module = shared:FindFirstChild(name)
        assert(module and module:IsA("ModuleScript") and #module.Source > 0, name .. " source is missing.")
    end
    local serverFolder = place:GetService("ServerScriptService"):FindFirstChild("Game")
    assert(serverFolder, "The server source folder is missing.")
    local gameScript = serverFolder:FindFirstChild("Game")
    assert(gameScript and gameScript:IsA("Script") and #gameScript.Source > 0, "The server entry point is missing.")
    for _, name in ipairs({ "World", "Costume", "ProfileStore" }) do
        local module = serverFolder:FindFirstChild(name)
        assert(module and module:IsA("ModuleScript") and #module.Source > 0, name .. " source is missing.")
    end
    local clientScripts = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
    local interfaceFolder = clientScripts and clientScripts:FindFirstChild("Interface")
    local interfaceScript = interfaceFolder and interfaceFolder:FindFirstChild("Interface")
    assert(interfaceScript and interfaceScript:IsA("LocalScript") and #interfaceScript.Source > 0,
        "The client interface source is missing.")
    return town
end

if not fs.isDir("build") then fs.writeDir("build") end
local rojo = findRojo()
local result = process.exec(rojo, {
    "build", "default.project.json", "-o", "build/rojo-unbaked.rbxlx",
})
if not result.ok then
    error("Rojo build failed (exit " .. tostring(result.code) .. "):\n" .. result.stderr .. result.stdout)
end
print((result.stdout:gsub("%s+$", "")))

local place = roblox.deserializePlace(fs.readFile("build/rojo-unbaked.rbxlx"))
local workspace = place:GetService("Workspace")
local compileWorld, compileError = loadstring(fs.readFile("src/server/World.luau"), "@src/server/World.luau")
assert(compileWorld, compileError)

-- Lune provides Roblox datatypes and editable instances, but no running game
-- services. The build only needs a harmless TweenService placeholder; actual
-- burger animations still use the real service when Studio runs the scripts.
local environment = setmetatable({
    workspace = workspace,
    game = {
        GetService = function(_, name)
            assert(name == "TweenService", "The edit-mode world requested an unsupported service: " .. name)
            return {}
        end,
    },
    Instance = roblox.Instance,
    CFrame = roblox.CFrame,
    Vector3 = roblox.Vector3,
    Color3 = roblox.Color3,
    UDim = roblox.UDim,
    UDim2 = roblox.UDim2,
    Enum = roblox.Enum,
}, { __index = getfenv() })
setfenv(compileWorld, environment)
local World = compileWorld()
local world = World.build(Config)
assert(#world.plots == Config.MaxPlots, "The world did not generate all restaurant plots.")
assert(#world.coins > 0, "The world did not generate free-roam collectibles.")

-- Lune's reflection layer keeps the legacy Font enum assignment separately
-- from FontFace. Supply its modern datatype explicitly before serialization.
for _, instance in ipairs(world.model:GetDescendants()) do
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        instance.FontFace = roblox.Font.fromEnum(instance.Font)
    end
end

local camera = workspace:FindFirstChildOfClass("Camera") or roblox.Instance.new("Camera")
camera.Name = "Camera"
camera.CFrame = roblox.CFrame.lookAt(roblox.Vector3.new(170, 150, -180), roblox.Vector3.new(0, 0, 0))
camera.Focus = roblox.CFrame.new(0, 0, 0)
camera.Parent = workspace
workspace.CurrentCamera = camera
-- Keep the default camera type: the game's normal third-person camera must
-- take over when a player spawns rather than remaining Scriptable.

local town = verifyPlace(place)
-- serializePlace's second parameter is a boolean: true writes XML (.rbxlx),
-- false writes Roblox's binary place format (.rbxl).
local xml = roblox.serializePlace(place, true)
local binary = roblox.serializePlace(place, false)
assert(xml:find("<roblox", 1, true), "XML place serialization failed.")
assert(binary:sub(1, 8) == "<roblox!", "Binary place serialization failed.")
verifyPlace(roblox.deserializePlace(xml))
verifyPlace(roblox.deserializePlace(binary))
fs.writeFile("build/KrustyKrabTycoon.rbxlx", xml)
fs.writeFile("build/KrustyKrabTycoon.rbxl", binary)
-- Keep a ready-to-open Studio place beside the sources for players who do not
-- have Rojo or Lune installed. The source modules remain authoritative: rebuild
-- this snapshot after changing gameplay, UI, or the procedural map.
if not table.find(process.args, "--no-snapshot") then
    fs.writeFile("KrustyKrabTycoon.rbxlx", xml)
end
print("Baked " .. tostring(#world.plots) .. " restaurants, " .. tostring(#world.coins)
    .. " collectibles, and " .. tostring(#town:GetDescendants()) .. " map instances.")
print("Verified scripts and map after XML and binary round trips.")
print("Built build/KrustyKrabTycoon.rbxlx (" .. tostring(#xml) .. " bytes)")
print("Built build/KrustyKrabTycoon.rbxl (" .. tostring(#binary) .. " bytes)")
if not table.find(process.args, "--no-snapshot") then
    print("Updated KrustyKrabTycoon.rbxlx (ready to open in Roblox Studio)")
end
