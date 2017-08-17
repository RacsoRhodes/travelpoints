--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.4                            2015-03-27
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
--		travelpoints.after_place_node()
--		travelpoints.can_dig()
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
--		travelpoints.on_destruct()
--		travelpoints.on_receive_fields()
--		travelpoints.player_can_use_pad()
--		travelpoints.player_exists()
--		travelpoints.player_in_players()
--		travelpoints.print_notice()
--		travelpoints.save_travelpoints_table()
--		travelpoints.save_world_restrictions()
--		travelpoints.set_pad_destination()
--		travelpoints.swap_node()
--		travelpoints.validate_config()
--		travelpoints.validate_desc()
--		travelpoints.validate_restriction_value()
--		travelpoints.validate_title()
--		travelpoints.travelpad_log()
--
--------------------------------------------------------------------------------

--[[

		Meta Data 1.4d
		
		string("location")
		string("owner")
		string("title")
		string("destination")
		string("source")
		string("version")
		int("timestamp")
		int("modstamp")
		
		int("utp_index") \ tp_index
		int("gtp_index") / 
		
		int("mode_index")
		string("players")
		
		string("user_travelpoints_array")   \ tp_array
		string("global_travelpoints_array") /
		
		string("formspec")
		string("infotext")
		
		

]]--


--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

--[After Place Node]------------------------------------------------------------
--
--	Node callback function.
--	Builds the default meta values for the placed node.
--
function travelpoints.after_place_node(pos, placer)

	-- Get node metadata.
	local meta = minetest.get_meta(pos)

	-- Get placer's name.
	local name = placer:get_player_name()

	-- Get player's travelpad count for this world.
	local travelpad_count = travelpoints.travelpad_log(name, meta, "count")

	-- Verify privs.
	if not minetest.get_player_privs(name)["travelpads"] then

		-- Report
		travelpoints.print_notice(name, "You do not have the privilege to place transporter pads.")

		-- Remove travelpad.
		minetest.remove_node(pos)

		-- Drop travelpad for pickup.
		minetest.add_item(pos, 'travelpoints:transporter_pad')

	-- Verify status.
	elseif minetest.get_node(pos).name == "travelpoints:transporter_pad_active" then
	
		-- Report
		travelpoints.print_notice(name, "You can not place an active transporter pad.")

		-- Remove active travelpad.
		minetest.remove_node(pos)

		-- Drop travelpad for pickup.
		minetest.add_item(pos, 'travelpoints:transporter_pad')
	
	-- Handle maximum_travelpads if it is configured.
	elseif ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.max_travelpads > 0 ) and ( travelpad_count >= travelpoints.restrictions.max_travelpads ) and ( not minetest.get_player_privs(name)["server"]) then

		-- Report
		travelpoints.print_notice(name, "You have already reached your maximum number of transporter pads: " .. travelpoints.restrictions.max_travelpads .. ".")

		-- Remove travelpad.
		minetest.remove_node(pos)

		-- Drop travelpad for pickup.
		minetest.add_item(pos, 'travelpoints:transporter_pad')

	else

		-- Set default values.
		meta:set_string("location", minetest.pos_to_string(pos))
		meta:set_string("owner", name)
		meta:set_string("title", "")
		meta:set_string("destination", "")
		meta:set_string("source", "") --(Mine/Global)
		meta:set_string("version", travelpoints.version_number)
		meta:set_int("timestamp", os.time())
		meta:set_int("modstamp", 0)
		meta:set_int("tp_index", 1)
		meta:set_string("tp_array", "return { }")
		meta:set_int("mode_index", 1)
		meta:set_string("players", "return {  }")

		-- Add travelpad to log.
		travelpoints.travelpad_log(name, meta, "add")

		-- Save default formspec
		meta:set_string("formspec", travelpoints.get_formspec("", meta))

		-- Save default infotext.
		meta:set_string("infotext", travelpoints.get_infotext(meta))

	end

end

--[Can Dig]---------------------------------------------------------------------
--
--	Node callback function.
--	Determines if the node can be dug.
--
travelpoints.can_dig = function(pos, player)

	-- Get node's metadata.
	local meta = minetest.get_meta(pos)

	-- Get player's name.
	local name = player:get_player_name()

	-- Dug by admin?
	if minetest.get_player_privs(name)["server"] then
		
		return true
	
	-- Dug by owner?
	elseif meta:get_string("owner") == name then

		-- Check if travelpad is "offline".
		if meta:get_string("destination") == "" then
			return true
		else
			travelpoints.print_notice(name, "A transporter pad can not be dug unless its destination is unset.")
			return false
		end

	-- Dug by Anyone else.
	else
		travelpoints.print_notice(name, "You can not dig a transporter pad you do not own.")
		return false
	end

