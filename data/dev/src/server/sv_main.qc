//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

float multilogin;
float exp_multiplier;
float gold_multiplier;

#pragma target fte // TremorRPG FTE only
#pragma warning disable F302 // disable potentially uninitialised variable
#pragma warning disable Q201 // disable suggest parenthesis for assignment used as truth value

void() main = {};
void() SpectatorConnect = {sprint(self, PRINT_HIGH, "Spectator mode is not supported\n");dropclient(self);}; // Tremor: No spectators allowed
void() info_null ={};

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
	clientstat(STAT_VENDOR, EV_FLOAT, npc_vendor);
	clientstat(STAT_SPELLMIN, EV_FLOAT, spell_power_min);
	clientstat(STAT_SPELLMAX, EV_FLOAT, spell_power_max);
	clientstat(STAT_BONFIRE, EV_FLOAT, bonfire);
	clientstat(STAT_CASTING, EV_FLOAT, cast_finished);
	clientstat(STAT_ATTACKSTAM, EV_FLOAT, attack_stamina);
	clientstat(STAT_PROJ_MIN, EV_FLOAT, projectile_power_min);
	clientstat(STAT_PROJ_MAX, EV_FLOAT, projectile_power_max);
	clientstat(STAT_GOLD_BANK, EV_FLOAT, gold_bank);
	clientstat(STAT_LEVITATE, EV_FLOAT, levitate_finished);

	clientstat(STAT_HELMETNAME, EV_STRING, helmetname);
	clientstat(STAT_HELMETVALUE, EV_FLOAT, helmetvalue);


	// Job Skills
	clientstat(STAT_MINING, EV_FLOAT, skill_mining);
	clientstat(STAT_FISHING, EV_FLOAT, skill_fishing);
	clientstat(STAT_WOODCUTTING, EV_FLOAT, skill_woodcutting);
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
	PART_WTORCH2 = particleeffectnum("wtorch2");
	PART_HEALTHPOTION = particleeffectnum("healthpotion");
	PART_MANAPOTION = particleeffectnum("manapotion");
	PART_BLOCK = particleeffectnum("block");
	PART_PARRY = particleeffectnum("parry");
	PART_MAGIC_CASTING = particleeffectnum("magiccast");
	PART_MAGIC_CASTING_ORB = particleeffectnum("magiccast_orb");
	PART_MELEE_HITWALL = particleeffectnum("melee_wallhit");
	PART_ARROW_HITWALL = particleeffectnum("arrow_wallhit");

	//
	PART_TREEHIT = particleeffectnum("treehit");
	PART_TREEFALL = particleeffectnum("treefall");
	//
	PART_OREHIT = particleeffectnum("orehit");
	PART_OREDIE = particleeffectnum("oredie");

	// Magic Spells - Particles
	PART_MAGIC_THORN1 = particleeffectnum("thornhit");
	PART_MAGIC_THORN2 = particleeffectnum("thornwall");
	PART_MAGIC_LIGHTHEAL = particleeffectnum("lightheal");
	PART_MAGIC_LEVITATE = particleeffectnum("levitate");
	//

	precache_model("models/player_m.glb");
	precache_model("models/player_f.glb");
	precache_model("models/chest.glb");
	precache_model("models/arrow.glb");
	precache_model("models/fishingbobber.glb");
	precache_model("progs/targetdot.spr");

	precache_sound ("bonfire1.wav");
	precache_sound ("levelup.wav");
	precache_sound ("hatchet1.wav");
	precache_sound ("miningpick1.wav");
	precache_sound ("arrow1.wav");
	precache_sound ("arrow2.wav");
	precache_sound ("sword1.wav");
	precache_sound ("punch1.wav");
	precache_sound ("dagger1.wav");
	precache_sound ("club1.wav");
	precache_sound ("punchhit.wav");
	precache_sound ("punchhit2.wav");
	precache_sound ("swordhit.wav");
	precache_sound ("swordhit2.wav");
	precache_sound ("daggerhit.wav");
	precache_sound ("daggerhit2.wav");
	precache_sound ("clubhit.wav");
	precache_sound ("clubhit2.wav");
	precache_sound ("backstab.wav");
	precache_sound ("shield1.wav");
	precache_sound ("shield2.wav");
	precache_sound ("shield3.wav");
	precache_sound ("parry.wav");
	precache_sound ("hitw_tink.wav");
	precache_sound ("hitw_bash.wav");
	precache_sound ("land1.wav");
	precache_sound ("land2.wav");
	precache_sound ("jump.wav");
	precache_sound ("lantern.wav");
	precache_sound ("move_step0.wav");
	precache_sound ("move_step1.wav");
	precache_sound ("move_wade0.wav");
	precache_sound ("move_wade1.wav");
	precache_sound ("learnspell.wav");
	precache_sound ("fishcast.wav");
	precache_sound ("fishbobber.wav");
	precache_sound ("fishsplash.wav");

	precache_sound ("item/drop.wav");
	precache_sound ("item/get.wav");
	precache_sound ("eat.wav");

	precache_sound ("magic/thorn_hit.wav");
	precache_sound ("magic/thorn_misc.wav");
	precache_sound ("magic/thorn_cast.wav");
	precache_sound ("magic/lightheal.wav");
	precache_sound ("magic/levitate.wav");
	precache_sound ("magic/levitateend.wav");
	precache_sound ("magic/casting.wav");

	SSQC_SendValuesToCSQC();
	spawn_daynight();
	
	// additional cvar setup
	registercvar("sv_multilogin", "0");
	registercvar("sv_expdmultiplier", "0");
	registercvar("sv_goldmultiplier", "0");

	multilogin = cvar("sv_multilogin");
	exp_multiplier = cvar("sv_expdmultiplier");
	gold_multiplier = cvar("sv_goldmultiplier");

	// Setup MOTD
    float f;
    string line, temp;

    f = fopen("motd.txt", FILE_READ);
    if (f > 0)
    {
        motd = ""; // clear previous MOTD, if any
        while ((line = fgets(f)))
            motd = strcat(motd, line, "\n");
        fclose(f);
    }
    else
	{
        motd = "";
		print ("Optional: motd not set\n");
	}
};

