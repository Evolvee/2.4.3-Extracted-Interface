SECURITYMATRIX_NUM_ROWS = 10;
SECURITYMATRIX_NUM_COLUMNS = 8;
SECURITYMATRIX_GRID_SIZE = 32;
SECURITYMATRIX_CELL_HIGHLIGHT_SCALE = 1.2; --2.0 is good for 64 pixel cells, 0.8 is good for 32 pixel cells
SECURITYMATRIX_GRID_OVERLAP = 6;
SECURITYMATRIX_HIGHLIGHT_OVERHANG = 4;
SECURITYMATRIX_PINWHEEL_BUTTON_SIZE = 32;
SECURITYMATRIX_PINWHEEL_VERTICAL_OFFSET = 18;

SecurityMatrix_Alphabet = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'};

SecurityMatrix_currentColumn = 1;
SecurityMatrix_currentRow = 1;
SecurityMatrix_currentValue = 0;
SecurityMatrix_isMoving = false;
SecurityMatrix_updateSpeed = 0.005;

function SecurityMatrix_CreateHeaders()
	local prevFrame = nil;
	for i=1, SECURITYMATRIX_NUM_ROWS do
		local newFrame = CreateFrame("Frame", "$parentRowHeader"..i, SecurityMatrixFrame, "SecurityMatrixHeaderElementTextFrameTemplate");
		if(i == 1) then
			newFrame:SetPoint("TOPLEFT", 0, -(SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP));
		else
			newFrame:SetPoint("TOP", prevFrame, "BOTTOM", 0, SECURITYMATRIX_GRID_OVERLAP);
		end
		newFrame:SetWidth(SECURITYMATRIX_GRID_SIZE);
		newFrame:SetHeight(SECURITYMATRIX_GRID_SIZE);
		getglobal("SecurityMatrixFrameRowHeader"..i.."Text"):SetText(i);
		getglobal("SecurityMatrixFrameRowHeader"..i):SetID(i);
		prevFrame = newFrame;
	end
	for i=1, SECURITYMATRIX_NUM_COLUMNS do
		local newFrame = CreateFrame("Frame", "$parentColumnHeader"..i, SecurityMatrixFrame, "SecurityMatrixHeaderElementTextFrameTemplate");
		if(i == 1) then
			newFrame:SetPoint("TOPLEFT", (SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP), 0);
		else
			newFrame:SetPoint("LEFT", prevFrame, "RIGHT", -SECURITYMATRIX_GRID_OVERLAP, 0);
		end
		newFrame:SetWidth(SECURITYMATRIX_GRID_SIZE);
		newFrame:SetHeight(SECURITYMATRIX_GRID_SIZE);
		getglobal("SecurityMatrixFrameColumnHeader"..i.."Text"):SetText(SecurityMatrix_Alphabet[i]);
		getglobal("SecurityMatrixFrameColumnHeader"..i):SetID(i);
		prevFrame = newFrame;
	end
end

function SecurityMatrix_CreateElements()
	local prevFrame = nil;
	--loop through all the rows
	for i=1, SECURITYMATRIX_NUM_ROWS do
		--loop through all the columns
		for j=1, SECURITYMATRIX_NUM_COLUMNS do
			--create a new frame and name it with a suffix of column+row
			local newBackgroundFrame = CreateFrame("Frame", "$parentElement"..i.."_"..j, SecurityMatrixFrame, "SecurityMatrixElementFrameTemplate");
			local newSparkleFrame = CreateFrame("Frame", "$parentElementSparkle"..i.."_"..j, SecurityMatrixFrame, "SecurityMatrixElementSparkleFrameTemplate");
			--if this is the first frame then anchor it to the top left of the parent frame
			if(j == 1) then
				newBackgroundFrame:SetPoint("TOPLEFT", (SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP), -((SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)*(i)));
			else
				newBackgroundFrame:SetPoint("LEFT", prevBackgroundFrame, "RIGHT", -SECURITYMATRIX_GRID_OVERLAP, 0);
			end
			--increment the frame layer for each frame so that they tile a little nicer
			newBackgroundFrame:SetFrameLevel(i*SECURITYMATRIX_NUM_COLUMNS + j + 10);
			--set the width/height here so we can change it easily without having to find it in the XML
			newBackgroundFrame:SetWidth(SECURITYMATRIX_GRID_SIZE);
			newBackgroundFrame:SetHeight(SECURITYMATRIX_GRID_SIZE);
			--line the text frame and highlight up with the background frame
			newSparkleFrame:SetAllPoints(newBackgroundFrame);
			getglobal("SecurityMatrixFrameElementSparkle"..i.."_"..j.."Highlight"):SetModelScale(SECURITYMATRIX_CELL_HIGHLIGHT_SCALE);
			getglobal("SecurityMatrixFrameElementSparkle"..i.."_"..j.."Highlight"):SetWidth(SECURITYMATRIX_GRID_SIZE);
			getglobal("SecurityMatrixFrameElementSparkle"..i.."_"..j.."Highlight"):SetHeight(SECURITYMATRIX_GRID_SIZE);
			prevBackgroundFrame = newBackgroundFrame;
		end
	end
