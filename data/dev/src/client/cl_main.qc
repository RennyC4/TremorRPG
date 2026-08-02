//
// CSQC - Main file
//

float(void) DrawDynamicLights =
{
	for (entity f = world; (f = find(f, classname, "dlight"));)
	{
		float lev = f.light_lev;
		float dist = vlen(vPlayerOrigin - f.origin);

		if (vlen(f.origin - vPlayerOrigin) > 2000)
			continue;

		float want_noshadow = 0;

		if (autocvar_tremor_lighting == "simple")
		{
			want_noshadow = 1;
			lev /= 1.5;
		}
		else if (f.spawnflags & 1)
		{
			want_noshadow = 1;
			lev /= 1.5;
		}

		if (want_noshadow)
			f.pflags |= PFLAGS_NOSHADOW;
		else
			f.pflags &= ~PFLAGS_NOSHADOW;

		if (f.spawnflags & 2)
			f.pflags |= PFLAGS_CORONA;
		else
			f.pflags &= ~PFLAGS_CORONA;

		if (lev < 5)
			lev = 5; // stop dlight culling flicker

		dynamiclight_add(f.origin + f.view_ofs, lev, [f.color_x, f.color_y, f.color_z], f.style, "", f.pflags);
	}
};

void() CSQC_DrawMonsterPlaques;

// ========================
// Entity (Player, monsters, allies, etc) send flags
// ========================

#define ESF_ORIGIN        1       // 0b0000000000000001
#define ESF_ANGLES        2       // 0b0000000000000010
#define ESF_VELOCITY      4       // 0b0000000000000100
#define ESF_FLAGS         8       // 0b0000000000001000
#define ESF_EFFECTS       16      // 0b0000000000010000
#define ESF_MODEL         32      // 0b0000000000100000
#define ESF_NAME          64      // 0b0000000001000000
#define ESF_HEALTH        128     // 0b0000000010000000
#define ESF_LEVEL         256     // 0b0000000100000000
#define ESF_PVP           512     // 0b0000001000000000
#define ESF_EQUIPMENT     1024    // 0b0000010000000000
#define ESF_ANIMATION     2048    // 0b0000100000000000
#define ESF_MISC          4096    // 0b0001000000000000

void() Hud_UpdateScores;
void(vector virtmin, vector virtsize) Hud_Scoreboard;
static void(float seat, vector mn, vector sz) renderscene_helper;

