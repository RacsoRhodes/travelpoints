--------------------------------------------------------------------------------
--
-- Minetest Mod "Travelpoints" Version 1.4                            2015-03-27
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
--		7.0 /tpgset <title>
--		7.1 /tpgset <title> <desc>
--
--		8.0 /tpggo
--		8.1 /tpggo <title>
--
--		9.0 /tpgdrop <title>
--		9.1 /tpgdrop all
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

	1.4 2015-03-27
	
		! This version adds global travelpoints as requested by dgm5555.
		! This version does not break existing travelpoint collections. ABM will
			automatically update existing transporter pads for formspec changes.
		+ init.lua - Added privilege "tpglobal".
		* functions.lua/travelpoints.get_travelpoints_table()
			Added parameter "mode".
			Added condition for opening either user's table or the global table.
		* Updated all calls to travelpoints.get_travelpoints_table().
		* functions.lua/travelpoints.save_travelpoints_table()
			Added parameter "mode".
			Added condition for opening either user's table or the global table.
		* Updated all calls to travelpoints.save_travelpoints_table().
		+ init.lua - Added chat command "tpgset".
		* functions.lua/travelpoints.get_travelpoints_array()
			Added parameter "mode".
			Added condition for opening either user's table or the global table.
		* Updated all calls to travelpoints.get_travelpoints_array().
		+ init.lua - Added chat command "tpggo".
		+ init.lua - Added chat command "tpgdrop".
		* functions.lua/travelpoints.get_formspec()
			Added parameter "mode".
			Renamed button "List Travelpoints" to "My Travelpoints".
			Added button "Global Travelpoints".
			Removed button "Save" (Saves automatically with each modification.)
			Added button "Exit".
			Moved timestamp and modstamp text.
			Added text for mod version.
		! Mod now requires at least version 0.4.10 of Minetest for changes
			in formspec.
		+ functions.lua/travelpoints.on_destruct()
		+ functions.lua/travelpoints.after_place_node()
		+ functions.lua/travelpoints.on_receive_fields()
		+ functions.lua/travelpoints.can_dig()
		* nodes.lua
			Transporter_pad definition now uses shared call backs.
			Transporter_pad_active definition now uses shared call backs.
		! Players with "server" privilege can now dig active transporter.
		* functions.lua/travelpoints.get_infotext() - Removed "Placed by "
			text, now just shows pad owner's name in parentheses.
		! Added version and source meta tags to pad nodes.
		* nodes.lua - ABM now updates old pads for changes in meta data.
		+ functions.lua/travelpoints.set_pad_destination()
		* functions.lua/travelpoints.get_travelpoints_array() no longer
			prepends 'none' to the travelpoints array.
		* Removed all "- 1" math that compensated for the extra index in the
			travelpoints array.
		* init.lua - Chat command "/travelpoints", fixed display for those with
			server privilege.
		* readme.txt 
			Rewrote "About Travelpoints" section.
			Added chat commands "/tpgset", "/tpggo" and "/tpgdrop".
			Fixed minor errors.			

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

	This mod is for Minetest 0.4.10 or later.
	
	Singleplayer
	
		Save world specific bookmarks to locations you travel to as
		"travelpoints",	then easily teleport to those travelpoints.

		You can also create transporter pads whose destination can be set to an
		existing travelpoint, no need to ever enter coords by hand.
		
		While meant for multiplayer servers, the global travelpoints features
		are available in singleplayer mode.

	Multiplayer
	
		Each user with the "travelpoints' privilege can set and drop their own
		collection of travelpoints. This privilege also allows the use of global
		travelpoints.
		
		Users with the "tpglobal" privilege can set and drop global
		travelpoints.
		
		Users with the "travelpads" privilege can place transporter pads which
		can be set to one of their own travelpoints or to a global travelpoint.
	
	Chat Commands
		
		The travelpoints mod allows you to save world specific, location
		bookmarks to the places you travel using "/tpset <title>".
		
		You can then use "/tpgo <title>" to teleport to the given location.
		
		If you wish to return to the location you just came from, use "/tpback".

		You can list your collection of travelpoints by using the command
		"/tpgo".
		
		If you want to delete an old travelpoint you no longer need, use
		"/tpdrop <title>".
		
		For setting a global travelpoint, use "/tpgset". For listing and using
		global travelpoints, use "/tpggo". For dropping a global travelpoint
		use "/tpgdrop".
		
		For more commands, and more thorough explanation of the above commands,
		see section 5 of this file below.

	Transporter Pads
		
		Transporter pads allow you to fast travel without having to use chat
		commands. They are useful in large complexes so you can go from one area
		or floor to another just by walking onto a pad.
		
		Place a transporter pad where you want it, then right click it. There
		can sometimes be a moment of lag between the time you place it and when
		it will let you access its interface.
		
		Before you can choose a destination for the pad, you must list the
		available travelpoints. Press "My Travelpoints" to list your own, or
		press "Global Travelpoints" to list the global collection.
		
		When the list appears you can then choose a destination for the pad.
		
		After choosing a destination the list will clear, and the pad will
		become active.
		
		You can change the destination any time you need to.
		
		To list all the transporter pads you have placed use the chat command
		"/travelpads".
		
		When playing multiplayer you can also set usage modes, allowing only you
		to use the transporter pad, anyone to use the pad, you and a list of
		players, or everyone except a list of players.
		
		There are also decorative nodes, one is a receiving pad that you can
		place at the destination of your transporter pad, the other is a light
		that can be placed above either your transporter pad or receiving pad.
		
		For more information about the nodes included in this mod see section 6
		of this file below.
		
	Restrictions
	
		There are no restrictions in singleplayer mode.

		Admins of multiplayer servers are able to set restrictions in the 
		travelpoints/config.lua file, as well as set world specific restrictions
		using "/travelpoints set <restriction> <value>" in game.
		
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

	This mod is for Minetest 0.4.10 or later.
	
	Extract archive, and rename directory "travelpoints-master" to
	"travelpoints".

	Move the extracted directory "travelpoints" into the "mods"	directory of
	your Minetest installation.
	
