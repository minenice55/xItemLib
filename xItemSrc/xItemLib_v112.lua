--xItemLib
--modular custom item library
--written by minenice, with help from the [REDACTED] (if you know what this is thanks a bunch lmao)
--don't expect this to be compatible with vanilla replays you fuck

--this is expected to be loaded as a packaged library (bundled with mods that need it), not as a dependancy (loaded outside of the mods that need it)
--however this does work as it's own standalone mod, if you just want the enhancements

--current library version (release, major, minor)
local currLibVer = 113
--current library revision (internal testing use)
local currRevVer = 1

--item flags, people making custom items can copy/paste this over to their lua scripts
local XIF_POWERITEM = 1 --is power item (affects final odds)
local XIF_COOLDOWNONSTART = 2 --can't be obtained on start cooldown
local XIF_UNIQUE = 4 --only one can exist in anyone's slot
local XIF_LOCKONUSE = 8 --locks the item slot when the item is used, slot must be unlocked manually by setting player.xItemData.xItem_itemSlotLocked to false
local XIF_COOLDOWNINDIRECT = 16 --checks if indirectitemcooldown is 0
local XIF_COLPATCH2PLAYER = 32 --map hud patch colour to player prefcolor
local XIF_ICONFORAMT = 64 --item icon and dropped item frame changes depending on the item amount (animation frames become amount frames)

-- Ashnal: for debug logging
local lastpdis

