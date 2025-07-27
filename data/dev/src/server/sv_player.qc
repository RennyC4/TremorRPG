
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

	print("Coord: ", pos_x, " ", pos_y, " ", pos_z, "\n");
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
	player_chain_remove(self);
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the realm.\n");
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

void() SV_RunClientCommand =
{
	runstandardplayerphysics(self);
};