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
};

void() PlayerPrintStats =
{
	string pos_x = ftos(self.origin_x);
	string pos_y = ftos(self.origin_y);
	string pos_z = ftos(self.origin_z);

	string ang_x = ftos(self.angles_x);
	string ang_y = ftos(self.angles_y);
	string ang_z = ftos(self.angles_z);

	print(self.loginname, " Coords: ", pos_x, " ", pos_y, " ", pos_z, "\n");
	print(self.loginname, " Angles: ", ang_x, " ", ang_y, "\n");
	print("EXP: ", ftos(self.exp), " Needed: ", ftos(self.exp_next), "\n");
	print("Gold: ", ftos(self.gold), "\n");
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
	if (self.button0)
	{
		if (self.health < 1)
		{
			PlayerSpawn(2); // respawn
			self.melee_finished = time + 1;
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
void() PlayerPostThink = {};

void() ClientConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the realm.\n");
};

void() PlayerDeath =
{
	self.radius_candamage = "FALSE"; // uses string
	self.movetype = MOVETYPE_TOSS;
	self.view_ofs = [0, 0, 4];
	centerprint (self, "You're Dead!\n");
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

		self.movetype = MOVETYPE_WALK;
		self.health = 100;
		self.max_health = 100;
		self.takedamage = DAMAGE_NO;
		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;
		self.fixangle = TRUE;
		setsize(self, [-0, -0, 0], [0, 0, 0]);
		self.view_ofs = [0, 0, 48];

		self.menu = TRUE;
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

		self.menu = FALSE;
		self.loggedin = TRUE;
		self.radius_candamage = "TRUE"; // uses string

		self.solid = SOLID_SLIDEBOX;
		self.flags |= FL_FINDABLE_NONSOLID;
		self.th_die = PlayerDeath;

		setmodel(self, "models/testplayer.iqm");

		stuffcmd (self, sprintf("music %s\n", self.music));
	}
	else // respawning from death
	{
		self.melee_finished = time + 1; // prevent attack on respawn

		self.classname = "player";
		self.health = self.max_health;
		self.takedamage = DAMAGE_AIM;
		self.movetype = MOVETYPE_WALK;
		self.view_ofs = [0, 0, 48];

		self.radius_candamage = "TRUE"; // uses string
		self.solid = SOLID_SLIDEBOX;
		self.flags |= FL_FINDABLE_NONSOLID;

		setorigin(self, spawn_spot.origin + '0 0 1');
		self.angles = spawn_spot.angles;

		setmodel(self, "models/testplayer.iqm");

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
		fputs(v, ftos(self.level), "\n");
		fputs(v, ftos(self.skillpoints), "\n");
		fputs(v, ftos(self.exp), "\n");
		fputs(v, ftos(self.exp_next), "\n");
		fputs(v, ftos(self.gold), "\n");
		fputs(v, ftos(self.attack_power_min), "\n");
		fputs(v, ftos(self.attack_power_max), "\n");

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
			print("Server GUID does not match players\n");
			return;
		}
	}

	// Passed security check
	// Grab stats from user server file
	float v = fopen(LOGIN_NAME, FILE_READ);
	if (v >= 0)
	{
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

		setorigin (self, self.origin); // relink properly
		self.fixangle = TRUE;
		self.displayname = self.loginname;

		fclose(v);

		PlayerSpawn(1); // Put player in game
	}
	else
		print("Character doesn't exist\n");
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
		self.menu = FALSE; // turn off menu in CSQC

		self.health = self.max_health = 100;
		self.level = 1;
		self.exp = 0;
		self.exp_next = 100;
		self.skillpoints = 25; // 25 skill points new players can dump into stats
		self.attack_power_min = 2;
		self.attack_power_max = 6;

		forceinfokey(self, "name", LOGIN_NAME);
		CSEv_Player_SaveChar();
		self.displayname = self.loginname;
		PlayerSpawn(1); // Put player in game
	}
};

//
//
//