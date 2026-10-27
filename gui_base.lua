
-- Allows dragging the native 3.3.5 color picker by its upper empty strip.
function NicDkpMakeColorPickerMovable()
 local picker=ColorPickerFrame
 if not picker then return end
 picker:SetMovable(true)
 picker:EnableMouse(true)
 if not picker.nicDkpDragHandle then
  local handle=CreateFrame("Frame",nil,picker)
  handle:SetPoint("TOPLEFT",picker,"TOPLEFT",12,-5)
  handle:SetPoint("TOPRIGHT",picker,"TOPRIGHT",-48,-5)
  handle:SetHeight(21)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart",function() picker:StartMoving() end)
  handle:SetScript("OnDragStop",function() picker:StopMovingOrSizing() end)
  handle:SetFrameLevel(picker:GetFrameLevel()+4)
  picker.nicDkpDragHandle=handle
 end
end
NicDkpBasePriceValue=100
SLASH_NICDKP1="/nd"
SlashCmdList["NICDKP"]=function() if NicDkpMainFrame and NicDkpMainFrame:IsShown() then NicDkpMainFrame:Hide() else ShowMainWindow() end end
NicDkpMode,NicDkpSrc,NicDkpMin,NicDkpMax="ALL","",0,999999
NicDkpStyle=NicDkpStyle or {}
NicDkpStyle.button=NicDkpStyle.button or {r=.20,g=.07,b=.31}
NicDkpStyle.border=NicDkpStyle.border or {r=0,g=0,b=0}
local styled={}
function StyleNicDkpPurpleButton(b)
 styled[#styled+1]=b
 local t=b:CreateTexture(nil,"BACKGROUND");t:SetTexture("Interface\\Buttons\\WHITE8X8");t:SetAllPoints(b)
 b:SetNormalTexture(t);b.nicTexture=t;t:SetVertexColor(NicDkpStyle.button.r,NicDkpStyle.button.g,NicDkpStyle.button.b)
 b.nicBorders={}
 for i=1,4 do
  local edge=b:CreateTexture(nil,"OVERLAY");edge:SetTexture("Interface\\Buttons\\WHITE8X8")
  if i==1 then edge:SetPoint("TOPLEFT",0,0);edge:SetPoint("TOPRIGHT",0,0);edge:SetHeight(1)
  elseif i==2 then edge:SetPoint("BOTTOMLEFT",0,0);edge:SetPoint("BOTTOMRIGHT",0,0);edge:SetHeight(1)
  elseif i==3 then edge:SetPoint("TOPLEFT",0,0);edge:SetPoint("BOTTOMLEFT",0,0);edge:SetWidth(1)
  else edge:SetPoint("TOPRIGHT",0,0);edge:SetPoint("BOTTOMRIGHT",0,0);edge:SetWidth(1) end
  local c=NicDkpStyle.border;edge:SetVertexColor(c.r,c.g,c.b);b.nicBorders[i]=edge
 end
end
function MakeBtn(p,w,h,x,y,t,f)
 local b=CreateFrame("Button",nil,p,"UIPanelButtonTemplate");b:SetSize(w,h);b:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);b:SetText(t);b:SetScript("OnClick",f);StyleNicDkpPurpleButton(b);return b
end
function MakeEdit(p,w,h,x,y,t,f)
 local b=CreateFrame("EditBox",nil,p,"InputBoxTemplate");b:SetSize(w,h);b:SetPoint("TOPLEFT",p,"TOPLEFT",x,y);b:SetAutoFocus(false);b:SetText(t or "");if f then b:SetScript("OnTextChanged",f) end;return b
