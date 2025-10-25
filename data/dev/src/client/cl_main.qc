//
// CSQC - Main file
//

void() Hud_UpdateScores;
void(vector virtmin, vector virtsize) Hud_Scoreboard;

void() CSQC_Precache =
{
	precache_model("models/lantern.glb");
	precache_model("models/sword0.glb");
	precache_model("models/sword1.glb");
	precache_model("models/dagger0.glb");
	precache_model("models/shield0.glb");
	precache_model("models/shield1.glb");
};

void() CSQC_Ent_Remove =
{
	// clean up CSQC ents
	if (self.skeletonindex)
		skel_delete(self.skeletonindex);
	if (self.lantern_vfx)
		remove(self.lantern_vfx);
	if (self.weapon_vfx)
		remove(self.weapon_vfx);
	if (self.offhand_vfx)
		remove(self.offhand_vfx);
	if (self.arrow_vfx)
		remove(self.arrow_vfx);
	//
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
		
	CSQC_Precache();
	last_input_time = time + 15; // don't use idle cam on map change
};

void(string rendererdescription) CSQC_RendererRestarted =
{
	localcmd("exec haze.cfg\n");
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	if (cvar("developer") > 0) // setup developer mode
	{
		clearscene();
		setproperty(VF_DRAWENGINESBAR, 0);
		addentities(MASK_ENGINE);
		renderscene();
		return;
	}

	vector virtsize = [width, height];
	float pause = serverkeyfloat(SERVERKEY_PAUSESTATE);
	float health = getstatf(STAT_HEALTH);
	float atbonfire = getstatf(STAT_BONFIRE);

	g_width = width;
	g_height = height;
	framecount = framecount + 1;

	clearscene(); // clear and update our global screen resolution vars
	setproperty(VF_DRAWENGINESBAR, 0); // disable quake status bar

	if (!player_idle && health > 0 && !lock_on_active && !atbonfire)
		setproperty(VF_DRAWCROSSHAIR, 1);
	else
		setproperty(VF_DRAWCROSSHAIR, 0);

	//if (cvar("sv_cheats") == 0) // entities are wrapped with csaddon with sv_cheats is 1
	addentities(MASK_VIEWMODEL | MASK_ENGINE);

	setproperty(VF_ORIGIN, vPlayerOrigin + [0, 0, getstatf(STAT_VIEWHEIGHT)]);
	setproperty(VF_ANGLES, view_angles);

	CSQC_LockOn_Update();
	if (health > 0)
	{
		if ((player_idle || atbonfire) && !lock_on_active)
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

	if (lock_on_active)
		CSQC_LockOn_Plaques(lock_on_target.origin);

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
	if (cvar("developer") > 0)
		return;

	tokenize(strCommand);

	if (argv(0) == "target")
		LockOn_Toggle = TRUE;
	if (argv(0) == "targetcycle")
		LockOn_CycleToggle = TRUE;
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
		float atbonfire = getstatf(STAT_BONFIRE);
		if (!player_menu && !atbonfire)
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
	if (cvar("developer") > 0)
		return;

	last_input_time = time;
	player_idle = FALSE;

	float player_menu = getstatf(STAT_MENU);
	float player_lockview = getstatf(STAT_LOCKVIEW);
	float health = getstatf(STAT_HEALTH);
	float atbonfire = getstatf(STAT_BONFIRE);

	// Send input to UI if a menu is active
	if (player_menu > 1)
		sui_input_event(evtype, scanx, chary, devid);

	// Normal gameplay input handling
	if (player_menu != MENU_LOGIN)
	{
		switch (evtype)
		{
			case IE_KEYDOWN:
			{
				string bind = getkeybind(scanx);

				if (atbonfire) // Disable movement keys at bonfire
				{
					if (bind == "+forward" || bind == "+back" || bind == "+moveleft" || bind == "+moveright" || bind == "+jump")
						return TRUE; // block movement
				}

				if (bind == "+button4")
					button4 = TRUE;

				return FALSE;
			}
			case IE_KEYUP:
			{
				string bind = getkeybind(scanx);

				if (atbonfire) // Disable movement keys at bonfire
				{
					if (bind == "+forward" || bind == "+back" || bind == "+moveleft" || bind == "+moveright" || bind == "+jump")
						return TRUE; // block movement
				}

				if (bind == "+button4")
					button4 = FALSE;

				return FALSE;
			}
			case IE_MOUSEDELTA:
			{
				// Disable mouse look under conditions
				if (player_lockview > time || health <= 0 || lock_on_active || atbonfire)
					return TRUE;
				else
					return FALSE;
			}
			case IE_MOUSEABS: // Mouse Absolute (UI cursor)
			{
				cursor_pos_x = scanx;
				cursor_pos_y = chary;
				return FALSE;
			}
		}
		return FALSE;
	}
	else
	{
		sui_input_event(evtype, scanx, chary, devid); // Menu input only (login or special screens)
		return TRUE;
	}
	return FALSE;
};

// CGAMEPACKET events
const float CSQC_INVENTORY = 1;
const float CSQC_NPCINFO = 2;
const float CSQC_INVENTORY_NPC = 3;
const float CSQC_TIMEOFDAY = 4;
//const float CSQC_LOCKON_INFO = 5;
const float CSQC_MAGIC = 6;
const float CSQC_LASTLOGIN = 7;
const float CSQC_WRITESPARM = 8;
const float CSQC_READSPARM = 9;
const float CSQC_WIPESPARM = 10;

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

	/*
	if (event == CSQC_LOCKON_INFO)
	{
	}
	*/

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
	if (event == CSQC_WIPESPARM)
		sParms_Wipe();
};

