if not SirusEPGP_Journal then SirusEPGP_Journal = {} end
if not SirusEPGP_ClassCache then SirusEPGP_ClassCache = {} end

function GetGuildIndexByName(targetName)
    if not IsInGuild() then return nil end
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name and targetName and name:match("^([^%-]+)") == targetName:match("^([^%-]+)") then return i end
    end
    return nil
end

function GetPlayerEP(name)
    if not name or name == "" then return 0 end

    local numMembers = GetNumGuildMembers()
    local targetNote = ""
    local targetRank = ""

    for i = 1, numMembers do
        local gName, rank, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
        if gName and gName:lower() == name:lower() then
            targetNote = officerNote or ""
            targetRank = rank or ""
            break
        end
    end

    targetNote = targetNote:gsub("^%s*(.-)%s*$", "%1")

    if targetNote ~= "" and not tonumber(targetNote) then
        local mainName = targetNote
        if mainName:lower() ~= name:lower() then
            return GetPlayerEP(mainName)
        end
    end

    local epValue = tonumber(targetNote) or 0
    return epValue
end

local NicDkpClassTokens = {
    WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true,
    DEATHKNIGHT=true, SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true,
}
local NicDkpLocalizedClasses = {
    ["Воин"]="WARRIOR", ["Воительница"]="WARRIOR",
    ["Паладин"]="PALADIN", ["Паладинка"]="PALADIN",
    ["Охотник"]="HUNTER", ["Охотница"]="HUNTER",
    ["Разбойник"]="ROGUE", ["Разбойница"]="ROGUE",
    ["Жрец"]="PRIEST", ["Жрица"]="PRIEST",
    ["Рыцарь смерти"]="DEATHKNIGHT",
    ["Шаман"]="SHAMAN", ["Шаманка"]="SHAMAN",
    ["Маг"]="MAGE", ["Магичка"]="MAGE",
    ["Чернокнижник"]="WARLOCK", ["Чернокнижница"]="WARLOCK",
    ["Друид"]="DRUID", ["Друидка"]="DRUID",
}
local function NicDkpResolveClass(className)
    if type(className)~="string" then return nil end
    local token=className:upper()
    if NicDkpClassTokens[token] then return token end
    return NicDkpLocalizedClasses[className]
end
function GetClassColoredName(playerName)
    if not playerName then return "|cffffffffНеизвестно|r" end
    local shortName=playerName:match("^[^%-]+") or playerName
    local classFileName=NicDkpResolveClass(SirusEPGP_ClassCache[playerName])
        or NicDkpResolveClass(SirusEPGP_ClassCache[shortName])
    if not classFileName then
        local idx=GetGuildIndexByName(playerName)
        if idx then
            local _,_,_,_,localizedClass,_,_,_,_,classToken=GetGuildRosterInfo(idx)
            classFileName=NicDkpResolveClass(classToken) or NicDkpResolveClass(localizedClass)
        end
    end
    if not classFileName and UnitExists(shortName) then
        local _,token=UnitClass(shortName)
        classFileName=NicDkpResolveClass(token)
    end
    if classFileName then
        SirusEPGP_ClassCache[playerName]=classFileName
        SirusEPGP_ClassCache[shortName]=classFileName
        local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName]
        if color then
            return string.format("|cff%02x%02x%02x%s|r",color.r*255,color.g*255,color.b*255,playerName)
        end
    end
    return "|cffffee00"..playerName.."|r"
end

function GetFilteredPlayers(mode, searchName, minEP, maxEP)
    local players = {}
    if IsInGuild() then 
        SetGuildRosterShowOffline(true)
        GuildRoster() 
        for i=1,GetNumGuildMembers() do
            local name,_,_,_,localizedClass,_,_,_,_,classToken=GetGuildRosterInfo(i)
            if name then
                local token=NicDkpResolveClass(classToken) or NicDkpResolveClass(localizedClass)
                if token then
                    SirusEPGP_ClassCache[name]=token
                    SirusEPGP_ClassCache[name:match("^[^%-]+") or name]=token
                end
            end
        end
    end
    local search = (searchName and searchName ~= "") and searchName:lower() or nil
    local numMin = tonumber(minEP) or 0
    local numMax = tonumber(maxEP) or 999999
    local rawList = {}
    local myName = UnitName("player")
    if mode == "RAID" and UnitInRaid("player") then
        for i = 1, 40 do local name = GetRaidRosterInfo(i) if name then tinsert(rawList, name) end end
    elseif mode == "PARTY" and UnitInParty("player") then
        for i = 1, 4 do local name = UnitName("party"..i) if name then tinsert(rawList, name) end end
        if myName then tinsert(rawList, myName) end
    else
        if mode ~= "ALL" then if myName then tinsert(rawList, myName) end
        elseif IsInGuild() then
            for i = 1, GetNumGuildMembers() do local name = GetGuildRosterInfo(i) if name then tinsert(rawList, name) end end
        else if myName then tinsert(rawList, myName) end end
    end
    for _, name in ipairs(rawList) do
        local ep = GetPlayerEP(name)
        local matchSearch = true
        if search and not name:lower():match(search) then matchSearch = false end
        if matchSearch and ep >= numMin and ep <= numMax then tinsert(players, {name = name, ep = ep}) end
    end
    table.sort(players, function(a, b) if a.ep == b.ep then return a.name < b.name else return a.ep > b.ep end end)
    return players
