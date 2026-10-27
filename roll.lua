NicDkpConfig=NicDkpConfig or {rollRankBonuses={ ["Старший рейдер"]=20,["Рейдер"]=0,["Новичок"]=0,["Офицер"]=0,["ГМ"]=0 }}
-- DKP 2.0 roll mode: actual Blizzard RandomRoll results, never client-supplied numbers.
NicDkpRoll = {active=false, entries={}, first=false, left=0, reroll=false}
local R=NicDkpRoll
local function myName() return (UnitName("player") or ""):match("^[^%-]+") end
local function isOwner() return R.owner and R.owner:match("^[^%-]+")==myName() end
local function canRaidWarn()
 if not UnitInRaid("player") then return false end
 for i=1,(GetNumRaidMembers() or 0) do
  local name,rank=GetRaidRosterInfo(i)
  if name and name:match("^[^%-]+")==myName() then
   return rank==1 or rank==2
  end
 end
 return false
end
local function announce(msg)
 if not UnitInRaid("player") then print(msg);return end
 -- One announcement only: RAID_WARNING for leader/assistant, RAID otherwise.
 local channel=canRaidWarn() and "RAID_WARNING" or "RAID"
 local ok,err=pcall(SendChatMessage,msg,channel)
 if not ok then print("[NIC-DKP] Ошибка "..channel..": "..tostring(err)) end
end
local function send(msg)
 SendAddonMessage("NICDKPROLL",msg,UnitInRaid("player") and "RAID" or "PARTY")
end
local function rankBonus(name)
 local idx=GetGuildIndexByName(name)
 if not idx then return 0 end
 local rankName=select(2,GetGuildRosterInfo(idx))
 local bonuses=NicDkpConfig and NicDkpConfig.rollRankBonuses or {}
 for configured,value in pairs(bonuses) do
  if rankName and configured:lower()==rankName:lower() then return tonumber(value) or 0 end
 end
 return 0
end
local function result(name,raw)
 local bonus=rankBonus(name)
 if R.special and raw==R.special then return 100,0 end
 return raw+bonus,bonus
