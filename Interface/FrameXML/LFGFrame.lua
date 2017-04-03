MAX_LFGS_FROM_SERVER = 50;
LFGS_TO_DISPLAY = 15;
NUM_LFG_CRITERIA = 3;
LFG_SET_COMMENT_THROTTLE = 3;
LFM_REFRESH_UPDATE_THROTTLE = 0.5;
LFG_REFRESH_UPDATE_THROTTLE = 0.5;
LFG_DISABLED_DROPDOWN_NAMES = {};
LFG_DISABLED_DROPDOWN_NAMES[1] = {};
LFG_DISABLED_DROPDOWN_NAMES[2] = {};
LFG_DISABLED_DROPDOWN_NAMES[3] = {};

----------------------------- LFG Parent Functions -----------------------------
function LFGParentFrame_OnLoad()
	PanelTemplates_SetNumTabs(this, 2);
	LFGParentFrame.selectedTab = 1;
	PanelTemplates_UpdateTabs(this);
	this:RegisterEvent("PARTY_MEMBERS_CHANGED");
end

function LFGParentFrame_OnEvent(event)
	if ( event == "PARTY_MEMBERS_CHANGED" ) then
		LFGParentFrame_UpdateTabs();
	end
end

function ToggleLFGParentFrame(tab)
	local hideLFGParent;
	if ( LFGParentFrame:IsShown() and tab == LFGParentFrame.selectedTab and LFGParentFrameTab1:IsVisible() ) then
		hideLFGParent = 1;
	end
	if ( LFGParentFrame:IsShown() and not tab ) then
		hideLFGParent = 1;
	end

	if ( hideLFGParent ) then
		HideUIPanel(LFGParentFrame);
	else
		ShowUIPanel(LFGParentFrame);
		-- Decide which subframe to show
		if ( not LFGParentFrame_UpdateTabs() ) then
			local _, _, _, _, _, _, _, _, _, queued, lfgStatus, lfmStatus = GetLookingForGroup();
			if ( queued or tab ) then
				if ( lfgStatus or tab == 1 ) then
					LFGParentFrameTab1_OnClick();
				else
					LFGParentFrameTab2_OnClick();
				end
			else
				LFGFrame:Hide();
				LFMFrame:Hide();
				LFGParentFrameTab1:Hide();
				LFGParentFrameTab2:Hide();
				LFGWizardFrame:Show();
			end
		end
	end
	UpdateMicroButtons();
end

function LFGParentFrameTab1_OnClick()
	PanelTemplates_SetTab(LFGParentFrame, 1);
	LFGFrame:Show();
	LFMFrame:Hide();
	LFGWizardFrame:Hide();
	PlaySound("igMainMenuOpen");
end

function LFGParentFrameTab2_OnClick()
	PanelTemplates_SetTab(LFGParentFrame, 2);
	LFGFrame:Hide();
	LFMFrame:Show();
	LFGWizardFrame:Hide();
	PlaySound("igMainMenuOpen");
end

-- Disable the LFG tab if the player is in a party
function LFGParentFrame_UpdateTabs()
	if ( GetNumPartyMembers() > 0 ) then
		LFGParentFrameTab2_OnClick();
		PanelTemplates_DisableTab(LFGParentFrame, 1);
		return 1;
	else
		PanelTemplates_EnableTab(LFGParentFrame, 1);
		return nil;
	end
end

----------------------------- Wizard Functions -----------------------------
function LFGWizardFrame_OnShow()
	LFGParentFrameBackground:SetTexture("Interface\\LFGFrame\\LFGParentFrame");
	LFGParentFrameTitle:SetText(LFGWIZARD_TITLE);
end

----------------------------- LFM Functions -----------------------------
function LFMFrame_OnShow()
	LFGParentFrameBackground:SetTexture("Interface\\LFGFrame\\LFMFrame");
	LFMFrame_Update();
	LFGParentFrameTab1:Show();
	LFGParentFrameTab2:Show();
	LFGParentFrameTitle:SetText(LFM_TITLE);
end

function LFMFrame_OnLoad()
	this:RegisterEvent("UPDATE_LFG_TYPES");
	-- Event for entire list
	this:RegisterEvent("UPDATE_LFG_LIST");
	this:RegisterEvent("MEETINGSTONE_CHANGED");
end

