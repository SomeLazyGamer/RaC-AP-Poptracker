ENABLE_DEBUG_LOG = true
Tracker:AddItems("items/items.json")
ScriptHost:LoadScript("scripts/utils.lua")

Tracker:AddMaps("maps/maps.json")

-- Layout
Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/tabs.json")
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")
Tracker:AddLayouts("layouts/planets.json")
Tracker:AddLayouts("layouts/settings.json")
Tracker:AddLayouts("layouts/weapons.json")

-- Locations
ScriptHost:LoadScript("scripts/locations_import.lua")

print("------------------------DEBUG-----------------------")
-- Table of All Planets
Planets = {
    "Novalis",
    "Kerwan",
	"Aridia",
	"Eudora",
    "Blarg",
    "Rilgar",
    "Umbris",
    "Batalia",
    "Orxon",
	"Gaspar",
	"Pokitaru",
    "Hoven",
    "Gemlik",
    "Oltanis",
    "Quartu",
    "Kalebo III",
	"Fleet",
	"Veldin"
}
print("Planet list: " .. Planets[1])
for _, name in pairs(Planets) do
---@type JsonItem
---@diagnostic disable-next-line: assign-type-mismatch
	local infobot = Tracker:FindObjectForCode(name)
	print("Checking: " .. name)
	infobot.BadgeText = string.sub(name, 1, 10)
	infobot:SetOverlayFontSize(12)
	infobot:SetOverlayAlign("center")
end

-- AutoTracking for Poptracker
if PopVersion and PopVersion >= "0.18.0" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
end