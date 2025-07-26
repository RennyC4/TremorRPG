void() CSQC_Ent_Remove = {remove(self);};
void() CSQC_Shutdown = {};

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
	drawfont = loadfont("", "Courier Prime Code", "12,16,24,32,64,72,128,256,512", -1, 0, 0);
	precache_everything();
};

noref void() CSQC_WorldLoaded =
{
	MENU = MENU_LOGIN; // first login, display login window
};

noref void(float isnew) CSQC_Ent_Update =
{
	// printf("csqc ent update %f\n", isnew);
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
	
	// Insert your own sui code here, make sure to uncomment sui_input_event as well
	if (MENU != MENU_OFF)
	{
		setcursormode(TRUE,"gfx/xhair", [16, 16], cvar("vid_conautoscale")); // enable mouse cursor when menus are active

		if (MENU == MENU_LOGIN)
			User_LoginScreen();
	}
	else
	{
		setcursormode(FALSE,"", 0, 0);
	}

	//
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
	if (!MENU)
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