function LFMFrame_OnEvent(event)
	if ( event == "UPDATE_LFG_LIST" or event == "UPDATE_LFG_TYPES" or event == "MEETINGSTONE_CHANGED" ) then
		LFMFrame_Update();
	end
end

function LFMFrame_Update()
	local selectedLFMType = UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown);
	local selectedLFMName = UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown);
	local numResults, totalCount = GetNumLFGResults(selectedLFMType, selectedLFMName);
	local name, level, zone, class, criteria1, criteria2, criteria3, comment, numPartyMembers;
	local button;
	local scrollOffset = FauxScrollFrame_GetOffset(LFMListScrollFrame);
	local resultIndex;
	local showScrollBar = nil;
	local zoneText;
	if ( numResults > LFGS_TO_DISPLAY ) then
		showScrollBar = 1;
	end
	local displayedText = "";
	if ( totalCount > MAX_LFGS_FROM_SERVER ) then
		displayedText = format(WHO_FRAME_SHOWN_TEMPLATE, MAX_WHOS_FROM_SERVER);
	end
	LFMFrameTotals:SetText(format(GetText("WHO_FRAME_TOTAL_TEMPLATE", nil, totalCount), totalCount).."  "..displayedText);
	for i=1, LFGS_TO_DISPLAY, 1 do
		resultIndex = scrollOffset + i;
		button = getglobal("LFMFrameButton"..i);
		button.lfgIndex = resultIndex;
		
		if ( resultIndex <= numResults ) then
			name, level, zone, class, criteria1, criteria2, criteria3, comment, numPartyMembers, isLFM = GetLFGResults(selectedLFMType, selectedLFMName, resultIndex);
			
			if ( name ) then
				getglobal("LFMFrameButton"..i.."Name"):SetText(name);
				getglobal("LFMFrameButton"..i.."Level"):SetText(level);
				getglobal("LFMFrameButton"..i.."Class"):SetText(class);
				zoneText = getglobal("LFMFrameButton"..i.."Zone");
				zoneText:SetText(zone);
					
				-- Show the party leader icon if necessary
				if ( numPartyMembers > 0 ) then
					getglobal("LFMFrameButton"..i.."PartyIcon"):Show();
				else	
					getglobal("LFMFrameButton"..i.."PartyIcon"):Hide();
				end

				-- Set info for the tooltip
				button.isLFM = isLFM;
				button.nameLine = format(LFM_NAME_TEMPLATE, name, level, class);
				button.zone = zone;
				button.criteria = BuildNewLineListString(criteria1, criteria2, criteria3);
				button.comment = comment;
				button.partyMembers = numPartyMembers;
				
				-- If need scrollbar resize columns
				if ( showScrollBar ) then
					zoneText:SetWidth(102);
				else
					zoneText:SetWidth(117);
				end

				-- Highlight the correct lfm
				if ( LFMFrame.selectedLFM == resultIndex ) then
					LFMFrame.selectedName = name;
					button:LockHighlight();
				else
					button:UnlockHighlight();
				end
				button:Show();
			end
		else
			button:Hide();
		end
	end

	-- Update send message and group invite buttons
	if ( LFMFrame.selectedName and (LFMFrame.selectedName ~= UnitName("player")) ) then
		LFMFrameSendMessageButton:Enable();
		if ( CanGroupInvite() ) then
			LFMFrameGroupInviteButton:Enable();
		else
			LFMFrameGroupInviteButton:Disable();
		end
	else
		LFMFrameSendMessageButton:Disable();
		LFMFrameGroupInviteButton:Disable();
	end

	-- If need scrollbar resize columns
	if ( showScrollBar ) then
		WhoFrameColumn_SetWidth(105, LFMFrameColumnHeader2);
	else
		WhoFrameColumn_SetWidth(120, LFMFrameColumnHeader2);
	end

	-- ScrollFrame update
	FauxScrollFrame_Update(LFMListScrollFrame, numResults, LFGS_TO_DISPLAY, 16);

	-- Update the search dropdowns
	local _, _, _, _, _, _, lfmType, lfmName, _, queued, _, lfmStatus, autoaddStatus = GetLookingForGroup();
	-- Set LFM settings
	-- Set the LFM Type DropDown
	UIDropDownMenu_Initialize(LFMFrameTypeDropDown, LFMFrameTypeDropDown_Initialize);
	if ( (GetNumPartyMembers() > 0 and IsPartyLeader() and AutoAddMembersCheckButton:GetChecked() and AutoAddMembersCheckButton:IsEnabled()) or not LFGFrame.loaded ) then
		SetLFMTypeCriteria(lfmType);
		LFGFrame.loaded = 1;
	end
	if ( queued and lfmStatus and ((GetNumPartyMembers() == 0) or IsPartyLeader())) then
		-- Set the LFM Name DropDown
		UIDropDownMenu_Initialize(LFMFrameNameDropDown, LFMFrameNameDropDown_Initialize);
		UIDropDownMenu_SetSelectedID(LFMFrameNameDropDown, lfmName);
		LFMEye:Show();
	elseif ( GetNumPartyMembers() == 0 ) then
		if ( queued and lfmStatus ) then
			LFMEye:Show();
		else
			LFMEye:Hide();
		end
		UIDropDownMenu_Initialize(LFMFrameNameDropDown, LFMFrameNameDropDown_Initialize);
		if ( lfmName ~= 0 ) then
			UIDropDownMenu_SetSelectedID(LFMFrameNameDropDown, lfmName);
		else
			UIDropDownMenu_ClearAll(LFMFrameNameDropDown);
		end
		
	else
		LFMEye:Hide();
	end
