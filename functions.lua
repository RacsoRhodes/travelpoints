--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.3                            2015-03-24
--
-- By Racso Rhodes
--
-- travelpoints/functions.lua
--
--------------------------------------------------------------------------------
-- License of source code, textures and sounds: WTFPL V2
--------------------------------------------------------------------------------
-- Copyright (C) 2013-2015 Racso Rhodes <racsorhodes@gmail.com>
-- This work is free. You can redistribute it and/or modify it under the
-- terms of the Do What The Fuck You Want To Public License, Version 2,
-- as published by Sam Hocevar. See the COPYING file for more details.
--------------------------------------------------------------------------------
-- TOC
--------------------------------------------------------------------------------
--
-- Functions
--
--		travelpoints.default_restrictions()
--		travelpoints.get_duration()
--		travelpoints.get_formspec()
--		travelpoints.get_infotext()
--		travelpoints.get_location()
--		travelpoints.get_pad_modes()
--		travelpoints.get_textlist_index()
--		travelpoints.get_travelpoints_array()
--		travelpoints.get_travelpoints_table()
--		travelpoints.get_world_restrictions()
--		travelpoints.is_empty()
--		travelpoints.player_can_use_pad()
--		travelpoints.player_exists()
--		travelpoints.player_in_players()
--		travelpoints.print_notice()
--		travelpoints.save_travelpoints_table()
--		travelpoints.save_world_restrictions()
--		travelpoints.swap_node()
--		travelpoints.validate_config()
--		travelpoints.validate_desc()
--		travelpoints.validate_restriction_value()
--		travelpoints.validate_title()
--		travelpoints.travelpad_log()
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

--[Default Restrictions]--------------------------------------------------------
--
--	Returns table of default restriction values for overriding bad values in
--	config.lua.
--
function travelpoints.default_restrictions(restriction)

	-- Initialize table
	local restrictions = {}
	
	-- Set default values.
	restrictions.max_travelpoints = 35
	restrictions.max_travelpads = 25
	restrictions.cooldown = 5*60
	restrictions.clear_back_pos = 0
	
	return restrictions[restriction]

end

--[Get Duration]----------------------------------------------------------------
--
--	Returns a duration of given precision for the given seconds.
--
function travelpoints.get_duration(seconds, precision)

	local precision = precision or 0
	local years = math.floor(seconds / 60 / 60 / 24 / 365)
	local days = math.floor(seconds / 60 / 60 / 24 % 365)
	local hours = math.floor(seconds / 60 / 60 % 24)
	local minutes = math.floor(seconds / 60 % 60)
	local seconds = seconds % 60
	local count = 0
	local t
	local duration = {}

	--[Years]-------------------------------------------------------------------

	if years > 0 then
		if precision == 0 then
			count = count + 1
			if years > 1 then
				t = years .. " years"
			else
				t = "1 year"
			end
			table.insert(duration, t)
		end
	end

	--[Days]--------------------------------------------------------------------

	if days > 0 then
		if ( precision == 0 ) or ( count < precision ) then
			count = count + 1
			if ( days > 1 ) then
				t =  days .. " days"
			else
				t = "1 day"
			end
			table.insert(duration, t)
		end
	end

	--[Hours]-------------------------------------------------------------------

	if hours > 0 then
		if ( precision == 0 ) or ( count < precision ) then
			count = count + 1
			if hours > 1 then
				t = hours .. " hours"
			else
				t = "1 hour"
			end
			table.insert(duration, t)
		end
	end

	--[Minutes]------------------------------------------------------------------

	if minutes > 0 then
		if ( precision == 0 ) or ( count < precision ) then
			count = count + 1
			if minutes > 1 then
				t = minutes .. " minutes"
			else
				t = "1 minute"
			end
			table.insert(duration, t)
		end
	end

	--[Seconds]-----------------------------------------------------------------

	if seconds > 0 then
		if ( precision == 0 ) or ( count < precision ) then
			count = count + 1
			if seconds > 1 then
				t = seconds .. " seconds"
			else
				t = " 1 second"
			end
			table.insert(duration, t)
		end
	end

	--[Finalize and Return]-----------------------------------------------------

	-- Build duration string and return.
	if #duration > 0 then
		if #duration > 2 then
			local d = ""
			-- Step through array to add punctuation.
			for key, value in ipairs(duration) do
				if key == #duration - 1 then
					d = d .. value .. ", and "
				elseif key == #duration then
					d = d .. " " .. value
				else
					d = d .. value .. ", "
				end
			end
			duration = d
		else
			duration = table.concat(duration, ", and ")
		end
		return duration
	else
		return "No duration"
	end
	