void() CSQC_Precache =
{
	precache_model("models/lantern.glb");
	precache_model("models/sword0.glb");
	precache_model("models/sword1.glb");
	precache_model("models/dagger0.glb");
	precache_model("models/shield0.glb");
	precache_model("models/shield1.glb");
	precache_model("models/club0.glb");
	precache_model("models/quiver.glb");
	precache_model("models/bow0.glb");
	precache_model("models/armor0.glb");
	precache_model("models/arrow2.glb");
	precache_model("models/bonfire.glb");

	precache_model("models/hatchet0.glb");
	precache_model("models/pick0.glb");
	precache_model("models/fishrod.glb");
	precache_model("models/walltorch1.glb");
	precache_model("models/walltorch2.glb");
	precache_model("models/fishschool.glb");

	precache_sound ("ambience/fountain.wav");
	precache_sound("bonfire1.wav");
	precache_sound("bonfire2.wav");
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
	if (self.armor_vfx)
		remove(self.armor_vfx);
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

// Initialization
noref void(float apiver, string enginename, float enginever) CSQC_Init =
{
	addprogs("csaddon.dat");

    ZoneName_alpha = spawn();

    // Default fonts
    drawfont1 = loadfont("", "fonts/trpg", "12", -1, 0, 0);
    drawfont = drawfont1;
    drawfont2 = loadfont("", "cour", "12", -1, 0, 0);
};

noref void() CSQC_WorldLoaded =
{
	registercommand("toggle_cursor", "Turns mouse cursor on or off\n");
	registercommand("+showscores", "Show scoreboard");
	registercommand("show_character", "Displays character information screen\n");
	registercommand("show_inventory", "Displays inventory information screen\n");
	registercommand("show_magic", "Displays magic information screen\n");
	registercommand("show_questlog", "Displays quest log information screen\n");
	registercommand("toggle_crouch", "Crouching & sneaking\n");
	registercommand("toggle_camera", "3rd person camera toggle\n");
	registercommand("+use", "Use what is in front of player\n");
	registercommand("quick_health", "Use a health potion\n");
	registercommand("quick_mana", "Use a mana potion\n");

	CSQC_Precache();
	last_input_time = time + 15; // reset idle cam on map change
	
	//
	// Setup Particles
	//
	PART_LEVELUP = particleeffectnum("levelup");
	PART_FOUNTAIN = particleeffectnum("fountain");
	PART_BONFIRE = particleeffectnum("cu_flame");
	PART_WTORCH1 = particleeffectnum("wtorch1");
	PART_WTORCH2 = particleeffectnum("wtorch2");
	PART_HEALTHPOTION = particleeffectnum("healthpotion");
	PART_MANAPOTION = particleeffectnum("manapotion");
	PART_BLOCK = particleeffectnum("block");
	PART_PARRY = particleeffectnum("parry");
	PART_MAGIC_CASTING = particleeffectnum("magiccast");
	PART_MAGIC_CASTING_ORB = particleeffectnum("magiccast_orb");
	PART_TREEHIT = particleeffectnum("treehit");
	PART_TREEFALL = particleeffectnum("treefall");
	PART_WIZARD_F = particleeffectnum("wizard_f");
	PART_MELEE_HITWALL = particleeffectnum("melee_wallhit");
	PART_ARROW_HITWALL = particleeffectnum("arrow_wallhit");
};

void() CSQC_DayNight_Update =
{
	// update entity lighting on world map client-side, SSQC -> CSQC use inverted abslight values for some reason
	for (entity c = world;(c = findfloat(c, worldlight, TRUE));)
	{
		float light;

		c.drawflags |= 7;
		if (timeofday == TIME_DAY)
			light = -200;
		else if (timeofday == TIME_NIGHT)
			light = 225;
		else if (timeofday == TIME_DAWN)
			light = 1;
		else
			light = 190;

		c.abslight = 255 - light; // invert
	}
};

void(string rendererdescription) CSQC_RendererRestarted =
{
	localcmd("exec haze.cfg\n");
};

// CALLED EVERY CLIENT RENDER FRAME
void(float width, float height, float menushown) CSQC_UpdateView =
{
	//================
	// DEVELOPER MODE: used for terrain editing
	//================
	if (cvar("developer") > 0)
	{
		clearscene();

		setproperty(VF_DRAWENGINESBAR, 0);
		setproperty(VF_DRAWCROSSHAIR, 1);

		// Render the world
		addentities(MASK_VIEWMODEL | MASK_ENGINE);
		wrap_renderscene();

		return; // skip normal SUI / HUD rendering
	}
	//
	//
	//

	vector virtsize = [width, height];

	g_width = width;
	g_height = height;
	framecount = framecount + 1;

	float pause = serverkeyfloat(SERVERKEY_PAUSESTATE);
	float health = getstatf(STAT_HEALTH);
	float atbonfire = getstatf(STAT_BONFIRE);

	clearscene(); // clear and update our global screen resolution vars
	
	DrawDynamicLights();

	setproperty(VF_DRAWENGINESBAR, 0); // disable quake status bar

	if (!player_idle && health > 0 && !lock_on_active && !atbonfire)
		setproperty(VF_DRAWCROSSHAIR, 1);
	else
		setproperty(VF_DRAWCROSSHAIR, 0);

	setproperty(VF_ORIGIN, vPlayerOrigin + [0, 0, getstatf(STAT_VIEWHEIGHT)]);
	setproperty(VF_ANGLES, view_angles);

	addentities(MASK_VIEWMODEL | MASK_ENGINE);

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
					thirdcam_distz = 0;
			}
		}
	}
	else
		Camera_DeathCam();

	renderscene(); // does what you think it does

	CSQC_DrawMonsterPlaques();

	// Insert your own sui code here, make sure to uncomment sui_input_event as well
	sui_begin(g_width, g_height);
	if (showscores)
	{
		Hud_UpdateScores();
		Hud_Scoreboard([0, 0, 0], virtsize);
	}
	Player_Screen(); // HUD, day/night rendering, etc

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

	if (cvar("developer") > 0) // terrain editor
		return editor_brushes_command();

	float player_menu = getstatf(STAT_MENU);
	float atbonfire = getstatf(STAT_BONFIRE);

	if (!player_menu && !atbonfire && !cursor_mode)
	{
		// Tremor Jump / Dodge / Climb
		if (argv(0) == "+t_jump")
			User_DoJump = TRUE;
		if (argv(0) == "-t_jump")
			User_DoJump = FALSE;

		 // Tremor Attack
		if (argv(0) == "t_attack")
			User_DoAttack = TRUE;

		if (argv(0) == "quick_health")
			sendevent("Player_UseItem", "fs", 0, "Health Potion");
		if (argv(0) == "quick_mana")
			sendevent("Player_UseItem", "fs", 2, "Mana Potion");
	}

	if (argv(0) == "toggle_crouch")
		sendevent("PlayerCrouch", "");
	if (argv(0) == "target")
		LockOn_Toggle = TRUE;
	if (argv(0) == "targetcycle")
		LockOn_CycleToggle = TRUE;
	if (argv(0) == "cast")
	{
		if (lock_on_active)
			sendevent("DoAttack_Magic", "v", lockon_angles);
		else
			sendevent("DoAttack_Magic", "v", [0,0,0]); // send nothing when lock-on is off
	}
	if (argv(0) == "show_character")
	{
		// turn off cursor mode if user closes menu by quick command
		float player_menu = getstatf(STAT_MENU);
		if (!player_menu) cursor_mode = TRUE;
		else cursor_mode = FALSE;

		sendevent("PlayerShowStats", "");
	}
	if (argv(0) == "show_inventory")
	{
		// turn off cursor mode if user closes menu by quick command
		player_menu = getstatf(STAT_MENU);
		if (!player_menu) cursor_mode = TRUE;
		else cursor_mode = FALSE;

		sendevent("PlayerShowInventory", "");
	}
	if (argv(0) == "show_magic")
	{
		// turn off cursor mode if user closes menu by quick command
		player_menu = getstatf(STAT_MENU);
		if (!player_menu) cursor_mode = TRUE;
		else cursor_mode = FALSE;

		sendevent("PlayerShowMagic", "");
	}
	if (argv(0) == "show_questlog")
	{
		// turn off cursor mode if user closes menu by quick command
		player_menu = getstatf(STAT_MENU);
		if (!player_menu) cursor_mode = TRUE;
		else cursor_mode = FALSE;

		sendevent("PlayerShowQuestLog", "");
	}
	if (argv(0) == "toggle_camera") // send camera mode to SSQC for various reasons
	{
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
	if (argv(0) == "+showscores")
		showscores = TRUE;
	else if (argv(0) == "-showscores")
		showscores = FALSE;
	if (argv(0) == "toggle_cursor")
	{
		if (!player_menu)
		{
			if (!cursor_mode)
				cursor_mode = TRUE;
			else
				cursor_mode = FALSE;
		}
	}
	return FALSE;
};