end

function LFMFrame_OnUpdate(elapsed)
	--Enable or disable the refresh button based on CanSendLFGQuery
	if ( LFMFrameSearchButton.refreshTimer >= LFM_REFRESH_UPDATE_THROTTLE ) then
		if ( CanSendLFGQuery(UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown), UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown)) and UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown) ) then
			LFMFrameSearchButton:Enable();
		else
			LFMFrameSearchButton:Disable();
		end
		LFMFrameSearchButton.refreshTimer = 0;

		--If your party is full you can't autoadd
		local _, _, _, _, _, _, _, _, _, queued, lfgStatus, lfmStatus = GetLookingForGroup();
		if ( (queued and lfgStatus) or PartyIsFull() or ((GetNumPartyMembers() > 0) and not IsPartyLeader()) ) then
			LFMFrame_DisableAutoAdd();
		else
			LFMFrame_EnableAutoAdd();
		end
	else
		LFMFrameSearchButton.refreshTimer = LFMFrameSearchButton.refreshTimer + elapsed;
	end
	if ( LFMFrame.doUpdate ) then
		LFMFrame_Update();
		LFMFrame.doUpdate = nil;
	end
end

function LFMFrame_UpdateAutoAdd(autoaddStatus, setCheckbox)
	if ( autoaddStatus and AutoAddMembersCheckButton:IsEnabled() ) then
		SetLFMAutofill();
	else
		ClearLFMAutofill();
	end
	if ( setCheckbox ) then
		AutoAddMembersCheckButton:SetChecked(autoaddStatus);
	end
	LFM_AUTO_ADD = autoaddStatus;
end

function LFMButton_OnClick(button)
	if ( button == "LeftButton" ) then
		LFMFrame.selectedLFM = getglobal("LFMFrameButton"..this:GetID()).lfgIndex;
		LFGFrame.selectedName = getglobal("LFMFrameButton"..this:GetID().."Name"):GetText();
		LFMFrame_Update();
	end
end

function LFMButton_OnEnter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 27, -37);
	if ( this.isLFM ) then
		GameTooltip:SetText(LFM_TITLE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	else
		GameTooltip:SetText(LFG_TITLE, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	
	GameTooltip:AddLine(this.nameLine);
	local numPartyMembers = this.partyMembers;
	if ( numPartyMembers > 0 ) then
		GameTooltip:AddTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon");
	end
	if ( numPartyMembers > 0 ) then
		local lfmType = UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown);
		local lfmName = UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown);
		local name, level, class;
		for i=1, numPartyMembers do
			name, level, class = GetLFGPartyResults(lfmType, lfmName, this.lfgIndex, i);
			if ( name ) then
				GameTooltip:AddLine(format(LFM_NAME_TEMPLATE, name, level, class));
				-- Bogus texture to make the spacing correct
				GameTooltip:AddTexture("");
			end
		end
	end
	GameTooltip:AddLine("\n"..this.criteria, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	if ( this.comment and this.comment ~= "" ) then
		GameTooltip:AddLine("\n"..this.comment, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
	GameTooltip:Show();
	
end

-- Type Dropdown stuff
function LFMFrameTypeDropDown_Initialize()
	Dropdown_GetLFMTypes(GetLFGTypes());
end

function Dropdown_GetLFMTypes(...)
	local info = UIDropDownMenu_CreateInfo();
	for i=1, select("#", ...), 1 do
		info.text = select(i, ...);
		info.func = LFMTypeButton_OnClick;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end

function LFMTypeButton_OnClick()
	SetLFMTypeCriteria(this:GetID());
end

function SetLFMTypeCriteria(id)
	if ((id ~= UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown)) and UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown)) then
		UIDropDownMenu_ClearAll(LFMFrameNameDropDown);
	end
	UIDropDownMenu_SetSelectedID(LFMFrameTypeDropDown, id);
	if ( id == 1 ) then
		ClearLookingForMore();
		LFMFrame.doUpdate = 1;
	end
