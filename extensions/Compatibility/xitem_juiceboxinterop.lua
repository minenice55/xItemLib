-- The optimization momento certificado.
local k_itemamount = k_itemamount
local min = min
-- No more opti.

local xitemHooked = false

local VERSION = 3
local JB_NAMESPACE = "JUICEBOX"

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[JB_NAMESPACE] and modData[JB_NAMESPACE].defDat.ver > VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(JB_NAMESPACE, "Juicebox", 
	{
		lib = "By Tyron - XItem interop by JugadorXEI",
		ver = VERSION,
	})
	
	-- This NEEDS to have a function, otherwise the getfunc hook for this doesn't work.
	local tripleSneakersFunc = lib.getItemDataById(KRITEM_TRIPLESNEAKER)["getfunc"]
	if not tripleSneakersFunc then lib.getItemDataById(KRITEM_TRIPLESNEAKER)["getfunc"] = function(p, getitem) end end
	
	lib.getXItemModData(JB_NAMESPACE, KRITEM_TRIPLESNEAKER)["getfunc"] = function(player, item)
		if G_BattleGametype() then return end
		if not (JUICEBOX and JUICEBOX.value) then return end
		if item ~= KRITEM_TRIPLESNEAKER then return end -- Just in case.
		
		-- Only for getting items through roulette, dropped/debug items are fine.
		if xItemLib.toggles.debugItem > 0 then return end 
		
		player.kartstuff[k_itemamount] = min(2, $)
	end

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)