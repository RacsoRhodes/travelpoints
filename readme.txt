--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.3                            2015-03-24
--
-- By Racso Rhodes
--
-- travelpoints/readme.txt
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
--	01. Changelog
--
--	02. About Travelpoints
--
--	03. Install Mod
--
--	04. Textures
--
--	05. Chat Commands
--
--		1.0 /travelpoints
--		1.1 /travelpoints set
--		1.2 /travelpoints set <restriction> <value>
--
--		2.0 /tpset <title>
--		2.1 /tpset <title> <desc>
--
--		3.0 /tpgo
--		3.1 /tpgo <title>
--
--		4.0 /tpback
--
--		5.0 /tpdrop <title>
--		5.1 /tpdrop all
--
--		6.0 /travelpads
--
--	06. Nodes
--
--		1.0 travelpoints:transporter_pad
--
--			A. Recipe
--			B. Refund
--
--		2.0 travelpoints:pad_light
--
--			A. Recipe
--			B. Refund
--
--		3.0 travelpoints:receiver_pad
--
--			A. Recipe
--			B. Refund
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
01. Changelog
--------------------------------------------------------------------------------

	1.3 2015-03-24
	
		! This version is preparing the project for GitHub and addressing minor
			issues.
		* Changed email address in all files: racsorhodes@gmail.com
		* config.lua - Fixed some wording in "About Config", including a
			reference to the old name of this mod.
		* readme.txt - Changed wording and corrected spelling.
		* Renamed sound file "pad_teleport.ogg" to 
			"travelpoints_pad_teleport.ogg".
		* nodes.lua - Updated ABM definition for the change in the sound file
			name.
		* Various spelling corrections.
		* readme.txt - Updated with GitHub URLs.

	1.2	2013-12-21
	
		* Textures are now hard coded in node definitions as suggested by
			"addi".
		- Removed function travelpoints.get_node_textures()
		* Removed texture resolution setting from config.lua.
		* Removed texture validation from travelpoints.validate_config()
		* Updated texture information in readme.txt.
		* Changed screenshot, no longer showing version number.
	
	1.1 2013-12-20
		
		! Renamed project from "Waypoints" to "Travelpoints".
		* Renamed all functions and wording to match change in mod name.
		* Replaced calls to minetest.env:get_player_by_name() to
			minetest.get_player_by_name()
		* Various minor fixes, typos and the like.
		* Replaced call to minetest.env:get_objects_inside_radius() with
			minetest.get_objects_inside_radius()
		* Changed readme.txt to reflect the rebranding.
		* Improved the description and General Usage to more clearly explain
			what this mod does.
		* Changed placement of "Last Modified" on formspec.
		* Changed screenshot.
	
	1.0 2013-12-16
	
		! Initial release.

--------------------------------------------------------------------------------
02. About Travelpoints
--------------------------------------------------------------------------------

	This mod is for Minetest 0.4.8 or the latest build.
	
	Save world specific bookmarks to locations you travel to as "travelpoints",
	then easily teleport to those travelpoints.

	You can also create transporter pads whose destination can be set to an
	existing travelpoint, no need to ever enter coords by hand.

	General Usage
	
		The travelpoints mod allows you to save world specific, location
		bookmarks to the places you travel using "/tpset <title>".
		
		You can then use "/tpgo <title>" to teleport to the given location.
		
		If you wish to return to the location you just came from, use "/tpback".

		You can list your collection of travelpoints by using the command
		"/tpgo".
		
		If you want to delete an old travelpoint you no longer need, use
		"/tpdrop <title>".
		
		Make transporter pads for those travelpoints you use quite often.
		
		After placing a transporter pad, and right clicking it you can see a
		list of your existing travelpoints, allowing you to choose one as the
		destination of the transporter pad.
		
		When playing multiplayer you can also set usage modes, allowing only you
		to use the transporter pad, anyone to use the pad, you and a list of
		players, or everyone except a list of players.
		
		There are also decorative nodes. One is a light that you can place above
		the transporter pad. As well as a receiving pad which you can place at
		the destination of a transporter pad with a light above it for show.
		
		For more commands, and more thorough explanation of the above
		commands, see section 5 of this file below.
	
	Restrictions
	
		There are no restrictions in singleplayer mode, but those running
		multiplayer servers are able to set restrictions in the 
		travelpoints/config.lua file, as well as set world specific restrictions
		using /travelpoints set <restriction> <value> in game.
		
		Server administrators can restrict the following features:
		
			max_travelpoints - The maximum travelpoints a player can save.
			max_travelpads - The maximum transporter pads a player can place.
			cooldown - Impose a cooldown between usage of /tpgo <title>
			clear_back_pos - Clear the return location after use.
		
		Players with "server" privilege are not affected by these restrictions.
	
	Minetest Forums
	
		Project thread:
			https://forum.minetest.net/viewtopic.php?id=8021
	
	GitHub
	
		Project home:
			https://github.com/RacsoRhodes/travelpoints
		
		Latest version:
			https://github.com/RacsoRhodes/travelpoints/archive/master.zip

--------------------------------------------------------------------------------
03. Install Mod
--------------------------------------------------------------------------------

	This mod is for Minetest 0.4.8 or the latest build.
	
	Extract or move the extracted directory "travelpoints" into the "mods"
	directory of your Minetest installation.
	
