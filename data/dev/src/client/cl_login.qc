// Character login screen / Creation

void() User_ResumeCharacter =
{
	if (!LOGIN_NAME)
	{
		print("Please enter a character name!\n");
		return;
	}
	else
	{
		localcmd("name ", LOGIN_NAME, "\n");
		MENU = MENU_OFF;
	}
};

void() User_NewCharacter =
{
	if (!LOGIN_NAME)
	{
		print("Please enter a character name!\n");
		return;
	}
	else
	{
		localcmd("name ", LOGIN_NAME, "\n");
		MENU = MENU_OFF;
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

	sui_text([0, 4], MENU_TEXT_MEDIUM, "Welcome to Quake RPG", MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([size_x / 3.5, size_y - 115], MENU_TEXT_MEDIUM, "User Name", MENU_TEXT_MEDIUM, 1, 0);

	// Login / New character buttons
	my_button("login_login", [25, size_y - 55], [size_x - 60, 40], "Login") ? User_ResumeCharacter() : 0;
	my_button("login_newchar", [0, size_y], [size_x, 40], "New Character") ? User_NewCharacter() : 0;
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	my_button("login_quit", [g_width / 2.18, g_height / 2.25], [40, 40], "Quit") ? localcmd("quit\n") : 0;

	// Name Entry
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_fill([0, 0], '240 25 0', MENU_BG_DARK, 0.75, 0);
	text_input_control("name_entry", [0, 0], [240, 25], 31, LOGIN_NAME, cursor);
	sui_border_box([0, 0], '240 25 0', 2, MENU_BORDER, 0.3, 0);
};