end

-- Entryname Dropdown stuff
function LFMFrameNameDropDown_Initialize()
	if ( UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown) ) then
		Dropdown_GetLFMTypeNames(GetLFGTypeEntries(UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown)));
	end
end

function Dropdown_GetLFMTypeNames(...)
	local info = UIDropDownMenu_CreateInfo();
	for i=1, select("#", ...), 2 do
		info.text = select(i, ...);
		info.func = LFMNameButton_OnClick;
		info.owner = UIDROPDOWNMENU_OPEN_MENU;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end

function LFMNameButton_OnClick()
	UIDropDownMenu_SetSelectedID(LFMFrameNameDropDown, this:GetID());
	if ( not PartyIsFull() ) then
		SetLookingForMore(UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown), UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown));
	end
	SendLFGQuery();
end

--Wrapper function for the LFGQuery function to determine whether can query for new information or if throttled
--If throttled just get the old information so that the ui seems responsive
function SendLFGQuery()
	if ( CanSendLFGQuery(UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown), UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown)) ) then
		LFGQuery(UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown), UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown));
	else
		LFMFrame_Update();		
	end	
end

function LFMFrameSearchButton_OnClick()
	if ( not PartyIsFull() and (AutoAddMembersCheckButton:GetChecked() and AutoAddMembersCheckButton:IsEnabled()) ) then
		SetLookingForMore(UIDropDownMenu_GetSelectedID(LFMFrameTypeDropDown), UIDropDownMenu_GetSelectedID(LFMFrameNameDropDown));
	end
	SendLFGQuery();
end

function LFMFrame_DisableAutoAdd()
	AutoAddMembersCheckButton:Disable();
	AutoAddMembersCheckButtonText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	AutoAddMembersCheckButtonTooltipFrame:Show();
end

function LFMFrame_EnableAutoAdd()
	AutoAddMembersCheckButton:Enable();
	AutoAddMembersCheckButtonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	AutoAddMembersCheckButtonTooltipFrame:Hide();
end

----------------------------- LFG Functions -----------------------------
function LFGFrame_OnLoad()
	LFGFrame.firstTimeShown = 1;
	this:RegisterEvent("LFG_UPDATE");
	this:RegisterEvent("MEETINGSTONE_CHANGED");
	LFGFrame.refreshTimer = 0;
end

function LFGFrame_OnEvent(event)
	if ( event == "LFG_UPDATE" or event == "MEETINGSTONE_CHANGED" ) then
		LFGFrame_Update();
	end
end

function LFGFrame_OnShow()
	LFGParentFrameBackground:SetTexture("Interface\\LFGFrame\\LFGFrame");
	LFGParentFrameTab1:Show();
	LFGParentFrameTab2:Show();
	LFGParentFrameTitle:SetText(LFG_TITLE);
	LFGFrame_Update();
	LFGFrame_UpdateDropDowns();
end

function LFGFrame_OnHide()
	-- Save the comment when you hide the LFGFrame
	LFGFrame_SetLFGComment();
	LFGComment.sendTimer = nil;
end

