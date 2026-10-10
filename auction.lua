AucIsActive, AucItem, AucBid, AucBidder = false, nil, 0, "Никто"

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("CHAT_MSG_RAID")
watcher:RegisterEvent("CHAT_MSG_RAID_LEADER")
watcher:RegisterEvent("CHAT_MSG_ADDON")
watcher:SetScript("OnEvent", function(_, event, msg, sender, channel, snd)

    if event == "CHAT_MSG_ADDON" then
        -- WoW 3.3.5 CHAT_MSG_ADDON args: prefix, message, distribution, sender.
        local prefix, addonMessage, distribution = msg, sender, channel
        if prefix == "NICDKP" and addonMessage and (distribution == "RAID" or distribution == "PARTY") then
            local cmd, bid, bidder = addonMessage:match("^([^:]+):?([^:]*):?([^:]*)$")
            if cmd == "TIMER" then
                AucTimeLeft = tonumber(bid) or 0
            elseif cmd == "UPDATE" then
                AucBid = tonumber(bid) or 0
                AucBidder = bidder or "Никто"
                if NicDkpAucStatusText and AucIsActive then
                    local currentBasePrice = NicDkpBasePriceValue or 100
                    local nextMinBid = GetNextMinimumBid(AucBid, currentBasePrice)
                    NicDkpAucStatusText:SetText(string.format("Лидер торгов: %s\nТекущая ставка: %d EP\nСледующая минимальная: %d EP\nАвтозавершение через: %d сек.", AucBidder or "Никто", AucBid, nextMinBid, math.max(0, math.ceil(AucTimeLeft or 7))))
                end
            end
        end
        return
    end

    if not AucIsActive then return end
    local name = sender:match("^([^%-]+)")
    local bid = nil

    local cleanMsg = msg:gsub("^%s*(.-)%s*$", "%1")
    
    if cleanMsg:lower() == "all-in" or cleanMsg:lower() == "аллин" then 
        bid = GetPlayerEP(name)
    else
        local num = cleanMsg:match("^(%d+)$") 
        if num then bid = tonumber(num) end 
    end
    
    local currentBasePrice = NicDkpBasePriceValue or 100
    local minRequired = GetNextMinimumBid(AucBid, currentBasePrice)

    if bid then
        local playerEP = GetPlayerEP(name) or 0

        if bid < minRequired then
            BroadcastRaidMessage(string.format("[NIC-DKP]: Ставка %s отклонена: %d EP, минимум %d EP.", name, bid, minRequired))

        elseif playerEP < bid then
            BroadcastRaidMessage(string.format("[NIC-DKP]: Ставка %s отклонена: недостаточно EP (%d из %d).", name, playerEP, bid))
        
        else
            AucBid, AucBidder = bid, name
            BroadcastRaidMessage(string.format("Ставка принята: %s (%d EP)", name, bid))
            if StartAuctionCountdown then StartAuctionCountdown() end
            if UpdateAuctionTabUI then UpdateAuctionTabUI() end
        end
    end
end)

