class "Annie"
function Annie:__init()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	Callback.Add("Load", function() self:Load() end)

	self.stacks = 0
	self.stun = false
	self.manapc = 100
	self.enemies = {}

	self.qTarget = myHero
	self.rTarget = myHero

	self.doQ = false
	self.doW = false
	self.doE = false
	self.doR = false

	self.qReady = false
	self.wReady = false
	self.eReady = false
	self.rReady = false

	self:loadMenu()
	self:ThatTable()
	self:EnemiesIntoTablenID()
end

--master yourself, master the enemy.
function Annie:EnemiesIntoTablenID()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		local nID = hero.networkID
		if not hero.isMe then
			if hero.isEnemy then
				self.enemies[nID] = hero
			end
		else
			self.enemies[nID] = hero
		end
	end
end

function Annie:ThatTable()
	self._ = {
		combo = {
			{
				function()
					return self.rTarget and self.stun and self.rReady and self.doR and self:DoMana("Combo", "R")
				end, 
				function() 
					self:CastR(self.rTarget)
				end
			},
			{
				function()
					return self.stacks == 3 and self.eReady and self.doE and self:DoMana("Combo", "E")
				end, 
				function() 
					self:CastE()
				end
			},
			{
				function()
					return self.qTarget and self.qReady and self.doQ and self:DoMana("Combo", "Q")
				end, 
				function() 
					self:CastQ(self.qTarget)
				end
			},
			{
				function()
					return self.qTarget and self.wReady and self.doW and self:DoMana("Combo", "W")
				end, 
				function() 
					self:CastW(self.qTarget)
				end
			},
		},
		harass =  {
			{
				function() 
					return self.qTarget and self.qReady and self.doQ and self:DoMana("Harass", "Q")
				end, 
				function() 
					self:CastQ(self.qTarget)
				end
			},
			{
				function() 
					return self.qTarget and self.wReady and self.doQ and self:DoMana("Harass", "W")
				end, 
				function() 
					self:CastW(self.qTarget)
				end
			},
		},
		auto = {
			{
				function()
					return 
				end,
				function()
			
				end
			},
		}
	}

	self.lastTick = {}
	self.maxTicks = {}
	do self.____ = {} self._____ = {} for k, v in pairs(self._) do self.____[k] = 0 self._____[k] = #v end end
end

function Annie:Advance(___)
	do local __ = ___:lower() local function ______(__) if __[1](_) then __[2](___) end end self.____[__] = self.____[__] + 1 if self.____[__] > self._____[__] then self.____[__] = 1 end ______(self._[__][self.____[__]]) end
end

function Annie:CalcEffectiveHP(unit)
	local effectiveMR = (unit.magicResist * (myHero.magicPenPercent)) - myHero.magicPen
	return (unit.health * (effectiveMR >= 0 and (100/(100 + effectiveMR)) or (2-(100/(100-effectiveMR)))))
end

function Annie:CalcDmg(target, raw)
	local effectiveMR = (target.magicResist * (myHero.magicPenPercent)) - myHero.magicPen
	return (raw * (effectiveMR >= 0 and (100/(100 + effectiveMR)) or (2-(100/(100-effectiveMR)))))
end

function Annie:TargetSelector()
	local qnID = myHero.networkID 
	local rnID = myHero.networkID
	local lowestEffectiveHP = 25000
	local lowestEffectiveHPr = 25000
	local extraRangeVal = self.Config.Combo.rRange:Value()
	for i = 1, Game.HeroCount() do
		local hero = Game.Hero(i)
		local effectiveHP = self:CalcEffectiveHP(hero)
		if hero.isEnemy and not hero.dead and effectiveHP < lowestEffectiveHP then
			if hero.distance < 625 then
				lowestEffectiveHP = effectiveHP
				qnID = hero.networkID
			end
			if hero.distance < extraRangeVal and effectiveHP < lowestEffectiveHPr then
				lowestEffectiveHPr = effectiveHP
				rnID = hero.networkID
			end
		end
	end
	self.qTarget = self.enemies[qnID]
	self.rTarget = self.enemies[rnID]
end

function Annie:TrackBuffs()
	local marker = false
	for i = 1, myHero.buffCount do
		local buff = myHero:GetBuff(i)
		if buff.name == "anniepassiveprimed" then
			marker = true
		end
		if buff.name == "anniepassivestack" then
			self.stacks = buff.count
		end
	end
	if marker then
		self.stun = true
	else 
		self.stun = false
	end
end

