
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/setting_mapping.lua")

HINT_STATUS_MAPPING = {}
if Highlight then
	HINT_STATUS_MAPPING = {
		[20] = Highlight.Avoid,
		[40] = Highlight.None,
		[10] = Highlight.NoPriority,
		[0] = Highlight.Unspecified,
		[30] = Highlight.Priority,
	}
end

CUR_INDEX = -1
--SLOT_DATA = nil
GLOBAL_ITEMS = {}

SLOT_DATA = {}
OBTAINED_ITEMS = {}

PROGRESSIVE_PACKS = {
  [2] = "HeliPack",
  [3] = "ThrusterPack",
  [4] = "HydroPack"
}
PROG_PACK_ORDER = nil
PROGRESSIVE_HELMETS = {
  [5] = "SonicSummoner",
  [6] = "O2Mask",
  [7] = "PilotHelmet"
}
PROG_HELMET_ORDER = nil
PROGRESSIVE_HOVERBOARD = {
  [30] = "Hoverboard",
  [48] = "Zoomerator"
}
PROG_HOVER_ORDER = nil
PROGRESSIVE_BOOTS = {
  [28] = "Magneboots",
  [29] = "GrindBoots"
}
PROG_BOOTS_ORDER = nil
PROGRESSIVE_TRADE = {
  [35] = "Persuader",
  [49] = "Raritanium"
}
PROG_TRADE_ORDER = nil
PROGRESSIVE_NANO = {
  [52] = "PremiumNanotech",
  [53] = "UltraNanotech"
}
PROG_NANO_ORDER = nil
PROGRESSIVE_BOMB = {
  [10] = "BombGlove",
  [310] = "GoldBombGlove"
}
PROG_BOMB_ORDER = nil
PROGRESSIVE_BLAST = {
  [15] = "Blaster",
  [315] = "GoldBlaster"
}
PROG_BLAST_ORDER = nil
PROGRESSIVE_SUCK = {
  [9] = "SuckCannon",
  [309] = "GoldSuckCannon"
}
PROG_SUCK_ORDER = nil
PROGRESSIVE_PYRO = {
  [16] = "Pyrocitor",
  [316] = "GoldPyrocitor"
}
PROG_PYRO_ORDER = nil
PROGRESSIVE_DOOM = {
  [10] = "GloveofDoom",
  [310] = "GoldGloveofDoom"
}
PROG_DOOM_ORDER = nil
PROGRESSIVE_MINE = {
  [17] = "MineGlove",
  [317] = "GoldMineGlove"
}
PROG_MINE_ORDER = nil
PROGRESSIVE_DEV = {
  [11] = "Devastator",
  [311] = "GoldDevastator"
}
PROG_DEV_ORDER = nil
PROGRESSIVE_DECOY = {
  [25] = "DecoyGlove",
  [325] = "GoldDecoyGlove"
}
PROG_DECOY_ORDER = nil
PROGRESSIVE_TESLA = {
  [19] = "TeslaClaw",
  [319] = "GoldTeslaClaw"
}
PROG_TESLA_ORDER = nil
PROGRESSIVE_MORPH = {
  [21] = "Morph-o-Ray",
  [321] = "GoldMorph-o-Ray"
}
PROG_MORPH_ORDER = nil

-- gets the data storage key for hints for the current player
-- returns nil when not connected to AP
function getHintDataStorageKey()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getHintDataStorageKey while not connect to AP server")
		end
		return nil
	end
	return string.format("_read_hints_%s_%s", Archipelago.TeamNumber, Archipelago.PlayerNumber)
end

-- resets an item to its initial state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = false
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			obj.CurrentStage = 0
			obj.Active = false
		elseif item_type == "consumable" then
			obj.AcquiredCount = 0
		elseif item_type == "custom" then
		-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: tried to reset static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("resetItem: could not find item object for code %s", item_code))
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type, multiplier)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
		elseif item_type == "custom" then
		-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
