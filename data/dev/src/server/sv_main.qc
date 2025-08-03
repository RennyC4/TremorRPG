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
	clientstat(STAT_MANA, EV_FLOAT, mana);
	clientstat(STAT_MAXMANA, EV_FLOAT, max_mana);
	clientstat(STAT_STAMINA, EV_FLOAT, stamina);

	clientstat(STAT_MAINHAND, EV_STRING, main_hand);
	clientstat(STAT_OFFHAND, EV_STRING, off_hand);

	clientstat(STAT_LEVEL, EV_FLOAT, level);
	clientstat(STAT_EXP, EV_FLOAT, exp);
	clientstat(STAT_EXPNEEDED, EV_FLOAT, exp_next);
	clientstat(STAT_EXPOLDNEEDED, EV_FLOAT, exp_oldnext);
	clientstat(STAT_GOLD, EV_FLOAT, gold);
	clientstat(STAT_GENDER, EV_STRING, gender);
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

	registercommand("show_character", "Displays character information screen\n");

	SSQC_SendValuesToCSQC();
};

// Registered console commands (defined in main.qc)
float(string cmd) ConsoleCmd =
{
	entity targ;

	tokenize(cmd);
	if (argv(0) == "show_character")
	{
		for (entity targ = world;(targ = find(targ, classname, "player"));)
		{
			if (clienttype(targ) == CLIENTTYPE_REAL)
			{
				if (targ.menu == MENU_OFF)
					targ.menu = MENU_CHARACTER;
				else
					targ.menu = MENU_OFF;
			}
		}
	}
	else
		return FALSE;
	return TRUE;
};

void() SpectatorConnect = {};

float(float min, float max) random_range =
{
    return ceil(min + (random() * (max - min)));
};

void (entity player, string msg) Update_EventLog =
{
	string msg2 = strzone(strcat("^7", msg, "\n"));
	//sprint(player, PRINT_HIGH, msg2);
};

void() SV_RunClientCommand = {runstandardplayerphysics(self);};