end

--[Get Formspec]----------------------------------------------------------------
--
--	Build formspec for travelpoints:transporter_pad/_active.
--
function travelpoints.get_formspec(meta)

	-- Pull metadata.
	local title = meta:get_string("title")
	local destination = meta:get_string("destination")
	local timestamp = meta:get_int("timestamp")
	local modstamp = meta:get_int("modstamp")
	local travelpoints_array = minetest.deserialize(meta:get_string("travelpoints_array"))
	local tp_index = meta:get_int("tp_index")
	local tp_count = ""
	local mode_index = meta:get_int("mode_index")
	local players = minetest.deserialize(meta:get_string("players"))

	-- Get travelpoint count.
	if #travelpoints_array > 1 then
		tp_count = #travelpoints_array - 1
	end

	-- Convert travelpoints_array to string.
	local tp_string = table.concat(travelpoints_array, ",")

	-- Set status
	local status
	if (title ~= "") and (destination ~= "") then
		status = "Destination: " .. title .. " " .. destination
	else
		status = "Offline"
	end

	-- Set last_modified
	local last_modified
	if modstamp > 0 then
		last_modified = os.date("%Y-%m-%d at %I:%M:%S %p", modstamp)
	else
		last_modified = "never"
	end

	local formspec = ""

	formspec = formspec .. "size[10,6.8]"
	formspec = formspec .. "label[0.1,0.0;" .. status .. "]"
	formspec = formspec .. "box[-0.28,0.6;10.37,0.05;#FFFFFF]"
	formspec = formspec .. "label[0.1,0.7;Available Travelpoints: " .. tp_count  .."]"
	formspec = formspec .. "textlist[0.1,1.2;5.7,3.6;travelpoint;" .. tp_string .. ";" .. tp_index .. "]"
	formspec = formspec .. "button[0.1,4.83;2.9,1;list_travelpoints;List Travelpoints]"
	formspec = formspec .. "button_exit[3.15,4.83;2.9,1;unset_destination;Unset Destination]"
	formspec = formspec .. "label[2.5,5.95;Placed on " .. os.date("%Y-%m-%d", timestamp) .. "]"
	formspec = formspec .. "button_exit[0.1,5.65;2,1;save;Save]"
	formspec = formspec .. "label[0.1,6.5;Last Modified: " .. last_modified .. "]"
	
	-- Multiplayer fields.
	if not minetest.is_singleplayer() then

		formspec = formspec .. "label[6.2,0.7;Pad Usage Mode]"
		formspec = formspec .. "dropdown[6.2,1.2;3.8;mode;" .. table.concat(travelpoints.get_pad_modes(), ",") .. ";" .. mode_index .. "]"
		formspec = formspec .. "field[6.5,2.7;3.7,1;player_name;Player Name;]"
		formspec = formspec .. "button[6.2,3.2;3.7,1;add_player;Add Player]"

		if #players > 0 then

			if #players == 1 then
				formspec = formspec .. "label[6.2,4.1;...this player:]"
			else
				formspec = formspec .. "label[6.2,4.1;...these " .. #players .. " players:]"
			end
			formspec = formspec .. "dropdown[6.2,4.6;3.8;players;" .. table.concat(players, ",") .. ";]"
			formspec = formspec .. "button[6.2,5.3;3.7,1;remove_player;Remove Player]"

		end

	end

	return formspec

end

