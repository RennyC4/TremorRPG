//
//	Saveload.qc - New Character Save System
//
//	Format:
//
//	KEY=VALUE
//
//	Example:
//
//	LEVEL=5
//	MAIN_HAND=Short Sword
//
//	Sections:
//
//	[CHARACTER]
//	[STATS]
//	[EQUIPMENT]
//	[SKILLS]
//	[INVENTORY]
//	[SPELLS]
//	[SECURITY]
//

float(entity targ, string itemname, float count) AddToInventory;
void(float type) PlayerSpawn;

// ============================================================
// PASSWORD
// ============================================================

string EncodePassword(string username, string password)
{
	string salt = strcat(username, ":TremorSalt_v1:");
	string hash = digest_hex("SHA2-256", salt, password);

	for (float i = 0; i < 1000; i++)
		hash = digest_hex("SHA2-256", salt, hash);

	return hash;
}

// ============================================================
// FILE WRITE HELPERS
// ============================================================

void(float f, string key, string value) SaveString =
{
	fputs(f, strcat(key, "=", value), "\n");
};

void(float f, string key, float value) SaveFloat =
{
	fputs(f, strcat(key, "=", ftos(value)), "\n");
};

void(float f, string section) SaveSection =
{
	fputs(f, strcat("\n[", section, "]"), "\n");
};

// ============================================================
// FILE PARSER
// ============================================================

string save_lines[4096];
float save_line_count;

// Load file into memory
float(string filename) LoadCharacterFile =
{
	float f;
	string line;

	save_line_count = 0;

	f = fopen(filename, FILE_READ);

	if (f < 0)
		return FALSE;

	while ((line = fgets(f)))
	{
		save_lines[save_line_count] = line;
		save_line_count++;

		if (save_line_count >= 4096)
			break;
	}

	fclose(f);
	return TRUE;
};

// ============================================================
// VALUE LOOKUP
// ============================================================

string(string key) ReadSaveString =
{
	float i;
	string prefix;

	prefix = strcat(key, "=");


	for (i = 0; i < save_line_count; i++)
	{
		if (substring(save_lines[i], 0, strlen(prefix)) == prefix)
			return substring(save_lines[i], strlen(prefix), 999);
	}


	return "";
};

float(string key, float default_value) ReadSaveFloat =
{
	string value;

	value = ReadSaveString(key);

	if (value == "")
		return default_value;

	return stof(value);
};

// ============================================================
// SECTION FINDING
// ============================================================

float(string section) FindSection =
{
	float i;
	string name;

	name = strcat("[", section, "]");

	for (i = 0; i < save_line_count; i++)
	{
		if (save_lines[i] == name)
			return i;
	}

	return -1;
};

// ============================================================
// PASSWORD CHECK
// ============================================================

string() ReadPassword =
{
	return ReadSaveString("PASSWORD");
};

