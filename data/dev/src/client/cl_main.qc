//
// CSQC - Main file
//

void() Hud_UpdateScores;
void(vector virtmin, vector virtsize) Hud_Scoreboard;

void() CSQC_Ent_Remove = {remove(self);};

float(string key, string val) find_player_id =
{
	for (int currentindex = 0; currentindex < maxclients; currentindex++)
	{
		if (getplayerkeyvalue(currentindex, key) == val)
			return currentindex;
	}
	return -1;
};

noref void(float apiver, string enginename, float enginever) CSQC_Init =
{
	ZoneName_alpha = spawn();
	drawfont = loadfont("", "Courier Prime Code", "4,8,12,16,24,32,64,72,128,256,512", -1, 0, 0);
};

noref void() CSQC_WorldLoaded =
{
	registercommand("+showscores", "Show scoreboard");
	registercommand("show_character", "Displays character information screen\n");
	registercommand("toggle_crouch", "Crouching & sneaking\n");
	registercommand("+use", "Use what is in front of player\n");

	if (cvar("developer") == 1)
		localcmd("sv_cheats 1\nsv_csqc_progname csaddon.dat\nrestart\n");
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	vector virtsize = [width, height];

	framecount = framecount + 1;

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
	
	
	// Insert your own sui code here, make sure to uncomment sui_input_event as well
	
	if (showscores)
	{
		Hud_UpdateScores();
		Hud_Scoreboard('0 0 0', virtsize);
	}
	else
		Player_Hud();

	//
	//

	sui_menu_nav();
	sui_end();

	if (framecount == 10)
		localcmd("exec haze.cfg\n");
};

float(string strCommand) CSQC_ConsoleCommand =
{
	tokenize(strCommand);
	if (argv(0) == "show_character")
		sendevent("PlayerShowStats", "");
	if (argv(0) == "toggle_crouch")
		sendevent("PlayerCrouch", "");
	if (argv(0) == "+showscores") // scoreboard
		showscores = TRUE;
	else
		showscores = FALSE;
	return FALSE;
};

float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	float player_menu = getstatf(STAT_MENU);

	if (player_menu == MENU_CHARACTER) // Character screen
		sui_input_event(evtype, scanx, chary, devid);

	if (player_menu != MENU_LOGIN)
	{
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
	}
	else // disable player inputs under certain conditions
	{
		sui_input_event(evtype, scanx, chary, devid); // Should only be activated when menus are on
		return TRUE;
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

noref void CSQC_Shutdown() =
{
	//sendevent("Player_SaveChar", "");
};