--[Get Infotext]----------------------------------------------------------------
--
--	Builds infotext for travelpoints:transporter_pad/_active
--
function travelpoints.get_infotext(meta)

	-- Pull metadata values.
	local owner = meta:get_string("owner")
	local title = meta:get_string("title")
	local destination = meta:get_string("destination")

	-- Set status
	local status
	if (title ~= "") and (destination ~= "") then
		status = "\"" .. title .. "\""
	else
		status = "Offline"
	end

	if minetest.is_singleplayer() then
		return status
	else
		return status .. " (Placed by " .. owner .. ")"
	end
end

--[Get Location]----------------------------------------------------------------
--
--	Get player's location as a table of coordinates.
--
function travelpoints.get_location(name)

	-- Get player position.
	local pos = minetest.get_player_by_name(name):getpos()

	-- Round down values and adjust.
	pos.x = math.floor(pos.x + 0.5)
	pos.y = math.floor(pos.y + 0.5)
	pos.z = math.floor(pos.z + 0.5)

	return pos

end

--[Get Pad Modes]---------------------------------------------------------------
--
--	Returns a table or array of access modes for
--	transporter_pad/_active formspec.
--
function travelpoints.get_pad_modes(return_type)

	-- Mode names.
	local one, two, three, four = "Owner only", "Everyone", "Owner and...", "Everyone except..."

	if return_type == "table" then
		return { [one] = 1, [two] = 2, [three] = 3, [four] = 4 }
	else
		return { [1] = one, [2] = two, [3] = three, [4] = four }
	end

end

--[Get Textlist Index]----------------------------------------------------------
--
--	Extracts the index number for formspec textlist fields.
--
function travelpoints.get_textlist_index(index)

	return tonumber(string.match(index, "^%a+:(%d+)"))

end

--[Get Travelpoints Array]------------------------------------------------------
--
--	Builds an array of travelpoint table elements.
--
--	Written initially for travelpoints:transpoerter_pad/_active formspec then
--	became useful for getting a travelpoint count.
--
function travelpoints.get_travelpoints_array(name)

	-- Get travelpoints_table.
	local travelpoints_table = travelpoints.get_travelpoints_table(name)

	-- Check if travelpoints_table is empty.
	if not travelpoints.is_empty(travelpoints_table) then

		local travelpoints_array = {}

		-- Step through travelpoints_table to pack travelpoints_array.
		for key, value in pairs(travelpoints_table) do

			-- Omit keys that begin with an underscore.
			if string.find(key, "^[^_].+") then

				-- <title> (<x>, <y>, <z>)
				table.insert(travelpoints_array, key .. " " .. minetest.formspec_escape(minetest.pos_to_string(value.pos)))

			end

		end

		-- Sort values.
		table.sort(travelpoints_array, function(A, B) return A < B end)

		-- Add "none" at index 1.
		table.insert(travelpoints_array, 1, "none")

		return travelpoints_array

	else

		return { "none" }

	end

end

--[Get Travelpoints Table]------------------------------------------------------
--
--	Get player's travelpoints table for the current world.
--
function travelpoints.get_travelpoints_table(name)

	-- Set travelpoints_table file path.
	local travelpoints_table_file = travelpoints.travelpoints_tables .. travelpoints.delimiter .. name .. ".tpt"

	-- Open player's travelpoints_table file for reading.
	local read_handle, read_error = io.open(travelpoints_table_file, "r")

	-- Check if travelpoints_table file failed to open. (Might not exist yet.)
	if read_error ~= nil then

		-- Create travelpoints_table file.
		local write_handle, write_error = io.open(travelpoints_table_file, "w")

		-- Check if travelpoints_table file could not be created.
		if write_error ~= nil then

			-- Report error to player.
			travelpoints.print_notice(name, "Error: Travelpoints table file could not be read or created: \"" .. travelpoints_table_file .. "\"")

			return nil

		else

			write_handle:close()

			-- Return empty table.
			return {}

		end

	else

		-- Get travelpoints_table file's contents.
		local travelpoints_table_file_contents = read_handle:read("*a")

		read_handle:close()

		-- Check if file is empty.
		if string.len(travelpoints_table_file_contents) > 0 then

			-- Return deserialized table.
			return minetest.deserialize(travelpoints_table_file_contents)

		else

			return {}

		end

	end