// ============================================================
// SAVE CHARACTER
// ============================================================
void(entity targ, float type) CSEv_Player_SaveChar =
{
	if (!targ.loggedin)
		return;

	string filename;
	float f;
	float i;

	string old_origin_x;
	string old_origin_y;
	string old_origin_z;

	string old_angle_x;
	string old_angle_y;
	string old_angle_z;

	filename = strcat("chr/", targ.loginname, ".chr");

	// ========================================================
	// Preserve old position when type == 1
	// ========================================================

	if (type)
	{
		if (LoadCharacterFile(filename))
		{
			old_origin_x = ReadSaveString("ORIGIN_X");
			old_origin_y = ReadSaveString("ORIGIN_Y");
			old_origin_z = ReadSaveString("ORIGIN_Z");

			old_angle_x = ReadSaveString("ANGLE_X");
			old_angle_y = ReadSaveString("ANGLE_Y");
			old_angle_z = ReadSaveString("ANGLE_Z");
		}

		// Safety fallback for missing old saves

		if (old_origin_x == "")
			old_origin_x = ftos(targ.origin_x);

		if (old_origin_y == "")
			old_origin_y = ftos(targ.origin_y);

		if (old_origin_z == "")
			old_origin_z = ftos(targ.origin_z);


		if (old_angle_x == "")
			old_angle_x = ftos(targ.angles_x);

		if (old_angle_y == "")
			old_angle_y = ftos(targ.angles_y);

		if (old_angle_z == "")
			old_angle_z = ftos(targ.angles_z);
	}

	f = fopen(filename, FILE_WRITE);
	if (f < 0)
		return;

	// ========================================================
	// CHARACTER
	// ========================================================

	SaveSection(f, "CHARACTER");

	SaveString(f, "GUID", targ.guid);
	SaveString(f, "LOGINNAME", targ.loginname);
	SaveString(f, "GENDER", targ.gender);

	SaveFloat(f, "MUSIC", targ.music);
	SaveString(f, "ZONE", targ.zonename);

	// ========================================================
	// POSITION
	// ========================================================

	if (!type)
	{
		SaveFloat(f, "ORIGIN_X", targ.origin_x);
		SaveFloat(f, "ORIGIN_Y", targ.origin_y);
		SaveFloat(f, "ORIGIN_Z", targ.origin_z);

		SaveFloat(f, "ANGLE_X", targ.angles_x);
		SaveFloat(f, "ANGLE_Y", targ.angles_y);
		SaveFloat(f, "ANGLE_Z", targ.angles_z);
	}
	else
	{
		SaveString(f, "ORIGIN_X", old_origin_x);
		SaveString(f, "ORIGIN_Y", old_origin_y);
		SaveString(f, "ORIGIN_Z", old_origin_z);

		SaveString(f, "ANGLE_X", old_angle_x);
		SaveString(f, "ANGLE_Y", old_angle_y);
		SaveString(f, "ANGLE_Z", old_angle_z);
	}

	// ========================================================
	// STATS
	// ========================================================

	SaveSection(f, "STATS");

	SaveFloat(f, "HEALTH", targ.health);
	SaveFloat(f, "MAX_HEALTH", targ.max_health);

	SaveFloat(f, "MANA", targ.mana);
	SaveFloat(f, "MAX_MANA", targ.max_mana);

	SaveFloat(f, "LEVEL", targ.level);
	SaveFloat(f, "SKILLPOINTS", targ.skillpoints);

	SaveFloat(f, "EXP", targ.exp);
	SaveFloat(f, "EXP_NEXT", targ.exp_next);
	SaveFloat(f, "EXP_OLDNEXT", targ.exp_oldnext);

	SaveFloat(f, "GOLD", targ.gold);
	SaveFloat(f, "BANK_GOLD", targ.gold_bank);


	SaveFloat(f, "ATTACK_POWER_MIN", targ.attack_power_min);
	SaveFloat(f, "ATTACK_POWER_MAX", targ.attack_power_max);
	SaveFloat(f, "ATTACK_SPEED", targ.attack_speed);
	SaveFloat(f, "ATTACK_TYPE", targ.attack_type);
	SaveFloat(f, "ATTACK_STAMINA", targ.attack_stamina);
	SaveFloat(f, "ATTACK_LENGTH", targ.attack_length);

	SaveFloat(f, "BLOCK_VALUE", targ.blockvalue);


	SaveFloat(f, "PVP", targ.pvp);
	SaveFloat(f, "PVP_ENABLE_COUNT", targ.pvpenable_count);
	SaveFloat(f, "PVP_AUTOFLAGGED", targ.pvp_autoflagged);


	SaveString(f, "SPELL_EQUIPPED", targ.spell_equipped);

	SaveFloat(f, "SPELL_POWER_MIN", targ.spell_power_min);
	SaveFloat(f, "SPELL_POWER_MAX", targ.spell_power_max);

	SaveFloat(f, "PROJECTILE_POWER_MIN", targ.projectile_power_min);
	SaveFloat(f, "PROJECTILE_POWER_MAX", targ.projectile_power_max);

	// ========================================================
	// EQUIPMENT
	// ========================================================

	SaveSection(f, "EQUIPMENT");

	SaveString(f, "MAIN_HAND", targ.main_hand);
	SaveString(f, "OFF_HAND", targ.off_hand);

	SaveString(f, "ARMOR", targ.armorname);
	SaveFloat(f, "ARMOR_VALUE", targ.armorvalue);

	SaveString(f, "HELMET", targ.helmetname);
	SaveFloat(f, "HELMET_VALUE", targ.helmetvalue);

	// future-proof slots
	// NOTE: I'll add this later

	/*
	SaveString(f, "BOOTS", targ.boots);
	SaveString(f, "GLOVES", targ.gloves);

	SaveString(f, "RING1", targ.ring1);
	SaveString(f, "RING2", targ.ring2);

	SaveString(f, "AMULET", targ.amulet);
	*/

	// ========================================================
	// TOOLS
	// ========================================================

	SaveSection(f, "TOOLS");

	SaveFloat(f, "HATCHET_DURABILITY", targ.hatchet_durability);
	SaveFloat(f, "PICK_DURABILITY", targ.pick_durability);

	// ========================================================
	// SKILLS
	// ========================================================

	SaveSection(f, "SKILLS");

	SaveFloat(f, "UNARMED", targ.skill_unarmed);
	SaveFloat(f, "SLASH", targ.skill_slash);
	SaveFloat(f, "PIERCE", targ.skill_pierce);
	SaveFloat(f, "BASH", targ.skill_bash);

	SaveFloat(f, "STEALTH", targ.skill_stealth);
	SaveFloat(f, "BACKSTAB", targ.skill_backstab);

	SaveFloat(f, "OFFENSIVE_MAGIC", targ.skill_offensivemagic);
	SaveFloat(f, "DEFENSIVE_MAGIC", targ.skill_defensivemagic);
	SaveFloat(f, "NEUTRAL_MAGIC", targ.skill_neutralmagic);

	SaveFloat(f, "ENDURANCE", targ.skill_endurance);
	SaveFloat(f, "SPELL_RESIST", targ.skill_spellresist);

	SaveFloat(f, "ARCHERY", targ.skill_archery);

	SaveFloat(f, "HEALTH_REGEN", targ.skill_healthregen);
	SaveFloat(f, "MANA_REGEN", targ.skill_manaregen);

	SaveFloat(f, "HAGGLE", targ.skill_haggle);

	SaveFloat(f, "CLIMB", targ.skill_climb);
	SaveFloat(f, "SWIM", targ.skill_swim);
	SaveFloat(f, "ACROBATIC", targ.skill_acrobatic);

	SaveFloat(f, "MINING", targ.skill_mining);
	SaveFloat(f, "FISHING", targ.skill_fishing);
	SaveFloat(f, "WOODCUTTING", targ.skill_woodcutting);

	// ========================================================
	// INVENTORY
	// ========================================================

	dprint(strcat("MAX INVENTORY = ", ftos(MAX_INVENTORY), "\n"));
	dprint(strcat("INV COUNT = ", ftos(targ.inv_count), "\n"));
	
	SaveSection(f, "INVENTORY");

	for (i = 0; i < targ.inv_count; i++)
	{
		if (targ.inventory[i] != "")
		{
			fputs(f,strcat(targ.inventory[i], "=", ftos(targ.inventory_count[i])), "\n");
		}
	}

	// ========================================================
	// SPELLS
	// ========================================================
	SaveSection(f, "SPELLS");

	for (i = 0; i < targ.spell_count; i++)
	{
		if (targ.spell[i] != "")
			fputs(f, targ.spell[i], "\n");
	}

	// ========================================================
	// SECURITY
	// ========================================================

	SaveSection(f, "SECURITY");

	if (targ.password != "" && targ.password != __NULL__)
	{
		SaveString(f, "PASSWORD", EncodePassword(targ.loginname, targ.password));
	}

	fclose(f);

	sprint(targ, PRINT_HIGH, strcat(targ.loginname, " character saved\n"));
};

