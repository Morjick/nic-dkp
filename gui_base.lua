NicDkpBasePriceValue = 100

SLASH_NICDKP1, SLASH_NICDKP2 = "/nd", "/dkp"
SlashCmdList["NICDKP"] = function() if NicDkpMainFrame and NicDkpMainFrame:IsShown() then NicDkpMainFrame:Hide() else ShowMainWindow() end end

NicDkpMode, NicDkpVal, NicDkpSelP = "ALL", 10, nil
NicDkpSrc, NicDkpMin, NicDkpMax, NicDkpIsPct = "", 0, 999999, false

function SwitchToTab(tName)
    NicDkpMainTabFrame:Hide() NicDkpJournalTabFrame:Hide() NicDkpAuctionTabFrame:Hide()
    if NicDkpSingleFrame then NicDkpSingleFrame:Hide() end
    if tName == "main" then NicDkpMainTabFrame:Show() UpdateMainTabUI()
    elseif tName == "journal" then NicDkpJournalTabFrame:Show() UpdateJournalTabUI()
    elseif tName == "auction" then NicDkpAuctionTabFrame:Show() UpdateAuctionTabUI() end
end

NicDkpStyledButtons = NicDkpStyledButtons or {}
NicDkpStyle = NicDkpStyle or {}
NicDkpStyle.button = NicDkpStyle.button or { r = 0.20, g = 0.07, b = 0.31 }
NicDkpStyle.border = NicDkpStyle.border or { r = 0, g = 0, b = 0 }

local function ApplyNicDkpButtonColors(b)
    if not b then return end
    local c = NicDkpStyle.button or { r = 0.20, g = 0.07, b = 0.31 }
    local border = NicDkpStyle.border or { r = 0, g = 0, b = 0 }
    if b.__nicNormal then b.__nicNormal:SetVertexColor(c.r, c.g, c.b, 1) end
    if b.__nicPushed then b.__nicPushed:SetVertexColor(c.r * 0.52, c.g * 0.52, c.b * 0.52, 1) end
    if b.__nicHighlight then b.__nicHighlight:SetVertexColor(math.min(1, c.r + 0.28), math.min(1, c.g + 0.28), math.min(1, c.b + 0.28), 0.35) end
    if b.__nicBorder then
        for _, edge in ipairs(b.__nicBorder) do edge:SetVertexColor(border.r, border.g, border.b, 1) end
    end
    local text = b:GetFontString()
    if text then text:SetTextColor(1, 1, 1, 1) end
end

function StyleNicDkpPurpleButton(b)
    if not b then return end
    if not b.__nicNormal then
        local normal = b:CreateTexture(nil, "BACKGROUND")
        normal:SetTexture("Interface\\Buttons\\WHITE8X8")
        normal:SetAllPoints(b)
        b:SetNormalTexture(normal)
        b.__nicNormal = normal

        local pushed = b:CreateTexture(nil, "BACKGROUND")
        pushed:SetTexture("Interface\\Buttons\\WHITE8X8")
        pushed:SetAllPoints(b)
        b:SetPushedTexture(pushed)
        b.__nicPushed = pushed

        local highlight = b:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
        highlight:SetAllPoints(b)
        highlight:SetBlendMode("ADD")
        b:SetHighlightTexture(highlight)
        b.__nicHighlight = highlight

        -- Four crisp 1px edge textures avoid the blurry/missing backdrop border on 3.3.5 clients.
        b.__nicBorder = {}
        local edges = {
            { "TOPLEFT", "TOPRIGHT", 0, -1, nil, 1 },
            { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 0, nil, 1 },
            { "TOPLEFT", "BOTTOMLEFT", 1, 0, 1, nil },
            { "TOPRIGHT", "BOTTOMRIGHT", -1, 0, 1, nil },
        }
        for i, spec in ipairs(edges) do
            local edge = b:CreateTexture(nil, "OVERLAY")
            edge:SetTexture("Interface\\Buttons\\WHITE8X8")
            if i == 1 then edge:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0); edge:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0); edge:SetHeight(1)
            elseif i == 2 then edge:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0); edge:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0); edge:SetHeight(1)
            elseif i == 3 then edge:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0); edge:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 0, 0); edge:SetWidth(1)
            else edge:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0); edge:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0); edge:SetWidth(1) end
            table.insert(b.__nicBorder, edge)
        end
        table.insert(NicDkpStyledButtons, b)
    end
    ApplyNicDkpButtonColors(b)
