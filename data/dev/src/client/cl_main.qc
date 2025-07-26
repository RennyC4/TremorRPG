vector MENU_BG = '0.2 0.3 0.4';
vector MENU_BG_DARK = '0.1 0.15 0.2';
vector MENU_BORDER = '0.3 0.4 0.5';
vector MENU_BUTTON = '0.3 0.4 0.5';
vector MENU_BUTTON_BORDER = '0.35 0.45 0.55';
vector MENU_TEXT_1 = '1 1 1';
vector MENU_TEXT_2 = '0.7 0.75 0.75';
vector MENU_HIGHLIGHT = '1 1 1';
vector MENU_DARKEN = '1 1 1';

vector MENU_TEXT_SMALL = '8 8 0';
vector MENU_TEXT_MEDIUM = '16 16 0';
vector MENU_TEXT_LARGE = '24 24 0';

void() CSQC_Ent_Remove = {remove(self);};

void() CSQC_Shutdown = {};

noref void(float apiver, string enginename, float enginever) CSQC_Init =
{
	drawfont = loadfont("", "Courier Prime Code", "12,16,24,32,64,72,128,256,512", -1, 0, 0);
	precache_everything();
};

noref void() CSQC_WorldLoaded = {};

noref void(float isnew) CSQC_Ent_Update =
{
	// printf("csqc ent update %f\n", isnew);
};

float(string id, vector pos, vector size, string text) my_button =
{
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BUTTON + MENU_HIGHLIGHT * 0.25 : MENU_BUTTON; 
	basecolor = sui_is_held(id) ? MENU_BUTTON - MENU_DARKEN * 0.1 : basecolor;
	sui_fill([0, 0], size, basecolor, 0.6, 0);
	sui_border_box([0, 0], size, 1, MENU_BUTTON_BORDER, 0.4, 0);

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_text([0, 0], MENU_TEXT_SMALL, text, MENU_TEXT_1, 1, 0);	
	sui_action_element([0, 0], size, id, sui_noop);
	sui_pop_frame();

	return sui_is_clicked(id);
};

// Character login screen / Creation
void() CSQC_LoginScreen =
{
	vector pos = [0, 0];
	vector size = [360, 160];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);

	sui_text([0, 4], MENU_TEXT_MEDIUM, "Login", MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	sui_text([0, 40], MENU_TEXT_MEDIUM, "Name:", MENU_TEXT_MEDIUM, 1, 0);
	sui_text([0, 70], MENU_TEXT_MEDIUM, "Password:", MENU_TEXT_MEDIUM, 1, 0);

	my_button("login_login", [25, size_y - 55], [size_x - 60, 40], "Login") ? localcmd("map world\n") : 0;
	my_button("login_newchar", [0, size_y], [size_x, 40], "New Character") ? localcmd("map world\n") : 0;
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	//clear and update our global screen resolution vars
	clearscene();
	g_width = width;
	g_height = height;

	//disable quake status bar and quake crosshair
	setproperty(VF_DRAWENGINESBAR, 0);	
	setproperty(VF_DRAWCROSSHAIR, 0);

	campos = getproperty(VF_ORIGIN);
	camang = getproperty(VF_ANGLES);

	//autoadd entities received from servers for drawing	
	addentities(MASK_ENGINE);

	//does what you think it does
	renderscene();
	
	sui_begin(g_width, g_height);
	
	// Insert your own sui code here even for CSQC
	// Make sure to uncomment sui_input_event as well.

	CSQC_LoginScreen();

	//

	sui_menu_nav();
	sui_end();
};

float(string cmd) CSQC_ConsoleCommand =
{
	tokenize(cmd);
	switch(argv(0))
	{
		default:
			return FALSE;
	}
	return TRUE;
};

float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	sui_input_event(evtype, scanx, chary, devid); // Should only be activated when menus are on
	switch(evtype)
	{
		case IE_KEYDOWN:
			return FALSE;
		case IE_KEYUP:
			return FALSE;
		case IE_MOUSEDELTA:
			return FALSE;
		case IE_MOUSEABS:
			cursor_pos_x = scanx;
			cursor_pos_y = chary;
			return FALSE;
	}
	return FALSE;
};

void() CSQC_Parse_Event =
{
	float first = readbyte();
	switch(first)
	{
		default:
			printf("No action for byte %f\n", first);
		break;
	}
};

float(string key, string val) find_player_id =
{
	for (int currentindex = 0; currentindex < maxclients; currentindex++)
	{
		if (getplayerkeyvalue(currentindex, key) == val)
			return currentindex;
	}
	return -1;
}

void(string printmsg, float printlvl) CSQC_Parse_Print =
{
	print(printmsg);
};
