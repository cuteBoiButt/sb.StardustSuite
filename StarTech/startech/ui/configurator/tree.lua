--
require "/sys/stardust/skilltree/skilltree.lua"

local function loadItem()
  local itm = player.swapSlotItem()
  if not itm or not itemutil.property(itm, "stardustlib:skillTree") then return pane.dismiss() end
  cfgSlot:setItem(itm)
  player.setSwapSlotItem()
  local title = itemutil.property(itm, "shortdescription") or "(unknown item)"
  metagui.startEvent(function()
    for i=0,5 do
      coroutine.yield()
      metagui.setTitle(title)
    end
  end)
  return itm
end

local function saveItem(itm)
  --[[ apply stats
  local stats = { }
  util.appendLists(stats, itemutil.baseProperty(itm, "statusEffects"))
  util.appendLists(stats, {
    { stat = "protection", amount = calc(skillData.stats.armor) },
    { stat = "maxHealth", amount = calc(skillData.stats.health) - 100 },
    { stat = "maxEnergy", amount = calc(skillData.stats.energy) - 100 },
    { stat = "powerMultiplier", baseMultiplier = calc(skillData.stats.damage) },
    --{ stat = "healthRegen", amount = 1 },
    { stat = "stardustlib:leech", amount = calc(skillData.stats.leech) },
  })
  util.appendLists(stats, skillData.effects) -- carry over node status effects
  itm.parameters.statusEffects = stats -- ]]
  local skillData = itm.parameters["stardustlib:skillData"]
  local calc = skilltree.calculateFinalStat
  
  itm.parameters.tooltipFields = itm.parameters.tooltipFields or { }
  
  local category = itemutil.property(itm, "category")
  if category == "startech:power.weapon" then -- pulse weapon
    local dmg = calc(skillData.stats.damage) * calc(skillData.stats.speed)
    local tier = dmg*2 - 1
    itm.parameters.level = tier
    itm.parameters.tooltipFields.bottomLabel = string.format(
      "%s ^lightgray;power (tier ^white;%s^lightgray;)",
      skilltree.displayNumber(dmg, true),
      skilltree.displayNumber(tier)
    )
  end
  
  cfgSlot:setItem(nil) --see https://github.com/zetaPRIME/sb.StardustSuite/pull/25
  cfgSlot:setItem(itm)
end

function init()
  skilltree.initFromItem(treeCanvas, loadItem, saveItem)
end

function apply:onClick() skilltree.applyChanges() end
function reset:onClick()
  if player.isAdmin() and metagui.checkShift() then
    return skilltree.refundAll()
  end
  skilltree.resetChanges()
end

if debugAP then
  function debugAP:onEnter()
    player.setProperty("stardustlib:ap", tonumber(debugAP.text))
    skilltree.recalculateStats()
  end
end

function toggleStats:onClick()
  sidebarContainer:setVisible(not sidebarContainer.visible)
  self:setText(sidebarContainer.visible and "<" or ">")
end

function update()
  -- ...
end

function uninit()
  local itm = cfgSlot:item()
  if itm then player.giveItem(itm) end
end

--function cfgSlot:acceptsItem(itm) return (itm or {count=0}).count == 0 end
function cfgSlot:onItemModified()
  pane.dismiss()
end
