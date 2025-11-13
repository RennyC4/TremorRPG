// Character login screen / creation / map transfer
// nameforplayerent = getplayerkeyvalue(csqcplayerent.entnum-1, "name");

string Send_LastLogin;
void() sParms_Write;

void() User_ResumeCharacter_MapTransfer =
{
	string line;

	// read sParms
	float v = fopen("sparms", FILE_READ);
	if (v)
	{
		if (line = fgets(v))
			Send_LastLogin = line;
		fclose(v);
	}

	if (Send_LastLogin) // Send it to SSQC
		sendevent("ResumeCharacterMapTransfer", "s", Send_LastLogin);

	LOGIN_NAME = Send_LastLogin; // set for CSQC's sake
};

void() User_ResumeCharacter =
{
	if (!LOGIN_NAME)
	{
		print("Please enter your past character name\n");
		return;
	}
	else
		sendevent("ResumeCharacter", "s", LOGIN_NAME);
};

void(string sendgender) User_NewCharacter =
{
	if (!LOGIN_NAME)
	{
		print("Please enter a new character name!\n");
		return;
	}
	if (!LOGIN_GENDER)
	{
		print("Please select your gender!\n");
		return;
	}

	sendevent("CreateNewCharacter", "ss", LOGIN_NAME, sendgender);
	sParms_Write(); // write local(client) file for map transfer
};

void(int what) SetGender =
{
	if (!what)
	{
		print("Male selected\n");
		LOGIN_GENDER = "Male";
	}
	else
	{
		print("Female selected\n");
		LOGIN_GENDER = "Female";
	}
};

void() User_LoginScreen =
{
	vector pos = [0, 0];
	vector size = [360, 160];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_pic(pos+[0,-90], [214,115.5], "textures/logo2.png", [1,1,1], 1, 0); // logo
	sui_text([0, 32.5], MENU_TEXT_SMALL, "Desired Name", MENU_TEXT_MEDIUM, 1, 0);

	// Login / New character buttons
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	my_button("login_login", [0, size_y - 90], [size_x, 40], "Login") ? User_ResumeCharacter() : 0;
	my_button("login_newchar", [0, size_y], [size_x, 40], "New Character") ? User_NewCharacter(LOGIN_GENDER) : 0;
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	my_button("login_quit", [g_width / 2.18, g_height / 2.25], [40, 40], "Disconnect") ? localcmd("disconnect\n") : 0;

	// Name Entry
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_fill([0, -25], '240 25 0', MENU_BG_DARK, 0.75, 0);
	text_input_control("name_entry", [0, -25], [240, 25], 31, LOGIN_NAME, cursor);
	sui_border_box([0, -25], '240 25 0', 2, MENU_BORDER, 0.3, 0);

	sui_text([0, 45], MENU_TEXT_SMALL, "New Character", MENU_TEXT_MEDIUM, 1, 0);

	// Gender entry
	my_button("login_male", [-30, 65], [50, 25], "Male") ? SetGender(0) : 0;
	my_button("login_female", [30, 65], [50, 25], "Female") ? SetGender(1) : 0;

	sui_pop_frame();

	// Display MOTD on login screen, if any exists
	if (motd != "")
	{
		pos = [0, g_height-65];
		size = [435, 65];

		drawfill(pos, size, MENU_BG_DARK, 0.25, 0);
		drawtextfield(pos, size, 3, motd);
	}
};