-- put any code here that slot_data should affect (toggling setting items for example)
	PROG_PACK_ORDER = slot_data["progressive_packs_order"]
	PROG_HELMET_ORDER = slot_data["progressive_helmets_order"]
	PROG_BOOTS_ORDER = slot_data["progressive_boots_order"]
	PROG_HOVER_ORDER = slot_data["progressive_hoverboard_order"]
	PROG_TRADE_ORDER = slot_data["progressive_raritanium_order"]
	PROG_NANO_ORDER = slot_data["progressive_nanotech_order"]
	PROG_BOMB_ORDER = slot_data["progressive_bomb_glove_order"]
	PROG_PYRO_ORDER = slot_data["progressive_pyrocitor_order"]
	PROG_BLAST_ORDER = slot_data["progressive_blaster_order"]
	PROG_DOOM_ORDER = slot_data["progressive_glove_of_doom_order"]
	PROG_MINE_ORDER = slot_data["progressive_mine_glove_order"]
	PROG_SUCK_ORDER = slot_data["progressive_suck_cannon_order"]
	PROG_DEV_ORDER = slot_data["progressive_devastator_order"]
	PROG_DECOY_ORDER = slot_data["progressive_decoy_glove_order"]
	PROG_TESLA_ORDER = slot_data["progressive_tesla_claw_order"]
	PROG_MORPH_ORDER = slot_data["progressive_morph_o_ray_order"]
end

function onClear(slot_data)
-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end
	CUR_INDEX = -1
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
							if obj.Highlight then
								obj.Highlight = Highlight.None
							end
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
					-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end
    if slot_data["shuffle_gold_bolts"] then
        local obj = Tracker:FindObjectForCode("BoltSanity")
        local stage = slot_data["shuffle_gold_bolts"]
        if obj then
            obj.CurrentStage = stage
        end
    end

	apply_slot_data(slot_data)
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}
	-- manually run snes interface functions after onClear in case we need to update them (i.e. because they need slot_data)
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
	-- add snes interface functions here
	end
	-- setup data storage tracking for hint tracking
	local data_strorage_keys = {}
	if PopVersion >= "0.32.0" then
		data_strorage_keys = { getHintDataStorageKey() }
	end
	-- subscribes to the data storage keys for updates
	-- triggers callback in the SetNotify handler on update
	Archipelago:SetNotify(data_strorage_keys)
	-- gets the current value for the data storage keys
	-- triggers callback in the Retrieved handler when result is received
	Archipelago:Get(data_strorage_keys)
  Tracker.BulkUpdate = false

end

function handleProgressiveOptions(item_code)

	if item_code == "ProgPack" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local pack = PROGRESSIVE_PACKS[PROG_PACK_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, pack))
    	Tracker:FindObjectForCode(pack).Active = true
	end
	if item_code == "ProgHelmet" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local hat = PROGRESSIVE_HELMETS[PROG_HELMET_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, hat))
    	Tracker:FindObjectForCode(hat).Active = true
	end
	if item_code == "ProgBoots" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local boot = PROGRESSIVE_BOOTS[PROG_BOOTS_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, boot))
    	Tracker:FindObjectForCode(boot).Active = true
	end
	if item_code == "ProgHover" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local hover = PROGRESSIVE_HOVERBOARD[PROG_HOVER_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, hover))
    	Tracker:FindObjectForCode(hover).Active = true
	end
	if item_code == "ProgTrade" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local trade = PROGRESSIVE_TRADE[PROG_TRADE_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, trade))
    	Tracker:FindObjectForCode(trade).Active = true
	end
	if item_code == "ProgNano" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local nano = PROGRESSIVE_NANO[PROG_NANO_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, nano))
    	Tracker:FindObjectForCode(nano).Active = true
	end
	if item_code == "ProgBomb" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local bomb = PROGRESSIVE_BOMB[PROG_BOMB_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, bomb))
    	Tracker:FindObjectForCode(bomb).Active = true
	end
	if item_code == "ProgBlast" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local blast = PROGRESSIVE_BLAST[PROG_BLAST_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, blast))
    	Tracker:FindObjectForCode(blast).Active = true
	end
	if item_code == "ProgPyro" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local pyro = PROGRESSIVE_PYRO[PROG_PYRO_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, pyro))
    	Tracker:FindObjectForCode(pyro).Active = true
	end
	if item_code == "ProgDoom" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local doom = PROGRESSIVE_DOOM[PROG_DOOM_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, doom))
    	Tracker:FindObjectForCode(doom).Active = true
	end
	if item_code == "ProgMine" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local mine = PROGRESSIVE_MINE[PROG_MINE_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, mine))
    	Tracker:FindObjectForCode(mine).Active = true
	end
	if item_code == "ProgSuck" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local suck = PROGRESSIVE_SUCK[PROG_SUCK_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, suck))
    	Tracker:FindObjectForCode(suck).Active = true
	end
	if item_code == "ProgDev" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local dev = PROGRESSIVE_DEV[PROG_DEV_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, dev))
    	Tracker:FindObjectForCode(dev).Active = true
	end
	if item_code == "ProgDecoy" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local decoy = PROGRESSIVE_DECOY[PROG_DECOY_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, decoy))
    	Tracker:FindObjectForCode(decoy).Active = true
	end
	if item_code == "ProgTesla" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local tesla = PROGRESSIVE_TELSA[PROG_TESLA_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, tesla))
    	Tracker:FindObjectForCode(tesla).Active = true
	end
	if item_code == "ProgMorph" then
    	local obj = Tracker:FindObjectForCode(item_code)
    	local morph = PROGRESSIVE_MORPH[PROG_MORPH_ORDER[obj.CurrentStage]]
    	print(string.format("handleProgressiveOptions: got %s at stage %d, activating item %s", item_code, obj.CurrentStage, morph))
    	Tracker:FindObjectForCode(morph).Active = true
	end
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end
	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			local multiplier = item_table[3] or 1
			if item_code then
				incrementItem(item_code, item_type, multiplier)
				handleProgressiveOptions(item_code)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping item_table with no item_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onClear: skipping empty item_table"))
		end
	end
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
	-- track local items via snes interface
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
	-- add snes interface functions for local item tracking here
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						obj.AvailableChestCount = obj.AvailableChestCount - 1
					else
					-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
