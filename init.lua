--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.4                            2015-03-27
--
-- By Racso Rhodes
--
-- travelpoints/init.lua
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
-- On Load
--
-- Chat Commands
--
--		/tpback
--		/tpdrop
--		/tpgdrop
--		/tpggo
--		/tpgo
--		/tpgset
--		/travelpads
--		/travelpoints
--		/tpset
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- On Load
--------------------------------------------------------------------------------

-- Register privilege - travelpoints.
--
-- This allows users to set, drop and use their own travelpoints.
-- Also allows usage of global travelpoints.
--
minetest.register_privilege("travelpoints", "Can use the Travelpoints chat commands.")

-- Register privilege - travelpads
--
-- This allows the placing of travelpoints:tansporter_pad nodes.
--
minetest.register_privilege("travelpads", "Can place Travelpoint Transporter Pads.")

-- Register privilege - tpglobal
--
-- This allows the saving and dropping of global travelpoints.
--
minetest.register_privilege("tpglobal", "Can set and drop global travelpoints.")

-- Initialize mod table.
travelpoints = {}

-- Get path to this mod.
travelpoints.modpath = minetest.get_modpath(minetest.get_current_modname())

-- Get path to current world.
travelpoints.worldpath = minetest.get_worldpath()

-- Get filesystem directory delimiter.
travelpoints.delimiter = string.sub(package.config, 1, 1)

-- Set travelpoints_tables directory path.
travelpoints.travelpoints_tables = travelpoints.worldpath .. travelpoints.delimiter .. "travelpoints_tables"

-- Create directory if it does not exist.
if minetest.mkdir then
	minetest.mkdir(travelpoints.travelpoints_tables)
else
	os.execute("mkdir \"" .. travelpoints.travelpoints_tables .. "\"")
end

-- Set version for /travelpoints.
travelpoints.version_number = "1.4"

-- Set version date for /travelpoints.
travelpoints.version_date = "2015-03-27"

-- Initialize restrictions table.
travelpoints.restrictions = {}

-- Load config file.
dofile(travelpoints.modpath .. travelpoints.delimiter .. "config.lua")

-- Load functions file.
dofile(travelpoints.modpath .. travelpoints.delimiter .. "functions.lua")

-- Load nodes file.
dofile(travelpoints.modpath .. travelpoints.delimiter .. "nodes.lua")

-- Validate config setting values.
travelpoints.validate_config()

-- Get world specific restrictions.
travelpoints.get_world_restrictions()

--------------------------------------------------------------------------------
-- Chat Commands
--------------------------------------------------------------------------------

--[/tpback]--------------------------------------------------------------------
--
--	Returns player to the location they last used /tpgo <title>.
--
minetest.register_chatcommand("tpback", {
	params = "",
	description = "Teleports you back to the location where \"/tpgo <title>\" was last used.",
	privs = {travelpoints=true},
	func = function(name, param)

		-- Get travelpoints_table.
		local travelpoints_table = travelpoints.get_travelpoints_table("user", name)

		-- Check for return location.
		if not travelpoints_table._back then
			travelpoints.print_notice(name, "You have no return location.")
			return
		end

		-- Get player.
		local player = minetest.get_player_by_name(name)

		-- Teleport player.
		player:setpos(travelpoints_table._back)

		-- Report.
		travelpoints.print_notice(name, "You have returned to " .. minetest.pos_to_string(travelpoints_table._back) .. "." )

		-- Clear return location.
		if travelpoints.restrictions.clear_back_pos > 0 then
			travelpoints_table._back = nil
			travelpoints.save_travelpoints_table("user", name, travelpoints_table)
		end

	end,
})

