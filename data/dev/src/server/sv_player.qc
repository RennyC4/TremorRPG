//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc
//

float(entity ePVEnt, float flChanged) Player_SendEntity;

void() ClientConnect = {};
void() CSEv_ShutDownMenus = {stuffcmd (self, sprintf("play %s\n", "menu/menu_close.wav"));self.menu = MENU_OFF;};
void(entity targ, float type) CSEv_Player_SaveChar;
void(entity player) SendPlayerInventory;
void(entity player) SendMagicSpells;
void() ClientKill = {};
void() SetNewParms = {};
void(float elapsedtime) SV_PausedTic = {};
void() info_player_start = {};
void(string LOGIN_NAME) CSEv_ResumeCharacter_s;

#define player_dimension_hit 1
#define player_dimension_solid 2

//
// Parms - for map transfers
//

void(string reads1, string reads2, string reads3, string reads4, string reads5) CSEv_SSQC_ReadsParms_sssss =
{
	self.main_hand = reads1;
	self.off_hand = reads2;
	self.armorname = reads3;
	self.spell_equipped = reads4;
	self.armorname = reads5;
};

void() WipeParms =
{
	parm1 = 0;
	parm2 = 0;
	parm3 = 0;
	parm4 = 0;
	parm5 = 0;
	parm6 = 0;
	parm7 = 0;
	parm8 = 0;
	parm9 = 0;
	parm10 = 0;
	parm11 = 0;
	parm12 = 0;
	parm13 = 0;
	parm14 = 0;
	parm15 = 0;
	parm16 = 0;
	parm17 = 0;
	parm18 = 0;
	parm19 = 0;
	parm20 = 0;
	parm21 = 0;
	parm22 = 0;
	parm23 = 0;
	parm24 = 0;
	parm25 = 0;
	parm26 = 0;
};

void() SetChangeParms =
{
	CSEv_Player_SaveChar(self, 1); // map transfer save user character before map change (saves inventory/spells properly etc)

	// write updated client string parms
	msg_entity = self;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_WRITESPARM);
	multicast(self.origin, MULTICAST_ONE_R);
	//

	parm1 = self.loggedin;
	parm2 = self.spawnloc;
	parm3 = self.health;
	parm4 = self.max_health;
	parm5 = self.mana;
	parm6 = self.max_mana;
	parm7 = self.gold;
	parm8 = self.exp;
	parm9 = self.exp_next;
	parm10 = self.level;
	parm11 = self.skillpoints;
	parm12 = self.attack_power_min;
	parm13 = self.attack_power_max;
	parm14 = self.attack_speed;
	parm15 = self.attack_type;
	parm16 = self.attack_stamina;
	parm17 = self.attack_length;
	parm18 = self.armorvalue;
	parm19 = self.blockvalue;
	parm20 = self.spell_power_min;
	parm21 = self.spell_power_max;
	parm22 = self.skill_mining;
	parm23 = self.skill_fishing;
	parm24 = self.skill_woodcutting;
	parm25 = self.lantern;
	parm26 = self.camera_toggle;
};

void() SetCheckParms =
{
	self.loggedin = parm1;
	self.spawnloc = parm2;
	self.health = parm3;
	self.max_health = parm4;
	self.mana = parm5;  
	self.max_mana = parm6;
	self.gold = parm7;
	self.exp = parm8;
	self.exp_next = parm9;
	self.level = parm10;
	self.skillpoints = parm11;
	self.attack_power_min = parm12;
	self.attack_power_max = parm13;
	self.attack_speed = parm14;
	self.attack_type = parm15;
	self.attack_stamina = parm16;
	self.attack_length = parm17;
	self.armorvalue = parm18;
	self.blockvalue = parm19;
	self.spell_power_min = parm20;
	self.spell_power_max = parm21;
	self.skill_mining = parm22;
	self.skill_fishing = parm23;
	self.skill_woodcutting = parm24;
	self.lantern = parm25;
	self.camera_toggle = parm26;
};

void() SetCheckStringParms = // read updated client string parms
{
	msg_entity = self;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_READSPARM);
	multicast(self.origin, MULTICAST_ONE_R);
};

//

.float climb_stamina_finished;
void() PlayerClimb =
{
	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 24, MOVE_NORMAL, self);

	if (trace_fraction == 1)
		return;
	if (self.climb_finished > time)
		return;
	if (self.levitate_finished > time)
		return;

	float climbcalc = 50 + (self.skill_climb * 0.35); // speed calculation
	float stamcalc = 0.01 + (self.skill_climb * 0.0005); // stamina calculation

	if (trace_ent.solid == SOLID_BSP)
	{
		if (self.stamina > 0)
		{
			self.inair_count = 0; // reset inair counter on climbing
			self.fall_maxspeed = 0;
			self.climbing = TRUE;
			self.velocity = [0, 0];
			self.velocity_z += climbcalc;
			self.flags &= ~FL_ONGROUND;
			self.flags &= ~FL_PARTIALGROUND;
			if (self.climb_stamina_finished < time)
			{
				self.stamina -= 1;
				self.climb_stamina_finished = time + stamcalc;
			}
		}
		else
		{
			self.stamina = 0;
			self.climb_finished = time + 3;
		}
	}

	// check for ledge to climb over
	makevectors (self.angles);
	vector start = self.origin;
	start_z += 8;
	v_forward_z = 0;
	normalize(v_forward);
	vector end = start + v_forward * 24;

	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward * 24;
		self.movedir = trace_plane_normal * -50;

		traceline (start, end, TRUE, self);
		if (trace_fraction == 1) // empty air
			self.velocity_z = 225;
	}
};

void() Player_RemoveCrouch =
{
	vector from = self.origin;
	vector mins = [-16, -16, 0];
	vector maxs = [16, 16, 56]; // standing bbox

	tracebox(from, mins, maxs, from, MOVE_NOMONSTERS, self);

	if (trace_fraction) // trace is clear
	{
		self.crouch = FALSE;
		self.view_ofs = [0, 0, 48];
		setsize (self, mins, maxs);
	}
};

void() CSEv_PlayerJump =
{
    if (self.bonfire)
        return;
    if (self.dodge_finished > time)
        return;
	if (self.spellani_finished > time)
		return;
    if (self.stagger_finished > time)
        return;

    PlayerClimb();

    if (self.climbing)
        return;
    if (self.melee_finished > time)
        return;
	if (self.fishcast_finished > time) // fishing
		return;
	if (self.fishing_finished > time) // fishing
		return;
    if (!(self.flags & FL_ONGROUND))
        return;
    if (self.menu == MENU_CHARACTER || self.menu == MENU_INVENTORY || 
        self.menu == MENU_MAGIC || self.menu == MENU_BANKING)
        return;

    // Skill-based calculations
    float stamcalc = self.skill_acrobatic * 0.35;
    float jumpcalc = self.skill_acrobatic * 1.1;

    // Cap
    if (stamcalc > 35)
        stamcalc = 35;

    // Cap jump bonus to avoid excessive height
    float maxJumpBonus = 150; // tweak as needed
    if (jumpcalc > maxJumpBonus)
        jumpcalc = maxJumpBonus;

    // Optional minimum stamina cost
    float staminaCost = max(5, 35 - stamcalc);

    if (self.stamina >= staminaCost)
    {
        Player_RemoveCrouch();
		// You should be able to jump out of spell casting
		if (self.cast_finished > time)
		{
			self.cast_finished = time;
			self.cast_finished_spell = ""; // important: always clear this after the spell is fired, or else it'll refire
			self.anistate = ANISTATE_NONE;
			sprint (self, PRINT_HIGH, "^1Spell cancelled!\n");
		}
		if (self.potion_use_finished > time) // cancel potion use
		{
			self.healthpot_heal_rate = self.healthpot_heal_remaining = 0;
			self.healthpot_finished = time;
			self.manapot_heal_rate = self.manapot_heal_remaining = 0;
			self.manapot_finished = time;
			self.potion_use_finished = time;
		}

        // Perform jump
        self.velocity_z = (270 + jumpcalc);
        self.weaponframe = 0;
        self.pressedJump = TRUE; // Air melee check
        self.stamina -= staminaCost;
		if (self.levitate_finished < time) // do not overwrite levitation state
			self.anistate = ANISTATE_JUMP;
    }
};

