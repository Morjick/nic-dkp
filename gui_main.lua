local massReason, singleReason = "", "" -- Храним текст комментариев

function CreateMainTabFrame(f)
    local t1 = CreateFrame("Frame", "NicDkpMainTabFrame", f) t1:SetSize(360, 340) t1:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -65)
    local drop = MakeBtn(t1, 105, 20, 10, -5, "Вся гильдия", nil)
    local menu = {
        { text = "Вся гильдия", func = function() NicDkpMode = "ALL" drop:SetText("Вся гильдия") UpdateMainTabUI() end },
        { text = "Только рейд", func = function() NicDkpMode = "RAID" drop:SetText("Только рейд") UpdateMainTabUI() end },
        { text = "Только группа", func = function() NicDkpMode = "PARTY" drop:SetText("Только группа") UpdateMainTabUI() end },
    }
    local mF = CreateFrame("Frame", "NicDkpMenuFrame", t1, "UIDropDownMenuTemplate")
    drop:SetScript("OnClick", function() EasyMenu(menu, mF, "cursor", 0, 0, "MENU") end)

    MakeBtn(t1, 75, 20, 120, -5, "Обновить", function() if IsInGuild() then GuildRoster() end UpdateMainTabUI() end)
    MakeBtn(t1, 80, 20, 250, -42, "Цвета", function() ShowNicDkpPalette() end)
    
    local sLbl = t1:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall") sLbl:SetPoint("TOPLEFT", t1, "TOPLEFT", 15, -30) sLbl:SetText("Поиск по нику:")
    local searchBox = MakeEdit(t1, 90, 20, 15, -42, "", function(self) NicDkpSrc = self:GetText() UpdateMainTabUI() end)

    local minLbl = t1:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall") minLbl:SetPoint("TOPLEFT", t1, "TOPLEFT", 120, -30) minLbl:SetText("EP от:")
    local minEdit = MakeEdit(t1, 50, 20, 120, -42, "0", function(self) NicDkpMin = tonumber(self:GetText()) or 0 UpdateMainTabUI() end)

    local maxLbl = t1:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall") maxLbl:SetPoint("TOPLEFT", t1, "TOPLEFT", 185, -30) maxLbl:SetText("до:")
    local maxEdit = MakeEdit(t1, 65, 20, 185, -42, "999999", function(self) NicDkpMax = tonumber(self:GetText()) or 999999 UpdateMainTabUI() end)

    local sf = CreateFrame("ScrollFrame", "NicDkpMainScrollFrame", t1, "UIPanelScrollFrameTemplate") sf:SetSize(310, 140) sf:SetPoint("TOPLEFT", t1, "TOPLEFT", 15, -68)
    CreateFrame("Frame", "NicDkpMainScrollContent", sf):SetParent(sf) sf:SetScrollChild(NicDkpMainScrollContent)

    -- ПОЛЕ ВВОДА ДЛЯ МАССОВОГО КОММЕНТАРИЯ
    local rLbl = t1:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall") rLbl:SetPoint("TOPLEFT", t1, "TOPLEFT", 15, -215) rLbl:SetText("Комментарий к массовому действию:")
    local rEdit = MakeEdit(t1, 310, 22, 15, -227, "", function(self) massReason = self:GetText() end)

    local h = t1:CreateFontString(nil, "ARTWORK", "GameFontNormal") h:SetPoint("TOPLEFT", t1, "TOPLEFT", 15, -252) h:SetText("Действие с EP (например: 300, 10%, -250, -30%):")
    local commandBox = MakeEdit(t1, 115, 22, 20, -274, "", function(self) NicDkpEPCommand = self:GetText() end, "NicDkpEPCommandEdit")
    commandBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    MakeBtn(t1, 135, 22, 145, -274, "Применить действие", function()
        local command = commandBox:GetText() or ""
        local amountText = command:gsub("%%", "")
        local amount = tonumber(amountText)
        if not amount or amount == 0 then
            print("|cffff4444[NIC-DKP]:|r Введите число: 300, 10%, -250 или -30%.")
            return
        end
        local isPercent = command:find("%%") ~= nil
        local act = amount > 0 and "начисление" or "срез"
        local list = GetFilteredPlayers(NicDkpMode, NicDkpSrc, NicDkpMin, NicDkpMax)
        local reason = massReason ~= "" and massReason or (act == "начисление" and "Массовое начисление" or "Массовый срез")
        for _, player in ipairs(list) do
            MassChangeEP({{name = player.name}}, math.abs(amount), act, isPercent, reason)
        end
        print(string.format("|cffb080ff[NIC-DKP]:|r Применено %s %s к %d игрокам.", command, isPercent and "от EP" or "EP", #list))
        if IsInGuild() then GuildRoster() end
        UpdateMainTabUI()
    end)

    MakeBtn(t1, 140, 22, 170, -310, "Шаблоны EP", function()
        if ShowBossTemplatesWindow then ShowBossTemplatesWindow() end
    end)

    MakeBtn(t1, 140, 22, 20, -310, "Выгрузить базу в Excel", function()
        local csv = "Игрок;Текущее ЕП\n"
        local list = GetFilteredPlayers(NicDkpMode, NicDkpSrc, NicDkpMin, NicDkpMax)
        for _, p in ipairs(list) do csv = csv .. string.format("%s;%d\n", p.name, p.ep) end
        if NicDkpExportFrame then NicDkpExportFrame:Hide() end
        local ef = CreateFrame("Frame", "NicDkpExportFrame", UIParent) ef:SetSize(340, 220) ef:SetPoint("CENTER") ef:EnableMouse(true) ef:SetFrameStrata("DIALOG")
        ef:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
        tinsert(UISpecialFrames, "NicDkpExportFrame")
        local title = ef:CreateFontString(nil, "ARTWORK", "GameFontNormal") title:SetPoint("TOPLEFT", ef, "TOPLEFT", 15, -10) title:SetText("Текущий список (Ctrl+A -> Ctrl+C):")
        CreateFrame("Button", nil, ef, "UIPanelCloseButton"):SetPoint("TOPRIGHT", ef, "TOPRIGHT", -2, -2)
        local eb = CreateFrame("EditBox", nil, ef) eb:SetMultiLine(true) eb:SetSize(310, 160) eb:SetPoint("TOPLEFT", ef, "TOPLEFT", 15, -30) eb:SetFontObject("ChatFontNormal") eb:SetText(csv) eb:SetAutoFocus(true) eb:HighlightText()
    end)

    CreateJournalTabFrame(f) CreateAuctionTabFrame(f) CreateSinglePlayerFrame(f)
    SwitchToTab("main")
end

function UpdateMainTabUI()
    local s = NicDkpMainScrollContent if not s then return end
    for _, k in ipairs({s:GetChildren()}) do k:Hide() k:SetParent(nil) end
    local list = GetFilteredPlayers(NicDkpMode, NicDkpSrc, NicDkpMin, NicDkpMax)
    if NicDkpCountText then NicDkpCountText:Show() NicDkpCountText:SetText(string.format("Отображено: %d чел.", #list)) end
    local y = 0
    for _, p in ipairs(list) do
        local r = CreateFrame("Button", nil, s) r:SetSize(290, 20) r:SetPoint("TOPLEFT", s, "TOPLEFT", 0, y)
        local t = r:CreateTexture() t:SetAllPoints() t:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight") t:SetBlendMode("ADD") t:Hide()
        r:SetScript("OnEnter", function() t:Show() end) r:SetScript("OnLeave", function() t:Hide() end)
        r:SetScript("OnClick", function() NicDkpSelP = p.name NicDkpSingleFrame:Show() NicDkpSingleTitle:SetText(GetClassColoredName(p.name)) end)
        local n = r:CreateFontString(nil, "ARTWORK", "GameFontNormal") n:SetPoint("LEFT", r, "LEFT", 5, 0) n:SetText(GetClassColoredName(p.name))
        local e = r:CreateFontString(nil, "ARTWORK", "GameFontHighlight") e:SetPoint("RIGHT", r, "RIGHT", -5, 0) e:SetText("EP: " .. p.ep)
        y = y - 20
    end
    s:SetSize(290, math.abs(y))
end

function CreateSinglePlayerFrame(p)
    local sf = CreateFrame("Frame", "NicDkpSingleFrame", p) sf:SetSize(160, 190) sf:SetPoint("LEFT", p, "RIGHT", 5, 0) sf:Hide()
    sf:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    tinsert(UISpecialFrames, "NicDkpSingleFrame")
    local t = sf:CreateFontString("NicDkpSingleTitle", "ARTWORK", "GameFontNormal") t:SetPoint("TOP", sf, "TOP", 0, -10) CreateFrame("Button", nil, sf, "UIPanelCloseButton"):SetPoint("TOPRIGHT", sf, "TOPRIGHT", -2, -2)

    local sCmLbl = sf:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall") sCmLbl:SetPoint("TOPLEFT", sf, "TOPLEFT", 15, -30) sCmLbl:SetText("Комментарий:")
    local sCmEdit = MakeEdit(sf, 130, 20, 15, -42, "", function(self) singleReason = self:GetText() end)

    local lbl = sf:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall") lbl:SetPoint("TOPLEFT", sf, "TOPLEFT", 15, -70) lbl:SetText("Значение:")
    local ed = MakeEdit(sf, 50, 22, 20, -82, "10", nil)
    
    local delayFrame = CreateFrame("Frame")
    local function SafeRefresh()
        local timeElapsed = 0
        delayFrame:SetScript("OnUpdate", function(self, elapsed)
            timeElapsed = timeElapsed + elapsed
            if timeElapsed >= 0.3 then
                self:SetScript("OnUpdate", nil)
                if IsInGuild() then GuildRoster() end
                UpdateMainTabUI()
            end
        end)
    end

    MakeBtn(sf, 125, 22, 15, -115, "Начислить", function() 
        if NicDkpSelP then 
            local v = tonumber(ed:GetText()) or 0 
            MassChangeEP({{name = NicDkpSelP}}, v, "начисление", false, singleReason) 
            SafeRefresh()
        end 
    end)
    
    MakeBtn(sf, 125, 22, 15, -140, "Срезать", function() 
        if NicDkpSelP then 
            local v = tonumber(ed:GetText()) or 0 
            MassChangeEP({{name = NicDkpSelP}}, v, "срез", false, singleReason) 
            SafeRefresh()
        end 
    end)
end
