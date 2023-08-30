-- The optimization momento certificado.
local TICRATE = TICRATE
local k_eggmanexplode = k_eggmanexplode
local k_roulettetype = k_roulettetype
local max = max
-- No more opti.

local xitemHooked = false

local VERSION = 1
local EGGPANIC_NAMESPACE = "EGGPANIC"

local eggpanic_active = nil
local eggxtend_active = nil

local function xitemHandler()
	if not eggpanic_active then eggpanic_active = CV_FindVar("eggpanic") end
	if not eggxtend_active then eggxtend_active = CV_FindVar("eggbox_extend") end
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[EGGPANIC_NAMESPACE] and modData[EGGPANIC_NAMESPACE].defDat.ver > VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(EGGPANIC_NAMESPACE, "Egg Panic", 
	{
		lib = "By Angular - XItem interop by JugadorXEI",
		ver = VERSION,
		-- Fixes Egg Panic extended timer not working if xitem is loaded last.
		enditemroll = function(player, useodds, mashed, spbrush)
			if not (eggpanic_active and eggpanic_active.value) then return end
			if not (eggxtend_active and eggxtend_active.value) then return end
			if not player then return end
			local pks = player.kartstuff
			
			if pks[k_roulettetype] ~= 2 then return end
			pks[k_eggmanexplode] = max($, 6*TICRATE)
		end
	})

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)