void(float flIsNew) CSQC_Ent_Update =
{
	float flEntType = readbyte();

	//
	// Players
	//
	if (flEntType == ENT_PLAYER)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "player";
			self.solid = SOLID_TRIGGER;
			self.predraw = Player_PreDraw;
			self.drawmask = MASK_ENGINE;
			self.view_ofs = '0 0 48';
		}

		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();

		self.angles_x = readcoord();
		self.angles_y = readcoord();
		self.angles_z = readcoord();

		self.velocity_x = readshort();
		self.velocity_y = readshort();
		self.velocity_z = readshort();
		self.flags = readfloat();
		self.effects = readfloat();
		self.modelindex = readshort();
		self.netname = readstring();
		self.climbing = readbyte();
		self.health = readshort();
		self.max_health = readshort();
		self.level = readbyte();
		self.colormod_x = readcoord();
		self.colormod_y = readcoord();
		self.colormod_z = readcoord();
		self.pvp = readbyte();
		self.loggedin = readbyte();
		self.main_hand = readstring();
		self.off_hand = readstring();
		self.anistate = readbyte();
		self.bonfire = readbyte();
		self.cast_finished = readbyte();
		self.attack_type = readbyte();
		self.blocking = readbyte();
		self.crouch = readbyte();

		setsize(self, [-16, -16, 0], [16, 16, 56]);
		setorigin(self, self.origin);
	}

	//
	// Monsters
	//
	if (flEntType == ENT_MONSTER)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "monster";
			self.solid = SOLID_SLIDEBOX;
			self.predraw = Monster_PreDraw;
			self.drawmask = MASK_ENGINE;
			self.view_ofs = '0 0 48';
		}

		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.angles_x = readcoord();
		self.angles_y = readcoord();
		self.angles_z = readcoord();
		self.velocity_x = readshort();
		self.velocity_y = readshort();
		self.velocity_z = readshort();
		self.flags = readfloat();
		self.effects = readfloat();
		self.alpha = readbyte();
		self.modelindex = readshort();
		self.health = readshort();
		self.max_health = readshort();
		self.displayname = readstring();
		self.speed = readbyte();
		self.main_hand = readstring();
		self.off_hand = readstring();
		self.level = readbyte();
		self.anistate = readbyte();
		self.ai_mode = readbyte();
	}
};

noref void CSQC_Shutdown() = {};