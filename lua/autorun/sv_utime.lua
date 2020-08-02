-- Written by Team Ulysses, http://ulyssesmod.net/
module( "Utime", package.seeall )
if not SERVER then return end

utime_welcome = CreateConVar( "utime_welcome", "1", FCVAR_ARCHIVE )

if not sql.TableExists( "utime" ) then
	sql.Query( "CREATE TABLE IF NOT EXISTS utime ( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, player INTEGER NOT NULL, totaltime INTEGER NOT NULL, lastvisit INTEGER NOT NULL );" )
	sql.Query( "CREATE INDEX IDX_UTIME_PLAYER ON utime ( player DESC );" )
end

function onJoin( ply )
	local uid = ply:UniqueID()
	local row = sql.QueryRow( "SELECT totaltime, lastvisit FROM utime WHERE player = " .. uid .. ";" )
	local time = 0

	if row then
		if utime_welcome:GetBool() then
			ULib.tsay( ply, "[UTime] Welcome back " .. ply:Nick() .. ", you last played on this server " .. os.date( "%c", row.lastvisit ) )
		end
		sql.Query( "UPDATE utime SET lastvisit = " .. os.time() .. " WHERE player = " .. uid .. ";" )
		time = row.totaltime
	else
		if utime_welcome:GetBool() then
			ULib.tsay( ply, "[UTime] Welcome to our server " .. ply:Nick() .. "!" )
		end
		sql.Query( "INSERT into utime ( player, totaltime, lastvisit ) VALUES ( " .. uid .. ", 0, " .. os.time() .. " );" )
	end
	ply:SetUTime( time )
	ply:SetUTimeStart( CurTime() )
end
hook.Add( "PlayerInitialSpawn", "UTimeInitialSpawn", function( ply )
    timer.Simple( 20, function() onJoin(ply) end )
end )

function updatePlayer( ply )
    local totalTime = ply:GetUTimeTotalTime()
    if totalTime == nil then
        print("[UTime] Got nil for current time when trying to update total time for player: " .. ply:Nick() .. " (" .. ply:SteamID64() .. " | " .. ply:UniqueID() .. ")")
        return
    end

    if not ply:IsConnected() then
        print("[UTime] Tried to update a player that wasn't fully connected yet!")
        return
    end

	sql.Query( "UPDATE utime SET totaltime = " .. math.floor( totalTime ) .. " WHERE player = " .. ply:UniqueID() .. ";" )
end
hook.Add( "PlayerDisconnected", "UTimeDisconnect", updatePlayer )

function updateAll()
	local players = player.GetAll()

	for _, ply in ipairs( players ) do
		if ply and ply:IsConnected() then
			updatePlayer( ply )
		end
	end
end
timer.Create( "UTimeTimer", 67, 0, updateAll )
