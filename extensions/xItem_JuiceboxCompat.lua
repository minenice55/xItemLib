--don't load shit if xItem isn't loaded
if not xItemLib then return end
-- idem for JB
if not JUICEBOX then return end

local xItemLib = xItemLib
local libfunc = xItemLib.func
local modName = "XITEM_JUICELAYER"

local k_itemtype = k_itemtype
local k_itemblink = k_itemblink
local k_itemheld = k_itemheld
local k_itemamount = k_itemamount

local XIF_POWERITEM = 1 --is power item (affects final odds)
local XIF_COOLDOWNONSTART = 2 --can't be obtained on start cooldown
local XIF_UNIQUE = 4 --only one can exist in anyone's slot
local XIF_LOCKONUSE = 8 --locks the item slot when the item is used, slot must be unlocked manually by setting player.xItemData.xItem_itemSlotLocked to false
local XIF_COOLDOWNINDIRECT = 16 --checks if indirectitemcooldown is 0
local XIF_COLPATCH2PLAYER = 32 --map hud patch colour to player prefcolor
local XIF_ICONFORAMT = 64 --item icon and dropped item frame changes depending on the item amount (animation frames become amount frames)

--create the extension and bind to the lib
local JuiceExt = {}

-- let custom items activate itemspy
-- use `xItemLib.func.getXItemModData("XITEM_JUICELAYER", "KITEM_NAME")["itemspy_eligible"] = true` 
-- after defining your item to enable itemspy for it
local function itemSpyEligible(p)
	if not JUICEBOX.value then return false end
	local dat = libfunc.getXItemModData(modName, p.kartstuff[k_itemtype])
	if (dat == null) then return false end
	return dat["itemspy_eligible"] or false
end

local function arrowThinker(mobj)
	if G_BattleGametype() then return end
    if not JUICEBOX.value then return end

	if mobj and mobj.valid and mobj.target and mobj.target.player and mobj.target.player.health then
        local p = mobj.target.player
		if not p.JBSpy then
			p.JBspy = mobj
		end
	end
end

local function minimapSpy(v, p, c)
	if not JUICEBOX.value then return end

	if not (p and p.mo and p.mo.valid) then return end
	if not itemSpyEligible(p) then return end
	for dude in players.iterate
		if dude == p then continue end
		if not (dude.mo and dude.mo.valid) then continue end
		if (not dude.kartstuff[k_itemtype]) or (dude.kartstuff[k_itemblink]) or (dude.kartstuff[k_itemheld]) then continue end
		local itdat = libfunc.getItemDataById(dude.kartstuff[k_itemtype])
		if (itdat == null) return end
		local idx = 0
		if itdat.flags and (itdat.flags & XIF_ICONFORAMT) then 
			idx = kartstuff[k_itemamount]
		else
			idx = leveltime
		end
		print("spying on player " .. dude.name .. " holding item " .. itdat.name)
		v.drawOnMinimap(dude.mo.x, dude.mo.y, 2*FRACUNIT/3, v.cachePatch(itdat.getItemPatchSingle(true, idx), SKINCOLOR_NONE))
	end
end

local function spawnOverhead(p)
	p.JBspy = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z + P_GetPlayerHeight(p)+16*FRACUNIT, MT_XITEMPLAYERARROW)
	p.JBspy.target = p.mo
	p.JBspy.flags2 = $|MF2_DONTDRAW
end