void(float whichdir) CSEv_PlayerDodge_f =
{
	if (self.bonfire)
		return;
	if (self.spellani_finished > time)
		return;
	if (self.climbing)
		return;

// You should be able to dodge out of stagger
//	if (self.stagger_finished > time)
//		return;

	if (self.dodge_finished > time)
		return;
	if (self.melee_finished > time)
		return;
	if (self.fishcast_finished > time) // fishing
		return;
	if (self.fishing_finished > time) // fishing
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (self.menu == MENU_CHARACTER || self.menu == MENU_INVENTORY || self.menu == MENU_MAGIC || self.menu == MENU_BANKING)
		return;

	if (self.stamina >= 25)
	{
		// You should be able to dodge out of spell casting
		if (self.cast_finished > time)
		{
			self.cast_finished = time;
			self.cast_finished_spell = ""; // important: always clear this after the spell is fired, or else it'll refire
			self.anistate = ANISTATE_NONE;
			sprint (self, PRINT_HIGH, "^1Spell cancelled!\n");
		}

		if (self.potion_use_finished > time) // cancel potion use
		{
			self.healthpot_heal_rate = self.healthpot_heal_remaining = 0;
			self.healthpot_finished = time;
			self.manapot_heal_rate = self.manapot_heal_remaining = 0;
			self.manapot_finished = time;
			self.potion_use_finished = time;
		}

		self.stamina -= 25;
		self.dodgedir = whichdir;
		//print (ftos(self.dodgedir), "\n");

		if (whichdir == 8)
		{
			self.godmode_finished = time + 0.35;
			self.dodge_finished = time + 0.5;
			if (self.main_hand != "Fishing Rod")
				self.stepdodge_counter = time + 1;
			self.anistate = ANISTATE_STEPDODGE;
		}
		else
		{
			self.godmode_finished = time + 0.2;
			self.dodge_finished = time + 0.8;
			self.anistate = ANISTATE_DODGE;
		}

		self.velocitypush_finished = self.dodge_finished;
		self.lockview_finished = self.dodge_finished;
		self.stagger_finished = time; // remove stagger on dodge

		Player_RemoveCrouch(); // remove crouch
	}
};

// camera toggle from csqc -> ssqc for various reasons
void(float toggle) CSEv_CameraToggle_f =
{
	if (self.menu != MENU_OFF)
		return;

	if (!toggle)
		self.camera_toggle = FALSE;
	else
		self.camera_toggle = TRUE;
};

// pitch update from CSQC
void(vector ang) CSEv_PitchUpdate_v =
{
	if (!ang)
		return;

	makevectors (ang);
	self.angles_x = ang_x;
	self.fixangle = TRUE;
};

void() CSEv_PlayerCrouch =
{
	if (!self.loggedin)
		return;
	if (self.blocking)
		return;
	if (self.deadflag == DEAD_DEAD || self.health <= 0)
		return;
	if (self.potion_use_finished > time)
		return;
	if (self.bonfire)
		return;
	if (self.melee_finished > time)
		return;
	if (self.fishcast_finished > time) // fishing
		return;
	if (self.fishing_finished > time) // fishing
		return;
	if (self.stagger_finished > time)
		return;
	if (self.cancast_finished > time) // for insta-cast spells
		return;
	if (self.cast_finished > time)
		return;
	if (self.spellani_finished > time)
		return;

	// --- Entering crouch ---
	if (!self.crouch)
	{
		setsize(self, [-16, -16, 0], [16, 16, 28]);
		self.view_ofs = [0, 0, 24];
		self.crouch = TRUE;
	}
	else
		Player_RemoveCrouch();
};

void() SV_RunClientCommand =
{
	input_buttons &= ~2; // taking over +jump
	runstandardplayerphysics(self);
};

// function used for helping developer placing objects in terrain mode + cheats 
void() Player_DeveloperBind =
{
	if (cvar("developer") > 0 ||  cvar("sv_cheats") > 0)
	{
		string pos_x = ftos(self.origin_x);
		string pos_y = ftos(self.origin_y);
		string pos_z = ftos(self.origin_z);

		string ang_x = ftos(self.angles_x);
		string ang_y = ftos(self.angles_y);
		string ang_z = ftos(self.angles_z);

		sprint(self, PRINT_HIGH, "Coords: ", pos_x, " ", pos_y, " ", pos_z);
		sprint(self, PRINT_HIGH, "\nAngles: ", ang_x, " ", ang_y, "\n");
	}

	if (cvar("sv_cheats") > 0) // give cheat stats
	{
		self.skillpoints = 99999;
		self.gold = 99999;
		self.level ++;
		self.mana = self.max_mana;
		self.health = self.max_health;

		AddToInventory(self, "Health Potion", 1);
		AddToInventory(self, "Mana Potion", 1);
		AddToInventory(self, "Small Fish", 10); // debug item
	}
};

// called from CSQC ("show_character" console command)
void() CSEv_PlayerShowStats = 
{
	if (self.deadflag != DEAD_NO)
		return;
	
	if (self.menu == MENU_CHARACTER)
	{
		self.menushut_finished = time + 0.2; // prevent +attack misfire
		self.menu = MENU_OFF;
		stuffcmd (self, sprintf("play %s\n", "menu/menu_close.wav")); // sound
	}
	else if (self.menu == MENU_INVENTORY || self.menu == MENU_MAGIC || self.menu == MENU_OFF)
	{
		if (self.menu == MENU_OFF)
			stuffcmd (self, sprintf("play %s\n", "menu/menu_open.wav")); // sound
		else
			stuffcmd (self, sprintf("play %s\n", "menu/menu_next.wav")); // sound
		self.menu = MENU_CHARACTER;
	}
};

// called from CSQC ("show_inventory" console command + button)
void() CSEv_PlayerShowInventory = 
{
	if (self.deadflag != DEAD_NO)
		return;

	if (self.menu == MENU_INVENTORY)
	{
		self.menushut_finished = time + 0.2; // prevent +attack misfire
		self.menu = MENU_OFF;
		stuffcmd (self, sprintf("play %s\n", "menu/menu_close.wav")); // sound
	}
	else if (self.menu == MENU_CHARACTER || self.menu == MENU_MAGIC || self.menu == MENU_OFF)
	{
		if (self.menu == MENU_OFF)
			stuffcmd (self, sprintf("play %s\n", "menu/menu_open.wav")); // sound
		else
			stuffcmd (self, sprintf("play %s\n", "menu/menu_next.wav")); // sound
		self.menu = MENU_INVENTORY;
	}		
};

