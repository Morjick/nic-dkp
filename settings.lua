NicDkpConfig = NicDkpConfig or {}
local defaults = {offspec=50, prices={100,200,500,1000}, modifiers={}, revision=1}
for k,v in pairs(defaults) do if NicDkpConfig[k]==nil then NicDkpConfig[k]=v end end
function NicDkpModifier(name)
 local key = (name or ""):match("^[^%-]+")
 return tonumber(NicDkpConfig.modifiers[key or ""] or 0) or 0
end
function NicDkpActualCost(name,bid,offspec)
 local base = offspec and math.floor(bid*(100-NicDkpConfig.offspec)/100) or bid
 local penalty = math.max(0,-NicDkpModifier(name))
 return math.floor(base*(100+penalty)/100+0.5)
end
function NicDkpBumpConfig() NicDkpConfig.revision=(NicDkpConfig.revision or 1)+1 end
