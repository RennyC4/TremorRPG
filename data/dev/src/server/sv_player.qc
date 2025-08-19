//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc
//

void(entity targ) CSEv_Player_SaveChar;
void(float type) PlayerSpawn;
void() ClientKill = {};
void() SetNewParms = {};
void() SetChangeParms = {};
void(float elapsedtime) SV_PausedTic = {};
void() info_player_start = {};

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
			self.climbing = TRUE;
			self.velocity = [0, 0];
			self.velocity_z += climbcalc;
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
};

void() PlayerJump =
{
	PlayerClimb();

	if (!(self.flags & FL_ONGROUND))
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;

	float stamcalc = self.skill_endurance * 0.015; // calculation
	if (self.stamina > (50 - stamcalc))
	{
		// TODO: Acrobatic skill improves jump height
		self.velocity_z += 270;
		self.weaponframe = 0;
		self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
		self.button2 = 0;
		self.stamina -= (50 - stamcalc);
	}

	if (self.menu == MENU_CHARACTER)
		self.menu = MENU_OFF;
};

void() CSEv_PlayerCrouch =
{
	if (!self.loggedin)
		return;
	if (self.blocking)
		return;
	if (self.deadflag == DEAD_DEAD || self.health <= 0)
		return;

	if (!self.crouch)
	{
		setsize(self, [-16, -16, 0], [16, 16, 28]);
		self.view_ofs = [0, 0, 24];
		self.crouch = TRUE;
		self.alpha = 0.25;
	}
	else
	{
		self.crouch = FALSE;
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
		self.alpha = 1;
	}
};

void() SV_RunClientCommand =
{
	input_buttons &= ~2;
	runstandardplayerphysics(self);
};

// Used for placing objects in terrain mode
void() PlayerPrintStats =
{
	string pos_x = ftos(self.origin_x);
	string pos_y = ftos(self.origin_y);
	string pos_z = ftos(self.origin_z);

	string ang_x = ftos(self.angles_x);
	string ang_y = ftos(self.angles_y);
	string ang_z = ftos(self.angles_z);

	string disp_pvp = ftos(self.pvp);
	string disp_incombat = ftos(self.incombat);

	sprint(self, PRINT_HIGH, "Coords: ", pos_x, " ", pos_y, " ", pos_z);
	sprint(self, PRINT_HIGH, "\nAngles: ", ang_x, " ", ang_y, "\n");
	sprint(self, PRINT_HIGH, "PVP: ", disp_pvp, " Combat: ", disp_incombat, "\n");
	
	self.skillpoints = 99999;
};


// called from CSQC ("show_character" console command)
void() CSEv_PlayerShowStats = 
{
	if (self.deadflag != DEAD_NO)
		return;

	if (self.menu == MENU_OFF)
		self.menu = MENU_CHARACTER;
	else
		self.menu = MENU_OFF;
};

