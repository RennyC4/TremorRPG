//
//	Saveload.qc - Character saving & Loading functions
//

float(entity targ, string itemname, float count) AddToInventory;
void(float type) PlayerSpawn;

#define inventory_start 44
#define spells_start 45

// ============================================================
// SAVE CHARACTER (Corrected)
// ============================================================
void(entity targ, float type) CSEv_Player_SaveChar =
{
    if (!targ.loggedin)
        return;

    string filename = strcat(targ.loginname, ".chr");
    string old_music;
    string old_origin[6];
    float f, i;

    // --- Step 0: Preserve old file data for backward compatibility ---
    f = fopen(filename, FILE_READ);
    if (f >= 0)
    {
        string line;
        fgets(f); // guid
        fgets(f); // loginname
        fgets(f); // gender
        old_music = fgets(f);

        fgets(f); // zonename
        for (i = 0; i < 6; i++)
            old_origin[i] = fgets(f);

        fclose(f);
    }

    // --- Step 1: Open file for writing ---
    f = fopen(filename, FILE_WRITE);
    if (f < 0) return;

    // --- BASIC STATS ---
    fputs(f, targ.guid, "\n");
    fputs(f, targ.loginname, "\n");
    fputs(f, targ.gender, "\n");
    fputs(f, (old_music != __NULL__) ? old_music : targ.music, "\n");
    fputs(f, targ.zonename, "\n");

    // Origin + angles
    if (!type)
    {
        fputs(f, ftos(targ.origin_x), "\n");
        fputs(f, ftos(targ.origin_y), "\n");
        fputs(f, ftos(targ.origin_z), "\n");
        fputs(f, ftos(targ.angles_x), "\n");
        fputs(f, ftos(targ.angles_y), "\n");
        fputs(f, ftos(targ.angles_z), "\n");
    }
    else
    {
        for (i = 0; i < 6; i++)
            fputs(f, old_origin[i], "\n");
    }

    // --- STATS ---
    float stats[] = {
        targ.health, targ.max_health, targ.mana, targ.max_mana, targ.level,
        targ.skillpoints, targ.exp, targ.exp_next, targ.gold, targ.attack_power_min,
        targ.attack_power_max, targ.attack_speed, targ.attack_type, targ.attack_stamina,
        targ.attack_length
    };
    for (i = 0; i < 15; i++)
        fputs(f, ftos(stats[i]), "\n");

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

    // --- SKILLS ---
    float skills[] = {
        targ.skill_unarmed, targ.skill_slash, targ.skill_pierce, targ.skill_bash,
        targ.skill_stealth, targ.skill_backstab, targ.skill_offensivemagic, targ.skill_defensivemagic,
        targ.skill_neutralmagic, targ.skill_endurance, targ.skill_spellresist, targ.skill_archery,
        targ.skill_healthregen, targ.skill_manaregen, targ.skill_haggle, targ.skill_climb,
        targ.skill_swim, targ.skill_acrobatic, targ.skill_mining, targ.skill_fishing,
        targ.skill_woodcutting
    };
    for (i = 0; i < 21; i++)
        fputs(f, ftos(skills[i]), "\n");

    // --- INVENTORY ---
    fputs(f, "#INVENTORY_START\n");
    fputs(f, ftos(targ.inv_count), "\n");
    for (i = 0; i < targ.inv_count; i++)
    {
        fputs(f, targ.inventory[i], "\n");
        fputs(f, ftos(targ.inventory_count[i]), "\n");
    }

    // --- SPELLS ---
    fputs(f, "#SPELLS_START\n");
    fputs(f, ftos(targ.spell_count), "\n");
    for (i = 0; i < targ.spell_count; i++)
        fputs(f, targ.spell[i], "\n");

    // --- UPGRADES (always save current in-memory values) ---
    fputs(f, ftos(targ.gold_bank), "\n");
    fputs(f, ftos(targ.exp_oldnext), "\n");
    fputs(f, ftos(targ.hatchet_durability), "\n");
    fputs(f, ftos(targ.pick_durability), "\n");

    fclose(f);
    sprint(targ, PRINT_HIGH, strcat(targ.loginname, " character saved\n"));
};