--[/tpdrop]--------------------------------------------------------------------
--
--	Allows player to remove the specified travelpoint for the current world, if
--	"all" is used, all travelpoints are removed.
--
minetest.register_chatcommand("tpdrop", {
	params = "<title> | all",
	description = "Removes the travelpoint specified by <title>. To remove all of your travelpoints for this world, use \"/tpdrop all\".",
	privs = {travelpoints=true},
	func = function(name, param)

		------------------------------------------------------------------------
		--	/tpdrop
		------------------------------------------------------------------------
		if param == "" then

			travelpoints.print_notice(name, "Error: No travelpoint was specified.")

			return

		------------------------------------------------------------------------
		--	/tpdrop all
		------------------------------------------------------------------------
		elseif param == "all" then

			-- Get travelpoints_table.
			local travelpoints_table = travelpoints.get_travelpoints_table("user", name)

			-- Initialize new travelpoints_table.
			local tpt = {}

			-- Step through travelpoints_table.
			for key, value in pairs(travelpoints_table) do

				-- Find keys that begin with an underscore and add to new table.
				if string.find(key, "^_[%w_]+$") then
					tpt[key] = value
				end

			end

			-- Overwrite existing travelpoints_table with new table.
			if travelpoints.save_travelpoints_table("user", name, tpt) then

				-- Report success.
				travelpoints.print_notice(name, "You have removed all of your travelpoints for this world." )

			else

				-- Report error.
				travelpoints.print_notice(name, "Error: Your travelpoints for this world could not be removed.")

			end

			return

		------------------------------------------------------------------------
		--	/tpdrop <title>
		------------------------------------------------------------------------
		else

			-- Get Title.
			local title = string.match(param, "^([^ ]+)%s*")

			-- Validate Title.
			local notice = travelpoints.validate_title(title)
			if notice ~= nil then
				travelpoints.print_notice(name, notice)
				return
			end

			-- Get travelpoints_table.
			local travelpoints_table = travelpoints.get_travelpoints_table("user", name)

			-- Check if <title> is a valid travelpoint.
			if travelpoints_table[title] == nil then
				travelpoints.print_notice(name, "Error: Travelpoint \""  .. title .. "\" does not exist.")
				return
			end

			-- Remove travelpoint from table.
			travelpoints_table[title] = nil

			-- Save travelpoints_table.
			if travelpoints.save_travelpoints_table("user", name, travelpoints_table) then

				-- Report success.
				travelpoints.print_notice(name, "Travelpoint \"" .. title .. "\" has been removed." )

			else

				-- Report error.
				travelpoints.print_notice(name, "Error: Travelpoint \"" .. title .. "\" could not be removed.")

			end

		end

	end,
})

--[/tpgdrop]--------------------------------------------------------------------
--
--	Removes global travelpoints, or all if specified.
--
minetest.register_chatcommand("tpgdrop", {
	params = "<title> | all",
	description = "Removes the global travelpoint specified by <title>. To remove all global travelpoints for this world, use \"/tpgdrop all\".",
	privs = {tpglobal=true},
	func = function(name, param)

		------------------------------------------------------------------------
		--	/tpgdrop
		------------------------------------------------------------------------
		if param == "" then

			travelpoints.print_notice(name, "Error: No travelpoint was specified.")

			return

		------------------------------------------------------------------------
		--	/tpgdrop all
		------------------------------------------------------------------------
		elseif param == "all" then

			-- Check if user has server privilege.
			if minetest.get_player_privs(name)["server"] then
			
				-- Get travelpoints table.
				local travelpoints_table = travelpoints.get_travelpoints_table("global", name)

				-- Initialize new travelpoints table.
				local tpt = {}

				-- Overwrite existing travelpoints table with new table.
				if travelpoints.save_travelpoints_table("global", name, tpt) then

					-- Report success.
					travelpoints.print_notice(name, "You have removed all global travelpoints for this world." )

				else

					-- Report error.
					travelpoints.print_notice(name, "Error: Global travelpoints for this world could not be removed.")

				end

				return

			else
				
				-- Report error.
				travelpoints.print_notice(name, "Server privilege required to drop all global travelpoints.")
				
			end
		
		------------------------------------------------------------------------
		--	/tpgdrop <title>
		------------------------------------------------------------------------
		else

			-- Get Title.
			local title = string.match(param, "^([^ ]+)%s*")

			-- Validate Title.
			local notice = travelpoints.validate_title(title)
			if notice ~= nil then
				travelpoints.print_notice(name, notice)
				return
			end

			-- Get travelpoints_table.
			local travelpoints_table = travelpoints.get_travelpoints_table("global", name)

			-- Check if <title> is a valid travelpoint.
			if travelpoints_table[title] == nil then
				travelpoints.print_notice(name, "Error: Global travelpoint \""  .. title .. "\" does not exist.")
				return
			end

			-- Remove travelpoint from table.
			travelpoints_table[title] = nil

			-- Save travelpoints_table.
			if travelpoints.save_travelpoints_table("global", name, travelpoints_table) then

				-- Report success.
				travelpoints.print_notice(name, "Global travelpoint \"" .. title .. "\" has been removed." )

			else

				-- Report error.
				travelpoints.print_notice(name, "Error: Global travelpoint \"" .. title .. "\" could not be removed.")

			end

		end

	end,
})