function LFGFrame_OnUpdate(elapsed)
	--Send the comment into the system after the throttle time has passed, if something has changed in the editbox
	if ( LFGComment.sendTimer ) then
		if ( LFGComment.sendTimer >= LFG_SET_COMMENT_THROTTLE ) then
			LFGFrame_SetLFGComment();
			LFGComment.sendTimer = nil;
		else
			LFGComment.sendTimer = LFGComment.sendTimer + elapsed;
		end
	end
	--Upate the state of autojoin
	--If your party is full you can't autojoin
	if ( LFGFrame.refreshTimer >= LFG_REFRESH_UPDATE_THROTTLE ) then
		local _, _, _, _, _, _, _, _, _, queued, lfgStatus, lfmStatus = GetLookingForGroup();
		if ( (queued and lfmStatus) or PartyIsFull() ) then
			LFGFrame_DisableAutoJoin();
		else
			LFGFrame_EnableAutoJoin();
		end
		LFGFrame.refreshTimer = 0;
	else
		LFGFrame.refreshTimer = LFGFrame.refreshTimer + elapsed;
	end
end

function LFGFrame_Update()
	local type1, name1, type2, name2, type3, name3, lfmType, lfmName, comment, queued, lfgStatus, lfmStatus, autoaddStatus = GetLookingForGroup();
	-- Set LFG settings
	if ( type1 ) then
		UIDropDownMenu_Initialize(LFGFrameTypeDropDown1, LFGFrameTypeDropDown_Initialize);
		SetLFGTypeCriteria(LFGFrameTypeDropDown1, type1);
		UIDropDownMenu_Initialize(LFGFrameNameDropDown1, LFGFrameNameDropDown1_Initialize);
		SetLFGNameCriteria(LFGFrameNameDropDown1, name1, UIDropDownMenu_GetValue(name1), 1);
	end
	if ( type2 ) then
		UIDropDownMenu_Initialize(LFGFrameTypeDropDown2, LFGFrameTypeDropDown_Initialize);
		SetLFGTypeCriteria(LFGFrameTypeDropDown2, type2);
		UIDropDownMenu_Initialize(LFGFrameNameDropDown2, LFGFrameNameDropDown2_Initialize);
		SetLFGNameCriteria(LFGFrameNameDropDown2, name2, UIDropDownMenu_GetValue(name2), 1);
	end
	if ( type3 ) then
		UIDropDownMenu_Initialize(LFGFrameTypeDropDown3, LFGFrameTypeDropDown_Initialize);
		SetLFGTypeCriteria(LFGFrameTypeDropDown3, type3);
		UIDropDownMenu_Initialize(LFGFrameNameDropDown3, LFGFrameNameDropDown3_Initialize);
		SetLFGNameCriteria(LFGFrameNameDropDown3, name3, UIDropDownMenu_GetValue(name3), 1);
	end

	if ( comment and comment ~= "" ) then
		LFGComment:SetText(comment);
	else
		LFGComment:SetText(CLICK_TO_ENTER_COMMENT);
	end
	LFGFrame_UpdateAutoJoin();
	-- Show/Hide Eye
	if ( queued and lfgStatus ) then
		LFGEye:Show();
	else
		LFGEye:Hide();
	end
	LFMFrame_UpdateAutoAdd(autoaddStatus, 1);
end

function LFGFrame_UpdateDropDowns()
	if ( UIDropDownMenu_GetSelectedID(LFGFrameNameDropDown1) ~= 0 ) then
		LFGFrame.firstTimeShown = nil;
	end
	if ( LFGFrame.firstTimeShown ) then
		LFGLabel2:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		UIDropDownMenu_DisableDropDown(LFGFrameTypeDropDown2);
		UIDropDownMenu_DisableDropDown(LFGFrameNameDropDown2);
		LFGLabel3:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		UIDropDownMenu_DisableDropDown(LFGFrameTypeDropDown3);
		UIDropDownMenu_DisableDropDown(LFGFrameNameDropDown3);
		LFGFrame.firstTimeShown = nil;
		return;
	end
	
	-- If a type is selected then enable the name dropdown
	if ( UIDropDownMenu_GetSelectedID(LFGFrameTypeDropDown1) ~= 0 ) then
		UIDropDownMenu_EnableDropDown(LFGFrameNameDropDown1);
	end	

	-- If a name is selected in the first dropdown then enable the second set of dropdowns
	if ( UIDropDownMenu_GetSelectedID(LFGFrameNameDropDown1) and UIDropDownMenu_GetSelectedID(LFGFrameNameDropDown1) ~= 0 ) then
		LFGLabel2:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		UIDropDownMenu_EnableDropDown(LFGFrameTypeDropDown2);
	end

	-- If a type is selected then enable the name dropdown
	if ( UIDropDownMenu_GetSelectedID(LFGFrameTypeDropDown2) ~= 0 and UIDropDownMenu_IsEnabled(LFGFrameTypeDropDown2) ) then
		UIDropDownMenu_EnableDropDown(LFGFrameNameDropDown2);
	end	
	
	-- If a name is selected in the second dropdown then enable the second set of dropdowns
	if ( UIDropDownMenu_GetSelectedID(LFGFrameNameDropDown2) and UIDropDownMenu_GetSelectedID(LFGFrameNameDropDown2) ~= 0 ) then
		LFGLabel3:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		UIDropDownMenu_EnableDropDown(LFGFrameTypeDropDown3);
	end	

	-- If a type is selected then enable the name dropdown
	if ( UIDropDownMenu_GetSelectedID(LFGFrameTypeDropDown3) ~= 0 and UIDropDownMenu_IsEnabled(LFGFrameTypeDropDown3)) then
		UIDropDownMenu_EnableDropDown(LFGFrameNameDropDown3);
	end
