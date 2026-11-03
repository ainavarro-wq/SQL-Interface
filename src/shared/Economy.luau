-- Pure functions shared by the server and the standalone Lune tests.
local Economy = {}

function Economy.newProfile(config)
    return { cash = config.StartingCash, burgersServed = 0, upgrades = {} }
end

function Economy.sanitizeProfile(config, stored)
    local profile = Economy.newProfile(config)
    if type(stored) ~= "table" then
        return profile
    end
    local function safeInteger(value, fallback)
        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
            return fallback
        end
        return math.clamp(math.floor(value), 0, 1000000000)
    end
    profile.cash = safeInteger(stored.cash, config.StartingCash)
    profile.burgersServed = safeInteger(stored.burgersServed, 0)
    if type(stored.upgrades) == "table" then
        for _, upgrade in ipairs(config.Upgrades) do
            if stored.upgrades[upgrade.id] == true
                and (not upgrade.requires or profile.upgrades[upgrade.requires]) then
                profile.upgrades[upgrade.id] = true
            end
        end
    end
    return profile
end

function Economy.purchase(config, profile, id)
    local upgrade = config.getUpgrade(id)
    if not upgrade then
        return false, "That upgrade does not exist."
    end
    if profile.upgrades[id] then
        return false, "You already own this upgrade."
    end
    if upgrade.requires and not profile.upgrades[upgrade.requires] then
        return false, "Buy the previous upgrade first."
    end
    if profile.cash < upgrade.cost then
        return false, "You need $" .. tostring(upgrade.cost - profile.cash) .. " more."
    end
    profile.cash -= upgrade.cost
    profile.upgrades[id] = true
    return true, upgrade.name .. " unlocked!"
end

function Economy.burgerValue(config, profile)
    local value = config.BaseBurgerValue
    local upgrades = profile.upgrades
    if upgrades.secretSauce then value += 12 end
    if upgrades.diningRoom then value += 6 end
    if upgrades.neonSign then value += 4 end
    if upgrades.jellyfishGarden then value += 4 end
    if upgrades.goldenSpatula then value += 18 end
    return value
end

function Economy.cookMultiplier(profile)
    return if profile.upgrades.speedyGrill then 0.65 else 1
end

function Economy.serve(config, profile)
    local earned = Economy.burgerValue(config, profile)
    profile.cash += earned
    profile.burgersServed += 1
    return earned
end

return Economy