// ============================================================
// LOAD CHARACTER
// ============================================================

void(string LOGIN_NAME, string LOGIN_PASSWORD) CSEv_ResumeCharacter_ss =
{
	if (cvar("developer") > 0)
		return;

	float i;

	string filename;
	string file_password;
	string encoded_password;

	filename = strcat("chr/", LOGIN_NAME, ".chr");

	// ========================================================
	// LOAD FILE
	// ========================================================

	if (!LoadCharacterFile(filename))
	{
		sprint(self, PRINT_HIGH, "Character doesn't exist\n");
		return;
	}

	// ========================================================
	// GUID CHECK
	// ========================================================

	string file_guid;
	file_guid = ReadSaveString("GUID");

	self.guid = infokey(self, INFOKEY_P_GUID);

	if (cvar("sv_multilogin") == 0)
	{
		entity targ;

		for (targ = world; (targ = find(targ, classname, "player")); )
		{
			if (targ != self && targ.guid == self.guid)
			{
				sprint(self, PRINT_HIGH, "You cannot run multiple instances of Tremor RPG on the same server\n");
				dropclient(self);
				return;
			}
		}
	}

	// ========================================================
	// PASSWORD
	// ========================================================

	file_password = ReadSaveString("PASSWORD");

	if (file_password != "")
	{
		encoded_password = EncodePassword(LOGIN_NAME, LOGIN_PASSWORD);

		if (encoded_password == file_password)
		{
			self.password = LOGIN_PASSWORD;
		}
		else
		{
			sprint(self, PRINT_HIGH, "^1Incorrect password\n");
			return;
		}
	}
	else
	{
		if (LOGIN_PASSWORD == "")
		{
			sprint(self, PRINT_HIGH, "^1Password required\n");
			return;
		}
		self.password = LOGIN_PASSWORD;
	}

	// ========================================================
	// CHARACTER
	// ========================================================

	self.netname = self.loginname = ReadSaveString("LOGINNAME");
	self.gender = ReadSaveString("GENDER");
	self.music = ReadSaveFloat("MUSIC",0);
	self.zonename = ReadSaveString("ZONE");

	if (!self.loggedin)
	{
		self.origin_x =
			ReadSaveFloat("ORIGIN_X",0);

		self.origin_y =
			ReadSaveFloat("ORIGIN_Y",0);

		self.origin_z =
			ReadSaveFloat("ORIGIN_Z",0);


		self.angles_x =
			ReadSaveFloat("ANGLE_X",0);

		self.angles_y =
			ReadSaveFloat("ANGLE_Y",0);

		self.angles_z =
			ReadSaveFloat("ANGLE_Z",0);
	}

	// ========================================================
	// STATS
	// ========================================================

	self.health =
		ReadSaveFloat("HEALTH",100);

	if (self.health < 1)
		self.health = 1;

	self.max_health =
		ReadSaveFloat("MAX_HEALTH",100);

	self.mana =
		ReadSaveFloat("MANA",50);

	self.max_mana =
		ReadSaveFloat("MAX_MANA",50);

	self.level =
		ReadSaveFloat("LEVEL",1);

	self.skillpoints =
		ReadSaveFloat("SKILLPOINTS",0);

	self.exp =
		ReadSaveFloat("EXP",0);

	self.exp_next =
		ReadSaveFloat("EXP_NEXT",100);

	self.exp_oldnext =
		ReadSaveFloat("EXP_OLDNEXT", self.exp_next);

	self.gold =
		ReadSaveFloat("GOLD",0);

	self.gold_bank =
		ReadSaveFloat("BANK_GOLD",0);

	// Combat
	self.attack_power_min =
		ReadSaveFloat("ATTACK_POWER_MIN",1);

	self.attack_power_max =
		ReadSaveFloat("ATTACK_POWER_MAX",1);

	self.attack_speed =
		ReadSaveFloat("ATTACK_SPEED",1);

	self.attack_type =
		ReadSaveFloat("ATTACK_TYPE",0);

	self.attack_stamina =
		ReadSaveFloat("ATTACK_STAMINA",0);

	self.attack_length =
		ReadSaveFloat("ATTACK_LENGTH",1);

	self.blockvalue =
		ReadSaveFloat("BLOCK_VALUE",0);

	// PVP
	self.pvp =
		ReadSaveFloat("PVP",0);

	self.pvpenable_count =
		ReadSaveFloat("PVP_ENABLE_COUNT",0);

	self.pvp_autoflagged =
		ReadSaveFloat("PVP_AUTOFLAGGED",0);

	// Magic
	self.spell_equipped =
		ReadSaveString("SPELL_EQUIPPED");

	self.spell_power_min =
		ReadSaveFloat("SPELL_POWER_MIN",0);

	self.spell_power_max =
		ReadSaveFloat("SPELL_POWER_MAX",0);


	self.projectile_power_min =
		ReadSaveFloat("PROJECTILE_POWER_MIN",0);

	self.projectile_power_max =
		ReadSaveFloat("PROJECTILE_POWER_MAX",0);

	// ========================================================
	// EQUIPMENT
	// ========================================================

	self.main_hand =
		ReadSaveString("MAIN_HAND");

	self.off_hand =
		ReadSaveString("OFF_HAND");

	self.armorname =
		ReadSaveString("ARMOR");

	self.armorvalue =
		ReadSaveFloat("ARMOR_VALUE",0);

	self.helmetname =
		ReadSaveString("HELMET");

	self.helmetvalue =
		ReadSaveFloat("HELMET_VALUE",0);

	// Future slots
	/*
	self.boots =
		ReadSaveString("BOOTS");

	self.gloves =
		ReadSaveString("GLOVES");

	self.ring1 =
		ReadSaveString("RING1");

	self.ring2 =
		ReadSaveString("RING2");

	self.amulet =
		ReadSaveString("AMULET");
	*/

	// Tools
	self.hatchet_durability =
		ReadSaveFloat("HATCHET_DURABILITY",100);

	self.pick_durability =
		ReadSaveFloat("PICK_DURABILITY",100);

	// ========================================================
	// SKILLS
	// ========================================================

	self.skill_unarmed =
		ReadSaveFloat("UNARMED",0);

	self.skill_slash =
		ReadSaveFloat("SLASH",0);

	self.skill_pierce =
		ReadSaveFloat("PIERCE",0);

	self.skill_bash =
		ReadSaveFloat("BASH",0);

	self.skill_stealth =
		ReadSaveFloat("STEALTH",0);

	self.skill_backstab =
		ReadSaveFloat("BACKSTAB",0);

	self.skill_offensivemagic =
		ReadSaveFloat("OFFENSIVE_MAGIC",0);

	self.skill_defensivemagic =
		ReadSaveFloat("DEFENSIVE_MAGIC",0);

	self.skill_neutralmagic =
		ReadSaveFloat("NEUTRAL_MAGIC",0);

	self.skill_endurance =
		ReadSaveFloat("ENDURANCE",0);

	self.skill_spellresist =
		ReadSaveFloat("SPELL_RESIST",0);

	self.skill_archery =
		ReadSaveFloat("ARCHERY",0);

	self.skill_healthregen =
		ReadSaveFloat("HEALTH_REGEN",0);

	self.skill_manaregen =
		ReadSaveFloat("MANA_REGEN",0);

	self.skill_haggle =
		ReadSaveFloat("HAGGLE",0);

	self.skill_climb =
		ReadSaveFloat("CLIMB",0);

	self.skill_swim =
		ReadSaveFloat("SWIM",0);

	self.skill_acrobatic =
		ReadSaveFloat("ACROBATIC",0);

	self.skill_mining =
		ReadSaveFloat("MINING",0);

	self.skill_fishing =
		ReadSaveFloat("FISHING",0);

	self.skill_woodcutting =
		ReadSaveFloat("WOODCUTTING",0);

	// ========================================================
	// INVENTORY
	// ========================================================

	self.inv_count = 0;
	for (float i = 0; i < MAX_INVENTORY; i++)
	{
		self.inventory[i] = "";
		self.inventory_count[i] = 0;
	}

	float start;
	string item;
	float qty;

	start = FindSection("INVENTORY");

	if (start >= 0)
	{
		for (i = start + 1; i < save_line_count; i++)
		{
			if (save_lines[i] == "[SPELLS]")
				break;

			if (save_lines[i] == "")
				continue;

			float split;

			split = strstrofs(save_lines[i], "=", 0);

			if (split < 0)
				continue;

			item = substring(save_lines[i], 0, split);

			qty = stof(substring(save_lines[i], split + 1, 999));

			AddToInventory(self, item, qty);
		}
	}

	// ========================================================
	// SPELLS
	// ========================================================

	self.spell_count = 0;
	start = FindSection("SPELLS");

	if (start >= 0)
	{
		for (i = start + 1; i < save_line_count; i++)
		{
			if (save_lines[i] == "")
				continue;

			if (save_lines[i][0] == '[')
				break;

			if (self.spell_count >= 64)
				break;

			self.spell[self.spell_count] =
				save_lines[i];

			self.spell_count++;
		}
	}

	// ========================================================
	// FINALIZE
	// ========================================================

	setorigin(self,self.origin);
	self.fixangle = TRUE;
	self.displayname = self.loginname;
	self.stamina = 100;

	PlayerSpawn(1);

	sprint(self, PRINT_HIGH, strcat(self.loginname, " character resumed\n"));
};