--[/tpggo]-----------------------------------------------------------------------
--
--	Teleports player to specified global travelpoint, or displays available
--	global travelpoints if no title given.
--
minetest.register_chatcommand("tpggo", {
	params = "(nothing) | <title>",
	description = "Teleports you to the specified global travelpoint. If no travelpoint given, a list of available global travelpoints is displayed.",
	privs = {travelpoints=true},
	func = function(name, param)

		-- Get global travelpoints table.
		local global_travelpoints_table = travelpoints.get_travelpoints_table("global", name)

		-- Get player's travelpoints table.
		local user_travelpoints_table = travelpoints.get_travelpoints_table("user", name)
		
		-- Assume no cooldown until calculated otherwise.
		local cooldown_remaining = "none"

		-- Get current time.
		local now = os.time()

		-- Check if cooldown needs to be calculated.
		if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.cooldown > 0 ) and ( not minetest.get_player_privs(name)["server"] ) then

			if user_travelpoints_table._cooldown ~= nil then

				-- Cooldown timestamp.
				local coolstamp = user_travelpoints_table._cooldown

				-- Seconds since cooldown timestamp.
				local seconds_since = ( now - coolstamp )

				-- Check if seconds since last /tpgo <title> or /tpggo <title>
				-- is less than cooldown time.
				if seconds_since < travelpoints.restrictions.cooldown then

					-- Get time remaining for cooldown.
					cooldown_remaining = travelpoints.get_duration(travelpoints.restrictions.cooldown - seconds_since)

				end

			end

		end

		------------------------------------------------------------------------
		--	/tpggo
		------------------------------------------------------------------------
		if param == "" then

			-- Get travelpoints array.
			local travelpoints_array = travelpoints.get_travelpoints_array("global", name)

			-- Check if there are any travelpoints.
			if #travelpoints_array > 0 then

				-- Begin output.
				travelpoints.print_notice(name, "Available global travelpoints:")

				-- Step through travelpoints_array.
				for index, value in ipairs(travelpoints_array) do

					-- Extract title from value: "<title> (<x>, <y>, <z>)"
					local title = string.match(value, "^([^ ]+)%s+")

					-- Output lines.
					-- <n>. <title> (<x>, <y>, <z>). Saved on <date> at <time>. Descripton: <desc>
					travelpoints.print_notice(name, index .. ". \"" .. title .. "\" " .. minetest.pos_to_string(global_travelpoints_table[title].pos) .. ". Saved on " .. os.date("%Y-%m-%d at %I:%M:%S %p", global_travelpoints_table[title].timestamp) .. ". Description: " .. global_travelpoints_table[title].desc)

				end

			else
				travelpoints.print_notice(name, "There are no saved global travelpoints.")
			end

			-- Cooldown remaining.
			if cooldown_remaining ~= "none" then
				travelpoints.print_notice(name, "Your remaining cooldown is: " .. cooldown_remaining .. ".")
			end

			return

		------------------------------------------------------------------------
		--	/tpggo <title>
		------------------------------------------------------------------------
		else

			-- Check if player is on cooldown.
			if cooldown_remaining == "none" then

				-- Get Title.
				local title = string.match(param, "^([^ ]+)%s*")

				-- Validate Title.
				local notice = travelpoints.validate_title(title)
				if notice ~= nil then
					travelpoints.print_notice(name, notice)
					return
				end

				-- Check for specified travelpoint.
				if not global_travelpoints_table[title] then
					travelpoints.print_notice(name, "Error: Global travelpoint \"" .. title .. "\"does not exist.")
					return
				end

				-- Set location for /tpback
				user_travelpoints_table._back = travelpoints.get_location(name)

				-- Get player.
				local player = minetest.get_player_by_name(name)

				-- Teleport player.
				player:setpos(global_travelpoints_table[title].pos)

				-- Report.
				travelpoints.print_notice(name, "Teleported to global travelpoint: \"" .. title .. "\". Use /tpback to return to " .. minetest.pos_to_string(user_travelpoints_table._back) .. "." )

				-- Set cooldown if needed.
				if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.cooldown > 0 ) then
					user_travelpoints_table._cooldown = now
				end

				-- Save player's travelpoints table.
				travelpoints.save_travelpoints_table("user", name, user_travelpoints_table)

			else

				-- Report
				travelpoints.print_notice(name, "Time remaining on your cooldown: " .. cooldown_remaining .. ".")

			end

		end

	end,
})