end

function RefreshNicDkpButtonColors()
    for _, b in ipairs(NicDkpStyledButtons or {}) do
        if b and b.GetObjectType and b:GetObjectType() == "Button" then ApplyNicDkpButtonColors(b) end
    end
end

local function OpenNicDkpColorPicker(kind)
    NicDkpStyle = NicDkpStyle or {}
    local key = kind == "border" and "border" or "button"
    NicDkpStyle[key] = NicDkpStyle[key] or (key == "border" and {r=0,g=0,b=0} or {r=0.20,g=0.07,b=0.31})
    local old = NicDkpStyle[key]
    local function apply(r, g, b)
        NicDkpStyle[key] = { r = r, g = g, b = b }
        RefreshNicDkpButtonColors()
    end
    if not ColorPickerFrame then return end
    ColorPickerFrame.hasOpacity = false
    ColorPickerFrame.func = function() local r,g,b = ColorPickerFrame:GetColorRGB(); apply(r,g,b) end
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.cancelFunc = function(previous)
        if type(previous) == "table" then apply(previous[1] or old.r, previous[2] or old.g, previous[3] or old.b) end
    end
    ColorPickerFrame:SetColorRGB(old.r or 0, old.g or 0, old.b or 0)
    ColorPickerFrame.previousValues = { old.r or 0, old.g or 0, old.b or 0 }
    ColorPickerFrame:Show()
end

function ShowNicDkpPalette()
    if NicDkpPaletteFrame then NicDkpPaletteFrame:Show(); return end
    local f = CreateFrame("Frame", "NicDkpPaletteFrame", UIParent)
    f:SetSize(230, 125); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG"); f:EnableMouse(true)
    f:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    tinsert(UISpecialFrames, "NicDkpPaletteFrame")
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12); title:SetText("Настройка цветов")
    CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    MakeBtn(f, 190, 26, 20, -38, "Цвет кнопок", function() OpenNicDkpColorPicker("button") end)
    MakeBtn(f, 190, 26, 20, -72, "Цвет обводки", function() OpenNicDkpColorPicker("border") end)
end

function MakeBtn(p, w, h, x, y, t, f)
    local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    b:SetSize(w, h) b:SetPoint("TOPLEFT", p, "TOPLEFT", x, y) b:SetText(t) b:SetScript("OnClick", f)
    StyleNicDkpPurpleButton(b)
    return b
end

function MakeEdit(p, w, h, x, y, t, f, name)
    -- Build a plain edit box with an explicit stretched background. InputBoxTemplate's
    -- left/middle/right textures can leave blank gaps on some customized 3.3.5 clients.
    local e = CreateFrame("EditBox", name, p)
    e:SetSize(w, h)
    e:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    e:SetAutoFocus(false)
    e:SetFontObject(GameFontHighlightSmall)
    e:SetTextInsets(5, 5, 2, 2)
    e:SetText(t or "")
    e:SetJustifyH("LEFT")
    e:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }})
    e:SetBackdropColor(0.04, 0.025, 0.06, 1)
    e:SetBackdropBorderColor(0.38, 0.30, 0.44, 1)
    e:SetScript("OnTextChanged", f)
    return e
end

function ShowMainWindow()
    if NicDkpMainFrame then NicDkpMainFrame:Show() return end
    local f = CreateFrame("Frame", "NicDkpMainFrame", UIParent)
    f:SetSize(380, 440) f:SetPoint("CENTER") f:EnableMouse(true) f:SetMovable(true)
    f:RegisterForDrag("LeftButton") f:SetScript("OnDragStart", f.StartMoving) f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 }})
    tinsert(UISpecialFrames, "NicDkpMainFrame")

    local titleText = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    titleText:SetPoint("TOP", f, "TOP", 0, -15)
    titleText:SetText("Napoleon is a Cake - EP")

    CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
    f:CreateFontString("NicDkpCountText", "ARTWORK", "GameFontNormalSmall"):SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 15)

    MakeBtn(f, 100, 24, 20, -35, "База EP", function() SwitchToTab("main") end)
    MakeBtn(f, 100, 24, 125, -35, "Журнал", function() SwitchToTab("journal") end)
    MakeBtn(f, 100, 24, 230, -35, "Аукцион", function() SwitchToTab("auction") end)

    CreateMainTabFrame(f) CreateJournalTabFrame(f) CreateAuctionTabFrame(f) CreateSinglePlayerFrame(f) ShowRBDialogWindow()
    SwitchToTab("main")