end
function ShowNicDkpPalette()
 if NicDkpPaletteFrame then NicDkpPaletteFrame:Show();return end
 local f=CreateFrame("Frame","NicDkpPaletteFrame",UIParent)
 f:SetSize(245,150);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
 f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 local title=f:CreateFontString(nil,"ARTWORK","GameFontNormal")
 title:SetPoint("TOP",f,"TOP",0,-15);title:SetText("Настройка цветов")
 local function pick(key)
  local old=NicDkpStyle[key]
  ColorPickerFrame.hasOpacity=false
  ColorPickerFrame.func=function()
   local r,g,b=ColorPickerFrame:GetColorRGB();NicDkpStyle[key]={r=r,g=g,b=b}
   for _,button in ipairs(styled) do
    if button.nicTexture then local c=NicDkpStyle.button;button.nicTexture:SetVertexColor(c.r,c.g,c.b) end
    if button.nicBorders then local c=NicDkpStyle.border;for _,edge in ipairs(button.nicBorders) do edge:SetVertexColor(c.r,c.g,c.b) end end
   end
  end
  ColorPickerFrame:SetColorRGB(old.r,old.g,old.b);ColorPickerFrame:Show()
  NicDkpMakeColorPickerMovable()
 end
 MakeBtn(f,190,26,27,-43,"Цвет кнопок",function() pick("button") end)
 MakeBtn(f,190,26,27,-81,"Цвет обводки",function() pick("border") end)
 CreateFrame("Button",nil,f,"UIPanelCloseButton"):SetPoint("TOPRIGHT",f,"TOPRIGHT",-2,-2)
 f:Show()
end
function SwitchToTab() if NicDkpMainTabFrame then NicDkpMainTabFrame:Show();UpdateMainTabUI() end end
function ShowMainWindow()
 if NicDkpMainFrame then NicDkpMainFrame:Show();UpdateMainTabUI();return end
 local f=CreateFrame("Frame","NicDkpMainFrame",UIParent);f:SetSize(380,340);f:SetPoint("CENTER");f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 local title=f:CreateFontString(nil,"ARTWORK","GameFontNormalLarge");title:SetPoint("TOP",0,-17);title:SetText("Napoleon is a Cake - EP")
 CreateFrame("Button",nil,f,"UIPanelCloseButton"):SetPoint("TOPRIGHT",-5,-5)
 local sig=f:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");sig:SetPoint("BOTTOMRIGHT",-12,10);sig:SetText("Improved by Eezzee")
 CreateMainTabFrame(f);UpdateMainTabUI()
 MakeBtn(f,100,23,16,-307,"Журнал",NicDkpGuildShowHistory)
end
function BroadcastRaidMessage(msg)
 if UnitInRaid("player") then SendChatMessage(msg,"RAID") elseif UnitInParty("player") then SendChatMessage(msg,"PARTY") else print(msg) end
end

function NicDkpGuildUpdateHistory()
 local panel=NicDkpGuildHistoryFrame
 if not panel or not panel:IsShown() then return end
 local lines={}
 for _,r in ipairs(NicDkpHistoryList()) do
  local amount=r.amount>=0 and ("+"..r.amount) or tostring(r.amount)
  local desc=r.action..(r.reason~="" and (": "..r.reason) or "")
  lines[#lines+1]=string.format("[%s] %s: %s | %s | %s EP",r.date,r.officer,r.player,desc,amount)
 end
 panel.text:SetText(#lines>0 and table.concat(lines,"\n") or "История пуста. Нажмите «Обновить журнал» для синхронизации.")
 panel.content:SetHeight(math.max(240,panel.text:GetStringHeight()+20))
end
function NicDkpGuildShowHistory()
 if NicDkpGuildHistoryFrame then NicDkpGuildHistoryFrame:Show();NicDkpGuildUpdateHistory();return end
 local f=CreateFrame("Frame","NicDkpGuildHistoryFrame",UIParent)
 f:SetSize(550,390);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
 f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 local title=f:CreateFontString(nil,"ARTWORK","GameFontNormalLarge");title:SetPoint("TOPLEFT",15,-17);title:SetText("Журнал гильдии — 21 день")
 CreateFrame("Button",nil,f,"UIPanelCloseButton"):SetPoint("TOPRIGHT",-5,-5)
 MakeBtn(f,165,24,16,-42,"Обновить журнал",NicDkpHistoryRequest)
 local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",15,-76);scroll:SetSize(505,294)
 local content=CreateFrame("Frame",nil,scroll);content:SetSize(485,260);scroll:SetScrollChild(content)
 local text=content:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");text:SetPoint("TOPLEFT",0,0);text:SetWidth(480);text:SetJustifyH("LEFT");text:SetJustifyV("TOP")
 f.text=text;f.content=content
 NicDkpGuildUpdateHistory()
end
