-- Compile every Luau source file without executing Roblox-only services.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local count = 0

local function check(directory)
    for _, name in ipairs(fs.readDir(directory)) do
        local path = directory .. "/" .. name
        if fs.isDir(path) then
            check(path)
        elseif name:match("%.luau$") then
            luau.load(fs.readFile(path), { debugName = path })
            count += 1
        end
    end
end

for _, directory in ipairs({ "src", "tests", "scripts" }) do
    check(directory)
end
print("Compiled " .. count .. " Luau files successfully.")