end

--[Get World Restrictions]------------------------------------------------------
--
--	If world restrictions are set, the restrictions imposed by config.lua are
--	superseded.
--
function travelpoints.get_world_restrictions()

	-- Set restrictions file path.
	local restrictions_file = travelpoints.worldpath .. travelpoints.delimiter .. "travelpoints_restrictions.tpt"

	-- Check if file exists
	if file_exists(restrictions_file) then -- builtin/misc_helpers.lua
	
		-- Open restrictions file for reading.
		local read_handle, read_error = io.open(restrictions_file, "r")

		-- Check if restrictions file failed to open.
		if read_error == nil then

			-- Get restrictions file's contents.
			local restrictions_file_contents = read_handle:read("*a")

			read_handle:close()

			-- Check if file is empty.
			if string.len(restrictions_file_contents) > 0 then

				local restrictions = minetest.deserialize(restrictions_file_contents)
				
				-- Validate restrictions table.
				if ( type(restrictions) == "table" ) and ( not travelpoints.is_empty(restrictions) ) then
				
					-- Step through restrictions from config file.
					for key, value in pairs(travelpoints.restrictions) do
					
						-- Check if restriction value needs to be changed.
						if ( restrictions[key] ~= nil ) and ( restrictions[key] ~= travelpoints.restrictions[key] ) then
						
							-- Validate value.
							if travelpoints.validate_restriction_value(key, restrictions[key]) then
							
								-- Set value.
								travelpoints.restrictions[key] = restrictions[key]
								
								-- Report to log.
								print("Travelpoints -!- Config restriction " .. key .. " superseded with " .. travelpoints.restrictions[key])
							
							end
						
						end
					
					end
				
				end

			end
		
		end

	end

end

--[Is Empty]--------------------------------------------------------------------
--
--	Determine if a table is empty.
--
function travelpoints.is_empty(table_name)

	if type(table_name) ~= "table" then
		return nil
	end

	local count = 0

	for key, value in pairs(table_name) do
		if table_name[key] ~= nil then
			count = count + 1
			if count > 0 then
				break
			end
		end
	end

	if count == 0 then
		return true
	else
		return false
	end

end

--[Player Can Use Pad]----------------------------------------------------------
--
--	Returns a boolean value for whether or not the player can use the pad.
--
function travelpoints.player_can_use_pad(meta, player)

	local mode = meta:get_int("mode_index")
	local owner = meta:get_string("owner")
	local players = meta:get_string("players")

	-- Pad Mode: Owner only.
	if ( mode == 1 ) and ( player == owner ) then

		return true

	-- Pad Mode: Everyone
	elseif mode == 2 then

		return true

	-- Pad Mode: Owner and...
	elseif ( mode == 3 ) and ( ( player == owner ) or ( travelpoints.player_in_players(player, players) ) ) then

		return true

	-- Pad Mode: Everyone except...
	elseif ( mode == 4 ) and ( not travelpoints.player_in_players(player, players) ) then

		return true

	else

		return false

	end

end

--[Player Exists]---------------------------------------------------------------
--
--	Checks to see if named player exists, either currently online or by player
--	file.
--

function travelpoints.player_exists(player_name)

	if player_name ~= nil then

		if minetest.get_player_by_name(player_name) then
			return true
		else

			-- Set player's file path.
			local player_file = travelpoints.worldpath .. travelpoints.delimiter .. "players" .. travelpoints.delimiter .. player_name

			-- Check if player file exists.
			if file_exists(player_file) then -- builtin/common/misc_helpers.lua
				return true
			else
				return false
			end

		end

	else
		return false
	end

end


