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
	drawfont = loadfont("", "Courier Prime Code", "12,16,24,32,64,72,128,256,512", -1, 0, 0);
};

noref void() CSQC_WorldLoaded =
{
	MENU = MENU_LOGIN; // first login, display login window

	if (cvar("developer") == 1)
		localcmd("sv_cheats 1\nsv_csqc_progname csaddon.dat\nrestart\n");
};

noref void(float isnew) CSQC_Ent_Update =
{
	// printf("csqc ent update %f\n", isnew);
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
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

	if (cvar("developer") == 0)
	{
		float player_loggedin = getstatf(STAT_LOGGEDIN);
		float player_menu = getstatf(STAT_MENU);
		if (player_menu > 0)
		{
			setcursormode(TRUE,"gfx/xhair", [16, 16], cvar("vid_conautoscale")); // enable mouse cursor when menus are active

			if (player_menu == MENU_LOGIN)
				User_LoginScreen();
		}
		else // Regular gameplay
		{
			float zonedisplay_finished = getstatf(STAT_ZONENAME_TIME);
			if (zonedisplay_finished > time)
				Draw_ZoneName(g_width, g_height);
			else
				ZoneName_alpha.doalpha = 0;

			Draw_Health();

			setcursormode(FALSE,"", 0, 0);
		}
	}
	
	//
	//

	sui_menu_nav();
	sui_end();
	
	if (framecount == 10)
		localcmd("exec haze.cfg\n");
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
	float player_menu = getstatf(STAT_MENU);

	if (!player_menu || cvar("developer") == 1)
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
	else // disable player inputs when a menu is activated
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

void(string printmsg, float printlvl) CSQC_Parse_Print =
{
	print(printmsg);
};

noref void CSQC_Shutdown() =
{
	sendevent("Player_SaveChar", "");
};