end
local function standings()
 local entries={}
 for name,raw in pairs(R.entries) do
  local total,bonus=result(name,raw)
  entries[#entries+1]={name=name,raw=raw,total=total,bonus=bonus}
 end
 table.sort(entries,function(a,b) if a.total==b.total then return a.name<b.name end return a.total>b.total end)
 return entries
end
local function redraw()
 if not NicDkpRollWindow then return end
 if not R.active then NicDkpRollWindow:Hide();return end
 if not R.dismissed then NicDkpRollWindow:Show() end
 NicDkpRollItem:SetText(R.item or "Розыгрыш")
 NicDkpRollRule:SetText(R.special and (R.special.."=100") or "Classic")
 NicDkpRollTimer:SetText(R.first and ("Осталось: "..math.ceil(R.left).." сек.") or "Ожидание первого броска")
 local entries=standings()
 for i=1,25 do
  local label=NicDkpRollRows[i]
  if entries[i] then
   local e=entries[i]
   label:SetText(string.format("%d. %s     %d%s = %d",i,e.name,e.raw,e.bonus>0 and (" +"..e.bonus) or "",e.total))
   local classToken
   for j=1,GetNumGuildMembers() do
    local guildName,_,_,_,localizedClass,_,_,_,_,_,token=GetGuildRosterInfo(j)
    if guildName and guildName:match("^[^%-]+") == e.name:match("^[^%-]+") then
     classToken=token
     if not classToken then
      for k,v in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do if v==localizedClass then classToken=k;break end end
      if not classToken then for k,v in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do if v==localizedClass then classToken=k;break end end end
     end
     break
    end
   end
   local color=classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
   if color then label:SetTextColor(color.r,color.g,color.b) else label:SetTextColor(1,1,1) end
   label:Show()
  else label:Hide() end
 end
 NicDkpRollListContent:SetHeight(math.max(160,#entries*23))
 if R.entries[UnitName("player")] or (R.eligible and not R.eligible[UnitName("player")]) then NicDkpRollButton:Disable() else NicDkpRollButton:Enable() end
end
local createWindow
local function stopRound()
 local entries=standings()
 if #entries==0 then
  if isOwner() then announce("[NIC-DKP]: Розыгрыш завершён без участников.") end
  R.active=false;if isOwner() then send("END") end;redraw();return
 end
 local top=entries[1].total
 local tied={}
 for _,e in ipairs(entries) do if e.total==top then tied[#tied+1]=e.name end end
 if #tied>1 then
  if isOwner() then
   announce("[NIC-DKP]: Ничья за первое место ("..top.."). Переброс: "..table.concat(tied,", "))
   send("TIE:"..table.concat(tied,","))
  end
  R.eligible={};for _,name in ipairs(tied) do R.eligible[name]=true end
  R.entries={};R.first=false;R.left=0;R.deadline=nil;R.reroll=true
  redraw()
 else
  if isOwner() then announce("[NIC-DKP]: Победитель розыгрыша: "..entries[1].name.." ("..top..")") end
  R.active=false;if isOwner() then send("END") end;redraw()
 end
end
function NicDkpStartRoll(item,special)
 print("[NIC-DKP]: Розыгрыш запускает только офицер.");return
end
function NicDkpGuildDisabledRoll(item,special)
 if not IsPlayerOfficer() then print("[NIC-DKP]: Недостаточно прав для запуска ролла.");return end
 if R.active then print("[NIC-DKP]: Розыгрыш уже активен.");return end
 if AucIsActive then print("[NIC-DKP]: Сначала завершите аукцион.");return end
 if special~=nil and (type(special)~="number" or special<1 or special>99 or special~=math.floor(special)) then print("[NIC-DKP]: Правило от 1 до 99.");return end
 if createWindow then createWindow() end
 if NicDkpRollWindow then NicDkpRollWindow:Show() end
 R.owner=myName();R.active=true;R.dismissed=false;R.deadline=nil;R.item=item;R.special=special;R.entries={};R.first=false;R.left=0;R.reroll=false;R.eligible=nil
 redraw()
 -- Preserve the original clickable item hyperlink. In WoW 3.3.5a adding
 -- extra text to an item hyperlink can make the whole message too long,
 -- especially on Sirus custom items. Announce the item on its own and
 -- announce the special rule separately using the same single chat channel.
 local label=tostring(item or "предмет")
 local channel=canRaidWarn() and "RAID_WARNING" or "RAID"
 if not UnitInRaid("player") then channel=nil end
 local function sendNotice(message)
  if not channel then print(message);return true end
  local ok,err=pcall(SendChatMessage,message,channel)
  if not ok then print("[NIC-DKP] Ошибка анонса: "..tostring(err)) end
  return ok
 end
 local itemNotice="[DKP] Ролл: "..label
 -- Do not truncate item hyperlinks; use a compact clickable link without
 -- extra text if it would exceed the chat message limit.
 if #itemNotice>250 then itemNotice=label end
 sendNotice(itemNotice)
 if special then
  sendNotice("[DKP] Условие розыгрыша: "..tostring(special).." = 100")
 end
 local synced,syncErr=pcall(send,"START:"..tostring(special or 0)..":"..item)
 if not synced then print("[NIC-DKP] Ошибка синхронизации ролла: "..tostring(syncErr)) end
 if UnitInRaid("player") then
  print("[NIC-DKP] Анонс предмета: "..itemNotice..(special and ("; условие "..special.."=100") or ""))
 end
 redraw()
end
createWindow=function()
 if NicDkpRollWindow then return end
 local f=CreateFrame("Frame","NicDkpRollWindow",UIParent)
 f:SetSize(330,355);f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetPoint("CENTER",UIParent,"CENTER",300,30);f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",f.StartMoving);f:SetScript("OnDragStop",f.StopMovingOrSizing)
 f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
 close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5)
 close:SetScript("OnClick",function() R.dismissed=true;f:Hide() end)
 local item=f:CreateFontString("NicDkpRollItem","ARTWORK","GameFontNormal");item:SetPoint("TOP",0,-18);item:SetWidth(290)
 local rule=f:CreateFontString("NicDkpRollRule","ARTWORK")
 rule:SetFont("Fonts\\FRIZQT__.TTF",25,"OUTLINE")
 rule:SetTextColor(0.2,1,0.15)
 rule:SetPoint("TOP",0,-40)
 rule:SetWidth(290)
 rule:SetJustifyH("CENTER")
 local timer=f:CreateFontString("NicDkpRollTimer","ARTWORK","GameFontNormal");timer:SetPoint("TOP",0,-78)
 local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetSize(290,160);scroll:SetPoint("TOPLEFT",12,-108)
 local content=CreateFrame("Frame","NicDkpRollListContent",scroll);content:SetSize(270,160);scroll:SetScrollChild(content)
 NicDkpRollRows={}
 for i=1,25 do
  local label=content:CreateFontString(nil,"ARTWORK");label:SetFont("Fonts\\FRIZQT__.TTF",15,"OUTLINE");label:SetPoint("TOPLEFT",5,-(i-1)*23);label:SetWidth(260);label:SetJustifyH("LEFT");NicDkpRollRows[i]=label
 end
 local b=CreateFrame("Button","NicDkpRollButton",f,"UIPanelButtonTemplate");b:SetSize(180,25);b:SetPoint("BOTTOM",0,52);b:SetText("Ролл")
 if StyleNicDkpPurpleButton then StyleNicDkpPurpleButton(b) end
 b:SetScript("OnClick",function()
  if not R.active or R.entries[UnitName("player")] or (R.eligible and not R.eligible[UnitName("player")]) then return end
  RandomRoll(1,100)
 end)
 f:Hide()
end
local function systemRollPattern()
 local fmt=RANDOM_ROLL_RESULT or "%s rolls %d (%d-%d)"
 local pattern=""
 local pos=1
 while pos<=#fmt do
  local c=fmt:sub(pos,pos)
  if c=="%" then
   local kind=fmt:sub(pos+1,pos+1)
   if kind=="s" then pattern=pattern.."(.+)";pos=pos+2
   elseif kind=="d" then pattern=pattern.."(%d+)";pos=pos+2
   else pattern=pattern.."%%";pos=pos+1 end
  else
   if c:find("[%(%)%.%+%-%*%?%[%]%^%$]") then pattern=pattern.."%" end
   pattern=pattern..c;pos=pos+1
  end
 end
 return "^"..pattern.."$"
end
local listener=CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_ADDON");listener:RegisterEvent("CHAT_MSG_SYSTEM")
listener:SetScript("OnEvent",function(_,event,...)
 if event=="CHAT_MSG_ADDON" then
  local prefix,msg,dist,sender=...
  if prefix~="NICDKPROLL" or (dist~="RAID" and dist~="PARTY") then return end
  local author=(sender or ""):match("^[^%-]+")
  if author==myName() then return end -- Never overwrite host countdown with echoed addon messages.
  local idx=GetGuildIndexByName(author)
  local rank
  if idx then local _,_,r=GetGuildRosterInfo(idx);rank=r end
  if msg:sub(1,6)=="START:" then
   if not rank or rank>2 then return end
   local n,item=msg:match("^START:(%d+):(.+)$")
   if not n or not item then return end
   if createWindow then createWindow() end
   R.owner=author;R.active=true;R.dismissed=false;R.deadline=nil;R.item=item;R.special=tonumber(n)~=0 and tonumber(n) or nil;R.entries={};R.first=false;R.left=0;R.reroll=false;R.eligible=nil
  elseif msg:sub(1,6)=="BONUS:" then
   if author~=R.owner then return end
   local ser=LibStub("AceSerializer-3.0",true)
   if ser then
    local ok,bonuses=ser:Deserialize(msg:sub(7))
    if ok and type(bonuses)=="table" then NicDkpConfig.rollRankBonuses=bonuses end
   end
  elseif msg:sub(1,5)=="TIME:" then
   if author~=R.owner then return end
   R.first=true;R.left=tonumber(msg:sub(6)) or 0;R.deadline=R.deadline or (GetTime()+R.left)
  elseif msg:sub(1,5)=="TIE:" then
   if author~=R.owner then return end
   R.entries={};R.first=false;R.left=0;R.deadline=nil;R.reroll=true;R.eligible={}
   for name in msg:sub(5):gmatch("[^,]+") do R.eligible[name]=true end
  elseif msg=="END" then if author~=R.owner then return end;R.active=false
  end
  redraw();return
 end
 if not R.active then return end
 local msg=...
 local name,raw,min,max=msg:match(systemRollPattern())
 raw=tonumber(raw);min=tonumber(min);max=tonumber(max)
 if not name or not raw or min~=1 or max~=100 then return end
 name=name:match("^[^%-]+")
 if R.eligible and not R.eligible[name] then return end
 if R.entries[name] then return end
 R.entries[name]=raw
 if isOwner() then
  R.first=true;R.left=10;R.deadline=GetTime()+10;send("TIME:10")
 end
 redraw()
end)
local ticker=CreateFrame("Frame")
local accum=0
ticker:SetScript("OnUpdate",function(_,elapsed)
 if not R.active or not R.first then return end
 if isOwner() then
  if not R.deadline then R.deadline=GetTime()+math.max(0,R.left) end
  R.left=math.max(0,R.deadline-GetTime())
  accum=accum+elapsed
  if accum>=1 then accum=0;send("TIME:"..math.ceil(R.left)) end
  if R.left<=0.05 then
   R.left=0
   if not R.finishing then
    R.finishing=true
    local ok,err=pcall(stopRound)
    R.finishing=false
    if not ok then
     print("[NIC-DKP] Ошибка завершения ролла: "..tostring(err))
     R.active=false;R.first=false
     send("END")
    end
   end
  end
 else R.left=math.max(0,(R.deadline or GetTime())-GetTime()) end
 redraw()
end)
local load=CreateFrame("Frame");load:RegisterEvent("PLAYER_LOGIN")
load:SetScript("OnEvent",function() createWindow() end)
