//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc
//

void() CSEv_Player_SaveChar;
void(float type) PlayerSpawn;
void() ClientKill = {};
void() SetNewParms = {};
void() SetChangeParms = {};
void(float elapsedtime) SV_PausedTic = {};
void() info_player_start = {};

void() PlayerJump =
{
	if (!(self.flags & FL_ONGROUND))
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;

	self.weaponframe = 0;
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.button2 = 0;

	if (self.menu == MENU_CHARACTER)
		self.menu = MENU_OFF;
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

	sprint(self, PRINT_HIGH, "Coords: ", pos_x, " ", pos_y, " ", pos_z);
	sprint(self, PRINT_HIGH, "\nAngles: ", ang_x, " ", ang_y, "\n");
};

// This is ugly / could be written better but eh
void(float which) CSEv_User_AddSkillPoint_f =
{
	if (self.skillpoints <= 0)
		return;

	float cap = (self.level * 10) + 10;
	if (!which)
	{
		if (self.skill_unarmed < cap)
		{
			self.skill_unarmed += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 1)
	{
		if (self.skill_slash < cap)
		{
			self.skill_slash += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 2)
	{
		if (self.skill_pierce < cap)
		{
			self.skill_pierce += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 3)
	{
		if (self.skill_unarmed < cap)
		{
			self.skill_bash += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 4)
	{
		if (self.skill_stealth < cap)
		{
			self.skill_stealth += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 5)
	{
		if (self.skill_backstab < cap)
		{
			self.skill_backstab += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 6)
	{
		if (self.skill_offensivemagic < cap)
		{
			self.skill_offensivemagic += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 7)
	{
		if (self.skill_defensivemagic < cap)
		{
			self.skill_defensivemagic += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 8)
	{
		if (self.skill_neutralmagic < cap)
		{
			self.skill_neutralmagic += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 9)
	{
		if (self.skill_endurance < cap)
		{
			self.skill_endurance += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 10)
	{
		if (self.skill_spellresist < cap)
		{
			self.skill_spellresist += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 11)
	{
		if (self.skill_archery < cap)
		{
			self.skill_archery += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 12)
	{
		if (self.skill_healthregen < cap)
		{
			self.skill_healthregen += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else if (which == 13)
	{
		if (self.skill_manaregen < cap)
		{
			self.skill_manaregen += 1;
			self.skillpoints -= 1;
			return;
		}
	}
	else
	{
		print ("error: skill doesn't exist\n");
		return;
	}
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
		self.pvp = TRUE;
		eventlog_print = (strcat("PVP: ^1Enabled"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
	}
	else
	{
		eventlog_print = (strcat("PVP: ^2Disabled"));
		stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
		self.pvp = FALSE;
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
			DoAttack_Melee();
	}

	if (self.button2)
		PlayerJump();
	else
		self.flags = self.flags | FL_JUMPRELEASED;

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

	if (self.deadflag != DEAD_DEAD)
	{
		if (!self.incombat)
		{
			// Non-combat health regeneration
			if (self.healthregen_finished < time)
			{		
				if (self.health < self.max_health)
					self.health += 1;

				self.healthregen_finished = time + 1;
			}
		}
		// Stamina regeneration
		if (self.staminaregen_finished < time)
		{		
			if (self.stamina < 100)
				self.stamina += 1;
			else
				self.stamina = 100;

			self.staminaregen_finished = time + 0.1;
		}
		if (self.pvp == 2 && self.pvpenable_finished < time)
		{
			self.pvp = TRUE;
			self.pvp_autoflagged = TRUE;
			string eventlog_print = "^1You've been auto flagged for PVP!\n";
			stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
		}
	}
};

void() ClientConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the realm\n");
};

void() PlayerDeath =
{
	string eventlog_print = "^1You're dead!\n";
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

	self.menu = MENU_OFF; // flip all menus off
	self.incombat = FALSE;
	self.deadflag = DEAD_DEAD;
	self.radius_candamage = "FALSE"; // uses string
	self.movetype = MOVETYPE_NONE;
	self.view_ofs = [0, 0, 4];
	centerprint (self, "/PYou're Dead!\n\nPress Attack to respawn\n");
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
		self.solid = SOLID_SLIDEBOX;
		self.flags |= FL_FINDABLE_NONSOLID;
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
		self.solid = SOLID_SLIDEBOX;
		self.flags |= FL_FINDABLE_NONSOLID;
		self.stamina = 100;
		self.pvp_autoflagged = FALSE;

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
	if (self.guid && self.loggedin) // valid player, save character on disconnect
		CSEv_Player_SaveChar();

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

void() CSEv_Player_SaveChar =
{
	if (!self.guid || !self.loggedin) // invalid player
		return;

	float v = fopen(self.loginname, FILE_WRITE);
	if (v >= 0)
	{
		// stats
		fputs(v, self.guid, "\n");
		fputs(v, self.loginname, "\n");
		fputs(v, self.gender, "\n");
		fputs(v, self.music, "\n");
		fputs(v, self.zonename, "\n");
		fputs(v, ftos(self.origin_x), "\n");
		fputs(v, ftos(self.origin_y), "\n");
		fputs(v, ftos(self.origin_z), "\n");
		fputs(v, ftos(self.angles_x), "\n");
		fputs(v, ftos(self.angles_y), "\n");
		fputs(v, ftos(self.angles_z), "\n");
		fputs(v, ftos(self.health), "\n");
		fputs(v, ftos(self.max_health), "\n");
		fputs(v, ftos(self.mana), "\n");
		fputs(v, ftos(self.max_mana), "\n");
		fputs(v, ftos(self.level), "\n");
		fputs(v, ftos(self.skillpoints), "\n");
		fputs(v, ftos(self.exp), "\n");
		fputs(v, ftos(self.exp_next), "\n");
		fputs(v, ftos(self.gold), "\n");
		fputs(v, ftos(self.attack_power_min), "\n");
		fputs(v, ftos(self.attack_power_max), "\n");
		fputs(v, ftos(self.attack_speed), "\n");
		fputs(v, ftos(self.attack_type), "\n");
		fputs(v, ftos(self.attack_stamina), "\n");
		fputs(v, self.main_hand, "\n");
		fputs(v, self.off_hand, "\n");
		fputs(v, self.armorname, "\n");
		fputs(v, ftos(self.armorvalue), "\n");
		fputs(v, ftos(self.pvp), "\n");
		//

		// skills
		fputs(v, ftos(self.skill_unarmed), "\n");
		fputs(v, ftos(self.skill_slash), "\n");
		fputs(v, ftos(self.skill_pierce), "\n");
		fputs(v, ftos(self.skill_bash), "\n");
		fputs(v, ftos(self.skill_stealth), "\n");
		fputs(v, ftos(self.skill_backstab), "\n");
		fputs(v, ftos(self.skill_offensivemagic), "\n");
		fputs(v, ftos(self.skill_defensivemagic), "\n");
		fputs(v, ftos(self.skill_neutralmagic), "\n");
		fputs(v, ftos(self.skill_endurance), "\n");
		fputs(v, ftos(self.skill_spellresist), "\n");
		fputs(v, ftos(self.skill_archery), "\n");
		fputs(v, ftos(self.skill_healthregen), "\n");
		fputs(v, ftos(self.skill_manaregen), "\n");		
		//

		fclose(v);
		print(self.loginname, " character saved\n");
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
		{
			self.netname = line;
			self.loginname = line;
		}
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
			self.main_hand = line;
		if (line = fgets(v))
			self.off_hand = line;
		if (line = fgets(v))
			self.armorname = line;
		if (line = fgets(v))
			self.armorvalue = stof(line);
		if (line = fgets(v))
			self.pvp = stof(line);
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
		self.main_hand = "Broken Sword";
		self.off_hand = "Empty";

		// default armor
		self.armorname = "Plain Clothes";
		self.armorvalue = 0;
		self.pvp = FALSE;

		forceinfokey(self, "name", LOGIN_NAME);
		CSEv_Player_SaveChar();
		self.displayname = self.loginname;
		PlayerSpawn(1); // Put player in game
	}
};

//
//
//