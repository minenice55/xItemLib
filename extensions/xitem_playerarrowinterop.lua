-- Optimization.
local G_BattleGametype = G_BattleGametype
local P_SpawnMobj = P_SpawnMobj
local pairs = pairs
-- No more.

local xitemHooked = false

local VERSION = 2
local ARROWS_NAMESPACE = "PLAYERARROWS"

if restorePlayerVariables == nil then
	rawset(_G, "restorePlayerVariables", {})
end

local function anyVariablesOnApply()
	local overrideArrow = false
	
	for key, func in pairs(restorePlayerVariables) do
		if not func() then continue end
		overrideArrow = true
		break
	end
		
	return overrideArrow
end

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[ARROWS_NAMESPACE] and modData[ARROWS_NAMESPACE].defDat.ver > VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end
	
	restorePlayerVariables["JBspy"] = function()
		return JUICEBOX and JUICEBOX.value
	end
	restorePlayerVariables["FRoverhead"] = function()
		local var = CV_FindVar("fr_enabled")
		return var and var.value
	end

	lib.addXItemMod(ARROWS_NAMESPACE, "Player Arrows Fix for various mods", 
	{
		lib = "Player Arrows Fix for various mods - XItem interop by JugadorXEI",
		ver = VERSION,
		-- Fixes XItem stealing the Player Arrow references creating an infinite loop.
		playerArrowSpawn = function(arrowMo, playerMo)
			if not anyVariablesOnApply() then return end
			if G_BattleGametype() then return end
			local player = playerMo.player
			if not player then return end

			local f = P_SpawnMobj(arrowMo.x, arrowMo.y, arrowMo.z, MT_XITEMPLAYERARROW)
			f.threshold = arrowMo.threshold
			f.movecount = arrowMo.movecount
			f.flags = arrowMo.flags
			f.flags2 = arrowMo.flags2
			f.target = arrowMo.target
			f.scale = arrowMo.scale
			f.destscale = arrowMo.destscale
			f.state = arrowMo.state
			for key, func in pairs(restorePlayerVariables) do
				if not func() then continue end
				player[key] = f
			end
			
			-- This results in two MT_XITEMPLAYERARROWs being created,
			-- but for the one we create at least the references are preserved.
			return true
		end
	})

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)