--[/tpgo]-----------------------------------------------------------------------
--
--	Teleports player to specified travelpoint, or displays available
--	travelpoints if no title given.
--
minetest.register_chatcommand("tpgo", {
	params = "(nothing) | <title>",
	description = "Teleports you to the specified travelpoint. If no travelpoint given, a list of available travelpoints is displayed.",
	privs = {travelpoints=true},
	func = function(name, param)

		-- Get travelpoints_table.
		local travelpoints_table = travelpoints.get_travelpoints_table("user", name)

		-- Assume no cooldown until calculated otherwise.
		local cooldown_remaining = "none"

		-- Get current time.
		local now = os.time()

		-- Check if coodown needs to be calculated.
		if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.cooldown > 0 ) and ( not minetest.get_player_privs(name)["server"] ) then

			if travelpoints_table._cooldown ~= nil then

				-- Cooldown timestamp.
				local coolstamp = travelpoints_table._cooldown

				-- Seconds since cooldown timestamp.
				local seconds_since = ( now - coolstamp )

				-- Check if seconds since last /tpgo <title> is less than cooldown time.
				if seconds_since < travelpoints.restrictions.cooldown then

					-- Get time remaining for cooldown.
					cooldown_remaining = travelpoints.get_duration(travelpoints.restrictions.cooldown - seconds_since)

				end

			end

		end

		------------------------------------------------------------------------
		--	/tpgo
		------------------------------------------------------------------------
		if param == "" then

			-- Get travelpoints_array.
			local travelpoints_array = travelpoints.get_travelpoints_array("user", name)

			-- Check if player has any travelpoints.
			if #travelpoints_array > 0 then

				-- Begin output.
				travelpoints.print_notice(name, "Your available travelpoints:")

				-- Step through travelpoints_array.
				for index, value in ipairs(travelpoints_array) do

					-- Extract title from value: "<title> (<x>, <y>, <z>)"
					local title = string.match(value, "^([^ ]+)%s+")

					-- Output lines.
					-- <n>. <title> (<x>, <y>, <z>). Saved on <date> at <time>. Descripton: <desc>
					travelpoints.print_notice(name, index .. ". \"" .. title .. "\" " .. minetest.pos_to_string(travelpoints_table[title].pos) .. ". Saved on " .. os.date("%Y-%m-%d at %I:%M:%S %p", travelpoints_table[title].timestamp) .. ". Description: " .. travelpoints_table[title].desc)

				end

			else
				travelpoints.print_notice(name, "You have no saved travelpoints.")
			end

			-- Check conditions for handling max_travelpoints.
			if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.max_travelpoints > 0 ) and ( not minetest.get_player_privs(name)["server"] ) then
				local max_travelpoints = travelpoints.restrictions.max_travelpoints
				if max_travelpoints > 0 then
					if tp_count < max_travelpoints then
						if tp_count == 0 then
							travelpoints.print_notice(name, "You can set " .. max_travelpoints .. " travelpoints.")
						else
							travelpoints.print_notice(name, "You can set " .. ( max_travelpoints - tp_count ) .. " more travelpoints.")
						end
					elseif tp_count == max_travelpoints then
						travelpoints.print_notice(name, "You can set no more travelpoints unless you /tpdrop older ones. Maximum allowed is " .. max_travelpoints .. ".")
					end
				end
			end

			-- Cooldown remaining.
			if cooldown_remaining ~= "none" then
				travelpoints.print_notice(name, "Your remaining cooldown is: " .. cooldown_remaining .. ".")
			end

			return

		------------------------------------------------------------------------
		--	/tpgo <title>
		------------------------------------------------------------------------
		else

			-- Check if player is on cooldown.
			if cooldown_remaining == "none" then

				-- Get Title.
				local title = string.match(param, "^([^ ]+)%s*")

				-- Validate Title.
				local notice = travelpoints.validate_title(title)
				if notice ~= nil then
					travelpoints.print_notice(name, notice)
					return
				end

				-- Check for specified travelpoint.
				if not travelpoints_table[title] then
					travelpoints.print_notice(name, "Error: Travelpoint \"" .. title .. "\"does not exist.")
					return
				end

				-- Set location for /tpback
				travelpoints_table._back = travelpoints.get_location(name)

				-- Get player.
				local player = minetest.get_player_by_name(name)

				-- Teleport player.
				player:setpos(travelpoints_table[title].pos)

				-- Report.
				travelpoints.print_notice(name, "Teleported to travelpoint: \"" .. title .. "\". Use /tpback to return to " .. minetest.pos_to_string(travelpoints_table._back) .. "." )

				-- Set cooldown if needed.
				if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.cooldown > 0 ) then
					travelpoints_table._cooldown = now
				end

				-- Save travelpoints_table.
				travelpoints.save_travelpoints_table("user", name, travelpoints_table)

			else

				-- Report
				travelpoints.print_notice(name, "Time remaining on your cooldown: " .. cooldown_remaining .. ".")

			end

		end

	end,
})

