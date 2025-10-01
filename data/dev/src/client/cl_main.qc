//
// CSQC - Main file
//

void() Hud_UpdateScores;
void(vector virtmin, vector virtsize) Hud_Scoreboard;

void() CSQC_Ent_Remove = 
{
	self.classname = "";
	self.modelindex = 0;
	remove(self);
};

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
	// default
	drawfont1 = loadfont("", "fonts/trpg", "12", -1, 0, 0);
	drawfont = drawfont1;
	// event box
	drawfont2 = loadfont("", "cour", "12", -1, 0, 0); // set font
};

noref void() CSQC_WorldLoaded =
{
	registercommand("+showscores", "Show scoreboard");
	registercommand("show_character", "Displays character information screen\n");
	registercommand("show_inventory", "Displays inventory information screen\n");
	registercommand("show_magic", "Displays magic information screen\n");
	registercommand("toggle_crouch", "Crouching & sneaking\n");
	registercommand("toggle_camera", "3rd person camera toggle\n");
	registercommand("+use", "Use what is in front of player\n");

	if (cvar("developer") == 1)
		localcmd("sv_cheats 1\nsv_csqc_progname teredit.dat\nrestart\n");
};

void(string rendererdescription) CSQC_RendererRestarted =
{
	localcmd("exec haze.cfg\n");
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	vector virtsize = [width, height];
	float pause = serverkeyfloat(SERVERKEY_PAUSESTATE);
	float lockon = getstatf(STAT_LOCKEDON);
	float health = getstatf(STAT_HEALTH);

	g_width = width;
	g_height = height;
	framecount = framecount + 1;

	clearscene(); // clear and update our global screen resolution vars

	//disable quake status bar
	setproperty(VF_DRAWENGINESBAR, 0);

	if (!lockon && !player_idle && health > 0)
		setproperty(VF_DRAWCROSSHAIR, 1);
	else
		setproperty(VF_DRAWCROSSHAIR, 0);

	//autoadd entities received from servers for drawing
	addentities((intermission?0:MASK_VIEWMODEL)|MASK_ENGINE);

	setproperty(VF_ORIGIN, vPlayerOrigin + [0, 0, getstatf(STAT_VIEWHEIGHT)]);
	setproperty(VF_ANGLES, view_angles);

	Player_Lantern();
	if (lockon)
		FaceTarget();

	if (health > 0)
	{
		if (player_idle)
			Camera_IdleOrbit();
		else if (camera_mode)
		{
			if (thirdcam_dist < 100) // zoom out smoothly
				thirdcam_dist += (200 * frametime);
			else if (thirdcam_dist != 100)
				thirdcam_dist = 100;

			// smooth z
			if (thirdcam_distz < 20)
				thirdcam_distz += (50 * frametime);
			else if (thirdcam_distz != 20)
				thirdcam_distz = 20;

			Camera_Third();
		}
		if (!camera_mode)
		{
			if (thirdcam_dist > 45 || thirdcam_distz > 0) // smooth zoom in when camera is off
			{
				thirdcam_dist -= (200 * frametime);

				if (thirdcam_distz > 0)
					thirdcam_distz -= (75 * frametime);
				else if (thirdcam_distz != 0)
					thirdcam_distz = 0;

				Camera_Third();
			}
			else
			{
				if (thirdcam_dist != 24) // inital cam distance
					thirdcam_dist = 24;
				if (thirdcam_distz != 0) // inital cam z origin
					thirdcam_dist = 0;
			}
		}
	}
	else
		Camera_DeathCam();

	renderscene(); // does what you think it does

	// Insert your own sui code here, make sure to uncomment sui_input_event as well
	sui_begin(g_width, g_height);
	if (showscores)
	{
		Hud_UpdateScores();
		Hud_Scoreboard('0 0 0', virtsize);
	}
	else
		Player_Hud();

	sui_menu_nav();
	sui_end();

	//
	//
	if (framecount == 10)
		localcmd("exec haze.cfg\n");
	if (pause > 0)
		pauseframe += 1;
	else
		pauseframe = 0;
};

