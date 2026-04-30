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
	// =========================================================
	// SCALE
	// =========================================================
	float scale_x = g_width / 1920;
	float scale_y = g_height / 1080;
	float scale = min(scale_x, scale_y);
	scale = bound(0.75, scale, 1.5);

	#define UI(x,y) [x * scale, y * scale]

	// =========================================================
	// BACKGROUND
	// =========================================================
	sui_pic([0,0], [g_width, g_height], "textures/login.jpg", '0.5 0.5 0.5', 1, 0);

	// =========================================================
	// PANEL (LEFT SIDE)
	// =========================================================
	vector size = UI(380, 270);
	float margin = 40 * scale;

	vector pos = [
		margin,
		(g_height - size_y) * 0.5
	];

	// Autofill once
	if (!did_autofill)
	{
		ReadLastLogin();
		did_autofill = TRUE;
	}

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_push_frame(pos, size);

	// Background
	sui_fill([0,0], size, MENU_BG, 0.75, 0);
	sui_border_box([0,0], size, 2, MENU_BORDER, 0.3, 0);

	// =========================================================
	// LOGO
	// =========================================================
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_pic(UI(75, -110), UI(214,90), "textures/logo2.png", [1,1,1], 1, 0);

	// =========================================================
	// CONTENT FLOW (TOP → BOTTOM)
	// =========================================================
	float y = 10 * scale;
	vector input_size = UI(240, 25);

	// ---- Header ----
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([size_x * 0.01, y], MENU_TEXT_MEDIUM, "Character Information", '0 1 1', 1, 0);

	y += 35 * scale;

	// ---- Name ----
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	sui_text(UI(10, y + 5), MENU_TEXT_SMALL, "Name", MENU_TEXT_MEDIUM, 1, 0);

	sui_fill(UI(80, y - 5), input_size, MENU_BG_DARK, 0.75, 0);
	text_input_control("name_entry", UI(80, y - 5), input_size, 31, LOGIN_NAME, cursor, FALSE);
	sui_border_box(UI(80, y - 5), input_size, 2, MENU_BORDER, 0.3, 0);

	y += 35 * scale;

	// ---- Password ----
	sui_text(UI(10, y + 5), MENU_TEXT_SMALL, "Password", MENU_TEXT_MEDIUM, 1, 0);

	sui_fill(UI(80, y - 5), input_size, MENU_BG_DARK, 0.75, 0);
	text_input_control("password_entry", UI(80, y - 5), input_size, 31, LOGIN_PASSWORD, cursor, TRUE);
	sui_border_box(UI(80, y - 5), input_size, 2, MENU_BORDER, 0.3, 0);

	y += 40 * scale;

	// ---- Login buttons ----
	float btn_h = 24 * scale;

	my_button("login_login",
		[0, y],
		[size_x * 0.5, btn_h],
		"Login", "") ? User_ResumeCharacter(FALSE) : 0;

	my_button("login_lastlogin",
		[size_x * 0.5, y],
		[size_x * 0.5, btn_h],
		"Use Last Login", "") ? User_ResumeCharacter(TRUE) : 0;

	y += 35 * scale;

	// ---- New Character section ----
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([size_x * 0.45, y], MENU_TEXT_SMALL, "New Character", '0 1 1', 1, 0);

	y += 25 * scale;

	// Gender buttons (centered properly)
	float btn_w = 70 * scale;
	float gap = 20 * scale;
	float start_x = (size_x - (btn_w * 2 + gap)) * 0.5;

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	my_button("login_male",
		[start_x, y],
		[btn_w, 26 * scale],
		"Male", "") ? SetGender(0) : 0;

	my_button("login_female",
		[start_x + btn_w + gap, y],
		[btn_w, 26 * scale],
		"Female", "") ? SetGender(1) : 0;

	y += 40 * scale;

	// ---- Create Character (LAST like original) ----
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	my_button("login_newchar",
		[0, y],
		[size_x, 36 * scale],
		"Create New Character", "") ? User_NewCharacter(LOGIN_GENDER) : 0;

	sui_pop_frame();

	// =========================================================
	// DISCONNECT BUTTON (BOTTOM RIGHT)
	// =========================================================
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);

	my_button("login_quit",
		UI(-10, -10),
		UI(140, 32),
		"Disconnect", "") ? localcmd("disconnect\n") : 0;

	// =========================================================
	// MOTD (BOTTOM CENTER)
	// =========================================================
	if (motd != "")
	{
		vector msize = UI(500, 70);
		vector mpos = [
			(g_width - msize_x) * 0.5,
			g_height - msize_y - 10 * scale
		];

		drawfill(mpos, msize, MENU_BG_DARK, 0.25, 0);
		drawtextfield(mpos, msize, 3, motd);
	}
};