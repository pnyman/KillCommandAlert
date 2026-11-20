-- Kill Command Alert for WoW 1.12 (Turtle WoW / OctoWoW)
-- Lua 5.0 compatible.

local SPELL_ID   = 41827
local SPELL_NAME = "Kill Command"
local FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Built-in sounds. Entries containing "\\" are files (PlaySoundFile), others are sound names (PlaySound).
local SOUNDS = {
    "Sound\\Interface\\RaidWarning.wav",
    "Sound\\Interface\\MapPing.wav",
    "Sound\\Interface\\LevelUp.wav",
    "Sound\\Spells\\ShaysBell.wav",
    "Sound\\Spells\\PVPFlagTaken.wav",
    "Sound\\Doodad\\BellTollAlliance.wav",
    "Sound\\Doodad\\BellTollHorde.wav",
    "Sound\\Interface\\iTellMessage.wav",
    "igQuestListComplete",
    "igPlayerInvite",
    "igQuestFailed",
    "TellMessage",
    "AuctionWindowOpen",
    "LEVELUPSOUND",
}

local defaults = {
    size = 72, sound = true, locked = true, mode = "both",
    soundFile = "Sound\\Interface\\RaidWarning.wav",
    point = "CENTER", relPoint = "CENTER", x = 0, y = 120,
}

local db
local showing = false
local testUntil = 0
local barSlot = nil
local spellIcon = nil

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000KillCommandAlert:|r " .. msg)
end

local function PlayAny(snd)
    if not snd or snd == "" then return end
    if string.find(snd, "\\") or string.find(snd, "%.wav$") or string.find(snd, "%.mp3$") then
        PlaySoundFile(snd)
    else
        PlaySound(snd)
    end
end

-- Hidden tooltip used to read buff/action names
local tip = CreateFrame("GameTooltip", "KCA_ScanTip", nil, "GameTooltipTemplate")
local function TipName()
    local fs = getglobal("KCA_ScanTipTextLeft1")
    return fs and fs:GetText()
end

---------------------------------------------------------------------------
-- Icon frame
---------------------------------------------------------------------------
local f = CreateFrame("Frame", "KillCommandAlertFrame", UIParent)
f:SetFrameStrata("HIGH")
f:SetClampedToScreen(true)
f:SetMovable(true)
f:Hide()

local icon = f:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(f)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local glow = f:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetBlendMode("ADD")
glow:SetVertexColor(1, 0.3, 0.1)

local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
label:SetPoint("TOP", f, "BOTTOM", 0, -4)
label:SetText(SPELL_NAME .. "!")

f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", function() this:StartMoving() end)
f:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local p, _, rp, x, y = this:GetPoint()
    db.point, db.relPoint, db.x, db.y = p, rp, x, y
end)

local function ApplySettings()
    f:ClearAllPoints()
    f:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
    f:SetWidth(db.size)
    f:SetHeight(db.size)
    glow:SetWidth(db.size * 1.8)
    glow:SetHeight(db.size * 1.8)
    glow:SetPoint("CENTER", f, "CENTER", 0, 0)
    f:EnableMouse(not db.locked)
end

---------------------------------------------------------------------------
-- Find the icon in the spellbook
---------------------------------------------------------------------------
local function FindSpellIcon()
    local i = 1
    while true do
        local name = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == SPELL_NAME then
            spellIcon = GetSpellTexture(i, BOOKTYPE_SPELL)
            return
        end
        i = i + 1
    end
end

---------------------------------------------------------------------------
-- Method 1: buff on the player (spell ID via SuperWoW, otherwise by name)
---------------------------------------------------------------------------
local function CheckBuff()
    for i = 1, 32 do
        local tex, _, sid = UnitBuff("player", i)
        if not tex then break end
        if sid and sid == SPELL_ID then return tex end
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
        tip:ClearLines()
        tip:SetUnitBuff("player", i)
        if TipName() == SPELL_NAME then return tex end
    end
    return nil
end

---------------------------------------------------------------------------
-- Method 2: the ability becomes usable on the action bar (reactive ability)
---------------------------------------------------------------------------
local function FindBarSlot()
    barSlot = nil
    for slot = 1, 120 do
        if HasAction(slot) then
            tip:SetOwner(WorldFrame, "ANCHOR_NONE")
            tip:ClearLines()
            tip:SetAction(slot)
            if TipName() == SPELL_NAME then
                barSlot = slot
                return
            end
        end
    end
end

local function CheckBar()
    if not barSlot then return nil end
    local usable, noMana = IsUsableAction(barSlot)
    if not usable and not noMana then return nil end
    local start, dur = GetActionCooldown(barSlot)
    if start > 0 and dur > 1.5 then return nil end -- on a real cooldown (not GCD)
    return GetActionTexture(barSlot)
end

---------------------------------------------------------------------------
-- Show/hide
---------------------------------------------------------------------------
local function Update()
    local tex
    if GetTime() < testUntil then
        tex = spellIcon or FALLBACK_ICON
    else
        if db.mode == "buff" or db.mode == "both" then tex = CheckBuff() end
        if not tex and (db.mode == "bar" or db.mode == "both") then tex = CheckBar() end
    end

    if tex then
        icon:SetTexture(spellIcon or tex)
        if not showing then
            showing = true
            f:Show()
            if db.sound then PlayAny(db.soundFile) end
        end
    elseif showing and db.locked then
        showing = false
        f:Hide()
    end