end

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
function travelpoints.get_formspec(mode, meta) -- mode(|user|global)

	-- Pull metadata.
	local title = meta:get_string("title")
	local destination = meta:get_string("destination")
	local source = meta:get_string("source")
	local timestamp = meta:get_int("timestamp")
	local modstamp = meta:get_int("modstamp")
	local version = meta:get_string("version")
	local tp_array = minetest.deserialize(meta:get_string("tp_array"))
	local tp_index = meta:get_int("tp_index")
	local tp_count = 0
	local mode_index = meta:get_int("mode_index")
	local players = minetest.deserialize(meta:get_string("players"))

	-- Get travelpoint count.
	if #tp_array > 0 then
		tp_count = #tp_array
	end

	-- Convert travelpoints array to string.
	local tp_string = table.concat(tp_array, ",")
	
	-- Set status
	local status
	if (title ~= "") and (destination ~= "") then
		status = "Destination: " .. title .. " " .. destination .. " (" .. source .. ")"
	else
		status = "Offline"
	end

	-- Set list label
	local list_label
	if mode == "user" then
		list_label = "My Travelpoints: " .. tp_count
	elseif mode == "global" then
		list_label = "Global Travelpoints: " .. tp_count
	else
		list_label = "Travelpoints:"
	end
	
	-- Set tp string
	if mode == "user" then
		tp_string = "user_list;" .. tp_string .. ";" .. tp_index
	else
		tp_string = "global_list;" .. tp_string .. ";" .. tp_index
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
	formspec = formspec .. "label[0.1,0.7;" .. list_label .."]"
	formspec = formspec .. "textlist[0.1,1.2;5.7,3.6;" .. tp_string .. "]"
	formspec = formspec .. "button[0.1,4.83;2.9,1;my_travelpoints;My Travelpoints]"
	formspec = formspec .. "button[3.15,4.83;2.9,1;global_travelpoints;Global Travelpoints]"
	formspec = formspec .. "button[0.1,5.65;2.9,1;unset_destination;Unset Destination]"
	formspec = formspec .. "button_exit[3.15,5.65;2.9,1;exit;Exit]"
	formspec = formspec .. "label[0.1,6.6;Placed: " .. os.date("%Y-%m-%d", timestamp) .. "]"
	formspec = formspec .. "label[3.15,6.6;Modified: " .. last_modified .. "]"
	formspec = formspec .. "label[9.2,6.6;v" .. version .. "]"
	
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
		return status .. " (" .. owner .. ")"
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
	pos.y = math.floor(pos.y) + 0.5
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
function travelpoints.get_travelpoints_array(mode, name) -- mode(user/global)

	-- Get table.
	local travelpoints_table = travelpoints.get_travelpoints_table(mode, name)
	
	-- Check if travelpoints table is empty.
	if not travelpoints.is_empty(travelpoints_table) then

		local travelpoints_array = {}

		-- Step through travelpoints table to pack travelpoints array.
		for key, value in pairs(travelpoints_table) do

			-- Omit keys that begin with an underscore.
			if string.find(key, "^[^_].+") then

				-- <title> (<x>, <y>, <z>)
				table.insert(travelpoints_array, key .. " " .. minetest.formspec_escape(minetest.pos_to_string(value.pos)))

			end

		end

		-- Sort values.
		table.sort(travelpoints_array, function(A, B) return A < B end)

		return travelpoints_array

	else

		return { }

	end

end

--[Get Travelpoints Table]------------------------------------------------------
--
--	Get player's travelpoints table for the current world.
--
function travelpoints.get_travelpoints_table(mode, name) -- mode(user/global), name

	local travelpoints_table_file
	
	-- Set travelpoints table file path.
	if mode == "user" then
		
		-- User's table.
		travelpoints_table_file = travelpoints.travelpoints_tables .. travelpoints.delimiter .. name .. ".tpt"
		
	else
		
		-- Global table.
		travelpoints_table_file = travelpoints.worldpath .. travelpoints.delimiter .. "travelpoints_global.tpt"
	
	end
	
	-- Open travelpoints table file for reading.
	local read_handle, read_error = io.open(travelpoints_table_file, "r")

	-- Check if travelpoints table file failed to open. (Might not exist yet.)
	if read_error ~= nil then

		-- Create travelpoints table file.
		local write_handle, write_error = io.open(travelpoints_table_file, "w")

		-- Check if travelpoints table file could not be created.
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

