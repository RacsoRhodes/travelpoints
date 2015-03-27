--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.4                            2015-03-27
--
-- By Racso Rhodes
--
-- travelpoints/config.lua
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
--	About Config
--
--	Restrictions
--
--		Maximum Travelpoints
--		Maximum Travelpads
--		Cooldown
--		Clear Back Pos
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- About Config
--------------------------------------------------------------------------------
--
--	If any values placed here are invalid the script will ignore them and use
--	hard coded, default values instead.
--
--	The restrictions are for multiplayer servers and are ignored when playing
--	singleplayer.
--
--	Restrictions here are the global default, they can be modified in game, per
--	world, by using the command: /travelpoints set <restriction> <value>
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Restrictions
--------------------------------------------------------------------------------

--[Maximum Travelpoints]--------------------------------------------------------
--
--	Limit the amount of travelpoints a player can save.
--
--	0 for no limit.

travelpoints.restrictions.max_travelpoints = 35

--[Maximum Travelpads]----------------------------------------------------------
--
--	Limit the amount of transporter pads a player can place.
--
--	0 for no limit.

travelpoints.restrictions.max_travelpads = 25

--[Cooldown]--------------------------------------------------------------------
--
--	Set a cooldown in seconds for how long a player must wait before they can
--	use the /tpgo <title> command again.
--
--	0 for no cooldown.
--
--	Example values
--
--		900	= 15 minutes
--		15*60 = 15 minutes
--		30*60 = 30 minutes
--		60*60 = 1 hour
--
--		Maximum cooldown is 3600 seconds (one hour)

travelpoints.restrictions.cooldown = 5*60

--[Clear Back Pos]--------------------------------------------------------------
--
--	Set this value to "1" to clear the coords used by /tpback after use.
--
--	Valid values: 1 | 0

travelpoints.restrictions.clear_back_pos = 0

--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------