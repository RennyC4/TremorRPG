//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc
//

void() CSEv_ShutDownMenus = {localsound("menu/menu_close", 4, 1);self.menu = MENU_OFF;};
void(entity targ, float type) CSEv_Player_SaveChar;
void(float type) PlayerSpawn;
void(entity player) SendPlayerInventory;
void(entity player) SendMagicSpells;
float(entity targ, string itemname, float count) AddToInventory;
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

void() PlayerJump =
{
	if (self.bonfire)
		return;
	if (self.dodge_finished > time)
		return;

	PlayerClimb();

	if (self.climbing)
		return;
	if (self.melee_finished > time)
		return;
	if (self.cast_finished > time)
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;
	if (self.menu == MENU_CHARACTER || self.menu == MENU_INVENTORY || self.menu == MENU_MAGIC)
		return;

	float stamcalc = self.skill_acrobatic * 0.35; // skill calculation
	float jumpcalc = self.skill_acrobatic * 1.1; // skill calculation
	if (self.stamina > (50 - stamcalc))
	{
		Player_RemoveCrouch(); // remove crouch

		self.velocity_z += (270 + jumpcalc);
		self.weaponframe = 0;
		self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
		self.button2 = 0;
		if (stamcalc > 49)
			stamcalc = 49;
		self.stamina -= (50 - stamcalc);
		sound (self, CHAN_AUTO, "jump.wav", 1, ATTN_NORM);
		
	}
};