// called from CSQC ("show_magic" console command)
void() CSEv_PlayerShowMagic = 
{
	if (self.deadflag != DEAD_NO)
		return;

	if (self.menu == MENU_MAGIC)
	{
		self.menushut_finished = time + 0.2; // prevent +attack misfire
		self.menu = MENU_OFF;
		stuffcmd (self, sprintf("play %s\n", "menu/menu_close.wav")); // sound
	}
	else if (self.menu == MENU_CHARACTER || self.menu == MENU_INVENTORY || self.menu == MENU_OFF)
	{
		if (self.menu == MENU_OFF)
			stuffcmd (self, sprintf("play %s\n", "menu/menu_open.wav")); // sound
		else
			stuffcmd (self, sprintf("play %s\n", "menu/menu_next.wav")); // sound
		self.menu = MENU_MAGIC;
	}
};

// called from CSQC button
void() CSEv_PlayerShowBuySell = {stuffcmd (self, sprintf("play %s\n", "menu/menu_next.wav"));self.menu = MENU_BUYSELL;};
void() CSEv_PlayerShowDialogue = {stuffcmd (self, sprintf("play %s\n", "menu/menu_next.wav"));self.menu = MENU_DIALOGUE;};
void() CSEv_PlayerShowBanking = {stuffcmd (self, sprintf("play %s\n", "menu/menu_next.wav"));self.menu = MENU_BANKING;};

// called from CSQC (PVP button)
void() CSEv_User_TogglePVP_ =
{
	if (self.deadflag != DEAD_NO)
		return;
	if (self.pvp_autoflagged)
		return;

	if (!self.pvp)
	{
		sprint(self, PRINT_HIGH, "PVP: ^8Unavailable\n");
		stuffcmd (self, sprintf("play %s\n", "menu/btn_generic.wav"));
		return;
	}

	// Disable PVP
	if (self.pvp == 1)
	{
		self.pvp = 2;
		sprint(self, PRINT_HIGH, "PVP: ^2Disabled\n");
		stuffcmd (self, sprintf("play %s\n", "menu/btn_pvp.wav"));
		return;
	}

	// switch dimension hit then run the trace
	self.dimension_hit = player_dimension_hit + 1;
	tracebox(self.origin, self.mins, self.maxs, self.origin, MOVE_NORMAL, self);

	if (trace_startsolid)
	{
		sprint(self, PRINT_HIGH, "PVP: ^3Can't enable, too close to another player!\n");
		self.dimension_hit = player_dimension_hit;
		return;
	}

	self.pvp = 1;
	sprint(self, PRINT_HIGH, "PVP: ^1Enabled\n");
	stuffcmd (self, sprintf("play %s\n", "menu/btn_pvp.wav"));
};

void() CheckImpulses =
{
	switch (self.impulse)
	{
		case 1:
			Player_DeveloperBind(); // Debugging
		break;
		default:
			break;
	}
	self.impulse = 0;
};

entity() get_spawn_point =
{
	entity spawnpoint;

	for (spawnpoint = world; (spawnpoint = find(spawnpoint, classname, "info_player_start"));)
	{
		if (spawnpoint.spawnloc == self.spawnloc)
			return spawnpoint;
	}
	return find(world, classname, "info_player_start"); // fallback: just return the first info_player_start
};

//
// Use button
//

void() Player_Use =
{
	if (self.bonfire && self.bonfire_finished < time)
	{
		Player_RemoveCrouch(); // remove crouch
		self.movetype = MOVETYPE_WALK; // start movement

		string eventlog_print = "^5You stand back up ...\n";
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
		self.anistate = ANISTATE_NONE;
		self.bonfire = FALSE;
		self.bonfire_finished = time + 1; // fixes input bleed
		self.pvp_autoflagged = FALSE;
		self.pvpenable_count = 0;
		CSEv_Player_SaveChar(self, 0); // full save
		return;
	}

	if (self.menu)
		return;

	makevectors (self.angles);
	vector source = self.origin;
	source = self.origin + self.view_ofs;
	traceline (source, source + v_forward * USEDISTANCE, MOVE_ENTCHAIN, self);

	if (trace_ent.th_use)
	{
		trace_ent.user = self;
		trace_ent.think = trace_ent.th_use;
		trace_ent.nextthink = time + 0.1;
	}
	else
		sprint(self, PRINT_HIGH, "There's nothing there ...\n");

	self.button3_pressed = TRUE;
};

//
// Block button
//

void() Player_ShieldBlock =
{
	if (self.blockvalue <= 0)
		return;
	if (self.fishcast_finished > time) // fishing
		return;
	if (self.fishing_finished > time) // fishing
		return;

	if (self.melee_finished < time && self.stagger_finished < time)
	{
		if (!self.blocking)
		{
			if (self.parry_finished < time && self.parry_cooldown_finished < time)
			{
				self.parry_finished = time + 0.135; // success window
				self.parry_cooldown_finished = time + 0.8;
			}			
		}
		self.blocking = TRUE;
	}
	else
		self.blocking = FALSE;
};

//
// Fall Damage
//

float() FallDamage_MediumMul =
{
    if (self.waterlevel >= 3)
        return FALL_WATER_MUL_LVL3;
    if (self.waterlevel >= 2)
        return FALL_WATER_MUL_LVL2;
    if (self.watertype == CONTENT_SLIME)
        return FALL_SLIME_MUL;
    if (self.watertype == CONTENT_LAVA)
        return FALL_LAVA_MUL;
    return 1; // normal air
};

void() FallDamage_Update =
{
    if (self.movetype == MOVETYPE_NOCLIP || self.health <= 0 || self.deadflag == DEAD_DEAD)
    {
        self.fall_maxspeed = 0;
        self.was_onground = (self.flags & FL_ONGROUND) != 0;
        return;
    }

    // While airborne, keep the largest downward speed seen this airtime
    if (!(self.flags & FL_ONGROUND) && !self.climbing)
    {
		self.inair_count += 1;
		if (self.inair_count >= 12 && !self.waterlevel && !self.climbing && self.levitate_finished < time)
			self.lockview_finished = time + 0.1; // lock view when leaving ground, but not over small inclines (climbing is fine)
        float down = - self.velocity_z; // positive when falling
        if (down > self.fall_maxspeed)
            self.fall_maxspeed = down;
    }

    // Landing
    if ((self.flags & FL_ONGROUND) && !self.was_onground)
    {
		self.inair_count = 0;
        // small guard against multiple hits in the same frame slice
        if (time - self.last_landtime > LAND_COOLDOWN)
        {
            float impact = self.fall_maxspeed - (self.skill_acrobatic / 2);
            float mul = FallDamage_MediumMul(); // cushion media reduces impact
            impact *= mul;

            // Reset for next airtime *before* any early exits
            self.fall_maxspeed = 0;
            self.last_landtime = time;

            // Soft landing sound only
            if (impact > FALL_SOFT_SPEED && impact <= FALL_DAMAGE_SPEED)
				sound (self, CHAN_AUTO, "land1.wav", 1, ATTN_NORM);
            // Damage
            else if (impact > FALL_DAMAGE_SPEED)
            {
                float dmg = (impact - FALL_DAMAGE_SPEED) * FALL_SCALE;
				dmg = ceil(dmg);
				DoDamage(self, world, dmg, TRUE);
                sound (self, CHAN_AUTO, "land2.wav", 1, ATTN_NORM);
            }
        }
        self.fall_maxspeed = 0;
    }
    self.was_onground = (self.flags & FL_ONGROUND) != 0;
};