--[/tpgset]---------------------------------------------------------------------
--
--	Adds a new travelpoint to the world's global travelpoints table.
--
minetest.register_chatcommand("tpgset", {
	params = "<title> | <title> <desc>",
	description = "Set a new global travelpoint at your current location. Title required, description optional.",
	privs = {tpglobal=true},
	func = function(name, param)

		------------------------------------------------------------------------
		--	/tpgset
		------------------------------------------------------------------------

		if param == "" then
			travelpoints.print_notice(name, "Error: Travelpoint must be saved with a title.")
			return
		else

			--------------------------------------------------------------------
			--	/tpgset <title> | <title> <desc>
			--------------------------------------------------------------------

			local title, desc, notice, pos

			-- Get parameters.
			if string.find(param, "^[^ ]+%s+.+") then
				title, desc = string.match(param, "^([^ ]+)%s+(.+)")
			else
				title = param
				desc = ""
			end

			-- Validate Title.
			if title ~= nil then
				notice = travelpoints.validate_title(title)
				if notice ~= nil then
					travelpoints.print_notice(name, notice)
					return
				end
			end

			-- Validate Description.
			if desc ~= "" then
				notice = travelpoints.validate_desc(desc)
				if notice ~= nil then
					travelpoints.print_notice(name, notice)
					return
				end
			end

			-- Get player's location.
			pos = travelpoints.get_location(name)

			-- Initialize temporary travelpoint table.
			local travelpoint = {}

			-- Build travelpoint table.
			travelpoint.pos = pos
			travelpoint.desc = desc
			travelpoint.timestamp = os.time()

			-- Get travelpoints_table.
			local travelpoints_table = travelpoints.get_travelpoints_table("global", name)

			-- Check for duplicate title.
			if travelpoints_table[title] ~= nil then
				travelpoints.print_notice(name, "Error: A global travelpoint already exists for this title: " .. title)
			else

				-- Merge tables.
				travelpoints_table[title] = travelpoint

				-- Save travelpoints_table.
				if travelpoints.save_travelpoints_table("global", name, travelpoints_table) then
					travelpoints.print_notice(name, "Global travelpoint \"" .. title .. "\" has been saved.")
				else
					travelpoints.print_notice(name, "Error: Global travelpoint \"" .. title .. "\" could not be saved.")
				end

			end

		end

	end,
})