end

-- Pulsing glow + periodic check
local elapsedTotal, throttle = 0, 0
f:SetScript("OnUpdate", function()
    elapsedTotal = elapsedTotal + arg1
    local a = 0.55 + 0.45 * math.sin(elapsedTotal * 6)
    glow:SetAlpha(a)
end)

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function()
    throttle = throttle + arg1
    if throttle >= 0.1 then
        throttle = 0
        if db then Update() end
    end
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("VARIABLES_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
ev:RegisterEvent("SPELLS_CHANGED")
ev:RegisterEvent("LEARNED_SPELL_IN_TAB")
ev:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if type(KillCommandAlertDB) ~= "table" then KillCommandAlertDB = {} end
        db = KillCommandAlertDB
        for k, v in pairs(defaults) do
            if db[k] == nil then db[k] = v end
        end
        ApplySettings()
    elseif event == "PLAYER_ENTERING_WORLD" then
        FindSpellIcon()
        FindBarSlot()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        FindBarSlot()
    else
        FindSpellIcon()
    end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_KILLCOMMANDALERT1 = "/kca"
SlashCmdList["KILLCOMMANDALERT"] = function(msg)
    local _, _, cmd, rest = string.find(msg or "", "^(%S*)%s*(.-)$")
    cmd = string.lower(cmd or "")

    if cmd == "test" then
        testUntil = GetTime() + 4
        showing = false
        Update()
        Print("Showing test icon for 4 seconds.")
    elseif cmd == "unlock" then
        db.locked = false
        ApplySettings()
        testUntil = GetTime() + 99999
        Update()
        Print("Unlocked - drag the icon where you want it. Type /kca lock when done.")
    elseif cmd == "lock" then
        db.locked = true
        testUntil = 0
        ApplySettings()
        showing = false
        f:Hide()
        Print("Locked.")
    elseif cmd == "size" then
        local n = tonumber(rest)
        if n and n >= 16 and n <= 300 then
            db.size = n
            ApplySettings()
            Print("Size: " .. n)
        else
            Print("Usage: /kca size 16-300")
        end
    elseif cmd == "sounds" then
        Print("Built-in sounds (preview with /kca play <number>):")
        for i = 1, table.getn(SOUNDS) do
            local mark = (SOUNDS[i] == db.soundFile) and " |cff00ff00<- selected|r" or ""
            Print(i .. ". " .. SOUNDS[i] .. mark)
        end
    elseif cmd == "play" then
        local n = tonumber(rest)
        local snd = (n and SOUNDS[n]) or (rest ~= "" and rest) or db.soundFile
        Print("Playing: " .. snd)
        PlayAny(snd)
    elseif cmd == "sound" then
        local n = tonumber(rest)
        local lower = string.lower(rest or "")
        if rest == "" then
            db.sound = not db.sound
            Print("Sound: " .. (db.sound and "on" or "off"))
        elseif lower == "on" then
            db.sound = true
            Print("Sound: on")
        elseif lower == "off" then
            db.sound = false
            Print("Sound: off")
        elseif n then
            if SOUNDS[n] then
                db.soundFile = SOUNDS[n]
                db.sound = true
                Print("Sound selected: " .. db.soundFile)
                PlayAny(db.soundFile)
            else
                Print("No sound with number " .. n .. ". See /kca sounds")
            end
        else
            db.soundFile = rest
            db.sound = true
            Print("Sound selected: " .. db.soundFile)
            PlayAny(db.soundFile)
        end
    elseif cmd == "mode" then
        rest = string.lower(rest or "")
        if rest == "buff" or rest == "bar" or rest == "both" then
            db.mode = rest
            Print("Mode: " .. rest)
        else
            Print("Usage: /kca mode buff | bar | both")
        end
    elseif cmd == "reset" then
        for k, v in pairs(defaults) do db[k] = v end
        ApplySettings()
        Print("Settings reset.")
    elseif cmd == "debug" then
        Print("Action bar slot: " .. (barSlot and barSlot or "not found"))
        for i = 1, 32 do
            local tex, _, sid = UnitBuff("player", i)
            if not tex then break end
            tip:SetOwner(WorldFrame, "ANCHOR_NONE")
            tip:ClearLines()
            tip:SetUnitBuff("player", i)
            Print("Buff " .. i .. ": " .. (TipName() or "?") .. (sid and (" (id " .. sid .. ")") or ""))
        end
    else
        Print("Commands:")
        Print("/kca test - show the icon")
        Print("/kca unlock | lock - move the icon")
        Print("/kca size <n> - size in pixels (now " .. db.size .. ")")
        Print("/kca sound - toggle sound on/off (now " .. (db.sound and "on" or "off") .. ")")
        Print("/kca sounds - list built-in sounds")
        Print("/kca play <number or path> - preview a sound")
        Print("/kca sound <number or path> - choose sound (now " .. db.soundFile .. ")")
        Print("/kca mode buff|bar|both - how the proc is detected (now " .. db.mode .. ")")
        Print("/kca debug - list your buffs")
        Print("/kca reset - reset settings")
    end
end