function Annie:loadMenu()
	self.Config = MenuElement({id = "Annie", name = "Annie", type = MENU})
		self.Config:MenuElement({id = "Combo", name = "Combo", type = MENU})
			self.Config.Combo:MenuElement({id = "Q", name = "Use Q", value = true})
			self.Config.Combo:MenuElement({id = "W", name = "Use W", value = true})
			self.Config.Combo:MenuElement({id = "E", name = "Use E", value = true})
			self.Config.Combo:MenuElement({id = "R", name = "Use R", value = true})
			self.Config.Combo:MenuElement({id = "rRange", name = "R range", value = 600, min = 600, max = 880, step = 5})
		self.Config:MenuElement({id = "Harass", name = "Harass", type = MENU})
			self.Config.Harass:MenuElement({id = "Q", name = "Use Q", value = true})
			self.Config.Harass:MenuElement({id = "W", name = "Use W", value = true})
		self.Config:MenuElement({id = "Draw", name = "Draw", type = MENU})
			self.Config.Draw:MenuElement({id = "range", name = "Draw Range", value = true})
		self.Config:MenuElement({id = "Mana", name = "Mana", type = MENU})
			self.Config.Mana:MenuElement({id = "Combo", name = "Mana", type = MENU})
				self.Config.Mana.Combo:MenuElement({id = "Q", name = "Q Mana%", value = 0, min = 0, max = 100, step = 1})
				self.Config.Mana.Combo:MenuElement({id = "W", name = "W Mana%", value = 0, min = 0, max = 100, step = 1})
				self.Config.Mana.Combo:MenuElement({id = "E", name = "E Mana%", value = 10, min = 0, max = 100, step = 1})
				self.Config.Mana.Combo:MenuElement({id = "R", name = "R Mana%", value = 0, min = 0, max = 100, step = 1})
			self.Config.Mana:MenuElement({id = "Harass", name = "Mana", type = MENU})
				self.Config.Mana.Harass:MenuElement({id = "Q", name = "Q Mana%", value = 40, min = 0, max = 100, step = 1})
				self.Config.Mana.Harass:MenuElement({id = "W", name = "W Mana%", value = 50, min = 0, max = 100, step = 1})
		self.Config:MenuElement({id = "Keys", name = "Keys", type = MENU})
			self.Config.Keys:MenuElement({id = "Combo", name = "Combo", key = string.byte(" ")})
			self.Config.Keys:MenuElement({id = "Harass", name = "Harass", key = string.byte("C")})
end

function Annie:DoMana(mode, spell)
	return self.Config.Mana[mode][spell]:Value() < self.manapc
end

function Annie:CastQ(unit)
	if unit and unit.isEnemy then
		Control.CastSpell(HK_Q, unit)
	end
end

function Annie:CastW(unit, pos)
	if unit and unit.isEnemy then
		if pos then
			Control.CastSpell(HK_W, pos)
		else
			Control.CastSpell(HK_W, unit)
		end
	end
end

function Annie:CastE()
	Control.CastSpell(HK_E)
end

function Annie:CastR(unit, pos)
	if unit and unit.isEnemy then
		if pos then
			Control.CastSpell(HK_R, pos)
		else
			Control.CastSpell(HK_R, unit)
		end
	end
end

function Annie:Tick()
	for _, v in pairs({"Combo", "Harass"}) do
		if self.Config.Keys[v]:Value() then
			self:Advance(v);break;
		end
	end

	self:TargetSelector()
	self:TrackBuffs()
	self.manapc = myHero.mana/myHero.maxMana*100

	self.qReady = CanUseSpell(0) == READY
	self.wReady = CanUseSpell(1) == READY
	self.eReady = CanUseSpell(2) == READY
	self.rReady = CanUseSpell(3) == READY

	self.doQ = (self.Config.Keys.Combo:Value() and self.Config.Combo.Q:Value()) or (self.Config.Keys.Harass:Value() and self.Config.Harass.Q:Value())
	self.doW = (self.Config.Keys.Combo:Value() and self.Config.Combo.W:Value()) or (self.Config.Keys.Harass:Value() and self.Config.Harass.W:Value())
	self.doE = (self.Config.Keys.Combo:Value() and self.Config.Combo.E:Value())
	self.doR = (self.Config.Keys.Combo:Value() and self.Config.Combo.R:Value())
end

function Annie:Draw()
	if self.Config.Draw.range:Value() then
		Draw.Circle(myHero.pos, 625, Draw.Color(100, 100, 100, 120))
	end
end

Annie()