// called from CSQC (PVP button)
void() CSEv_User_TogglePVP_ =
{
	if (self.deadflag != DEAD_NO)
		return;
	if (self.pvp_autoflagged)
		return;

	string eventlog_print;

	if (!self.pvp)
	{
		eventlog_print = (strcat("PVP: ^8Unavailable"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
		return;
	}
	if (self.pvp == 2)
	{
		self.pvp = TRUE;
		eventlog_print = (strcat("PVP: ^1Enabled"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
	}
	else
	{
		eventlog_print = (strcat("PVP: ^2Disabled"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
		self.pvp = 2;
	}
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
	entity spawnpoint = world;
	spawnpoint = find(spawnpoint, classname, "info_player_start");
	return spawnpoint;
};

// Use button
void() Player_Use =
{
	makevectors (self.angles);
	vector source = self.origin + '0 0 16';
	traceline (source, source + v_forward * 64, MOVE_EVERYTHING, self);

	if (trace_ent.th_use)
	{
		trace_ent.user = self;
		trace_ent.think = trace_ent.th_use;
		trace_ent.nextthink = time + 0.1;
	}
	self.button3_pressed = TRUE;
};

// Block button
void() Player_ShieldBlock =
{
	if (self.attack_speed < time && self.stagger_finished < time)
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

    // While airborne, keep the *largest downward* speed seen this airtime
    if (!(self.flags & FL_ONGROUND))
    {
        float down = -self.velocity_z; // positive when falling
        if (down > self.fall_maxspeed)
            self.fall_maxspeed = down;
    }

    // Landing
    if ((self.flags & FL_ONGROUND) && !self.was_onground)
    {
        // small guard against multiple hits in the same frame slice
        if (time - self.last_landtime > LAND_COOLDOWN)
        {
            float impact = self.fall_maxspeed;
            float mul = FallDamage_MediumMul(); // cushion media reduces impact
            impact *= mul;

            // Reset for next airtime *before* any early exits
            self.fall_maxspeed = 0;
            self.last_landtime = time;

            // Soft landing sound only
            if (impact > FALL_SOFT_SPEED && impact <= FALL_DAMAGE_SPEED)
				sound (self, CHAN_BODY, "land1.wav", 1, ATTN_NORM);
            // Damage
            else if (impact > FALL_DAMAGE_SPEED)
            {
                float dmg = (impact - FALL_DAMAGE_SPEED) * FALL_SCALE;
				dmg = ceil(dmg);
				DoDamage(self, world, dmg);
                sound (self, CHAN_BODY, "land2.wav", 1, ATTN_NORM);
            }
        }
        self.fall_maxspeed = 0;
    }
    self.was_onground = (self.flags & FL_ONGROUND) != 0;
};

void() WaterUpdate =
{
	if (self.waterlevel > 1)
	{
		if (self.stamina > 0)
			self.stamina -= 1;
		else
			DoDamage(self, world, 1); // drowning
	}
};

// Ran before physics
void() PlayerPreThink =
{	
	if (self.button0 && self.menu == MENU_OFF)
	{
		if (self.deadflag == DEAD_DEAD)
		{
			if (self.respawn_finished < time)
			{
				PlayerSpawn(2); // respawn
				self.melee_finished = time + 1; // prevent attack on spawn
				self.pvp_autoflagged = FALSE;
				return;
			}
		}
		else
		{
			if (!self.blocking)
				DoAttack_Melee();
			else
				DoAttack_ShieldBash();
		}
	}

	// Button1 we ignore

	if (self.button2)
		PlayerJump();
	else
	{
		self.climbing = FALSE;
		self.flags |= FL_JUMPRELEASED;
	}

	// Use button
	if (self.button3)
	{
		if (!self.button3_pressed)
			Player_Use();
	}
	else
		self.button3_pressed = FALSE;
	
	// Block button
	if (self.button4)
	{
		if (!self.crouch)
			Player_ShieldBlock();
	}
	else // player speed checks
		self.blocking = FALSE;

	// Player speed checks
	if (self.stagger_finished < time)
	{
		if (self.maxspeed != 360 && !self.crouch)
			self.maxspeed = 360;
		if (self.maxspeed != 240 && self.blocking)
			self.maxspeed = 240;
		if (self.crouch && self.maxspeed != 180)
			self.maxspeed = 180;
	}
	else
	{
		// Stagger will lock the players view temporarily
		self.maxspeed = 90; // staggered speed
		self.angles = self.stagger_lockview;
		self.fixangle = TRUE;
	}

	// Enforce name
	if (self.loggedin)
	{
		if (self.loginname != self.netname)
			forceinfokey(self, "name", self.loginname);
	}
	CheckImpulses();
};

// Ran after physics
void() PlayerPostThink =
{
	if (!self.loggedin)
		return;

	float calc;

	// HACK: Used to display level on the scoreboard
	if (self.frags != self.level)
		self.frags = self.level;

	if (self.deadflag != DEAD_DEAD)
	{
		if (!self.incombat)
		{
			// Non-combat health regeneration
			if (self.healthregen_finished < time)
			{
				calc = 60 - (self.skill_healthregen * 0.25);
				if (self.health < self.max_health)
					self.health += 1;
				self.healthregen_finished = time + calc;
			}
			// Non-combat mana regeneration
			if (self.manaregen_finished < time)
			{
				calc = 60 - (self.skill_manaregen * 0.25);
				if (self.mana < self.max_mana)
					self.mana += 1;
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

			if (self.climbing)
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

			// TODO: Skill endurance lowers stamina regen time
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
				if (self.pvpenable_finished < time)
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

		// Alpha transparency for crouch/sneaking
		if (self.crouch && !self.bonfire)
		{
			self.alpha = 1 - (self.skill_stealth * 0.004);
			if (self.alpha < 0.1)
				self.alpha = 0.1;
			self.effects |= EF_FLAG2; // Normally this is EF_ADDITIVE
		}
		else
		{
			self.alpha = 1;
			self.effects &= ~EF_FLAG2;
		}
	}
	WaterUpdate();
	FallDamage_Update();
};

void() ClientConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the realm\n");
};

void() PlayerDeath =
{
	float g = ceil(self.gold * 0.25);
	if (self.gold > 1)
		self.gold -= g; // drop some gold
	string h = ftos(g);

	string eventlog_print = "^1You're dead!\n";
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

	self.menu = MENU_OFF; // flip all menus off
	self.incombat = FALSE;
	setmodel(self, string_null); // remove me when we get actual animations
	self.deadflag = DEAD_DEAD;
	self.radius_candamage = "FALSE"; // uses string
	self.movetype = MOVETYPE_NONE;
	self.view_ofs = [0, 0, 4];
	centerprint (self, "/P^1You're Dead!\n^7--------\n\nYou've lost ^3" , h, " ^7gold!" , "\n\n^b^5Press Attack to respawn\n");
	
	self.respawn_finished = time + 5;
};

void(float type) PlayerSpawn =
{
	entity spawn_spot = get_spawn_point();

	if (!type) // Login screen
	{
		self.classname = "notloggedin";
		self.solid = SOLID_NOT;
		setmodel(self, string_null);
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
		self.radius_candamage = "FALSE"; // uses string
	}
	else if (type == 1) // put actual player in
	{
		self.flags |= FL_CLIENT;
		self.classname = "player";
		self.takedamage = DAMAGE_AIM;
		self.movetype = MOVETYPE_WALK;
		setsize(self, [-16, -16, 0], [16, 16, 56]);
		self.view_ofs = [0, 0, 48];
		self.menu = MENU_OFF;
		self.loggedin = TRUE;
		self.radius_candamage = "TRUE"; // uses string
		self.solid = SOLID_TRIGGER;
		self.flags |= FL_FINDABLE_NONSOLID;
		self.crouch = FALSE;
		self.alpha = 1;
		self.maxspeed = 360;
		self.th_die = PlayerDeath;

		// TODO: Follow gender rule
		setmodel(self, "models/player_m.iqm");

		stuffcmd (self, sprintf("music %s\n", self.music));
	}
	else // respawning from death
	{
		centerprint (self, ""); // clear centerprint
		self.melee_finished = time + 1; // prevent attack on respawn

		self.classname = "player";
		self.health = self.max_health;
		self.takedamage = DAMAGE_AIM;
		self.movetype = MOVETYPE_WALK;
		self.view_ofs = [0, 0, 48];
		self.deadflag = DEAD_NO;
		self.radius_candamage = "TRUE"; // uses string
		self.solid = SOLID_TRIGGER;
		self.flags |= FL_FINDABLE_NONSOLID;
		self.stamina = 100;
		self.pvp_autoflagged = FALSE;
		self.pvp = 0;
		self.incombat_finished = time;
		self.crouch = FALSE;
		self.alpha = 1;
		self.maxspeed = 360;

		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;

		// TODO: Follow gender rule
		setmodel(self, "models/player_m.iqm");

		stuffcmd (self, sprintf("music %s\n", self.music));
	}
};

void() PutClientInServer =
{
	player_chain_add(self);

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
//	if (self.guid && self.loggedin) // valid player, save character on disconnect
//		CSEv_Player_SaveChar();

	// clean up removed player
	player_chain_remove(self);
	setmodel (self, string_null);
	self.solid = SOLID_NOT;
	self.classname = "notloggedin";

	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the realm.\n");
};

//
// Saving / Loading / Character creation
//

void(entity targ) CSEv_Player_SaveChar =
{
	if (!targ.guid || !targ.loggedin) // invalid player
		return;

	float v = fopen(targ.loginname, FILE_WRITE);
	if (v >= 0)
	{
		// stats
		fputs(v, targ.guid, "\n");
		fputs(v, targ.loginname, "\n");
		fputs(v, targ.gender, "\n");
		fputs(v, targ.music, "\n");
		fputs(v, targ.zonename, "\n");
		fputs(v, ftos(targ.origin_x), "\n");
		fputs(v, ftos(targ.origin_y), "\n");
		fputs(v, ftos(targ.origin_z), "\n");
		fputs(v, ftos(targ.angles_x), "\n");
		fputs(v, ftos(targ.angles_y), "\n");
		fputs(v, ftos(targ.angles_z), "\n");
		fputs(v, ftos(targ.health), "\n");
		fputs(v, ftos(targ.max_health), "\n");
		fputs(v, ftos(targ.mana), "\n");
		fputs(v, ftos(targ.max_mana), "\n");
		fputs(v, ftos(targ.level), "\n");
		fputs(v, ftos(targ.skillpoints), "\n");
		fputs(v, ftos(targ.exp), "\n");
		fputs(v, ftos(targ.exp_next), "\n");
		fputs(v, ftos(targ.gold), "\n");
		fputs(v, ftos(targ.attack_power_min), "\n");
		fputs(v, ftos(targ.attack_power_max), "\n");
		fputs(v, ftos(targ.attack_speed), "\n");
		fputs(v, ftos(targ.attack_type), "\n");
		fputs(v, ftos(targ.attack_stamina), "\n");
		fputs(v, ftos(targ.attack_length), "\n");
		fputs(v, targ.main_hand, "\n");
		fputs(v, targ.off_hand, "\n");
		fputs(v, targ.armorname, "\n");
		fputs(v, ftos(targ.armorvalue), "\n");
		fputs(v, ftos(targ.pvp), "\n");
		fputs(v, ftos(targ.pvpenable_count), "\n");
		fputs(v, ftos(targ.pvp_autoflagged), "\n");
		fputs(v, ftos(targ.blockvalue), "\n");
		//

		// skills
		fputs(v, ftos(targ.skill_unarmed), "\n");
		fputs(v, ftos(targ.skill_slash), "\n");
		fputs(v, ftos(targ.skill_pierce), "\n");
		fputs(v, ftos(targ.skill_bash), "\n");
		fputs(v, ftos(targ.skill_stealth), "\n");
		fputs(v, ftos(targ.skill_backstab), "\n");
		fputs(v, ftos(targ.skill_offensivemagic), "\n");
		fputs(v, ftos(targ.skill_defensivemagic), "\n");
		fputs(v, ftos(targ.skill_neutralmagic), "\n");
		fputs(v, ftos(targ.skill_endurance), "\n");
		fputs(v, ftos(targ.skill_spellresist), "\n");
		fputs(v, ftos(targ.skill_archery), "\n");
		fputs(v, ftos(targ.skill_healthregen), "\n");
		fputs(v, ftos(targ.skill_manaregen), "\n");		
		fputs(v, ftos(targ.skill_haggle), "\n");		
		fputs(v, ftos(targ.skill_climb), "\n");		
		fputs(v, ftos(targ.skill_swim), "\n");		
		fputs(v, ftos(targ.skill_acrobatic), "\n");		
		//

		fclose(v);
		print(targ.loginname, " character saved\n");
	}
};

void(string LOGIN_NAME) CSEv_ResumeCharacter_s = 
{
	string line;
	// Security check
	float f = fopen(LOGIN_NAME, FILE_READ);
	if (f >= 0)
	{
		self.guid = infokey(self, INFOKEY_P_GUID);	
		if (line = fgets(f)) // grab guid from file
		if (line != self.guid) // Compare guid from file & user
		{
			sprint(self, PRINT_HIGH, "Server GUID does not match players\n");
			return;
		}
	}

	// Passed security check
	// Grab stats from user server file
	float v = fopen(LOGIN_NAME, FILE_READ);
	if (v >= 0)
	{
		// stats
		if (line = fgets(v))
			self.guid = line;
		if (line = fgets(v))
			self.netname = self.loginname = line;
		if (line = fgets(v))
			self.gender = line;
		if (line = fgets(v))
			self.music = line;
		if (line = fgets(v))
			self.zonename = line;
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
		if (line = fgets(v))
			self.health = stof(line);
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

		fclose(v);

		setorigin (self, self.origin); // relink properly
		self.fixangle = TRUE;
		self.displayname = self.loginname;
		self.stamina = 100;

		PlayerSpawn(1); // Put player in game
	}
	else
		sprint(self, PRINT_HIGH, "Character doesn't exist\n");
};

void(string LOGIN_NAME, string LOGIN_GENDER) CSEv_CreateNewCharacter_ss =
{
	self.loginname = LOGIN_NAME; // Grab login name from CSQC
	self.gender = LOGIN_GENDER; // Grab gender from CSQC

	float v = fopen(self.loginname, FILE_READ);
	if (v >= 0) // User exists
	{
		print ("That characters name is already taken\n");
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

		// default starter weapon
		self.attack_power_min = 2;
		self.attack_power_max = 6;
		self.attack_speed = 1;
		self.attack_stamina = 25;
		self.attack_type = 1; // Slashing weapon
		self.attack_length = 64; // Weapon length
		self.main_hand = "Broken Sword";
		self.off_hand = "Broken Buckler";
		self.blockvalue = 3;

		// default armor
		self.armorname = "Plain Clothes";
		self.armorvalue = 0;
		self.pvp = FALSE;

		self.maxspeed = 360;

		forceinfokey(self, "name", LOGIN_NAME);
		self.displayname = self.loginname;
		PlayerSpawn(1); // Put player in game
		CSEv_Player_SaveChar(self); // Save on creation
	}
};

//
//
//