end

function SecurityMatrix_NewCoordinate(row, column)
	--start the movement animation
	SecurityMatrix_isMoving = true;
	
	--turn off the sparkle on the old cell
	getglobal("SecurityMatrixFrameElementSparkle"..SecurityMatrix_currentRow.."_"..SecurityMatrix_currentColumn.."Highlight"):Hide();
	getglobal("SecurityMatrixFrameElementSparkle"..SecurityMatrix_currentRow.."_"..SecurityMatrix_currentColumn.."Texture"):Hide();
	
	--turn off the text highlight on the old row/column headers
	getglobal("SecurityMatrixFrameRowHeader"..SecurityMatrix_currentRow.."Text"):SetText(getglobal("SecurityMatrixFrameRowHeader"..SecurityMatrix_currentRow):GetID());
	getglobal("SecurityMatrixFrameColumnHeader"..SecurityMatrix_currentColumn.."Text"):SetText(SecurityMatrix_Alphabet[getglobal("SecurityMatrixFrameColumnHeader"..SecurityMatrix_currentColumn):GetID()]);
	
	--set the new row/column
	SecurityMatrix_currentRow = row;
	SecurityMatrix_currentColumn = column;
	
	--turn on the sparkle on the new cell
	getglobal("SecurityMatrixFrameElementSparkle"..SecurityMatrix_currentRow.."_"..SecurityMatrix_currentColumn.."Highlight"):Show();
	getglobal("SecurityMatrixFrameElementSparkle"..SecurityMatrix_currentRow.."_"..SecurityMatrix_currentColumn.."Texture"):Show();
	
	--turn on the text highlight on the new row/column headers
	getglobal("SecurityMatrixFrameRowHeader"..SecurityMatrix_currentRow.."Text"):SetText("|cFF00FF00"..getglobal("SecurityMatrixFrameRowHeader"..SecurityMatrix_currentRow):GetID().."|r");
	getglobal("SecurityMatrixFrameColumnHeader"..SecurityMatrix_currentColumn.."Text"):SetText("|cFF00FF00"..SecurityMatrix_Alphabet[getglobal("SecurityMatrixFrameColumnHeader"..SecurityMatrix_currentColumn):GetID()].."|r");
	
	--set the direction text to mention the new cell
	SecurityMatrixKeypadDirections:SetText(string.format(SECURITYMATRIX_ENTER_CELL, SecurityMatrix_Alphabet[SecurityMatrix_currentColumn], SecurityMatrix_currentRow));
	
	--set a flag so the update function knows we are just starting a move
	SecurityMatrix_startMoving = true;
end

function SecurityMatrix_GetNewCoordinates()
	--get the next set of coordinates
	local notDone, x, y = GetMatrixCoordinates();
	--if we are done entering numbers then hide the matrix
	if(not notDone) then
		SecurityMatrixLoginFrame:Hide();
		return;
	end
	--move to the next set of coordinates
	SecurityMatrix_NewCoordinate(y + 1, x + 1);
end

function SecurityMatrix_ButtonClick()
	--show a star to the user and send the number to the client
	if(not SecurityMatrixKeypadEntryLeftDigit:IsVisible()) then
		SecurityMatrixKeypadEntryLeftDigit:Show();
	elseif(not SecurityMatrixKeypadEntryRightDigit:IsVisible()) then
		SecurityMatrixKeypadEntryRightDigit:Show();
		--enable the OK button if we have both digits
		SecurityMatrixKeypadButtonOK:Enable();
	end
	MatrixEntered(this:GetID());
	--enable the clear button if it's not already
	SecurityMatrixKeypadButtonClear:Enable();
end