--[Player In Players]-----------------------------------------------------------
--
--	Returns boolean for whether or not given player is in a node's players list.
--
function travelpoints.player_in_players(player, players)

	local players = minetest.deserialize(players)
	
	local player_in_players = false
	
	-- Step through array to see if given player is in it.
	for key, value in ipairs(players) do
	
		if value == player then
			player_in_players = true
			break
		end
	
	end
	
	return player_in_players

end

--[Print Notice]----------------------------------------------------------------
--
--	Send notice to the player.
--
function travelpoints.print_notice(name, content)

	-- Add prefix.
	content = "Travelpoints -!- " .. content

	-- Send notice to player.
	minetest.chat_send_player(name, content, false)

end

--[Save travelpoints_table]----------------------------------------------------------------
--
--	Saves any changes to the travelpoints table to the player's travelpoints_table file.
--
function travelpoints.save_travelpoints_table(name, travelpoints_table)

	-- Validate travelpoints_table.
	if ( travelpoints_table == nil ) or ( type(travelpoints_table) ~= "table" ) then
		return false
	end

	-- Set travelpoints_table file path.
	local travelpoints_table_file = travelpoints.travelpoints_tables .. travelpoints.delimiter .. name .. ".tpt"

	-- Open travelpoints_table file for writing.
	local write_handle, write_error = io.open(travelpoints_table_file, "w")

	-- Check for error.
	if write_error ~= nil then
		travelpoints.print_notice(name, "Error: Travelpoints table file could not be opened for writing: \"" .. travelpoints_table_file .. "\"")
		return false
	end

	-- Serialize travelpoints_table.
	local serialized = minetest.serialize(travelpoints_table)

	-- Save data.
	write_handle:write(serialized)
	write_handle:flush()
	write_handle:close()

	return true

end

--[Save World Restrictions]-----------------------------------------------------
--
--	Saves in game changes to restrictions via /travelpoints set <restriction>
--	<value>.
--
function travelpoints.save_world_restrictions(restrictions)

	-- Validate restrictions table.
	if ( restrictions == nil ) or ( type(restrictions) ~= "table" ) then
		return false
	end

	-- Set restrictions file path.
	local restrictions_file = travelpoints.worldpath .. travelpoints.delimiter .. "travelpoints_restrictions.tpt"

	-- Open restrictions file for writing.
	local write_handle, write_error = io.open(restrictions_file, "w")

	-- Check for error.
	if write_error ~= nil then
		travelpoints.print_notice(name, "Error: Restrictions file could not be opened for writing: \"" .. restrictions_file .. "\"")
		return false
	end

	-- Serialize restrictions table.
	local serialized = minetest.serialize(restrictions)

	-- Save data.
	write_handle:write(serialized)
	write_handle:flush()
	write_handle:close()

	return true
	
end

--[Swap Node]-------------------------------------------------------------------
--
--	This function should not be needed after Minetest 0.4.9
--
--	"hacky_swap_node()" was replaced with "minetest.swap_node()" after 0.4.8 was
--	released, so for those using latest builds I have included this function.
--	
function travelpoints.swap_node(pos, name)

	if minetest.swap_node ~= nil then
	
		-- I have included the following lines from https://github.com/minetest/minetest/blob/master/games/minimal/mods/default/init.lua#L1321
		-- because while "swap_node(pos,name)" is a global function there, in the Fess build I
		-- tested in it was a local function.
		
		-- Get node.
		local node = minetest.get_node(pos)
		
		-- Check if node at position is already swapped.
		if node.name == name then
			return
		end
		
		node.name = name
		
		-- Perform swap.
		minetest.swap_node(pos, node)
		
	else
	
		hacky_swap_node(pos, name) -- default/nodes.lua
	
	end	

end

--[Validate Config]-------------------------------------------------------------
--
--	Validate the values set in the config file, switching to default values if
--	invalid values given.
--
function travelpoints.validate_config()
	
	-- Step through restrictions from config file.
	for key, value in pairs(travelpoints.restrictions) do
		-- Test validity of the current restriction.
		if not travelpoints.validate_restriction_value(key, value) then
			if ( key == "cooldown" ) and ( value > 3600 ) then
				-- If cooldown is set too high, set it to max (1 hour)
				travelpoints.restrictions[key] = 3600
			else
				-- For all other invalid values set to default.
				travelpoints.restrictions[key] = travelpoints.default_restrictions(key)
			end
		end
	end

