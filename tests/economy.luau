local Config = require("../src/shared/Config")
local Economy = require("../src/shared/Economy")

local passed = 0
local failed = 0

local function equal(actual, expected, message)
    assert(actual == expected, (message or "Unexpected value")
        .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function test(name, callback)
    local ok, problem = pcall(callback)
    if ok then
        passed += 1
        print("PASS " .. name)
    else
        failed += 1
        warn("FAIL " .. name .. ": " .. tostring(problem))
    end
end

local function fundedProfile()
    local profile = Economy.newProfile(Config)
    profile.cash = 10000
    return profile
end

local function rejectedPurchase(profile, id)
    local before = profile.cash
    local success, message = Economy.purchase(Config, profile, id)
    equal(success, false)
    equal(profile.cash, before, "Rejected purchase must not debit cash")
    assert(type(message) == "string" and #message > 0, "Expected a useful rejection message")
end

test("new players get starting cash and independent profiles", function()
    local first = Economy.newProfile(Config)
    local second = Economy.newProfile(Config)
    equal(first.cash, 50)
    equal(first.burgersServed, 0)
    equal(next(first.upgrades), nil)
    first.upgrades.secondGrill = true
    equal(second.upgrades.secondGrill, nil)
end)

test("serving pays the base price and increments burgers served", function()
    local profile = Economy.newProfile(Config)
    equal(Economy.serve(Config, profile), 25)
    equal(profile.cash, 75)
    equal(profile.burgersServed, 1)
    equal(Economy.serve(Config, profile), 25)
    equal(profile.cash, 100)
    equal(profile.burgersServed, 2)
end)

test("purchase with exact funds unlocks upgrade and debits exactly once", function()
    local profile = Economy.newProfile(Config)
    profile.cash = 120
    local success, message = Economy.purchase(Config, profile, "secondGrill")
    equal(success, true)
    equal(profile.cash, 0)
    equal(profile.upgrades.secondGrill, true)
    assert(type(message) == "string" and #message > 0)
end)

test("unknown upgrades are rejected without spending cash", function()
    local profile = fundedProfile()
    rejectedPurchase(profile, "unlimitedBurgers")
    equal(next(profile.upgrades), nil)
end)

test("insufficient funds leave the upgrade locked and cash unchanged", function()
    local profile = Economy.newProfile(Config)
    rejectedPurchase(profile, "secondGrill")
    equal(profile.upgrades.secondGrill, nil)
end)

test("missing prerequisite blocks an otherwise affordable purchase", function()
    local profile = fundedProfile()
    rejectedPurchase(profile, "speedyGrill")
    equal(profile.upgrades.speedyGrill, nil)
end)

test("duplicate purchases cannot charge the player again", function()
    local profile = fundedProfile()
    assert(Economy.purchase(Config, profile, "secondGrill"))
    rejectedPurchase(profile, "secondGrill")
    equal(profile.upgrades.secondGrill, true)
end)

test("every upgrade purchases in order with exact cumulative debit", function()
    local profile = fundedProfile()
    local spent = 0
    for _, upgrade in ipairs(Config.Upgrades) do
        local success = Economy.purchase(Config, profile, upgrade.id)
        equal(success, true, upgrade.id .. " should unlock")
        spent += upgrade.cost
        equal(profile.cash, 10000 - spent)
        equal(profile.upgrades[upgrade.id], true)
    end
    equal(spent, 3340)
end)

test("payout bonuses build to 69 dollars per burger", function()
    local profile = fundedProfile()
    local payouts = { 25, 25, 37, 43, 47, 51, 69 }
    for index, upgrade in ipairs(Config.Upgrades) do
        assert(Economy.purchase(Config, profile, upgrade.id))
        equal(Economy.burgerValue(Config, profile), payouts[index], upgrade.id .. " payout")
    end
    local before = profile.cash
    equal(Economy.serve(Config, profile), 69)
    equal(profile.cash, before + 69)
    equal(profile.burgersServed, 1)
end)

test("quick-flip upgrade reduces both cooking stages to 65 percent", function()
    local profile = fundedProfile()
    equal(Economy.cookMultiplier(profile), 1)
    assert(Economy.purchase(Config, profile, "secondGrill"))
    equal(Economy.cookMultiplier(profile), 1)
    assert(Economy.purchase(Config, profile, "speedyGrill"))
    equal(Economy.cookMultiplier(profile), 0.65)
    assert(math.abs(Config.CookSeconds * Economy.cookMultiplier(profile) - 1.95) < 1e-9)
    assert(math.abs(Config.FinishSeconds * Economy.cookMultiplier(profile) - 1.3) < 1e-9)
end)

test("missing or malformed saved profiles use safe defaults", function()
    for _, value in ipairs({ false, "not a profile", 42, {} }) do
        local profile = Economy.sanitizeProfile(Config, value)
        equal(profile.cash, 50)
        equal(profile.burgersServed, 0)
        equal(next(profile.upgrades), nil)
    end
    equal(Economy.sanitizeProfile(Config, nil).cash, 50)
end)

test("finite saved counters are floored and bounded", function()
    local profile = Economy.sanitizeProfile(Config, { cash = 123.99, burgersServed = 8.8 })
    equal(profile.cash, 123)
    equal(profile.burgersServed, 8)
    profile = Economy.sanitizeProfile(Config, { cash = -50, burgersServed = -4 })
    equal(profile.cash, 0)
    equal(profile.burgersServed, 0)
    profile = Economy.sanitizeProfile(Config, { cash = 2e12, burgersServed = 3e12 })
    equal(profile.cash, 1000000000)
    equal(profile.burgersServed, 1000000000)
end)

test("infinity NaN and nonnumeric saved counters cannot enter the economy", function()
    for _, value in ipairs({ math.huge, -math.huge, 0 / 0, "100", true }) do
        local profile = Economy.sanitizeProfile(Config, { cash = value, burgersServed = value })
        equal(profile.cash, 50)
        equal(profile.burgersServed, 0)
    end
end)

test("unknown and truthy nonboolean saved upgrades are discarded", function()
    local profile = Economy.sanitizeProfile(Config, {
        upgrades = { secondGrill = "true", speedyGrill = true, unknownUpgrade = true },
    })
    equal(next(profile.upgrades), nil)
end)

test("saved upgrades cannot skip prerequisite chains", function()
    local profile = Economy.sanitizeProfile(Config, {
        upgrades = { secondGrill = true, secretSauce = true, diningRoom = true, goldenSpatula = true },
    })
    equal(profile.upgrades.secondGrill, true)
    equal(profile.upgrades.speedyGrill, nil)
    equal(profile.upgrades.secretSauce, nil)
    equal(profile.upgrades.diningRoom, nil)
    equal(profile.upgrades.goldenSpatula, nil)
    equal(Economy.burgerValue(Config, profile), 25)
end)

test("valid saved upgrades survive regardless of stored insertion order", function()
    local storedUpgrades = {}
    for index = #Config.Upgrades, 1, -1 do
        storedUpgrades[Config.Upgrades[index].id] = true
    end
    local profile = Economy.sanitizeProfile(Config, {
        cash = 777, burgersServed = 12, upgrades = storedUpgrades,
    })
    equal(profile.cash, 777)
    equal(profile.burgersServed, 12)
    for _, upgrade in ipairs(Config.Upgrades) do
        equal(profile.upgrades[upgrade.id], true)
    end
    equal(Economy.burgerValue(Config, profile), 69)
end)

print(string.format("\n%d passed; %d failed", passed, failed))
assert(failed == 0, "Economy test failures")
