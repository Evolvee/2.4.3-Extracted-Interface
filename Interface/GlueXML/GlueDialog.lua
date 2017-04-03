
GlueDialogTypes = { };

GlueDialogTypes["REALM_IS_FULL"] = {
	text = TEXT(REALM_IS_FULL_WARNING),
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	showAlert = 1,
	OnAccept = function()
		SetGlueScreen("charselect");
		ChangeRealm(RealmList.selectedCategory , RealmList.currentRealm);
	end,
	OnCancel = function()
		CharacterSelect_ChangeRealm();
	end,
}

GlueDialogTypes["SUGGEST_REALM"] = {
	text = TEXT(format(SUGGESTED_REALM_TEXT,"UNKNOWN REALM")),
	button1 = TEXT(ACCEPT),
	button2 = TEXT(VIEW_ALL_REALMS),
	OnShow = function()
		GlueDialogText:SetText(format(SUGGESTED_REALM_TEXT, RealmWizard.suggestedRealmName));
	end,
	OnAccept = function()
		SetGlueScreen("charselect");
		ChangeRealm(RealmWizard.suggestedCategory, RealmWizard.suggestedID);
	end,
	OnCancel = function()
		SetGlueScreen("charselect");
		CharacterSelect_ChangeRealm();
	end,
}

GlueDialogTypes["DISCONNECTED"] = {
	text = TEXT(DISCONNECTED),
	button1 = TEXT(OKAY),
	button2 = nil,
	OnShow = function()
		RealmList:Hide();
		VirtualKeypadFrame:Hide();
		SecurityMatrixLoginFrame:Hide();
		StatusDialogClick();
	end,
	OnAccept = function()
	end,
	OnCancel = function()
	end,
}

GlueDialogTypes["INVALID_NAME"] = {
	text = TEXT(CHAR_CREATE_INVALID_NAME),
	button1 = TEXT(OKAY),
	button2 = nil,
	OnAccept = function()
	end,
	OnCancel = function()
	end,
}

GlueDialogTypes["CANCEL"] = {
	text = "",
	button1 = TEXT(CANCEL),
	button2 = nil,
	OnAccept = function()
		StatusDialogClick();
	end,
	OnCancel = function()
	end,
}

GlueDialogTypes["OKAY"] = {
	text = "",
	button1 = TEXT(OKAY),
	button2 = nil,
	OnShow = function()
		VirtualKeypadFrame:Hide();
		StatusDialogClick();
	end,
	OnAccept = function()
		StatusDialogClick();
	end,
	OnCancel = function()
	end,
}

GlueDialogTypes["OKAY_WITH_URL"] = {
	text = "",
	button1 = TEXT(HELP),
	button2 = TEXT(OKAY),
	OnAccept = function()
		LaunchURL(getglobal(GlueDialog.data));
	end,
	OnCancel = function()
		StatusDialogClick();
	end,
}

GlueDialogTypes["CONNECTION_HELP"] = {
	text = "",
	button1 = TEXT(HELP),
	button2 = TEXT(OKAY),
	OnShow = function()
		VirtualKeypadFrame:Hide();
		StatusDialogClick();
	end,
	OnAccept = function()
		AccountLoginUI:Hide();
		ConnectionHelpFrame:Show();
	end,
	OnCancel = function()
	end,
}

GlueDialogTypes["CINEMATICS"] = {
	text = TEXT(CINEMATICS),
	button1 = TEXT(WORLD_OF_WARCRAFT),
	button2 = TEXT(BURNING_CRUSADE),
	displayVertical = true,
	escapeHides = true,

	OnAccept = function()
		MovieFrame.version = 1;
--		PlaySound("gsTitleIntroMovie");
		SetGlueScreen("movie");
	end,
	OnCancel = function()
		MovieFrame.version = 2;
--		PlaySound("gsTitleIntroMovie");
		SetGlueScreen("movie");
	end,
}