float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	if (cvar("developer") > 0) // Terrain editor
		return wrap_InputEvent(evtype, scanx, chary);

	last_input_time = time;
	player_idle = FALSE;

	float player_menu = getstatf(STAT_MENU);
	float player_lockview = getstatf(STAT_LOCKVIEW);
	float health = getstatf(STAT_HEALTH);
	float atbonfire = getstatf(STAT_BONFIRE);

	// Send input to UI if a menu is active, or cursor mode is toggled on
	if (player_menu > 1 || cursor_mode)
		sui_input_event(evtype, scanx, chary, devid);

	// Normal gameplay input handling
	if (player_menu != MENU_LOGIN)
	{
		switch (evtype)
		{
			case IE_KEYDOWN:
			{
				string bind = getkeybind(scanx);

				// Escape closes existing menus
				if (bind == "togglemenu" && player_menu > 0)
				{
					sendevent("ShutDownMenus", "");
					return TRUE;
				}

				if (bind == "+jump") // block jump
					return TRUE;
				if (bind == "+attack") // block attack
					return TRUE;

				if (atbonfire || player_menu > 0) // Disable movement keys at bonfire/menu stuff
				{
					if (bind == "+forward" || bind == "+back" || bind == "+moveleft" || bind == "+moveright")
						return TRUE; // block movement
				}

				if (bind == "+moveleft")
					button_left = TRUE;
				if (bind == "+moveright")
					button_right = TRUE;
				if (bind == "+forward")
					button_up = TRUE;
				if (bind == "+back")
					button_down = TRUE;

				if (bind == "+button4")
					button4 = TRUE;

				return FALSE;
			}
			case IE_KEYUP:
			{
				bind = getkeybind(scanx);

				if (bind == "+moveleft")
					button_left = FALSE;
				if (bind == "+moveright")
					button_right = FALSE;
				if (bind == "+forward")
					button_up = FALSE;
				if (bind == "+back")
					button_down = FALSE;

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

void(string msg) CSQC_AddChatMessage =
{
    float i;

    // shift everything down
    for (i = MAX_CHAT_LINES - 1; i > 0; i--)
    {
        chat_lines[i] = chat_lines[i - 1];
        chat_times[i] = chat_times[i - 1];
    }

    chat_lines[0] = msg;
    chat_times[0] = time;
};

string(string s) StripColors =
{
    string out = "";
    float i = 0;
    float len = strlen(s);

    while (i < len)
    {
        if (substring(s, i, 1) == "^")
        {
            i += 2; // skip ^ and next char
            continue;
        }

        out = strcat(out, substring(s, i, 1));
        i++;
    }

    return out;
};

void(string msg) CSQC_WrapAndAddChat =
{
    string clean = StripColors(msg);
    float len = strlen(clean);
    float pos = 0;

    float real_index = 0; // index into original string

    while (pos < len)
    {
        float max = CHAT_LINE_CHARS;
        float end = pos + max;

        if (end >= len)
        {
            CSQC_AddChatMessage(substring(msg, real_index, strlen(msg)));
            break;
        }

        float cut = end;

        // find last space
        while (cut > pos && substring(clean, cut, 1) != " ")
            cut--;

        if (cut == pos)
            cut = end;

        // Now: get corresponding real string indices
        float clean_i = 0;
        float real_i = 0;

        while (clean_i < cut && real_i < strlen(msg))
        {
            if (substring(msg, real_i, 1) == "^")
                real_i += 2;
            else
            {
                clean_i++;
                real_i++;
            }
        }

        string line = substring(msg, real_index, real_i - real_index);
        CSQC_AddChatMessage(line);

        real_index = real_i;

        // Skip spaces
        while (real_index < strlen(msg) &&
               substring(msg, real_index, 1) == " ")
        {
            real_index++;
            pos++;
        }

        pos = cut;
    }
};

void(entity speaker, string msg) FloatingText_Add =
{
    if (!speaker)
        return;

    speaker.floattext_msg = msg;
    speaker.floattext_time = time + 6;
};

//
// Quest log - client side
//

#define MAX_QUESTS 64

float quest_count;

string quest_id[MAX_QUESTS];
string quest_name[MAX_QUESTS];
string quest_description[MAX_QUESTS];

float quest_status[MAX_QUESTS];

float quest_progress[MAX_QUESTS];
float quest_needed[MAX_QUESTS];

float quest_reward_exp[MAX_QUESTS];
float quest_reward_gold[MAX_QUESTS];

string quest_reward_item[MAX_QUESTS];
float quest_reward_item_count[MAX_QUESTS];

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
	//
	// NPC interaction update
	//

	if (event == CSQC_NPCINFO)
	{
		float b;

		npc_name = readstring();
		npc_dialogue = readstring();

		//
		// Available quests
		//

		npc_available_count = readbyte();

		if (npc_available_count > 32)
			npc_available_count = 32;

		for (b = 0; b < npc_available_count; b++)
		{
			npc_available_id[b] = readstring();
			npc_available_name[b] = readstring();
		}

		//
		// Clear unused slots
		//

		for (; b < 32; b++)
		{
			npc_available_id[b] = "";
			npc_available_name[b] = "";
		}

		//
		// Turn-in quests
		//

		npc_turnin_count = readbyte();
		if (npc_turnin_count > 32)
			npc_turnin_count = 32;

		for (b = 0; b < npc_turnin_count; b++)
		{
			npc_turnin_id[b] = readstring();
			npc_turnin_name[b] = readstring();
		}

		//
		// Clear unused slots
		//

		for (; b < 32; b++)
		{
			npc_turnin_id[b] = "";
			npc_turnin_name[b] = "";
		}
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
	{
		timeofday = readbyte();
		CSQC_DayNight_Update();
	}

	// motd
	if (event == CSQC_MOTD)
		motd = readstring();

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
	if (event == CSQC_SAY)
	{
		string msg = readstring();
		CSQC_WrapAndAddChat(msg); // add to chat box
	}
	if (event == CSQC_SAY_NEARBY)
	{
		float entread = readentitynum();
		msg = readstring();
		entity speaker = findfloat(world, entnum, entread);

		//print("Received nearby msg from ent:", ftos(entnum), " text:", msg, "\n"); // DEBUG

		if (speaker)
		{
			FloatingText_Add(speaker, msg);
			localsound("misc/talk.wav");
		}
	}
	if (event == CSQC_QUESTINFO)
	{
		float count;
		float h;
		float p;

		count = readbyte();

		if (count > MAX_QUESTS)
			count = MAX_QUESTS;

		quest_count = count;

		//
		// Clear old quests
		//

		for (h = 0; h < MAX_QUESTS; h++)
		{
			quest_log[h].id = "";
			quest_log[h].name = "";
			//quest_log[h].description = ""; // crashes, needs it's own packet

			quest_log[h].objective_count = 0;

			for (p = 0; p < MAX_QUEST_OBJECTIVES; p++)
			{
				quest_log[h].objective_text[p] = "";
				quest_log[h].objective_progress[p] = 0;
				quest_log[h].objective_needed[p] = 0;
			}

			quest_log[h].status = QUEST_LOCKED;

			quest_log[h].reward_exp = 0;
			quest_log[h].reward_gold = 0;

			quest_log[h].reward_item = "";
			quest_log[h].reward_item_count = 0;
		}

		//
		// Read quests
		//

		for (h = 0; h < count; h++)
		{
			quest_log[h].id = readstring();
			quest_log[h].name = readstring();
			//quest_log[h].description = readstring(); // crashes, needs it's own packet

			//
			// Objectives
			//

			quest_log[h].objective_count = readbyte();

			if (quest_log[h].objective_count > MAX_QUEST_OBJECTIVES)
				quest_log[h].objective_count = MAX_QUEST_OBJECTIVES;

			for (p = 0; p < quest_log[h].objective_count; p++)
			{
				quest_log[h].objective_text[p] = readstring();
				quest_log[h].objective_progress[p] = readbyte();
				quest_log[h].objective_needed[p] = readfloat();
			}

			//
			// Status
			//

			quest_log[h].status = readbyte();

			//
			// Rewards
			//

			quest_log[h].reward_exp = readfloat();
			quest_log[h].reward_gold = readfloat();

			quest_log[h].reward_item = readstring();
			quest_log[h].reward_item_count = readfloat();
		}
	}
	if (event == CSQC_QUEST_NOTIFY)
	{
		quest_notify_image = readstring();
		quest_notify_name = readstring();

		quest_notify_time = time + 6;
	}
	if (event == CSQC_QUEST_COMPLETE)
	{
		quest_complete_name = readstring();

		quest_complete_time = time + 6;
		quest_complete_alpha = 1;
		localsound("q_cmplt.wav");
	}
	if (event == CSQC_QUEST_PREVIEW)
	{
		quest_preview_id = readstring();
		quest_preview_name = readstring();
		quest_preview_description = readstring();
		quest_preview_objective = readstring();

		quest_preview_level = readfloat();

		quest_preview_reward_exp = readfloat();
		quest_preview_reward_gold = readfloat();

		quest_preview_reward_item = readstring();
		quest_preview_reward_item_count = readfloat();
	    //
		// Request full description separately
		//

		quest_preview_description = "Loading...";
		sendevent("QuestDescription", "s", quest_preview_id);
	}
	if (event == CSQC_QUEST_OBJECTIVE_COMPLETE)
	{
		localsound("objcomplete.wav");
		quest_objective_notify_text = readstring();
		quest_objective_notify_time = time + 3;
	}
	if (event == CSQC_QUESTDETAILS)
	{
		float x;
		string id;
		string desc;

		id = readstring();
		desc = readstring();

		// Quest Log
		for (x = 0; x < quest_count; x++)
		{
			if (quest_log[x].id == id)
			{
				quest_log[x].description = desc;
				break;
			}
		}

		// NPC Preview
		if (quest_preview_id == id)
			quest_preview_description = desc;
	}
};

.vector prediction_error;
.float prediction_error_time;
void(float flIsNew) CSQC_Ent_Update =
{
    float flEntType = readbyte();

    if (flEntType == ENT_PLAYER)
    {
		float deltaFlags = readshort();

        if (flIsNew)
        {
            self.classname = "player";
            self.solid = SOLID_TRIGGER;
            self.predraw = Player_PreDraw;
            self.drawmask = MASK_ENGINE;
            self.view_ofs = '0 0 48';
            self.worldlight = TRUE;
            setsize(self, [-16, -16, 0], [16, 16, 56]);

            self.prediction_error = '0 0 0';
            self.prediction_error_time = 0;
        }

        vector oldOrigin = self.origin;

        // --- Update origin if flagged ---
        if (deltaFlags & ESF_ORIGIN)
        {
            self.origin_x = readcoord();
            self.origin_y = readcoord();
            self.origin_z = readcoord();

            // --- Local player auto-resync ---
            if (self.entnum == player_localentnum)
            {
				/*
                vPlayerOrigin = self.origin;
                vPlayerOriginOld = self.origin;
                vPlayerOriginOld_z = self.origin_z;
                vPlayerVelocity = self.velocity;
                */
                self.prediction_error_time = time;
            }
        }

        // --- Update other fields as usual ---
        if (deltaFlags & ESF_ANGLES) { self.angles_x = readcoord(); self.angles_y = readcoord(); self.angles_z = readcoord(); }
        if (deltaFlags & ESF_VELOCITY) { self.velocity_x = readcoord(); self.velocity_y = readcoord(); self.velocity_z = readcoord(); }
        if (deltaFlags & ESF_FLAGS) self.flags = readfloat();
        if (deltaFlags & ESF_EFFECTS) self.effects = readfloat();
        if (deltaFlags & ESF_MODEL) self.modelindex = readshort();
        if (deltaFlags & ESF_NAME) self.netname = readstring();
        if (deltaFlags & ESF_HEALTH) { self.health = readshort(); self.max_health = readshort(); }
        if (deltaFlags & ESF_LEVEL) self.level = readbyte();
        if (deltaFlags & ESF_PVP) self.pvp = readbyte();
        if (deltaFlags & ESF_EQUIPMENT) { self.main_hand = readstring(); self.off_hand = readstring(); self.armorname = readstring(); self.helmetname = readstring(); }
        if (deltaFlags & ESF_ANIMATION) { self.anistate = readbyte(); self.cast_finished = readbyte(); self.attack_type = readbyte(); self.blocking = readbyte(); }
        if (deltaFlags & ESF_MISC) { self.climbing = readbyte(); self.bonfire = readbyte(); self.crouch = readbyte(); self.dodgedir = readbyte(); self.stepdodge_counter = readbyte(); self.waterlevel = readbyte(); self.levitate_finished = readbyte(); self.melee_finished = readbyte();}

        if (flIsNew)
            setorigin(self, self.origin);

		entity_state_update(self, self.origin, self.angles, self.velocity, time);
    }

	//
	// Monsters
	//
	if (flEntType == ENT_MONSTER)
	{
        float deltaFlags = readshort();

		if (flIsNew)
		{
			self.classname = "monster";
			self.solid = SOLID_SLIDEBOX;
			self.predraw = Monster_PreDraw;
			self.drawmask = MASK_ENGINE;
			self.view_ofs = '0 0 48';
			self.worldlight = TRUE;
			self.movetype = MOVETYPE_STEP;
		}

		if (deltaFlags & ESF_ORIGIN)
		{
			self.origin_x = readcoord();
			self.origin_y = readcoord();
			self.origin_z = readcoord();
		}

		if (deltaFlags & ESF_ANGLES)
		{
			//self.angles_x = readcoord();
			self.angles_y = readcoord();
			self.angles_z = readcoord();
		}

		if (deltaFlags & ESF_VELOCITY)
		{
			self.velocity_x = readcoord();
			self.velocity_y = readcoord();
			self.velocity_z = readcoord();
		}

		if (deltaFlags & ESF_FLAGS)
			self.flags = readfloat();

		if (deltaFlags & ESF_EFFECTS)
			self.effects = readfloat();

		if (deltaFlags & ESF_MODEL)
			self.modelindex = readshort();

		if (deltaFlags & ESF_HEALTH)
		{
			self.health = readshort();
			self.max_health = readshort();
		}

		if (deltaFlags & ESF_MISC)
		{
			self.alpha = readbyte();
			self.displayname = readstring();
			self.speed = readbyte();
			self.level = readbyte();
			self.ai_mode = readbyte();
			self.movetype = readshort();
		}

		if (deltaFlags & ESF_EQUIPMENT)
		{
			self.main_hand = readstring();
			self.off_hand = readstring();
		}

		if (deltaFlags & ESF_ANIMATION)
		{
			self.anistate = readbyte();
			self.attack_speed = readbyte();
		}

		entity_state_update(self, self.origin, self.angles, self.velocity, time);
	}

	//
	// Water fountain
	//
	if (flEntType == ENT_FOUNTAIN)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "fountain";
			self.solid = SOLID_NOT;
			self.predraw = Fountain_PreDraw;
			self.drawmask = MASK_ENGINE;
		}
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
	}
	
	//
	// Wall Torch 1
	//
	if (flEntType == ENT_WALLTORCH1)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "walltorch1";
			self.solid = SOLID_NOT;
			self.predraw = WallTorch1_PreDraw;
			self.drawmask = MASK_ENGINE;
			setmodel(self, "models/walltorch1.glb");
		}
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.angles_x = readcoord();
		self.angles_y = readcoord();
		self.angles_z = readcoord();
	}

	//
	// Wall Torch 2
	//
	if (flEntType == ENT_WALLTORCH2)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "walltorch2";
			self.solid = SOLID_NOT;
			self.predraw = WallTorch2_PreDraw;
			self.drawmask = MASK_ENGINE;
			setmodel(self, "models/walltorch2.glb");
		}
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.angles_x = readcoord();
		self.angles_y = readcoord();
		self.angles_z = readcoord();
	}

	//
	// Dynamic Light
	//
	if (flEntType == ENT_DLIGHT)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "dlight";
			self.solid = SOLID_NOT;
			self.predraw = Dlight_PreDraw;
			self.drawmask = MASK_ENGINE;
		}
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();

		self.color_x = readcoord();
		self.color_y = readcoord();
		self.color_z = readcoord();

		self.pflags = readshort();
		self.light_lev = readshort();
		self.spawnflags = readshort();
		self.style = readbyte();
	}
	
	//
	// Bonfire
	//
	if (flEntType == ENT_BONFIRE)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "dlight";
			self.solid = SOLID_SLIDEBOX;;
			self.predraw = Bonfire_PreDraw;
			self.drawmask = MASK_ENGINE;
			setmodel(self, "models/bonfire.glb");
			setsize(self, [-16, -16, 0], [16, 16, 80]);
		}
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		setorigin(self, self.origin);
		ambientsound(self.origin, "bonfire2.wav", 0.5, ATTN_STATIC);
	}
	
	//
	// NPCS
	//
	if (flEntType == ENT_NPC)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "npc";
			self.solid = SOLID_SLIDEBOX;;
			self.predraw = NPC_PreDraw;
			self.drawmask = MASK_ENGINE;
			self.view_ofs = '0 0 48';
			self.worldlight = TRUE;
		}
		self.modelindex = readshort();
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.idealangles_x = readcoord();
		self.idealangles_y = readcoord();
		self.idealangles_z = readcoord();
		self.part_vfx = readbyte();

		setorigin(self, self.origin);
	}
	
	//
	// Allies (Guards, special NPCs)
	//
	if (flEntType == ENT_ALLY)
	{
        float deltaFlags = readshort();

		if (flIsNew)
		{
			self.classname = "ally";
			self.solid = SOLID_SLIDEBOX;
			self.predraw = Ally_PreDraw;
			self.drawmask = MASK_ENGINE;
			self.view_ofs = '0 0 48';
			self.worldlight = TRUE;
		}

		if (deltaFlags & ESF_ORIGIN)
		{
			self.origin_x = readcoord();
			self.origin_y = readcoord();
			self.origin_z = readcoord();
		}

		if (deltaFlags & ESF_ANGLES)
		{
			self.angles_x = readcoord();
			self.angles_y = readcoord();
			self.angles_z = readcoord();
		}

		if (deltaFlags & ESF_VELOCITY)
		{
			self.velocity_x = readcoord();
			self.velocity_y = readcoord();
			self.velocity_z = readcoord();
		}

		if (deltaFlags & ESF_FLAGS)
			self.flags = readfloat();

		if (deltaFlags & ESF_EFFECTS)
			self.effects = readfloat();

		if (deltaFlags & ESF_MODEL)
			self.modelindex = readshort();

		if (deltaFlags & ESF_HEALTH)
		{
			self.health = readshort();
			self.max_health = readshort();
		}

		if (deltaFlags & ESF_MISC)
		{
			self.alpha = readbyte();
			self.displayname = readstring();
			self.speed = readbyte();
			self.level = readbyte();
			self.ai_mode = readbyte();
		}

		if (deltaFlags & ESF_EQUIPMENT)
		{
			self.main_hand = readstring();
			self.off_hand = readstring();
		}

		if (deltaFlags & ESF_ANIMATION)
		{
			self.anistate = readbyte();
			self.attack_speed = readbyte();
		}

		entity_state_update(self, self.origin, self.angles, self.velocity, time);
	}
	
	//
	// Fishing Node
	//
	if (flEntType == ENT_FISHNODE)
	{
		deltaFlags = readshort();

		if (flIsNew)
		{
			self.classname = "fishing_node";
			self.solid = SOLID_NOT;
			self.predraw = FishNode_PreDraw;
			self.drawmask = MASK_ENGINE;
		}

		if (deltaFlags & ESF_ORIGIN)
		{
			self.origin_x = readcoord();
			self.origin_y = readcoord();
			self.origin_z = readcoord();
		}

		if (deltaFlags & ESF_HEALTH)
			self.health = readbyte();

		float is_alive = (self.health > 0);

		// Detect state change
		if (is_alive != self.was_alive)
		{
			if (is_alive)
			{
				// Fade IN
				setmodel(self, "models/fishschool.glb");
				self.alpha = 0;
				self.target_alpha = 1;
				self.fade_speed = 0.5;
			}
			else
			{
				// Fade OUT
				self.target_alpha = 0;
				self.fade_speed = 0.5;
			}

			self.was_alive = is_alive;
		}
	}
};

noref void CSQC_Shutdown() =
{
#ifdef CAMQUAKE
	spline_shutdown();
#endif
};