end

function LogAction(pName, val, act, reason)
    local note = act
    if reason and reason ~= "" then note = act .. " (" .. reason .. ")" end
    table.insert(SirusEPGP_Journal, 1, {date = date("%m-%d %H:%M"), officer = UnitName("player") or "Офицер", action = note, player = pName, amount = val})
end

local function GetMainOrSelfIndex(name)
    if not name or name == "" then return nil end
    local numMembers = GetNumGuildMembers()
    local targetNote = ""
    local myIndex = nil

    for i = 1, numMembers do
        local gName, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)
        if gName and gName:lower() == name:lower() then
            targetNote = officerNote or ""
            myIndex = i
            break
        end
    end

    targetNote = targetNote:gsub("^%s*(.-)%s*$", "%1")

    if targetNote ~= "" and not tonumber(targetNote) then
        local mainName = targetNote
        if mainName:lower() ~= name:lower() then
            for i = 1, numMembers do
                local gName = GetGuildRosterInfo(i)
                if gName and gName:lower() == mainName:lower() then
                    return i -- Возвращаем индекс мэйна!
                end
            end
        end
    end

    return myIndex
end

function MassChangeEP(pList, val, act, isPct, reason)
    if not IsInGuild() then return end
    
    local defaultReason = (act == "начисление") and "Поощрение" or "Снижение"
    local txtReason = (reason and reason ~= "") and reason or defaultReason
    local sign = (act == "начисление") and "+" or "-"

    if #pList > 3 then
        local displayType = isPct and "%" or "EP"
        SendChatMessage(string.format("[NIC-DKP]: Массовый срез/начисление для %d чел. Размер: %s%d %s. Причина: %s", #pList, sign, val, displayType, txtReason), "GUILD")
    end

    for _, p in ipairs(pList) do
        local writeIdx = GetMainOrSelfIndex(p.name)

        if writeIdx then
            local cur = GetPlayerEP(p.name)
            local changeAmount = val
            if isPct then changeAmount = math.floor(cur * (val / 100)) end
            if act == "начисление" and not isPct then changeAmount = math.floor(changeAmount * (1 + math.max(0, NicDkpModifier(p.name)) / 100) + 0.5) end
            
            local new = (act == "начисление") and (cur + changeAmount) or math.max(0, cur - changeAmount)

            GuildRosterSetOfficerNote(writeIdx, tostring(math.floor(new)))

            LogAction(p.name, changeAmount, act == "начисление" and "Начисление" or "Срез", txtReason)

            if #pList <= 3 then
                SendChatMessage(string.format("[NIC-DKP]: %s получил(a) %s%d EP. Причина: %s", p.name, sign, changeAmount, txtReason), "GUILD")
            end
        end
    end
    GuildRoster()
end


-- =========================================================================
-- ТАБЛИЦА РЕЙДОВ И СИСТЕМА ЗАВЕРШЕНИЯ РТ
-- =========================================================================
NicDkpRaidPrices = {
    { id = "karag", name = "Каражан (гер)", cost = 1500 },
    { id = "lgg", name = "Логово Груула (гер)", cost = 2000 },
    { id = "lmg", name = "Логово Мактеридона (гер)", cost = 1000 },
    { id = "ivk", name = "ИВК", cost = 1200 },
    { id = "ivkfull", name = "ИВК (50/50)", cost = 1700 },
    { id = "lg", name = "Логово Груула (об)", cost = 1000 },
    { id = "lm", name = "Логово Мактеридона (об)", cost = 500 },
}
NicDkpSelectedRaids = {}

function FinishRaidTurnout()
    local totalCost = 0
    local raidNames = ""
    for _, raid in ipairs(NicDkpRaidPrices) do 
        if NicDkpSelectedRaids[raid.id] then 
            totalCost = totalCost + raid.cost 
            if raidNames == "" then raidNames = raid.name else raidNames = raidNames .. " + " .. raid.name end
        end 
    end
    if totalCost == 0 then return end
    local mode = "ALL"
    if UnitInRaid("player") then mode = "RAID" elseif UnitInParty("player") then mode = "PARTY" end
    local list = GetFilteredPlayers(mode, "", 0, 999999)

    SendChatMessage(string.format("[NIC-DKP]: Рейдовое время завершено! Все участники состава (%d чел.) получают по +%d EP за (%s)", #list, totalCost, raidNames), "GUILD")
    
    MassChangeEP(list, totalCost, "начисление", false, "Завершение РТ: " .. raidNames)
    NicDkpSelectedRaids = {}
end

function IsPlayerOfficer()
    if not IsInGuild() then return false end
    local idx = GetGuildIndexByName(UnitName("player"))
    if idx then local _, _, rank = GetGuildRosterInfo(idx) if rank and rank <= 2 then return true end end
    return false
end

function GetNextMinimumBid(currentBid, basePrice)
    if not currentBid or currentBid == 0 then
        return tonumber(basePrice) or 100
    end
    
    local step = 100
    if currentBid >= 5000 then
        step = 1000
    elseif currentBid >= 2000 then
        step = 500
    elseif currentBid >= 1000 then
        step = 250
    end
    
    return currentBid + step
end

function NicDkpModifier(name) return 0 end
function NicDkpActualCost(name,bid,offspec) return offspec and math.floor(bid*0.5) or bid end