.float swim_stamina_finished;
.float underwatersfx_finished;
.float drowning_finished;
void() WaterUpdate =
{
	if (self.waterlevel > 1)
	{
		if (self.lantern)
		{
			sound(self, CHAN_AUTO, "lantern.wav", 0.25, ATTN_NORM);
			sprint(self, PRINT_HIGH, strcat("Lantern is unlit\n"));
			self.effects &= ~EF_BRIGHTLIGHT;
			self.lantern = FALSE;
		}

		if (self.waterlevel >= 3)
		{

			if (self.underwatersfx_finished < time)
			{
				stuffcmd (self, sprintf("play %s\n", "inwater.wav")); // sound
				self.underwatersfx_finished = time + 9.9;
			}
		}
		else
		{
			if (self.underwatersfx_finished > time)
			{
				stuffcmd (self, sprintf("stopsound %s\n", "inwater.wav")); // sound
				self.underwatersfx_finished = time;
			}
		}

		float stamcalc = 0.01 + (self.skill_swim * 0.0025); // stamina calculation
		if (self.stamina > 0)
		{
			if (self.swim_stamina_finished < time)
			{
				self.stamina -= 1;
				self.swim_stamina_finished = time + stamcalc;
			}
		}
		else
		{
			if (self.drowning_finished < time)
			{
				if (ceil(self.health > self.max_health / 5))
					DoDamage(self, world, ceil(self.max_health / 5), TRUE); // drowning
				else
					DoDamage(self, world, self.max_health, TRUE); // drowned
				self.drowning_finished = time + 3;
			}
		}
	}
};

void(float speed) Player_VelocityPush =
{
	// Extra check to ensure that players dodgedir doesn't hang
	if (self.dodge_finished < time && self.dodgedir != 0)
		self.dodgedir = 0;

    if (self.velocitypush_finished < time)
        return;
    if (!(self.flags & FL_ONGROUND))
        return;
    if (self.deadflag == DEAD_DEAD)
        return;

    makevectors([0, self.angles_y, 0]);

	if (!self.dodgedir)
		self.velocity = v_forward * speed;
	else if (self.dodgedir == 1)
		self.velocity = -v_right * speed;
	else if (self.dodgedir == 2)
		self.velocity = v_right * speed;
	else if (self.dodgedir == 3)
		self.velocity = -v_forward * speed;
	else if (self.dodgedir == 4)
		self.velocity = normalize((-v_right) + (-v_forward)) * speed;
	else if (self.dodgedir == 5)
		self.velocity = normalize((-v_right) + (v_forward)) * speed;
	else if (self.dodgedir == 6)
		self.velocity = normalize((v_right) + (-v_forward)) * speed;
	else if (self.dodgedir == 7)
		self.velocity = normalize((v_right) + (v_forward)) * speed;
	else
		self.velocity = -v_forward * speed;

	self.flags &= ~FL_ONGROUND;
	self.flags &= ~FL_PARTIALGROUND;
};

// Helper: Check if all attack cooldowns are ready
float() CanAttack =
{
    return (self.melee_finished < time &&
            self.cancast_finished < time &&
			self.stagger_finished < time &&
            self.cast_finished < time &&
			self.potion_use_finished < time &&
            self.menushut_finished < time);
};

// Main SSQC attack function
void() CSEv_User_StartAttack_ =
{
    if (self.dodge_finished > time || self.menu != MENU_OFF || self.bonfire)
        return;

    // Dead / respawn check
    if (self.deadflag == DEAD_DEAD || self.health <= 0)
    {
        if (self.respawn_finished < time)
        {
            PlayerSpawn(3); // respawn
            // Reset timers to avoid stuck states
            self.melee_finished = time + 1;
            self.cancast_finished = time;
            self.cast_finished = time;
            self.lockview_finished = time;
            self.velocitypush_finished = time;
            self.stepdodge_counter = time;
            self.anistate = ANISTATE_NONE;
            return;
        }
        else
            return;
    }

    // Blocking with shield
    if (self.blocking && self.blockvalue > 0)
    {
        self.anistate = ANISTATE_BASH;
        DoAttack_ShieldBash();
        return;
    }

    // Main attack logic
    if (!self.blocking && CanAttack())
    {
        float stamcalc = self.skill_endurance * 0.015;
        float requiredStamina = self.attack_stamina - stamcalc;

        if (self.stamina < requiredStamina || self.button4)
            return;

        // Deduct stamina
        self.stamina -= requiredStamina;

		// Air melee attack priority with ground distance check
		if (!(self.flags & FL_ONGROUND) && self.attack_type != 4 && self.pressedJump)
		{
			if (self.main_hand != "Fishing Rod")
			{
				self.anistate = ANISTATE_AIRMELEE;
				self.melee_finished = time + self.attack_speed;
				self.velocitypush_finished = time + (self.attack_speed / 4);
				self.lockview_finished = time + self.attack_speed;
				return;
			}
			else
			{
				self.anistate = ANISTATE_JUMP;
				self.melee_finished = time;
				self.velocitypush_finished = time;
				self.lockview_finished = time + self.attack_speed;

			}
		}

        // Ground attacks
        float nobow = FALSE;

        if (self.stepdodge_counter >= time)
        {
            // Step counter interrupts normal attack
            self.anistate = ANISTATE_STEPCOUNTER;
            self.melee_finished = time + 1.5;
            self.lockview_finished = time + 1.5;
            self.velocitypush_finished = time + 0.75;
            self.stepdodge_counter = time; // Turn off counter
        }
        else
        {
            // Select attack type
            if (self.attack_type == 0)
			{
				if (self.main_hand == "Fishing Rod")
					self.anistate = ANISTATE_FISHCAST;
				else
					self.anistate = ANISTATE_PUNCH;
			}
            else if (self.attack_type == 1)
                self.anistate = ANISTATE_SLASH;
            else if (self.attack_type == 2)
                self.anistate = ANISTATE_STAB;
            else if (self.attack_type == 3)
                self.anistate = ANISTATE_SMASH;
            else if (self.attack_type == 4)
            {
                string lname = string_tolower(self.off_hand);
                if (strstrofs(lname, "bow", 0) != -1 && self.flags & FL_ONGROUND)
                    self.anistate = ANISTATE_ARCHERY;
                else
                    nobow = TRUE;
            }
            else
            {
                print("Error: Unknown attack_type in User_StartAttack\n");
                return;
            }

            // Set cooldown timers
            if (!nobow)
            {
				if (self.main_hand == "Fishing Rod")
						self.melee_finished = time + 9999;
					else
						self.melee_finished = time + self.attack_speed;

                if (self.attack_type != 4)
				{
					if (self.main_hand != "Hatchet" && self.main_hand != "Mining Pick" && self.main_hand != "Fishing Rod") // job equippables do not push players
						self.velocitypush_finished = time + (self.attack_speed / 4);

					if (self.main_hand == "Fishing Rod")
						self.lockview_finished = time + 9999;
					else
						self.lockview_finished = time + self.attack_speed; // bows don't lock player view
				}
            }
        }
    }
};

