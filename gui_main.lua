function CreateMainTabFrame(parent)
 local f=CreateFrame("Frame","NicDkpMainTabFrame",parent);f:SetSize(355,265);f:SetPoint("TOPLEFT",12,-48)
 MakeBtn(f,95,23,10,-5,"Обновить",function() GuildRoster();UpdateMainTabUI() end)
 MakeBtn(f,85,23,120,-5,"Цвета",ShowNicDkpPalette)
 -- Custom search edit: avoid InputBoxTemplate's missing middle texture on 3.3.5a.
 local search=CreateFrame("EditBox",nil,f)
 search:SetSize(120,21)
 search:SetPoint("TOPLEFT",f,"TOPLEFT",220,-6)
 search:SetAutoFocus(false)
 search:SetFontObject("ChatFontNormal")
 search:SetTextInsets(7,7,0,0)
 search:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=false,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 search:SetBackdropColor(0.08,0.08,0.1,0.95)
 search:SetBackdropBorderColor(0.6,0.55,0.4,1)
 search:SetText("")
 search:SetScript("OnTextChanged",function() UpdateMainTabUI() end)
 search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
 search:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
 NicDkpGuildSearch=search
 local count=f:CreateFontString("NicDkpCountText","ARTWORK","GameFontHighlightSmall");count:SetPoint("TOPLEFT",15,-36)
 local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetSize(315,190);scroll:SetPoint("TOPLEFT",10,-60)
 local content=CreateFrame("Frame",nil,scroll);content:SetSize(295,2160);scroll:SetScrollChild(content)
 NicDkpGuildRows={}
 for i=1,120 do
  local row=CreateFrame("Frame",nil,content);row:SetSize(282,18);row:SetPoint("TOPLEFT",0,-(i-1)*18)
  local name=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");name:SetPoint("LEFT",0,0);name:SetWidth(202);name:SetJustifyH("LEFT")
  local ep=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");ep:SetPoint("RIGHT",0,0);ep:SetWidth(80);ep:SetJustifyH("RIGHT")
  NicDkpGuildRows[i]={frame=row,name=name,ep=ep}
 end
end
function UpdateMainTabUI()
 if not NicDkpGuildRows then return end
 local filter=NicDkpGuildSearch and NicDkpGuildSearch:GetText():lower() or ""
 local list=GetFilteredPlayers("ALL","",0,999999)
 local matches={}
 for _,player in ipairs(list) do
  if filter=="" or player.name:lower():find(filter,1,true) then
   matches[#matches+1]=player
  end
 end
 for i,row in ipairs(NicDkpGuildRows) do
  local player=matches[i]
  if player then
   row.name:SetText(GetClassColoredName(player.name))
   row.ep:SetText(tostring(player.ep).." EP")
   row.frame:Show()
  else row.frame:Hide() end
 end
 NicDkpCountText:SetText("Согильдийцев: "..#matches)
end
