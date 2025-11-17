//
//	Saveload.qc - Character saving & Loading functions
//


float(entity targ, string itemname, float count) AddToInventory;
void(float type) PlayerSpawn;

void(entity targ, float type) CSEv_Player_SaveChar =
{
    if (!targ.loggedin)
        return;

    string filename = strcat(targ.loginname, ".chr");

    // prepare to preserve some data (music, origin)
    string old_music;
    string old_origin[6];
    float f, i;

    if (type == 1) // map transfer
    {
        f = fopen(filename, FILE_READ);
        if (f >= 0)
        {
            // line 1: guid
            fgets(f);
            // line 2: loginname
            fgets(f);
            // line 3: gender
            fgets(f);
            // line 4: music
            old_music = fgets(f);
            // line 5: zonename
            fgets(f);

            // next 6 lines = origin + angles
            for (i = 0; i < 6; i++)
                old_origin[i] = fgets(f);

            fclose(f);
        }
    }

    // write new file
    f = fopen(filename, FILE_WRITE);
    if (f < 0)
        return;

    fputs(f, targ.guid, "\n");
    fputs(f, targ.loginname, "\n");
    fputs(f, targ.gender, "\n");

    // don't update music if world model ends with "bsp"
    if (substring(world.model, -3, 3) == "bsp" && old_music != __NULL__)
        fputs(f, old_music, "\n");
    else
        fputs(f, targ.music, "\n");

    fputs(f, targ.zonename, "\n");

    // write origin + angles
    if (!type) // normal save
    {
        fputs(f, ftos(targ.origin_x), "\n");
        fputs(f, ftos(targ.origin_y), "\n");
        fputs(f, ftos(targ.origin_z), "\n");
        fputs(f, ftos(targ.angles_x), "\n");
        fputs(f, ftos(targ.angles_y), "\n");
        fputs(f, ftos(targ.angles_z), "\n");
    }
    else // map transfer
    {
        for (i = 0; i < 6; i++)
            fputs(f, old_origin[i], "\n");
    }

    // --- rest of stats/skills/inventory ---
    fputs(f, ftos(targ.health), "\n");
    fputs(f, ftos(targ.max_health), "\n");
    fputs(f, ftos(targ.mana), "\n");
    fputs(f, ftos(targ.max_mana), "\n");
    fputs(f, ftos(targ.level), "\n");
    fputs(f, ftos(targ.skillpoints), "\n");
    fputs(f, ftos(targ.exp), "\n");
    fputs(f, ftos(targ.exp_next), "\n");
    fputs(f, ftos(targ.gold), "\n");
    fputs(f, ftos(targ.attack_power_min), "\n");
    fputs(f, ftos(targ.attack_power_max), "\n");
    fputs(f, ftos(targ.attack_speed), "\n");
    fputs(f, ftos(targ.attack_type), "\n");
    fputs(f, ftos(targ.attack_stamina), "\n");
    fputs(f, ftos(targ.attack_length), "\n");
    fputs(f, targ.main_hand, "\n");
    fputs(f, targ.off_hand, "\n");
    fputs(f, targ.armorname, "\n");
    fputs(f, ftos(targ.armorvalue), "\n");
    fputs(f, ftos(targ.pvp), "\n");
    fputs(f, ftos(targ.pvpenable_count), "\n");
    fputs(f, ftos(targ.pvp_autoflagged), "\n");
    fputs(f, ftos(targ.blockvalue), "\n");
    fputs(f, targ.spell_equipped, "\n");
    fputs(f, ftos(targ.spell_power_min), "\n");
    fputs(f, ftos(targ.spell_power_max), "\n");
    fputs(f, ftos(targ.projectile_power_min), "\n");
    fputs(f, ftos(targ.projectile_power_max), "\n");

    // skills
    fputs(f, ftos(targ.skill_unarmed), "\n");
    fputs(f, ftos(targ.skill_slash), "\n");
    fputs(f, ftos(targ.skill_pierce), "\n");
    fputs(f, ftos(targ.skill_bash), "\n");
    fputs(f, ftos(targ.skill_stealth), "\n");
    fputs(f, ftos(targ.skill_backstab), "\n");
    fputs(f, ftos(targ.skill_offensivemagic), "\n");
    fputs(f, ftos(targ.skill_defensivemagic), "\n");
    fputs(f, ftos(targ.skill_neutralmagic), "\n");
    fputs(f, ftos(targ.skill_endurance), "\n");
    fputs(f, ftos(targ.skill_spellresist), "\n");
    fputs(f, ftos(targ.skill_archery), "\n");
    fputs(f, ftos(targ.skill_healthregen), "\n");
    fputs(f, ftos(targ.skill_manaregen), "\n");
    fputs(f, ftos(targ.skill_haggle), "\n");
    fputs(f, ftos(targ.skill_climb), "\n");
    fputs(f, ftos(targ.skill_swim), "\n");
    fputs(f, ftos(targ.skill_acrobatic), "\n");

    // jobs
    fputs(f, ftos(targ.skill_mining), "\n");
    fputs(f, ftos(targ.skill_fishing), "\n");
    fputs(f, ftos(targ.skill_woodcutting), "\n");

    fputs(f, ftos(targ.inv_count), "\n");
    fputs(f, ftos(targ.spell_count), "\n");

    // inventory
    for (i = 0; i < targ.inv_count; i++)
    {
        fputs(f, targ.inventory[i], "\n");
        fputs(f, ftos(targ.inventory_count[i]), "\n");
    }

    // magic
    for (i = 0; i < targ.spell_count; i++)
        fputs(f, targ.spell[i], "\n");

	// .chr v1 upgrade
	fputs(f, ftos(targ.gold_bank), "\n");

	// .chr v2 upgrade
	fputs(f, ftos(targ.exp_oldnext), "\n");

    fclose(f); // close file

    sprint(targ, PRINT_HIGH, strcat(targ.loginname, " character saved\n"));
};

