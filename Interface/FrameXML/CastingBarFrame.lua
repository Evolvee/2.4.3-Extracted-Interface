CASTING_BAR_ALPHA_STEP = 0.05;
CASTING_BAR_FLASH_STEP = 0.2;
CASTING_BAR_HOLD_TIME = 1;

function CastingBarFrame_OnLoad(unit, showTradeSkills)
	this:RegisterEvent("UNIT_SPELLCAST_START");
	this:RegisterEvent("UNIT_SPELLCAST_STOP");
	this:RegisterEvent("UNIT_SPELLCAST_FAILED");
	this:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
	this:RegisterEvent("UNIT_SPELLCAST_DELAYED");
	this:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	this:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
	this:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");

	this.unit = unit;
	this.showTradeSkills = showTradeSkills;
	this.casting = nil;
	this.channeling = nil;
	this.holdTime = 0;
	this.showCastbar = true;

	local barIcon = getglobal(this:GetName().."Icon");
	barIcon:Hide();
end

function CastingBarFrame_OnEvent(newevent, newarg1)
	if ( newevent == "PLAYER_ENTERING_WORLD" ) then
		local nameChannel  = UnitChannelInfo(this.unit);
		local nameSpell  = UnitCastingInfo(this.unit);
		if ( nameChannel ) then
			newevent = "UNIT_SPELLCAST_CHANNEL_START";
			newarg1 = this.unit;
		elseif ( nameSpell ) then
			newevent = "UNIT_SPELLCAST_START";
			newarg1 = this.unit;
		end
	end

	if ( newarg1 ~= this.unit ) then
		return;
	end

	local barSpark = getglobal(this:GetName().."Spark");
	local barText = getglobal(this:GetName().."Text");
	local barFlash = getglobal(this:GetName().."Flash");
	local barIcon = getglobal(this:GetName().."Icon");

	if ( newevent == "UNIT_SPELLCAST_START" ) then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(this.unit);
		if ( not name or (not this.showTradeSkills and isTradeSkill)) then
			this:Hide();
			return;
		end

		this:SetStatusBarColor(1.0, 0.7, 0.0);
		barSpark:Show();
		this.startTime = startTime / 1000;
		this.maxValue = endTime / 1000;

		-- startTime to maxValue		no endTime
		this:SetMinMaxValues(this.startTime, this.maxValue);
		this:SetValue(this.startTime);
		barText:SetText(text);
		barIcon:SetTexture(texture);
		this:SetAlpha(1.0);
		this.holdTime = 0;
		this.casting = 1;
		this.channeling = nil;
		this.fadeOut = nil;
		if ( this.showCastbar ) then
			this:Show();
		end

	elseif ( newevent == "UNIT_SPELLCAST_STOP" or newevent == "UNIT_SPELLCAST_CHANNEL_STOP" ) then
		if ( not this:IsVisible() ) then
			this:Hide();
		end
		if ( this:IsShown() ) then
			barSpark:Hide();
			barFlash:SetAlpha(0.0);
			barFlash:Show();
			this:SetValue(this.maxValue);
			if ( newevent == "UNIT_SPELLCAST_STOP" ) then
				this:SetStatusBarColor(0.0, 1.0, 0.0);
				this.casting = nil;
			else
				this.channeling = nil;
			end
			this.flash = 1;
			this.fadeOut = 1;
			this.holdTime = 0;
		end
	elseif ( newevent == "UNIT_SPELLCAST_FAILED" or newevent == "UNIT_SPELLCAST_INTERRUPTED" ) then
		if ( this:IsShown() and not this.channeling ) then
			this:SetValue(this.maxValue);
			this:SetStatusBarColor(1.0, 0.0, 0.0);
			barSpark:Hide();
			if ( newevent == "UNIT_SPELLCAST_FAILED" ) then
				barText:SetText(FAILED);
			else
				barText:SetText(INTERRUPTED);
			end
			this.casting = nil;
			this.channeling = nil;
			this.fadeOut = 1;
			this.holdTime = GetTime() + CASTING_BAR_HOLD_TIME;
		end
	elseif ( newevent == "UNIT_SPELLCAST_DELAYED" ) then
		if ( this:IsShown() ) then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(this.unit);
			if ( not name or (not this.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				this:Hide();
				return;
			end
			this.startTime = startTime / 1000;
			this.maxValue = endTime / 1000;
			this:SetMinMaxValues(this.startTime, this.maxValue);
		end
	elseif ( newevent == "UNIT_SPELLCAST_CHANNEL_START" ) then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(this.unit);
		if ( not name or (not this.showTradeSkills and isTradeSkill)) then
			-- if there is no name, there is no bar
			this:Hide();
			return;
		end

		this:SetStatusBarColor(0.0, 1.0, 0.0);
		barSpark:Show();
		this.startTime = startTime / 1000;
		this.endTime = endTime / 1000;
		this.duration = this.endTime - this.startTime;
		this.maxValue = this.startTime;

		-- startTime to endTime		no maxValue
		this:SetMinMaxValues(this.startTime, this.endTime);
		this:SetValue(this.endTime);
		barText:SetText(text);
		barIcon:SetTexture(texture);
		this:SetAlpha(1.0);
		this.holdTime = 0;
		this.casting = nil;
		this.channeling = 1;
		this.fadeOut = nil;
		if ( this.showCastbar ) then
			this:Show();
		end
	elseif ( newevent == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then
		if ( this:IsShown() ) then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(this.unit);
			if ( not name or (not this.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				this:Hide();
				return;
			end
			this.startTime = startTime / 1000;
			this.endTime = endTime / 1000;
			this.maxValue = this.startTime;
			this:SetMinMaxValues(this.startTime, this.endTime);
		end
	end
end

function CastingBarFrame_OnUpdate()
	local barSpark = getglobal(this:GetName().."Spark");
	local barFlash = getglobal(this:GetName().."Flash");

	if ( this.casting ) then
		local status = GetTime();
		if ( status > this.maxValue ) then
			status = this.maxValue;
		end
		if ( status == this.maxValue ) then
			this:SetValue(this.maxValue);
			this:SetStatusBarColor(0.0, 1.0, 0.0);
			barSpark:Hide();
			barFlash:SetAlpha(0.0);
			barFlash:Show();
			this.casting = nil;
			this.flash = 1;
			this.fadeOut = 1;
			return;
		end
		this:SetValue(status);
		barFlash:Hide();
		local sparkPosition = ((status - this.startTime) / (this.maxValue - this.startTime)) * this:GetWidth();
		if ( sparkPosition < 0 ) then
			sparkPosition = 0;
		end
		barSpark:SetPoint("CENTER", this, "LEFT", sparkPosition, 2);
	elseif ( this.channeling ) then
		local time = GetTime();
		if ( time > this.endTime ) then
			time = this.endTime;
		end
		if ( time == this.endTime ) then
			this:SetStatusBarColor(0.0, 1.0, 0.0);
			barSpark:Hide();
			barFlash:SetAlpha(0.0);
			barFlash:Show();
			this.channeling = nil;
			this.flash = 1;
			this.fadeOut = 1;
			return;
		end
		local barValue = this.startTime + (this.endTime - time);
		this:SetValue( barValue );
		barFlash:Hide();
		local sparkPosition = ((barValue - this.startTime) / (this.endTime - this.startTime)) * this:GetWidth();
		barSpark:SetPoint("CENTER", this, "LEFT", sparkPosition, 2);
	elseif ( GetTime() < this.holdTime ) then
		return;
	elseif ( this.flash ) then
		local alpha = barFlash:GetAlpha() + CASTING_BAR_FLASH_STEP;
		if ( alpha < 1 ) then
			barFlash:SetAlpha(alpha);
		else
			barFlash:SetAlpha(1.0);
			this.flash = nil;
		end
	elseif ( this.fadeOut ) then
		local alpha = this:GetAlpha() - CASTING_BAR_ALPHA_STEP;
		if ( alpha > 0 ) then
			this:SetAlpha(alpha);
		else
			this.fadeOut = nil;
			this:Hide();
		end
	end
end