end

function LFGFrame_UpdateAutoJoin()
	if ( AutoJoinCheckButton:GetChecked() and AutoJoinCheckButton:IsEnabled() ) then
		SetLFGAutojoin();
	else
		ClearLFGAutojoin();
	end
	LFG_AUTO_JOIN = AutoJoinCheckButton:GetChecked();
end

function LFGFrame_DisableAutoJoin()
	AutoJoinCheckButton:Disable();
	AutoJoinCheckButtonText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
	AutoJoinCheckButtonTooltipFrame:Show();
end

function LFGFrame_EnableAutoJoin()
	AutoJoinCheckButton:Enable();
	AutoJoinCheckButtonText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	AutoJoinCheckButtonTooltipFrame:Hide();
end

-- Type Dropdown stuff
function LFGFrameTypeDropDown_Initialize()
	Dropdown_GetLFGTypes(GetLFGTypes());
end

function Dropdown_GetLFGTypes(...)
	local info = UIDropDownMenu_CreateInfo();
	local text;
	local autoJoinSet;
	if ( AutoJoinCheckButton:GetChecked() and AutoJoinCheckButton:IsEnabled() ) then
		autoJoinSet = 1;
	end
	for i=1, select("#", ...), 1 do
		text = select(i, ...);
		-- Add autojoin to the end if auto join is set;
		if ( text == LFG_TYPE_DUNGEON and autoJoinSet ) then
			text = text.."  "..GRAY_FONT_COLOR_CODE.."("..AUTO_JOIN..")"..FONT_COLOR_CODE_CLOSE;
		end
		info.text = text;
		info.func = LFGTypeButton_OnClick;
		info.owner = UIDROPDOWNMENU_OPEN_MENU;
		info.checked = nil;
		UIDropDownMenu_AddButton(info);
	end
end

function LFGTypeButton_OnClick()
	SetLFGTypeCriteria(getglobal(this.owner), this:GetID());
	LFGFrame_UpdateDropDowns();
end

-- Function to set the type criteria for the lfg frame
function SetLFGTypeCriteria(dropdown, id)
	-- If the selected type is "none" then clear out the looking for group
	if ( id == 1 ) then
		SetLookingForGroup(dropdown:GetID(), 1, 0);
	end
	
	UIDropDownMenu_SetSelectedID(dropdown, id);
	local dropdownID = dropdown:GetID();
	local nameDropDown = getglobal("LFGFrameNameDropDown"..dropdownID);
	LFG_DISABLED_DROPDOWN_NAMES[dropdownID].type = id;
	nameDropDown.selectedType = id
	if ( UIDropDownMenu_GetSelectedID(nameDropDown)) then
		UIDropDownMenu_ClearAll(nameDropDown);
		getglobal("LFGSearchIcon"..dropdownID):SetTexture("");
	end
end

-- Entryname Dropdown stuff
function LFGFrameNameDropDown1_Initialize()
	local selectedType = UIDropDownMenu_GetSelectedID(LFGFrameTypeDropDown1);
	if ( selectedType ) then
		Dropdown_GetLFGTypeNames(LFGFrameTypeDropDown1, GetLFGTypeEntries(selectedType));
	end
