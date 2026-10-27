-- DKP 2.0 shared guild history, retained for 21 days.
-- AceComm handles message fragmentation; records never modify EP balances.
NicDkpHistory=NicDkpHistory or {records={},counter=0}
NicDkpHistory.records=NicDkpHistory.records or {}
local H=NicDkpHistory
local comm=LibStub("AceComm-3.0",true)
local serial=LibStub("AceSerializer-3.0",true)
local PREFIX="DKP2H21"
local ttl=21*24*60*60
local queue={}
local seen={}
local function short(n) return (n or ""):match("^[^%-]+") or "" end
local function validOfficer(n)
 local idx=GetGuildIndexByName(short(n))
 if not idx then return false end
 local _,_,rank=GetGuildRosterInfo(idx)
 return rank and rank<=2
end
local function purge()
 local now=time()
 for i=#H.records,1,-1 do
  local r=H.records[i]
  if type(r)~="table" or type(r.ts)~="number" or r.ts<now-ttl or r.ts>now+3600 then table.remove(H.records,i) end
 end
 if #H.records>3000 then
  table.sort(H.records,function(a,b) return a.ts>b.ts end)
  while #H.records>3000 do table.remove(H.records) end
 end
 wipe(seen)
 for _,r in ipairs(H.records) do if type(r.id)=="string" then seen[r.id]=true end end
end
local function accept(r)
 if type(r)~="table" or type(r.id)~="string" or #r.id>110 or type(r.ts)~="number" then return false end
 if type(r.officer)~="string" or type(r.player)~="string" or type(r.action)~="string" then return false end
 if not validOfficer(r.officer) or #r.player>70 or #r.action>250 or type(r.amount)~="number" then return false end
 if r.ts<time()-ttl or r.ts>time()+3600 or seen[r.id] then return false end
 seen[r.id]=true
 table.insert(H.records,1,r)
 if #H.records>3000 then purge() end
 if UpdateJournalTabUI and NicDkpJournalTabFrame and NicDkpJournalTabFrame:IsShown() then UpdateJournalTabUI() end
 if NicDkpGuildUpdateHistory then NicDkpGuildUpdateHistory() end
 return true
end
local function transmit(kind,data,target)
 if not comm or not serial or not IsInGuild() then return end
 local msg=serial:Serialize(kind,data)
 if target then comm:SendCommMessage(PREFIX,msg,"WHISPER",target,"BULK")
 else comm:SendCommMessage(PREFIX,msg,"GUILD",nil,"BULK") end
end
function NicDkpHistoryAdd(player,amount,action,reason)
 if not IsPlayerOfficer() then return end
 H.counter=(H.counter or 0)+1
 local r={id=short(UnitName("player"))..":"..time()..":"..H.counter,ts=time(),date=date("%d.%m %H:%M"),officer=short(UnitName("player")),player=tostring(player or ""),amount=tonumber(amount) or 0,action=tostring(action or ""),reason=tostring(reason or "")}
 if accept(r) then transmit("EVENT",r) end
end
function NicDkpHistoryRequest()
 purge()
 transmit("HELLO",time())
end
local listener={}
if comm then
 comm:Embed(listener)
 listener:RegisterComm(PREFIX,function(prefix,msg,distribution,sender)
  if not IsInGuild() or not serial or short(sender)==short(UnitName("player")) then return end
  local idx=GetGuildIndexByName(short(sender))
  if not idx then return end
  local ok,kind,data=serial:Deserialize(msg)
  if not ok then return end
  if kind=="EVENT" then
   -- The sender must be the original officer, not a viewer relaying records.
   if validOfficer(sender) and type(data)=="table" and short(data.officer)==short(sender) then accept(data) end
  elseif kind=="HELLO" then
   -- Only one responder per client per request; paced sends prevent flooding.
   purge()
   for _,r in ipairs(H.records) do
    queue[#queue+1]={target=sender,record=r}
   end
  elseif kind=="HISTORY" then
   -- Guildmates may relay cached records from officers, with the original
   -- officer name still checked against the current guild roster.
   accept(data)
  end
 end)
end
local frame=CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
local initialized=false
local elapsed=0
local delay=0
frame:SetScript("OnEvent",function(_,event)
 if event=="PLAYER_ENTERING_WORLD" then initialized=false;delay=8;purge() end
 if event=="GUILD_ROSTER_UPDATE" and not initialized and IsInGuild() then delay=math.min(delay,2) end
end)
frame:SetScript("OnUpdate",function(_,dt)
 elapsed=elapsed+dt
 if elapsed>=0.16 then
  elapsed=0
  if #queue>0 and IsInGuild() then
   local q=table.remove(queue,1)
   transmit("HISTORY",q.record,q.target)
  end
 end
 if not initialized and delay>0 then
  delay=delay-dt
  if delay<=0 and IsInGuild() then initialized=true;NicDkpHistoryRequest() end
 end
end)
function NicDkpHistoryList()
 purge()
 table.sort(H.records,function(a,b) if a.ts==b.ts then return a.id>b.id end return a.ts>b.ts end)
 return H.records
end