//
// day night server handler - spawned inside .hmp
//

entity daynight;
float daynight_count;
float daynight_speed;

void() daynight_think =
{
	// Let's not contend with day/night while developing
	if (cvar("developer") > 0)
	{
		remove(self);
		return;
	}

    daynight_speed += 0.05;
    if (daynight_speed >= 2 * M_PI)
        daynight_speed -= 2 * M_PI;

    daynight_count = (sin(daynight_speed) + 1) * 0.5;

    float cycle = 2 * M_PI;
    float day_len  = 0.40 * cycle; // 40% of cycle
    float dusk_len = 0.10 * cycle; // 10%
    float night_len = 0.40 * cycle; // 40%

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

		// update entity lighting on world map server-side
		for (entity c = world;(c = findfloat(c, worldlight, TRUE));)
		{
			c.drawflags |= 7;
			if (timeofday == TIME_DAY)
				c.abslight = 1;
			else if (timeofday == TIME_NIGHT)
				c.abslight = 225;
			else if (timeofday == TIME_DAWN)
				c.abslight = 140;
			else // dusk
				c.abslight = 190;
		}

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
	{
		if (timeofday == TIME_DAY)
			self.nextthink = time + 12;
		else
			self.nextthink = time + 8;
	}
    else
        self.nextthink = time + 6; // transition times between day/night

	// for debugging
	//self.nextthink = time + 0.1;
};

void() spawn_daynight =
{
	if (substring(world.model, -3, 3) != "hmp")
		return;
	if (daynight) // only spawn once
		return;
	if (cvar("developer") > 0)
		return;

	daynight = spawn();
	daynight.think = daynight_think;
	daynight.nextthink = time + 0.1;
};