// ============================================================
// SAVE INVENTORY ONLY
// ============================================================

void(entity targ) SaveInventory =
{
	string filename;
	float f;
	float i;
	float inventory_section;
	float next_section;

	filename = strcat("chr/", targ.loginname, ".chr");

	if (!LoadCharacterFile(filename))
		return;

	inventory_section = FindSection("INVENTORY");

	if (inventory_section < 0)
		return;

	// Find next section after inventory
	next_section = save_line_count;

	for (i = inventory_section + 1; i < save_line_count; i++)
	{
		if (substring(save_lines[i],0,1) == "[")
		{
			next_section = i;
			break;
		}
	}

	f = fopen(filename, FILE_WRITE);
	if (f < 0)
		return;

	// ========================================================
	// Write everything before inventory
	// ========================================================

	for (i = 0; i < inventory_section; i++)
	{
		fputs(f, save_lines[i], "\n");
	}

	// ========================================================
	// Write inventory
	// ========================================================

	fputs(f, "[INVENTORY]\n");

	for (i = 0; i < targ.inv_count; i++)
	{
		if (targ.inventory[i] != "")
		{
			fputs(f, strcat(targ.inventory[i], "=", ftos(targ.inventory_count[i])), "\n");
		}
	}

	// ========================================================
	// Restore everything after inventory
	// ========================================================

	for (i = next_section; i < save_line_count; i++)
	{
		fputs(f, save_lines[i], "\n");
	}

	fclose(f);
};