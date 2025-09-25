//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

#pragma target fte // TremorRPG FTE only
#pragma warning disable F302 // disable potentially uninitialised variable
#pragma warning disable Q201 // disable suggest parenthesis for assignment used as truth value

void() main = {};
void() SpectatorConnect = {sprint(self, PRINT_HIGH, "Spectator mode is not supported\n");dropclient(self);}; // Tremor: No spectators allowed

void() spawn_daynight;

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
	clientstat(STAT_PVP, EV_FLOAT, pvp);
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
	clientstat(STAT_ATTACKTYPE, EV_FLOAT, attack_type);
	clientstat(STAT_ARMORNAME, EV_STRING, armorname);
	clientstat(STAT_ARMORVALUE, EV_FLOAT, armorvalue);
	clientstat(STAT_INCOMBAT, EV_FLOAT, incombat);
	clientstat(STAT_BLOCKVALUE, EV_FLOAT, blockvalue);
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
	clientstat(STAT_SKILL_HAGGLE, EV_FLOAT, skill_haggle);
	clientstat(STAT_SKILL_CLIMB, EV_FLOAT, skill_climb);
	clientstat(STAT_SKILL_SWIM, EV_FLOAT, skill_swim);
	clientstat(STAT_SKILL_ACROBATIC, EV_FLOAT, skill_acrobatic);
	clientstat(STAT_REAPERMARK, EV_FLOAT, reaper_marks);
	clientstat(STAT_LOCKVIEW, EV_FLOAT, lockview_finished);
	clientstat(STAT_SPELLEQUIPPED, EV_STRING, spell_equipped);
	clientstat(STAT_LOCKEDON, EV_FLOAT, lock_on);
	clientstat(STAT_VENDOR, EV_FLOAT, npc_vendor);
	clientstat(STAT_SPELLMIN, EV_FLOAT, spell_power_min);
	clientstat(STAT_SPELLMAX, EV_FLOAT, spell_power_max);
	clientstat(STAT_BONFIRE, EV_FLOAT, bonfire);
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
	// Setup Particles
	//
	PART_LEVELUP = particleeffectnum("levelup");
	PART_FOUNTAIN = particleeffectnum("fountain");
	PART_BONFIRE = particleeffectnum("bonfire");
	PART_WTORCH1 = particleeffectnum("wtorch1");

	// Magic
	PART_MAGIC_THORN1 = particleeffectnum("thornhit");
	PART_MAGIC_THORN2 = particleeffectnum("thornwall");

	PART_MAGIC_CASTING = particleeffectnum("magiccast");
	PART_MAGIC_LIGHTHEAL = particleeffectnum("lightheal");
	//

	precache_model("models/player_m.glb");
	precache_model("models/player_f.glb");
	precache_model("models/chest.glb");
	precache_model("progs/targetdot.spr");

	precache_sound ("levelup.wav");
	precache_sound ("sword1.wav");
	precache_sound ("swordhit.wav");
	precache_sound ("backstab.wav");
	precache_sound ("shield1.wav");
	precache_sound ("shield2.wav");
	precache_sound ("shield3.wav");
	precache_sound ("parry.wav");
	precache_sound ("land1.wav");
	precache_sound ("land2.wav");
	precache_sound ("jump.wav");
	precache_sound ("lantern.wav");
	precache_sound ("move_step0.wav");
	precache_sound ("move_step1.wav");
	precache_sound ("move_wade0.wav");
	precache_sound ("move_wade1.wav");
	precache_sound ("learnspell.wav");

	precache_sound ("item/drop.wav");
	precache_sound ("item/get.wav");

	precache_sound ("magic/thorn_hit.wav");
	precache_sound ("magic/thorn_misc.wav");
	precache_sound ("magic/thorn_cast.wav");
	precache_sound ("magic/lightheal.wav");
	precache_sound ("magic/casting.wav");

	SSQC_SendValuesToCSQC();
	spawn_daynight();
};

//
// day night server handler - spawned inside .hmp
//

entity daynight;
float daynight_count;
float daynight_speed;

void() daynight_think =
{
    daynight_speed += 0.05;
    if (daynight_speed >= 2 * M_PI)
        daynight_speed -= 2 * M_PI;

    daynight_count = (sin(daynight_speed) + 1) * 0.5;

    float cycle = 2 * M_PI;
    float day_len  = 0.40 * cycle; // 40% of cycle
    float dusk_len = 0.10 * cycle; // 10%
    float night_len = 0.40 * cycle; // 40%

    // float dawn_len = cycle - (day_len + dusk_len + night_len); // 10%

    float a = daynight_speed; // 0..2PI
    float newtimeofday;

    if (a < day_len)
        newtimeofday = TIME_DAY;
    else if (a < day_len + dusk_len)
        newtimeofday = TIME_DUSK;
    else if (a < day_len + dusk_len + night_len)
        newtimeofday = TIME_NIGHT;
    else
        newtimeofday = TIME_DAWN;

    // only broadcast on change
    if (newtimeofday != timeofday)
    {
        timeofday = newtimeofday;

        for (entity b = world; (b = find(b, classname, "player")); )
        {
            msg_entity = b;
            WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
            WriteByte(MSG_MULTICAST, CSQC_TIMEOFDAY);
            WriteByte(MSG_MULTICAST, timeofday);
            multicast(self.origin, MULTICAST_ONE);
        }
    }

    // hold longer during DAY/NIGHT, shorter during transitions
    if (timeofday == TIME_NIGHT || timeofday == TIME_DAY)
        self.nextthink = time + 8;
    else
        self.nextthink = time + 4;
};

void() spawn_daynight =
{
	if (substring(world.model, -3, 3) != "hmp")
		return;
	if (daynight) // only spawn once
		return;
	if (cvar("developer") == 1)
		return;

	daynight = spawn();
	daynight.think = daynight_think;
	daynight.nextthink = time + 0.1;
};