//
// Special animation states sent to CSQC
//

void() Anistate_Handler =
{
	// Tied to stagger_finished
	if (self.anistate == ANISTATE_STUNNED || self.anistate == ANISTATE_IMPACT)
	{
		if (self.stagger_finished < time)
			self.anistate = ANISTATE_NONE;
	}

	if (self.anistate == ANISTATE_FISHCAST)
	{
		if (self.fishing_finished > time)
			self.anistate = ANISTATE_FISHIDLE;
		return;
	}

	// Tied to melee_finished
	if (self.anistate == ANISTATE_SLASH || self.anistate == ANISTATE_STAB || self.anistate == ANISTATE_PUNCH || self.anistate == ANISTATE_BASH
	|| self.anistate == ANISTATE_PARRY || self.anistate == ANISTATE_SMASH || self.anistate == ANISTATE_ARCHERY || self.anistate == ANISTATE_BLOCK
	|| self.anistate == ANISTATE_AIRMELEE || self.anistate == ANISTATE_STEPCOUNTER)// || self.anistate == ANISTATE_FISHCAST)
	{
		if (self.anistate == ANISTATE_AIRMELEE)
		{
			if (self.melee_finished < time && self.flags & FL_ONGROUND)
			{
				Player_RemoveCrouch();
				self.anistate = ANISTATE_NONE;
			}
		}
		else
		{
			if (self.melee_finished < time)
			{
				Player_RemoveCrouch();
				self.anistate = ANISTATE_NONE;
			}
		}
	}

	// Tied to spellani_finished
	if (self.anistate == ANISTATE_CASTAOE || self.anistate == ANISTATE_CASTTARGET || self.anistate == ANISTATE_CASTSELF)
	{
		if (self.spellani_finished < time)
			self.anistate = ANISTATE_NONE;
	}

	// Tied to potion_use_finished
	if (self.anistate == ANISTATE_DRINK)
	{
		if (self.potion_use_finished < time)
			self.anistate = ANISTATE_NONE;
	}

	// Tied to dodge_finished
	if (self.anistate == ANISTATE_DODGE || self.anistate == ANISTATE_STEPDODGE)
	{
		if (self.dodge_finished + 0.05 < time)
		{
			self.anistate = ANISTATE_NONE;
			self.dodgedir = 0;
			if (self.flags & FL_ONGROUND)
				self.velocity_x = self.velocity_y = 0; // remove velocity from roll
			self.melee_finished = time;
		}
	}

	if (self.flags & FL_ONGROUND || self.levitate_finished > time)
	{
		if (self.anistate == ANISTATE_JUMP)
			self.anistate = ANISTATE_NONE;
		self.climbing = FALSE;
	}
};

// Ran before physics
void() PlayerPreThink =
{
	// use button
	if (self.button3)
	{
		if (!self.button3_pressed)
			Player_Use();
	}
	else
		self.button3_pressed = FALSE;
	
	// block button
	if (self.button4 && self.potion_use_finished < time && !self.menu && self.blockvalue > 0)
	{
		if (!self.crouch)
			Player_ShieldBlock();
	}
	else
		self.blocking = FALSE;

	// player movement + speed checks
	if (self.stagger_finished < time)
	{
		// attack / dodge / magic commitment / npc interaction menus
		if (self.melee_finished > time || self.menu == MENU_DIALOGUE || self.menu == MENU_BUYSELL || self.menu == MENU_BANKING ||
			self.cast_finished > time || self.spellani_finished > time || self.potion_use_finished > time
			|| self.dodge_finished > time || self.fishcast_finished > time || self.fishing_finished > time)
			self.maxspeed = 1;
		else
		{
			if (self.maxspeed != 225 && !self.crouch)
				self.maxspeed = 225;
			if (self.maxspeed != 135 && self.blocking)
				self.maxspeed = 135;
			if ((self.crouch) && self.maxspeed != 100)
				self.maxspeed = 100;
		}
	}
	else // stagger is active
	{
		if (self.anistate != ANISTATE_IMPACT && self.anistate != ANISTATE_STUNNED)
		{
			self.anistate = ANISTATE_IMPACT;
			self.impact_frame = time + 1; // impact frame duration
		}
		if (self.anistate == ANISTATE_IMPACT && self.impact_frame < time)
			self.anistate = ANISTATE_STUNNED;

		self.maxspeed = 1; // staggered speed
	}

	// removes console spam in developer mode
	if (cvar("developer") == 0)
	{
		if (self.loggedin) // enforce name
		{
			if (self.loginname != self.netname)
				forceinfokey(self, "name", self.loginname);
		}
		//else
		//		forceinfokey(self, "name", "");
	}

	if (self.menu == MENU_INVENTORY || self.menu == MENU_BUYSELL)
		SendPlayerInventory(self); // send inventory to CSQC
	if (self.menu == MENU_MAGIC)
		SendMagicSpells(self); // send magic spells to CSQC

	CheckImpulses();
};

void(float flIsNew) Player_SendFlags =
{
    float flChanged = 0;

    // On first spawn, send all fields
    if (flIsNew)
    {
        flChanged = ESF_ORIGIN | ESF_ANGLES | ESF_VELOCITY | ESF_FLAGS | ESF_EFFECTS |
                    ESF_HEALTH | ESF_LEVEL | ESF_PVP | ESF_EQUIPMENT | ESF_ANIMATION |
                    ESF_MISC | ESF_MODEL | ESF_NAME;
    }
    else
    {
        // ORIGIN
        if (self.origin != self.last_origin)
            flChanged |= ESF_ORIGIN;

        // ANGLES
        if (self.v_angle != self.last_v_angle)
            flChanged |= ESF_ANGLES;

        // VELOCITY
        if (self.velocity != self.last_velocity)
            flChanged |= ESF_VELOCITY;

        // FLAGS / EFFECTS
        if (self.flags != self.last_flags)
            flChanged |= ESF_FLAGS;
        if (self.effects != self.last_effects)
            flChanged |= ESF_EFFECTS;

        // HEALTH
        if (self.health != self.last_health || self.max_health != self.last_max_health)
            flChanged |= ESF_HEALTH;

        // LEVEL
        if (self.level != self.last_level)
            flChanged |= ESF_LEVEL;

        // PVP
        if (self.pvp != self.last_pvp)
            flChanged |= ESF_PVP;

        // EQUIPMENT
        if (self.main_hand != self.last_main_hand ||
            self.off_hand != self.last_off_hand ||
            self.armorname != self.last_armorname)
            flChanged |= ESF_EQUIPMENT;

        // ANIMATION
        if (self.anistate != self.last_anistate ||
            self.cast_finished != self.last_cast_finished ||
            self.attack_type != self.last_attack_type ||
            self.blocking != self.last_blocking)
            flChanged |= ESF_ANIMATION;

        // MISC small flags
        if (self.climbing != self.last_climbing ||
            self.bonfire != self.last_bonfire ||
            self.crouch != self.last_crouch ||
            self.dodgedir != self.last_dodgedir ||
            self.stepdodge_counter != self.last_stepdodge ||
			self.waterlevel != self.last_waterlevel ||
			self.levitate_finished != self.last_levitate_finished ||
			self.melee_finished != self.last_melee_finished)
            flChanged |= ESF_MISC;

        // MODEL & NAME
        if (self.modelindex != self.last_modelindex)
            flChanged |= ESF_MODEL;
        if (self.netname != self.last_netname)
            flChanged |= ESF_NAME;
    }

    self.SendFlags = flChanged;
};