function JuiceExt.postplayerthink(p, cmd)
	if G_BattleGametype() then return end
    if not JUICEBOX.value then return end
	
	if not (p.mo and p.mo.valid) then return end
    if p.spectator then return end

	if p.playerstate == PST_LIVE then
		if not p.JBspy then
			spawnOverhead(p)
		elseif not p.JBspy.valid then
			spawnOverhead(p)
		end
	end
	
	if p.JBspy and p.JBspy.valid then
        p.JBspy.scale = FRACUNIT
		p.JBspy.color = p.skincolor
		if JUICEBOX_dp and JUICEBOX_dp.valid and p.valid and p.JBspy.tracer and (not splitscreen) then
			p.JBspy.flags2 = $|MF2_DONTDRAW
			p.JBspy.tracer.flags2 = $|MF2_DONTDRAW
			if p.kartstuff[k_itemblink] then
				p.JBspy.flags2 = $|MF2_SHADOW
				p.JBspy.tracer.flags2 = $|MF2_SHADOW
			else
				p.JBspy.flags2 = $ & ~MF2_SHADOW
				p.JBspy.tracer.flags2 = $ & ~MF2_SHADOW				
			end
			if p != JUICEBOX_dp and p.playerstate == PST_LIVE and itemSpyEligible(JUICEBOX_dp) and p.kartstuff[k_itemamount] then
				p.JBspy.flags2 = $ & (~MF2_DONTDRAW)
				p.JBspy.tracer.flags2 = $ & (~MF2_DONTDRAW)
			end
		end
	end
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
local function returnSplitflags(f, displaynum)
	if not (splitscreen) return f end

	if (splitscreen == 1)
		if (displaynum == 1)
			return f & ~(V_SNAPTOBOTTOM)
		else	-- p2
			return (f|V_SPLITSCREEN) & ~(V_SNAPTOTOP)
		end
	else
		if (displaynum == 1)
			return f & ~(V_SNAPTOBOTTOM|V_SNAPTORIGHT)
		elseif (displaynum == 2)	-- p2
			return (f|V_HORZSCREEN) & ~(V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		elseif (displaynum == 3)	-- p3
			return (f|V_SPLITSCREEN) & ~(V_SNAPTOTOP|V_SNAPTORIGHT)
		elseif (displaynum == 4)	-- p4
			return (f|V_SPLITSCREEN|V_HORZSCREEN) & ~(V_SNAPTOTOP|V_SNAPTOLEFT)
		end
	end
	return f
end

local function gatebar(v, p, c)
	if not JUICEBOX.value then return end
	if not (p.mo and p.mo.valid and p.gatedecay) then return end
	local right = (findSplitPlayerNum(p) == 2 or findSplitPlayerNum(p) == 4)
	local x, y = 5, (splitscreen) and 3 or 5
	local flags = returnSplitflags(V_SNAPTOLEFT|V_SNAPTOTOP|V_HUDTRANS, findSplitPlayerNum(p))
	if ((splitscreen) > 1) then
		x, y = (right) and 121 or -9, -8
		flags = returnSplitflags(V_SNAPTOLEFT|V_SNAPTORIGHT|V_SNAPTOTOP|V_HUDTRANS, findSplitPlayerNum(p))
	end
	local split_prefix = (splitscreen > 1) and "S" or "T"

	local gatebarsplit = (splitscreen > 1) and "S" or "R"
	if splitscreen == 1 then gatebarsplit = "M" end
	local gatebar = v.cachePatch("GBA"..gatebarsplit..((leveltime/3)%4)..(100-p.gatedecay))
	local itblink = p.kartstuff[k_itemblink]>4 and (not p.JBflashhold) and leveltime%2 -- JUICE: we hold itemblink for hyu balance but it looks shitty
	local showgatebar = (p.gatedecay < 100 or p.gatebarhappy < (1*TICRATE/3+6) or p.kartstuff[k_itemtype])

	showgatebar = showgatebar and (not G_BattleGametype())
	if showgatebar then
		local tcol = v.getColormap(p.mo.skin, p.mo.color)
		local tflag = flags&(~V_HUDTRANS)|((p.kartstuff[k_position] == 1) and V_HUDTRANSHALF or V_HUDTRANS)
		if p.gatedecay == 100 and (leveltime % 2) then
			tcol = v.getColormap(TC_ALLWHITE, SKINCOLOR_WHITE)
		elseif p.techedrecently and (leveltime % 2) then
			tcol = v.getColormap(TC_BLINK, p.skincolor)
		elseif (abs(p.techpenalty - leveltime) <= TICRATE/2) and (leveltime % 2)
			tcol = v.getColormap(TC_RAINBOW, SKINCOLOR_RED)
		elseif p.kartstuff[k_position] == 1 then
			tcol = v.getColormap(TC_RAINBOW, SKINCOLOR_BLACK)
		elseif p.decayflashrate and p.kartstuff[k_itemtype] and (not ((leveltime/3)%(p.decayflashrate)))
			-- tcol = v.getColormap(TC_RAINBOW, SKINCOLOR_RED)
			--tflag = $&(~V_HUDTRANS)|V_HUDTRANSHALF
		elseif p.gatedecay <= 98 and (not p.kartstuff[k_itemtype]) and (not ((leveltime/3)%(TICRATE/3)))
			-- tcol = v.getColormap(TC_RAINBOW, SKINCOLOR_GREEN)
			--tflag = $&(~V_HUDTRANS)|V_HUDTRANSHALF
		end

		if splitscreen>1 then
			if right then
				v.drawScaled((x+13)<<FRACBITS, (y+34)<<FRACBITS, FRACUNIT, gatebar, V_FLIP|tflag, tcol)
			else
				v.drawScaled((x+35)<<FRACBITS, (y+34)<<FRACBITS, FRACUNIT, gatebar, tflag, tcol)
			end
		else
			v.drawScaled((x+46)<<FRACBITS, (y+46)<<FRACBITS, FRACUNIT, gatebar, tflag, tcol)
		end

		if not (p.kartstuff[k_itemtype] or p.xItemData.xItem_itemSlotLockedTimer) then
			libfunc.hudDrawItemBox(v, p, c, true)
		end
	end
end

function JuiceExt.hudoverride(v, p, c)
	if not JUICEBOX.value then return end
	gatebar(v, p, c)
	minimapSpy(v, p, c)
end

JuiceExt["itemspy_eligible"] = false
if xItemLib then
	xItemLib.func.addXItemMod(modName, "xItemLib Juicebox Compat Layer", JuiceExt)
	xItemLib.func.getXItemModData(modName, "KITEM_HYUDORO")["itemspy_eligible"] = true
end
