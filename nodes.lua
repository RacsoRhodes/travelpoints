--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.3                            2015-03-24
--
-- By Racso Rhodes
--
-- travelpoints/nodes.lua
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
--	Recipes
--
--		travelpoints:transporter_pad
--		travelpoints:pad_light
--		travelpoints:receiver_pad
--		default:mese_crystal 10
--		default:mese_crystal 2
--		default:mese_crystal
--
--	Nodes
--
--		travelpoints:transporter_pad
--		travelpoints:transporter_pad_active
--		travelpoints:pad_light
--		travelpoints:receiver_pad
--
--	ABMs
--
--		travelpoints:transporter_pad/_active
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Recipes
--------------------------------------------------------------------------------

--[travelpoints:transporter_pad]------------------------------------------------------------

minetest.register_craft({
	output = 'travelpoints:transporter_pad',
	recipe = {
		{'default:copper_ingot', 'default:glass', 'default:copper_ingot'},
		{'default:steel_ingot', 'default:mese', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:gold_ingot', 'default:steel_ingot'},
	}
})

--[travelpoints:pad_light]-------------------------------------------------------

minetest.register_craft({
	output = 'travelpoints:pad_light',
	recipe = {
		{'default:copper_ingot', 'default:steel_ingot', 'default:copper_ingot'},
		{'default:steel_ingot', 'default:mese_crystal', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:glass', 'default:steel_ingot'},
	}
})

--[travelpoints:receiver_pad]-------------------------------------------------------

minetest.register_craft({
	output = 'travelpoints:receiver_pad',
	recipe = {
		{'', '', ''},
		{'default:copper_ingot', 'default:steel_ingot', 'default:copper_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})

--[default:mese_crystal 10]-----------------------------------------------------

minetest.register_craft({
	output = 'default:mese_crystal 10',
	recipe = {
		{'travelpoints:transporter_pad'},
	}
})

--[default:mese_crystal 2]-------------------------------------------------------

minetest.register_craft({
	output = 'default:mese_crystal 2',
	recipe = {
		{'travelpoints:pad_light'},
	}
})

--[default:mese_crystal]-------------------------------------------------------

minetest.register_craft({
	output = 'default:mese_crystal',
	recipe = {
		{'travelpoints:receiver_pad'},
	}
})

--------------------------------------------------------------------------------
-- Nodes
--------------------------------------------------------------------------------

--[travelpoints:transporter_pad]------------------------------------------------------

minetest.register_node("travelpoints:transporter_pad", {
	description = "Transporter Pad",
	tiles = {
		"travelpoints_transporter_pad_top.png",
		"travelpoints_transporter_pad_bottom.png",
		"travelpoints_transporter_pad_side.png",
		"travelpoints_transporter_pad_side.png",
		"travelpoints_transporter_pad_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=1},
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.4375, -0.5, 0.5,	-0.5, 0.5 },
		},
	},
	sounds = default.node_sound_stone_defaults(),

	----------------------------------------------------------------------------
	-- ON DESTRUCT
	----------------------------------------------------------------------------

	on_destruct = function(pos)

		-- Get nodes metadata.
		local meta = minetest.get_meta(pos)

		if meta:get_string("owner") ~= "" then

			-- Remove travelpad from log.
			travelpoints.travelpad_log(meta:get_string("owner"), meta, "remove")

		end

	end,

	----------------------------------------------------------------------------
	-- AFTER PLACE NODE
	----------------------------------------------------------------------------

	after_place_node = function(pos, placer)

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
			meta:set_int("timestamp", os.time())
			meta:set_int("modstamp", 0)
			meta:set_int("tp_index", 1)
			meta:set_int("mode_index", 1)
			meta:set_string("players", "return {  }")

			-- Add travelpad to log.
			travelpoints.travelpad_log(name, meta, "add")

			-- Get the current travelpoints array.
			local travelpoints_array = travelpoints.get_travelpoints_array(name)

			-- Serialize travelpoints_array.
			local travelpoints_array = minetest.serialize(travelpoints_array)

			-- Save travelpoints_array.
			meta:set_string("travelpoints_array", travelpoints_array)

			-- Save default formspec
			meta:set_string("formspec", travelpoints.get_formspec(meta))

			-- Save default infotext.
			meta:set_string("infotext", travelpoints.get_infotext(meta))

		end

	end,

	----------------------------------------------------------------------------
	-- ON RECIEVE FIELDS
	----------------------------------------------------------------------------

	on_receive_fields = function(pos, formname, fields, sender)

		local meta = minetest.get_meta(pos)

		local name = sender:get_player_name()

		local owner = meta:get_string("owner")

		-- Only pad owner or a player with server privilege can make changes.
		if ( name == owner ) or ( minetest.get_player_privs(name)["server"] ) then

			--------------------------------------------------------------------
			-- Handle get travelpoints press.
			--------------------------------------------------------------------
			--
			-- This syncs the node's travelpoints_array with the owner's current
			-- travelpoints_table.
			--
			if ( fields.list_travelpoints == "List Travelpoints" ) and ( name == owner ) then

				-- Get the current travelpoints array.
				local travelpoints_array = travelpoints.get_travelpoints_array(owner)

				-- Serialize travelpoints_array.
				local travelpoints_array = minetest.serialize(travelpoints_array)

				-- Save travelpoints_array.
				meta:set_string("travelpoints_array", travelpoints_array)

				-- Set pad to "Offline".
				--
				-- Assumed that player chose to refresh in order to point the pad to
				-- new coords.
				--
				meta:set_string("title", "")
				meta:set_string("destination", "")
				meta:set_int("tp_index", 1)

				-- Save modification timestamp.
				meta:set_int("modstamp", os.time())

				-- Save formspec.
				meta:set_string("formspec", travelpoints.get_formspec(meta))

				-- Save infotext.
				meta:set_string("infotext", travelpoints.get_infotext(meta))

			--------------------------------------------------------------------
			-- Handle travelpoint selection.
			--------------------------------------------------------------------

			elseif ( fields.travelpoint ) and ( name == owner) then

				-- Get index value.
				local index = travelpoints.get_textlist_index(fields.travelpoint)

				if index ~= meta:get_int("tp_index") then

					-- Get this node's travelpoints_array.
					local travelpoints_array = minetest.deserialize(meta:get_string("travelpoints_array"))

					-- Extract title and destination from array value.
					local title, destination = string.match(travelpoints_array[index], "^([^ ]+)%s+(.+)")

					-- Remove escapes.
					destination = string.gsub(destination, "\\", "", 2)

					-- Pads can't teleport to themselves.
					if destination ~= minetest.pos_to_string(pos) then

						-- Set or clear title and destination meta data.
						if ( index == 1 ) or ( index > #travelpoints_array ) then
							meta:set_string("title", "")
							meta:set_string("destination", "")
							meta:set_int("tp_index", 1)
							meta:set_string("travelpoints_array", "return {  }")
						else
							meta:set_string("title", title)
							meta:set_string("destination", destination)
							meta:set_int("tp_index", index)
							meta:set_string("travelpoints_array", "return {  }")
						end

						-- Save modification timestamp.
						meta:set_int("modstamp", os.time())

						-- Save formspec.
						meta:set_string("formspec", travelpoints.get_formspec(meta))

						-- Save infotext.
						meta:set_string("infotext", travelpoints.get_infotext(meta))

					else

						-- Report
						travelpoints.print_notice(name, "Error: You can not set the transporter pad's location as its destination.")

					end

				end

			--------------------------------------------------------------------
			-- Handle player addition.
			--------------------------------------------------------------------

			elseif ( fields.add_player == "Add Player" ) and ( string.len(fields.player_name) > 0 ) and ( name == owner) then

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
								meta:set_string("formspec", travelpoints.get_formspec(meta))

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
			-- Handle remove player.
			--------------------------------------------------------------------

			elseif ( fields.remove_player == "Remove Player" ) and ( name == owner ) then

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
					meta:set_string("formspec", travelpoints.get_formspec(meta))

				end

			--------------------------------------------------------------------
			-- Handle unset button press
			--------------------------------------------------------------------

			elseif fields.unset_destination == "Unset Destination" then

				-- Clear destination.
				meta:set_string("title", "")
				meta:set_string("destination", "")
				meta:set_int("tp_index", 1)

				-- Save modification timestamp.
				meta:set_int("modstamp", os.time())

				-- Save formspec.
				meta:set_string("formspec", travelpoints.get_formspec(meta))

				-- Save infotext.
				meta:set_string("infotext", travelpoints.get_infotext(meta))

			--------------------------------------------------------------------
			-- Handle pad access mode and save buttun press or escape key press.
			--------------------------------------------------------------------

			elseif ( fields.save == "Save" ) or ( fields.quit == "true" ) then

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
				meta:set_string("formspec", travelpoints.get_formspec(meta))

			else
				travelpoints.print_notice(name, "Only the owner of this pad can modify those fields")
			end

		else

			-- Report
			travelpoints.print_notice(name, "This transporter pad belongs to \"" .. owner .. "\", you can not modify it")

		end

	end,

	----------------------------------------------------------------------------
	-- CAN DIG
	----------------------------------------------------------------------------

	can_dig = function(pos, player)

		-- Get node's metadata.
		local meta = minetest.get_meta(pos)

		-- Get player's name.
		local name = player:get_player_name()

		-- Pads can be dug by their owners or by someone with server privilege.
		if ( minetest.get_player_privs(name)["server"] ) or ( meta:get_string("owner") == name ) then

			-- Check if travelpad is "offline".
			if meta:get_string("destination") == "" then
				return true
			else
				travelpoints.print_notice(name, "A transporter pad can not be dug unless its destination is set to \"none\".")
				return false
			end

		-- Anyone else.
		else
			travelpoints.print_notice(name, "You can not dig a transporter pad you do not own.")
			return false
		end

	end,

})

--[travelpoints:transporter_pad_active]------------------------------------------------------

minetest.register_node("travelpoints:transporter_pad_active", {
	description = "Active Transporter Pad",
	tiles = {
		"travelpoints_transporter_pad_top_active.png",
		"travelpoints_transporter_pad_bottom.png",
		"travelpoints_transporter_pad_side.png",
		"travelpoints_transporter_pad_side.png",
		"travelpoints_transporter_pad_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	drop = "travelpoints:transporter_pad",
	groups = {cracky=1, not_in_creative_inventory=1},
	light_source = 8,
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.4375, -0.5, 0.5, -0.5, 0.5 },
		},
	},
	sounds = default.node_sound_stone_defaults(),

	----------------------------------------------------------------------------
	-- ON DESTRUCT
	----------------------------------------------------------------------------

	on_destruct = function(pos)

		-- Get nodes metadata.
		local meta = minetest.get_meta(pos)

		if meta:get_string("owner") ~= "" then

			-- Remove travelpad from log.
			travelpoints.travelpad_log(meta:get_string("owner"), meta, "remove")

		end

	end,

	----------------------------------------------------------------------------
	-- AFTER PLACE NODE
	----------------------------------------------------------------------------

	after_place_node = function(pos, placer)

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
			meta:set_int("timestamp", os.time())
			meta:set_int("modstamp", 0)
			meta:set_int("tp_index", 1)
			meta:set_int("mode_index", 1)
			meta:set_string("players", "return {  }")

			-- Add travelpad to log.
			travelpoints.travelpad_log(name, meta, "add")

			-- Get the current travelpoints array.
			local travelpoints_array = travelpoints.get_travelpoints_array(name)

			-- Serialize travelpoints_array.
			local travelpoints_array = minetest.serialize(travelpoints_array)

			-- Save travelpoints_array.
			meta:set_string("travelpoints_array", travelpoints_array)

			-- Save default formspec
			meta:set_string("formspec", travelpoints.get_formspec(meta))

			-- Save default infotext.
			meta:set_string("infotext", travelpoints.get_infotext(meta))

		end

	end,

	----------------------------------------------------------------------------
	-- ON RECIEVE FIELDS
	----------------------------------------------------------------------------

	on_receive_fields = function(pos, formname, fields, sender)

		local meta = minetest.get_meta(pos)

		local name = sender:get_player_name()

		local owner = meta:get_string("owner")

		-- Only pad owner or a player with server privilege can make changes.
		if ( name == owner ) or ( minetest.get_player_privs(name)["server"] ) then

			--------------------------------------------------------------------
			-- Handle get travelpoints press.
			--------------------------------------------------------------------
			--
			-- This syncs the node's travelpoints_array with the owner's current
			-- travelpoints_table.
			--
			if ( fields.list_travelpoints == "List Travelpoints" ) and ( name == owner ) then

				-- Get the current travelpoints array.
				local travelpoints_array = travelpoints.get_travelpoints_array(owner)

				-- Serialize travelpoints_array.
				local travelpoints_array = minetest.serialize(travelpoints_array)

				-- Save travelpoints_array.
				meta:set_string("travelpoints_array", travelpoints_array)

				-- Set pad to "Offline".
				--
				-- Assumed that player chose to refresh in order to point the pad to
				-- new coords.
				--
				meta:set_string("title", "")
				meta:set_string("destination", "")
				meta:set_int("tp_index", 1)

				-- Save modification timestamp.
				meta:set_int("modstamp", os.time())

				-- Save formspec.
				meta:set_string("formspec", travelpoints.get_formspec(meta))

				-- Save infotext.
				meta:set_string("infotext", travelpoints.get_infotext(meta))

			--------------------------------------------------------------------
			-- Handle travelpoint selection.
			--------------------------------------------------------------------

			elseif ( fields.travelpoint ) and ( name == owner) then

				-- Get index value.
				local index = travelpoints.get_textlist_index(fields.travelpoint)

				if index ~= meta:get_int("tp_index") then

					-- Get this node's travelpoints_array.
					local travelpoints_array = minetest.deserialize(meta:get_string("travelpoints_array"))

					-- Extract title and destination from array value.
					local title, destination = string.match(travelpoints_array[index], "^([^ ]+)%s+(.+)")

					-- Remove escapes.
					destination = string.gsub(destination, "\\", "", 2)

					-- Pads can't teleport to themselves.
					if destination ~= minetest.pos_to_string(pos) then

						-- Set or clear title and destination meta data.
						if ( index == 1 ) or ( index > #travelpoints_array ) then
							meta:set_string("title", "")
							meta:set_string("destination", "")
							meta:set_int("tp_index", 1)
							meta:set_string("travelpoints_array", "return {  }")
						else
							meta:set_string("title", title)
							meta:set_string("destination", destination)
							meta:set_int("tp_index", index)
							meta:set_string("travelpoints_array", "return {  }")
						end

						-- Save modification timestamp.
						meta:set_int("modstamp", os.time())

						-- Save formspec.
						meta:set_string("formspec", travelpoints.get_formspec(meta))

						-- Save infotext.
						meta:set_string("infotext", travelpoints.get_infotext(meta))

					else

						-- Report
						travelpoints.print_notice(name, "Error: You can not set the transporter pad's location as its destination.")

					end

				end

			--------------------------------------------------------------------
			-- Handle player addition.
			--------------------------------------------------------------------

			elseif ( fields.add_player == "Add Player" ) and ( string.len(fields.player_name) > 0 ) and ( name == owner) then

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
								meta:set_string("formspec", travelpoints.get_formspec(meta))

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
			-- Handle remove player.
			--------------------------------------------------------------------

			elseif ( fields.remove_player == "Remove Player" ) and ( name == owner ) then

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
					meta:set_string("formspec", travelpoints.get_formspec(meta))

				end

			--------------------------------------------------------------------
			-- Handle unset button press
			--------------------------------------------------------------------

			elseif fields.unset_destination == "Unset Destination" then

				-- Clear destination.
				meta:set_string("title", "")
				meta:set_string("destination", "")
				meta:set_int("tp_index", 1)

				-- Save modification timestamp.
				meta:set_int("modstamp", os.time())

				-- Save formspec.
				meta:set_string("formspec", travelpoints.get_formspec(meta))

				-- Save infotext.
				meta:set_string("infotext", travelpoints.get_infotext(meta))

			--------------------------------------------------------------------
			-- Handle pad access mode and save buttun press or escape key press.
			--------------------------------------------------------------------

			elseif ( fields.save == "Save" ) or ( fields.quit == "true" ) then

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
				meta:set_string("formspec", travelpoints.get_formspec(meta))

			else
				travelpoints.print_notice(name, "Only the owner of this pad can modify those fields")
			end

		else

			-- Report
			travelpoints.print_notice(name, "This transporter pad belongs to \"" .. owner .. "\", you can not modify it")

		end

	end,

	----------------------------------------------------------------------------
	-- CAN DIG
	----------------------------------------------------------------------------

	can_dig = function(pos, player)

		-- Get node's metadata.
		local meta = minetest.get_meta(pos)

		-- Get player's name.
		local name = player:get_player_name()

		-- Pads can be dug by their owners or by someone with server privilege.
		if ( minetest.get_player_privs(name)["server"] ) or ( meta:get_string("owner") == name ) then

			-- Check if travelpad is "offline".
			if meta:get_string("destination") == "" then
				return true
			else
				travelpoints.print_notice(name, "A transporter pad can not be dug unless its destination is set to \"none\".")
				return false
			end

		-- Anyone else.
		else
			travelpoints.print_notice(name, "You can not dig a transporter pad you do not own.")
			return false
		end

	end,

})

--[travelpoints:pad_light]-------------------------------------------------------

minetest.register_node("travelpoints:pad_light", {
	description = "Pad Light",
	tiles = {
		"travelpoints_pad_light_top.png",
		"travelpoints_pad_light_bottom.png",
		"travelpoints_pad_light_side.png",
		"travelpoints_pad_light_side.png",
		"travelpoints_pad_light_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2},
	light_source = 10,
	post_effect_color = {a=65, r=205, g=255, b=255},
	node_box = {
		type = "fixed",
		fixed = {
			{ 0.5, 0.5, 0.5, -0.5, 0.4375, -0.5 },
		},
	},
	sounds = default.node_sound_stone_defaults(),
})

--[travelpoints:receiver_pad]-------------------------------------------------

minetest.register_node("travelpoints:receiver_pad", {
	description = "Receiver Pad",
	tiles = {
		"travelpoints_receiver_pad_top.png",
		"travelpoints_receiver_pad_bottom.png",
		"travelpoints_receiver_pad_side.png",
		"travelpoints_receiver_pad_side.png",
		"travelpoints_receiver_pad_side.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky=2},
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.4375, -0.5, 0.5, -0.5, 0.5 },
		},
	},
	sounds = default.node_sound_stone_defaults(),
})

--------------------------------------------------------------------------------
-- ABMs
--------------------------------------------------------------------------------

--[travelpoints:transporter_pad/_active]----------------------------------------------------
--
--	Swaps active and innactive pad nodes, and sends player to destination.
--
minetest.register_abm({
	nodenames = {"travelpoints:transporter_pad", "travelpoints:transporter_pad_active"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)

		local meta = minetest.get_meta(pos)

		--[travelpoints:transporter_pad]----------------------------------------------------
		--
		if node.name == "travelpoints:transporter_pad" then

			-- If pad has a destination, swap to active pad.
			if ( meta:get_string("title") ~= "" ) and ( meta:get_string("destination") ~= "" ) then

				travelpoints.swap_node(pos,"travelpoints:transporter_pad_active")

				-- Add travelpad to log.
				-- Swapping it triggers on_destruct, this compensates that.
				travelpoints.travelpad_log(meta:get_string("owner"), meta, "add")

			end

		--[travelpoints:transporter_pad_active]---------------------------------------------
		--
		elseif node.name == "travelpoints:transporter_pad_active" then

			-- If pad has no destination, swap to inactive pad.
			if ( meta:get_string("title") == "" ) or ( meta:get_string("destination") == "" ) then

				travelpoints.swap_node(pos,"travelpoints:transporter_pad")

				-- Add travelpad to log.
				-- Swapping it triggers on_destruct, this compensates that.
				travelpoints.travelpad_log(meta:get_string("owner"), meta, "add")

			else

				-- Get references to closest objects.
				local objects = minetest.get_objects_inside_radius(pos, 1)

				-- Step through objects.
				for key, value in pairs(objects) do

					-- Check if object is a player.
					if value:is_player() then

						-- Get player's name.
						local player = value:get_player_name()

						-- Get node's metadata.
						local meta = minetest.get_meta(pos)

						-- Get pos to send player to.
						local topos = minetest.string_to_pos(meta:get_string("destination"))

						if travelpoints.player_can_use_pad(meta, player) then

							minetest.sound_play("travelpoints_pad_teleport", {pos = pos, gain = 2.0, max_hear_distance = 10,})

							value:setpos(topos)

							minetest.sound_play("travelpoints_pad_teleport", {pos = topos, gain = 2.0, max_hear_distance = 10,})

						end

						break

					end

				end

			end

		end

	end

})

--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------