--[On Destruct]-----------------------------------------------------------------
--
--	Node callback function.
--	Removes entry from travelpad log when pad is destroyed.
--
function travelpoints.on_destruct(pos)

	-- Get nodes metadata.
	local meta = minetest.get_meta(pos)

	if meta:get_string("owner") ~= "" then

		-- Remove travelpad from log.
		travelpoints.travelpad_log(meta:get_string("owner"), meta, "remove")

	end

end

--[On Receive Fields]-----------------------------------------------------------
--
--	Node callback function.
--	Handles data from form.
--
function travelpoints.on_receive_fields(pos, formname, fields, sender)

	local meta = minetest.get_meta(pos)

	local name = sender:get_player_name()

	local owner = meta:get_string("owner")
	
	-- Only pad owner can make changes.
	if name == owner then

		--------------------------------------------------------------------
		-- Button "My Travelpoints"
		--------------------------------------------------------------------
		--
		-- This lists the user's travelpoints.
		--
		if fields.my_travelpoints == "My Travelpoints" then

			-- Get the user's travelpoints as an array.
			local tp_array = travelpoints.get_travelpoints_array("user", owner)

			-- Serialize the travelpoints array.
			local tp_array = minetest.serialize(tp_array)

			-- Set the travelpoints array.
			meta:set_string("tp_array", tp_array)

			-- Set pad to "Offline".
			--
			-- Assumed that player chose to refresh in order to point the pad to
			-- new coords.
			--
			meta:set_string("title", "")
			meta:set_string("destination", "")
			meta:set_int("tp_index", 0)

			-- Save formspec.
			meta:set_string("formspec", travelpoints.get_formspec("user", meta))

			-- Save infotext.
			meta:set_string("infotext", travelpoints.get_infotext(meta))

		--------------------------------------------------------------------
		-- Button "Global Travelpoints"
		--------------------------------------------------------------------
		--
		-- This syncs the node's global travelpoints array with the current
		-- global travelpoints table.
		--
		elseif fields.global_travelpoints == "Global Travelpoints" then

			-- Get the user's travelpoints as an array.
			local tp_array = travelpoints.get_travelpoints_array("global", owner)

			-- Serialize the travelpoints array.
			local tp_array = minetest.serialize(tp_array)

			-- Set the travelpoints array.
			meta:set_string("tp_array", tp_array)

			-- Set pad to "Offline".
			--
			-- Assumed that player chose to refresh in order to point the pad to
			-- new coords.
			--
			meta:set_string("title", "")
			meta:set_string("destination", "")
			meta:set_int("tp_index", 0)

			-- Save formspec.
			meta:set_string("formspec", travelpoints.get_formspec("global", meta))

			-- Save infotext.
			meta:set_string("infotext", travelpoints.get_infotext(meta))			
			
		--------------------------------------------------------------------
		-- Text list - select user travelpoint.
		--------------------------------------------------------------------

		elseif ( fields.user_list ) and ( name == owner) then

			-- Get index value.
			local index = travelpoints.get_textlist_index(fields.user_list)

			if index ~= meta:get_int("tp_index") then

				-- Get this node's travelpoints array.
				local tp_array = minetest.deserialize(meta:get_string("tp_array"))

				-- Extract title and destination from array value.
				local title, destination = string.match(tp_array[index], "^([^ ]+)%s+(.+)")

				-- Remove escapes.
				destination = string.gsub(destination, "\\", "", 2)

				-- Pads can't teleport to themselves.
				if destination ~= minetest.pos_to_string(pos) then

					-- Set or clear title and destination meta data.
					if ( index == 0 ) or ( index > #tp_array ) then
						meta:set_string("title", "")
						meta:set_string("destination", "")
						meta:set_string("source", "")
						meta:set_int("tp_index", 0)
					else
						meta:set_string("title", title)
						meta:set_string("destination", destination)
						meta:set_string("source", "Mine")
						meta:set_int("tp_index", index)
					end

					meta:set_string("tp_array", "return {  }")
					
					-- Save modification timestamp.
					meta:set_int("modstamp", os.time())

					-- Save formspec.
					meta:set_string("formspec", travelpoints.get_formspec("", meta))

					-- Save infotext.
					meta:set_string("infotext", travelpoints.get_infotext(meta))

				else

					-- Report
					travelpoints.print_notice(name, "Error: You can not set the transporter pad's location as its destination.")

				end

			end

		--------------------------------------------------------------------
		-- Text list - select global travelpoint.
		--------------------------------------------------------------------

		elseif fields.global_list then

			-- Get index value.
			local index = travelpoints.get_textlist_index(fields.global_list)

			if index ~= meta:get_int("tp_index") then

				-- Get this node's travelpoints array.
				local tp_array = minetest.deserialize(meta:get_string("tp_array"))

				-- Extract title and destination from array value.
				local title, destination = string.match(tp_array[index], "^([^ ]+)%s+(.+)")

				-- Remove escapes.
				destination = string.gsub(destination, "\\", "", 2)

				-- Pads can't teleport to themselves.
				if destination ~= minetest.pos_to_string(pos) then

					-- Set or clear title and destination meta data.
					if ( index == 0 ) or ( index > #tp_array ) then
						meta:set_string("title", "")
						meta:set_string("destination", "")
						meta:set_string("source", "")
						meta:set_int("tp_index", 0)
					else
						meta:set_string("title", title)
						meta:set_string("destination", destination)
						meta:set_string("source", "Global")
						meta:set_int("tp_index", index)
					end
					
					meta:set_string("tp_array", "return {  }")

					-- Save modification timestamp.
					meta:set_int("modstamp", os.time())

					-- Save formspec.
					meta:set_string("formspec", travelpoints.get_formspec("", meta))

					-- Save infotext.
					meta:set_string("infotext", travelpoints.get_infotext(meta))

				else

					-- Report
					travelpoints.print_notice(name, "Error: You can not set the transporter pad's location as its destination.")

				end

			end
			
		--------------------------------------------------------------------
		-- Button "Add Player"
		--------------------------------------------------------------------

		elseif ( fields.add_player == "Add Player" ) and ( string.len(fields.player_name) > 0 ) then

			local player = fields.player_name

			-- Validate input.
			if not string.find(player, "^[^%w_]+$") then

				-- Owner can't add their name.
				if player ~= name then

					-- Check if player exists.
					if travelpoints.player_exists(player) then

						-- Check if player is already in array.
						if not travelpoints.player_in_players(player, meta:get_string("players")) then

							-- Get players array.
							local players = minetest.deserialize(meta:get_string("players"))

							-- Add player.
							table.insert(players, player)

							-- Sort values.
							if #players > 1 then
								table.sort(players, function(A, B) return A < B end)
							end

							-- Save players array.
							meta:set_string("players", minetest.serialize(players))

							-- Save modification timestamp.
							meta:set_int("modstamp", os.time())

							-- Save formspec.
							meta:set_string("formspec", travelpoints.get_formspec("", meta))

						else

							-- Report
							travelpoints.print_notice(name, "Error: \"" .. player .. "\" is already listed.")

						end

					else

						-- Report
						travelpoints.print_notice(name, "Error: \"" .. player .. "\" is not an existing player for this world.")

					end

				else

					-- Report
					travelpoints.print_notice(name, "Error: You can't add your own name.")

				end

			else

				-- Report
				travelpoints.print_notice(name, "Error: The name you entered contains disallowed characters.")

			end

		--------------------------------------------------------------------
		-- Button "Remove Player"
		--------------------------------------------------------------------

		elseif fields.remove_player == "Remove Player" then

			local player = fields.players

			-- Get players array.
			local players = minetest.deserialize(meta:get_string("players"))

			local player_removed = false

			-- Step through players to find player.
			for index, value in ipairs(players) do

				-- Remove player when found.
				if value == player then
					table.remove(players, index)
					player_removed = true
					break
				end

			end

			-- Check if a player was removed.
			if player_removed then

				-- Sort values.
				if #players > 1 then
					table.sort(players, function(A, B) return A < B end)
				end

				-- Save players array.
				meta:set_string("players", minetest.serialize(players))

				-- Save modification timestamp.
				meta:set_int("modstamp", os.time())

				-- Save formspec.
				meta:set_string("formspec", travelpoints.get_formspec("", meta))

			end

		--------------------------------------------------------------------
		-- Button "Unset Destination"
		--------------------------------------------------------------------
		elseif fields.unset_destination == "Unset Destination" then

			-- Clear destination.
			meta:set_string("title", "")
			meta:set_string("destination", "")
			meta:set_string("source", "")
			meta:set_int("tp_index", 0)
			meta:set_string("tp_array", "return {  }")

			-- Save modification timestamp.
			meta:set_int("modstamp", os.time())

			-- Save formspec.
			meta:set_string("formspec", travelpoints.get_formspec("", meta))

			-- Save infotext.
			meta:set_string("infotext", travelpoints.get_infotext(meta))

		--------------------------------------------------------------------
		-- Drop down list "Pad Usage Mode"
		--------------------------------------------------------------------
		elseif fields.mode then
		
			-- Pad Access Mode
			if ( name == owner ) then
				if fields.mode then
					local mode_table = travelpoints.get_pad_modes("table")
					meta:set_int("mode_index", mode_table[fields.mode])
				end
			end

			-- Save modification timestamp.
			meta:set_int("modstamp", os.time())

			-- Save formspec.
			meta:set_string("formspec", travelpoints.get_formspec("", meta))
		
		-- Makes no sense but this block only triggers when the Escape key is
		-- pressed, will not work with button_exit which also sends quit=>true
		-- on top of it's own field.
		elseif fields.quit == "true" then
		
			-- Clear list.
			meta:set_int("tp_index", 0)
			meta:set_string("tp_array", "return {  }")
			
			-- Save formspec.
			meta:set_string("formspec", travelpoints.get_formspec("", meta))

		end

	else

		-- Report
		travelpoints.print_notice(name, "This transporter pad belongs to \"" .. owner .. "\", you can not modify it")

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
--	Saves any changes to the travelpoints table.
--
function travelpoints.save_travelpoints_table(mode, name, travelpoints_table) -- mode(user/global)

	-- Validate travelpoints_table.
	if ( travelpoints_table == nil ) or ( type(travelpoints_table) ~= "table" ) then
		return false
	end
	
	local travelpoints_table_file
	
	-- Set travelpoints table file path.
	if mode == "user" then
		
		-- User's table.
		travelpoints_table_file = travelpoints.travelpoints_tables .. travelpoints.delimiter .. name .. ".tpt"
		
	else
		
		-- Global table.
		travelpoints_table_file = travelpoints.worldpath .. travelpoints.delimiter .. "travelpoints_global.tpt"
	
	end
	
	-- Open travelpoints table file for writing.
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

--[Set Pad Destination]---------------------------------------------------------
--
--	Sets pad meta values for the destination chosen by user.
--

	-- Get index value.
	--local index = travelpoints.get_textlist_index(fields.global_list)


function travelpoints.set_pad_destination(mode, index, meta)

	local user_travelpoints_array, global_travelpoints_array
	
	if mode == "user" then
	
		if index ~= meta:get_int("gtp_index") then
			
			-- Get this node's global travelpoints array.
			global_travelpoints_array = minetest.deserialize(meta:get_string("global_travelpoints_array"))
		
		end
	
	else
	
	end

	if index ~= meta:get_int("gtp_index") then

		-- Get this node's global travelpoints array.
		local global_travelpoints_array = minetest.deserialize(meta:get_string("global_travelpoints_array"))

		-- Extract title and destination from array value.
		local title, destination = string.match(global_travelpoints_array[index], "^([^ ]+)%s+(.+)")

		-- Remove escapes.
		destination = string.gsub(destination, "\\", "", 2)

		-- Pads can't teleport to themselves.
		if destination ~= minetest.pos_to_string(pos) then

			-- Set or clear title and destination meta data.
			if ( index == 1 ) or ( index > #global_travelpoints_array ) then
				meta:set_string("title", "")
				meta:set_string("destination", "")
				meta:set_string("source", "")
				meta:set_int("gtp_index", 1)
			else
				meta:set_string("title", title)
				meta:set_string("destination", destination)
				meta:set_string("source", "Global")
				meta:set_int("gtp_index", index)
			end
			
			meta:set_string("global_travelpoints_array", "return {  }")
			meta:set_int("utp_index", 1)
			meta:set_string("user_travelpoints_array", "return {  }")

			-- Save modification timestamp.
			meta:set_int("modstamp", os.time())

			-- Save formspec.
			meta:set_string("formspec", travelpoints.get_formspec("global", meta))

			-- Save infotext.
			meta:set_string("infotext", travelpoints.get_infotext(meta))

		else

			-- Report
			travelpoints.print_notice(name, "Error: You can not set the transporter pad's location as its destination.")

		end


	end

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
	local travelpoints_table = travelpoints.get_travelpoints_table("user", name)
	
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
			travelpoints.save_travelpoints_table("user", name, travelpoints_table)
			
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
			travelpoints.save_travelpoints_table("user", name, travelpoints_table)
		
			return
		
		end

	end
		
end

--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------