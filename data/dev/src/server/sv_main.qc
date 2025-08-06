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
	clientstat(STAT_SKILLPOINTS, EV_FLOAT, skillpoints);
	clientstat(STAT_ATTACKMIN, EV_FLOAT, attack_power_min);
	clientstat(STAT_ATTACKMAX, EV_FLOAT, attack_power_max);
	clientstat(STAT_ATTACKSPEED, EV_FLOAT, attack_speed);
	clientstat(STAT_ARMORNAME, EV_STRING, armorname);
	clientstat(STAT_ARMORVALUE, EV_FLOAT, armorvalue);
	clientstat(STAT_INCOMBAT, EV_FLOAT, incombat);
	// Skills
	clientstat(STAT_SKILL_UNARMED, EV_FLOAT, skill_unarmed);
	clientstat(STAT_SKILL_SLASH, EV_FLOAT, skill_slash);
	clientstat(STAT_SKILL_PIERCE, EV_FLOAT, skill_pierce);
	clientstat(STAT_SKILL_BASH, EV_FLOAT, skill_bash);
	clientstat(STAT_SKILL_STEALTH, EV_FLOAT, skill_stealth);
	clientstat(STAT_SKILL_OFFENSIVEMAGIC, EV_FLOAT, skill_offensivemagic);
	clientstat(STAT_SKILL_DEFENSIVEMAGIC, EV_FLOAT, skill_defensivemagic);
	clientstat(STAT_SKILL_NEUTRALMAGIC, EV_FLOAT, skill_neutralmagic);
	clientstat(STAT_SKILL_ENDURANCE, EV_FLOAT, skill_endurance);
	clientstat(STAT_SKILL_SPELLRESIST, EV_FLOAT, skill_spellresist);
	clientstat(STAT_SKILL_BACKSTAB, EV_FLOAT, skill_backstab);
	clientstat(STAT_SKILL_ARCHERY, EV_FLOAT, skill_archery);
	clientstat(STAT_SKILL_HEALTHREGEN, EV_FLOAT, skill_healthregen);
	clientstat(STAT_SKILL_MANAREGEN, EV_FLOAT, skill_manaregen);
	// Job Skills
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

	precache_model("models/player_m.iqm");

	precache_sound ("levelup.wav");
	precache_sound ("sword1.wav");
	precache_sound ("swordhit.wav");

	SSQC_SendValuesToCSQC();
};

void() SpectatorConnect = {};
void() SV_RunClientCommand = {runstandardplayerphysics(self);};