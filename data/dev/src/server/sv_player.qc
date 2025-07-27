
//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc.
//

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

void() PlayerPrintLocation =
{
	string pos_x = ftos(self.origin_x);
	string pos_y = ftos(self.origin_y);
	string pos_z = ftos(self.origin_z);

	print("Coords: ", pos_x, " ", pos_y, " ", pos_z, "\n");
};

void() CheckImpulses =
{
	switch (self.impulse)
	{
		case 1:
			PlayerPrintLocation(); // Debugging for laying down entities
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

void() PlayerPreThink =
{	
	CheckImpulses();
	makevectors(self.v_angle);

	if (self.button0)
	{
		// Write attack code
	}

	if (self.button2)
		PlayerJump();
	else
		self.flags = self.flags | FL_JUMPRELEASED;
};

void() PlayerPostThink = {};
void() ClientKill = {};

void() ClientConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the realm.\n");
};

void() PlayerSpawn =
{
	entity spawn_spot = get_spawn_point();

	self.classname = "player";
	self.solid = SOLID_SLIDEBOX;
	setmodel(self, "models/testplayer.iqm");
	self.movetype = MOVETYPE_WALK;
	self.health = 100;
	setorigin(self, spawn_spot.origin + '0 0 1');
	self.angles = spawn_spot.angles;
	self.fixangle = TRUE;
	setsize(self, [-16, -16, 0], [16, 16, 56]);
	self.view_ofs = [0, 0, 48];
	self.player_loggedin = FALSE;
};

void() PutClientInServer =
{
	player_chain_add(self);

	self.player_guid = infokey(self, INFOKEY_P_GUID);
	if (!self.player_guid)
	{
		sprint(self, PRINT_HIGH, "please set cl_sendguid to 1\n");
		dropclient(self);
		return;
	}
	else
		PlayerSpawn();
};

void() ClientDisconnect =
{
	if (self.player_guid) // valid player
	{
		// Write players last X, Y, Z into their data file on disconnect
		string savename = strcat(self.netname, "_sv"); // add _sv to note that these are player server stats

		float v = fopen(savename, FILE_WRITE);
		if (v >= 0)
		{
			fputs(v, ftos(self.origin_x), "\n");
			fputs(v, ftos(self.origin_y), "\n");
			fputs(v, ftos(self.origin_z), "\n");

			fputs(v, ftos(self.angles_x), "\n");
			fputs(v, ftos(self.angles_y), "\n");
			fputs(v, ftos(self.angles_z), "\n");

			fclose(v);
		}
	}

	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the realm.\n");
	player_chain_remove(self);
};

void() SetNewParms = {};
void() SetChangeParms = {};
void() info_player_start = {};

void(float elapsedtime) SV_PausedTic =
{
	// if (elapsedtime > 2) setpause(0);
};

void(string command_string) SV_ParseClientCommand =
{
	tokenize(command_string);
	string cmd = argv(0);
	switch (cmd)
	{
		default: break;
	}
	clientcommand(self, command_string);
};

void() SV_RunClientCommand = {runstandardplayerphysics(self);};

void() CSEv_ResumeCharacter = 
{
	// Grab stats from user server file
	string line;
	string loadname = strcat(self.netname, "_sv"); // add _sv to note that these are player server stats
	float v = fopen(loadname, FILE_READ);
	if (v >= 0)
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

		setorigin (self, self.origin); // relink properly
		self.fixangle = TRUE;

		fclose(v);
	}
	self.player_loggedin = TRUE;
};

void() CSEv_CreateNewCharacter =
{
	self.player_loggedin = TRUE;
	print ("Create new character called\n");
};