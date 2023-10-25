--don't load shit if xItem isn't loaded
if not xItemLib then return end

local xItemLib = xItemLib
local libfunc = xItemLib.func

--create the extension and bind to the lib
--use some new tech here
local MultiSlotsExt = {}

local XIF_POWERITEM = 1 --is power item (affects final odds)
local XIF_COOLDOWNONSTART = 2 --can't be obtained on start cooldown
local XIF_UNIQUE = 4 --only one can exist in anyone's slot
local XIF_LOCKONUSE = 8 --locks the item slot when the item is used, slot must be unlocked manually by setting player.xItemData.xItem_itemSlotLocked to false
local XIF_COOLDOWNINDIRECT = 16 --checks if indirectitemcooldown is 0
local XIF_COLPATCH2PLAYER = 32 --map hud patch colour to player prefcolor
local XIF_ICONFORAMT = 64 --item icon and dropped item frame changes depending on the item amount (animation frames become amount frames)

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

local betweenSlotsRollTime = TICRATE/5
local betweenSlotsHudSpace = 24

local dSlotAmount = CV_RegisterVar({
    name = "multislot_amount",
    defaultvalue = "1",
    flags = CV_NETVAR,
    possiblevalue = CV_Unsigned
})

local bEggSlotDelete = CV_RegisterVar({
    name = "multislot_eggbox",
    defaultvalue = "yes",
    flags = CV_NETVAR,
    possiblevalue = CV_YesNo
})

local bLongerPowerCooldown = CV_RegisterVar({
    name = "multislot_powercooldown",
    defaultvalue = "yes",
    flags = CV_NETVAR,
    possiblevalue = CV_YesNo
})

local function ClassPlayer()
    return {
        slots = {},
        extraSlotsRouletteTime = {},
        extraSlotsStartFinishRoll = {},
        extraSlotsNum = dSlotAmount.value,
        shiftdelay = false
    }
end

local function ClassItem(item, amount, flashTime, flashType)
    return {
        item, amount, flashTime, flashType
    }
end

local function isMainSlotFree(p)
    local kartstuff = p.kartstuff
    if not p.xItemData then return false end
	if (p.xItemData.xItem_roulette > 0 or p.xItemData.xItem_itemSlotLocked
            or kartstuff[k_stealingtimer] > 0 or kartstuff[k_stolentimer] > 0 or kartstuff[k_growshrinktimer] > 0 or kartstuff[k_rocketsneakertimer] > 0
            or kartstuff[k_eggmanexplode] > 0 or kartstuff[k_itemtype] or kartstuff[k_itemamount]) then
        return false
    end
    return true
end

function MultiSlotsExt.preplayerthink(p, cmd)
    if not p.xItem_MultiSlots then
        p.xItem_MultiSlots = ClassPlayer()
    end
    if leveltime == 0 then
        p.xItem_MultiSlots = ClassPlayer()
    end

    local kartstuff = p.kartstuff
    local pdat = p.xItem_MultiSlots
    for i = 1, pdat.extraSlotsNum do
        if (not pdat.slots[i]) and pdat.extraSlotsRouletteTime[i] then
            if pdat.extraSlotsStartFinishRoll[i] then
                pdat.extraSlotsRouletteTime[i] = $-1
            end
            if pdat.extraSlotsRouletteTime[i] == 0 then
                --set item here
                local useodds = pdat.extraSlotsStartFinishRoll[i][1]
                local mashed = pdat.extraSlotsStartFinishRoll[i][2]
                local spbrush = pdat.extraSlotsStartFinishRoll[i][3]
                local type = pdat.extraSlotsStartFinishRoll[i][4]

                pdat.extraSlotsStartFinishRoll[i] = nil
                
                if type == 2 and bEggSlotDelete.value then
                    pdat.slots[i] = nil
                    S_StartSound(nil, sfx_itrolm, p)
                elseif (xItemLib.toggles.debugItem ~= 0 and not modeattacking) then
                    local di = min(xItemLib.toggles.debugItem, libfunc.countItems())
                    local it, amt = libfunc.getItemResult(p, di, false, true)
                    amt = xItemLib.cvars.dItemDebugAmt.value
                    pdat.slots[i] = ClassItem(it, amt, TICRATE/2, 2)
                    S_StartSound(nil, sfx_dbgsal, p)
                else
                    --not debugitem
                    local spawnchance = {}
                    local totalspawnchance = 0
                    local blinkMode = ((kartstuff[k_roulettetype] == 1) and 2 or (mashed and 1 or 0))

                    for j = 1, libfunc.countItems() do
                        local o = libfunc.getOdds(useodds, j, mashed, spbrush, p)
                        if o > 0 then
                            totalspawnchance = $ + o
                        end
                        spawnchance[j] = totalspawnchance
                    end

                    -- Award the player whatever power is rolled
                    if (totalspawnchance > 0) then
                        local spawnidx = P_RandomKey(totalspawnchance)
                        for j = 1, libfunc.countItems() do
                            if spawnchance[j] > spawnidx then 
                                local it, amt = libfunc.getItemResult(p, j, true, true)
                                pdat.slots[i] = ClassItem(it, amt, TICRATE/2, blinkMode)
                                break 
                            end
                        end
                        spawnidx = nil
                    else
                        pdat.slots[i] = ClassItem(1, 1, TICRATE/2, blinkMode)
                    end

                    S_StartSound(nil, mashed and sfx_itrolm or sfx_itrolf, p)
                end
            end
        end
    end
