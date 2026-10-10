-- Custom boss EP templates for NIC-DKP.
if not NicDkpBossTemplates then NicDkpBossTemplates = {} end

local selectedTemplateIndex = nil
local bossRows = {}
local EnsureBossTemplateData

-- Template synchronization uses the guild addon-message channel.
-- Any officer who edits templates can broadcast their current set to guildmates
-- who have this version of NIC-DKP installed.
local TEMPLATE_SYNC_PREFIX = "NICDKPTPL1"
local templateComm = {}
local aceComm = LibStub and LibStub:GetLibrary("AceComm-3.0", true)
local aceSerializer = LibStub and LibStub:GetLibrary("AceSerializer-3.0", true)
if aceComm and aceSerializer then
    aceComm:Embed(templateComm)

    function templateComm:OnTemplateSync(prefix, message, distribution, sender)
        if sender == UnitName("player") then return end
        local ok, command, payload = aceSerializer:Deserialize(message)
        if not ok or command ~= "TEMPLATES" or type(payload) ~= "table" then return end
        -- Sanitize the incoming payload before saving it.
        local clean = {}
        for _, template in ipairs(payload) do
            if type(template) == "table" and type(template.name) == "string" and type(template.bosses) == "table" then
                local item = { name = template.name, bosses = {} }
                for _, boss in ipairs(template.bosses) do
                    if type(boss) == "table" and type(boss.name) == "string" and tonumber(boss.cost) then
                        table.insert(item.bosses, { name = boss.name, cost = math.max(0, math.floor(tonumber(boss.cost))), selected = false })
                    end
                end
                table.insert(clean, item)
            end
        end
        NicDkpBossTemplates = clean
        selectedTemplateIndex = nil
        if NicDkpBossTemplateFrame and NicDkpBossTemplateFrame:IsShown() then
            NicDkpBossTemplateFrame:RefreshAll()
        end
        print(string.format("|cff663399[NIC-DKP]:|r Шаблоны EP синхронизированы от %s.", sender or "участника гильдии"))
    end

    templateComm:RegisterComm(TEMPLATE_SYNC_PREFIX, "OnTemplateSync")
end

local function SyncBossTemplates()
    if not IsInGuild() then
        print("|cffff0000[NIC-DKP]:|r Для синхронизации нужно состоять в гильдии.")
        return
    end
    if not aceComm or not aceSerializer then
        print("|cffff0000[NIC-DKP]:|r Библиотеки синхронизации не загружены.")
        return
    end
    EnsureBossTemplateData()
    local payload = aceSerializer:Serialize("TEMPLATES", NicDkpBossTemplates)
    aceComm:SendCommMessage(TEMPLATE_SYNC_PREFIX, payload, "GUILD", nil, "NORMAL")
    print("|cff663399[NIC-DKP]:|r Шаблоны отправлены гильдии. У участников с установленным NIC-DKP они заменят локальный список шаблонов.")
end

EnsureBossTemplateData = function()
    if type(NicDkpBossTemplates) ~= "table" then NicDkpBossTemplates = {} end
    for _, template in ipairs(NicDkpBossTemplates) do
        if type(template.bosses) ~= "table" then template.bosses = {} end
    end
end

local function ClearChildren(frame)
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
end