GlueDialogTypes["CLIENT_ACCOUNT_MISMATCH"] = {
	text = TEXT(CLIENT_ACCOUNT_MISMATCH),
	button1 = TEXT(RETURN_TO_LOGIN),
	button2 = TEXT(EXIT_GAME),
	html = 1,
	OnAccept = function()
		SetGlueScreen("login");
	end,
	OnCancel = function()
		PlaySound("gsTitleQuit");
		QuitGame();
	end,
}


GlueDialogTypes["SCANDLL_DOWNLOAD"] = {
	text = "",
	button1 = TEXT(QUIT),
	button2 = nil,
	OnAccept = function()
		AccountLogin_Exit();
	end,
	OnCancel = function()
	end,
}

GlueDialogTypes["SCANDLL_ERROR"] = {
	text = "",
	button1 = TEXT(SCANDLL_BUTTON_CONTINUEANYWAY),
	button2 = TEXT(QUIT),
	OnAccept = function()
		GlueDialog:Hide();
		ScanDLLContinueAnyway();
		AccountLoginUI:Show();
	end,
	OnCancel = function()
		-- Opposite semantics
		AccountLogin_Exit();
	end,
}

GlueDialogTypes["SCANDLL_HACKFOUND"] = {
	text = "",
	button1 = TEXT(SCANDLL_BUTTON_MOREINFO),
	button2 = TEXT(QUIT),
	OnAccept = function()
		LaunchURL(getglobal(GlueDialog.data));
		AccountLogin_Exit();
	end,
	OnCancel = function()
		AccountLogin_Exit();
	end,
}