end

local itdat
local function isPowerItem(it)
    itdat = libfunc.getItemDataById(it)
    return itdat.flags and (itdat.flags & XIF_POWERITEM == XIF_POWERITEM)
end

function MultiSlotsExt.postplayerthink(p, cmd)
    if p.xItem_MultiSlots then
        local pdat = p.xItem_MultiSlots
        local kartstuff = p.kartstuff
        for i = 1, pdat.extraSlotsNum do
            --shift items over
            if pdat.slots[i] then
                -- timers for item flashes
                if (pdat.slots[i][3]) then
                    pdat.slots[i][3] = $-1
                else
                    pdat.slots[i][3] = 0
                    pdat.slots[i][4] = 0
                end

                if (pdat.slots[i][1]) and (pdat.slots[i][2]) and i == 1 and isMainSlotFree(p) and not pdat.shiftdelay then
                    --delay for shifting
                    pdat.shiftdelay = true
                elseif (pdat.slots[i][1]) and (pdat.slots[i][2]) and i == 1 and isMainSlotFree(p) and pdat.shiftdelay then
                    pdat.shiftdelay = false
                    --give the item in next extra slot
                    kartstuff[k_itemtype] = pdat.slots[i][1]
                    kartstuff[k_itemamount] = pdat.slots[i][2]

                    --run item getfunc
                    local getitem = kartstuff[k_itemtype]
                    local it = libfunc.getItemDataById(getitem)
                    if it and it.getfunc then
                        local status, err = pcall(it.getfunc, p, getitem)
                        if not status then
                            error(err, 2)
                        end
                        --crossmod "hooks"
                        for i = 1, #xItemLib.xItemModNamespaces do
                            local fn = libfunc.getXItemModValue(i, getitem, "getfunc")
                            if fn == nil or (not type(fn) == "function") then continue end
                            local status, err = pcall(fn, p, getitem)
                            if not status then
                                error(err, 2)
                            end
                        end
                    end

                    --clear last slot
                    pdat.slots[i] = nil

                    --egg weird
                    if not kartstuff[k_eggmanheld] then
                        --set item cooldown
                        if bLongerPowerCooldown.value and isPowerItem(kartstuff[k_itemtype]) then
                            libfunc.xItem_setPlayerItemCooldown(p, TICRATE, false)
                        else
                            libfunc.xItem_setPlayerItemCooldown(p, TICRATE/3, false)
                        end
                    end
                end
            end
            if (not pdat.slots[i]) or (pdat.slots[i][1] == 0) or (pdat.slots[i][2] == 0) then
                --shift items in the extra slots
                pdat.slots[i] = pdat.slots[i + 1] or nil
                if pdat.slots[i + 1] then pdat.slots[i + 1] = nil end
            end
        end
    end
end

function MultiSlotsExt.startitemroll(p, cmd)
    if p.xItem_MultiSlots then
        local pdat = p.xItem_MultiSlots
        for i = 1, pdat.extraSlotsNum do
            if (not pdat.slots[i]) or not (pdat.slots[i][1] or pdat.slots[i][2]) then
                pdat.extraSlotsRouletteTime[i] = betweenSlotsRollTime*i
                pdat.extraSlotsStartFinishRoll[i] = nil
            end
        end
    end