function SecurityMatrix_OKClick()
	--don't move on to the next coordinate if this one is not filled in
	if(not SecurityMatrixKeypadEntryRightDigit:IsVisible()) then return; end
	--clear the *s
	SecurityMatrixKeypadEntryLeftDigit:Hide();
	SecurityMatrixKeypadEntryRightDigit:Hide();
	--enter the coordinates
	MatrixCommit();
	SecurityMatrix_GetNewCoordinates();
	--disable the OK button until we have two digits from the user
	SecurityMatrixKeypadButtonOK:Disable();
	SecurityMatrixKeypadButtonClear:Disable();
end

function SecurityMatrix_ClearClick()
	MatrixRevert();
	--hide the current cell *s
	SecurityMatrixKeypadEntryLeftDigit:Hide();
	SecurityMatrixKeypadEntryRightDigit:Hide();
	--disable the clear and OK buttons
	SecurityMatrixKeypadButtonClear:Disable();
	SecurityMatrixKeypadButtonOK:Disable();
end

function SecurityMatrix_OnLoad()
	SecurityMatrixFrame.timeSinceLastUpdate = 0;
	SecurityMatrix_CreateElements();
	SecurityMatrix_CreateHeaders();
	
	SecurityMatrixFrameHorizontalHighlightSlider:SetWidth((SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)*(SECURITYMATRIX_NUM_COLUMNS+1) + (SECURITYMATRIX_HIGHLIGHT_OVERHANG + SECURITYMATRIX_GRID_OVERLAP));
	SecurityMatrixFrameHorizontalHighlightSlider:SetHeight(SECURITYMATRIX_GRID_SIZE+SECURITYMATRIX_HIGHLIGHT_OVERHANG*2);
	SecurityMatrixFrameVerticalHighlightSlider:SetHeight((SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)*(SECURITYMATRIX_NUM_ROWS+1) + (SECURITYMATRIX_HIGHLIGHT_OVERHANG + SECURITYMATRIX_GRID_OVERLAP));
	SecurityMatrixFrameVerticalHighlightSlider:SetWidth(SECURITYMATRIX_GRID_SIZE+SECURITYMATRIX_HIGHLIGHT_OVERHANG*2);
	SecurityMatrixFrame:SetWidth((SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)*(SECURITYMATRIX_NUM_COLUMNS+1) + (SECURITYMATRIX_HIGHLIGHT_OVERHANG + SECURITYMATRIX_GRID_OVERLAP));
	SecurityMatrixFrame:SetHeight((SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)*(SECURITYMATRIX_NUM_ROWS+1) + (SECURITYMATRIX_HIGHLIGHT_OVERHANG + SECURITYMATRIX_GRID_OVERLAP));
end

function SecurityMatrixLoginFrame_OnLoad()
	SecurityMatrixLoginFrame:RegisterEvent("PLAYER_ENTER_MATRIX");
	SecurityMatrixLoginFrame:EnableKeyboard(true);
	
	SecurityMatrixLoginFrame:SetWidth(SecurityMatrixFrame:GetWidth() + SecurityMatrixKeypadFrame:GetWidth() + 16);
	SecurityMatrixLoginFrame:SetHeight(math.max(SecurityMatrixFrame:GetHeight(), SecurityMatrixKeypadFrame:GetHeight()) + 58);
	SecurityMatrixKeypadDirections:SetPoint("TOPLEFT", SecurityMatrixFrame, "TOPRIGHT", 4, -4);
	SecurityMatrixKeypadDirections:SetPoint("BOTTOMRIGHT", SecurityMatrixKeypadFrame, "TOPRIGHT", -4, 4);
	
	SecurityMatrixKeypadButtonOK:Disable();
	SecurityMatrixKeypadButtonClear:Disable();
end

function SecurityMatrixLoginFrame_OnEvent()
	if(event == "PLAYER_ENTER_MATRIX") then
		SECURITYMATRIX_NUM_COLUMNS = arg1;
		SECURITYMATRIX_NUM_ROWS = arg2;
		SecurityMatrixLoginFrame_OnLoad();
		SecurityMatrix_OnLoad();
		SecurityMatrix_GetNewCoordinates();
		SecurityMatrixLoginFrame:Show();
	end
end