function GlueDialog_Show(which, text, data)
	local dialogInfo = GlueDialogTypes[which];
	-- Pick a free dialog to use
	if ( GlueDialog:IsVisible() ) then
		if ( GlueDialogTypes[GlueDialog.which].OnHide ) then
			GlueDialogTypes[GlueDialog.which].OnHide();	
		end
	end

	GlueDialog.data = data;
	local glueText;
	if ( dialogInfo.html ) then
		glueText = GlueDialogHTML;
		GlueDialogHTML:Show();
		GlueDialogText:Hide();
	else
		glueText = GlueDialogText;
		GlueDialogHTML:Hide();
		GlueDialogText:Show();
	end
	
	-- Set the text of the dialog
	if ( text ) then
		glueText:SetText(text);
	else
		glueText:SetText(dialogInfo.text);
	end

	-- Get the height of the string
	local textHeight, _;
	if ( dialogInfo.html ) then
		_,_,_,textHeight = GlueDialogHTML:GetBoundsRect();
	else
		textHeight = GlueDialogText:GetHeight();
	end

	-- Set the buttons of the dialog
	if ( dialogInfo.button2 ) then
		GlueDialogButton1:ClearAllPoints();
		GlueDialogButton2:ClearAllPoints();
	
		if ( dialogInfo.displayVertical ) then
			GlueDialogButton2:SetPoint("BOTTOM", "GlueDialogBackground", "BOTTOM", 0, 16);
			GlueDialogButton1:SetPoint("BOTTOM", "GlueDialogButton2", "TOP", 0, 0);
		else
			GlueDialogButton1:SetPoint("BOTTOMRIGHT", "GlueDialogBackground", "BOTTOM", -6, 16);
			GlueDialogButton2:SetPoint("LEFT", "GlueDialogButton1", "RIGHT", 13, 0);
		end

		GlueDialogButton2:SetText(dialogInfo.button2);
		GlueDialogButton2:Show();
	else
		GlueDialogButton1:ClearAllPoints();
		GlueDialogButton1:SetPoint("BOTTOM", "GlueDialogBackground", "BOTTOM", 0, 16);
		GlueDialogButton2:Hide();
	end

	GlueDialogButton1:SetText(dialogInfo.button1);

	-- Set the miscellaneous variables for the dialog
	GlueDialog.which = which;
	GlueDialog.data = data;

	-- Show or hide the alert icon
	if ( dialogInfo.showAlert ) then
		GlueDialogBackground:SetWidth(600);
		GlueDialogAlertIcon:Show();
	else
		GlueDialogBackground:SetWidth(512);
		GlueDialogAlertIcon:Hide();
	end

	-- Editbox setup
	if ( dialogInfo.hasEditBox ) then
		GlueDialogEditBox:Show();
		if ( dialogInfo.maxLetters ) then
			GlueDialogEditBox:SetMaxLetters(dialogInfo.maxLetters);
		end
		if ( dialogInfo.maxBytes ) then
			GlueDialogEditBox:SetMaxBytes(dialogInfo.maxBytes);
		end
	else
		GlueDialogEditBox:Hide();
	end

	-- Finally size and show the dialog
	if ( dialogInfo.hasEditBox ) then
		GlueDialogBackground:SetHeight(16 + textHeight + 8 + GlueDialogEditBox:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif( dialogInfo.displayVertical ) then
		GlueDialogBackground:SetHeight(16 + textHeight + 8 + GlueDialogButton1:GetHeight() + 8 + GlueDialogButton2:GetHeight() + 16);
		GlueDialogBackground:SetWidth(16 + GlueDialogButton1:GetWidth() + 16);
	else
		GlueDialogBackground:SetHeight(16 + textHeight + 8 + GlueDialogButton1:GetHeight() + 16);
	end
		
	GlueDialog:Show();
end

function GlueDialog_OnLoad()
	this:RegisterEvent("OPEN_STATUS_DIALOG");
	this:RegisterEvent("UPDATE_STATUS_DIALOG");
	this:RegisterEvent("CLOSE_STATUS_DIALOG");
end

function GlueDialog_OnShow()
	local OnShow = GlueDialogTypes[this.which].OnShow;
	if ( OnShow ) then
		OnShow();
	end
end

function GlueDialog_OnEvent()
	if ( event == "OPEN_STATUS_DIALOG" ) then
		GlueDialog_Show(arg1, arg2, arg3);
	elseif ( event == "UPDATE_STATUS_DIALOG" and arg1 and (strlen(arg1) > 0) ) then
		GlueDialogText:SetText(arg1);
		local buttonText = nil;
		if ( arg2 ) then
			buttonText = arg2;
		elseif ( GlueDialogTypes[GlueDialog.which] ) then
			buttonText = GlueDialogTypes[GlueDialog.which].button1;
		end
		if ( buttonText ) then
			GlueDialogButton1:SetText(buttonText);
		end
		GlueDialogBackground:SetHeight(32 + GlueDialogText:GetHeight() + 8 + GlueDialogButton1:GetHeight() + 16);
	elseif ( event == "CLOSE_STATUS_DIALOG" ) then
		GlueDialog:Hide();
	end
end

function GlueDialog_OnHide()
--	PlaySound("igMainMenuClose");
end

function GlueDialog_OnClick(index)
	GlueDialog:Hide();
	if ( index == 1 ) then
		local OnAccept = GlueDialogTypes[GlueDialog.which].OnAccept;
		if ( OnAccept ) then
			OnAccept();
		end
	else
		local OnCancel = GlueDialogTypes[GlueDialog.which].OnCancel;
		if ( OnCancel ) then
			OnCancel();
		end
	end
	PlaySound("gsTitleOptionOK");
end

function GlueDialog_OnKeyDown()
	if ( arg1 == "PRINTSCREEN" ) then
		Screenshot();
		return;
	end

	local info = GlueDialogTypes[GlueDialog.which];
	if ( not info or info.ignoreKeys ) then
		return;
	end

	if ( info and info.escapeHides ) then
		GlueDialog:Hide();
	elseif ( arg1 == "ESCAPE" ) then
		if ( GlueDialogButton2:IsVisible() ) then
			GlueDialogButton2:Click();
		else
			GlueDialogButton1:Click();
		end
	elseif (arg1 == "ENTER" ) then
		GlueDialogButton1:Click();
	end
end