end

function MultiSlotsExt.enditemroll(p, useodds, mashed, spbrush)
    if p.xItem_MultiSlots then
        local pdat = p.xItem_MultiSlots
        for i = 1, pdat.extraSlotsNum do
            if pdat.extraSlotsRouletteTime[i] then
                pdat.extraSlotsStartFinishRoll[i] = {useodds, mashed, spbrush, p.kartstuff[k_roulettetype]}
            end
        end
    end
end

function MultiSlotsExt.hudoverride(v, p, c)
    local sx, sy, fflags, flip = libfunc.hudFindFlags(v, p, c)
    local itemBg = v.cachePatch("K_ISBG")
    local itemBgEmpty = v.cachePatch("K_ISBGD")
    local pdat = p.xItem_MultiSlots
    if splitscreen > 1 then
        sx = $ + betweenSlotsHudSpace*(flip and -1 or 1)
    else
        sx = $ + 50
    end

    for i = 0, pdat.extraSlotsNum - 1 do
        local patch = nil
        local px = sx + betweenSlotsHudSpace*(flip and -i or i)
        local idx = 0
        if iflags and (iflags & XIF_ICONFORAMT) then 
            idx = kartstuff[k_itemamount]
        else
            idx = leveltime
        end
        --print each item box and patch if available
        if pdat.slots[i+1] and pdat.slots[i+1][1] then
            local it = pdat.slots[i+1][1]
            local amt = pdat.slots[i+1][2]
            local blinkTime = pdat.slots[i+1][3]
            local blinkType = pdat.slots[i+1][4]
            itdat = libfunc.getItemDataById(it)

            local colour = v.getColormap(TC_DEFAULT, SKINCOLOR_NONE)
            if blinkTime and leveltime%2 == 1 then
                local colormode = TC_BLINK
                local localcolor = SKINCOLOR_WHITE
                if blinkType == 2 then
                    localcolor = 1 + (leveltime % (MAXSKINCOLORS-1))
                elseif blinkType == 1 then
                    localcolor = SKINCOLOR_RED
                end
                colour = v.getColormap(colormode, localcolor)
            elseif iflags and (iflags & XIF_COLPATCH2PLAYER == XIF_COLPATCH2PLAYER) then 
                colour = v.getColormap(TC_DEFAULT, p.skincolor)
            end
            
            patch = itdat.getItemPatchSingle(true, idx)
            
            --draw filled box            
            v.draw(px, sy, itemBg, V_HUDTRANS|fflags)
            v.draw(px, sy, v.cachePatch(patch), V_HUDTRANS|fflags, colour)
            --draw amount
            if amt > 1 then
                v.drawString(px+(flip and 2 or 24), sy+31, "x" + amt, V_ALLOWLOWERCASE|V_HUDTRANS|fflags)
            end

        elseif pdat.extraSlotsRouletteTime[i+1] then
            local av
            if xItemLib.localAvailableItems and #(xItemLib.localAvailableItems[p.splitscreenindex + 1]) then
                av = xItemLib.localAvailableItems[p.splitscreenindex + 1]
            end
            local colormode = TC_RAINBOW
            local localcolor = p.skincolor or SKINCOLOR_GREY
            local colour = v.getColormap(colormode, localcolor)
            --roulette animation
            if av and (table.maxn(av) > 0) then
                itdat = libfunc.getItemDataById(av[((leveltime/3 + (i+1)*2) % table.maxn(av)) + 1])
                patch = itdat.getItemPatchSingle(true, idx)
            else
                itdat = libfunc.getItemDataByName("KITEM_SNEAKER")
                patch = itdat.getItemPatchSingle(true, idx)
            end

            v.draw(px, sy, itemBg, V_HUDTRANS|fflags)
            v.draw(px, sy, v.cachePatch(patch), V_HUDTRANS|fflags, colour)

        elseif p.kartstuff[k_itemtype] then
            --draw empty box
            v.draw(px, sy, itemBgEmpty, V_HUDTRANS|fflags)
        end
    end
end

xItemLib.func.addXItemMod("XITEM_MULTISLOTS", "xItemLib MultiSlot", MultiSlotsExt)