function SecurityMatrix_OnUpdateFade(elapsed)
	--don't do anything if the security matrix isn't currently fading in
	if(not SecurityMatrix_isMoving) then
		this.timeSinceLastUpdate = 0;
		return;
	end
	
	--if this is the first run then setup the highlights
	if(SecurityMatrix_startMoving) then
		--move the highlight bars to the appropriate location and fade them all the way out
		SecurityMatrixFrameHorizontalHighlightSlider:SetPoint("TOPLEFT", 0, -((SecurityMatrix_currentRow)*(SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)-SECURITYMATRIX_HIGHLIGHT_OVERHANG));
		SecurityMatrixFrameVerticalHighlightSlider:SetPoint("TOPLEFT", ((SecurityMatrix_currentColumn)*(SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)-SECURITYMATRIX_HIGHLIGHT_OVERHANG), 0);
		SecurityMatrixFrameHorizontalHighlightSlider:SetAlpha(0.0);
		SecurityMatrixFrameVerticalHighlightSlider:SetAlpha(0.0);
		SecurityMatrix_startMoving = false;
	end
	
	--update the time since our last update
	this.timeSinceLastUpdate = this.timeSinceLastUpdate + elapsed;
	--keep the fading frame rate independant, increasing 1% every update
	while(this.timeSinceLastUpdate > SecurityMatrix_updateSpeed) do
		if(SecurityMatrixFrameVerticalHighlightSlider:GetAlpha() ~= 1.0) then
			SecurityMatrixFrameVerticalHighlightSlider:SetAlpha(SecurityMatrixFrameVerticalHighlightSlider:GetAlpha() + 0.01);
		elseif(SecurityMatrixFrameHorizontalHighlightSlider:GetAlpha() ~= 1.0) then
			SecurityMatrixFrameHorizontalHighlightSlider:SetAlpha(SecurityMatrixFrameHorizontalHighlightSlider:GetAlpha() + 0.01);
		else
			SecurityMatrix_isMoving = false;
		end
		this.timeSinceLastUpdate = this.timeSinceLastUpdate - SecurityMatrix_updateSpeed;
	end
end