float(entity e) CheckChatFlood =
{
    // If enough time passed, reset counter
    if (time - e.chat_last_time > CHAT_FLOOD_RESET)
        e.chat_flood_count = 0;

    // Increase counter
    e.chat_flood_count += 1;

    // Detect flooding
    if (e.chat_flood_count > CHAT_FLOOD_LIMIT)
        return TRUE;

    // Detect spam speed
    if (time - e.chat_last_time < CHAT_FLOOD_TIME)
        return TRUE;

    e.chat_last_time = time;

    return FALSE;
};

void(entity to, string msg) SendChat_Message =
{
    msg_entity = to;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
    WriteByte(MSG_MULTICAST, CSQC_SAY); // zone chat packet
    WriteString(MSG_MULTICAST, msg);
    multicast(self.origin, MULTICAST_ONE_R);
};

void(entity to, entity speaker, string msg) SendChat_Message_Nearby =
{
    msg_entity = to;

    WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
    WriteByte(MSG_MULTICAST, CSQC_SAY_NEARBY);
    WriteEntity(MSG_MULTICAST, speaker);
    WriteString(MSG_MULTICAST, msg);

    multicast(to.origin, MULTICAST_ONE_R);
};

#define CHAT_MAX_CHARS 90
void(string str) SV_ParseClientCommand =
{
    float numargs = tokenize_console(str);
    if (numargs < 1)
        return;

	// Zone chat
	if (argv(0) == "say")
	{
		if (CheckChatFlood(self))
		{
			sprint(self, PRINT_HIGH, "^1Spam limit reached, please wait\n");
			return;
		}

		string raw = substring(str, 4, strlen(str));

		if (strlen(raw) > CHAT_MAX_CHARS)
			raw = substring(raw, 0, CHAT_MAX_CHARS);

		string msg;
		for (entity e = world; (e = find(e, classname, "player")); )
		{
			if (self == e)
				msg = strcat("[^2Zone^7]^3", self.netname, "^7: ", raw);
			else
				msg = strcat("[^2Zone^7]^5", self.netname, "^7: ", raw);

			SendChat_Message(e, msg);

			// print each message to server console
			print(msg, "\n");
		}

		//print (msg, "\n"); // print to server console
		return;
	}

	// Nearby chat
	if (argv(0) == "say_team")
	{
		if (CheckChatFlood(self))
		{
			sprint(self, PRINT_HIGH, "^1Spam limit reached, please wait\n");
			return;
		}

		raw = substring(str, 9, strlen(str));
		string bubble_msg = raw; // only the spoken text

		// Remove starting quote
		if (substring(bubble_msg, 0, 1) == "\"")
			bubble_msg = substring(bubble_msg, 1, strlen(bubble_msg));

		// Remove ending quote
		if (substring(bubble_msg, strlen(bubble_msg)-1, 1) == "\"")
			bubble_msg = substring(bubble_msg, 0, strlen(bubble_msg)-1);
		
		if (strlen(raw) > CHAT_MAX_CHARS)
			raw = substring(raw, 0, CHAT_MAX_CHARS);

		// For Nearby chat
		for (entity e = world; (e = find(e, classname, "player")) ;)
		{
			if (self == e) // local player colour coded text
				msg = strcat("[^1Nearby^7]^3", self.netname, "^7: ", raw);
			else
				msg = strcat("[^1Nearby^7]^5", self.netname, "^7: ", raw);

			if (vlen(e.origin - self.origin) <= 1250)
			{
				SendChat_Message_Nearby(e, self, bubble_msg); // Chat 'bubble'
				SendChat_Message(e, msg); // Chat text box
			}
		}
		print (msg, "\n"); // print to server console
		return;
	}

	// handle the rest
	clientcommand(self, str);
};