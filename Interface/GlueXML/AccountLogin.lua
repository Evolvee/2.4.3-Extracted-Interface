FADE_IN_TIME = 2;
DEFAULT_TOOLTIP_COLOR = {0.8, 0.8, 0.8, 0.09, 0.09, 0.09};
MAX_PIN_LENGTH = 10;

function AccountLogin_OnLoad()
	this:SetSequence(0);
	this:SetCamera(0);
	
	TOSFrame.noticeType = "EULA";

	this:RegisterEvent("SHOW_SERVER_ALERT");
	this:RegisterEvent("SHOW_SURVEY_NOTIFICATION");
	this:RegisterEvent("CLIENT_ACCOUNT_MISMATCH");
	this:RegisterEvent("SCANDLL_FINISHED");

	local versionType, buildType, version, internalVersion, date = GetBuildInfo();
	AccountLoginVersion:SetText(format(TEXT(VERSION_TEMPLATE), versionType, version, internalVersion, buildType, date));

	-- Color edit box backdrops
	local backdropColor = DEFAULT_TOOLTIP_COLOR;
	AccountLoginAccountEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	AccountLoginAccountEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	AccountLoginPasswordEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	AccountLoginPasswordEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
end

function AccountLogin_OnShow()
	CurrentGlueMusic = GlueBackgroundMusic[GetClientExpansionLevel()];

	-- Try to show the EULA or the TOS
	AccountLogin_ShowUserAgreements();
	
	local serverName = GetServerName();
	if(serverName) then
		AccountLoginRealmName:SetText(serverName);
	else
		AccountLoginRealmName:Hide()
	end

	local accountName = GetSavedAccountName();
	AccountLoginAccountEdit:SetText(accountName);
	AccountLoginPasswordEdit:SetText("");

	if ( accountName == "" ) then
		AccountLogin_FocusAccountName();
	else
		AccountLogin_FocusPassword();
	end

	-- Set BC logo
	SetLogo( GetClientExpansionLevel() );

	if ( GetClientExpansionLevel() == 2 ) then
		this:SetModel("Interface\\GLUES\\MODELS\\UI_MainMenu_BurningCrusade\\UI_MainMenu_BurningCrusade.mdx");
		this:SetCamera(0);
	end
end

function AccountLogin_FocusPassword()
	AccountLoginPasswordEdit:SetFocus();
end

function AccountLogin_FocusAccountName()
	AccountLoginAccountEdit:SetFocus();
end

function AccountLogin_OnChar()
end