--[/travelpads]-----------------------------------------------------------------
--
--	Returns a list of transporter pads the user has placed.
--
minetest.register_chatcommand("travelpads", {
	params = "",
	description = "Lists the transporter pads you have placed.",
	privs = {travelpoints=true, travelpads=true},
	func = function(name, param)

		-- Get travelpoints_table.
		local travelpoints_table = travelpoints.get_travelpoints_table("user", name)

		-- Initialize array
		local travelpads = {}

		-- Pack array for count and sorting.
		if travelpoints_table._travelpads ~= nil then
			for key, value in pairs(travelpoints_table._travelpads) do
				if key ~= nil then
					table.insert(travelpads, value .. "|" .. key)
				end
			end
		end

		-- Sort values.
		table.sort(travelpads, function(A, B) return A > B end)

		local pad_count = #travelpads

		local now = os.time()

		-- List player's travelpads if there are any.
		if #travelpads == 0 then
			travelpoints.print_notice(name, "You have no placed transporter pads.")
		else
			local count = 1
			for key, value in ipairs(travelpads) do
				local values = value:split("|") -- builtin/misc_helpers.lua
				local since = now - values[1]
				-- <n>. Placed at (<x>, <y>, <z>) <duration> ago.
				travelpoints.print_notice(name, count .. ". Placed at " .. values[2] .. " " .. travelpoints.get_duration(since, 3) .. " ago.")
				count = count + 1
			end
		end

		-- Check conditions for handling max_travelpads.
		if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.max_travelpads > 0 ) and ( not minetest.get_player_privs(name)["server"] ) then
			local max_travelpads = travelpoints.restrictions.max_travelpads
			if max_travelpads > 0 then
				if pad_count < max_travelpads then
					if pad_count == 0 then
						travelpoints.print_notice(name, "You can place " .. max_travelpads .. " transporter pads.")
					else
						travelpoints.print_notice(name, "You can place " .. ( max_travelpads - pad_count ) .. " more transporter pads.")
					end
				elseif pad_count == max_travelpads then
					travelpoints.print_notice(name, "You can place no more transporter pads unless you remove older ones. Maximum allowed is " .. max_travelpads .. ".")
				end
			end
		end

	end,
})