// Ran after physics
void() PlayerPostThink =
{
	if (cvar("developer") > 0)
		return;

	Player_SendFlags(FALSE);

	if (!self.loggedin)
		return;

	float calc;

	WaterUpdate();
	FallDamage_Update();
	Anistate_Handler();

	if (self.deadflag == DEAD_DEAD)
	{
		self.anistate = ANISTATE_NONE; // CSQC handles death animation
		return;
	}

	if (self.frags != self.level) // HACK: used to display level on the scoreboard
		self.frags = self.level;
	
	if (self.pvp == 1)
		self.dimension_hit = player_dimension_hit + 1;
	else
		self.dimension_hit = player_dimension_hit;

	//
	// velocity push on player: melee/dodges
	//
	if (self.dodgedir != 8)
		Player_VelocityPush(200);
	else
		Player_VelocityPush(150); // step dodge speed
	//
	
	if (self.healthpot_heal_remaining > 0 && time > self.healthpot_finished) // health potion - apply ongoing healing
	{
		if (self.health >= self.max_health)
			self.healthpot_heal_remaining = 0;

		self.health = min(self.max_health, self.health + self.healthpot_heal_rate);
		self.healthpot_heal_remaining -= self.healthpot_heal_rate;
		self.healthpot_finished = time + 0.1; // how fast to tick
	}

	if (self.manapot_heal_remaining > 0 && time > self.manapot_finished) // mana potion - apply ongoing increase
	{
		if (self.mana >= self.max_mana)
			self.manapot_heal_remaining = 0;

		self.mana = min(self.max_mana, self.mana + self.manapot_heal_rate);
		self.manapot_heal_remaining -= self.manapot_heal_rate;
		self.manapot_finished = time + 0.1; // how fast to tick`
	}

	if (!self.incombat)
	{
		// Non-combat health regeneration
		if (self.healthregen_finished < time)
		{
			calc = 60 - (self.skill_healthregen * 0.25);
			if (self.health < self.max_health)
				self.health += 1;
			else
				self.health = self.max_health;
			self.healthregen_finished = time + calc;
		}
	}
	// Mana regeneration
	if (self.manaregen_finished < time)
	{
		calc = 60 - (self.skill_manaregen * 0.25);
		if (self.mana < self.max_mana)
			self.mana += 1;
		else
			self.mana = self.max_mana;
		self.manaregen_finished = time + calc;
	}

	// Stamina regeneration
	if (self.staminaregen_finished < time)
	{
		if (!self.blocking)
			calc = 0.2 - (self.skill_endurance * 0.0005);
		else
			calc = 0.4 - (self.skill_endurance * 0.0005);

		if (self.climbing || self.waterlevel > 1)
			calc = -1;

		// Check if standing still
		if (calc != -1)
		{
			if (vlen(self.velocity) < 1) // basically not moving
				calc *= 0.6667; // faster regen (1.5x)

			if (self.stamina < 99)
				self.stamina += 1;
			else
				self.stamina = 100;
		}

		self.staminaregen_finished = time + calc;
	}

	// PVP
	if (self.pvp == 2)
	{
		if (self.pvpenable_count >= 900) // 15 minutes
		{
			if (self.pvp_autoflagged == FALSE)
			{
				self.pvp = 1;
				self.pvp_autoflagged = TRUE;
				string eventlog_print = "^1You've been auto flagged for PVP!\n";
				stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
			}
		}
		else // count
		{
			if (self.pvpenable_finished < time && !self.bonfire)
			{
				self.pvpenable_count += 1;
				self.pvpenable_finished = time + 1;
			}
		}
	}
	if (self.incombat_finished < time && self.incombat)
	{
		self.incombat = FALSE;
		eventlog_print = (strcat("^2You've left combat\n"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
	}

	// Alpha transparency handler for crouch/sneaking
	if (self.crouch && !self.bonfire)
	{
		if (self.skill_stealth >= 25) // 25 is when stealth mechanics actually kick in
		{
			if (!self.lantern)
			{
				self.alpha = 1 - (self.skill_stealth * 0.004);
				self.colormod_x = self.colormod_y = self.colormod_z = self.alpha;
				if (self.alpha < 0.1)
					self.alpha = 0.1;
				self.effects |= EF_ADDITIVE;
			}
			else
			{
				self.alpha = 1;
				self.colormod_x = self.colormod_y = self.colormod_z = self.alpha;
				self.effects &= ~EF_ADDITIVE;
			}
		}
	}
	else
	{
		self.alpha = 1;
		self.colormod_x = self.colormod_y = self.colormod_z = self.alpha;
		self.effects &= ~EF_ADDITIVE;
	}

	if (self.flags & FL_ONGROUND)
	{
		if (self.inair_swing_sfx)
			self.inair_swing_sfx = FALSE;
		if (self.pressedJump)
			self.pressedJump = FALSE;
	}
	
	// levitate handler
	if (self.levitate_finished > time)
	{
		if (self.movetype != MOVETYPE_FLY)
			self.movetype = MOVETYPE_FLY;
	}
	else
	{
		// Only revert if we were actually levitating
		if (self.movetype == MOVETYPE_FLY)
		{
			self.movetype = MOVETYPE_WALK;
			sound(self, CHAN_AUTO, "magic/levitateend.wav", 1, ATTN_NORM);
		}
	}

	Player_CastMagic();
};

void() PlayerDeath =
{
	self.respawn_finished = time + 5;

	float g = ceil(self.gold * 0.25);
	if (self.gold > 1)
		self.gold -= g; // drop some gold
	string h = ftos(g);

	string eventlog_print = "^1You're dead!\n";
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

	self.menu = MENU_OFF; // flip all menus off
	self.incombat = FALSE;
	self.deadflag = DEAD_DEAD;
	self.radius_candamage = FALSE;
	self.movetype = MOVETYPE_TOSS;
	self.view_ofs = [0, 0, 4];
	self.healthpot_heal_remaining = 0;
	self.healthpot_heal_rate = 0;
	self.healthpot_finished = time;
	self.lantern = FALSE;

	centerprint (self, "/P^1You're Dead!\n^7--------\n\nYou've lost ^3" , h, " ^7gold!" , "\n\n^b^5Press Attack to respawn\n");
};

void(float type) PlayerSpawn =
{
	entity spawn_spot = get_spawn_point();

	if (!type) // login screen
	{
		self.classname = "notloggedin";
		self.solid = SOLID_NOT;
		setmodel(self, string_null);
		self.modelindex = 0;
		if (cvar("developer") == 0)
			self.movetype = MOVETYPE_NONE;
		else
			self.movetype = MOVETYPE_WALK;
		self.health = 100;
		self.max_health = 100;
		self.takedamage = DAMAGE_NO;
		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
		self.velocity = '0 0 0';

		self.menu = MENU_LOGIN;
		self.loggedin = FALSE;
		self.radius_candamage = FALSE;

		stuffcmd (self, sprintf("music sound/music/login.ogg\n")); // login screen music
	}
	else if (type == 1) // put first time player in
	{
		self.flags |= FL_CLIENT;
		self.classname = "player";
		self.takedamage = DAMAGE_AIM;
		self.movetype = MOVETYPE_WALK;
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
		self.menu = MENU_OFF;
		self.loggedin = TRUE;
		self.radius_candamage = TRUE;
		self.solid = SOLID_SLIDEBOX;

		self.dimension_hit = player_dimension_hit;
		self.dimension_solid = player_dimension_solid;

		self.flags |= FL_FINDABLE_NONSOLID;
		self.crouch = FALSE;
		self.alpha = 1;
		self.canbackstab = TRUE; // can be backstabbed
		self.th_die = PlayerDeath;

		if (self.gender == "Male")
		{
			setmodel(self, "models/player_m.glb");
			modelindex_player_m = self.modelindex;
		}
		else
		{
			setmodel(self, "models/player_f.glb");
			modelindex_player_f = self.modelindex;
		}
		bprint(PRINT_HIGH, self.netname);
		bprint(PRINT_HIGH, " enters the zone\n");

		stuffcmd (self, sprintf("music %s\n", self.music));
	}
	else if (type == 2) // map transition spawn
	{	
		self.flags |= FL_CLIENT;
		self.classname = "player";
		self.takedamage = DAMAGE_AIM;
		self.movetype = MOVETYPE_WALK;
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
		self.menu = MENU_OFF;
		self.radius_candamage = TRUE;
		self.solid = SOLID_SLIDEBOX;

		self.dimension_hit = player_dimension_hit;
		self.dimension_solid = player_dimension_solid;

		self.flags |= FL_FINDABLE_NONSOLID;
		self.crouch = FALSE;
		self.alpha = 1;
		self.canbackstab = TRUE; // can be backstabbed
		self.th_die = PlayerDeath;

		if (self.gender == "Male")
		{
			setmodel(self, "models/player_m.glb");
			modelindex_player_m = self.modelindex;
		}
		else
		{
			setmodel(self, "models/player_f.glb");
			modelindex_player_f = self.modelindex;
		}
		bprint(PRINT_HIGH, self.netname);
		bprint(PRINT_HIGH, " enters the zone\n");


		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;
		self.velocity = '0 0 0';

		stuffcmd (self, sprintf("stopmusic\n")); // stop music
	}
	else // respawning from death
	{
		if (self.underwatersfx_finished > time) // remove left over sound
		{
			stuffcmd (self, sprintf("stopsound %s\n", "inwater.wav")); // sound
			self.underwatersfx_finished = time;
		}

		centerprint (self, ""); // clear centerprint
		self.melee_finished = time + 1; // prevent attack on respawn

		self.classname = "player";
		self.health = self.max_health;
		self.takedamage = DAMAGE_AIM;
		self.movetype = MOVETYPE_WALK;
		self.view_ofs = [0, 0, 48];
		self.deadflag = DEAD_NO;
		self.radius_candamage = TRUE;
		self.solid = SOLID_SLIDEBOX;

		self.dimension_hit = player_dimension_hit;
		self.dimension_solid = player_dimension_solid;
		
		self.flags |= FL_FINDABLE_NONSOLID;
		self.stamina = 100;
		self.pvp_autoflagged = FALSE;
		self.pvp = 0;
		self.mana = self.max_mana;
		self.incombat_finished = time;
		self.crouch = FALSE;
		self.alpha = 1;
		self.canbackstab = TRUE; // can be backstabbed

		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;
		self.velocity = '0 0 0';

		stuffcmd (self, sprintf("music %s\n", self.music));
		CSEv_Player_SaveChar(self, 0); // full save on respawn
	}
};

// ======================================
// Send only changed entity data
// ======================================
float(entity ePVEnt, float flChanged) Player_SendEntity =
{
    // Unique identifier for player entity
    WriteByte(MSG_ENTITY, ENT_PLAYER);
	WriteShort(MSG_ENTITY, flChanged);

    // --- ORIGIN ---
    if (flChanged & ESF_ORIGIN)
    {
        WriteCoord(MSG_ENTITY, self.origin_x);
        WriteCoord(MSG_ENTITY, self.origin_y);
        WriteCoord(MSG_ENTITY, self.origin_z);
    }

    // --- ANGLES ---
    if (flChanged & ESF_ANGLES)
    {
        WriteCoord(MSG_ENTITY, self.v_angle_x);
        WriteCoord(MSG_ENTITY, self.v_angle_y);
        WriteCoord(MSG_ENTITY, self.v_angle_z);
    }

    // --- VELOCITY ---
    if (flChanged & ESF_VELOCITY)
    {
        WriteCoord(MSG_ENTITY, self.velocity_x);
        WriteCoord(MSG_ENTITY, self.velocity_y);
        WriteCoord(MSG_ENTITY, self.velocity_z);
    }

    // --- FLAGS & EFFECTS ---
    if (flChanged & ESF_FLAGS)   WriteFloat(MSG_ENTITY, self.flags);
    if (flChanged & ESF_EFFECTS) WriteFloat(MSG_ENTITY, self.effects);

    // --- MODEL & NAME ---
    if (flChanged & ESF_MODEL) WriteShort(MSG_ENTITY, self.modelindex);
    if (flChanged & ESF_NAME)  WriteString(MSG_ENTITY, self.netname);

    // --- HEALTH ---
    if (flChanged & ESF_HEALTH)
    {
        WriteShort(MSG_ENTITY, self.health);
        WriteShort(MSG_ENTITY, self.max_health);
    }

    // --- LEVEL & PVP ---
    if (flChanged & ESF_LEVEL) WriteByte(MSG_ENTITY, self.level);
    if (flChanged & ESF_PVP)   WriteByte(MSG_ENTITY, self.pvp);

    // --- EQUIPMENT ---
    if (flChanged & ESF_EQUIPMENT)
    {
        WriteString(MSG_ENTITY, self.main_hand);
        WriteString(MSG_ENTITY, self.off_hand);
        WriteString(MSG_ENTITY, self.armorname);
    }

    // --- ANIMATION & ACTION STATES ---
    if (flChanged & ESF_ANIMATION)
    {
        WriteByte(MSG_ENTITY, self.anistate);
        WriteByte(MSG_ENTITY, self.cast_finished);
        WriteByte(MSG_ENTITY, self.attack_type);
        WriteByte(MSG_ENTITY, self.blocking);
    }

    // --- MISC small flags ---
    if (flChanged & ESF_MISC)
    {
        WriteByte(MSG_ENTITY, self.climbing);
        WriteByte(MSG_ENTITY, self.bonfire);
        WriteByte(MSG_ENTITY, self.crouch);
        WriteByte(MSG_ENTITY, self.dodgedir);
        WriteByte(MSG_ENTITY, self.stepdodge_counter);
        WriteByte(MSG_ENTITY, self.waterlevel);
        WriteByte(MSG_ENTITY, self.levitate_finished);
        WriteByte(MSG_ENTITY, self.melee_finished);
    }

    // --- Update last sent values ---
    if (flChanged & ESF_ORIGIN)       self.last_origin = self.origin;
    if (flChanged & ESF_ANGLES)       self.last_v_angle = self.v_angle;
    if (flChanged & ESF_VELOCITY)     self.last_velocity = self.velocity;
    if (flChanged & ESF_FLAGS)        self.last_flags = self.flags;
    if (flChanged & ESF_EFFECTS)      self.last_effects = self.effects;
    if (flChanged & ESF_MODEL)        self.last_modelindex = self.modelindex;
    if (flChanged & ESF_NAME)         self.last_netname = self.netname;
    if (flChanged & ESF_HEALTH)
    {
        self.last_health = self.health;
        self.last_max_health = self.max_health;
    }
    if (flChanged & ESF_LEVEL)        self.last_level = self.level;
    if (flChanged & ESF_PVP)          self.last_pvp = self.pvp;
    if (flChanged & ESF_EQUIPMENT)
    {
        self.last_main_hand = self.main_hand;
        self.last_off_hand = self.off_hand;
        self.last_armorname = self.armorname;
    }
    if (flChanged & ESF_ANIMATION)
    {
        self.last_anistate = self.anistate;
        self.last_cast_finished = self.cast_finished;
        self.last_attack_type = self.attack_type;
        self.last_blocking = self.blocking;
    }
    if (flChanged & ESF_MISC)
    {
        self.last_climbing = self.climbing;
        self.last_bonfire = self.bonfire;
        self.last_crouch = self.crouch;
        self.last_dodgedir = self.dodgedir;
        self.last_stepdodge = self.stepdodge_counter;
        self.last_waterlevel = self.waterlevel;
        self.last_levitate_finished = self.levitate_finished;
		self.last_melee_finished = self.melee_finished;
    }

    return TRUE;
};

void() PutClientInServer =
{
    if (cvar("developer") > 0)
        return;

    player_chain_add(self);

    // IMPORTANT: Register sender first
    if (cvar("developer") == 0)
        self.SendEntity = Player_SendEntity;

    // Now force a full delta AFTER SendEntity exists
    Player_SendFlags(TRUE);

    // this is important, do not remove
    self.loggedin = parm1;
    self.spawnloc = parm2;
	//

	if (cvar("developer") == 0)
		self.SendEntity = Player_SendEntity;

	// map transition
	if (self.loggedin)
	{
		msg_entity = self;
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, CSQC_LASTLOGIN);
		multicast(self.origin, MULTICAST_ONE_R);

		SetCheckStringParms();

		if (parm26)
			stuffcmd (self, sprintf("toggle_camera\n")); // carry 3rd person camera state
		return;
	}
	else // wipe string parms on first entrance
	{
		msg_entity = self;
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, CSQC_WIPESPARM);
		multicast(self.origin, MULTICAST_ONE_R);
	}

	self.guid = infokey(self, INFOKEY_P_GUID);
	if (!self.guid)
	{
		sprint(self, PRINT_HIGH, "Please set cl_sendguid to 1\n");
		dropclient(self);
		return;
	}
	else
		PlayerSpawn(0);

	// Send MOTD on user entry to CSQC
	msg_entity = self;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_MOTD);
	WriteString(MSG_MULTICAST, motd);
	multicast(self.origin, MULTICAST_ONE_R);

	// Send time of day to players CSQC
	msg_entity = self;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_TIMEOFDAY);
	WriteByte(MSG_MULTICAST, timeofday);
	multicast(self.origin, MULTICAST_ONE_R);

	self.worldlight = TRUE;
};