function AccountLogin_OnKeyDown()
	if ( arg1 == "ESCAPE" ) then
		if ( ConnectionHelpFrame:IsVisible() ) then
			ConnectionHelpFrame:Hide();
			AccountLoginUI:Show();
		elseif ( SurveyNotificationFrame:IsVisible() ) then
			-- do nothing
		else
			AccountLogin_Exit();
		end
		
	elseif ( arg1 == "ENTER" ) then
		if ( not TOSAccepted() ) then
			return;
		elseif ( TOSFrame:IsVisible() or ConnectionHelpFrame:IsVisible() ) then
			return;
		elseif ( SurveyNotificationFrame:IsVisible() ) then
			AccountLogin_SurveyNotificationDone(1);
		end
		AccountLogin_Login();
	elseif ( arg1 == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function AccountLogin_OnEvent(event)
	if ( event == "SHOW_SERVER_ALERT" ) then
		ServerAlertText:SetText(arg1);
		ServerAlertScrollFrame:UpdateScrollChildRect();
		ServerAlertFrame:Show();
	elseif ( event == "SHOW_SURVEY_NOTIFICATION" ) then
		AccountLogin_ShowSurveyNotification();
	elseif ( event == "CLIENT_ACCOUNT_MISMATCH" ) then
		local accountExpansionLevel = arg1;
		local installationExpansionLevel = arg2;
		GlueDialog_Show("CLIENT_ACCOUNT_MISMATCH");		
	elseif ( event == "SCANDLL_FINISHED" ) then
		if ( arg1 == "OK" ) then
			GlueDialog:Hide();
			AccountLoginUI:Show();
		else
			local msg = format(getglobal("SCANDLL_MESSAGE_"..arg1), arg2);
			local url = "SCANDLL_URL_"..arg1;
			GlueDialog_Show("SCANDLL_HACKFOUND", msg, url);
			PlaySoundFile("Sound\\Creature\\MobileAlertBot\\MobileAlertBotIntruderAlert01.wav");
		end
	end
end

function AccountLogin_Login()
	PlaySound("gsLogin");
	DefaultServerLogin(AccountLoginAccountEdit:GetText(), AccountLoginPasswordEdit:GetText());
	AccountLoginPasswordEdit:SetText("");
	
	if ( AccountLoginSaveAccountName:GetChecked() ) then
		SetSavedAccountName(AccountLoginAccountEdit:GetText());
	else
		SetSavedAccountName("");
	end
end

function AccountLogin_TOS()
	if ( not GlueDialog:IsVisible() ) then
		PlaySound("gsLoginNewAccount");
		AccountLoginUI:Hide();
		TOSFrame:Show();
		TOSScrollFrame:Show();
		TOSScrollFrameScrollBar:SetValue(0);
		TOSFrameTitle:SetText(TOS_FRAME_TITLE);
		TOSText:Show();
	end
end

function AccountLogin_ManageAccount()
	PlaySound("gsLoginNewAccount");
	LaunchURL(AUTH_NO_TIME_URL);
end

function AccountLogin_LaunchCommunitySite()
	PlaySound("gsLoginNewAccount");
	LaunchURL(COMMUNITY_URL);
end

function AccountLogin_Credits()
	local expansion = GetClientExpansionLevel();
	if ( expansion == 2 ) then
		CreditsFrame.creditsType = 2;
		PlaySound("gsTitleCredits");
		SetGlueScreen("credits");
	else
		CreditsFrame.creditsType = 1;
--		PlaySound("gsTitleCredits");
		SetGlueScreen("credits");
	end
end

function AccountLogin_Cinematics()
	PlaySound("gsLoginNewAccount");
	if ( GetClientExpansionLevel() == 2 ) then
		if ( not GlueDialog:IsVisible() ) then
			GlueDialog_Show("CINEMATICS");
		end
	else
		MovieFrame.version = 1;
--		PlaySound("gsTitleIntroMovie");
		SetGlueScreen("movie");
	end
end

function AccountLogin_Options()
	PlaySound("gsTitleOptions");
end

function AccountLogin_Exit()
--	PlaySound("gsTitleQuit");
	QuitGame();
end

function AccountLogin_ShowSurveyNotification()
	GlueDialog:Hide();
	AccountLoginUI:Hide();
	SurveyNotificationAccept:Enable();
	SurveyNotificationDecline:Enable();
	SurveyNotificationFrame:Show();
end

function AccountLogin_SurveyNotificationDone(accepted)
	SurveyNotificationFrame:Hide();
	SurveyNotificationAccept:Disable();
	SurveyNotificationDecline:Disable();
	SurveyNotificationDone(accepted);
	AccountLoginUI:Show();
end

function AccountLogin_ShowUserAgreements()
	TOSScrollFrame:Hide();
	EULAScrollFrame:Hide();
	ScanningScrollFrame:Hide();
	ContestScrollFrame:Hide();
	TOSText:Hide();
	EULAText:Hide();
	ScanningText:Hide();
	if ( not EULAAccepted() ) then
		if ( ShowEULANotice() ) then
			TOSNotice:SetText(EULA_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "EULA";
		TOSFrameTitle:SetText(EULA_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth() + 310);
		EULAScrollFrame:Show();
		EULAText:Show();
		TOSFrame:Show();
	elseif ( not TOSAccepted() ) then
		if ( ShowTOSNotice() ) then
			TOSNotice:SetText(TOS_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "TOS";
		TOSFrameTitle:SetText(TOS_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth() + 310);
		TOSScrollFrame:Show();
		TOSText:Show();
		TOSFrame:Show();
	elseif ( not ScanningAccepted() and SHOW_SCANNING_AGREEMENT ) then
		if ( ShowScanningNotice() ) then
			TOSNotice:SetText(SCANNING_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "SCAN";
		TOSFrameTitle:SetText(SCAN_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth() + 310);
		ScanningScrollFrame:Show();
		ScanningText:Show();
		TOSFrame:Show();
	elseif ( not ContestAccepted() and SHOW_CONTEST_AGREEMENT ) then
		if ( ShowContestNotice() ) then
			TOSNotice:SetText(CONTEST_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "CONTEST";
		TOSFrameTitle:SetText(CONTEST_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth() + 310);
		ContestScrollFrame:Show();
		ContestText:Show();
		TOSFrame:Show();
	elseif ( not IsScanDLLFinished() ) then
		AccountLoginUI:Hide();
		TOSFrame:Hide();
		local dllURL = "";
		if ( IsWindowsClient() ) then dllURL = SCANDLL_URL_WIN32_SCAN_DLL; end
		ScanDLLStart(SCANDLL_URL_LAUNCHER_TXT, dllURL);
	else
		AccountLoginUI:Show();
		TOSFrame:Hide();
	end
end

-- Virtual keypad functions
function VirtualKeypadFrame_OnEvent(event)
	if ( event == "PLAYER_ENTER_PIN" ) then
		for i=1, 10 do
			getglobal("VirtualKeypadButton"..i):SetText(getglobal("arg"..i));
		end							
	end
	-- Randomize location to prevent hacking (yeah right)
	local xPadding = 5;
	local yPadding = 10;
	local xPos = random(xPadding, GlueParent:GetWidth()-VirtualKeypadFrame:GetWidth()-xPadding);
	local yPos = random(yPadding, GlueParent:GetHeight()-VirtualKeypadFrame:GetHeight()-yPadding);
	VirtualKeypadFrame:SetPoint("TOPLEFT", GlueParent, "TOPLEFT", xPos, -yPos);
	
	VirtualKeypadFrame:Show();
	VirtualKeypad_UpdateButtons();
end

function VirtualKeypadButton_OnClick()
	local text = VirtualKeypadText:GetText();
	if ( not text ) then
		text = "";
	end
	VirtualKeypadText:SetText(text.."*");
	VirtualKeypadFrame.PIN = VirtualKeypadFrame.PIN..this:GetID();
	VirtualKeypad_UpdateButtons();
end

function VirtualKeypadOkayButton_OnClick()
	local PIN = VirtualKeypadFrame.PIN;
	local numNumbers = strlen(PIN);
	local pinNumber = {};
	for i=1, MAX_PIN_LENGTH do
		if ( i <= numNumbers ) then
			pinNumber[i] = strsub(PIN,i,i);
		else
			pinNumber[i] = nil;
		end
	end
	PINEntered(pinNumber[1] , pinNumber[2], pinNumber[3], pinNumber[4], pinNumber[5], pinNumber[6], pinNumber[7], pinNumber[8], pinNumber[9], pinNumber[10]);
	VirtualKeypadFrame:Hide();
end

function VirtualKeypad_UpdateButtons()
	local numNumbers = strlen(VirtualKeypadFrame.PIN);
	if ( numNumbers >= 4 and numNumbers <= MAX_PIN_LENGTH ) then
		VirtualKeypadOkayButton:Enable();
	else
		VirtualKeypadOkayButton:Disable();
	end
	if ( numNumbers == 0 ) then
		VirtualKeypadBackButton:Disable();
	else
		VirtualKeypadBackButton:Enable();
	end
	if ( numNumbers >= MAX_PIN_LENGTH ) then
		for i=1, MAX_PIN_LENGTH do
			getglobal("VirtualKeypadButton"..i):Disable();
		end
	else
		for i=1, MAX_PIN_LENGTH do
			getglobal("VirtualKeypadButton"..i):Enable();
		end
	end
end
