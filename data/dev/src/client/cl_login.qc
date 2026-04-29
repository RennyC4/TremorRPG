// Character login screen / creation / map transfer

string Send_LastLogin;
void() sParms_Write;

// ============================================================
// MAP TRANSFER LOGIN (unchanged)
// ============================================================
void() User_ResumeCharacter_MapTransfer =
{
    string line;

    float v = fopen("sparms", FILE_READ);
    if (v)
    {
        if (line = fgets(v))
            Send_LastLogin = line;
        fclose(v);
    }

    if (Send_LastLogin)
        sendevent("ResumeCharacterMapTransfer", "s", Send_LastLogin);

    LOGIN_NAME = Send_LastLogin;
};

// ===============
// READ LAST LOGIN
// ===============
void() ReadLastLogin =
{
    float f;
    string name, pass;

    LOGIN_NAME = "";
    LOGIN_PASSWORD = "";

    f = fopen("lastlogin", FILE_READ);
    if (f < 0)
        return;

    name = fgets(f);
    pass = fgets(f);

    fclose(f);

    if (name && name != "")
        LOGIN_NAME = name;

    if (pass && pass != "")
        LOGIN_PASSWORD = pass;
};

// ================
// WRITE LAST LOGIN
// ================
void(string name, string password) WriteLastLogin =
{
    float f;

    if (!name || name == "")
        return;

    f = fopen("lastlogin", FILE_WRITE);
    if (f < 0)
        return;

    fputs(f, name, "\n");
    fputs(f, password, "\n");

    fclose(f);
};

// ============================================================
// RESUME CHARACTER
// ============================================================
void(float lastlogin) User_ResumeCharacter =
{
    // Use last login
    if (lastlogin)
    {
        ReadLastLogin();

        if (!LOGIN_NAME || LOGIN_NAME == "")
        {
            print("No last login exists, you must login at least once\n");
            return;
        }

        sendevent("ResumeCharacter", "ss", LOGIN_NAME, LOGIN_PASSWORD);
        return;
    }

    // Manual login
    if (!LOGIN_NAME || LOGIN_NAME == "")
    {
        print("Please enter your character name\n");
        return;
    }

    if (!LOGIN_PASSWORD || LOGIN_PASSWORD == "")
    {
        print("Please enter your password\n");
        return;
    }

    // Save locally
    WriteLastLogin(LOGIN_NAME, LOGIN_PASSWORD);

    sendevent("ResumeCharacter", "ss", LOGIN_NAME, LOGIN_PASSWORD);
};

// ============================================================
// CREATE NEW CHARACTER
// ============================================================
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
    if (!LOGIN_PASSWORD)
    {
        print("Please set a password!\n");
        return;
    }

    sendevent("CreateNewCharacter", "sss", LOGIN_NAME, sendgender, LOGIN_PASSWORD);
    sParms_Write();
};

// ============================================================
// GENDER SELECT
// ============================================================
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

// ============================================================
// LOGIN SCREEN UI
// ============================================================
float did_autofill;

void() User_LoginScreen =
{
	// Draw background
	vector bg_size = [g_width, g_height];
	sui_pic([0,0], bg_size, "textures/login.jpg", '0.5 0.5 0.5', 1, 0);

    vector pos = [40, -45];
    vector size = [360, 160];

    // Auto-fill last login ONCE
	if (!did_autofill)
	{
		ReadLastLogin();
		did_autofill = TRUE;
	}

    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
    sui_push_frame(pos, size);

    sui_fill([0, 0], size, MENU_BG, 0.75, 0);
    sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Tremor logo
    sui_pic(pos + [25, -125], [214,115.5], "textures/logo2.png", [1,1,1], 1, 0);

	// Menu text
    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([110, 10], MENU_TEXT_MEDIUM, "Character Information", '0 1 1', 1, 0);
    sui_text([10, 50], MENU_TEXT_SMALL, "Name", MENU_TEXT_MEDIUM, 1, 0);
    sui_text([10, 75], MENU_TEXT_SMALL, "Password", MENU_TEXT_MEDIUM, 1, 0);

    // Buttons
    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
    my_button("login_login", [0, size_y - 65], [size_x / 2, 20], "Login") ? User_ResumeCharacter(FALSE) : 0;
    my_button("login_lastlogin", [size_x / 2, size_y - 65], [size_x / 2, 20], "Use Last Login") ? User_ResumeCharacter(TRUE) : 0;
    my_button("login_newchar", [0, size_y], [size_x, 40], "Create New Character") ? User_NewCharacter(LOGIN_GENDER) : 0;

    sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);

    // Name input
    sui_fill([-15, -25], '240 25 0', MENU_BG_DARK, 0.75, 0);
    text_input_control("name_entry", [-15, -25], [240, 25], 31, LOGIN_NAME, cursor, FALSE);
    sui_border_box([-15, -25], '240 25 0', 2, MENU_BORDER, 0.3, 0);

    // Password input
    sui_fill([-15, 0], '240 25 0', MENU_BG_DARK, 0.75, 0);
    text_input_control("password_entry", [-15, 0], [240, 25], 31, LOGIN_PASSWORD, cursor, TRUE);
    sui_border_box([-15, 0], '240 25 0', 2, MENU_BORDER, 0.3, 0);

    // New character section
    sui_text([0, 45], MENU_TEXT_SMALL, "New Character", '0 1 1', 1, 0);

    my_button("login_male", [-30, 65], [50, 25], "Male") ? SetGender(0) : 0;
    my_button("login_female", [30, 65], [50, 25], "Female") ? SetGender(1) : 0;

    sui_pop_frame();

	// Disconnect button
	vector pos_dc = [0, 0];
    sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
    my_button("login_quit", pos_dc, [40, 40], "Disconnect") ? localcmd("disconnect\n") : 0;

    // MOTD
    if (motd != "")
    {
        pos = [0, g_height-65];
        size = [435, 65];

        drawfill(pos, size, MENU_BG_DARK, 0.25, 0);
        drawtextfield(pos, size, 3, motd);
    }
};