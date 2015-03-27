--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.4                            2015-03-27
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

	on_destruct = travelpoints.on_destruct,

	after_place_node = travelpoints.after_place_node,

	on_receive_fields = travelpoints.on_receive_fields,

	can_dig = travelpoints.can_dig,

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

	on_destruct = travelpoints.on_destruct,

	after_place_node = travelpoints.after_place_node,

	on_receive_fields = travelpoints.on_receive_fields,

	can_dig = travelpoints.can_dig,

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
--	Swaps active and inactive pad nodes, and sends player to destination.
--
minetest.register_abm({
	nodenames = {"travelpoints:transporter_pad", "travelpoints:transporter_pad_active"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)

		local meta = minetest.get_meta(pos)

		--[Convert old pads to version 1.4]-------------------------------------------------
		if meta:get_string("version") ~= "1.4" then
			
			meta:set_string("source", "Mine")
			meta:set_string("version", "1.4")
			meta:set_string("tp_array", "return { }")
			meta:set_int("tp_index", 0)
			meta:set_string("formspec", travelpoints.get_formspec("", meta))
			meta:set_string("infotext", travelpoints.get_infotext(meta))
			
		--[travelpoints:transporter_pad]----------------------------------------------------
		--
		elseif node.name == "travelpoints:transporter_pad" then

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