-- your code goes here
end

-- called whenever Archipelago:Get returns data from the data storage or
-- whenever a subscribed to (via Archipelago:SetNotify) key in data storgae is updated
-- oldValue might be nil (always nil for "_read" prefixed keys and via retrieved handler (from Archipelago:Get))
--if you plan to only use the hints key, you can remove this if

-- called whenever the hints key in data storage updated
-- NOTE: this should correctly handle having multiple mapped locations in a section.
--       if you only map sections 1 to 1 you can simplfy this. for an example see
--       https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/archipelago.lua
function onHintsUpdate(hints)
-- Highlight is only supported since version 0.32.0
	if PopVersion < "0.32.0" or not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local player_number = Archipelago.PlayerNumber
	-- get all new highlight values per section
	local sections_to_update = {}
	for _, hint in ipairs(hints) do
	-- we only care about hints in our world
		if hint.finding_player == player_number then
			updateHint(hint, sections_to_update)
		end
	end
	-- update the sections
	for location_code, highlight_code in pairs(sections_to_update) do
	-- find the location object
		local obj = Tracker:FindObjectForCode(location_code)
		-- check if we got the location and if it supports Highlight
		if obj and obj.Highlight then
			obj.Highlight = highlight_code
		end
	end
end

-- update section highlight based on the hint
function updateHint(hint, sections_to_update)
-- get the highlight enum value for the hint status
	local hint_status = hint.status
	local highlight_code = nil
	if hint_status then
		highlight_code = HINT_STATUS_MAPPING[hint_status]
	end
	if not highlight_code then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status,
				hint.location))
		end
		-- try to "recover" by checking hint.found (older AP versions without hint.status)
		if hint.found == true then
			highlight_code = Highlight.None
		elseif hint.found == false then
			highlight_code = Highlight.Unspecified
		else
			return
		end
	end
	-- get the location mapping for the location id
	local mapping_entry = LOCATION_MAPPING[hint.location]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: could not find location mapping for id %s", hint.location))
		end
		return
	end
	--get the "highest" highlight value pre section
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			-- skip hosted items, they don't support Highlight
			if location_code and location_code:sub(1, 1) == "@" then
			-- see if we already set a Highlight for this section
				local existing_highlight_code = sections_to_update[location_code]
				if existing_highlight_code then
				-- make sure we only replace None or "increase" the highlight but never overwrite with None
				-- this so sections with mulitple mapped locations show the "highest" Highlight and
				-- only show no Highlight when all hints are found
					if existing_highlight_code == Highlight.None or (existing_highlight_code < highlight_code and highlight_code ~= Highlight.None) then
						sections_to_update[location_code] = highlight_code
					end
				else
					sections_to_update[location_code] = highlight_code
				end
			end
		end
	end
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)