function ShowBossTemplatesWindow()
    EnsureBossTemplateData()
    if not NicDkpBossTemplateFrame then
        local f = CreateFrame("Frame", "NicDkpBossTemplateFrame", UIParent)
        f:SetSize(520, 390)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        tinsert(UISpecialFrames, "NicDkpBossTemplateFrame")
        f:Hide()

        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -12)
        title:SetText("Шаблоны начисления EP за боссов")
        local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

        local listLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        listLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -42)
        listLabel:SetText("Шаблоны")

        local listScroll = CreateFrame("ScrollFrame", "NicDkpBossTemplateListScroll", f, "UIPanelScrollFrameTemplate")
        listScroll:SetSize(145, 260)
        listScroll:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -62)
        local listContent = CreateFrame("Frame", nil, listScroll)
        listContent:SetSize(130, 1)
        listScroll:SetScrollChild(listContent)
        f.listContent = listContent

        local editorLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        editorLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 180, -42)
        editorLabel:SetText("Создать / изменить шаблон")

        local nameLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        nameLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 180, -63)
        nameLabel:SetText("Название:")
        f.nameEdit = MakeEdit(f, 190, 20, 240, -59, "", nil)

        f.createButton = MakeBtn(f, 75, 22, 435, -59, "Создать", function()
            local name = f.nameEdit:GetText()
            name = name and name:gsub("^%s*(.-)%s*$", "%1") or ""
            if name == "" then
                print("|cffff0000[NIC-DKP]:|r Введите название шаблона.")
                return
            end
            for _, template in ipairs(NicDkpBossTemplates) do
                if template.name:lower() == name:lower() then
                    print("|cffff0000[NIC-DKP]:|r Шаблон с таким названием уже существует.")
                    return
                end
            end
            table.insert(NicDkpBossTemplates, { name = name, bosses = {} })
            selectedTemplateIndex = #NicDkpBossTemplates
            f.nameEdit:SetText(name)
            f:RefreshAll()
        end)

        local bossLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        bossLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 180, -92)
        bossLabel:SetText("Босс:")
        f.bossNameEdit = MakeEdit(f, 145, 20, 220, -88, "", nil)

        local costLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        costLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 372, -92)
        costLabel:SetText("EP:")
        f.bossCostEdit = MakeEdit(f, 45, 20, 397, -88, "100", nil)

        MakeBtn(f, 65, 22, 445, -88, "Добавить", function()
            local template = selectedTemplateIndex and NicDkpBossTemplates[selectedTemplateIndex]
            if not template then
                print("|cffff0000[NIC-DKP]:|r Сначала создайте или выберите шаблон.")
                return
            end
            local bossName = f.bossNameEdit:GetText()
            bossName = bossName and bossName:gsub("^%s*(.-)%s*$", "%1") or ""
            local cost = tonumber(f.bossCostEdit:GetText())
            if bossName == "" or not cost or cost < 0 then
                print("|cffff0000[NIC-DKP]:|r Укажите имя босса и корректное количество EP.")
                return
            end
            table.insert(template.bosses, { name = bossName, cost = math.floor(cost), selected = false })
            f.bossNameEdit:SetText("")
            f:RefreshAll()
        end)

        local bossListLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        bossListLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 180, -120)
        bossListLabel:SetText("Отметьте убитых боссов для начисления:")

        local bossScroll = CreateFrame("ScrollFrame", "NicDkpBossTemplateBossScroll", f, "UIPanelScrollFrameTemplate")
        bossScroll:SetSize(310, 145)
        bossScroll:SetPoint("TOPLEFT", f, "TOPLEFT", 180, -140)
        local bossContent = CreateFrame("Frame", nil, bossScroll)
        bossContent:SetSize(285, 1)
        bossScroll:SetScrollChild(bossContent)
        f.bossContent = bossContent

        f.totalText = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        f.totalText:SetPoint("TOPLEFT", f, "TOPLEFT", 190, -305)
        f.totalText:SetText("Выбрано: 0 EP")

        MakeBtn(f, 180, 26, 180, -330, "Начислить группе", function()
            local template = selectedTemplateIndex and NicDkpBossTemplates[selectedTemplateIndex]
            if not template then
                print("|cffff0000[NIC-DKP]:|r Выберите шаблон.")
                return
            end
            local total, names = 0, {}
            for _, boss in ipairs(template.bosses) do
                if boss.selected then
                    total = total + (tonumber(boss.cost) or 0)
                    table.insert(names, boss.name)
                end
            end
            if total <= 0 or #names == 0 then
                print("|cffff0000[NIC-DKP]:|r Отметьте хотя бы одного босса с начислением больше 0 EP.")
                return
            end
            local mode = "ALL"
            if UnitInRaid("player") then mode = "RAID"
            elseif UnitInParty("player") then mode = "PARTY" end
            local players = GetFilteredPlayers(mode, "", 0, 999999)
            StaticPopup_Show("NICDKP_CONFIRM_BOSS_EP", tostring(total), tostring(#players), {
                total = total, names = names, templateName = template.name, players = players
            })
        end)

        MakeBtn(f, 120, 26, 370, -330, "Удалить шаблон", function()
            if not selectedTemplateIndex or not NicDkpBossTemplates[selectedTemplateIndex] then return end
            table.remove(NicDkpBossTemplates, selectedTemplateIndex)
            selectedTemplateIndex = nil
            f:RefreshAll()
        end)

        MakeBtn(f, 180, 22, 180, -362, "Синхронизировать с гильдией", SyncBossTemplates)

        f.RefreshAll = function(self)
            EnsureBossTemplateData()
            ClearChildren(self.listContent)
            ClearChildren(self.bossContent)
            local y = 0
            for i, template in ipairs(NicDkpBossTemplates) do
                local b = CreateFrame("Button", nil, self.listContent, "UIPanelButtonTemplate")
                b:SetSize(130, 22)
                b:SetPoint("TOPLEFT", self.listContent, "TOPLEFT", 0, y)
                b:SetText(template.name)
                StyleNicDkpPurpleButton(b)
                b:SetScript("OnClick", function()
                    selectedTemplateIndex = i
                    self.nameEdit:SetText(template.name)
                    self:RefreshAll()
                end)
                y = y - 24
            end
            self.listContent:SetHeight(math.max(1, math.abs(y)))
            local template = selectedTemplateIndex and NicDkpBossTemplates[selectedTemplateIndex]
            if template then
                self.nameEdit:SetText(template.name)
                self.createButton:SetText("Создать")
                local by = 0
                local total = 0
                for i, boss in ipairs(template.bosses) do
                    local row = CreateFrame("Frame", nil, self.bossContent)
                    row:SetSize(300, 22)
                    row:SetPoint("TOPLEFT", self.bossContent, "TOPLEFT", 0, by)
                    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    cb:SetSize(20, 20)
                    cb:SetPoint("LEFT", row, "LEFT", 0, 0)
                    cb:SetChecked(boss.selected and true or false)
                    cb:SetScript("OnClick", function(check)
                        boss.selected = check:GetChecked() and true or false
                        self:RefreshAll()
                    end)
                    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
                    label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                    label:SetWidth(220)
                    label:SetJustifyH("LEFT")
                    label:SetText(string.format("%s — %d EP", boss.name, tonumber(boss.cost) or 0))
                    local remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                    remove:SetSize(22, 18)
                    remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                    remove:SetText("X")
                    StyleNicDkpPurpleButton(remove)
                    remove:SetScript("OnClick", function()
                        table.remove(template.bosses, i)
                        self:RefreshAll()
                    end)
                    if boss.selected then total = total + (tonumber(boss.cost) or 0) end
                    by = by - 23
                end
                self.bossContent:SetHeight(math.max(1, math.abs(by)))
                self.totalText:SetText(string.format("Выбрано: %d EP", total))
            else
                self.nameEdit:SetText("")
                self.bossContent:SetHeight(1)
                self.totalText:SetText("Выбрано: 0 EP")
            end
        end
    end
    NicDkpBossTemplateFrame:Show()
    NicDkpBossTemplateFrame:RefreshAll()
end

StaticPopupDialogs["NICDKP_CONFIRM_BOSS_EP"] = {
    text = "Начислить %s EP каждому из %s участников выбранного состава?",
    button1 = "Начислить",
    button2 = "Отмена",
    OnAccept = function(self, data)
        if not data or not data.players or not data.total then return end
        local bossNames = table.concat(data.names or {}, " + ")
        MassChangeEP(data.players, data.total, "начисление", false,
            "Боссы (" .. (data.templateName or "шаблон") .. "): " .. bossNames)
        if UpdateMainTabUI then UpdateMainTabUI() end
        print(string.format("|cff00ff00[NIC-DKP]:|r Начислено %d EP участникам состава за: %s.", data.total, bossNames))
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