end

--[Validate Description]--------------------------------------------------------
--
--	Filters travelpoint description.
--
function travelpoints.validate_desc(desc)
	if string.find(desc, "[^%w_ ]") ~= nil then
		return 'Descriptions can only contain these characters: [0-9a-zA-Z _]'
	elseif string.len(desc) > 50 then
		return 'Description can not exceed 50 characters.'
	else
		return nil
	end
end

--[Validate Restriction Value]--------------------------------------------------
--
--	Validates a given restriction value, returning true if valid, or false with
--	error message if not.
--
function travelpoints.validate_restriction_value(key, value)

	if type(value) == "number" then

		if value >= 0 then
	
			-- Cooldown.
			if key == "cooldown" then

				if value > 3600 then
					return false, "Value of cooldown should not be longer than 3600 (1 hour)."
				else
					return true
				end

				-- Clear Tpback.
			elseif key == "clear_back_pos" then
				
				-- This value should be 1 or 0.
				if not string.find(value, "^[01]$") then
					return false, "Value for clear_back_pos can only be 1 or 0."
				else
					return true
				end
			
			else
				return true
			end
			
		else	
			return false, "Value of " .. key .. " should not be a negative number."
		end		
	
	else
		return false, "Value of ".. key .. " should be a number."
	end

end

--[Validate Title]--------------------------------------------------------------
--
--	Filters travelpoint title.
--
function travelpoints.validate_title(title)
	if string.find(title, "^%d+[%D]") ~= nil then
		return 'Title can not begin with a number if it contains non numeric characters.'
	elseif string.find(title, "^_.*") ~= nil then
		return 'Title can not begin with an underscore, but may contain them.'
	elseif string.find(title, "[^%w_]") ~= nil then
		return 'Title can only contain these characters: [0-9a-zA-Z_]'
	elseif string.len(title) > 25 then
		return 'Title can not exceed 25 characters.'
	elseif title == "all" then
		return "Title can not be \"all\", that is reserved for /tpdrop."
	else
		return nil
	end
end

--[Travelpad Log]---------------------------------------------------------------
--
--	Depending on action value, returns travelpad count, adds travelpad to log,
--	or removes travelpad from log.
--
function travelpoints.travelpad_log(name, meta, action)

	-- Get travelpoints_table.
	local travelpoints_table = travelpoints.get_travelpoints_table(name)
	
	-- Initialize _travelpads if needed.
	if travelpoints_table._travelpads == nil then
		travelpoints_table._travelpads = {}
	end
	
	-- Count travelpads.
	if action == "count" then

		local travelpads = {}
	
		-- Pack array to get count.
		for key, value in pairs(travelpoints_table._travelpads) do
			if key ~= nil then
				table.insert(travelpads, key)
			end
		end	
		
		return #travelpads
		
	-- Add travelpad to log.
	elseif action == "add" then
	
		-- Convert pos to string.
		local location = meta:get_string("location")
		
		-- Check if this location already has an entry,
		if travelpoints_table._travelpads[location] == nil then
			
			-- Add travelpad to travelpads.
			travelpoints_table._travelpads[location] = meta:get_int("timestamp")
			
			-- Save travelpoints_table.
			travelpoints.save_travelpoints_table(name, travelpoints_table)
			
			return
			
		end
			
	-- Remove travelpad from log.
	elseif action == "remove" then
	
		local location = meta:get_string("location")
		
		-- Verify that this location has an entry.
		if travelpoints_table._travelpads[location] ~= nil then
		
			-- Remove travelpad.
			travelpoints_table._travelpads[location] = nil
			
			-- Save travelpoints_table.
			travelpoints.save_travelpoints_table(name, travelpoints_table)
		
			return
		
		end

	end
		
end

--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------