-- Ashnal: I've moved vanilla item odds and flags up here for easy reference, this table is referenced much later when initializing vanilla items
local vanillaItemProps = {}
-- xItem useodds                                           1  2  3  4  5  6  7  8  9  10
vanillaItemProps["KITEM_SNEAKER"]         = {raceodds =  {20, 0, 0, 4, 6, 7, 0, 0, 0, 0 }, battleodds = { 2, 1 }, flags = nil                                                    }
vanillaItemProps["KITEM_ROCKETSNEAKER"]   = {raceodds =  { 0, 0, 0, 0, 0, 1, 4, 5, 3, 0 }, battleodds = { 0, 0 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KITEM_INVINCIBILITY"]   = {raceodds =  { 0, 0, 0, 0, 0, 1, 4, 6,10, 0 }, battleodds = { 2, 1 }, flags = XIF_POWERITEM|XIF_COOLDOWNONSTART                      }
vanillaItemProps["KITEM_BANANA"]          = {raceodds =  { 0, 9, 4, 2, 1, 0, 0, 0, 0, 0 }, battleodds = { 1, 0 }, flags = nil                                                    }
vanillaItemProps["KITEM_EGGMAN"]          = {raceodds =  { 0, 3, 2, 1, 0, 0, 0, 0, 0, 0 }, battleodds = { 1, 0 }, flags = nil                                                    }
vanillaItemProps["KITEM_ORBINAUT"]        = {raceodds =  { 0, 7, 6, 4, 2, 0, 0, 0, 0, 0 }, battleodds = { 8, 0 }, flags = XIF_ICONFORAMT                                         }
vanillaItemProps["KITEM_JAWZ"]            = {raceodds =  { 0, 0, 3, 2, 1, 1, 0, 0, 0, 0 }, battleodds = { 8, 1 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KITEM_MINE"]            = {raceodds =  { 0, 0, 2, 2, 1, 0, 0, 0, 0, 0 }, battleodds = { 4, 1 }, flags = XIF_POWERITEM|XIF_COOLDOWNONSTART                      }
vanillaItemProps["KITEM_BALLHOG"]         = {raceodds =  { 0, 0, 0, 2, 1, 0, 0, 0, 0, 0 }, battleodds = { 2, 1 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KITEM_SPB"]             = {raceodds =  { 0, 0, 1, 2, 3, 4, 2, 2, 0,20 }, battleodds = { 0, 0 }, flags = XIF_COOLDOWNINDIRECT                                   }
vanillaItemProps["KITEM_GROW"]            = {raceodds =  { 0, 0, 0, 0, 0, 0, 2, 5, 7, 0 }, battleodds = { 2, 1 }, flags = XIF_POWERITEM|XIF_COOLDOWNONSTART                      }
vanillaItemProps["KITEM_SHRINK"]          = {raceodds =  { 0, 0, 0, 0, 0, 0, 0, 2, 0, 0 }, battleodds = { 0, 0 }, flags = XIF_POWERITEM|XIF_COOLDOWNONSTART|XIF_COOLDOWNINDIRECT }
vanillaItemProps["KITEM_THUNDERSHIELD"]   = {raceodds =  { 0, 1, 2, 0, 0, 0, 0, 0, 0, 0 }, battleodds = { 0, 0 }, flags = XIF_POWERITEM|XIF_COOLDOWNONSTART|XIF_UNIQUE           }
vanillaItemProps["KITEM_HYUDORO"]         = {raceodds =  { 0, 0, 0, 0, 1, 2, 1, 0, 0, 0 }, battleodds = { 2, 0 }, flags = XIF_COOLDOWNONSTART|XIF_UNIQUE                         }
vanillaItemProps["KITEM_POGOSPRING"]      = {raceodds =  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, battleodds = { 2, 0 }, flags = nil                                                    }
vanillaItemProps["KITEM_KITCHENSINK"]     = {raceodds =  { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, battleodds = { 0, 0 }, flags = nil                                                    }
vanillaItemProps["KRITEM_TRIPLESNEAKER"]  = {raceodds =  { 0, 0, 0, 0, 3, 7, 9, 2, 0, 0 }, battleodds = { 0, 1 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KRITEM_TRIPLEBANANA"]   = {raceodds =  { 0, 0, 1, 1, 0, 0, 0, 0, 0, 0 }, battleodds = { 1, 0 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KRITEM_TENFOLDBANANA"]  = {raceodds =  { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0 }, battleodds = { 0, 1 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KRITEM_TRIPLEORBINAUT"] = {raceodds =  { 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 }, battleodds = { 2, 0 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KRITEM_QUADORBINAUT"]   = {raceodds =  { 0, 0, 0, 0, 1, 1, 0, 0, 0, 0 }, battleodds = { 1, 1 }, flags = XIF_POWERITEM                                          }
vanillaItemProps["KRITEM_DUALJAWZ"]       = {raceodds =  { 0, 0, 0, 1, 2, 0, 0, 0, 0, 0 }, battleodds = { 2, 1 }, flags = XIF_POWERITEM                                          }

local XBT_ATTACKDISABLED = 1<<7

--apparently this makes shit faster? wtf?
local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
local MAXSKINCOLORS = MAXSKINCOLORS
local ANG1 = ANG1
local k_sneakertimer = k_sneakertimer
local k_spinouttimer = k_spinouttimer
local k_wipeoutslow = k_wipeoutslow
local k_driftboost = k_driftboost
local k_floorboost = k_floorboost
local k_startboost = k_startboost
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
local k_rocketsneakertimer = k_rocketsneakertimer
local k_hyudorotimer = k_hyudorotimer
local k_drift = k_drift
local k_speedboost = k_speedboost
local k_accelboost = k_accelboost
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_driftcharge = k_driftcharge
local k_position = k_position
local k_roulettetype = k_roulettetype
local k_itemroulette = k_itemroulette
local k_bumper = k_bumper
local k_eggmanheld = k_eggmanheld
local k_itemheld = k_itemheld
local k_squishedtimer = k_squishedtimer
local k_respawn = k_respawn
local k_stolentimer = k_stolentimer
local k_stealingtimer = k_stealingtimer

--desperate times call for desperate measures
local FixedMul = FixedMul
local FixedDiv = FixedDiv
local R_PointToDist2 = R_PointToDist2
local type = type
local table = table
local pcall = pcall
local min = min
local max = max

--"lol," he said. "lmao."
--also rip kartmp dropped item fuse
freeslot(
	"MT_FLOATINGXITEM",
	"MT_XITEMPLAYERARROW"
)

mobjinfo[MT_FLOATINGXITEM] = {
	doomednum = -1,
    spawnstate = S_ITEMICON,
	deathsound = sfx_itpick,
    spawnhealth = 1,
    radius = 24*FRACUNIT,
    height = 32*FRACUNIT,
	mass = 100,
    flags = MF_SLIDEME|MF_SPECIAL|MF_DONTENCOREMAP
}

mobjinfo[MT_XITEMPLAYERARROW] = {
	doomednum = -1,
    spawnstate = S_PLAYERARROW,
    spawnhealth = 1000,
    radius = 36*FRACUNIT,
    height = 37*FRACUNIT,
	mass = 16,
    flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY|MF_DONTENCOREMAP
}

--one (nested) table per splitscreen player
local availableItems = {{}, {}, {}, {}}
--only for player 1
local debuggerDistributions = {it = {}, odds = {}, totalodds = 0, useodds = 0}

local function K_FlipFromObject(mo, master)
	mo.eflags = (mo.eflags & ~MFE_VERTICALFLIP)|(master.eflags & MFE_VERTICALFLIP)
	mo.flags2 = (mo.flags2 & ~MF2_OBJECTFLIP)|(master.flags2 & MF2_OBJECTFLIP)

	if (mo.eflags & MFE_VERTICALFLIP) then
		mo.z = $ + (master.height - FixedMul(master.scale, mo.height))
	end
end

local function smuggleDetection()
	local group = {}
	for p in players.iterate
		if not p.spectator then
			table.insert(group, p)
		end
	end
	
	for i=1, #group
		if group[i].kartstuff[k_position] <= 2
		and (group[i].kartstuff[k_itemtype] == 1
		or group[i].kartstuff[k_itemtype] == 2
		or group[i].kartstuff[k_itemtype] == 3
		or group[i].kartstuff[k_itemtype] == 11
		or group[i].kartstuff[k_invincibilitytimer] > 0
		or group[i].kartstuff[k_growshrinktimer] > 0
		or (HugeQuest and group[i].hugequest.huge > 0))
			--print("SMUGGLER DETECTED")
			return true
		end
	end

	return false
end

local function findSplitPlayerNum(p)
	if not p then return end
	local splitplaynum = 0
	local si = 1
	for dp in displayplayers.iterate do
		if dp and dp == p then
			return si
		end
		si = $+1
	end
	return 0
end

--new solution for vanilla item toggles
--thanks yoshimo
local cvarTbl = {}
local function getCVar(name)
    local cvar = cvarTbl[name]
    if not cvar then
        cvar = CV_FindVar(name)
        cvarTbl[name] = cvar
    end
    return cvar.value
end

local function getItemDataById(id)
	return xItemLib.xItemData[id]
end

local function getItemDataByName(namespace)
	return xItemLib.xItemData[xItemLib.xItemNamespaces[namespace]]
end

local function getLoadedItemAmount()
	return table.maxn(xItemLib.xItemData)
end

local function addXItemMod(namespace, iName, defDat) --mod namespace, friendly name, default (placeholder) item data
	table.insert(xItemLib.xItemModNamespaces, namespace)
	xItemLib.xItemCrossData.modData[namespace] = {iName = iName or namespace, defDat = defDat or {}}
	print("Added mod "..iName.." ("..namespace..") to xItem mods")
	local t = xItemLib.xItemCrossData.itemData
	-- id -1 is used for anything "global"
	if not t[-1] then
		t[-1] = {}
	end
	t[-1][namespace] = defDat or {}
	print("Added global mod data from mod "..iName)
	for itm = 1, xItemLib.func.countItems() do
		if not t[itm][namespace] then
			t[itm][namespace] = defDat or {}
			print("Added item mod data to item "..itm.." from mod "..iName)
		end

		--added mod, run init if wanted
		local fn = xItemLib.func.getXItemModValue(#xItemLib.xItemModNamespaces, itm, "itemaddedfunc")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, itm)
		if not status then
			error(err, 2)
		end
	end
end

local function setXItemModData(namespace, item, data)
	local crossDat = xItemLib.xItemCrossData
	if type(item) == "string" then
		item = xItemLib.func.findItemByNamespace(item, true)
	end
	if crossDat.itemData[item] then
		if crossDat.modData[namespace] then
			crossDat.itemData[item][namespace] = data
			print("Set mod "..namespace.."'s item data for item"..item)
		else
			print("Can't find mod "..namespace.." in xItem mods!")
		end
	else
		print("Can't find item "..item.." in xItems!")
	end
end

local function getXItemModData(namespace, item)
	local crossDat = xItemLib.xItemCrossData
	if type(item) == "string" then
		item = xItemLib.func.findItemByNamespace(item, true)
	end
	if crossDat.modData[namespace] and crossDat.itemData[item] then
		return crossDat.itemData[item][namespace]
	end
	return nil
end

local function getXItemModValue(mod, it, key)
	local libdat = xItemLib
	local libfn = libdat.func
	local id = libdat.xItemModNamespaces[mod]
	local crossMod = libfn.getXItemModData(id, it)
	if crossMod and type(crossMod) == "table" and crossMod[key] then
		return crossMod[key]
	end
	--now try mod's global data (fallback), only if we weren't checking global data to begin with
	if it ~= -1 then
		crossMod = libfn.getXItemModData(id, -1)
		if crossMod and type(crossMod) == "table" and crossMod[key] then
			return crossMod[key]
		end
	end
	--nothing found, continue
	return nil
end

--rework to use OOP a bit more
local function ClassXItem(num, namespace, iName, bigpatch, smallpatch, flags, raceodds, battleodds, getfunc, usefunc, hudfunc, oddsfunc, resultfunc, droppedstate, showInRoulette, preusefunc, droppedfunc)
	--set item patch
	local itemPatch = {}
	if type(bigpatch) == "string" then
		itemPatch.bigTics = false
		itemPatch.bigP = bigpatch
	elseif type(bigpatch) == "table" then
		itemPatch.bigTics = bigpatch[1]
		itemPatch.bigP = {}
		for i = 2, #bigpatch do
			table.insert(itemPatch.bigP, bigpatch[i])
		end
	end
	if type(smallpatch) == "string" then
		itemPatch.smallTics = false
		itemPatch.smallP = smallpatch
	elseif type(smallpatch) == "table" then
		itemPatch.smallTics = smallpatch[1]
		itemPatch.smallP = {}
		for i = 2, #smallpatch do
			table.insert(itemPatch.smallP, smallpatch[i])
		end
	end

	--set item dropped sprite
	local itemSprite = {}
	if not droppedstate then
		itemSprite = {tics = 0, pics = {{SPR_ITEM, 0}}}
	end
	if type(droppedstate) == "number" then
		itemSprite.tics = 0
		itemSprite.pics = {{droppedstate, A}}
	elseif type(droppedstate) == "table" then	-- format as either {tics between frames, {sprite, frame}, {sprite, frame}, ...} or {0, {sprite, frame}}
		itemSprite.tics = droppedstate[1]
		itemSprite.pics = {}
		for i = 2, #droppedstate do
			table.insert(itemSprite.pics, droppedstate[i])
		end
	end

	local ret = {
		id = num, --numerical item ID
		nameInternal = namespace, --internal item name
		flags = flags, --item flags
		name = iName, --"friendly" item name that can be used in other mods for display reasons
		defaultRaceOdds = raceodds or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, --item's default race odds
		defaultBattleOdds = battleodds or {0, 0}, --item's default battle odds
		getfunc = getfunc or nil, --function that fires when the item is first rolled, function(player, itemNum)
		usefunc = usefunc or nil, --function that fires when using the item, function(player, cmd)
		hudfunc = hudfunc or nil, --hud function that runs as long as the item is in the player's item slot, function(v, player, consoleplayer)
		oddsfunc = oddsfunc or nil, --function that runs when finalizing item odds, function(newodds, oddsPos, mashed, spbrush, player, secondist, pingame, pexiting), expected to return a newodds override
		resultfunc = resultfunc or nil, --function that runs when getting the item type, function(player, itemNum), expected to return itemNum and itemAmount overrides
		droppedstate = itemSprite, --table of sprites to use when item is dropped
		droppedfunc = droppedfunc or nil, --function that runs when the dropped item first spawns upon a strip, function(droppedMo, item, itemAmount), can return a spriteframe override
		showInRoulette = showInRoulette or nil, --function or boolean that determines wether to show the item in the roulette if function expected to return a boolean
		preusefunc = preusefunc or nil, --function that runs when th player is holding the attack button, before the item is used. the usefunc will run when the button is released instead of when pressed. function(player, cmd, ticsAttackHeld, playerJustPressedAttack?)
		toggled = true,
		patches = itemPatch,
	}

	function ret.getItemPatch(small)
		if small then
			return (ret.patches.smallTics or false), (ret.patches.smallP or "K_ISSAD")
		else
			return (ret.patches.bigTics or false), (ret.patches.bigP or "K_ITSAD")
		end
	end

	function ret.getItemPatchSingle(small, anime)
		local atics, get = ret.getItemPatch(small)
		local idx
		if atics then
			if ret.flags and (ret.flags & XIF_ICONFORAMT) then 
				idx = max(min(anime, table.maxn(get)), 1)
				return get[idx], table.maxn(get)
			else
				idx = (leveltime/atics) % table.maxn(get)
				return get[idx + 1], 1
			end
		else
			return get, 1
		end
	end

	function ret.getItemDropSprite(animate)
		if animate and ret.droppedstate.tics > 0 then
			local anf = 1
			if ret.flags and (ret.flags & XIF_ICONFORAMT) then
				anf = max(min(animate, #ret.droppedstate.pics), 1)
			else
				anf = ((animate/ret.droppedstate.tics) % #ret.droppedstate.pics) + 1
			end
			local pic = ret.droppedstate.pics[anf]
			return pic[1], pic[2]
		else
			local pic = ret.droppedstate.pics[1]
			return pic[1], pic[2]
		end
	end

	return ret
end

local function addXItem(namespace, iName, bigpatch, smallpatch, flags, raceodds, battleodds, getfunc, usefunc, hudfunc, oddsfunc, resultfunc, droppedstate, showInRoulette, preusefunc, droppedfunc)
	local item = xItemLib.func.countItems() + 1
	if type(namespace) ~= "table" then
		if type(namespace) ~= "string" then
			error("Tried to add item "..item..", first argument isn't a table or string", 2)
		end
	else
		namespace, iName, bigpatch, smallpatch, flags, raceodds, battleodds, getfunc, usefunc, hudfunc, oddsfunc, resultfunc, droppedstate, showInRoulette, preusefunc, droppedfunc = unpack(namespace, 1, 16)
		if type(namespace) ~= "string" then
			error("Tried to add item "..item..", first element in the passed table isn't a string", 2)
		end
	end
	
	--allocate an item object
	xItemLib.xItemData[item] = ClassXItem(item, namespace, iName, bigpatch, smallpatch, flags, raceodds, battleodds, getfunc, usefunc, hudfunc, oddsfunc, resultfunc, droppedstate, showInRoulette, preusefunc, droppedfunc)
	--default odds are nothing
	--this is separate for special "gobally set odds" functionality
	table.insert(xItemLib.xItemOddsRace, raceodds or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	table.insert(xItemLib.xItemOddsBattle, battleodds or {0, 0})

	----legacy behaviour for backwards compat (to be deprecated?)----
	xItemLib.xItemNamespaces[namespace] = item
	if flags then
		xItemLib.xItemFlags[item] = flags
	end

	xItemLib.toggles.xItemToggles[item] = true
	----end legacy behaviour----

	--add extension data
	xItemLib.xItemCrossData.itemData[item] = {}
	local t = xItemLib.xItemCrossData.itemData[item]
	for i = 1, #xItemLib.xItemModNamespaces do
		local id = xItemLib.xItemModNamespaces[i]
		if not t[id] then
			t[id] = xItemLib.xItemCrossData.modData.defDat
			print("Added item mod data to item "..item.." from mod "..xItemLib.xItemCrossData.modData[id].iName)
		end

		--added mod, run init if wanted
		local fn = xItemLib.func.getXItemModValue(i, item, "itemaddedfunc")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, item)
		if not status then
			error(err, 2)
		end
	end
	
	print("Added item "..item.." named "..namespace.." to xItems")
	print(xItemLib.func.countItems().." items are loaded ("..table.maxn(xItemLib.xItemData).." item objects)")
end

--must be exact match
local function findItemByNamespace(name, ignoreErrs)
	ignoreErrs = $ or false
	local i = 0
	if type(name) == "string" then --item namespace
		i = xItemLib.xItemNamespaces[name]
		if not i then
			if not ignoreErrs then
				error("can't find item "..name, 2)
			end
			return 0
		end
		return i
	end
	if not ignoreErrs then
		error("passed non-string to xItem findItemByNamespace()", 2)
	end
end

--simple matching, doesn't check for case
local function findItemByFriendlyName(name, ignoreErrs)
	ignoreErrs = $ or false
	local libdat = xItemLib
	local itdat = libdat.xItemData
	local libfn = libdat.func
	name = string.lower(name)
	
	local compName
	local possible = {}
	for i = 1, libfn.countItems() do
		compName = string.lower(itdat[i].name)
		if compName:find(name) then
			table.insert(possible, i)
		end
	end
	if #possible > 0 then
		return possible
	else
		if not ignoreErrs then
			error("can't find item "..name, 2)
		end
		return 0
	end
end

local dat
--item ID 0 will fully reset all odds
local function resetOddsForItem(item, p, battle)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	if item == 0 then
		dat.xItem_battleOdds = nil
		dat.xItem_raceOdds = nil
	else
		
		local i = item
		if type(item) == "string" then --item namespace
			i = xItemLib.xItemNamespaces[item]
			if not i then
				print("can't find item "..item)
				return
			end
		end
		
		if battle then
			dat.xItem_battleOdds[i] = xItemLib.xItemData[i].defaultBattleOdds
		else
			dat.xItem_raceOdds[i] = xItemLib.xItemData[i].defaultRaceOdds
		end
	end
end

local function setPlayerOddsForItem(item, p, raceOdds, battleOdds)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	if raceOdds then
		if not dat.xItem_raceOdds then
			dat.xItem_raceOdds = {}
		end
		dat.xItem_raceOdds[item] = raceOdds
	end
	if battleOdds then
		if not dat.xItem_battleOdds then
			dat.xItem_battleOdds = {}
		end
		dat.xItem_battleOdds[item] = battleOdds
	end
end

local starttime = 6*TICRATE + (3*TICRATE/4)

local function playerScaling(spbrush, playersInGame)
	return (8 - (spbrush and 2 or playersInGame))
end

local function checkStartCooldown()
	if leveltime < 30*TICRATE + starttime then
		return true
	end
	return false
end

local function checkPowerItemOdds(odds, mashed, spbrush, playersInGame)
	if (franticitems) then
		odds = $ * 2
	end
	odds = FixedMul($*FRACUNIT, FRACUNIT + ((xItemLib.func.getPlayerScaling(spbrush, playersInGame)*FRACUNIT) / 25))/FRACUNIT
	if (mashed > 0) then
		odds = FixedDiv(odds*FRACUNIT, FRACUNIT + mashed)/FRACUNIT
	end
	return odds
end

local function floatingItemThinker(mo)
	if not (mo and mo.valid) then return end
	local f = P_SpawnMobj(mo.x, mo.y, mo.z, MT_FLOATINGXITEM)
	f.momx = mo.momx
	f.momy = mo.momy
	f.momz = mo.momz
	f.scale = mo.scale
	f.destscale = mo.destscale
	f.threshold = mo.threshold
	f.movecount = mo.movecount
	f.flags = mo.flags
	f.flags2 = mo.flags2
	P_SpawnShadowMobj(f)
	P_RemoveMobj(mo)
end

local function floatingItemSpecial(s, t)
	--if t.player and t.player.xItemData and (t.player.xItemData.xItem_roulette or t.player.xItemData.xItem_itemSlotLocked) then
	return true
	--end
end

local function floatingXItemThinker(mo)
	if not (mo and mo.valid) then return end
	if (mo.flags & MF_NOCLIPTHING) then
		if (P_CheckDeathPitCollide(mo)) then
			P_RemoveMobj(mo)
			return
		elseif (P_IsObjectOnGround(mo)) then
			mo.momx = 1
			mo.momy = 0
			mo.flags = MF_SLIDEME|MF_SPECIAL|MF_DONTENCOREMAP|MF_NOGRAVITY
		end
	else
		mo.angle = $ + 4 * ANG1
		if (mo.flags2 & MF2_NIGHTSPULL) then
			if (not (mo.tracer) or not (mo.tracer.health) or mo.scale <= mapobjectscale >> 4) then
				P_RemoveMobj(mo)
				return
			end
			--fuck
			P_InstaThrust(mo, R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y), R_PointToDist2(mo.x, mo.y, mo.tracer.x, mo.tracer.y) >> 2)
		else
			local adj = FixedMul(FRACUNIT - cos(mo.angle), (mapobjectscale >> 3))
			if (mo.eflags & MFE_VERTICALFLIP) then
				mo.z = mo.ceilingz - mo.height - adj
			else
				mo.z = mo.floorz + adj
			end
		end
	end
	
	local i = mo.threshold
	local amt = mo.movecount
	local sprite, frame = SPR_ITEM, 0
	local idat = xItemLib.func.getItemDataById(mo.threshold)
	
	--set spriteframe here
	local anim = 0
	if idat.flags and (idat.flags & XIF_ICONFORAMT) then
		anim = amt
	else
		anim = leveltime
	end
	
	--run droppedfunc function if it exists
	if idat.droppedfunc then
		sprite, frame = idat.droppedfunc(mo, i, amt)
	else
		sprite, frame = idat.getItemDropSprite(anim)
	end
	
	--crossmod "hooks"
	for j = 1, #xItemLib.xItemModNamespaces do
		local fn = xItemLib.func.getXItemModValue(j, item, "droppedfunc")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, mo, i, amt)
		if not status then
			error(err, 2)
		end
	end
	
	if mo and mo.valid then
		mo.sprite = sprite
		mo.frame = frame|FF_PAPERSPRITE
	end
end

local function floatingXItemSpecial(s, t)
	if not t.player then
		return
	end
	
	local libdat = xItemLib
	local libfunc = libdat.func
	
	local p = t.player
	local kartstuff = p.kartstuff
	
	--hell
	if p.xItemData and (p.xItemData.xItem_roulette > 0 or p.xItemData.xItem_itemSlotLocked
		or kartstuff[k_stealingtimer] > 0 or kartstuff[k_stolentimer] > 0 or kartstuff[k_growshrinktimer] > 0 or kartstuff[k_rocketsneakertimer] > 0
		or kartstuff[k_eggmanexplode] > 0 or (kartstuff[k_itemtype] and kartstuff[k_itemtype] ~= s.threshold) or kartstuff[k_itemheld]) then
		return true
	end
	
	if (G_BattleGametype() and kartstuff[k_bumper] <= 0)
		return true
	end
	--print("a")
	kartstuff[k_itemtype] = s.threshold
	kartstuff[k_itemamount] = $ + s.movecount

	local it = libfunc.getItemDataById(s.threshold)
	
	--crossmod "hooks"
	for j = 1, #libdat.xItemModNamespaces do
		local fn = libfunc.getXItemModValue(j, s.threshold, "pickupfunc")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, p, s, t)
		if not status then
			error(err, 2)
		end
	end
	-- nah
	--if (kartstuff[k_itemamount] > 255) then
	--	kartstuff[k_itemamount] = 255
	--end

	--run getfunc here too
	if it and it.getfunc then
		local status, err = pcall(it.getfunc, p, s.threshold)
		if not status then
			error(err, 2)
		end
		--crossmod "hooks"
		for i = 1, #libdat.xItemModNamespaces do
			local fn = libfunc.getXItemModValue(i, s.threshold, "getfunc")
			if fn == nil or (not type(fn) == "function") then continue end
			local status, err = pcall(fn, p, s.threshold)
			if not status then
				error(err, 2)
			end
		end
	end

	S_StartSound(special, s.info.deathsound, p)

	s.tracer = t
	s.flags2 = $ | MF2_NIGHTSPULL
	s.destscale = mapobjectscale >> 4
	s.scalespeed = $ << 1

	s.flags = $ & ~MF_SPECIAL
	return true
end

local function itemBoxSpecial(s, t)
	if t.player and t.player.xItemData and (t.player.xItemData.xItem_roulette or t.player.xItemData.xItem_itemSlotLocked) then
		return true
	end
end

local function P_IsLocalPlayer(player)
	local i

	if player == consoleplayer then
		return true
	elseif splitscreen then
		for i = 1, splitscreen do -- Skip P1
			if player == displayplayers[i] then
				return true
            end
		end
	end

	return false
end

--thanks yoshimo for porting all this stuff over
local function playerArrowUnsetPositionThinking(mobj, scale)
	P_SetOrigin(mobj, mobj.target.x, mobj.target.y, mobj.target.z)
	
    mobj.angle = R_PointToAngle(mobj.x, mobj.y) + ANGLE_90 -- literally only happened because i wanted to ^L^R the SPR_ITEM's

    if not splitscreen and displayplayers[0].mo then
        scale = mobj.target.scale + FixedMul(FixedDiv(abs(P_AproxDistance(displayplayers[0].mo.x-mobj.target.x,
            displayplayers[0].mo.y-mobj.target.y)), RING_DIST), mobj.target.scale)
        if scale > 16*mobj.target.scale then
            scale = 16*mobj.target.scale
        end
    end
    mobj.destscale = scale

	K_FlipFromObject(mobj, mobj.target)
    
    return scale
end

local function vanillaArrowThinker(mo)
	local libdat = xItemLib
	local libfunc = libdat.func
	local status
	local err = false
	--crossmod "hooks"

	for i = 1, #libdat.xItemModNamespaces do
		local fn = libfunc.getXItemModValue(i, -1, "playerArrowSpawn")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, mo, mo.target)
		if not status then
			error(err, 2)
		end
	end
	
	local f = P_SpawnMobj(mo.x, mo.y, mo.z, MT_XITEMPLAYERARROW)
	f.threshold = mo.threshold
	f.movecount = mo.movecount
	f.flags = mo.flags
	f.flags2 = mo.flags2
	f.target = mo.target
	--f.tracer = mo.tracer
	f.scale = mo.scale
	f.destscale = mo.destscale
	f.state = mo.state
	mo.state = S_NULL
end

local function playerArrowThinker(mobj)
    if mobj and mobj.valid and mobj.target and mobj.target.health
        and mobj.target.player and not mobj.target.player.spectator
        and mobj.target.player.health and mobj.target.player.playerstate ~= PST_DEAD
        --[[and displayplayers[0].mo and not displayplayers[0].spectator]]
    then
		local mtrace = mobj.tracer
		local tm = mobj.target
		local tp = mobj.target.player
		local kartstuff = mobj.target.player.kartstuff
		local xitdat = mobj.target.player.xItemData
		
		if not xitdat then return true end
		
        local scale = 3*tm.scale
        mobj.color = tm.color
        K_MatchGenericExtraFlags(mobj, tm)

        if (G_RaceGametype() or kartstuff[k_bumper] <= 0)
--#if 1 -- Set to 0 to test without needing to host
            or ((tp == displayplayers[0]) or P_IsLocalPlayer(tp))
--#endif
        then
            mobj.flags2 = $ | MF2_DONTDRAW
        end

        --P_UnsetThingPosition(mobj)
        if mobj.flags & MF_NOCLIP then
            scale = playerArrowUnsetPositionThinking(mobj, scale)
        else
            mobj.flags = $ | MF_NOCLIP
            scale = playerArrowUnsetPositionThinking(mobj, scale)
            mobj.flags = $ & ~MF_NOCLIP
        end
        --P_SetThingPosition(mobj)

        if not mtrace then
            local overlay = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)
            mobj.tracer = overlay
            overlay.target = mobj
            overlay.state = S_PLAYERARROW_ITEM
            overlay.destscale = mobj.scale
            P_SetScale(overlay, (overlay.destscale))
			mtrace = mobj.tracer
        end

        -- Do this in an easy way
        if xitdat.xItem_roulette then
            mtrace.color = tp.skincolor
            mtrace.colorized = true
        else
            mtrace.color = SKINCOLOR_NONE
            mtrace.colorized = false
        end

        if not (mobj.flags2 & MF2_DONTDRAW) then
			local idat = xItemLib.func.getItemDataById(kartstuff[k_itemtype])
            local numberdisplaymin = 2
			if idat.flags and (idat.flags & XIF_ICONFORAMT) then
				numberdisplaymin = idat.droppedstate.tics + 1
			end
			
            -- Set it to use the correct states for its condition
            if xitdat.xItem_roulette then
				i = ((xitdat.xItem_roulette % (xItemLib.func.countItems() * 3)) / 3) + 1
				local sprite, frame = idat.getItemDropSprite(0)
				
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = sprite
                mtrace.frame = FF_FULLBRIGHT|frame
                mtrace.flags2 = $ & ~MF2_DONTDRAW
				
            elseif kartstuff[k_stolentimer] > 0 then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_HYUDORO
                if leveltime & 2 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif (kartstuff[k_stealingtimer] > 0) and (leveltime & 2) then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_HYUDORO
                mtrace.flags2 = $ & ~MF2_DONTDRAW
            elseif kartstuff[k_eggmanexplode] > 1 then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_EGGMAN
                if leveltime & 1 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif kartstuff[k_rocketsneakertimer] > 1 then
                --itembar = kartstuff[k_rocketsneakertimer] -- not today satan
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_ROCKETSNEAKER
                if leveltime & 1 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif kartstuff[k_growshrinktimer] > 0 then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_GROW

                if leveltime & 1 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif kartstuff[k_itemtype] and kartstuff[k_itemamount] > 0 then
                mobj.state = S_PLAYERARROW_BOX
				
				--find sprite to use
				local sprite, frame
				if idat.flags and (idat.flags & XIF_ICONFORAMT) then
					sprite, frame = idat.getItemDropSprite(kartstuff[k_itemamount])
				else
					sprite, frame = idat.getItemDropSprite(leveltime)
				end
				
				--set correct sprite BEFORE THE GAME DOES IT FFS
				mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = sprite
                mtrace.frame = FF_FULLBRIGHT|frame

                if kartstuff[k_itemheld] then
                    if leveltime & 1 then
                        mtrace.flags2 = $ & ~MF2_DONTDRAW
                    else
                        mtrace.flags2 = $ | MF2_DONTDRAW
                    end
                else
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                end
            else
                mobj.state = S_PLAYERARROW
                mtrace.state = S_PLAYERARROW_ITEM
            end

            mtrace.destscale = scale
			
            if kartstuff[k_itemamount] >= numberdisplaymin
                and kartstuff[k_itemamount] <= 10 -- Meh, too difficult to support greater than this; convert this to a decent HUD object and then maybe :V
            then
                local number = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)
                local numx = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)

                number.target = mobj
                number.state = S_PLAYERARROW_NUMBER
                P_SetScale(number, mtrace.scale)
                number.destscale = scale
                number.frame = FF_FULLBRIGHT|(kartstuff[k_itemamount])

                numx.target = mobj
                numx.state = S_PLAYERARROW_X
                P_SetScale(numx, mtrace.scale)
                numx.destscale = scale
            end

            if K_IsPlayerWanted(tp) and mobj.movecount ~= 1 then
                local wanted = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_PLAYERWANTED)
                wanted.target = tm
                wanted.tracer = mobj
                P_SetScale(wanted, mobj.scale)
                wanted.destscale = scale
                mobj.movecount = 1
            elseif not K_IsPlayerWanted(tp) then
                mobj.movecount = 0
            end
        else
            mtrace.flags2 = $ | MF2_DONTDRAW
        end
    elseif mobj.health > 0 then
        P_KillMobj(mobj, nil, nil)
        return true
    end
end

--odds functions start
local function xItem_GetItemResult(p, getitem, onlyReturn, skipGetFunc)
	if not p then return end

	local libdat = xItemLib
	local libfn = libdat.func
	local it = libfn.getItemDataById(getitem)
	local kartstuff = p.kartstuff

	local itr, amtr = 0, 0
	
	if it and it.resultfunc then
		itr, amtr = it.resultfunc(p, getitem)
		if not (onlyReturn) then
			kartstuff[k_itemtype], kartstuff[k_itemamount] = itr, amtr
		end
	else
		if (getitem <= 0 or getitem > libfn.countItems()) then -- Sneaker (Fallback) (xItem doesn't implement SadFace)
			if (getitem ~= 0) then
				print("ERROR: xItem_GetItemResult - Item roulette gave bad item "..getitem.." :(")
			end
			itr = 1
			if not (onlyReturn) then kartstuff[k_itemtype] = itr end
		else
			itr = getitem
			if not (onlyReturn) then kartstuff[k_itemtype] = itr end
		end
		amtr = 1
		if not (onlyReturn) then kartstuff[k_itemamount] = amtr end
	end
	if skipGetFunc then return itr, amtr end
	--custom on get functions
	if it and it.getfunc then
		local status, err = pcall(it.getfunc, p, getitem)
		if not status then
			error(err, 2)
		end
		--crossmod "hooks"
		for i = 1, #libdat.xItemModNamespaces do
			local fn = libfn.getXItemModValue(i, getitem, "getfunc")
			if fn == nil or (not type(fn) == "function") then continue end
			local status, err = pcall(fn, p, getitem)
			if not status then
				error(err, 2)
			end
		end
	end
	return itr, amtr
end

local function xItem_GetOdds(pos, item, mashed, spbrush, p, custTable)
	local distvar = 64*14
	local newodds = 0
	local pingame = 0
	local pexiting = 0
	local first
	local second
	local secondist = 0
	
	local libfn = xItemLib.func
	local itdat = libfn.getItemDataById(item)
	local kartstuff = p.kartstuff

	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData
	
	
	local itemenabled = {
		libfn.getCVar("sneaker"),
		libfn.getCVar("rocketsneaker"),
		libfn.getCVar("invincibility"),
		libfn.getCVar("banana"),
		libfn.getCVar("eggmanmonitor"),
		libfn.getCVar("orbinaut"),
		libfn.getCVar("jawz"),
		libfn.getCVar("mine"),
		libfn.getCVar("ballhog"),
		libfn.getCVar("selfpropelledbomb"),
		libfn.getCVar("grow"),
		libfn.getCVar("shrink"), 
		libfn.getCVar("thundershield"),
		libfn.getCVar("hyudoro"),
		libfn.getCVar("pogospring"),
		libfn.getCVar("kitchensink"),
		libfn.getCVar("triplesneaker"),
		libfn.getCVar("triplebanana"),
		libfn.getCVar("decabanana"),
		libfn.getCVar("tripleorbinaut"),
		libfn.getCVar("quadorbinaut"),
		libfn.getCVar("dualjawz")
	}
	
	if item <= 0 then return 0 end
	
	if custTable then
		if (not custTable[item]) or (not custTable[item][pos]) then
			if (G_BattleGametype()) then
				if dat.xItem_battleOdds and dat.xItem_battleOdds[item] then
					newodds = dat.xItem_battleOdds[item][pos]
				else
					newodds = xItemLib.xItemOddsBattle[item][pos]
				end
			else
				if dat.xItem_raceOdds and dat.xItem_raceOdds[item] then
					newodds = dat.xItem_raceOdds[item][pos]
				else
					newodds = xItemLib.xItemOddsRace[item][pos]
				end
			end
		else
			newodds = custTable[item][pos]
		end
	else
		if (G_BattleGametype()) then
			if dat.xItem_battleOdds and dat.xItem_battleOdds[item] then
				newodds = dat.xItem_battleOdds[item][pos]
			else
				newodds = xItemLib.xItemOddsBattle[item][pos]
			end
		else
			if dat.xItem_raceOdds and dat.xItem_raceOdds[item] then
				newodds = dat.xItem_raceOdds[item][pos]
			else
				newodds = xItemLib.xItemOddsRace[item][pos]
			end
		end
	end
	
	--print("got odds "..newodds)
	if newodds then newodds = $ << 2 end
		
	if item <= table.maxn(itemenabled) and not itemenabled[item] then newodds = 0 end
	if not xItemLib.toggles.xItemToggles[item] then
		newodds = 0
	end
	
	if newodds then
		for pi in players.iterate do
			local piks = pi.kartstuff
			--print("checking player " + pi.name)
			if pi.spectator then continue end
			if (not G_BattleGametype()) or piks[k_bumper] then pingame = $+1 end
			if pi.exiting or (pi.pflags & PF_TIMEOVER == PF_TIMEOVER) then pexiting = $+1 end
			if pi.mo then
				local checkItem = piks[k_itemtype]
				if itdat.flags and (itdat.flags & XIF_UNIQUE == XIF_UNIQUE) and checkItem == item then
					newodds = 0
				end
				if (not G_BattleGametype()) then
					if (piks[k_position] == 1 and (first == nil))
						first = pi.mo
						--print("got first")
					end
					if (piks[k_position] == 2 and (second == nil))
						second = pi.mo
						--print("got second")
					end
				end
			end
		end
		if (first and second) then
			--print("getting secondist")
			local p1 = first
			local p2 = second
			secondist = R_PointToDist2(0, p1.x, R_PointToDist2(p1.y, p1.z, p2.y, p2.z), p2.x) / mapobjectscale
			if (franticitems) then
				secondist = (15 * $) / 14
			end
			secondist = ((28 + (8-min(pingame, 16))) * $) / 28
		end
		
		--replaces the switch-case with a table of flags, for modularity
		if itdat.flags then
			if (itdat.flags & XIF_POWERITEM == XIF_POWERITEM) then
				newodds = libfn.getPowerOdds($, mashed, spbrush, pingame)
			end
			if (itdat.flags & XIF_COOLDOWNINDIRECT == XIF_COOLDOWNINDIRECT) then
				if (indirectitemcooldown > 0) then newodds = 0 end
			end
			if (itdat.flags & XIF_COOLDOWNONSTART == XIF_COOLDOWNONSTART) then
				if libfn.getStartCountdown() then newodds = 0 end
			end
		end
	end
	
	local status = true
	--special cases, custom items
	if itdat and itdat.oddsfunc then
		status, newodds = pcall(itdat.oddsfunc, $2, pos, mashed, spbrush, p, secondist, pingame, pexiting, item)
		if not status then
			error(newodds, 2)
			return 0
		end
	end
	--crossmod "hooks"
	for i = 1, #xItemLib.xItemModNamespaces do
		local fn = libfn.getXItemModValue(i, item, "oddsfunc")
		if fn == nil or (not type(fn) == "function") then continue end
		status, newodds = pcall(fn, $2, pos, mashed, spbrush, p, secondist, pingame, pexiting, item)
		if not status then
			error(newodds, 2)
		end
	end
	newodds = tonumber($) or 0
	
	distvar = nil
	pingame = nil
	pexiting = nil
	first = nil
	second = nil
	secondist = nil
	return newodds
end

local function setupDistTable(odds, num, disttable, distlen)
	local a = 0
	for i = num, 1, -1 do
		a = $+1
		disttable[distlen + a] = odds
	end
	return a
end

local aggressiondistance = 600
local function xItem_FindUseOdds(p, mashed, pingame, spbrush, dontforcespb)
	if not p then return end

	local distvar = 64*14
	local i
	local pdis = 0
	local useodds = 1
	local oddsvalid = {}
	local disttable = {}
	local distlen = 0
	--local debug_useoddsstopcode = 0
	
	local FAUXPOS = G_BattleGametype() and 2 or 10
	
	local libdat = xItemLib
	local libfn = libdat.func
	
	local pks = p.kartstuff
	
	--make faux positions valid or not
	for i = 1, FAUXPOS do
		local available = false
		for j = 1, libfn.countItems() do
			--print("checking itemodds for item "..j.." at pos "..i)
			if libfn.getOdds(i, j, mashed, spbrush, p) > 0 then
				available = true
				break
			end
		end
		oddsvalid[i] = available
	end
	
	--calc distances (honestly kinda weiiiirdddd)
	if xItemLib.cvars.bItemDistCalcConga.value then -- conga line calc, inspired by Sal's rr-item-cruncher branch
		if (p.mo and p.mo.valid) then
			local playerMoList = {}
			for q in players.iterate do
				if not (q.mo and q.mo.valid) then continue end
				playerMoList[q.kartstuff[k_position]] = q.mo
			end
			local toposition = p.kartstuff[k_position] - 1
			while toposition > 0 do
				local from = playerMoList[toposition + 1]
				local to = nil
				while not to and toposition > 0 do -- Ensures that if somehow the list has any gaps we skip over them, and prevent infinite looping
					to = playerMoList[toposition]
					toposition = $-1
				end
				if to and from then -- if somehow 1st isn't in the list, to would end up nil, so we need to catch that
					--local dist = (FixedHypot(FixedHypot(from.x - to.x, from.y - to.y), from.z - to.z))
					--print("from "..skins[from.skin].name.." to "..skins[to.skin].name.." is "..dist)
					pdis = $ + FixedHypot(FixedHypot(from.x/4 - to.x/4, from.y/4 - to.y/4), from.z/4 - to.z/4) -- trying to not overflow FixedHypot with large distances
					if toposition+1 == p.kartstuff[k_position] then -- When we check only the player immmediately ahead
						local ahead  = FixedHypot(FixedHypot(from.x/4 - to.x/4, from.y/4 - to.y/4), from.z/4 - to.z/4)*4
						to = playerMoList[toposition+2]
						if to then
							local behind = FixedHypot(FixedHypot(from.x/4 - to.x/4, from.y/4 - to.y/4), from.z/4 - to.z/4)*4
							local closerange = aggressiondistance*mapobjectscale
							from.xitemcloserange = not (ahead > closerange and behind > closerange)
						end
					end
				end
			end	
			pdis = ($ / mapobjectscale)*2 -- Scale it. This results in pdis values a bit weaker in smaller games, and a bit stronger in larger games than the original formula
			pdis = ((130 + 8 - min(pingame, 16)) * $) / 130 -- Again, but this time base it on playercount, same form as the following vanilla adjustment, but much weaker since it stacks with it
		end
	else -- original vanilla calc
		for p2 in players.iterate do
			if p.mo and p2 and (not p2.spectator) and p2.mo and (p2.kartstuff[k_position] ~= 0) and p2.kartstuff[k_position] < pks[k_position] then
				
				pdis = $ + FixedHypot(FixedHypot(p.mo.x/4 - p2.mo.x/4, p.mo.y/4 - p2.mo.y/4), p.mo.z/4 - p2.mo.z/4)*4 / mapobjectscale * (pingame - p2.kartstuff[k_position]) / max(1, ((pingame - 1) * (pingame + 1) / 3))
			end
		end
	end
	
	--set up distributions
	if (G_BattleGametype()) then
		if (pks[k_roulettetype] == 1 and oddsvalid[2])
			-- 1 is the extreme odds of player-controlled "Karma" items
			useodds = 2
			--debug_useoddsstopcode = 8
		else
			useodds = 1
			--debug_useoddsstopcode = 9
			if (oddsvalid[1] == false and oddsvalid[2])
				-- try to use karma odds as a fallback
				useodds = 2
				--debug_useoddsstopcode = 10
			end
		end
	else
		if oddsvalid[2] then distlen = $ + libfn.setupDist(2, 1, disttable, distlen) end
		if oddsvalid[3] then distlen = $ + libfn.setupDist(3, 1, disttable, distlen) end
		if oddsvalid[4] then distlen = $ + libfn.setupDist(4, 1, disttable, distlen) end
		if oddsvalid[5] then distlen = $ + libfn.setupDist(5, 2, disttable, distlen) end
		if oddsvalid[6] then distlen = $ + libfn.setupDist(6, 2, disttable, distlen) end
		if oddsvalid[7] then distlen = $ + libfn.setupDist(7, 3, disttable, distlen) end
		if oddsvalid[8] then distlen = $ + libfn.setupDist(8, 3, disttable, distlen) end
		if oddsvalid[9] then distlen = $ + libfn.setupDist(9, 1, disttable, distlen) end
		
		if (franticitems) then -- Frantic items make the distances between everyone artifically higher, for crazier items
			pdis = (15 * $) / 14
		end
		
		if (spbrush) then -- SPB Rush Mode: It's 2nd place's job to catch-up items and make 1st place's job hell
			pdis = (3 * $) >> 1
		end
		
		if smuggleDetection()
		and pks[k_position] > 1 then -- Haha, FUCK YOU
			pdis = (6*$)/5
		end

		pdis = ((28 + 8 - min(pingame, 16)) * $) / 28
		
		if pingame == 1 and oddsvalid[1] then					-- Record Attack, or just alone
			useodds = 1
			--debug_useoddsstopcode = 0
		elseif pdis <= 0 then									-- (64*14) *  0 =     0
			useodds = disttable[1]
			--debug_useoddsstopcode = 1
		elseif pks[k_position] == 2 and oddsvalid[10] and (spbplace == -1) and (not indirectitemcooldown) and (not dontforcespb) and (pdis > distvar*6) then -- Force SPB in 2nd
			useodds = 10
			--debug_useoddsstopcode = 7
		elseif pdis > distvar * ((12 * distlen) / 14) then -- (64*14) * 12 = 10752
			useodds = disttable[distlen]
			p.playerbot = nil
			--debug_useoddsstopcode = 2
		else
			for i = 1, 12 do
				if pdis <= distvar * ((i * distlen) / 14) then
					useodds = disttable[((i * distlen) / 14)] + 1
					--debug_useoddsstopcode = 3
					break
				end
			end
		end
	end
	--print("Got useodds "..useodds.." (kart useodds "..(useodds - 1).."). (position: "..p.kartstuff[k_position]..", distance: "..pdis..", stopcode: "..debug_useoddsstopcode..")") 
	--debug_useoddsstopcode = nil
	
	lastpdis = pdis
	
	distvar = nil
	i = nil
	pdis = nil
	distlen = nil
	
	return useodds
end

local function xItem_ItemRoulette(p, cmd)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	local i
	local pingame = 0
	local roulettestop
	local useodds = 0
	local spawnchance = {}
	local totalspawnchance = 0
	local bestbumper = 0
	local mashed = 0
	local dontforcespb = false
	local spbrush = false
	
	local kartstuff = p.kartstuff
	local libdat = xItemLib
	local libfn = libdat.func
	
	if leveltime == 0 then
		dat.xItem_roulette = 0
		libfn.resetItemOdds(0, p)
	end
	--stripped during roulette clears our fake one
	if dat.xItem_roulette and kartstuff[k_itemroulette] == 0 then
		dat.xItem_roulette = 0
		kartstuff[k_roulettetype] = 0
	end
	if kartstuff[k_itemroulette] and dat.xItem_roulette == 0 then
		dat.xItem_roulette = kartstuff[k_itemroulette]
		kartstuff[k_itemroulette] = 4

		for i = 1, #libdat.xItemModNamespaces do
			local fn = libfn.getXItemModValue(i, -1, "startitemroll")
			if fn == nil or (not type(fn) == "function") then continue end
			local status, err = pcall(fn, p)
			if not status then
				error(err, 2)
			end
		end

		if dat.xItem_resetOddsNextRoll == -1 then
			libfn.resetItemOdds(0, p)
			dat.xItem_resetOddsNextRoll = 0
		end
	end
	if kartstuff[k_itemroulette] and kartstuff[k_itemroulette] < 4 and (kartstuff[k_roulettetype] == 2) then
		dat.xItem_roulette = kartstuff[k_itemroulette]
		kartstuff[k_itemroulette] = 4
		kartstuff[k_roulettetype] = 2
		if dat.xItem_resetOddsNextRoll == -1 then
			libfn.resetItemOdds(0, p)
			dat.xItem_resetOddsNextRoll = 0
		end
	end
	
	if dat.xItem_roulette then
		kartstuff[k_itemroulette] = 4
		dat.xItem_roulette = $+1
	else
		return
	end
	
	-- Gotta check how many players are active at this moment.
	for p in players.iterate do
		if p.spectator then continue end
		pingame = $+1
		p.spawntowaypoint = true
		if (p.exiting) then
			dontforcespb = true
		end
		if (kartstuff[k_bumper] > bestbumper)
			bestbumper = kartstuff[k_bumper]
		end
	end
	if (pingame <= 2)
		dontforcespb = true
	end

	
	-- This makes the roulette produce the random noises.
	if P_IsLocalPlayer(p) and dat.xItem_roulette % 3 == 1 then
		S_StartSound(nil, sfx_itrol1 + ((dat.xItem_roulette / 3) % 8), p)
	end
	
	roulettestop = TICRATE + (3*(pingame - kartstuff[k_position]))
	if (G_RaceGametype())
		spbrush = (spbplace ~= -1 and kartstuff[k_position] == spbplace+1)
	end
	
	local splitplaynum = p.splitscreenindex + 1
	if P_IsLocalPlayer(p) and ((dat.xItem_roulette < 4) or (dat.xItem_roulette % 3 == 0)) then
		useodds = libfn.findUseOdds(p, 0, pingame, spbrush, dontforcespb)
		availableItems[splitplaynum] = libfn.hudFindRouletteItems(p, useodds, 0, spbrush)
	end
	
	if ((cmd.buttons & BT_ATTACK) or (cmd.buttons & XBT_ATTACKDISABLED)) and libdat.toggles.debugItem and libdat.cvars.bXRig.value then
		dat.xItem_roulette = TICRATE*3
	end
	if (((cmd.buttons & BT_ATTACK) or (cmd.buttons & XBT_ATTACKDISABLED)) and not (kartstuff[k_eggmanheld] or kartstuff[k_itemheld]) and dat.xItem_roulette >= roulettestop and not modeattacking) then
		-- Mashing reduces your chances for the good items
		mashed = FixedDiv(dat.xItem_roulette*FRACUNIT, ((TICRATE*3)+roulettestop)*FRACUNIT) - FRACUNIT
	elseif (not(dat.xItem_roulette >= (TICRATE*3))) then
		i = nil
		pingame = nil
		roulettestop = nil
		useodds = nil
		totalspawnchance = nil
		bestbumper = nil
		mashed = nil
		dontforcespb = nil
		spbrush = nil
		return
	end
	
	useodds = libfn.findUseOdds(p, mashed, pingame, spbrush, dontforcespb)
	
	if (kartstuff[k_roulettetype] == 2) then -- Fake items
		kartstuff[k_eggmanexplode] = max($, 4*TICRATE) --in case this runs after stuff like egg panic
		
		S_StartSound(nil, sfx_itrole, p)
		dat.xItem_itemSlotLocked = false --just in case
		if dat.xItem_resetOddsNextRoll == 1 then
			libfn.resetItemOdds(0, p)
			dat.xItem_resetOddsNextRoll = 0
		end

		for i = 1, #libdat.xItemModNamespaces do
			local fn = libfn.getXItemModValue(i, -1, "enditemroll")
			if fn == nil or (not type(fn) == "function") then continue end
			local status, err = pcall(fn, p, useodds, mashed, spbrush)
			if not status then
				error(err, 2)
			end
		end

		kartstuff[k_itemroulette] = 0
		dat.xItem_roulette = 0
		kartstuff[k_roulettetype] = 0
		
		i = nil
		pingame = nil
		roulettestop = nil
		useodds = nil
		totalspawnchance = nil
		bestbumper = nil
		mashed = nil
		dontforcespb = nil
		spbrush = nil
		return
	end
	
	--debugitem
	if (libdat.toggles.debugItem ~= 0 and not modeattacking) then
		local di = min(libdat.toggles.debugItem, libfn.countItems())
		libfn.getItemResult(p, di, false)
		kartstuff[k_itemamount] = libdat.cvars.dItemDebugAmt.value
		
		S_StartSound(nil, sfx_dbgsal, p)
		if dat.xItem_resetOddsNextRoll == 1 then
			libfn.resetItemOdds(0, p)
			dat.xItem_resetOddsNextRoll = 0
		end

		for i = 1, #libdat.xItemModNamespaces do
			local fn = libfn.getXItemModValue(i, -1, "enditemroll")
			if fn == nil or (not type(fn) == "function") then continue end
			local status, err = pcall(fn, p, useodds, mashed, spbrush)
			if not status then
				error(err, 2)
			end
		end
		kartstuff[k_itemblink] = TICRATE
		kartstuff[k_itemblinkmode] = 2
		kartstuff[k_itemroulette] = 0
		dat.xItem_roulette = 0
		kartstuff[k_roulettetype] = 0
		
		di = nil
		i = nil
		pingame = nil
		roulettestop = nil
		useodds = nil
		totalspawnchance = nil
		bestbumper = nil
		mashed = nil
		dontforcespb = nil
		spbrush = nil

		return
	end

	for i = 1, #libdat.xItemModNamespaces do
		local fn = libfn.getXItemModValue(i, -1, "enditemroll")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, p, useodds, mashed, spbrush)
		if not status then
			error(err, 2)
		end
	end
	
	for i = 1, libfn.countItems() do
		local o = libfn.getOdds(useodds, i, mashed, spbrush, p)
		if o > 0 then
			totalspawnchance = $ + o
		end
		spawnchance[i] = totalspawnchance
	end
	
	-- Award the player whatever power is rolled
	if (totalspawnchance > 0) then
		local spawnidx = P_RandomKey(totalspawnchance)
		for i = 1, libfn.countItems() do
			if spawnchance[i] > spawnidx then 
				if xItemLib.cvars.bServerLogRolls.value and consoleplayer == server then
					local itdat = libfn.getItemDataById(i)
					local racetime = max(leveltime - starttime, 0)
					-- we useodds-1 here to use the vanilla 0 based odds numbering
					print("Player "..#p.." "..p.name.." got "..itdat.name.." with position "..p.kartstuff[k_position].." of "..pingame.." and useodds "..(useodds-1).." and pdis "..lastpdis.." and spbrush "..tostring(spbrush).." at leveltime "..leveltime.." aka "..G_TicsToMinutes(racetime)..":"..G_TicsToSeconds(racetime)..":"..G_TicsToCentiseconds(racetime)) 
				end
				libfn.getItemResult(p, i, false)
				break 
			end
		end
		spawnidx = nil
	else
		// failsafe if no item could be obtained
		if xItemLib.cvars.bServerLogRolls.value and consoleplayer == server then
			local itdat = libfn.getItemDataById(1)
			local racetime = max(leveltime - starttime, 0)
			-- we useodds-1 here to use the vanilla 0 based odds numbering
			print("FAILSAFE: Player "..#p.." "..p.name.." got failsafe "..itdat.name.." with position "..p.kartstuff[k_position].." of "..pingame.." and useodds "..(useodds-1).." and pdis "..lastpdis.." and spbrush "..tostring(spbrush).." at leveltime "..leveltime.." aka "..G_TicsToMinutes(racetime)..":"..G_TicsToSeconds(racetime)..":"..G_TicsToCentiseconds(racetime)) 
		end
		libfn.getItemResult(p, 1, false)
	end
	
	if dat.xItem_resetOddsNextRoll == 1 then
		libfn.resetItemOdds(0, p)
		dat.xItem_resetOddsNextRoll = 0
	end
	
	S_StartSound(nil, ((kartstuff[k_roulettetype] == 1) and sfx_itrolk or (mashed and sfx_itrolm or sfx_itrolf)), p)
	
	kartstuff[k_itemblink] = TICRATE
	kartstuff[k_itemblinkmode] = ((kartstuff[k_roulettetype] == 1) and 2 or (mashed and 1 or 0))
	
	kartstuff[k_itemroulette] = 0
	dat.xItem_roulette = 0  --Since we're done, clear the roulette number
	kartstuff[k_roulettetype] = 0 --This too
	
	i = nil
	pingame = nil
	roulettestop = nil
	useodds = nil
	totalspawnchance = nil
	bestbumper = nil
	mashed = nil
	dontforcespb = nil
	spbrush = nil
end

local function xItem_handleDistributionDebugger(pa)
	if not pa then return end

	local libdat = xItemLib
	local libfn = libdat.func
	if (libdat.cvars.bItemDebugDistrib.value or libdat.cvars.bItemDebugDistribReplayOnly.value and replayplayback) and displayplayers[0] == pa then
		local pingame = 0
		local dontforcespb = false
		local spbrush = false
		local kartstuff = pa.kartstuff
		local bestbumper = 0

		for p in players.iterate do
			if p.spectator then continue end
			if not p then continue end
			pingame = $+1
			if (p.exiting) then
				dontforcespb = true
			end
			if (kartstuff[k_bumper] > bestbumper)
				bestbumper = kartstuff[k_bumper]
			end
		end
		if (pingame <= 2)
			dontforcespb = true
		end
		if (G_RaceGametype())
			spbrush = (spbplace ~= -1 and kartstuff[k_position] == spbplace+1)
		end

		local useodds = libfn.findUseOdds(pa, 0, pingame, spbrush, dontforcespb)
		debuggerDistributions = libfn.findItemDistributions(pa, useodds, 0, spbrush)
	end
end

local function canUseItem(p)
	return (p and p.mo and p.mo.health > 0 and (not p.spectator) and (not p.exiting)
		and p.kartstuff[k_spinouttimer] == 0 and p.kartstuff[k_squishedtimer] == 0 and p.kartstuff[k_respawn] == 0
		and not(p.xItemData.xItem_attackedDuringRoll or p.xItemData.xItem_itemSlotLockedTimer))
end

local function playerCmdHook(p, cmd)
	if not p then return end

	if p.xItemData and p.xItemData.xItem_itemSlotLockedTimer then
		if cmd.buttons & BT_ATTACK then
			cmd.buttons = ($|XBT_ATTACKDISABLED) & ~BT_ATTACK
		end
	end
end

local function setPlayerItemCooldown(p, time, force)
	if p and p.xItemData and not(p.spectator or p.exiting) then
		force = $ or false
		if force then
			p.xItemData.xItem_itemSlotLockedTimerMax = time
			p.xItemData.xItem_itemSlotLockedTimer = time
		else
			if time >= p.xItemData.xItem_itemSlotLockedTimer then
				p.xItemData.xItem_itemSlotLockedTimerMax = time
				p.xItemData.xItem_itemSlotLockedTimer = time
			end
		end
	end
end

local function xItem_BasicItemHandler(p, cmd)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	local kartstuff = p.kartstuff
	
	local libdat = xItemLib
	local libfunc = libdat.func
	local cv = libdat.cvars
	
	local item = kartstuff[k_itemtype]
	local itdat = libfunc.getItemDataById(item)
	local canUseItem = libfunc.canUseItem
	
	local attackJustDown = (((cmd.buttons & BT_ATTACK) or (cmd.buttons & XBT_ATTACKDISABLED)) and dat.xItem_pressedUse == 0)
	local attackDown = ((cmd.buttons & BT_ATTACK) or (cmd.buttons & XBT_ATTACKDISABLED))
	local attackReleased = ((dat.xItem_pressedUse) and not ((cmd.buttons & BT_ATTACK) or (cmd.buttons & XBT_ATTACKDISABLED)))
	local noHyudoro = (p.kartstuff[k_stolentimer] == 0 and p.kartstuff[k_stealingtimer] == 0)
	
	local status, err
	if itdat and itdat.preusefunc then
		if canUseItem(p) and noHyudoro then
			if attackDown then
				status, err = pcall(itdat.preusefunc, p, cmd, dat.xItem_pressedUse, attackJustDown)
				if not status then
					error(err, 2)
				end
				--crossmod "hooks"

				for i = 1, #libdat.xItemModNamespaces do
					local fn = libfunc.getXItemModValue(i, item, "preusefunc")
					if fn == nil or (not type(fn) == "function") then continue end
					local status, err = pcall(fn, p, cmd, dat.xItem_pressedUse, attackJustDown)
					if not status then
						error(err, 2)
					end
				end

			elseif attackReleased then
				if itdat and itdat.usefunc then
					status, err = pcall(itdat.usefunc, p, cmd)
					if not status then
						error(err, 2)
					end
				end
				if itdat.flags and (itdat.flags & XIF_LOCKONUSE == XIF_LOCKONUSE) then
					dat.xItem_itemSlotLocked = true
				end
				--crossmod "hooks"
				for i = 1, #libdat.xItemModNamespaces do
					local fn = libfunc.getXItemModValue(i, item, "usefunc")
					if fn == nil or (not type(fn) == "function") then continue end
					local status, err = pcall(fn, p, cmd)
					if not status then
						error(err, 2)
					end
				end
			end
		end
	elseif itdat and canUseItem(p) and attackJustDown and noHyudoro then
		--print("using item "..item)
		if itdat.flags and (itdat.flags & XIF_LOCKONUSE == XIF_LOCKONUSE) then
			dat.xItem_itemSlotLocked = true
		end
		if itdat and itdat.usefunc then
			--print("has a function")
			status, err = pcall(itdat.usefunc, p, cmd)
			if not status then
				error(err, 2)
			end
		end
		--crossmod "hooks"
		for i = 1, #libdat.xItemModNamespaces do
			local fn = libfunc.getXItemModValue(i, item, "usefunc")
			if fn == nil or (not type(fn) == "function") then continue end
			local status, err = pcall(fn, p, cmd)
			if not status then
				error(err, 2)
			end
		end
	elseif (not item) and (not dat.xItem_lastItem) and attackJustDown and libdat.toggles.debugItem and cv.bXRig.value then
		kartstuff[k_itemroulette] = TICRATE*3
	end
	
	if attackDown and (dat.xItem_roulette > 0 or p.kartstuff[k_respawn] ~= 0) then
		dat.xItem_attackedDuringRoll = true
	end
	if (not attackDown) and dat.xItem_roulette == 0 and p.kartstuff[k_respawn] == 0 and dat.xItem_attackedDuringRoll then
		dat.xItem_attackedDuringRoll = false
	end
	p.findwaypoint, p.racebot = nil, nil

	if ((dat.xItem_pressedUse) and not attackDown) then
		dat.xItem_pressedUse = 0
	elseif attackDown then
		dat.xItem_pressedUse = $+1
	end

	if dat.xItem_itemSlotLockedTimer then
		dat.xItem_itemSlotLockedTimer = $ - 1

		if dat.xItem_itemSlotLockedTimer == 0 then
			dat.xItem_itemSlotLockedTimerMax = 0
		end
	end
	dat.xItem_lastItem = item
end

--port of item hud to lua
--now even more modular and extensible, and specifically made for xItemLib

local splitplayers = {}
local function splitnum(p)
	for i = 1, #splitplayers do
		if splitplayers[i] == p
			return i-1
		end
	end
end

local BASEVIDWIDTH  = 320
local BASEVIDHEIGHT = 200

local ITEM_X = 5
local ITEM_Y = 5

local ITEM1_X = -9
local ITEM1_Y = -8

local ITEM2_X = BASEVIDWIDTH-39
local ITEM2_Y = -8
local colormode = TC_RAINBOW
local localcolor = SKINCOLOR_NONE

local function xItem_FindHudFlags(v, p, c)
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		if c.pnum == 1 then
			return ITEM_X, ITEM_Y, V_SNAPTOTOP|V_SNAPTOLEFT, false
		else
			return ITEM_X, ITEM_Y, V_SNAPTOLEFT|V_SPLITSCREEN, false
		end
	else -- now we're having a fun game.
		if c.pnum == 1 or c.pnum == 3 then -- If we are P1 or P3...
			return ITEM1_X, ITEM1_Y, (c.pnum == 3 and V_SPLITSCREEN or V_SNAPTOTOP)|V_SNAPTOLEFT, false	-- flip P3 to the bottom.	
		else -- else, that means we're P2 or P4.
			return ITEM2_X, ITEM2_Y, (c.pnum == 4 and V_SPLITSCREEN or V_SNAPTOTOP)|V_SNAPTORIGHT, true
		end
	end
end

local function xItem_DrawItemBox(v, p, c, fill)
	fill = $ or false
	local fx, fy, fflags = xItemLib.func.hudFindFlags(v, p, c)
	local localbg = {v.cachePatch("K_ITBG"), v.cachePatch("K_ISBG")}

	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		if fill then
			local rectTopX, rectTopY, rectSize = 10, 10, 30
			v.drawFill(fx + rectTopX, fy + rectTopY, rectSize, rectSize, 25|fflags)
		end
		v.draw(fx, fy, localbg[1], V_HUDTRANS|fflags)
	else -- now we're having a fun game.
		if fill then
			local rectTopX, rectTopY, rectSize = 16, 15, 16
			v.drawFill(fx + rectTopX, fy + rectTopY, rectSize, rectSize, 25|fflags)
		end
		v.draw(fx, fy, localbg[2], V_HUDTRANS|fflags)
	end
end

local function xItem_DrawTimerBar(v, p, c)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	local fx, fy, fflags = xItemLib.func.hudFindFlags(v, p, c)
	local kp_itemtimer = {v.cachePatch("K_ITIMER"), v.cachePatch("K_ISIMER")}

	local itembar = dat.xItem_timerBar
	local maxitembar = dat.xItem_maxTimerBar

	if itembar > 0 then
		local offset = 1
		local barlength = 26
		local height = 2
		local x = 11
		local y = 35
		if splitscreen > 1 then
			offset = 2
			barlength = 12
			height = 1
			x = 17
			y = 27
		end

		local fill = ((itembar*barlength)/maxitembar)
		local length = min(barlength, fill)
		
		v.draw(fx+x, fy+y, kp_itemtimer[offset], V_HUDTRANS|fflags)
		-- The left dark "AA" edge
		if length == 2 then
			v.drawFill(fx+x+1, fy+y+1, 2, height, 12|fflags)
		else
			v.drawFill(fx+x+1, fy+y+1, 1, height, 12|fflags)
		end
		-- The bar itself
		if (length > 2) then
			v.drawFill(fx+x+length, fy+y+1, 1, height, 12|fflags) -- the right one
			if (height == 2) then
				v.drawFill(fx+x+2, fy+y+2, length-2, 1, 8|fflags) -- the dulled underside
			end
			v.drawFill(fx+x+2, fy+y+1, length-2, 1, 120|fflags) -- the shine
		end
	end

	dat.xItem_timerBar = 0
	dat.xItem_maxTimerBar = 0
end

local function xItem_DrawItemMinecraftCooldown(v, p, c)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	if leveltime % 2 then return end
	
	if not(dat.xItem_itemSlotLockedTimer or dat.xItem_itemSlotLockedTimerMax) then return end
	local fx, fy, fflags = xItemLib.func.hudFindFlags(v, p, c)
	local rectTop = 5
	local rectSize = 40
	local localbg = {v.cachePatch("K_ITBG"), v.cachePatch("K_ISBG")}

	local itembar = dat.xItem_itemSlotLockedTimer
	local maxitembar = dat.xItem_itemSlotLockedTimerMax
	local length = min(rectSize, ((itembar*rectSize)/maxitembar))
	
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		v.drawFill(fx + rectTop, fy + rectTop + (rectSize - length), rectSize, length, 2|fflags)
	else -- now we're having a fun game.
		local rectTopV = 13
		rectTop = 14
		rectSize = 20
		length = min(rectSize, ((itembar*rectSize)/maxitembar))

		v.drawFill(fx + rectTop, fy + rectTopV + (rectSize - length), rectSize, length, 2|fflags)
	end
end

local function xItem_DrawCooldownItemBox(v, p, c)
	local libfn = xItemLib.func
	libfn.hudDrawItemBox(v, p, c, true)
	libfn.hudDrawItemCooldown(v, p, c)
end

local function xItem_DrawItem(v, p, c, i, blink, disableBox)
	if not p then return end
	if not p.xItemData then return end

	disableBox = $ or false
	local fx, fy, fflags, flipamount = xItemLib.func.hudFindFlags(v, p, c)
	local itTflags = V_HUDTRANS
	local offset = ((splitscreen > 1) and 2 or 1)
	local get
	
	local kp_itemx = v.cachePatch("K_ITX")
	local localmul = {v.cachePatch("K_ITMUL"), v.cachePatch("K_ISMUL")}
	local kp_itemtimer = {v.cachePatch("K_ITIMER"), v.cachePatch("K_ISIMER")}
	
	local rouletteAnim = false
	local libdat = xItemLib
	local libfn = libdat.func
	
	local kartstuff = p.kartstuff
	
	if i == nil then
		i = kartstuff[k_itemtype]
	end
	local itdat = libfn.getItemDataById(i)
	
	local colour = v.getColormap(TC_DEFAULT, SKINCOLOR_NONE)
	if i and p and itdat.flags and (itdat.flags & XIF_COLPATCH2PLAYER == XIF_COLPATCH2PLAYER) then 
		colour = v.getColormap(TC_DEFAULT, p.skincolor)
	end
	
	local s, icn
	if i > 0 then
		local idx = 0
		if itdat.flags and (itdat.flags & XIF_ICONFORAMT) then 
			idx = kartstuff[k_itemamount]
		else
			idx = leveltime
		end
		s, get = itdat.getItemPatchSingle(splitscreen >= 2, idx)
		icn = v.cachePatch(s)
	end
	if icn == nil then icn = v.cachePatch("K_ITSAD") end
	if p.xItemData.xItem_roulette then
		colormode = TC_RAINBOW
		localcolor = p.skincolor or SKINCOLOR_GREY
		colour = v.getColormap(colormode, localcolor)
		if libdat.cvars.bRouletteAnim.value then
			rouletteAnim = true
		end
	end
	
	if kartstuff[k_itemblink] and leveltime%2 == 1 then
		colormode = TC_BLINK
		if kartstuff[k_itemblinkmode] == 2 then
			localcolor = 1 + (leveltime % (MAXSKINCOLORS-1))
		elseif kartstuff[k_itemblinkmode] == 1 then
			localcolor = SKINCOLOR_RED
		else
			localcolor = SKINCOLOR_WHITE
		end
		colour = v.getColormap(colormode, localcolor)
	end
	
	if not disableBox then
		libfn.hudDrawItemBox(v, p, c)
	end
	
	local yShift = ((leveltime%3)-1)
	if splitscreen < 2 then 
		if rouletteAnim then
			fy = $ + 10*yShift
			if yShift then itTflags = V_HUDTRANSHALF end
		end
	else 
		if rouletteAnim then
			fy = $ + 4*yShift
			if yShift then itTflags = V_HUDTRANSHALF end
		end
	end

	local drawAmt = (not (itdat.flags and (itdat.flags & XIF_ICONFORAMT))) or (itdat.flags and (itdat.flags & XIF_ICONFORAMT) and kartstuff[k_itemamount] > get)
	
	--fuck me
	if kartstuff[k_itemamount] > 1 and drawAmt then
		v.draw(fx + (flipamount and 48 or 0), fy, localmul[offset], V_HUDTRANS|fflags|(flipamount and V_FLIP or 0))
		if (blink and leveltime % blink == 0) or (not blink) and blink ~= -1 then
			v.draw(fx, fy, icn, itTflags|fflags, colour)
		end
		if offset == 2 then
			if flipamount then	-- reminder that this is for 3/4p's right end of the screen.
				v.drawString(fx+2, fy+31, "x" + kartstuff[k_itemamount], V_ALLOWLOWERCASE|V_HUDTRANS|fflags)
			else
				v.drawString(fx+24, fy+31, "x" + kartstuff[k_itemamount], V_ALLOWLOWERCASE|V_HUDTRANS|fflags)
			end
		else
			v.draw(fx+28, fy+41, kp_itemx, V_HUDTRANS|fflags)
			v.drawKartString(fx+38, fy+36, kartstuff[k_itemamount], V_HUDTRANS|fflags)
		end
	else
		if (blink and leveltime % blink == 0) or (not blink) and blink ~= -1 then
			v.draw(fx, fy, icn, itTflags|fflags, colour)
		end
	end

	--timer bar
	libfn.xItem_DrawTimerBar(v, p, c)

	if not disableBox then
		libfn.hudDrawItemCooldown(v, p, c)
	end
end

--had a look at eggpanic to make sure this works clean with that too out of the box
local function xItem_drawEggTimer(v, p, c)
	local fx, fy, fflags = xItemLib.func.hudFindFlags(v, p, c)
	
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		v.draw(fx+17, fy+13, v.cachePatch("K_EGGN" .. min(G_TicsToSeconds(p.kartstuff[k_eggmanexplode]), 5)), fflags|V_HUDTRANS)
	else -- now we're having a fun game.
		v.draw(fx+17, fy+13, v.cachePatch("K_EGGN" .. min(G_TicsToSeconds(p.kartstuff[k_eggmanexplode]), 5)), fflags|V_HUDTRANS)
	end
end

local function xItem_drawSad(v, p, c)
	local fx, fy, fflags = xItemLib.func.hudFindFlags(v, p, c)
	
	if splitscreen < 2 then
		v.draw(fx, fy, v.cachePatch("K_ITSAD"), fflags|V_HUDTRANS)
	else
		v.draw(fx, fy+13, v.cachePatch("K_ISSAD"), fflags|V_HUDTRANS)
	end
end

local function findItemDistributions(p, useodds, spbrush)
	local distributions = {
		totalodds = 0,
		it = {},
		odds = {},
		useodds = {}
	}
	
	distributions.pdis = lastpdis
	
	local libdat = xItemLib
	local libfn = xItemLib.func
	local cv = libdat.cvars
	local tg = libdat.toggles
	
	if tg.debugItem then
		local di = min(tg.debugItem, libfn.countItems())
		distributions.it = {di}
		distributions.odds = {1}
		distributions.totalodds = 1
		distributions.useodds = useodds or 0
		return distributions
	end

	for i = 1, libfn.countItems() do
		local odds = libfn.getOdds(useodds, i, 0, spbrush, p)
		if odds > 0 then
			table.insert(distributions.it, i)
			table.insert(distributions.odds, odds)
			distributions.totalodds = $ + odds
		end
	end

	// failsafe odds
	if distributions.totalodds == 0 then
		distributions.totalodds = 1
		distributions.it = {1}
		distributions.odds = {1}
	end

	distributions.useodds = useodds or 0

	return distributions
end

local function xItem_drawDistributions(v, p, c)
	if not (xItemLib.cvars.bItemDebugDistrib.value or xItemLib.cvars.bItemDebugDistribReplayOnly.value and replayplayback)	then return	end
	if p ~= displayplayers[0] then return end
	local libdat = xItemLib
	local libfn = xItemLib.func

	local fx = 40
	local fy = -10
	local totalodds = debuggerDistributions.totalodds
	for i = 1, #(debuggerDistributions.it) do
		local it = debuggerDistributions.it[i]
		local odds = debuggerDistributions.odds[i]
		local perc = FixedMul(10000*FRACUNIT, FixedDiv(odds, totalodds)) >> FRACBITS

		local s, get = libfn.getItemDataById(it).getItemPatchSingle(true, 1)
		local icn = v.cachePatch(s)
		v.draw(fx + 28 * ((i-1) % 10), fy + 30 * ((i-1) / 10), icn, V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS)
		v.drawString(fx + 28 * ((i-1) % 10) + 38, fy + 30 * ((i-1) / 10) + 26, (perc/100) + "." + (perc%100) + "%", V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS, "small-right")
	end

	-- God fixing this to use vanilla useodds number display to reduce confusion
	v.drawString(fx, fy + 12, "useodds : " + (debuggerDistributions.useodds-1) + "  pdis : " + debuggerDistributions.pdis, V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS, "small")
end

local function findAvailableRoulettePatches(p, useodds, spbrush)
	local available = {}
	local libdat = xItemLib
	local libfn = xItemLib.func
	local cv = libdat.cvars
	local tg = libdat.toggles
	
	if cv.bEnhancedRoulette.value and tg.debugItem then
		local di = min(tg.debugItem, libfn.countItems())
		available = {di}
		return available
	end
	
	for i = 1, libfn.countItems() do
		local dat = libfn.getItemDataById(i).showInRoulette
		if not dat then continue end
		if type(dat) == "function" then
			if dat(p) then
				table.insert(available, i)
				continue
			end
		else
			table.insert(available, i)
			continue
		end
	end
	
	--CTGP-7 roulette
	if cv.bEnhancedRoulette.value and useodds then
		local eav = {}
		for j = 1, #available do
			if libfn.getOdds(useodds, available[j], 0, spbrush, p) > 0 then
				table.insert(eav, available[j])
				continue
			end
		end
		available = eav
	end
	return available
end

local function xItem_hudMain(v, p, c)
	if not p then return end
	if not p.xItemData then return end
	dat = p.xItemData

	local libdat = xItemLib
	local libfn = libdat.func
	local dat = p.xItemData
	
	hud.disable("item")

	local status
	local err = false
	for i = 1, #libdat.xItemModNamespaces do
		local fn = libfn.getXItemModValue(i, -1, "hudoverride")
		--print(type(fn))
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, v, p, c)
		if not status then
			error(err, 1)
		end
	end

	if dat then
		splitplayers[#splitplayers+1] = p
		local kartstuff = p.kartstuff
		local itdat = libfn.getItemDataById(kartstuff[k_itemtype])
		if p.xItemData.enableHud then
			--handle vanilla special cases first
			if kartstuff[k_stolentimer] > 0 then
				libfn.hudDrawItem(v, p, c, 14, 2)
			elseif kartstuff[k_stealingtimer] > 0 and leveltime % 2 then
				libfn.hudDrawItem(v, p, c, 14)
			elseif kartstuff[k_eggmanexplode] then
				libfn.hudDrawItem(v, p, c, 5, 2)
				libfn.hudDrawEgg(v, p, c)
			elseif kartstuff[k_rocketsneakertimer] then
				libfn.hudDrawItem(v, p, c, 2, 2)
				dat.xItem_timerBar = kartstuff[k_rocketsneakertimer]
				dat.xItem_maxTimerBar = 8*3*TICRATE
			elseif kartstuff[k_growshrinktimer] > 0 then
				libfn.hudDrawItem(v, p, c, 11, 2)
				if kartstuff[k_growcancel] > 0 then
					dat.xItem_timerBar = kartstuff[k_growcancel]
					dat.xItem_maxTimerBar = 26
				end
			elseif kartstuff[k_sadtimer] or kartstuff[k_itemtype] == -1 then
				libfn.hudDrawItem(v, p, c, 0, -1)
				if leveltime % 2 then
					libfn.hudDrawSad(v, p, c)
				end
			--draw the roulette
			elseif dat.xItem_roulette then
				local av = availableItems[p.splitscreenindex + 1]
				--print(splitnum(p))
				if av and table.maxn(av) then
					libfn.hudDrawItem(v, p, c, av[((leveltime/3) % table.maxn(av)) + 1])
				end
			--draw the held item
			elseif kartstuff[k_itemtype] then
				--custom item hud drawer here (this only runs when the item is still in the slot, if special timers are involved like above the mod should handle that by itself)
				if itdat and itdat.hudfunc then
					pcall(itdat.hudfunc, v, p, c)
				else
					if kartstuff[k_itemheld] then
						libfn.hudDrawItem(v, p, c, kartstuff[k_itemtype], 2)
					else
						libfn.hudDrawItem(v, p, c, kartstuff[k_itemtype])
					end
				end
			elseif dat.xItem_itemSlotLockedTimer then
				libfn.hudDrawItemCooldownBox(v, p, c)
			end
			--crossmod "hooks"
			for i = 1, #libdat.xItemModNamespaces do
				local fn = libfn.getXItemModValue(i, kartstuff[k_itemtype], "itemhudfunc")
				if fn == nil or (not type(fn) == "function") then continue end
				local status, err = pcall(fn, v, p, c)
				if not status then
					error(err, 2)
				end
			end
		end	
		--debugger goes last
		libfn.xItem_drawDistributions(v, p, c)
	end
end

local function setDebugItem(p, cv)
	local i = tonumber(cv)
	local t
	if not i then
		i = tostring(cv)
		--for all the calls here we're ignoring errors
		--first search by friendly name
		t = xItemLib.func.findItemByFriendlyName(i, true)
		if t then
			if #t == 1 then
				xItemLib.toggles.debugItem = t[1]
				print("Set debugitem to \x82"..xItemLib.xItemData[t[1]].name.."\x80")
				return
			else
				table.sort(t)
				local s = ""
				CONS_Printf(p, "Found too many items! Did you mean:")
				for x, it in ipairs(t) do
					s = $..(xItemLib.xItemData[it].name.." (ID \x82".. it.."\x80)")
					if x ~= #t then
						s = $..", \n"
					end
				end
				CONS_Printf(p, s)
				
				s = nil
				return
			end
		end
		--then by internal
		t = xItemLib.func.findItemByNamespace(i, true)
		if t > 0 then
			xItemLib.toggles.debugItem = t
			print("Set debugitem to \x82"..xItemLib.xItemData[t].name.."\x80")
			return
		end
	end
	--then just vanilla kart behaviour
	i = max(min(tonumber(i) or 0, xItemLib.func.countItems()), 0)
	xItemLib.toggles.debugItem = i
	if i > 0 then
		print("Set debugitem to \x82"..xItemLib.xItemData[i].name.."\x80")
	else
		print("Disabled debugitem")
	end
	
	t = nil
	i = nil
end

local function toggleItem(p, cv)
	local i = tonumber(cv)
	local t
	if not i then
		i = tostring(cv)
		t = xItemLib.func.findItemByFriendlyName(i, true)
		if t then
			if #t == 1 then
				xItemLib.toggles.xItemToggles[t[1]] = (not $)
				xItemLib.toggles.allToggle = true
				print("\x82"..xItemLib.xItemData[t[1]].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[t[1]] and "enabled" or "disabled"))
				return
			else
				table.sort(t)
				local s = ""
				CONS_Printf(p, "Found too many items! Did you mean:")
				for x, it in ipairs(t) do
					s = $..(xItemLib.xItemData[it].name.." (ID \x82".. it.."\x80)")
					if x ~= #t then
						s = $..", \n"
					end
				end
				CONS_Printf(p, s)
				
				s = nil
				return
			end
		end
		--then by internal
		t = xItemLib.func.findItemByNamespace(i, true)
		if t > 0 then
			xItemLib.toggles.xItemToggles[t] = (not $)
			xItemLib.toggles.allToggle = true
			print("\x82"..xItemLib.xItemData[y].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[t] and "enabled" or "disabled"))
			return
		end
	end
	--then just vanilla kart behaviour (or all items if no argument)
	i = max(min(tonumber(i) or 0, xItemLib.func.countItems()), 0)
	if i > 0 then
		xItemLib.toggles.xItemToggles[i] = (not $)
		xItemLib.toggles.allToggle = true
		print("\x82"..xItemLib.xItemData[i].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[i] and "enabled" or "disabled"))
	else
		xItemLib.toggles.allToggle = (not $)
		for i = 1, xItemLib.func.countItems() do
			xItemLib.toggles.xItemToggles[i] = xItemLib.toggles.allToggle
		end
		print("Toggled all xItems to " .. (xItemLib.toggles.allToggle and "enabled (".."\x82".."all items".."\x80".." can appear)" or "disabled (only ".."\x82".."the first loaded item".."\x80".." will appear)"))
	end
	
	t = nil
	i = nil
end

local function listItem(p)
	CONS_Printf(p, "\n\3\135xItemLib\n\128by \130minenice\128")
	CONS_Printf(p, "Library version \130"..currLibVer.." (revision "..currRevVer..")")
	
	CONS_Printf(p, "\nNow listing all loaded xItems:\n----------------")
	local ndat = xItemLib.xItemNamespaces
	local itdat = xItemLib.xItemData
	local idat
	local nsp = ""
	for i = 1, xItemLib.func.countItems() do
		idat = itdat[i]
		for k, v in pairs(ndat) do
			if i == v then
				nsp = k
			end
		end
		if xItemLib.toggles.xItemToggles[i] then
			CONS_Printf(p, "\x83"..idat.name.."\x80 (Item ID \x82"..i.."\x80, namespaced \134"..nsp.."\x80)")
		else
			CONS_Printf(p, "\x85"..idat.name.."\x80 (Item ID \x82"..i.."\x80, namespaced \134"..nsp.."\x80)")
		end
	end
end

local function playerThinkFrame(p)
	local libdat = xItemLib
	local libfn = libdat.func
	if not p.xItemData then
		p.xItemData = {
			xItem_lastItem = 0,
			xItem_roulette = 0,
			xItem_rouletteType = 0,
			xItem_attackedDuringRoll = false,
			
			xItem_raceOdds = nil,
			xItem_battleOdds = nil,
			xItem_resetOddsNextRoll = 0, --0 = no, -1 = before rolling for an item, 1 = after rolling for an item
			
			xItem_blink = 0,
			xItem_blinkMode = 0,
			xItem_timerBar = 0,
			xItem_maxTimerBar = 0,
			
			xItem_pressedUse = 0,
			
			xItem_itemSlotLocked = false,
			xItem_itemSlotLockedTimer = 0,
			xItem_itemSlotLockedTimerMax = 0,
			
			xItem_Hud_availableItems = {},
			enableHud = true, --enables / disables the xItemLib item hud, as a replacement for hud.disable("item") and hud.enable("item")
		}

		--quick init step even though this may not do much
		libfn.getCVar("sneaker")
		libfn.getCVar("rocketsneaker")
		libfn.getCVar("invincibility")
		libfn.getCVar("banana")
		libfn.getCVar("eggmanmonitor")
		libfn.getCVar("orbinaut")
		libfn.getCVar("jawz")
		libfn.getCVar("mine")
		libfn.getCVar("ballhog")
		libfn.getCVar("selfpropelledbomb")
		libfn.getCVar("grow")
		libfn.getCVar("shrink")
		libfn.getCVar("thundershield")
		libfn.getCVar("hyudoro")
		libfn.getCVar("pogospring")
		libfn.getCVar("kitchensink")
		libfn.getCVar("triplesneaker")
		libfn.getCVar("triplebanana")
		libfn.getCVar("decabanana")
		libfn.getCVar("tripleorbinaut")
		libfn.getCVar("quadorbinaut")
		libfn.getCVar("dualjawz")
	end

	for i = 1, #libdat.xItemModNamespaces do
		local fn = libfn.getXItemModValue(i, -1, "preplayerthink")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, p, p.cmd)
		if not status then
			error(err, 1)
		end
	end
	
	libfn.xItem_handleDistributionDebugger(p)
	libfn.attackHandler(p, p.cmd)
	libfn.doRoulette(p, p.cmd)
	
	for i = 1, #libdat.xItemModNamespaces do
		local fn = libfn.getXItemModValue(i, -1, "postplayerthink")
		if fn == nil or (not type(fn) == "function") then continue end
		local status, err = pcall(fn, p, p.cmd)
		if not status then
			error(err, 1)
		end
	end
end

if not xItemLib then
	print("\3\135xItemLib\n\128by \130minenice\128")
	print("Initial xItemLib loading...")
	print("Library version \130"..currLibVer.." (revision "..currRevVer..")")
	
	rawset(_G, "xItemLib", {
		gLibVersion = currLibVer,
		gRevVersion = currRevVer,
		func = {},
		xItems = {},
		xItemNamespaces = {},
		xItemData = {}, --holds an item name, functions (on get (when rolled), on use, hud function), default raceodds, default battleodds
		xItemPatch = {}, --format is {{tics, bigpatch1, bigpatch2, ...}, {tics, smallpatch1, smallpatch2, ...}}
		xItemFlags = {},
		
		--extra item data
		xItemModNamespaces = {},
		xItemCrossData = {
			modData = {},
			itemData = {},
		}, 
		
		xItemOddsRace = {},
		xItemOddsBattle = {},
		cvars = {},
		--not netsynched
		localAvailableItems = availableItems,

		toggles = {
			debugItem = 0,
			allToggle = true,
			xItemToggles = {},
		}
	})

	rawset(_G, "K_FlipFromObject", K_FlipFromObject)
	
	xItemLib.func.countItems = getLoadedItemAmount
	xItemLib.func.addItem = addXItem
	xItemLib.func.resetItemOdds = resetOddsForItem
	xItemLib.func.setPlayerOddsForItem = setPlayerOddsForItem
	xItemLib.func.getPlayerScaling = playerScaling
	xItemLib.func.getStartCountdown = checkStartCooldown
	xItemLib.func.getPowerOdds = checkPowerItemOdds
	xItemLib.func.floatingItemThinker = floatingItemThinker
	xItemLib.func.floatingItemSpecial = floatingItemSpecial
	xItemLib.func.itemBoxSpecial = itemBoxSpecial
	xItemLib.func.getItemResult = xItem_GetItemResult
	xItemLib.func.getOdds = xItem_GetOdds
	xItemLib.func.setupDist = setupDistTable
	xItemLib.func.findUseOdds = xItem_FindUseOdds
	xItemLib.func.doRoulette = xItem_ItemRoulette
	xItemLib.func.attackHandler = xItem_BasicItemHandler
	xItemLib.func.hudFindFlags = xItem_FindHudFlags
	xItemLib.func.hudDrawItemBox = xItem_DrawItemBox
	xItemLib.func.xItem_DrawTimerBar = xItem_DrawTimerBar
	xItemLib.func.hudDrawItem = xItem_DrawItem
	xItemLib.func.hudDrawEgg = xItem_drawEggTimer
	xItemLib.func.hudDrawSad = xItem_drawSad
	xItemLib.func.hudDrawItemCooldown = xItem_DrawItemMinecraftCooldown
	xItemLib.func.hudDrawItemCooldownBox = xItem_DrawCooldownItemBox
	xItemLib.func.hudMain = xItem_hudMain
	xItemLib.func.playerThinker = playerThinkFrame
	xItemLib.func.hudFindRouletteItems = findAvailableRoulettePatches
	xItemLib.func.findItemByNamespace = findItemByNamespace
	xItemLib.func.findItemByFriendlyName = findItemByFriendlyName
	xItemLib.func.getCVar = getCVar
	xItemLib.func.findItemDistributions = findItemDistributions
	xItemLib.func.xItem_drawDistributions = xItem_drawDistributions
	xItemLib.func.xItem_handleDistributionDebugger = xItem_handleDistributionDebugger
	xItemLib.func.xItem_setPlayerItemCooldown = setPlayerItemCooldown
	xItemLib.func.playerCmdHook = playerCmdHook
	--here you go yoshimo lmao
	xItemLib.func.canUseItem = canUseItem
	--a
	xItemLib.func.floatingXItemThinker = floatingXItemThinker
	xItemLib.func.floatingXItemSpecial = floatingXItemSpecial
	xItemLib.func.playerArrowThinker = playerArrowThinker
	xItemLib.func.vanillaArrowThinker = vanillaArrowThinker
	--crossmod support
	xItemLib.func.addXItemMod = addXItemMod
	xItemLib.func.setXItemModData = setXItemModData
	xItemLib.func.getXItemModData = getXItemModData
	xItemLib.func.getXItemModValue = getXItemModValue
	--OOP stuff
	xItemLib.func.getItemDataById = getItemDataById
	xItemLib.func.getItemDataByName = getItemDataByName
	
	--console commands
	xItemLib.func.setDebugItem = setDebugItem
	xItemLib.func.toggleItem = toggleItem
	xItemLib.func.listItem = listItem
	
	
	COM_AddCommand("xitemdebugitem", xItemLib.func.setDebugItem, 1) --equivalent to kartdebugitem, can also take item names
	COM_AddCommand("togglexitem", xItemLib.func.toggleItem, 1) --toggles specified items, or all if none specified
	COM_AddCommand("listxitem", xItemLib.func.listItem, 4) --prints all item names to the console
	
	xItemLib.cvars.dItemDebugAmt = CV_RegisterVar({ --equivalent to kartdebugamount
		name = "xitemdebugamount",
		defaultvalue = "1",
		flags = CV_NETVAR,
		possiblevalue = CV_Natural
	})
	xItemLib.cvars.bXRig = CV_RegisterVar({ --rig 2
		name = "xitemdebugrig",
		defaultvalue = "Yes",
		flags = CV_NETVAR,
		possiblevalue = CV_YesNo
	})
	xItemLib.cvars.bEnhancedRoulette = CV_RegisterVar({ --enables the CTGP-7 style enhanced roulette
		name = "xitemroulette",
		defaultvalue = "No",
		possiblevalue = CV_YesNo
	})
	xItemLib.cvars.bRouletteAnim = CV_RegisterVar({ --enables the fancy roulette animation
		name = "xitemrouletteanim",
		defaultvalue = "No",
		possiblevalue = CV_YesNo
	})
	xItemLib.cvars.bItemDebugDistrib = CV_RegisterVar({ --distribution debugger
		name = "xitemdebugdistributions",
		defaultvalue = "No",
		flags = CV_NETVAR,
		possiblevalue = CV_YesNo
	})
	-- Ashnal: Couple new cvars
	-- This is a non-netvar that allows you to view the distribution debugger within replays, without allowing it in netgames that the replays come from
	xItemLib.cvars.bItemDebugDistribReplayOnly = CV_RegisterVar({ --distribution debugger
		name = "xitemdebugdistributionsreplay",
		defaultvalue = "No",
		flags = nil,
		possiblevalue = CV_YesNo
	})
	-- This one logs all item rolls in the server players log, nice for dedicated servers, but requires hostmod to properly set consoleplayer
	xItemLib.cvars.bServerLogRolls = CV_RegisterVar({ --distribution debugger
		name = "xitemserverlogrolls",
		defaultvalue = "No",
		flags = nil,
		possiblevalue = CV_YesNo
	})
	
	xItemLib.cvars.bItemDistCalcConga = CV_RegisterVar({ -- conga line option
		name = "xitemdistcalcconga",
		defaultvalue = "No",
		flags = CV_NETVAR,
		possiblevalue = CV_YesNo
	})
	
	local function spbOdds(newodds, pos, mashed, rush, p, secondist, pingame, pexiting)
		local nod = newodds
		local distvar = 64*14
		if ((indirectitemcooldown > 0) or (pexiting > 0) or (secondist/distvar < 3)) and (pos ~= 10) then -- Force SPB
			nod = 0
		else
			nod = $ * min((secondist/distvar)-4, 3)
		end
		return nod
	end
	
	local function hyuuOdds(newodds, pos, mashed, rush, p, secondist, pingame, pexiting)
		local nod = newodds
		if (hyubgone > 0) or (pingame-1 <= pexiting) then
			nod = 0
		end
		return nod
	end
	
	local function shrinkOdds(newodds, pos, mashed, rush, p, secondist, pingame, pexiting)
		local nod = newodds
		if (indirectitemcooldown > 0) or (pingame-1 <= pexiting) then
			nod = 0
		end
		return nod
	end
	
	local function getSpb(p, i)
		K_SetIndirectItemCooldown(20*TICRATE)
	end
	
	local function getHyuu(p, i)
		K_SetHyudoroCooldown(5*TICRATE)
	end
	
	local function getTripleShoe(p, i)
		return xItemLib.xItemNamespaces["KITEM_SNEAKER"], 3
	end
	
	local function getTripleBanana(p, i)
		return xItemLib.xItemNamespaces["KITEM_BANANA"], 3
	end
	
	local function getDecaBanana(p, i)
		return xItemLib.xItemNamespaces["KITEM_BANANA"], 10
	end
	
	local function getTripleOrbi(p, i)
		return xItemLib.xItemNamespaces["KITEM_ORBINAUT"], 3
	end
	
	local function getQuadOrbi(p, i)
		return xItemLib.xItemNamespaces["KITEM_ORBINAUT"], 4
	end
	
	local function getDualJawz(p, i)
		return xItemLib.xItemNamespaces["KITEM_JAWZ"], 2
	end
	
	local function showPogo(p)
		if (G_BattleGametype()) then
			return true
		else
			return false
		end
	end

	hud.add(function(v, p, c)
		xItemLib.func.hudMain(v, p, c)
	end, "game")
	
	addHook("ThinkFrame", do
		for i = 0, #players-1 do
			if players[i] then
				xItemLib.func.playerThinker(players[i])
			end
		end
	end)

	addHook("PlayerCmd", xItemLib.func.playerCmdHook)

	--dropped item behaviour
	addHook("MobjThinker", xItemLib.func.floatingItemThinker, MT_FLOATINGITEM)

	addHook("TouchSpecial", xItemLib.func.floatingItemSpecial, MT_FLOATINGITEM)

	addHook("TouchSpecial", xItemLib.func.itemBoxSpecial, MT_RANDOMITEM)
	
	addHook("MobjThinker", xItemLib.func.floatingXItemThinker, MT_FLOATINGXITEM)

	addHook("TouchSpecial", xItemLib.func.floatingXItemSpecial, MT_FLOATINGXITEM)
	
	addHook("MobjThinker", xItemLib.func.playerArrowThinker, MT_XITEMPLAYERARROW)
	
	addHook("MobjThinker", xItemLib.func.vanillaArrowThinker, MT_PLAYERARROW)

	xItemLib.func.addItem{"KITEM_SNEAKER", "Sneaker", "K_ITSHOE", "K_ISSHOE", vanillaItemProps["KITEM_SNEAKER"].flags, vanillaItemProps["KITEM_SNEAKER"].raceodds, vanillaItemProps["KITEM_SNEAKER"].battleodds, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 1}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_ROCKETSNEAKER", "Rocket Sneaker", "K_ITRSHE", "K_ISRSHE", vanillaItemProps["KITEM_ROCKETSNEAKER"].flags, vanillaItemProps["KITEM_ROCKETSNEAKER"].raceodds, vanillaItemProps["KITEM_ROCKETSNEAKER"].battleodds, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 2}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_INVINCIBILITY", "Invincibility", {3, "K_ITINV1", "K_ITINV2", "K_ITINV3", "K_ITINV4", "K_ITINV5", "K_ITINV6", "K_ITINV7"}, {3, "K_ISINV1", "K_ISINV2", "K_ISINV3", "K_ISINV4", "K_ISINV5", "K_ISINV6"}, vanillaItemProps["KITEM_INVINCIBILITY"].flags,vanillaItemProps["KITEM_INVINCIBILITY"].raceodds, vanillaItemProps["KITEM_INVINCIBILITY"].battleodds, nil, nil, nil, nil, nil, {3, {SPR_ITMI, A}, {SPR_ITMI, B}, {SPR_ITMI, C}, {SPR_ITMI, D}, {SPR_ITMI, E}, {SPR_ITMI, F}, {SPR_ITMI, G}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_BANANA", "Banana", "K_ITBANA", "K_ISBANA", vanillaItemProps["KITEM_BANANA"].flags, vanillaItemProps["KITEM_BANANA"].raceodds, vanillaItemProps["KITEM_BANANA"].battleodds, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 4}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_EGGMAN", "Eggman Monitor", "K_ITEGGM", "K_ISEGGM", vanillaItemProps["KITEM_EGGMAN"].flags, vanillaItemProps["KITEM_EGGMAN"].raceodds, vanillaItemProps["KITEM_EGGMAN"].battleodds, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 5}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_ORBINAUT", "Orbinaut", {35, "K_ITORB1", "K_ITORB2", "K_ITORB3", "K_ITORB4"}, "K_ISORBN", vanillaItemProps["KITEM_ORBINAUT"].flags, vanillaItemProps["KITEM_ORBINAUT"].raceodds, vanillaItemProps["KITEM_ORBINAUT"].battleodds, nil, nil, nil, nil, nil, {4, {SPR_ITMO, A}, {SPR_ITMO, B}, {SPR_ITMO, C}, {SPR_ITMO, D}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_JAWZ", "Jawz", "K_ITJAWZ", "K_ISJAWZ", vanillaItemProps["KITEM_JAWZ"].flags, vanillaItemProps["KITEM_JAWZ"].raceodds, vanillaItemProps["KITEM_JAWZ"].battleodds, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 7}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_MINE", "Mine", "K_ITMINE", "K_ISMINE", vanillaItemProps["KITEM_MINE"].flags, vanillaItemProps["KITEM_MINE"].raceodds, vanillaItemProps["KITEM_MINE"].battleodds, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 8}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_BALLHOG", "Ballhog", "K_ITBHOG", "K_ISBHOG", vanillaItemProps["KITEM_BALLHOG"].flags, vanillaItemProps["KITEM_BALLHOG"].raceodds, vanillaItemProps["KITEM_BALLHOG"].battleodds, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 9}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_SPB", "Self-Propelled Bomb", "K_ITSPB", "K_ISSPB", vanillaItemProps["KITEM_SPB"].flags, vanillaItemProps["KITEM_SPB"].raceodds, vanillaItemProps["KITEM_SPB"].battleodds, getSpb, nil, nil, spbOdds, nil,  {0, {SPR_ITEM, 10}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_GROW", "Grow", "K_ITGROW", "K_ISGROW", vanillaItemProps["KITEM_GROW"].flags, vanillaItemProps["KITEM_GROW"].raceodds, vanillaItemProps["KITEM_GROW"].battleodds, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 11}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_SHRINK", "Shrink", "K_ITSHRK", "K_ISSHRK", vanillaItemProps["KITEM_SHRINK"].flags, vanillaItemProps["KITEM_SHRINK"].raceodds, vanillaItemProps["KITEM_SHRINK"].battleodds, getSpb, nil, nil, shrinkOdds, nil,  {0, {SPR_ITEM, 12}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_THUNDERSHIELD", "Thunder Shield", "K_ITTHNS", "K_ISTHNS", vanillaItemProps["KITEM_THUNDERSHIELD"].flags, vanillaItemProps["KITEM_THUNDERSHIELD"].raceodds, vanillaItemProps["KITEM_THUNDERSHIELD"].battleodds, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 13}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_HYUDORO", "Hyudoro", "K_ITHYUD", "K_ISHYUD", vanillaItemProps["KITEM_HYUDORO"].flags, vanillaItemProps["KITEM_HYUDORO"].raceodds, vanillaItemProps["KITEM_HYUDORO"].battleodds, getHyuu, nil, nil, hyuuOdds, nil,  {0, {SPR_ITEM, 14}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_POGOSPRING", "Pogo Spring", "K_ITPOGO", "K_ISPOGO", vanillaItemProps["KITEM_POGOSPRING"].flags, vanillaItemProps["KITEM_POGOSPRING"].raceodds, vanillaItemProps["KITEM_POGOSPRING"].battleodds, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 15}}, showPogo, nil, nil} --what if I throw in a sneaky pogo lmao
	xItemLib.func.addItem{"KITEM_KITCHENSINK", "Kitchen Sink", "K_ITSINK", "K_ISSINK", vanillaItemProps["KITEM_KITCHENSINK"].flags, vanillaItemProps["KITEM_KITCHENSINK"].raceodds, vanillaItemProps["KITEM_KITCHENSINK"].battleodds, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 16}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TRIPLESNEAKER", "Triple Sneaker", "K_ITSHOE", "K_ISSHOE", vanillaItemProps["KRITEM_TRIPLESNEAKER"].flags, vanillaItemProps["KRITEM_TRIPLESNEAKER"].raceodds, vanillaItemProps["KRITEM_TRIPLESNEAKER"].battleodds, nil, nil, nil, nil, getTripleShoe,  {0, {SPR_ITEM, 1}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TRIPLEBANANA", "Triple Banana", "K_ITBANA", "K_ISBANA", vanillaItemProps["KRITEM_TRIPLEBANANA"].flags, vanillaItemProps["KRITEM_TRIPLEBANANA"].raceodds, vanillaItemProps["KRITEM_TRIPLEBANANA"].battleodds, nil, nil, nil, nil, getTripleBanana, {0, {SPR_ITEM, 4}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TENFOLDBANANA", "Deca Banana", "K_ITBANA", "K_ISBANA", vanillaItemProps["KRITEM_TENFOLDBANANA"].flags, vanillaItemProps["KRITEM_TENFOLDBANANA"].raceodds, vanillaItemProps["KRITEM_TENFOLDBANANA"].battleodds, nil, nil, nil, nil, getDecaBanana, {0, {SPR_ITEM, 5}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TRIPLEORBINAUT", "Triple Orbinaut", "K_ITORB3", "K_ISORBN", vanillaItemProps["KRITEM_TRIPLEORBINAUT"].flags, vanillaItemProps["KRITEM_TRIPLEORBINAUT"].raceodds, vanillaItemProps["KRITEM_TRIPLEORBINAUT"].battleodds, nil, nil, nil, nil, getTripleOrbi, {0, {SPR_ITMO, C}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_QUADORBINAUT", "Quad Orbinaut", "K_ITORB4", "K_ISORBN", vanillaItemProps["KRITEM_QUADORBINAUT"].flags, vanillaItemProps["KRITEM_QUADORBINAUT"].raceodds, vanillaItemProps["KRITEM_QUADORBINAUT"].battleodds, nil, nil, nil, nil, getQuadOrbi, {0, {SPR_ITMO, D}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_DUALJAWZ", "Dual Jawz", "K_ITJAWZ", "K_ISJAWZ", vanillaItemProps["KRITEM_DUALJAWZ"].flags, vanillaItemProps["KRITEM_DUALJAWZ"].raceodds, vanillaItemProps["KRITEM_DUALJAWZ"].battleodds, nil, nil, nil, nil, getDualJawz, {0, {SPR_ITEM, 7}}, false, nil, nil}
	xItemLib.func.addXItemMod("XITEM_CORE", "xItemLib", {lib = "by minenice"})
	
	addHook("NetVars", function(net)
		xItemLib.toggles = net(xItemLib.toggles)
	end)
end

if xItemLib.gLibVersion < currLibVer or (xItemLib.gLibVersion == currLibVer and (xItemLib.gRevVersion ~= nil and xItemLib.gRevVersion < currRevVer)) then
	print("\3\135xItemLib\n\128by \130minenice\128")
	print("Updating to library version \130"..currLibVer.." (revision "..currRevVer..")")
	xItemLib.func = {}
	xItemLib.func.countItems = getLoadedItemAmount
	xItemLib.func.addItem = addXItem
	xItemLib.func.resetItemOdds = resetOddsForItem
	xItemLib.func.setPlayerOddsForItem = setPlayerOddsForItem
	xItemLib.func.getPlayerScaling = playerScaling
	xItemLib.func.getStartCountdown = checkStartCooldown
	xItemLib.func.getPowerOdds = checkPowerItemOdds
	xItemLib.func.floatingItemThinker = floatingItemThinker
	xItemLib.func.floatingItemSpecial = floatingItemSpecial
	xItemLib.func.itemBoxSpecial = itemBoxSpecial
	xItemLib.func.getItemResult = xItem_GetItemResult
	xItemLib.func.getOdds = xItem_GetOdds
	xItemLib.func.setupDist = setupDistTable
	xItemLib.func.findUseOdds = xItem_FindUseOdds
	xItemLib.func.doRoulette = xItem_ItemRoulette
	xItemLib.func.attackHandler = xItem_BasicItemHandler
	xItemLib.func.hudFindFlags = xItem_FindHudFlags
	xItemLib.func.hudDrawItemBox = xItem_DrawItemBox
	xItemLib.func.hudDrawItem = xItem_DrawItem
	xItemLib.func.hudDrawEgg = xItem_drawEggTimer
	xItemLib.func.hudDrawSad = xItem_drawSad
	xItemLib.func.hudMain = xItem_hudMain
	xItemLib.func.playerThinker = playerThinkFrame
	xItemLib.func.hudFindRouletteItems = findAvailableRoulettePatches
	xItemLib.func.findItemByNamespace = findItemByNamespace
	xItemLib.func.findItemByFriendlyName = findItemByFriendlyName
	xItemLib.func.canUseItem = canUseItem
	xItemLib.func.floatingXItemThinker = floatingXItemThinker
	xItemLib.func.floatingXItemSpecial = floatingXItemSpecial
	xItemLib.func.playerArrowThinker = playerArrowThinker
	xItemLib.func.vanillaArrowThinker = vanillaArrowThinker
	xItemLib.func.addXItemMod = addXItemMod
	xItemLib.func.setXItemModData = setXItemModData
	xItemLib.func.getXItemModData = getXItemModData
	xItemLib.func.getXItemModValue = getXItemModValue
	xItemLib.func.getCVar = getCVar
	xItemLib.func.findItemDistributions = findItemDistributions
	xItemLib.func.xItem_drawDistributions = xItem_drawDistributions
	xItemLib.func.xItem_handleDistributionDebugger = xItem_handleDistributionDebugger
	xItemLib.func.xItem_setPlayerItemCooldown = setPlayerItemCooldown
	xItemLib.func.hudDrawItemCooldown = xItem_DrawItemMinecraftCooldown
	xItemLib.func.hudDrawItemCooldownBox = xItem_DrawCooldownItemBox
	xItemLib.func.playerCmdHook = playerCmdHook
	xItemLib.func.xItem_DrawTimerBar = xItem_DrawTimerBar

	xItemLib.func.getItemDataById = getItemDataById
	xItemLib.func.getItemDataByName = getItemDataByName

	xItemLib.func.setDebugItem = setDebugItem
	xItemLib.func.toggleItem = toggleItem
	xItemLib.func.listItem = listItem

	-- first time I'm doing this
	if (xItemLib.gLibVersion < 112) then
		COM_AddCommand("xitemdebugitem", xItemLib.func.setDebugItem, 1) --equivalent to kartdebugitem, can also take item names
		COM_AddCommand("togglexitem", xItemLib.func.toggleItem, 1)
		COM_AddCommand("listxitem", xItemLib.func.listItem, 4)
		rawset(_G, "K_FlipFromObject", K_FlipFromObject)

		xItemLib.xItemData[xItemLib.xItemNamespaces["KITEM_INVINCIBILITY"]].flags = XIF_COOLDOWNONSTART
		xItemLib.xItemData[xItemLib.xItemNamespaces["KITEM_MINE"]].flags = XIF_COOLDOWNONSTART

		xItemLib.cvars.bXRig = CV_RegisterVar({ --rig 2
			name = "xitemdebugrig",
			defaultvalue = "Yes",
			flags = CV_NETVAR,
			possiblevalue = CV_YesNo
		})
	end
	
	if (xItemLib.gLibVersion < 113) then -- Monkey see, monkey follow?
		-- Ashnal: Couple new cvars
		-- This is a non-netvar that allows you to view the distribution debugger within replays, without allowing it in netgames that the replays come from
		xItemLib.cvars.bItemDebugDistribReplayOnly = CV_RegisterVar({ --distribution debugger
			name = "xitemdebugdistributionsreplay",
			defaultvalue = "No",
			flags = nil,
			possiblevalue = CV_YesNo
		})
		-- This one logs all item rolls in the server players log, nice for dedicated servers, but requires hostmod to properly set consoleplayer
		xItemLib.cvars.bServerLogRolls = CV_RegisterVar({ --distribution debugger
			name = "xitemserverlogrolls",
			defaultvalue = "No",
			flags = nil,
			possiblevalue = CV_YesNo
		})
		
		xItemLib.cvars.bItemDistCalcConga = CV_RegisterVar({ -- conga line option
			name = "xitemdistcalcconga",
			defaultvalue = "No",
			flags = CV_NETVAR,
			possiblevalue = CV_YesNo
		})
	end

	xItemLib.gLibVersion = currLibVer
	xItemLib.gRevVersion = currRevVer
else
	print("xItemLib is to date")
end