void(string LOGIN_NAME) CSEv_ResumeCharacter_s = 
{
	if (cvar("developer") > 0)
		return;

	string line;
	string add_ext = strcat(LOGIN_NAME, ".chr");

	// security check
	float f = fopen(add_ext, FILE_READ);
	if (f >= 0)
	{
		self.guid = infokey(self, INFOKEY_P_GUID);	
		if (line = fgets(f)) // grab guid from file
		if (line != "" && line != self.guid) // compare guid from file & user, server owner can wipe guid line if needed
		{
			sprint(self, PRINT_HIGH, "Server GUID does not match clients\n");
			return;
		}
	}

	if (cvar("sv_multilogin") == 0) // cheats allows multi-boxing
	{
		// check GUID against all other players on the server, if they match, kick new client
		for (entity targ = world;(targ = find(targ, classname, "player"));)
		{
			if (targ != self && targ.guid == self.guid)
			{
				sprint(self, PRINT_HIGH, "You cannot run multiple instances of Tremor RPG on the same server\n");
				dropclient(self);
			}
		}
	}

	// passed security check, grab stats from user server file
	float v = fopen(add_ext, FILE_READ);
	if (v >= 0)
	{
		// stats
		if (line = fgets(v)) {} // do not set GUID any longer
			//self.guid = line;
		if (line = fgets(v))
			self.netname = self.loginname = line;
		if (line = fgets(v))
			self.gender = line;
		if (line = fgets(v))
			self.music = line;
		if (line = fgets(v))
			self.zonename = line;

		if (!self.loggedin)
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
		}
		else // skip 6 lines, already logged in; map transition
		{
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
			if (line = fgets(v)) {}
		}

		if (line = fgets(v))
			self.health = stof(line);
		if (self.health < 0)
			self.health = 1;
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
		if (line = fgets(v))
			self.spell_equipped = line;
		if (line = fgets(v))
			self.spell_power_min = stof(line);
		if (line = fgets(v))
			self.spell_power_max = stof(line);
		if (line = fgets(v))
			self.projectile_power_min = stof(line);
		if (line = fgets(v))
			self.projectile_power_max = stof(line);
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

		//jobs
		if (line = fgets(v))
			self.skill_mining = stof(line);
		if (line = fgets(v))
			self.skill_fishing = stof(line);
		if (line = fgets(v))
			self.skill_woodcutting = stof(line);
		//
		
		if (line = fgets(v)) // inventory count
			self.read_inv_count = stof(line);

		if (line = fgets(v)) // spell count
			self.spell_count = stof(line);

		// load inventory
		float i;
		string what = "";
		for (i = 0; i < self.read_inv_count; i++)
		{
			if (line = fgets(v)) // add item
			{
				what = line;
				AddToInventory(self, what, 0);
			}
			if (line = fgets(v)) // add count to item
				AddToInventory(self, what, stof(line));
		}
		// load spells
		for (i = 0; i < self.spell_count; i++)
		{
			if (line = fgets(v)) // add spell(s)
				self.spell[i] = line;
		}
		
		// .chr v1 upgrade
		if (line = fgets(v))
			self.gold_bank = stof(line);
		else
			self.gold_bank = 0; // fallback for old characters

		// .chr v2 upgrade
		if (line = fgets(v))
			self.exp_oldnext = stof(line);
		else
			self.exp_oldnext = self.exp_next; // fallback for old characters

		fclose(v);

		setorigin (self, self.origin); // relink properly
		self.fixangle = TRUE;
		self.displayname = self.loginname;
		self.stamina = 100;
		
		PlayerSpawn(1); // Put player in game
	}
	else
	{
		sprint(self, PRINT_HIGH, "Character doesn't exist\n");
		return;
	}

	sprint(self, PRINT_HIGH, strcat(self.loginname, " character resumed\n"));
};