function SecurityMatrix_OnUpdateSlide(elapsed)
	--don't do anything if the security matrix isn't currently moving
	if(not SecurityMatrix_isMoving) then
		this.timeSinceLastUpdate = 0;
		return;
	end
	
	--if this is the first run then setup the slider
	if(SecurityMatrix_startMoving) then
		--set the new row/column goal coordinates (so we don't have to keep calculating them over and over)
		SecurityMatrixFrame.goalHorizontalOffset = -((SecurityMatrix_currentRow)*(SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)-SECURITYMATRIX_HIGHLIGHT_OVERHANG);
		SecurityMatrixFrame.goalVerticalOffset = ((SecurityMatrix_currentColumn)*(SECURITYMATRIX_GRID_SIZE-SECURITYMATRIX_GRID_OVERLAP)-SECURITYMATRIX_HIGHLIGHT_OVERHANG);
		SecurityMatrix_startMoving = false;
	end
	
	--make the sliders visible, otherwise the fade code will make the sliders invisible
	SecurityMatrixFrameHorizontalHighlightSlider:SetAlpha(1.0);
	SecurityMatrixFrameVerticalHighlightSlider:SetAlpha(1.0);
	
	--update the time since our last update
	this.timeSinceLastUpdate = this.timeSinceLastUpdate + elapsed;
	--keep the animation frame rate independant moving every 0.01 seconds
	while(this.timeSinceLastUpdate > SecurityMatrix_updateSpeed) do
		--get the current yOffset for the horizontal highlight
		horizontalPoint, horizontalRelativeTo, horizontalRelativePoint, horizontalXOfs, horizontalYOfs = SecurityMatrixFrameHorizontalHighlightSlider:GetPoint(1)
		--fix the floating point errors in WoW UI coordinates
		horizontalYOfs = floor(horizontalYOfs+0.5);
		--if the horizontal highlight is below the target row then move it up
		if(horizontalYOfs < this.goalHorizontalOffset) then
			SecurityMatrixFrameHorizontalHighlightSlider:ClearAllPoints();
			SecurityMatrixFrameHorizontalHighlightSlider:SetPoint("TOPLEFT", 0, horizontalYOfs + 1);
		--if the horizontal highlight is above the target row then move it down
		elseif(horizontalYOfs > this.goalHorizontalOffset) then
			SecurityMatrixFrameHorizontalHighlightSlider:ClearAllPoints();
			SecurityMatrixFrameHorizontalHighlightSlider:SetPoint("TOPLEFT", 0, horizontalYOfs - 1);
		end
		
		--get the current yOffset for the horizontal highlight
		verticalPoint, verticalRelativeTo, verticalRelativePoint, verticalXOfs, verticalYOfs = SecurityMatrixFrameVerticalHighlightSlider:GetPoint(1)
		--fix the floating point errors in WoW UI coordinates
		verticalXOfs = floor(verticalXOfs+0.5);
		--if the vertical highlight is below the target row then move it up
		if(verticalXOfs+0.5 < this.goalVerticalOffset) then
			SecurityMatrixFrameVerticalHighlightSlider:ClearAllPoints();
			SecurityMatrixFrameVerticalHighlightSlider:SetPoint("TOPLEFT", verticalXOfs + 1, 0);
		--if the vertical highlight is above the target row then move it down
		elseif(verticalXOfs > this.goalVerticalOffset) then
			SecurityMatrixFrameVerticalHighlightSlider:ClearAllPoints();
			SecurityMatrixFrameVerticalHighlightSlider:SetPoint("TOPLEFT", verticalXOfs - 1, 0);
		end
		
		--check to see if we are done moving
		if(verticalXOfs == this.goalVerticalOffset and horizontalYOfs == this.goalHorizontalOffset) then
			SecurityMatrix_isMoving = false;
		end
		
		--we are done with this update frame, go on to the next
		this.timeSinceLastUpdate = this.timeSinceLastUpdate - SecurityMatrix_updateSpeed;
	end
end

function SecurityMatrixPinwheel_OnLoad()
	this.angle = 36 * this:GetID();
	this.timeSinceLastUpdate = 0;
	this:SetWidth(SECURITYMATRIX_PINWHEEL_BUTTON_SIZE);
	this:SetHeight(SECURITYMATRIX_PINWHEEL_BUTTON_SIZE);
	this:SetPoint("CENTER", SecurityMatrixKeypadFrame, "CENTER", (-(SECURITYMATRIX_PINWHEEL_BUTTON_SIZE*2) * math.cos(this.angle * (math.pi/180))), (15+(SECURITYMATRIX_PINWHEEL_BUTTON_SIZE*2) * math.sin(this.angle * (math.pi/180))));
end

function SecurityMatrixPinwheel_OnShow()
	this.stopSpinning = false;
end

function SecurityMatrixPinwheel_OnHide()
	this.stopSpinning = true;
end

function SecurityMatrixPinwheel_OnUpdate()
	if(this.stopSpinning) then
		this.timeSinceLastUpdate = 0;
		return;
	end
	
	local cursorX, cursorY = GetCursorPosition(SecurityMatrixKeypadFrame);
	local centerX, centerY = SecurityMatrixKeypadFrame:GetCenter();
	xOffset = cursorX - centerX;
	yOffset = cursorY - centerY - SECURITYMATRIX_PINWHEEL_VERTICAL_OFFSET;
	distance = math.sqrt(xOffset*xOffset + yOffset*yOffset);
	
	this.timeSinceLastUpdate = this.timeSinceLastUpdate + arg1;
	while(this.timeSinceLastUpdate > 0.01) do
		this.timeSinceLastUpdate = this.timeSinceLastUpdate - 0.01;
		if(SecurityMatrixKeypadFrame.superSpin) then
			this.angle = this.angle + 3;
		else
			this.angle = this.angle + (distance - SECURITYMATRIX_PINWHEEL_BUTTON_SIZE*2)/100;
		end
		if(this.angle > 360) then
			this.angle = this.angle-360;
		end
		this:ClearAllPoints();
		this:SetPoint("CENTER", SecurityMatrixKeypadFrame, "CENTER", (-(SECURITYMATRIX_PINWHEEL_BUTTON_SIZE*2) * math.cos(this.angle * (math.pi/180))), (SECURITYMATRIX_PINWHEEL_VERTICAL_OFFSET+(SECURITYMATRIX_PINWHEEL_BUTTON_SIZE*2) * math.sin(this.angle * (math.pi/180))));
	end
end

function SecurityMatrixPinwheel_HideNumbers()
	for i=0, 9, 1 do
		button = getglobal("SecurityMatrixPinwheelButton"..i);
		button:SetText("");
		button.stopSpinning = true;
	end
end

function SecurityMatrixPinwheel_ShowNumbers()
	for i=0, 9, 1 do
		button = getglobal("SecurityMatrixPinwheelButton"..i);
		button:SetText(i);
		button.stopSpinning = false;
	end
end
