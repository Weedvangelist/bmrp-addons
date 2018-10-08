if SERVER then
	AddCSLuaFile('autorun/vox.lua')
	util.AddNetworkString("VOXBroadcast")
	util.AddNetworkString("VOXList")

	function CanBroadCast(player)
		if (VOX_ADMINONLY:GetInt() == 1) then
			return (player:IsAdmin())
		end
		return true
	end

	VOX_ADMINONLY = CreateConVar( "vox_adminonly", 1, FCVAR_NOTIFY, "Set VOX Broadcaster admin only" )
	VOX_DELAY = CreateConVar( "vox_delay", 1, FCVAR_NOTIFY, "VOX delay" )
	VOX_NEXTBROADCAST = CurTime()

	hook.Add( "PlayerInitialSpawn", "VOXBroadcast", function(player)
		timer.Simple( 5, function()
			if (!player:IsValid()) then return end
			player:ChatPrint("Thanks to downloading VOX Announcer! - Black Tea Za rebel1324")
			player:ChatPrint("/vox <string> will broadcast the sound! console command also works!")
			player:ChatPrint("/voxlist or /voxhelp will direct you to how to use this vox announcer!")
			if (VOX_ADMINONLY:GetInt() == 1) then
				player:ChatPrint("Only admins can VOX Broadcast in this server.")
			else
				player:ChatPrint("Anyone can VOX Broadcast in this server.")
			end
		end)
	end)

	hook.Add( "PlayerSay", "VOXBroadcast", function( player, text )
		if (string.Left( text, 1 ) == "!" or string.Left( text, 1 ) == "/") then
			text = string.sub(text, 2)
			local command = string.Explode( " ", text )
			if (command[1] == "vox") then
				if (!VOX_NEXTBROADCAST or VOX_NEXTBROADCAST < CurTime()) then
					table.remove(command, 1)
					local voxline = table.concat(command, " ")
					if CanBroadCast(player) then
						net.Start("VOXBroadcast")
							net.WriteString(voxline)
						net.Broadcast()
					end
					VOX_NEXTBROADCAST = CurTime() + VOX_DELAY:GetInt()
				end
			end
			if (command[1] == "voxlist" or command[1] == "voxhelp") then
				net.Start("VOXList")
				net.Send(player)
				return false
			end
		end
	end)

	concommand.Add("vox", function(ply, cmd, args)
		if (!VOX_NEXTBROADCAST or VOX_NEXTBROADCAST < CurTime()) then
			local voxline = table.concat(args, " ")
			if CanBroadCast(ply) then
				net.Start( "VOXBroadcast" )
					net.WriteString(voxline)
				net.Broadcast()
			end
			VOX_NEXTBROADCAST = CurTime() + VOX_DELAY:GetInt()
		end
	end)
else	
	net.Receive("VOXBroadcast", function(length)
		local string = net.ReadString() 
		voxBroadcast( string )
	end)
	net.Receive("VOXList", function(length)
		local dframe = vgui.Create("DFrame")
		dframe:SetSize(ScrW()/2, ScrH()/2)
		dframe:Center()
		dframe:MakePopup()
		local label = dframe:Add("DLabel")
		label:Dock(TOP)
		label:SetFont("ChatFont")
		label:SetText("  VOX HELP - Loading will take few second.")
		local html = dframe:Add("DHTML")
		html:Dock(FILL)
		html:OpenURL( "https://pastebin.com/n26J9fE1" )
	end)
	
	local commands = {
		["delay"] = function(time, input, entity)
			return time + tonumber(input)
		end,
	}
	
	local sl = string.lower
	local path = "vox/"
	function voxBroadcast(string, entity, sndDat)
		local time = 0
		local emitEntity = entity or LocalPlayer()
		local table = string.Explode( " ", string )
		for k, v in ipairs( table ) do
			v = sl(v)
			local sndDir = path .. v .. ".wav"
			if (string.Left( v, 1 ) == "!") then
				v = string.sub(v, 2)
				local command = string.Explode( "=", v )
				if commands[command[1]] then
					time = commands[command[1]](time, command[2], entity)
				end
			else
				if (k != 1) then
					time = time + SoundDuration(sndDir) + .1
				end
				timer.Simple( time, function()
					if emitEntity:IsValid() then
						if emitEntity == LocalPlayer() then
							surface.PlaySound(sndDir)
						else
							local sndDat = sndDat or { pitch = 100, level = 70, volume = 1 }
							sound.Play(sndDir, emitEntity:GetPos(), sndDat.level, sndDat.pitch, sndDat.volume)
						end
					end
				end)
			end
		end
	end
	
	/*
	print("------------------------EXAMPLES--------------------------")
	print("------------------------VOX LINE LIST--------------------------")
	for k, v in pairs( file.Find( "sound/vox/*", "GAME", "nameasc" ) ) do
		local string = v
		string = string.Replace( v, ".wav", "" )
		print(string)	
	end
	*/
