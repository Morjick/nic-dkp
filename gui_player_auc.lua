PlayerAucActive = false
PlayerAucItem = nil
PlayerAucBasePrice = 100
PlayerAucCurBid = 0
PlayerAucLeader = "Никто"
PlayerAucOffspec = false
PlayerAucOffspecDiscount = 50
PlayerAucTimerStarted = false

function CreatePlayerAuctionWindow()
    if NicDkpPlayerAucFrame then return end

    if not NicDkp_PosCache then NicDkp_PosCache = {} end

    local f = CreateFrame("Frame", "NicDkpPlayerAucFrame", UIParent)
    f:SetSize(280, 220) f:EnableMouse(true) f:SetMovable(true)
    f:RegisterForDrag("LeftButton") f:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    f:Hide()
    tinsert(UISpecialFrames, "NicDkpPlayerAucFrame")

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOffset = self:GetPoint()
        NicDkp_PosCache.point = point
        NicDkp_PosCache.rel = relativePoint
        NicDkp_PosCache.x = xOfs
        NicDkp_PosCache.y = yOffset
    end)

    if NicDkp_PosCache.x then
        f:SetPoint(NicDkp_PosCache.point, UIParent, NicDkp_PosCache.rel, NicDkp_PosCache.x, NicDkp_PosCache.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 320, -50)
    end

    local itemText = f:CreateFontString("NicDkpPlayerAucItemText", "ARTWORK", "GameFontNormal")
    itemText:SetPoint("TOP", f, "TOP", 0, -15) itemText:SetText("Предмет")

    local myEpText = f:CreateFontString("NicDkpPlayerAucMyEpText", "ARTWORK", "GameFontHighlightSmall")
    myEpText:SetPoint("TOP", itemText, "BOTTOM", 0, -5)

    local statusText = f:CreateFontString("NicDkpPlayerAucStatusText", "ARTWORK", "GameFontNormalLarge")
    statusText:SetPoint("TOP", myEpText, "BOTTOM", 0, -15)

    local bBid = CreateFrame("Button", "NicDkpPlayerAucBidBtn", f, "UIPanelButtonTemplate")
    StyleNicDkpPurpleButton(bBid)
    bBid:SetSize(200, 26) bBid:SetPoint("TOP", statusText, "BOTTOM", 0, -20)
    bBid:SetScript("OnClick", function()
        if PlayerAucActive then
            local nextBid = GetNextMinimumBid(PlayerAucCurBid, PlayerAucBasePrice)
            local myEp = GetPlayerEP(UnitName("player"))
            if myEp >= NicDkpActualCost(myName,nextBid,PlayerAucOffspec) then
                SendChatMessage(tostring(nextBid), "RAID")
            else
                BroadcastRaidMessage("[NIC-DKP]: " .. UnitName("player") .. " не может сделать ставку: недостаточно EP.")
            end
        end
    end)

    local bAllIn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    StyleNicDkpPurpleButton(bAllIn)
    bAllIn:SetSize(200, 24) bAllIn:SetPoint("TOP", bBid, "BOTTOM", 0, -5) bAllIn:SetText("ALL-IN!")
    bAllIn:SetScript("OnClick", function()
        if PlayerAucActive then
            local myEp = GetPlayerEP(UnitName("player"))
            if myEp > PlayerAucCurBid then
                SendChatMessage("all-in", "RAID")
            else
                BroadcastRaidMessage("[NIC-DKP]: " .. UnitName("player") .. " не может поставить ALL-IN: EP меньше текущей ставки.")
            end
        end
    end)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
end

