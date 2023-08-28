-- The optimization momento certificado.
local KITEM_BANANA = KITEM_BANANA
local KITEM_ORBINAUT = KITEM_ORBINAUT
local KITEM_JAWZ = KITEM_JAWZ
local KRITEM_TENFOLDBANANA = KRITEM_TENFOLDBANANA
local KRITEM_QUADORBINAUT = KRITEM_QUADORBINAUT
local KRITEM_TRIPLEORBINAUT = KRITEM_TRIPLEORBINAUT
local KRITEM_DUALJAWZ = KRITEM_DUALJAWZ
local TICRATE = TICRATE
local k_itemblink = k_itemblink
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
local MF2_DONTDRAW = MF2_DONTDRAW
local max = max
-- No more opti.

local xitemHooked = false

local VERSION = 2
local KMP_NAMESPACE = "KARTMP"

-- Hooray for reusability, right?
-- Copied from KMP to preserve KMP Item Limiter:
--[ITEMTYPE] = {initial amount to go over of, num of players, remove 1 every n player, min it can lower to}
local itemfalloff = {
	[KITEM_BANANA] 		= {4, 5, 1, 3},		-- if we have >= 4 bananas with 5 or more players, remove 1 banana / player with a minimum of 3.
	[KITEM_ORBINAUT]	= {2, 6, 2, 2},		-- remove 1 every 2 player, minimum 2 orbis, this is p fine!
	[KITEM_JAWZ]		= {2, 8, 1, 1},		-- remove dual jawz past 8 players, literally FUCK OFF.
}

local function K_countplayers()
	local count = 0
	for p in players.iterate do
		if not (p.mo and p.mo.valid) then continue end
		count = $+1
	end
	return count
end

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData

	local didItExistBefore = modData[KMP_NAMESPACE] ~= nil
	if modData[KMP_NAMESPACE] and modData[KMP_NAMESPACE].defDat.ver > VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(KMP_NAMESPACE, "KartMP", 
	{
		lib = "By Lat - KartMP interop by JugadorXEI",
		ver = VERSION,
		-- Fixes KartMP's item limiter.
		getfunc = function(player, item)
			if not (kmp_itemlimiter and kmp_itemlimiter.value) then return end
			-- Only for getting items through roulette, dropped/debug items are fine.
			if xItemLib.toggles.debugItem > 0 then return end
			
			local pks = player.kartstuff
			
			local actualItem = pks[k_itemtype]
			if not itemfalloff[actualItem] return end
			
			local playerCount = K_countplayers()
			
			for k, v in pairs(itemfalloff) do
				if actualItem == k then
					local amount = pks[k_itemamount]

					-- If we have too many items of this type and too many players for this item...
					if amount >= v[1] and playerCount >= v[2] then

						local diff = playerCount - v[2]
						local loop_count = 0	-- how many players we've counted

						for i = 1, diff+1 do 
							loop_count = $+1
							if not (loop_count % v[3]) and amount > v[4] then -- > min item count for this
								amount = $-1 -- remove 1 item
							end
						end

						pks[k_itemamount] = amount
						break
					end
				end
			end
		end,
	})

	modData[KMP_NAMESPACE].xItemFuse = function(mo)
		if not (mo and mo.valid) then return end
		if not (kmp_floatingitemfuse and kmp_floatingitemfuse.value) then return end
		if modData[KMP_NAMESPACE].defDat.ver > VERSION then return end
		
		if P_IsObjectOnGround(mo) and not mo.fuse then
			local numlaps = mapheaderinfo[gamemap].numlaps
			mo.fuse = max(12*TICRATE, (60-(10*numlaps))*TICRATE)
		end

		if mo.fuse then
			mo.flags2 = (mo.fuse <= 5*TICRATE and leveltime % 2) and $ + MF2_DONTDRAW or $ & ~(MF2_DONTDRAW)
		end
	end

	-- These NEED to have a function. Otherwise overriding the amounts doesn't work.
	local decabananaFunc 	= lib.getItemDataById(KRITEM_TENFOLDBANANA)["getfunc"]
	local quadorbFunc 		= lib.getItemDataById(KRITEM_QUADORBINAUT)["getfunc"]
	local tripleorbtFunc 	= lib.getItemDataById(KRITEM_TRIPLEORBINAUT)["getfunc"]
	local dualjawzFunc		= lib.getItemDataById(KRITEM_DUALJAWZ)["getfunc"]
	if not decabananaFunc 	then lib.getItemDataById(KRITEM_TENFOLDBANANA)["getfunc"] = function(p, getitem) end end
	if not quadorbFunc 		then lib.getItemDataById(KRITEM_QUADORBINAUT)["getfunc"] = function(p, getitem) end end
	if not tripleorbtFunc 	then lib.getItemDataById(KRITEM_TRIPLEORBINAUT)["getfunc"] = function(p, getitem) end end
	if not dualjawzFunc 	then lib.getItemDataById(KRITEM_DUALJAWZ)["getfunc"] = function(p, getitem) end end
	
	-- Don't hook this again if it was already hooked.
	if not didItExistBefore then
		addHook("MobjThinker", function(mo) modData[KMP_NAMESPACE].xItemFuse(mo) end, MT_FLOATINGXITEM)
	end 
	
	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)