float(string strCommand) CSQC_ConsoleCommand =
{
	tokenize(strCommand);
	if (argv(0) == "cast")
		sendevent("DoAttack_Magic", "");
	if (argv(0) == "show_character")
		sendevent("PlayerShowStats", "");
	if (argv(0) == "show_inventory")
		sendevent("PlayerShowInventory", "");
	if (argv(0) == "show_magic")
		sendevent("PlayerShowMagic", "");
	if (argv(0) == "toggle_crouch")
		sendevent("PlayerCrouch", "");
	if (argv(0) == "toggle_camera") // send camera mode to SSQC for various reasons
	{
		float player_menu = getstatf(STAT_MENU);
		if (!player_menu)
		{
			if (!camera_mode)
			{
				sendevent("CameraToggle", "f", 1);
				camera_mode = TRUE;
			}
			else
			{
				sendevent("CameraToggle", "f", 0);
				camera_mode = FALSE;
			}
		}
	}
	if (argv(0) == "+showscores") // scoreboard
		showscores = TRUE;
	else
		showscores = FALSE;
	return FALSE;
};

float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	last_input_time = time;
	player_idle = FALSE;

	float player_menu = getstatf(STAT_MENU);
	float player_lockview = getstatf(STAT_LOCKVIEW);
	float health = getstatf(STAT_HEALTH);

	if (player_menu > 1)
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
			{
				if (player_lockview > time || health <= 0) // disable mouse movement
					return TRUE;
				else
					return FALSE;
			}
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

// CGAMEPACKET events
const float CSQC_INVENTORY = 1;
const float CSQC_NPCINFO = 2;
const float CSQC_INVENTORY_NPC = 3;
const float CSQC_TIMEOFDAY = 4;
const float CSQC_LOCKON_INFO = 5;
const float CSQC_MAGIC = 6;
const float CSQC_LASTLOGIN = 7;
const float CSQC_WRITESPARM = 8;
const float CSQC_READSPARM = 9;

void() CSQC_Parse_Event =
{
	int i;
	float event = readbyte();

	// inventory update
	if (event == CSQC_INVENTORY)
	{
        inv_count = readbyte();
        for (i = 0; i < inv_count; i++)
        {
            inventory[i] = readstring();
            inventory_count[i] = readfloat();
        }
	}
	// NPC interaction update
	if (event == CSQC_NPCINFO)
	{
		npc_name = readstring();
		npc_dialogue = readstring();
	}
	// inventory update from an NPC
	if (event == CSQC_INVENTORY_NPC)
	{
        npc_inv_count = readbyte();
        for (i = 0; i < npc_inv_count; i++)
        {
            npc_inventory[i] = readstring();
            npc_inventory_gold[i] = readfloat();
        }
	}
	// time of day for day / night effects
	if (event == CSQC_TIMEOFDAY)
		timeofday = readbyte();
	// lock on
	if (event == CSQC_LOCKON_INFO)
	{
		LOCKON_NAME = readstring();
		LOCKON_LEVEL = readshort();
		LOCKON_HEALTH = readshort();
		LOCKON_MAXHEALTH = readshort();

		LOCKON_COORD_X = readcoord();
		LOCKON_COORD_Y = readcoord();
		LOCKON_COORD_Z = readcoord();
	}
	// magic update
	if (event == CSQC_MAGIC)
	{
        spell_count = readbyte();
        for (i = 0; i < spell_count; i++)
			spell[i] = readstring();
	}
	// last login update, for map transfers
	if (event == CSQC_LASTLOGIN)
		User_ResumeCharacter_MapTransfer();
	if (event == CSQC_WRITESPARM)
		sParms_Write();
	if (event == CSQC_READSPARM)
		sParms_Read();
};

noref void CSQC_Shutdown() = {};