-- All prices and game balance live here; no asset IDs or paid services needed.
local Config = {}

Config.Title = "Krusty Krab Tycoon"
Config.StartingCash = 50
Config.BaseBurgerValue = 25
Config.CookSeconds = 3
Config.FinishSeconds = 2
Config.MaxPlots = 4
Config.CollectibleCash = 10
Config.CollectibleCooldown = 30
Config.DataStoreName = "KrustyKrabTycoon_v1"
-- Off for the prototype. Enable only after publishing and testing DataStores.
Config.PersistenceEnabled = false

Config.Upgrades = {
    { id = "secondGrill", name = "Second grill", cost = 120,
      description = "Cook two burgers at once.", requires = nil },
    { id = "speedyGrill", name = "Quick-flip grill", cost = 180,
      description = "Cook both sides 35% faster.", requires = "secondGrill" },
    { id = "secretSauce", name = "Secret sauce", cost = 260,
      description = "Earn $12 more for every burger.", requires = "speedyGrill" },
    { id = "diningRoom", name = "Dining room", cost = 380,
      description = "Add tables and $6 tips.", requires = "secretSauce" },
    { id = "neonSign", name = "Neon restaurant sign", cost = 550,
      description = "Light up your restaurant. Tips increase by $4.", requires = "diningRoom" },
    { id = "jellyfishGarden", name = "Jellyfish garden", cost = 750,
      description = "Add a garden and $4 in extra tips.", requires = "neonSign" },
    { id = "goldenSpatula", name = "Golden spatula", cost = 1100,
      description = "The ultimate chef upgrade. Earn $18 extra per burger.", requires = "jellyfishGarden" },
}

function Config.getUpgrade(id)
    for _, upgrade in ipairs(Config.Upgrades) do
        if upgrade.id == id then
            return upgrade
        end
    end
    return nil
end

return Config