end
function LFGFrameNameDropDown2_Initialize()
	local selectedType = UIDropDownMenu_GetSelectedID(LFGFrameTypeDropDown2);
	if ( selectedType ) then
		Dropdown_GetLFGTypeNames(LFGFrameTypeDropDown2, GetLFGTypeEntries(selectedType));
	end
end
function LFGFrameNameDropDown3_Initialize()
	local selectedType = UIDropDownMenu_GetSelectedID(LFGFrameTypeDropDown3);
	if ( selectedType ) then
		Dropdown_GetLFGTypeNames(LFGFrameTypeDropDown3, GetLFGTypeEntries(selectedType));
	end
end

function Dropdown_GetLFGTypeNames(...)
	local info = UIDropDownMenu_CreateInfo();
	local typeDropdown = select(1, ...);
	local dropdownID = typeDropdown:GetID();
	local selectedType = UIDropDownMenu_GetSelectedID(typeDropdown);
	local index;
	for i=2, select("#", ...), 2 do
		index = i/2;
		info.text = select(i, ...);
		info.value = select(i+1, ...);
		info.func = LFGNameButton_OnClick;
		info.owner = UIDROPDOWNMENU_OPEN_MENU;
		info.checked = nil;
		info.disabled = nil;
		for j=1, #LFG_DISABLED_DROPDOWN_NAMES do
			if ( j ~= dropdownID ) then
				if ( LFG_DISABLED_DROPDOWN_NAMES[j].type == selectedType and LFG_DISABLED_DROPDOWN_NAMES[j].name == index ) then
					info.disabled = 1;
				end
			end
		end
		UIDropDownMenu_AddButton(info);
	end
end

function LFGNameButton_OnClick()
	SetLFGNameCriteria(getglobal(this.owner), this:GetID(), this.value);
	LFGFrame_UpdateDropDowns();
end

-- Function to set the name criteria for the lfg frame
function SetLFGNameCriteria(dropdown, id, icon, doNotSetLookingForGroup)
	local dropdownID = dropdown:GetID();
	if ( not doNotSetLookingForGroup ) then
		SetLookingForGroup(dropdownID, dropdown.selectedType, id);
		if ( LFGComment.sendTimer ) then
			LFGFrame_SetLFGComment();
			LFGComment.sendTimer = nil;
		end
	end

	UIDropDownMenu_SetSelectedID(dropdown, id);
	LFG_DISABLED_DROPDOWN_NAMES[dropdownID].name = id;

	local iconTexture = getglobal("LFGSearchIcon"..dropdownID);
	local iconPath = "Interface\\LFGFrame\\LFGIcon-";
	local selectedText = "";
	if ( UIDropDownMenu_GetText(getglobal("LFGFrameNameDropDown"..dropdownID)) ) then
		selectedText = UIDropDownMenu_GetText(getglobal("LFGFrameTypeDropDown"..dropdownID));
	end
	if ( icon and icon ~= "" ) then
		icon = iconPath..icon;
	elseif ( selectedText == LFG_TYPE_QUEST ) then
		icon = iconPath.."Quest";
	elseif ( selectedText == LFG_TYPE_DUNGEON ) then
		icon = iconPath.."Dungeon";
	elseif ( selectedText == LFG_TYPE_RAID ) then
		icon = iconPath.."Raid";
	elseif ( selectedText == LFG_TYPE_ZONE ) then
		icon = iconPath.."Zone";
	elseif ( selectedText == LFG_TYPE_BATTLEGROUND ) then
		icon = iconPath.."BattleGround";
	end

	-- If finally have an icon then start the shine
	if ( icon and icon ~= "" ) then
		--AnimatedShine_Start(iconTexture, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	else
		icon = "";
	end
	iconTexture:SetTexture(icon);
end

function LFGFrameClearAllButton_OnClick()
	SetLFGComment("");
	ClearLookingForGroup();
	LFGFrame_Update();
	LFGComment:SetText(CLICK_TO_ENTER_COMMENT);
	LFGComment:ClearFocus();
end

function LFGFrame_SetLFGComment()
	local commentText;
	if ( LFGComment:GetText() ~= CLICK_TO_ENTER_COMMENT ) then
		commentText = LFGComment:GetText();
	end
	SetLFGComment(commentText);
end