function UpdatePlayerAuctionUI()
    if not NicDkpPlayerAucFrame then CreatePlayerAuctionWindow() end
    
    if PlayerAucActive then
        NicDkpPlayerAucFrame:Show()
        
        local myName = UnitName("player")
        local myEp = GetPlayerEP(myName)
        local nextMinBid = GetNextMinimumBid(PlayerAucCurBid, PlayerAucBasePrice)
        
        NicDkpPlayerAucItemText:SetText(PlayerAucItem or "Неизвестный предмет")
        NicDkpPlayerAucMyEpText:SetText(string.format("Ваш баланс: |cff00ff00%d ЕР|r", myEp))
        local timerText = PlayerAucTimerStarted and ("До завершения: " .. math.max(0, math.ceil(PlayerAucTimeLeft or 0)) .. " сек.") or "Ожидание первой ставки"
        local modeText = PlayerAucOffspec and ("\nОффспек: скидка "..PlayerAucOffspecDiscount.."%") or ""
        NicDkpPlayerAucStatusText:SetText(string.format("Лидер: %s\nСтавка: %d EP\n%s%s", GetClassColoredName(PlayerAucLeader), PlayerAucCurBid, timerText, modeText))

        NicDkpPlayerAucBidBtn:SetText(string.format("Поставить %d EP", nextMinBid))

        if myEp < nextMinBid then
            NicDkpPlayerAucBidBtn:Disable()
        else
            NicDkpPlayerAucBidBtn:Enable()
        end
    else
        NicDkpPlayerAucFrame:Hide()
    end
end

local netListener = CreateFrame("Frame")
netListener:RegisterEvent("CHAT_MSG_RAID")
netListener:RegisterEvent("CHAT_MSG_RAID_LEADER")
netListener:RegisterEvent("CHAT_MSG_ADDON")

netListener:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
        local msg, sender = select(1, ...), select(2, ...)
        if not msg or not sender then return end

        local itemLink = msg:match("^=== АУКЦИОН НАЧАТ: (.+) ===$")
        if itemLink then
            PlayerAucActive = true
            PlayerAucItem = itemLink
            PlayerAucBasePrice = 100
            PlayerAucCurBid = 0
            PlayerAucLeader = "Никто"
            PlayerAucTimeLeft = 0
            PlayerAucTimerStarted = false
            PlayerAucOffspec = false
            UpdatePlayerAuctionUI()
            return
        end

        if msg:match("^=== ТОРГИ ЗАВЕРШЕНЫ") or msg:match("Отмена торгов") then
            PlayerAucActive = false
            UpdatePlayerAuctionUI()
            print("|cff00ff00[NIC-DKP]:|r Торги за предмет завершены.")
            return
        end
    end

        if event == "CHAT_MSG_ADDON" then
        local prefix, msg, typeChan = select(1, ...), select(2, ...), select(3, ...)
        if prefix ~= "NICDKP" or not msg then return end
        if typeChan ~= "RAID" and typeChan ~= "PARTY" then return end

        if msg:find("^START:") then
            local data = msg:sub(7) 
            local lastColon = data:match("^.*():")

            if lastColon then
                local itemLink = data:sub(1, lastColon - 1)
                local priceStr = data:sub(lastColon + 1)
                
                PlayerAucActive = true
                PlayerAucItem = (itemLink and itemLink ~= "") and itemLink or "Предмет лута"
                PlayerAucBasePrice = tonumber(priceStr) or 100
                PlayerAucCurBid = 0
                PlayerAucLeader = "Никто"
                PlayerAucTimeLeft = 0
                PlayerAucTimerStarted = false
                PlayerAucOffspec = false
                UpdatePlayerAuctionUI()
            end
            
        elseif msg:find("^UPDATE:") then
            local _, bid, leader = strsplit(":", msg)
            PlayerAucCurBid = tonumber(bid) or 0
            PlayerAucLeader = (leader and leader ~= "") and leader or "Никто"
            UpdatePlayerAuctionUI()

        elseif msg:find("^TIMER:") then
            PlayerAucTimeLeft = tonumber(msg:sub(7)) or 0
            PlayerAucTimerStarted = PlayerAucTimeLeft > 0
            UpdatePlayerAuctionUI()
        elseif msg:find("^OFFSPEC:") then
            local flag,discount=msg:match("^OFFSPEC:(%d):?(%d*)")
            PlayerAucOffspec = flag == "1"
            PlayerAucOffspecDiscount = tonumber(discount) or 50
            UpdatePlayerAuctionUI()
            
        elseif msg == "STOP" then
            PlayerAucActive = false
            UpdatePlayerAuctionUI()
        end
    end
end)