void() ClientDisconnect =
{
	CSEv_Player_SaveChar(self, 1); // save character on disconnect, do not update X/Y position

	player_chain_remove(self); // clean up removed player
	setmodel (self, string_null);
	self.modelindex = 0;
	self.solid = SOLID_NOT;
	self.classname = "notloggedin";
	self.loggedin = FALSE;
	WipeParms();
	self.SendEntity = 0; // wipe this so CSQC can clean up player ents

	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the zone\n");
};

//
// Saving / Loading / Map Transfer / Character creation
//

void(string LOGIN_NAME) CSEv_ResumeCharacterMapTransfer_s = 
{
	if (cvar("developer") > 0)
		return;

	if (!LOGIN_NAME) // local user tampered with lastlogin
	{
		sprint(self, PRINT_HIGH, "Error: Last login is invalid\n");
		dropclient(self);
		return;
	}

	self.loginname = LOGIN_NAME;
	self.netname = LOGIN_NAME;
	CSEv_ResumeCharacter_s(self.loginname);

	// security check
	string line;
	string add_ext = strcat(LOGIN_NAME, ".chr");
	float f = fopen(add_ext, FILE_READ);
	if (f >= 0)
	{
		self.guid = infokey(self, INFOKEY_P_GUID);
		if (line = fgets(f)) // grab guid from file
		if (line != "" && line != self.guid) // compare guid from file & user, server owner can wipe guid line if needed
		{
			sprint(self, PRINT_HIGH, "Server GUID does not match clients\n");
			dropclient(self);
			return;
		}
	}
	self.music = ""; // clear after load so music is loaded properly
	self.zonename = ""; // clear after load
	PlayerSpawn(2);
	SetCheckParms(); // grab and restore parms AFTER character is resumed

	if (parm25)
		self.effects |= EF_BRIGHTLIGHT;
};

