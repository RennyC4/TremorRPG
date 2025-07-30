//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

void() main = {};

//called for each frame that QC runs
void() StartFrame = {};

// Send SSQC values to CSQC
void() SSQC_SendValuesToCSQC =
{
	clientstat(STAT_GUID, EV_STRING, guid);
	clientstat(STAT_LOGGEDIN, EV_FLOAT, loggedin);
	clientstat(STAT_PLAYER_X, EV_FLOAT, origin_x);
	clientstat(STAT_PLAYER_Y, EV_FLOAT, origin_y);
	clientstat(STAT_PLAYER_Z, EV_FLOAT, origin_z);

	clientstat(STAT_PLAYER_ANGLE_X, EV_FLOAT, angles_x);
	clientstat(STAT_PLAYER_ANGLE_Y, EV_FLOAT, angles_y);
	clientstat(STAT_PLAYER_ANGLE_Z, EV_FLOAT, angles_z);

	clientstat(STAT_MENU, EV_FLOAT, menu);
	clientstat(STAT_ZONENAME, EV_STRING, zonename);
	clientstat(STAT_ZONENAME_TIME, EV_FLOAT, zonename_finished);

	clientstat(STAT_HEALTH, EV_FLOAT, health);
	clientstat(STAT_MAXHEALTH, EV_FLOAT, max_health);
};

void() worldspawn =
{
	//
	// Setup Default Lightstyles
	//

	lightstyle(0, "m");
	lightstyle(1, "mmnmmommommnonmmonqnmmo");
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
	lightstyle(4, "mamamamamama");
	lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");
	lightstyle(6, "nmonqnmomnmomomno");
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
	lightstyle(9, "aaaaaaaazzzzzzzz");
	lightstyle(10, "mmamammmmammamamaaamammma");
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");
	lightstyle(63, "a");

	//
	//
	//

	//
	// Setup Particles
	//

	PART_FOUNTAIN = particleeffectnum("fountain");

	//
	//
	//

	precache_model("models/testplayer.iqm");

	precache_sound ("levelup.wav");
	precache_sound ("sword1.wav");
	precache_sound ("swordhit.wav");

	SSQC_SendValuesToCSQC();
};

void() SpectatorConnect = {};

float(float min, float max) random_range =
{
    return ceil(min + (random() * (max - min)));
};

#define FOR_EACH_CLIENT(v) for(v = world; (v = findflags(v, flags, FL_CLIENT)) != world; )
#define FOR_EACH_REALCLIENT(v) FOR_EACH_CLIENT(v) if(clienttype(v) == CLIENTTYPE_REAL)

void(entity targ, string msg_in) Say =
{
	string msg_string; 

	if (msg_in == "" || msg_in == " ")
		return;

	msg_string = strzone(strcat("(say_msg)", targ.netname, "^7: ", msg_in));
};

void(string command_string) SV_ParseClientCommand =
{
	tokenize(command_string);
	string cmd = argv(0);
	switch (cmd)
	{
		case "say":
			Say(self, substring(command_string, 4, strlen(command_string) - 1));
		break;
		default:
			break;
	}
	clientcommand(self, command_string);
};

void() SV_RunClientCommand = {runstandardplayerphysics(self);};