--------------------------------------------------------------------------------
04. Textures
--------------------------------------------------------------------------------

	This mod ships with 16x16 textures, with resolutions up to 512 available:

		32 https://github.com/RacsoRhodes/travelpoints-textures-32/archive/master.zip

		64 https://github.com/RacsoRhodes/travelpoints-textures-64/archive/master.zip

		128 https://github.com/RacsoRhodes/travelpoints-textures-128/archive/master.zip

		256 https://github.com/RacsoRhodes/travelpoints-textures-256/archive/master.zip

		512	https://github.com/RacsoRhodes/travelpoints-textures-512/archive/master.zip
	
	Install

		Extract your chosen resolution, and copy or move the image files within
		to the directory of the texture pack you are currently using.
		
		For example, if you were using the texture pack "SummerFields", you would 
		download the 32x32 archive above and place the images contained into the
		texture pack's directory: textures/SummerFields/

--------------------------------------------------------------------------------
05. Chat Commands
--------------------------------------------------------------------------------

	Note:
	
		All player travelpoint tables are serialized and saved in the
		"travelpoints_tables" directory of the current world as
		<player_name>.tpt.

	----------------------------------------------------------------------------
	1.0 /travelpoints
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.

		Provides the player with information about the version of Travelpoints
		the server is running, with an output like:
		
			Travelpoints -!- Running Travelpoints version 1.2 released on 2013-12-21.
			Travelpoints -!- Restrictions:
			Travelpoints -!- Max Travelpoints: [35] You have: [0]
			Travelpoints -!- Max Transporter Pads: [25] You have [0]
			Travelpoints -!- Cooldown: [5 minutes] Your cooldown is: [none]
			Travelpoints -!- Back Location: [not cleared after use]
			
		In singleplayer mode the restrictions are not displayed.
			
	----------------------------------------------------------------------------
	1.1 /travelpoints set
	----------------------------------------------------------------------------
	
		Requires "travelpoints" and "server" privileges.
		
		Displays the restrictions that can be modified in game.
		
	----------------------------------------------------------------------------
	1.2 /travelpoints set <restriction> <value>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" and "server" privileges.
		
		Change the given restriction to a new value.
		
		These changes are saved to the world's directory as a serialized table
		in a file named "travelpoints_restrictions.tpt". If this file is present
		during server startup, the restrictions within will supersede those in
		"travelpoints/config.lua".

	----------------------------------------------------------------------------
	2.0 /tpset <title>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Saves a new travelpoint at the player's current position for the current
		world.
		
	----------------------------------------------------------------------------
	2.1 /tpset <title> <desc>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Saves a new travelpoint at the player's current position with a 
		description for the current world.
		
	----------------------------------------------------------------------------
	3.0 /tpgo
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Provides a list of travelpoints the player has saved for the current
		world.

	----------------------------------------------------------------------------
	3.1 /tpgo <title>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Teleports player to the given travelpoint.
		
		Also saves the position the player used the command at for use with the
		/tpback command.
		
	----------------------------------------------------------------------------
	4.0 /tpback
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Returns player to the location where /tpgo <title> was last used.
		
	----------------------------------------------------------------------------
	5.0 /tpdrop <title>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Deletes the specified travelpoint for the current world.
	
	----------------------------------------------------------------------------
	5.1 /tpdrop all
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Deletes all the player's travelpoints for the current world.
		
	----------------------------------------------------------------------------
	6.0 /travelpads
	----------------------------------------------------------------------------

		Requires "travelpoints" and "travelpads" privileges.
		
		Lists all the player's placed transporter pads for the current world.
		
--------------------------------------------------------------------------------
06. Nodes
--------------------------------------------------------------------------------

	----------------------------------------------------------------------------
	1.0 travelpoints:transporter_pad
	----------------------------------------------------------------------------

		Requires "travelpads" privilege to place this node in the world.
		
		Once placed, the owner can right click it and use the form to set one
		of their existing travelpoints as the transporter pad's destination.
		
		Transporter pads have four usage modes the owner can set:
			
			1. "Owner Only"
			2. "Everyone"
			3. "Owner and..." (list of players)
			4. "Everyone except..." (list of players)
		
		A transporter pad can not be dug if it has a destination set.
		
		Only the owner or someone with "server" privilege can unset and dig a
		transporter pad.
	
		Since anyone can view a transporter pad's form, the list of travelpoints
		is automatically cleared each time the transporter pad is modified.
		
		A. Recipe
		
			ME default:mese 1
			GL default:glass 1
			GI default:gold_ingot 1
			CI default:copper_ingot 2
			SI default:steel_ingot 4
			
			CI GL CI
			SI ME SI
			SI GI SI
			
		B. Refund
		
			Transporter pad can be converted to 10 default:mese_crystal
			
	----------------------------------------------------------------------------
	2.0 travelpoints:pad_light
	----------------------------------------------------------------------------

		This is a decorative node that can be placed over a transporter pad or
		a receiver pad.
		
		A. Recipe
		
			MC default:mese_crystal 1
			GL default:glass 1
			CI default:copper_ingot 2
			SI default:steel_ingot 5
			
			CI SI CI
			SI MC SI
			SI GL SI
			
		B. Refund
		
			Pad light can be converted to 2 default:mese_crystal
		
	----------------------------------------------------------------------------
	3.0 travelpoints:receiver_pad
	----------------------------------------------------------------------------

		This is a decorative node. Place it at the destination of a transporter
		pad act as a receiving pad.
		
		A. Recipe
		
			XX nothing
			CI default:copper_ingot 2
			SI default:steel_ingot 4
			
			XX XX XX
			CI SI CI
			SI SI SI
			
		B. Refund
		
			Receiver pad can be converted to 1 default:mese_crystal
			
--------------------------------------------------------------------------------
-- EOF
--------------------------------------------------------------------------------