end

function CreateJournalTabFrame(p)
    local t2 = CreateFrame("Frame", "NicDkpJournalTabFrame", p) 
    t2:SetSize(360, 310) t2:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -80) t2:Hide()
    
    MakeBtn(t2, 160, 24, 10, -5, "Выгрузить в CSV", function()
        local csv = "Дата;Офицер;Действие;Игрок;Количество\n"
        for _, e in ipairs(SirusEPGP_Journal) do csv = csv .. string.format("%s;%s;%s;%s;%d\n", e.date, e.officer, e.action, e.player, e.amount) end
        if NicDkpExportFrame then NicDkpExportFrame:Hide() end
        local ef = CreateFrame("Frame", "NicDkpExportFrame", UIParent) ef:SetSize(340, 220) ef:SetPoint("CENTER") ef:EnableMouse(true) ef:SetFrameStrata("DIALOG")
        ef:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
        tinsert(UISpecialFrames, "NicDkpExportFrame")
        local title = ef:CreateFontString(nil, "ARTWORK", "GameFontNormal") title:SetPoint("TOPLEFT", ef, "TOPLEFT", 15, -10) title:SetText("Ctrl+A и Ctrl+C для копирования:")
        CreateFrame("Button", nil, ef, "UIPanelCloseButton"):SetPoint("TOPRIGHT", ef, "TOPRIGHT", -2, -2)
        local eb = CreateFrame("EditBox", nil, ef) eb:SetMultiLine(true) eb:SetSize(310, 160) eb:SetPoint("TOPLEFT", ef, "TOPLEFT", 15, -30) eb:SetFontObject("ChatFontNormal") eb:SetText(csv) eb:SetAutoFocus(true) eb:HighlightText()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "NicDkpJournalScrollFrame", t2, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(315, 260) 
    scrollFrame:SetPoint("TOPLEFT", t2, "TOPLEFT", 10, -35)

    local logsArea = CreateFrame("Frame", "NicDkpJournalLogsArea", scrollFrame)
    logsArea:SetSize(315, 1)
    scrollFrame:SetScrollChild(logsArea)
end

function UpdateJournalTabUI()
    if NicDkpCountText then NicDkpCountText:Hide() end
    local s = NicDkpJournalLogsArea if not s then return end

    local kids = {s:GetChildren()}
    for _, kid in ipairs(kids) do kid:Hide() kid:SetParent(nil) end
    
    local y = 0
    for i = 1, #SirusEPGP_Journal do
        local e = SirusEPGP_Journal[i]
        
        local row = CreateFrame("Frame", nil, s) 
        row:SetSize(320, 18) 
        row:SetPoint("TOPLEFT", s, "TOPLEFT", 0, y)
        
        local f = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall") 
        f:SetPoint("LEFT", row, "LEFT", 0, 0) 
        f:SetText(string.format("[%s] %s -> %s (%s: %d)", e.date, e.officer, GetClassColoredName(e.player), e.action, e.amount))
        
        y = y - 18
    end

    s:SetHeight(math.abs(y) + 10)
end

NicDkpBasePriceValue = 100

function CreateAuctionTabFrame(p)
    local t3 = CreateFrame("Frame", "NicDkpAuctionTabFrame", p) t3:SetSize(360, 310) t3:SetPoint("TOPLEFT", p, "TOPLEFT", 10, -80) t3:Hide()

    local lbl1 = t3:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall") lbl1:SetPoint("TOPLEFT", t3, "TOPLEFT", 15, -5) lbl1:SetText("Ссылка на вещь (через Shift+Клик):")
    local eb = MakeEdit(t3, 320, 25, 15, -20, "", nil, "NicDkpAucItemEdit")
    eb:EnableMouse(true)
    eb:SetScript("OnMouseDown", function(self) self:SetFocus() end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local lbl2 = t3:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall") lbl2:SetPoint("TOPLEFT", t3, "TOPLEFT", 15, -45) lbl2:SetText("Базовая цена:")
    local ebBase = MakeEdit(t3, 50, 22, 15, -58, tostring(NicDkpBasePriceValue), function(self) NicDkpBasePriceValue = tonumber(self:GetText()) or 100 end)

    MakeBtn(t3, 100, 24, 80, -56, "Начать торги", function()
        local txt = eb:GetText()
        if txt and txt ~= "" then
            AucIsActive, AucItem, AucBid, AucBidder = true, txt, 0, "Никто"
            AucOffspec, AucTimerStarted = false, false
            if NicDkpOffspecButton then NicDkpOffspecButton:SetText("Оффспек") end
            SendChatMessage("=== АУКЦИОН НАЧАТ: " .. txt .. " ===", "RAID_WARNING")
            SendChatMessage("Пишите ставку цифрами в чат или используйте окно аддона. Таймер на 10 секунд начнётся после первой ставки и будет обновляться после каждой новой ставки.", "RAID")
            local channel = UnitInRaid("player") and "RAID" or "PARTY"
            SendAddonMessage("NICDKP", string.format("START:%s:%d", txt, NicDkpBasePriceValue), channel)
            PlayerAucActive, PlayerAucItem, PlayerAucBasePrice = true, txt, NicDkpBasePriceValue
            PlayerAucCurBid, PlayerAucLeader = 0, "Никто"
            AucTimeLeft = 0
            if UpdatePlayerAuctionUI then UpdatePlayerAuctionUI() end
            UpdateAuctionTabUI()
        end
    end)

    MakeBtn(t3, 80, 24, 185, -56, "Отменить", function()
        AucIsActive, AucItem = false, nil
        AucTimerStarted, AucOffspec = false, false
        if NicDkpOffspecButton then NicDkpOffspecButton:SetText("Оффспек") end
        if NicDkpAuctionTimerFrame then NicDkpAuctionTimerFrame:SetScript("OnUpdate", nil) end
        local channel = UnitInRaid("player") and "RAID" or "PARTY"
        SendAddonMessage("NICDKP", "STOP", channel)
        SendChatMessage("[NIC-DKP]: Аукцион отменён.", "RAID")
        eb:SetText("") UpdateAuctionTabUI()
    end)

    MakeBtn(t3, 80, 24, 270, -56, "Завершить", function() FinishAuction(false) end)
    MakeBtn(t3, 105, 20, 15, -85, "Дефолт (100)", function() ebBase:SetText("100"); NicDkpBasePriceValue = 100 end)
    MakeBtn(t3, 105, 20, 127, -85, "Оружие (200)", function() ebBase:SetText("200"); NicDkpBasePriceValue = 200 end)
    MakeBtn(t3, 105, 20, 239, -85, "Токен (500)", function() ebBase:SetText("500"); NicDkpBasePriceValue = 500 end)
    -- Move the fourth preset to its own row so it stays inside the auction window.
    MakeBtn(t3, 105, 20, 15, -109, "Печенька (1000)", function() ebBase:SetText("1000"); NicDkpBasePriceValue = 1000 end)

    local status = t3:CreateFontString("NicDkpAucStatusText", "ARTWORK", "GameFontNormal")
    status:SetPoint("TOPLEFT", t3, "TOPLEFT", 15, -142)
    status:SetWidth(330)
    status:SetJustifyH("LEFT")
    status:SetText("Аукцион закрыт.")

    NicDkpOffspecButton = MakeBtn(t3, 105, 22, 127, -109, "Оффспек", function()
        if not AucIsActive then
            BroadcastRaidMessage("[NIC-DKP]: Сначала начните аукцион.")
            return
        end
        AucOffspec = not AucOffspec
        NicDkpOffspecButton:SetText("Оффспек")
        -- Explicitly refresh the button's FontString for customized 3.3.5 clients.
        local label = NicDkpOffspecButton:GetFontString()
        if label then label:SetText(offspecLabel); label:Show() end
        NicDkpOffspecButton:Show()
        local channel = UnitInRaid("player") and "RAID" or "PARTY"
        SendAddonMessage("NICDKP", "OFFSPEC:" .. (AucOffspec and "1" or "0"), channel)
        BroadcastRaidMessage("[NIC-DKP]: Режим оффспека " .. (AucOffspec and "включён — победитель заплатит 50% конечной ставки." or "выключен — победитель заплатит полную ставку."))
        UpdateAuctionTabUI()
    end)
end

function BroadcastRaidMessage(message)
    if UnitInRaid("player") then
        SendChatMessage(message, "RAID")
    elseif UnitInParty("player") then
        SendChatMessage(message, "PARTY")
    else
        print(message)
    end
end

function StartAuctionCountdown()
    if not AucIsActive then return end
    if not NicDkpAuctionTimerFrame then NicDkpAuctionTimerFrame = CreateFrame("Frame", "NicDkpAuctionTimerFrame") end
    AucTimerStarted = true
    AucTimeLeft = 10
    AucLastBroadcastTime = nil
    local channel = UnitInRaid("player") and "RAID" or "PARTY"
    SendAddonMessage("NICDKP", "TIMER:10", channel)
    NicDkpAuctionTimerFrame:SetScript("OnUpdate", function(self, elapsed)
        if not AucIsActive or not AucTimerStarted then self:SetScript("OnUpdate", nil); return end
        AucTimeLeft = (AucTimeLeft or 10) - elapsed
        local whole = math.max(0, math.ceil(AucTimeLeft))
        if whole ~= AucLastBroadcastTime then
            AucLastBroadcastTime = whole
            local ch = UnitInRaid("player") and "RAID" or "PARTY"
            SendAddonMessage("NICDKP", "TIMER:" .. whole, ch)
            if NicDkpAucStatusText and AucIsActive then
                local nextMinBid = GetNextMinimumBid(AucBid, NicDkpBasePriceValue)
                local mode = AucOffspec and "\nРежим: Оффспек (50%)" or ""
                NicDkpAucStatusText:SetText(string.format("Лидер торгов: %s\nТекущая ставка: %d EP\nСледующая минимальная: %d EP\nАвтозавершение через: %d сек.%s", AucBidder or "Никто", AucBid or 0, nextMinBid, whole, mode))
            end
            if UpdatePlayerAuctionUI then UpdatePlayerAuctionUI() end
        end
        if AucTimeLeft <= 0 then
            self:SetScript("OnUpdate", nil)
            FinishAuction()
        end
    end)
end

function FinishAuction()
    if not AucIsActive then return end
    if NicDkpAuctionTimerFrame then NicDkpAuctionTimerFrame:SetScript("OnUpdate", nil) end
    local winner, bid, item = AucBidder, tonumber(AucBid) or 0, AucItem or "предмет"
    if winner and winner ~= "Никто" and bid > 0 then
        local cost = AucOffspec and math.floor(bid * 0.5) or bid
        local suffix = AucOffspec and " (оффспек, 50%)" or ""
        BroadcastRaidMessage(string.format("=== ТОРГИ ЗАВЕРШЕНЫ. Победитель: %s (%d EP)%s ===", winner, cost, suffix))
        if cost > 0 then MassChangeEP({{name = winner}}, cost, "срез", false, "Выиграл шмотку: " .. item .. suffix) end
    else
        BroadcastRaidMessage("=== ТОРГИ ЗАВЕРШЕНЫ. Ставок нет, победителя нет. ===")
    end
    local channel = UnitInRaid("player") and "RAID" or "PARTY"
    SendAddonMessage("NICDKP", "STOP", channel)
    AucIsActive, AucItem = false, nil
    AucTimeLeft, AucLastBroadcastTime, AucTimerStarted, AucOffspec = nil, nil, false, false
    if NicDkpOffspecButton then NicDkpOffspecButton:SetText("Оффспек") end
    if NicDkpAucItemEdit then NicDkpAucItemEdit:SetText("") end
    UpdateAuctionTabUI()
    if UpdateMainTabUI then UpdateMainTabUI() end
    if UpdatePlayerAuctionUI then UpdatePlayerAuctionUI() end
end

function UpdateAuctionTabUI()
    if NicDkpCountText then NicDkpCountText:Hide() end
    local status = NicDkpAucStatusText
    if not status then return end
    if AucIsActive then
        local nextMinBid = GetNextMinimumBid(AucBid, NicDkpBasePriceValue)
        local timerText = AucTimerStarted and ("Автозавершение через: " .. math.max(0, math.ceil(AucTimeLeft or 0)) .. " сек.") or "Ожидание первой ставки — таймер не запущен."
        local mode = AucOffspec and "\nРежим: Оффспек (50%)" or ""
        status:SetText(string.format("Лидер торгов: %s\nТекущая ставка: %d EP\nСледующая минимальная: %d EP\n%s%s", AucBidder or "Никто", AucBid or 0, nextMinBid, timerText, mode))
        local channel = UnitInRaid("player") and "RAID" or "PARTY"
        SendAddonMessage("NICDKP", string.format("UPDATE:%d:%s", AucBid, AucBidder), channel)
    else
        status:SetText("Аукцион закрыт.")
    end
end

function ShowRBDialogWindow()
    if NicDkpRTFrame then NicDkpRTFrame:Show() return end
    local f = CreateFrame("Frame", "NicDkpRTFrame", UIParent) f:SetSize(340, 260) f:SetPoint("CENTER") f:EnableMouse(true) f:SetFrameStrata("DIALOG")
    f:Hide()

    f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    tinsert(UISpecialFrames, "NicDkpRTFrame")
    local rtTitle = f:CreateFontString(nil, "ARTWORK", "GameFontNormal") rtTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -12) rtTitle:SetText("Выберите пройденные рейды:")
    CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    local y = -40
    for _, r in ipairs(NicDkpRaidPrices) do
        local cb = CreateFrame("CheckButton", "NicDkpCB_" .. r.id, f, "InterfaceOptionsCheckButtonTemplate") cb:SetPoint("TOPLEFT", f, "TOPLEFT", 20, y)
        _G[cb:GetName() .. "Text"]:SetText(string.format("%s (|cffffffff%d EP|r)", r.name, r.cost))
        cb:SetScript("OnClick", function(self) NicDkpSelectedRaids[r.id] = self:GetChecked() and true or nil end)
        y = y - 25
    end
    MakeBtn(f, 160, 24, 90, -220, "Рассчитать и Начислить", function() FinishRaidTurnout() f:Hide() UpdateMainTabUI() end)
end


CreateFrame("Frame"):SetScript("OnUpdate", function(self) if NicDkpMainTabFrame and not NicDkpRTBtn then MakeBtn(NicDkpMainTabFrame, 110, 20, 200, -5, "Завершить РТ", function() ShowRBDialogWindow() end) self:SetScript("OnUpdate", nil) end end)

StaticPopupDialogs["CONFIRM_EP_CHANGE"] = {
    text = "Применить массовое действие к отображаемому списку?", button1 = "Да", button2 = "Нет",
    OnAccept = function(self, data)
        local list = GetFilteredPlayers(NicDkpMode, NicDkpSrc, NicDkpMin, NicDkpMax)
        MassChangeEP(list, NicDkpVal, data.act, NicDkpIsPct)
        print(string.format("[NIC-DKP]: Применено %s на %d %s для %d чел.", data.act, NicDkpVal, NicDkpIsPct and "%" or "ед.", #list))
        UpdateMainTabUI()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local linkHookFrame = CreateFrame("Frame")
linkHookFrame:RegisterEvent("PLAYER_LOGIN")
linkHookFrame:SetScript("OnEvent", function()
    hooksecurefunc("ChatEdit_InsertLink", function(link)
        if NicDkpMainFrame and NicDkpMainFrame:IsShown() and NicDkpAuctionTabFrame and NicDkpAuctionTabFrame:IsShown() then
            if NicDkpAucItemEdit then
                NicDkpAucItemEdit:SetText(link)
                NicDkpAucItemEdit:SetFocus()
                return true
            end
        end
    end)
end)