// ============================================================
// RESUME/LOAD CHARACTER
// ============================================================
void(string LOGIN_NAME) CSEv_ResumeCharacter_s =
{
    if (cvar("developer") > 0)
        return;

    string add_ext = strcat(LOGIN_NAME, ".chr");
    string line;

    // --- Step 0: Check GUID ---
    float f = fopen(add_ext, FILE_READ);
    if (f >= 0)
    {
        self.guid = infokey(self, INFOKEY_P_GUID);
        if (line = fgets(f))
            if (line != "" && line != self.guid)
            {
                sprint(self, PRINT_HIGH, "Server GUID does not match clients\n");
                fclose(f);
                return;
            }
        fclose(f);
    }

    // --- Step 1: Prevent multiple logins ---
    if (cvar("sv_multilogin") == 0)
    {
        for (entity targ = world; (targ = find(targ, classname, "player")); )
        {
            if (targ != self && targ.guid == self.guid)
            {
                sprint(self, PRINT_HIGH, "You cannot run multiple instances of Tremor RPG on the same server\n");
                dropclient(self);
            }
        }
    }

    // --- Step 2: Read the entire file dynamically ---
    float v = fopen(add_ext, FILE_READ);
    if (v < 0)
    {
        sprint(self, PRINT_HIGH, "Character doesn't exist\n");
        return;
    }

    string file_contents[2048];
    float total_lines = 0;
    float inv_count_line = -1;
    float spell_count_line = -1;

    while ((line = fgets(v)))
    {
        file_contents[total_lines] = line;

        if (line == "#INVENTORY_START")
            inv_count_line = total_lines + 1;
        if (line == "#SPELLS_START")
            spell_count_line = total_lines + 1;

        total_lines++;
    }
    fclose(v);

    // --- Safe fallbacks for old files ---
    if (inv_count_line < 0) inv_count_line = total_lines;       // points to end of file
    if (spell_count_line < 0) spell_count_line = total_lines;   // points to end of file

    // --- Step 3: Parse stats & skills (fixed lines) ---
    self.netname = self.loginname = (total_lines > 1) ? file_contents[1] : LOGIN_NAME;
    self.gender = (total_lines > 2) ? file_contents[2] : "Male";
    self.music = (total_lines > 3) ? file_contents[3] : "";
    self.zonename = (total_lines > 4) ? file_contents[4] : "";

    if (!self.loggedin)
    {
        self.origin_x = (total_lines > 5) ? stof(file_contents[5]) : 0;
        self.origin_y = (total_lines > 6) ? stof(file_contents[6]) : 0;
        self.origin_z = (total_lines > 7) ? stof(file_contents[7]) : 0;
        self.angles_x = (total_lines > 8) ? stof(file_contents[8]) : 0;
        self.angles_y = (total_lines > 9) ? stof(file_contents[9]) : 0;
        self.angles_z = (total_lines > 10) ? stof(file_contents[10]) : 0;
    }

    self.health = (total_lines > 11) ? stof(file_contents[11]) : 100;
    if (self.health < 1) self.health = 1;
    self.max_health = (total_lines > 12) ? stof(file_contents[12]) : 100;
    self.mana = (total_lines > 13) ? stof(file_contents[13]) : 50;
    self.max_mana = (total_lines > 14) ? stof(file_contents[14]) : 50;
    self.level = (total_lines > 15) ? stof(file_contents[15]) : 1;
    self.skillpoints = (total_lines > 16) ? stof(file_contents[16]) : 0;
    self.exp = (total_lines > 17) ? stof(file_contents[17]) : 0;
    self.exp_next = (total_lines > 18) ? stof(file_contents[18]) : 100;
    self.gold = (total_lines > 19) ? stof(file_contents[19]) : 0;
    self.attack_power_min = (total_lines > 20) ? stof(file_contents[20]) : 1;
    self.attack_power_max = (total_lines > 21) ? stof(file_contents[21]) : 1;
    self.attack_speed = (total_lines > 22) ? stof(file_contents[22]) : 1;
    self.attack_type = (total_lines > 23) ? stof(file_contents[23]) : 0;
    self.attack_stamina = (total_lines > 24) ? stof(file_contents[24]) : 0;
    self.attack_length = (total_lines > 25) ? stof(file_contents[25]) : 1;
    self.main_hand = (total_lines > 26) ? file_contents[26] : "";
    self.off_hand = (total_lines > 27) ? file_contents[27] : "";
    self.armorname = (total_lines > 28) ? file_contents[28] : "";
    self.armorvalue = (total_lines > 29) ? stof(file_contents[29]) : 0;
    self.pvp = (total_lines > 30) ? stof(file_contents[30]) : 0;
    self.pvpenable_count = (total_lines > 31) ? stof(file_contents[31]) : 0;
    self.pvp_autoflagged = (total_lines > 32) ? stof(file_contents[32]) : 0;
    self.blockvalue = (total_lines > 33) ? stof(file_contents[33]) : 0;
    self.spell_equipped = (total_lines > 34) ? file_contents[34] : "";
    self.spell_power_min = (total_lines > 35) ? stof(file_contents[35]) : 0;
    self.spell_power_max = (total_lines > 36) ? stof(file_contents[36]) : 0;
    self.projectile_power_min = (total_lines > 37) ? stof(file_contents[37]) : 0;
    self.projectile_power_max = (total_lines > 38) ? stof(file_contents[38]) : 0;

    // skills (lines 39–59)
    self.skill_unarmed = (total_lines > 39) ? stof(file_contents[39]) : 0;
    self.skill_slash = (total_lines > 40) ? stof(file_contents[40]) : 0;
    self.skill_pierce = (total_lines > 41) ? stof(file_contents[41]) : 0;
    self.skill_bash = (total_lines > 42) ? stof(file_contents[42]) : 0;
    self.skill_stealth = (total_lines > 43) ? stof(file_contents[43]) : 0;
    self.skill_backstab = (total_lines > 44) ? stof(file_contents[44]) : 0;
    self.skill_offensivemagic = (total_lines > 45) ? stof(file_contents[45]) : 0;
    self.skill_defensivemagic = (total_lines > 46) ? stof(file_contents[46]) : 0;
    self.skill_neutralmagic = (total_lines > 47) ? stof(file_contents[47]) : 0;
    self.skill_endurance = (total_lines > 48) ? stof(file_contents[48]) : 0;
    self.skill_spellresist = (total_lines > 49) ? stof(file_contents[49]) : 0;
    self.skill_archery = (total_lines > 50) ? stof(file_contents[50]) : 0;
    self.skill_healthregen = (total_lines > 51) ? stof(file_contents[51]) : 0;
    self.skill_manaregen = (total_lines > 52) ? stof(file_contents[52]) : 0;
    self.skill_haggle = (total_lines > 53) ? stof(file_contents[53]) : 0;
    self.skill_climb = (total_lines > 54) ? stof(file_contents[54]) : 0;
    self.skill_swim = (total_lines > 55) ? stof(file_contents[55]) : 0;
    self.skill_acrobatic = (total_lines > 56) ? stof(file_contents[56]) : 0;
    self.skill_mining = (total_lines > 57) ? stof(file_contents[57]) : 0;
    self.skill_fishing = (total_lines > 58) ? stof(file_contents[58]) : 0;
    self.skill_woodcutting = (total_lines > 59) ? stof(file_contents[59]) : 0;

	// --- Step 4: Load inventory safely ---
	self.read_inv_count = (inv_count_line < total_lines) ? stof(file_contents[inv_count_line]) : 0;
	if (self.read_inv_count > 64) 
	{
		self.read_inv_count = 64; 
		sprint(self, PRINT_HIGH, "Inventory truncated to 64 items\n");
	}

	string what = "";
	float i;
	for (i = 0; i < self.read_inv_count && (inv_count_line + 1 + (i*2)) < total_lines && i < 64; i++)
	{
		what = file_contents[inv_count_line + 1 + (i * 2)];
		float qty = (inv_count_line + 2 + (i*2) < total_lines) ? stof(file_contents[inv_count_line + 2 + (i * 2)]) : 0;
		if (qty > 0)  // Only add real quantities
			AddToInventory(self, what, qty);
	}

	// --- Step 4b: Assign equipped items AFTER inventory is restored ---
	self.main_hand = (total_lines > 26) ? file_contents[26] : "";
	self.off_hand = (total_lines > 27) ? file_contents[27] : "";
	self.armorname = (total_lines > 28) ? file_contents[28] : "";
	self.armorvalue = (total_lines > 29) ? stof(file_contents[29]) : 0;
	self.pvp = (total_lines > 30) ? stof(file_contents[30]) : 0;
	self.pvpenable_count = (total_lines > 31) ? stof(file_contents[31]) : 0;
	self.pvp_autoflagged = (total_lines > 32) ? stof(file_contents[32]) : 0;
	self.blockvalue = (total_lines > 33) ? stof(file_contents[33]) : 0;
	self.spell_equipped = (total_lines > 34) ? file_contents[34] : "";
	self.spell_power_min = (total_lines > 35) ? stof(file_contents[35]) : 0;
	self.spell_power_max = (total_lines > 36) ? stof(file_contents[36]) : 0;
	self.projectile_power_min = (total_lines > 37) ? stof(file_contents[37]) : 0;
	self.projectile_power_max = (total_lines > 38) ? stof(file_contents[38]) : 0;

    // --- Step 5: Load spells safely ---
    self.spell_count = (spell_count_line < total_lines) ? stof(file_contents[spell_count_line]) : 0;
    if (self.spell_count > 64) { self.spell_count = 64; sprint(self, PRINT_HIGH, "Spell list truncated to 64 spells\n"); }

    for (i = 0; i < self.spell_count && (spell_count_line + 1 + i) < total_lines && i < 64; i++)
        self.spell[i] = file_contents[spell_count_line + 1 + i];

	// --- Step 6: Load upgrades safely ---
	float upgrades_start = spell_count_line + self.spell_count + 1;
	// Load gold bank, default to 0 if missing
	self.gold_bank = (upgrades_start < total_lines) ? stof(file_contents[upgrades_start]) : 0;
	// Load old next exp, default to self.exp_next if missing
	self.exp_oldnext = (upgrades_start + 1 < total_lines) ? stof(file_contents[upgrades_start + 1]) : self.exp_next;
	// Load hatchet durability, default to 100 if missing
	self.hatchet_durability = (upgrades_start + 2 < total_lines) ? stof(file_contents[upgrades_start + 2]) : 100;
	// Load hatchet durability, default to 100 if missing
	self.pick_durability = (upgrades_start + 3 < total_lines) ? stof(file_contents[upgrades_start + 3]) : 100;

    // --- Step 7: Finalize player ---
    setorigin(self, self.origin);
    self.fixangle = TRUE;
    self.displayname = self.loginname;
    self.stamina = 100;

    PlayerSpawn(1);

    sprint(self, PRINT_HIGH, strcat(self.loginname, " character resumed\n"));
};