--[/travelpoints]------------------------------------------------------------------
--
--	Gives player information about the mod and allows those with server privs to
--	modify restrictions in game.
--
minetest.register_chatcommand("travelpoints", {
	params = "(nothing) | set | set <restriction> <value>",
	description = "Provides players with details about the mod. Players with server privilege can use \"/travelpoints set\" to change restrictions.",
	privs = {travelpoints=true},
	func = function(name, param)

		------------------------------------------------------------------------
		--	/travelpoints
		------------------------------------------------------------------------

		if param == "" then

			if ( not minetest.is_singleplayer() ) then

				local max_travelpoints
				local max_travelpads
				local cooldown
				local player_cooldown = "none"
				local travelpads = {}
				local tpback
				local travelpoints_table = travelpoints.get_travelpoints_table("user", name)
				local travelpoints_array = travelpoints.get_travelpoints_array("user", name)

				-- Max travelpoints
				if minetest.get_player_privs(name)["server"] then
					max_travelpoints = "No limit (server privilege)"
				elseif travelpoints.restrictions.max_travelpoints == 0 then
					max_travelpoints = "No limit"
				else
					max_travelpoints = travelpoints.restrictions.max_travelpoints
				end

				-- Max travelpads
				if minetest.get_player_privs(name)["server"] then
					max_travelpads = "No limit (server privilege)"
				elseif travelpoints.restrictions.max_travelpads == 0 then
					max_travelpads = "No limit"
				else
					max_travelpads = travelpoints.restrictions.max_travelpads
				end

				-- Cooldown
				if minetest.get_player_privs(name)["server"] then
					cooldown = "No cooldown (server privilege)"
				elseif travelpoints.restrictions.cooldown == 0 then
					cooldown = "No cooldown"
				else
					cooldown = travelpoints.get_duration(travelpoints.restrictions.cooldown)
				end

				-- Player cooldown
				if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.cooldown > 0 ) and ( not minetest.get_player_privs(name)["server"] ) then
					if travelpoints_table._cooldown ~= nil then
						local difference = os.time() - travelpoints_table._cooldown
						if difference < travelpoints.restrictions.cooldown then
							player_cooldown = travelpoints.get_duration(difference)
						end
					end
				end

				if travelpoints.restrictions.clear_back_pos > 0 then
					tpback = "is cleared after use"
				else
					tpback = "not cleared after use"
				end

				if travelpoints_table._travelpads ~= nil then
					-- Pack array to get travelpad count.
					for key, value in pairs(travelpoints_table._travelpads) do
						if key ~= nil then
							table.insert(travelpads, key)
						end
					end
				end

				-- Report
				travelpoints.print_notice(name, "Running Travelpoints version " .. travelpoints.version_number .. " released on " .. travelpoints.version_date .. ".")
				travelpoints.print_notice(name, "Restrictions:")
				travelpoints.print_notice(name, "Max Travelpoints: [" .. max_travelpoints .. "] You have: [" .. #travelpoints_array .. "]")
				travelpoints.print_notice(name, "Max Transporter Pads: [" .. max_travelpads .. "] You have: [" .. #travelpads .. "]")
				travelpoints.print_notice(name, "Cooldown: [" .. cooldown .. "] Your cooldown is: [" .. player_cooldown .. "]")
				travelpoints.print_notice(name, "Back Location: [" .. tpback .. "]")

			else
				-- Report
				travelpoints.print_notice(name, "Running Travelpoints version " .. travelpoints.version_number .. " released on " .. travelpoints.version_date .. ".")
			end

		------------------------------------------------------------------------
		--	/travelpoints set
		------------------------------------------------------------------------

		-- Show available restrictions.
		elseif param == "set" then

			-- Check privs.
			if minetest.get_player_privs(name)["server"] then
				travelpoints.print_notice(name, "Available restrictions to modify with \"/travelpoints set <restriction> <value>\" are:")
				travelpoints.print_notice(name, "max_travelpoints <value> - Change travelpoints limit, \"0\" for no limit. Currently: " .. travelpoints.restrictions.max_travelpoints)
				travelpoints.print_notice(name, "max_travelpads <value> - Change travelpads limit, \"0\" for no limit. Currently: " .. travelpoints.restrictions.max_travelpads)
				travelpoints.print_notice(name, "cooldown <value> - Change cooldown time, \"0\" for no cooldown. Currently: " .. travelpoints.restrictions.cooldown)
				travelpoints.print_notice(name, "clear_back_pos <value> - Change /tpback location setting. Currently: " .. travelpoints.restrictions.clear_back_pos)
			else
				travelpoints.print_notice(name, "Server privilege required for that command.")
			end

		------------------------------------------------------------------------
		--	/travelpoints set <restriction> <value>
		------------------------------------------------------------------------

		-- Check parameters.
		elseif string.find(param, "^set [%w_ ]+") then

			-- Check privs.
			if minetest.get_player_privs(name)["server"] then

				local restriction, value

				-- Split parameters
				local parameters = param:split(" ") -- builtin/misc_helpers.lua

				-- Table to test <restriction> against.
				local restrictions = { max_travelpoints = true, max_travelpads = true, cooldown = true,  clear_back_pos = true }

				-- Validate <restriction>
				if restrictions[parameters[2]] then
					restriction = parameters[2]
				else
					travelpoints.print_notice(name, "Error: Restriction name was mistyped.")
					return
				end

				-- Validate <value>
				if type(tonumber(parameters[3])) == "number" then
					value = tonumber(parameters[3])
				else
					travelpoints.print_notice(name, "Error: Restriction value must be a number.")
					return
				end

				local change_made = false

				-- Validate input.
				local result, error_message = travelpoints.validate_restriction_value(restriction, value)

				-- Max Travelpoints
				if restriction == "max_travelpoints" then

					if value == travelpoints.restrictions.max_travelpoints then
						travelpoints.print_notice(name, "There was no change to max_travelpoints.")
					elseif result then
						travelpoints.restrictions.max_travelpoints = value
						travelpoints.print_notice(name, "Value of max_travelpoints is now " .. travelpoints.restrictions.max_travelpoints .. ".")
						change_made = true
					else
						travelpoints.print_notice(name, error_message)
					end

				-- Max Travelpads
				elseif restriction == "max_travelpads" then

					if value == travelpoints.restrictions.max_travelpads then
						travelpoints.print_notice(name, "There was no change to max_travelpads.")
					elseif result then
						travelpoints.restrictions.max_travelpads = value
						travelpoints.print_notice(name, "Value of max_travelpads is now " .. travelpoints.restrictions.max_travelpads .. ".")
						change_made = true
					else
						travelpoints.print_notice(name, error_message)
					end

				-- Cooldown
				elseif restriction == "cooldown" then

					if value == travelpoints.restrictions.cooldown then
						travelpoints.print_notice(name, "There was no change to cooldown.")
					elseif result then
						travelpoints.restrictions.cooldown = value
						travelpoints.print_notice(name, "Value of cooldown is now " .. travelpoints.restrictions.cooldown .. ".")
						change_made = true
					else
						travelpoints.print_notice(name, error_message)
					end

				-- Clear Back Pos
				elseif restriction == "clear_back_pos" then

					if value == travelpoints.restrictions.clear_back_pos then
						travelpoints.print_notice(name, "There was no change to clear_back_pos.")
					elseif result then
						travelpoints.restrictions.clear_back_pos = value
						travelpoints.print_notice(name, "Value of clear_back_pos is now " .. travelpoints.restrictions.clear_back_pos .. ".")
						change_made = true
					else
						travelpoints.print_notice(name, error_message)
					end

				else
					travelpoints.print_notice(name, "Error: Restriction name was mistyped.")
				end

				-- Save changes.
				if change_made then
					-- Save changes to world's "travelpoints_restrictions" file.
					if travelpoints.save_world_restrictions(travelpoints.restrictions) then
						travelpoints.print_notice(name, "Restrictions for this world saved.")
					else
						travelpoints.print_notice(name, "Error: Restrictions for this world could not be saved.")
					end
				end

			else
				travelpoints.print_notice(name, "Server privilege required for that command.")
			end

		else
			travelpoints.print_notice(name, "Error: Command could not be processed, you may have mistyped it.")
		end

	end,

})

--[/tpset]---------------------------------------------------------------------
--
--	Adds a new travelpoint to the player's travelpoints_table for the current
--	world.
--
minetest.register_chatcommand("tpset", {
	params = "<title> | <title> <desc>",
	description = "Set a new travelpoint at your current location. Title required, description optional.",
	privs = {travelpoints=true},
	func = function(name, param)

		------------------------------------------------------------------------
		--	/tpset
		------------------------------------------------------------------------

		if param == "" then
			travelpoints.print_notice(name, "Error: Travelpoint must be saved with a title.")
			return
		else

		------------------------------------------------------------------------
		--	/tpset <title> | <title> <desc>
		------------------------------------------------------------------------

			local tp_count = #travelpoints.get_travelpoints_array("user", name)

			-- Handle maximum_travelpoints if it is configured.
			if ( not minetest.is_singleplayer() ) and ( travelpoints.restrictions.max_travelpoints > 0 ) and ( tp_count >= travelpoints.restrictions.max_travelpoints ) and ( not minetest.get_player_privs(name)["server"] ) then

				travelpoints.print_notice(name, "You have already reached your maximum number of travelpoints: " .. travelpoints.restrictions.max_travelpoints .. ".")

				return

			else

				local title, desc, notice, pos

				-- Get parameters.
				if string.find(param, "^[^ ]+%s+.+") then
					title, desc = string.match(param, "^([^ ]+)%s+(.+)")
				else
					title = param
					desc = ""
				end

				-- Validate Title.
				if title ~= nil then
					notice = travelpoints.validate_title(title)
					if notice ~= nil then
						travelpoints.print_notice(name, notice)
						return
					end
				end

				-- Validate Description.
				if desc ~= "" then
					notice = travelpoints.validate_desc(desc)
					if notice ~= nil then
						travelpoints.print_notice(name, notice)
						return
					end
				end

				-- Get player's location.
				pos = travelpoints.get_location(name)

				-- Initialize temporary travelpoint table.
				local travelpoint = {}

				-- Build travelpoint table.
				travelpoint.pos = pos
				travelpoint.desc = desc
				travelpoint.timestamp = os.time()

				-- Get travelpoints_table.
				local travelpoints_table = travelpoints.get_travelpoints_table("user", name)

				-- Check for duplicate title.
				if travelpoints_table[title] ~= nil then
					travelpoints.print_notice(name, "Error: A travelpoint already exists for this title: " .. title)
				else

					-- Merg tables.
					travelpoints_table[title] = travelpoint

					-- Save travelpoints_table.
					if travelpoints.save_travelpoints_table("user", name, travelpoints_table) then
						travelpoints.print_notice(name, "Travelpoint \"" .. title .. "\" has been saved.")
					else
						travelpoints.print_notice(name, "Error: Travelpoint \"" .. title .. "\" could not be saved.")
					end

				end

			end

		end

	end,
})

--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------