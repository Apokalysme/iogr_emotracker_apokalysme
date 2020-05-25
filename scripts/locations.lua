-- use "$openModeON"
function openModeON()
    if Tracker:ProviderCountForCode("setting_open_mode_ON") > 0 then
		return 1
	else
		return 0
	end
end

-- use "$chaosMode"
function chaosMode()
	if Tracker:ProviderCountForCode("setting_mode_chaos") > 0 then
		return 1
	else
		return 0
	end
end

-- use $oneWillAbility
function oneWillAbility()
	dash = Tracker:ProviderCountForCode("psycho_dash")
	pdash = Tracker:ProviderCountForCode("powerful_dash")
	slide = Tracker:ProviderCountForCode("psycho_slide")
	spin = Tracker:ProviderCountForCode("spin_dash")
	
	if ( dash > 0 or slide > 0 or spin > 0 or pdash > 0 ) then
		return 1
	else
		return 0
	end
end

-- use $incanStatues
function incanStatues()
	statue_a = Tracker:ProviderCountForCode("inca_statue_a")
	statue_b = Tracker:ProviderCountForCode("inca_statue_b")
	
	if ( statue_a > 0 and statue_b > 0 ) then
		return 1
	else
		return 0
	end
end

-- use $incaDungeon
function incaDungeon()
	ability = oneWillAbility()
	statues = incanStatues()
	block = Tracker:ProviderCountForCode("diamond_block")
	wind = Tracker:ProviderCountForCode("melody_wind")
	
	if ( ability > 0 and statues > 0 and block > 0 and wind > 0 ) then
		return 1
	else
		return 0
	end
end

-- use $allMineKeys
function allMineKeys()
	key_a = Tracker:ProviderCountForCode("mine_key_a")
	key_b = Tracker:ProviderCountForCode("mine_key_b")
	elevator = Tracker:ProviderCountForCode("elevator_key")
	
	if ( key_a > 0 and key_b > 0 and elevator > 0 ) then
		return 1
	else
		return 0
	end
end

-- use "$skyGarden"
function skyGarden()
	if Tracker:ProviderCountForCode("crystal_ball") == 4 then
		return 1
	else
		return 0
	end
end

