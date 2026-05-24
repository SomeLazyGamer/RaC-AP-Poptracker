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

-- AutoTracking for Poptracker
if PopVersion and PopVersion >= "0.18.0" then
    ScriptHost:LoadScript("scripts/autotracking.lua")
end