--------------------------------------------------------------------------------
04. Textures
--------------------------------------------------------------------------------

	This mod ships with 16x16 textures, with resolutions up to 512 available:

		32 https://github.com/RacsoRhodes/travelpoints-textures-32/archive/master.zip

		64 https://github.com/RacsoRhodes/travelpoints-textures-64/archive/master.zip

		128 https://github.com/RacsoRhodes/travelpoints-textures-128/archive/master.zip

		256 https://github.com/RacsoRhodes/travelpoints-textures-256/archive/master.zip

		512 https://github.com/RacsoRhodes/travelpoints-textures-512/archive/master.zip
	
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
		
		The serialized global travelpoints are saved in the world's root
		directory as "travelpoints_global.tpt"

	----------------------------------------------------------------------------
	1.0 /travelpoints
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.

		Provides the player with information about the version of Travelpoints
		the server is running, with an output like:
		
		Mutiplayer

			Travelpoints -!- Running Travelpoints version 1.4 released on 2015-03-27.
			Travelpoints -!- Restrictions:
			Travelpoints -!- Max Travelpoints: [35] You have: [12]
			Travelpoints -!- Max Transporter Pads: [25] You have [6]
			Travelpoints -!- Cooldown: [5 minutes] Your cooldown is: [none]
			Travelpoints -!- Back Location: [not cleared after use]
			
		Singleplayer
			
			Travelpoints -!- Running Travelpoints version 1.4 released on 2015-03-27.

			
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
		
		Saves a new travelpoint at the player's position for the current world.
		
	----------------------------------------------------------------------------
	2.1 /tpset <title> <desc>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Saves a new travelpoint at the player's position with a description for
		the current world.
		
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
		
	----------------------------------------------------------------------------
	7.0 /tpgset <title>
	----------------------------------------------------------------------------
	
		Requires "tpglobal" privilege.
		
		Saves a new global travelpoint at the player's position for the	current
		world.
		
	----------------------------------------------------------------------------
	7.1 /tpgset <title> <desc>
	----------------------------------------------------------------------------
	
		Requires "tpglobal" privilege.
		
		Saves a new global travelpoint at the player's position with a
		description for the current world.

	----------------------------------------------------------------------------
	8.0 /tpggo
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Provides a list of global travelpoints for the current world.

	----------------------------------------------------------------------------
	8.1 /tpggo <title>
	----------------------------------------------------------------------------
	
		Requires "travelpoints" privilege.
		
		Teleports player to the given global travelpoint.
		
		Also saves the position the player used the command at for use with the
		/tpback command.
		
	----------------------------------------------------------------------------
	9.0 /tpgdrop <title>
	----------------------------------------------------------------------------
	
		Requires "tpglobal" privilege.
		
		Deletes the specified global travelpoint for the current world.
	
	----------------------------------------------------------------------------
	9.1 /tpgdrop all
	----------------------------------------------------------------------------
	
		Requires "tpglobal" and "server" privileges.
		
		Deletes all global travelpoints for the current world.

--------------------------------------------------------------------------------
06. Nodes
--------------------------------------------------------------------------------

	----------------------------------------------------------------------------
	1.0 travelpoints:transporter_pad
	----------------------------------------------------------------------------

		Requires "travelpads" privilege to place this node in the world.
		
		Once placed, the owner can right click it to access the interface where
		they can set a destination to one of their own travelpoints or to one
		of the global travelpoints.
		
		In multiplayer, the transporter pads have four usage modes the owner
		can set:
			
			1. "Owner Only"
			2. "Everyone"
			3. "Owner and..." (list of players)
			4. "Everyone except..." (list of players)
		
		Only the owner of a transporter pad can modify its settings.
		
		The owner of the transporter pad can dig it only if they unset the
		destination first.
		
		A player with "server" privilege can dig a transporter_pad whether it
		has a destination or not.
		
		Since anyone can view a transporter pad's interface, the list of
		travelpoints is automatically cleared each time the destination is
		modified.
		
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
		pad to act as a receiving pad.
		
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