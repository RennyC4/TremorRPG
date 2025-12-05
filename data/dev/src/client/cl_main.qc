//
// CSQC - Main file
//

float(void) DrawDynamicLights =
{
    for (entity e = world; (e = find(e, classname, "dlight"));)
	{
		float dist = vlen(vPlayerOrigin - e.origin);

		if (vlen(e.origin - vPlayerOrigin) > 2000)
			continue;

		float lev = e.light_lev;
		float want_noshadow = 0;

		if (autocvar_tremor_lighting == "simple")
		{
			want_noshadow = 1;
			lev /= 1.5;
		}
		else if (e.spawnflags & 1)
		{
			want_noshadow = 1;
			lev /= 1.5;
		}

		if (want_noshadow)
			e.pflags |= PFLAGS_NOSHADOW;
		else
			e.pflags &= ~PFLAGS_NOSHADOW;

		if (e.spawnflags & 2)
			e.pflags |= PFLAGS_CORONA;
		else
			e.pflags &= ~PFLAGS_CORONA;

		if (lev < 5) lev = 5; // stop dlight culling flicker

		dynamiclight_add(e.origin, lev, [e.color_x, e.color_y, e.color_z], e.style, "", e.pflags);
	}
};

void() CSQC_DrawMonsterPlaques;

// ========================
// Player Send Flags (PSF)
// ========================

// Bit positions (max 16 for two bytes)
#define PSF_ORIGIN        1       // 0b0000000000000001
#define PSF_ANGLES        2       // 0b0000000000000010
#define PSF_VELOCITY      4       // 0b0000000000000100
#define PSF_FLAGS         8       // 0b0000000000001000
#define PSF_EFFECTS       16      // 0b0000000000010000
#define PSF_MODEL         32      // 0b0000000000100000
#define PSF_NAME          64      // 0b0000000001000000
#define PSF_HEALTH        128     // 0b0000000010000000

// Second byte (shifted by 8)
#define PSF_LEVEL         256     // 0b0000000100000000
#define PSF_PVP           512     // 0b0000001000000000
#define PSF_EQUIPMENT     1024    // 0b0000010000000000
#define PSF_ANIMATION     2048    // 0b0000100000000000
#define PSF_MISC          4096    // 0b0001000000000000

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
	registercommand("+showscores", "Show scoreboard");
	registercommand("show_character", "Displays character information screen\n");
	registercommand("show_inventory", "Displays inventory information screen\n");
	registercommand("show_magic", "Displays magic information screen\n");
	registercommand("toggle_crouch", "Crouching & sneaking\n");
	registercommand("toggle_camera", "3rd person camera toggle\n");
	registercommand("+use", "Use what is in front of player\n");

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
};

void(string rendererdescription) CSQC_RendererRestarted =
{
	localcmd("exec haze.cfg\n");
};

void() CSQC_DayNight_Update =
{
	// update entity lighting on world map client-side, SSQC -> CSQC use inverted abslight values for some reason
	for (entity c = world;(c = findfloat(c, worldlight, TRUE));)
	{
		float light;

		c.drawflags = 7;
		if (timeofday == TIME_DAY)
			light = 1;
		else if (timeofday == TIME_NIGHT)
			light = 225;
		else if (timeofday == TIME_DAWN)
			light = 140;
		else
			light = 190;

		c.abslight = 255 - light;
	}
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

	if (!player_menu && !atbonfire)
	{
		// Tremor Jump / Dodge / Climb
		if (argv(0) == "+t_jump")
			User_DoJump = TRUE;
		if (argv(0) == "-t_jump")
			User_DoJump = FALSE;

		 // Tremor Attack
		if (argv(0) == "t_attack")
			User_DoAttack = TRUE;
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
		sendevent("PlayerShowStats", "");
	if (argv(0) == "show_inventory")
		sendevent("PlayerShowInventory", "");
	if (argv(0) == "show_magic")
		sendevent("PlayerShowMagic", "");
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

// CGAMEPACKET events
const float CSQC_INVENTORY = 1;
const float CSQC_NPCINFO = 2;
const float CSQC_INVENTORY_NPC = 3;
const float CSQC_TIMEOFDAY = 4;
const float CSQC_MOTD = 5;
const float CSQC_MAGIC = 6;
const float CSQC_LASTLOGIN = 7;
const float CSQC_WRITESPARM = 8;
const float CSQC_READSPARM = 9;
const float CSQC_WIPESPARM = 10;
const float CSQC_SAY = 11;
const float CSQC_SAY_NEARBY = 12;

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
		string msg = readstring();
		entity speaker = findfloat(world, entnum, entread);

		//print("Received nearby msg from ent:", ftos(entnum), " text:", msg, "\n"); // DEBUG

		if (speaker)
			FloatingText_Add(speaker, msg);
	}

};

.vector prediction_error;
.float prediction_error_time;
void(float flIsNew) CSQC_Ent_Update =
{
    float flEntType = readbyte();

    if (flEntType == ENT_PLAYER)
    {
        float deltaFlags1 = readbyte();
        float deltaFlags2 = readbyte();
        float deltaFlags = deltaFlags1 + (deltaFlags2 * 256);

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
        if (deltaFlags & PSF_ORIGIN)
        {
            self.origin_x = readcoord();
            self.origin_y = readcoord();
            self.origin_z = readcoord();

            self.prev_origin = self.last_origin;
            self.last_origin = self.origin;
            self.last_update_time = time;

            // --- Local player auto-resync ---
            if (self.entnum == player_localentnum)
            {
                vPlayerOrigin = self.origin;
                vPlayerOriginOld = self.origin;
                vPlayerOriginOld_z = self.origin_z;
                vPlayerVelocity = self.velocity;
                self.prediction_error_time = time;
            }
        }

        // --- Update other fields as usual ---
        if (deltaFlags & PSF_ANGLES) { self.angles_x = readcoord(); self.angles_y = readcoord(); self.angles_z = readcoord(); }
        if (deltaFlags & PSF_VELOCITY) { self.velocity_x = readshort(); self.velocity_y = readshort(); self.velocity_z = readshort(); }
        if (deltaFlags & PSF_FLAGS) self.flags = readfloat();
        if (deltaFlags & PSF_EFFECTS) self.effects = readfloat();
        if (deltaFlags & PSF_MODEL) self.modelindex = readshort();
        if (deltaFlags & PSF_NAME) self.netname = readstring();
        if (deltaFlags & PSF_HEALTH) { self.health = readshort(); self.max_health = readshort(); }
        if (deltaFlags & PSF_LEVEL) self.level = readbyte();
        if (deltaFlags & PSF_PVP) self.pvp = readbyte();
        if (deltaFlags & PSF_EQUIPMENT) { self.main_hand = readstring(); self.off_hand = readstring(); self.armorname = readstring(); }
        if (deltaFlags & PSF_ANIMATION) { self.anistate = readbyte(); self.cast_finished = readbyte(); self.attack_type = readbyte(); self.blocking = readbyte(); }
        if (deltaFlags & PSF_MISC) { self.climbing = readbyte(); self.bonfire = readbyte(); self.crouch = readbyte(); self.dodgedir = readbyte(); self.stepdodge_counter = readbyte(); }

        if (flIsNew)
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
			self.worldlight = TRUE;
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
		self.attack_speed = readbyte();
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
			self.classname = "bonfire";
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
		ambientsound(self.origin, "bonfire2.wav", 1, ATTN_STATIC);
	}
};

noref void CSQC_Shutdown() =
{
#ifdef CAMQUAKE
	spline_shutdown();
#endif
};