void(float whichdir) CSEv_PlayerDodge_f =
{
	if (self.bonfire)
		return;
	if (self.cast_finished > time)
		return;
	if (self.dodge_finished > time)
		return;
	if (self.melee_finished > time)
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;
	if (self.menu == MENU_CHARACTER || self.menu == MENU_INVENTORY || self.menu == MENU_MAGIC)
		return;

	if (self.stamina >= 20)
	{
		self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
		self.button2 = 0;
		self.stamina -= 20;

		self.dodgedir = whichdir;
		//print (ftos(self.dodgedir), "\n");

		if (whichdir == 8)
		{
			self.godmode_finished = time + 0.35;
			self.dodge_finished = time + 0.5;
			self.stepdodge_counter = time + 1;
			self.anistate = ANISTATE_STEPDODGE;
		}
		else
		{
			self.godmode_finished = time + 0.2;
			self.dodge_finished = time + 0.8;
			self.anistate = ANISTATE_DODGE;
			sound (self, CHAN_AUTO, "jump.wav", 1, ATTN_NORM);
		}

		self.velocitypush_finished = self.dodge_finished;
		self.lockview_finished = self.dodge_finished;

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

	if (!self.crouch) // --- Entering crouch ---
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

// function used for placing objects in terrain mode, cheats 
void() PlayerPrintStats =
{
	string pos_x = ftos(self.origin_x);
	string pos_y = ftos(self.origin_y);
	string pos_z = ftos(self.origin_z);

	string ang_x = ftos(self.angles_x);
	string ang_y = ftos(self.angles_y);
	string ang_z = ftos(self.angles_z);

	sprint(self, PRINT_HIGH, "Coords: ", pos_x, " ", pos_y, " ", pos_z);
	sprint(self, PRINT_HIGH, "\nAngles: ", ang_x, " ", ang_y, "\n");

	if (cvar("sv_cheats") > 0) // give cheat stats
	{
		self.skillpoints = 99999;
		self.gold = 99999;
		self.level ++;
		self.mana = self.max_mana;
		self.health = self.max_health;

		AddToInventory(self, "Health Potion", 1);
		AddToInventory(self, "Mana Potion", 1);
	}

	sprint(self, PRINT_HIGH, "Proj_Min: ", ftos(self.projectile_power_min), "\n");
	sprint(self, PRINT_HIGH, "Proj_Min: ", ftos(self.projectile_power_max), "\n");
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
		return;
	}

	// Disable PVP
	if (self.pvp == 1)
	{
		self.pvp = 2;
		sprint(self, PRINT_HIGH, "PVP: ^2Disabled\n");
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
};

void() CheckImpulses =
{
	switch (self.impulse)
	{
		case 1:
			PlayerPrintStats(); // Debugging
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
		self.user.pvp_autoflagged = FALSE;
		self.user.pvpenable_count = 0;
		CSEv_Player_SaveChar(self, 0); // full save user character
		return;
	}

	makevectors (self.angles);
	vector source = self.origin;
	source = self.origin + self.view_ofs;
	traceline (source, source + v_forward * 72, MOVE_ENTCHAIN, self);

	if (trace_ent.th_use)
	{
		trace_ent.user = self;
		trace_ent.think = trace_ent.th_use;
		trace_ent.nextthink = time + 0.1;
	}
	self.button3_pressed = TRUE;
};

//
// Block button
//

void() Player_ShieldBlock =
{
	if (self.blockvalue <= 0)
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
		if (self.inair_count >= 12 && !self.waterlevel && !self.climbing)
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
		if (self.waterlevel >= 3)
		{
			if (self.lantern)
				self.lantern = FALSE;

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

//
// Footstep sound handler
//

.float nextfootstep_finished;
void() FootstepThink =
{
    if (!(self.flags & FL_ONGROUND))
        return;
	if (self.deadflag == DEAD_DEAD)
		return;

	string s;
    vector vel = self.velocity;
    float speed = vlen(vel);

	if (speed < 5)
		return;

    if (time >= self.nextfootstep_finished)
    {
        if (self.waterlevel >= 1)
            s = strcat("move_wade", ftos(floor(random()*2)), ".wav");
        else
            s = strcat("move_step", ftos(floor(random()*2)), ".wav");

		if (!self.waterlevel)
		{
			if (!self.crouch)
			{
				if (self.potion_use_finished > time)
					self.nextfootstep_finished = time + 0.5;
				if (!self.blocking)
					self.nextfootstep_finished = time + 0.35;
				else
					self.nextfootstep_finished = time + 0.5;
				sound(self, CHAN_BODY, s, 0.25, ATTN_NORM);
			}
			else
			{
				self.nextfootstep_finished = time + 0.5;
				sound(self, CHAN_BODY, s, 0.1, ATTN_NORM);
			}
		}
		else
		{
			sound(self, CHAN_AUTO, s, 0.25, ATTN_NORM); // water sounds need CHAN_AUTO
			self.nextfootstep_finished = time + 0.35;
		}
    }
};

void(float speed) Player_VelocityPush =
{
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

// Main SSQC attack function
void() CSEv_User_StartAttack_ =
{
	if (self.dodge_finished > time)
		return;
	if (self.menu != MENU_OFF)
		return;
	if (self.bonfire)
		return;

	if (self.deadflag == DEAD_DEAD || self.health <= 0)
	{
		if (self.respawn_finished < time)
		{
			PlayerSpawn(3); // respawn
			self.melee_finished = time + 1; // prevent attack on spawn
			self.pvp_autoflagged = FALSE;
			return;
		}
	}
	else
	{
		if (!self.blocking)
		{
			if (self.melee_finished < time && self.cancast_finished < time && self.cast_finished < time && self.menushut_finished < time)
			{
				float stamcalc = self.skill_endurance * 0.015;

				if (self.stamina >= (self.attack_stamina - stamcalc) && !self.button4)
				{
					float nobow = FALSE;

					// --------------------------------
					// Air melee - absolute priority
					// --------------------------------
					if (!(self.flags & FL_ONGROUND))
					{
						if (self.attack_type != 4) // not bow
							self.anistate = ANISTATE_AIRMELEE;
					}
					else // Normal ground attacks
					{
						if (self.stepdodge_counter < time)
						{
							if (self.attack_type == 0)
								self.anistate = ANISTATE_PUNCH;
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
								print("Error: Unknown attack_type in User_StartAttack\n");
						}
						else
							self.anistate = ANISTATE_STEPCOUNTER;
					}

					// Disabled as it interferes with stealth attacks
					//Player_RemoveCrouch();

					if (!nobow)
					{
						self.stamina -= (self.attack_stamina - stamcalc);
						if (self.anistate == ANISTATE_STEPCOUNTER)
						{
							self.melee_finished = time + 1.5;
							self.lockview_finished = time + 1.5;
							self.velocitypush_finished = time + 0.75;
							self.stepdodge_counter = time; // Turn off counter
						}
						else
						{
							self.melee_finished = time + self.attack_speed;
							self.lockview_finished = time + self.attack_speed;
							if (self.attack_type != 4)
								self.velocitypush_finished = time + (self.attack_speed / 4);
						}
					}
				}
			}
		}
		else if (self.blockvalue > 0)
		{
			self.anistate = ANISTATE_BASH;
			DoAttack_ShieldBash();
		}
	}
};

//
// Special animation states sent to CSQC
//

void() Anistate_Handler =
{
	// Tied to melee_finished
	if (self.anistate == ANISTATE_SLASH || self.anistate == ANISTATE_STAB || self.anistate == ANISTATE_PUNCH || self.anistate == ANISTATE_BASH
	|| self.anistate == ANISTATE_PARRY || self.anistate == ANISTATE_SMASH || self.anistate == ANISTATE_ARCHERY || self.anistate == ANISTATE_BLOCK
	|| self.anistate == ANISTATE_AIRMELEE || self.anistate == ANISTATE_STEPCOUNTER)
	{
		if (self.anistate == ANISTATE_AIRMELEE)
		{
			if (self.melee_finished < time && self.flags & FL_ONGROUND)
				self.anistate = ANISTATE_NONE;
		}
		else
		{
			if (self.melee_finished < time)
				self.anistate = ANISTATE_NONE;
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
		if (self.dodge_finished < time)
		{
			self.anistate = ANISTATE_NONE;
			self.dodgedir = 0;
			self.velocity_x = self.velocity_y = 0; // remove velocity from roll
			self.melee_finished = time;
		}
	}

	if (self.flags & FL_ONGROUND)
		self.climbing = FALSE;
};

// Ran before physics
void() PlayerPreThink =
{
	// Button1 we ignore
	if (self.button2)
	{
		PlayerJump();
		self.button2 = TRUE;
	}
	else
	{
		self.climbing = FALSE;
		self.flags |= FL_JUMPRELEASED;
	}

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
		if (self.anistate == ANISTATE_STUNNED || self.anistate == ANISTATE_IMPACT) // Reset stun state once stagger time is over
			self.anistate = ANISTATE_NONE;

		// === STUN COOLDOWN HANDLING ===
		if (self.next_stun_allowed && self.next_stun_allowed < time)
			self.next_stun_allowed = 0; // cooldown expired

		// attack / dodge / magic commitment / npc interaction menus
		if (self.melee_finished > time || self.menu == MENU_DIALOGUE || self.menu == MENU_BUYSELL ||
			self.cast_finished > time || self.spellani_finished > time || self.potion_use_finished > time
			|| self.dodge_finished > time)
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
	else
	{
		// Only apply stun if not on cooldown
		if (!self.next_stun_allowed || self.next_stun_allowed < time)
		{
			self.anistate = ANISTATE_STUNNED;
			self.maxspeed = 1; // staggered speed
			self.next_stun_allowed = time + 2; // 2 seconds cooldown before next stun
		}
	}
	if (self.loggedin) // enforce name
	{
		if (self.loginname != self.netname)
			forceinfokey(self, "name", self.loginname);
	}

	if (self.menu == MENU_INVENTORY || self.menu == MENU_BUYSELL)
		SendPlayerInventory(self); // send inventory to CSQC
	if (self.menu == MENU_MAGIC)
		SendMagicSpells(self); // send magic spells to CSQC

	CheckImpulses();
};

// Ran after physics
void() PlayerPostThink =
{
	self.SendFlags = 1;

	if (!self.loggedin)
		return;

	float calc;

	WaterUpdate();
	FootstepThink();
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
		Player_VelocityPush(200, 0);
	else
		Player_VelocityPush(150, 0); // step dodge speed
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
		// Non-combat mana regeneration
		if (self.manaregen_finished < time)
		{
			calc = 60 - (self.skill_manaregen * 0.25);
			if (self.mana < self.max_mana)
				self.mana += 1;
			else
				self.mana = self.max_mana;
			self.manaregen_finished = time + calc;
		}
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

		//string calc_disp = ftos(calc);
		//print (calc_disp, "\n");
		if (calc != -1)
		{
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

	if (self.flags & FL_ONGROUND && self.inair_swing_sfx)
		self.inair_swing_sfx = FALSE;
	Player_CastMagic();
};

void() ClientConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " enters the zone\n");
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
	self.movetype = MOVETYPE_NONE;
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

		self.menu = MENU_LOGIN;
		self.loggedin = FALSE;
		self.radius_candamage = FALSE;

		stuffcmd (self, sprintf("music sound/music/track03.ogg\n")); // login screen music
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

		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;
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
		self.incombat_finished = time;
		self.crouch = FALSE;
		self.alpha = 1;
		self.canbackstab = TRUE; // can be backstabbed

		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;
		self.velocity = '0 0 0';

		stuffcmd (self, sprintf("music %s\n", self.music));
		CSEv_Player_SaveChar(self, 0); // full save on creation
	}
};

float(entity ePVEnt, float flChanged) Player_SendEntity =
{
	WriteByte(MSG_ENTITY, ENT_PLAYER); // Unique identifier

	WriteCoord(MSG_ENTITY, self.origin_x); // Position X
	WriteCoord(MSG_ENTITY, self.origin_y); // Position Y
	WriteCoord(MSG_ENTITY, self.origin_z); // Position Z

	WriteCoord(MSG_ENTITY, self.v_angle_x); // View angle X
	WriteCoord(MSG_ENTITY, self.v_angle_y); // View angle Y
	WriteCoord(MSG_ENTITY, self.v_angle_z); // View angle Z

	WriteShort(MSG_ENTITY, self.velocity_x); // Velocity X
	WriteShort(MSG_ENTITY, self.velocity_y); // Velocity X
	WriteShort(MSG_ENTITY, self.velocity_z); // Velocity X

	WriteFloat(MSG_ENTITY, self.flags); // Flags, important for physics
	WriteFloat(MSG_ENTITY, self.effects); // Effects
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteString(MSG_ENTITY, self.netname);
	WriteByte(MSG_ENTITY, self.climbing); // Climbing - Animation
	WriteShort(MSG_ENTITY, self.health); // Animation + additional checks
	WriteShort(MSG_ENTITY, self.max_health);
	WriteByte(MSG_ENTITY, self.level);

	WriteCoord(MSG_ENTITY, self.colormod_x); //
	WriteCoord(MSG_ENTITY, self.colormod_y); // colormod
	WriteCoord(MSG_ENTITY, self.colormod_z); //

	WriteByte(MSG_ENTITY, self.pvp);
	WriteByte(MSG_ENTITY, self.loggedin);
	WriteString(MSG_ENTITY, self.main_hand);
	WriteString(MSG_ENTITY, self.off_hand);
	WriteByte(MSG_ENTITY, self.anistate);
	WriteByte(MSG_ENTITY, self.bonfire);
	WriteByte(MSG_ENTITY, self.cast_finished);
	WriteByte(MSG_ENTITY, self.attack_type);
	WriteByte(MSG_ENTITY, self.blocking);
	WriteByte(MSG_ENTITY, self.crouch);
	WriteByte(MSG_ENTITY, self.dodgedir);
	WriteByte(MSG_ENTITY, self.stepdodge_counter);
	WriteString(MSG_ENTITY, self.armorname);
	
	return TRUE;
};

void() PutClientInServer =
{
	if (cvar("developer") > 0)
		return;

	player_chain_add(self);

	// this is important, do not remove them
	self.loggedin = parm1;
	self.spawnloc = parm2;
	//

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

void(entity targ, float type) CSEv_Player_SaveChar =
{
    if (!targ.loggedin)
        return;

    string filename = strcat(targ.loginname, ".chr");

    // prepare to preserve some data (music, origin)
    string old_music;
    string old_origin[6];
    float f, i;

    if (type == 1) // map transfer
    {
        f = fopen(filename, FILE_READ);
        if (f >= 0)
        {
            // line 1: guid
            fgets(f);
            // line 2: loginname
            fgets(f);
            // line 3: gender
            fgets(f);
            // line 4: music
            old_music = fgets(f);
            // line 5: zonename
            fgets(f);

            // next 6 lines = origin + angles
            for (i = 0; i < 6; i++)
                old_origin[i] = fgets(f);

            fclose(f);
        }
    }

    // write new file
    f = fopen(filename, FILE_WRITE);
    if (f < 0)
        return;

    fputs(f, targ.guid, "\n");
    fputs(f, targ.loginname, "\n");
    fputs(f, targ.gender, "\n");

    // don't update music if world model ends with "bsp"
    if (substring(world.model, -3, 3) == "bsp" && old_music != __NULL__)
        fputs(f, old_music, "\n");
    else
        fputs(f, targ.music, "\n");

    fputs(f, targ.zonename, "\n");

    // write origin + angles
    if (!type) // normal save
    {
        fputs(f, ftos(targ.origin_x), "\n");
        fputs(f, ftos(targ.origin_y), "\n");
        fputs(f, ftos(targ.origin_z), "\n");
        fputs(f, ftos(targ.angles_x), "\n");
        fputs(f, ftos(targ.angles_y), "\n");
        fputs(f, ftos(targ.angles_z), "\n");
    }
    else // map transfer
    {
        for (i = 0; i < 6; i++)
            fputs(f, old_origin[i], "\n");
    }

    // --- rest of stats/skills/inventory ---
    fputs(f, ftos(targ.health), "\n");
    fputs(f, ftos(targ.max_health), "\n");
    fputs(f, ftos(targ.mana), "\n");
    fputs(f, ftos(targ.max_mana), "\n");
    fputs(f, ftos(targ.level), "\n");
    fputs(f, ftos(targ.skillpoints), "\n");
    fputs(f, ftos(targ.exp), "\n");
    fputs(f, ftos(targ.exp_next), "\n");
    fputs(f, ftos(targ.gold), "\n");
    fputs(f, ftos(targ.attack_power_min), "\n");
    fputs(f, ftos(targ.attack_power_max), "\n");
    fputs(f, ftos(targ.attack_speed), "\n");
    fputs(f, ftos(targ.attack_type), "\n");
    fputs(f, ftos(targ.attack_stamina), "\n");
    fputs(f, ftos(targ.attack_length), "\n");
    fputs(f, targ.main_hand, "\n");
    fputs(f, targ.off_hand, "\n");
    fputs(f, targ.armorname, "\n");
    fputs(f, ftos(targ.armorvalue), "\n");
    fputs(f, ftos(targ.pvp), "\n");
    fputs(f, ftos(targ.pvpenable_count), "\n");
    fputs(f, ftos(targ.pvp_autoflagged), "\n");
    fputs(f, ftos(targ.blockvalue), "\n");
    fputs(f, targ.spell_equipped, "\n");
    fputs(f, ftos(targ.spell_power_min), "\n");
    fputs(f, ftos(targ.spell_power_max), "\n");
    fputs(f, ftos(targ.projectile_power_min), "\n");
    fputs(f, ftos(targ.projectile_power_max), "\n");

    // skills
    fputs(f, ftos(targ.skill_unarmed), "\n");
    fputs(f, ftos(targ.skill_slash), "\n");
    fputs(f, ftos(targ.skill_pierce), "\n");
    fputs(f, ftos(targ.skill_bash), "\n");
    fputs(f, ftos(targ.skill_stealth), "\n");
    fputs(f, ftos(targ.skill_backstab), "\n");
    fputs(f, ftos(targ.skill_offensivemagic), "\n");
    fputs(f, ftos(targ.skill_defensivemagic), "\n");
    fputs(f, ftos(targ.skill_neutralmagic), "\n");
    fputs(f, ftos(targ.skill_endurance), "\n");
    fputs(f, ftos(targ.skill_spellresist), "\n");
    fputs(f, ftos(targ.skill_archery), "\n");
    fputs(f, ftos(targ.skill_healthregen), "\n");
    fputs(f, ftos(targ.skill_manaregen), "\n");
    fputs(f, ftos(targ.skill_haggle), "\n");
    fputs(f, ftos(targ.skill_climb), "\n");
    fputs(f, ftos(targ.skill_swim), "\n");
    fputs(f, ftos(targ.skill_acrobatic), "\n");

    // jobs
    fputs(f, ftos(targ.skill_mining), "\n");
    fputs(f, ftos(targ.skill_fishing), "\n");
    fputs(f, ftos(targ.skill_woodcutting), "\n");

    fputs(f, ftos(targ.inv_count), "\n");
    fputs(f, ftos(targ.spell_count), "\n");

    // inventory
    for (i = 0; i < targ.inv_count; i++)
    {
        fputs(f, targ.inventory[i], "\n");
        fputs(f, ftos(targ.inventory_count[i]), "\n");
    }

    // magic
    for (i = 0; i < targ.spell_count; i++)
        fputs(f, targ.spell[i], "\n");

    fclose(f);

    sprint(targ, PRINT_HIGH, strcat(targ.loginname, " character saved\n"));
};

void(string LOGIN_NAME) CSEv_ResumeCharacter_s = 
{
	if (cvar("developer") > 0)
		return;

	string line;
	string add_ext = strcat(LOGIN_NAME, ".chr");

	// security check
	float f = fopen(add_ext, FILE_READ);
	if (f >= 0)
	{
		self.guid = infokey(self, INFOKEY_P_GUID);	
		if (line = fgets(f)) // grab guid from file
		if (line != "" && line != self.guid) // compare guid from file & user, server owner can wipe guid line if needed
		{
			sprint(self, PRINT_HIGH, "Server GUID does not match clients\n");
			return;
		}
	}

	if (cvar("sv_multilogin") == 0) // cheats allows multi-boxing
	{
		// check GUID against all other players on the server, if they match, kick new client
		for (entity targ = world;(targ = find(targ, classname, "player"));)
		{
			if (targ != self && targ.guid == self.guid)
			{
				sprint(self, PRINT_HIGH, "You cannot run multiple instances of Tremor RPG on the same server\n");
				dropclient(self);
			}
		}
	}

	// passed security check, grab stats from user server file
	float v = fopen(add_ext, FILE_READ);
	if (v >= 0)
	{
		// stats
		if (line = fgets(v)) {} // do not set GUID any longer
			//self.guid = line;
		if (line = fgets(v))
			self.netname = self.loginname = line;
		if (line = fgets(v))
			self.gender = line;
		if (line = fgets(v))
			self.music = line;
		if (line = fgets(v))
			self.zonename = line;

		if (!self.loggedin)
		{
			if (line = fgets(v))
				self.origin_x = stof(line);
			if (line = fgets(v))
				self.origin_y = stof(line);
			if (line = fgets(v))
				self.origin_z = stof(line);
			if (line = fgets(v))
				self.angles_x = stof(line);
			if (line = fgets(v))
				self.angles_y = stof(line);
			if (line = fgets(v))
				self.angles_z = stof(line);
		}
		else // skip 6 lines, already logged in; map transition
		{
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
		}

		if (line = fgets(v))
			self.health = stof(line);
		if (self.health < 0)
			self.health = 1;
		if (line = fgets(v))
			self.max_health = stof(line);
		if (line = fgets(v))
			self.mana = stof(line);
		if (line = fgets(v))
			self.max_mana = stof(line);
		if (line = fgets(v))
			self.level = stof(line);
		if (line = fgets(v))
			self.skillpoints = stof(line);
		if (line = fgets(v))
			self.exp = stof(line);
		if (line = fgets(v))
			self.exp_next = stof(line);
		if (line = fgets(v))
			self.gold = stof(line);
		if (line = fgets(v))
			self.attack_power_min = stof(line);
		if (line = fgets(v))
			self.attack_power_max = stof(line);
		if (line = fgets(v))
			self.attack_speed = stof(line);
		if (line = fgets(v))
			self.attack_type = stof(line);
		if (line = fgets(v))
			self.attack_stamina = stof(line);
		if (line = fgets(v))
			self.attack_length = stof(line);
		if (line = fgets(v))
			self.main_hand = line;
		if (line = fgets(v))
			self.off_hand = line;
		if (line = fgets(v))
			self.armorname = line;
		if (line = fgets(v))
			self.armorvalue = stof(line);
		if (line = fgets(v))
			self.pvp = stof(line);
		if (line = fgets(v))
			self.pvpenable_count = stof(line);
		if (line = fgets(v))
			self.pvp_autoflagged = stof(line);
		if (line = fgets(v))
			self.blockvalue = stof(line);
		if (line = fgets(v))
			self.spell_equipped = line;
		if (line = fgets(v))
			self.spell_power_min = stof(line);
		if (line = fgets(v))
			self.spell_power_max = stof(line);
		if (line = fgets(v))
			self.projectile_power_min = stof(line);
		if (line = fgets(v))
			self.projectile_power_max = stof(line);
		//

		// skills
		if (line = fgets(v))
			self.skill_unarmed = stof(line);
		if (line = fgets(v))
			self.skill_slash = stof(line);
		if (line = fgets(v))
			self.skill_pierce = stof(line);
		if (line = fgets(v))
			self.skill_bash = stof(line);
		if (line = fgets(v))
			self.skill_stealth = stof(line);
		if (line = fgets(v))
			self.skill_backstab = stof(line);
		if (line = fgets(v))
			self.skill_offensivemagic = stof(line);
		if (line = fgets(v))
			self.skill_defensivemagic = stof(line);
		if (line = fgets(v))
			self.skill_neutralmagic = stof(line);
		if (line = fgets(v))
			self.skill_endurance = stof(line);
		if (line = fgets(v))
			self.skill_spellresist = stof(line);
		if (line = fgets(v))
			self.skill_archery = stof(line);
		if (line = fgets(v))
			self.skill_healthregen = stof(line);
		if (line = fgets(v))
			self.skill_manaregen = stof(line);
		if (line = fgets(v))
			self.skill_haggle = stof(line);
		if (line = fgets(v))
			self.skill_climb = stof(line);
		if (line = fgets(v))
			self.skill_swim = stof(line);
		if (line = fgets(v))
			self.skill_acrobatic = stof(line);
		//

		//jobs
		if (line = fgets(v))
			self.skill_mining = stof(line);
		if (line = fgets(v))
			self.skill_fishing = stof(line);
		if (line = fgets(v))
			self.skill_woodcutting = stof(line);
		//
		
		if (line = fgets(v)) // inventory count
			self.read_inv_count = stof(line);

		if (line = fgets(v)) // spell count
			self.spell_count = stof(line);

		// load inventory
		float i;
		string what = "";
		for (i = 0; i < self.read_inv_count; i++)
		{
			if (line = fgets(v)) // add item
			{
				what = line;
				AddToInventory(self, what, 0);
			}
			if (line = fgets(v)) // add count to item
				AddToInventory(self, what, stof(line));
		}
		// load spells
		for (i = 0; i < self.spell_count; i++)
		{
			if (line = fgets(v)) // add spell(s)
				self.spell[i] = line;
		}

		fclose(v);

		setorigin (self, self.origin); // relink properly
		self.fixangle = TRUE;
		self.displayname = self.loginname;
		self.stamina = 100;
		
		PlayerSpawn(1); // Put player in game
	}
	else
	{
		sprint(self, PRINT_HIGH, "Character doesn't exist\n");
		return;
	}

	sprint(self, PRINT_HIGH, strcat(self.loginname, " character resumed\n"));
};

void(string LOGIN_NAME, string LOGIN_GENDER) CSEv_CreateNewCharacter_ss =
{
	self.loginname = LOGIN_NAME; // Grab login name from CSQC
	self.gender = LOGIN_GENDER; // Grab gender from CSQC
	
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