void(string LOGIN_NAME, string LOGIN_GENDER, string LOGIN_PASSWORD) CSEv_CreateNewCharacter_sss =
{
	self.loginname = LOGIN_NAME; // Grab login name from CSQC
	self.gender = LOGIN_GENDER; // Grab gender from CSQC
	self.password = LOGIN_PASSWORD; // Grab password from CSQC
	
	string add_ext = strcat(self.loginname, ".chr");
	float v = fopen(add_ext, FILE_READ);
	if (v >= 0) // User exists
	{
		sprint (self, PRINT_HIGH, "That characters name is already taken\n");
		return;
	}
	else
	{
		self.loggedin = TRUE;
		self.menu = MENU_OFF; // turn off menu in CSQC

		// starting stats
		self.health = self.max_health = 100;
		self.mana = self.max_mana = 25;
		self.level = 1;
		self.exp = 0;
		self.exp_next = 100;
		self.stamina = 100;
		self.skillpoints = 25; // 25 skill points new players can dump into stats

		// default starters
		self.attack_power_min = 2;
		self.attack_power_max = 6;
		self.attack_speed = 1.2;
		self.attack_stamina = 25;
		self.attack_type = 1; // slashing weapon
		self.attack_length = 64; // weapon length
		self.main_hand = "Broken Sword";
		self.off_hand = "Broken Buckler";
		self.blockvalue = 4;
		self.gold = 0;
		self.gold_bank = 0;
		self.exp_oldnext = 0;

		// default armor
		self.armorname = "Plain Clothes";
		self.armorvalue = 0;
		self.pvp = FALSE;

		self.spell_equipped = "None";

		forceinfokey(self, "name", LOGIN_NAME);
		self.displayname = self.loginname;
		PlayerSpawn(1); // Put player in game
		CSEv_Player_SaveChar(self, 0); // full save on creation
	}
};

//
//
//