// ===================
// SAVE INVENTORY ONLY + (backwards-compatible)
// ===================
void(entity targ) SaveInventory =
{
    string filename = strcat(targ.loginname, ".chr");
    float f, b;
    float i;

    f = fopen(filename, FILE_READ);
    if (f < 0) return;

    string file_contents[2048];
    float total_lines = 0;
    float inv_start = -1;
    float spell_start = -1;
    string line;

    while ((line = fgets(f)))
    {
        file_contents[total_lines] = line;
        if (line == "#INVENTORY_START") inv_start = total_lines;
        if (line == "#SPELLS_START") spell_start = total_lines;
        total_lines++;
    }
    fclose(f);

    if (inv_start < 0) inv_start = 0;
    if (spell_start < 0) spell_start = inv_start + 2;

    // Preserve upgrades
    float upgrades_start = spell_start + 1 + targ.spell_count;

    b = fopen(filename, FILE_WRITE);
    if (b < 0) return;

    // Write all lines before inventory
    for (i = 0; i < inv_start; i++)
        fputs(b, file_contents[i], "\n");

    // Write inventory
    fputs(b, "#INVENTORY_START\n");
    fputs(b, ftos(targ.inv_count), "\n");
    for (i = 0; i < targ.inv_count; i++)
    {
        fputs(b, targ.inventory[i], "\n");
        fputs(b, ftos(targ.inventory_count[i]), "\n");
    }

    // Write spells
    fputs(b, "#SPELLS_START\n");
    fputs(b, ftos(targ.spell_count), "\n");
    for (i = 0; i < targ.spell_count; i++)
        fputs(b, targ.spell[i], "\n");

    // Write upgrades (current in-memory values)
    fputs(b, ftos(targ.gold_bank), "\n");
    fputs(b, ftos(targ.exp_oldnext), "\n");
    fputs(b, ftos(targ.hatchet_durability), "\n");

    // Write remaining lines after upgrades (future-proof)
    for (i = upgrades_start + 3; i < total_lines; i++)
        if (strlen(file_contents[i]) > 0)
            fputs(b, file_contents[i], "\n");

    fclose(b);
};