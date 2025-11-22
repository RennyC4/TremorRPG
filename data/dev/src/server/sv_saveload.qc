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

    // Preserve some data for map transfers
    if (type == 1) // map transfer
    {
        f = fopen(filename, FILE_READ);
        if (f >= 0)
        {
            fgets(f); // guid
            fgets(f); // loginname
            fgets(f); // gender
            old_music = fgets(f);
            fgets(f); // zonename
            for (i = 0; i < 6; i++)
                old_origin[i] = fgets(f);
            fclose(f);
        }
    }

    // Open file for writing
    f = fopen(filename, FILE_WRITE);
    if (f < 0) return;

    // --- BASIC STATS ---
    fputs(f, targ.guid, "\n");
    fputs(f, targ.loginname, "\n");
    fputs(f, targ.gender, "\n");

    // Preserve music from old file if it exists
    if (old_music != __NULL__)
        fputs(f, old_music, "\n");
    else
        fputs(f, targ.music, "\n");

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

    // --- SKILLS ---
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
    fputs(f, ftos(targ.skill_mining), "\n");
    fputs(f, ftos(targ.skill_fishing), "\n");
    fputs(f, ftos(targ.skill_woodcutting), "\n");

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

    // --- UPGRADES ---
    fputs(f, ftos(targ.gold_bank), "\n");
    fputs(f, ftos(targ.exp_oldnext), "\n");

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

    string line;
    string add_ext = strcat(LOGIN_NAME, ".chr");

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
    }

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

    // --- STEP 1: Read the file dynamically ---
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

    if (inv_count_line < 0) inv_count_line = 44;
    if (spell_count_line < 0) spell_count_line = 45;

    // --- STEP 2: Parse stats & skills ---
    self.netname = self.loginname = file_contents[1];
    self.gender = file_contents[2];
    self.music = file_contents[3];
    self.zonename = file_contents[4];

    if (!self.loggedin)
    {
        self.origin_x = stof(file_contents[5]);
        self.origin_y = stof(file_contents[6]);
        self.origin_z = stof(file_contents[7]);
        self.angles_x = stof(file_contents[8]);
        self.angles_y = stof(file_contents[9]);
        self.angles_z = stof(file_contents[10]);
    }

    self.health = stof(file_contents[11]);
    if (self.health < 0) self.health = 1;
    self.max_health = stof(file_contents[12]);
    self.mana = stof(file_contents[13]);
    self.max_mana = stof(file_contents[14]);
    self.level = stof(file_contents[15]);
    self.skillpoints = stof(file_contents[16]);
    self.exp = stof(file_contents[17]);
    self.exp_next = stof(file_contents[18]);
    self.gold = stof(file_contents[19]);
    self.attack_power_min = stof(file_contents[20]);
    self.attack_power_max = stof(file_contents[21]);
    self.attack_speed = stof(file_contents[22]);
    self.attack_type = stof(file_contents[23]);
    self.attack_stamina = stof(file_contents[24]);
    self.attack_length = stof(file_contents[25]);
    self.main_hand = file_contents[26];
    self.off_hand = file_contents[27];
    self.armorname = file_contents[28];
    self.armorvalue = stof(file_contents[29]);
    self.pvp = stof(file_contents[30]);
    self.pvpenable_count = stof(file_contents[31]);
    self.pvp_autoflagged = stof(file_contents[32]);
    self.blockvalue = stof(file_contents[33]);
    self.spell_equipped = file_contents[34];
    self.spell_power_min = stof(file_contents[35]);
    self.spell_power_max = stof(file_contents[36]);
    self.projectile_power_min = stof(file_contents[37]);
    self.projectile_power_max = stof(file_contents[38]);

    self.skill_unarmed = stof(file_contents[39]);
    self.skill_slash = stof(file_contents[40]);
    self.skill_pierce = stof(file_contents[41]);
    self.skill_bash = stof(file_contents[42]);
    self.skill_stealth = stof(file_contents[43]);
    self.skill_backstab = stof(file_contents[44]);
    self.skill_offensivemagic = stof(file_contents[45]);
    self.skill_defensivemagic = stof(file_contents[46]);
    self.skill_neutralmagic = stof(file_contents[47]);
    self.skill_endurance = stof(file_contents[48]);
    self.skill_spellresist = stof(file_contents[49]);
    self.skill_archery = stof(file_contents[50]);
    self.skill_healthregen = stof(file_contents[51]);
    self.skill_manaregen = stof(file_contents[52]);
    self.skill_haggle = stof(file_contents[53]);
    self.skill_climb = stof(file_contents[54]);
    self.skill_swim = stof(file_contents[55]);
    self.skill_acrobatic = stof(file_contents[56]);
    self.skill_mining = stof(file_contents[57]);
    self.skill_fishing = stof(file_contents[58]);
    self.skill_woodcutting = stof(file_contents[59]);

    // --- STEP 3: Load inventory & spells dynamically ---
    self.read_inv_count = stof(file_contents[inv_count_line]);
    self.spell_count = stof(file_contents[spell_count_line]);

    string what = "";
    float i;
    for (i = 0; i < self.read_inv_count; i++)
    {
        what = file_contents[inv_count_line + 1 + (i * 2)];
        AddToInventory(self, what, 0);
        AddToInventory(self, what, stof(file_contents[inv_count_line + 2 + (i * 2)]));
    }

    for (i = 0; i < self.spell_count; i++)
        self.spell[i] = file_contents[spell_count_line + 1 + i];

    // upgrades
    self.gold_bank = (spell_count_line + self.spell_count + 1 < total_lines) ? stof(file_contents[spell_count_line + self.spell_count + 1]) : 0;
    self.exp_oldnext = (spell_count_line + self.spell_count + 2 < total_lines) ? stof(file_contents[spell_count_line + self.spell_count + 2]) : self.exp_next;

    // finalize player
    setorigin(self, self.origin);
    self.fixangle = TRUE;
    self.displayname = self.loginname;
    self.stamina = 100;

    PlayerSpawn(1);

    sprint(self, PRINT_HIGH, strcat(self.loginname, " character resumed\n"));
};

// ============================================================
// SAVE INVENTORY ONLY (Safe & Dynamic)
// ============================================================
void(entity targ) SaveInventory =
{
    string filename = strcat(targ.loginname, ".chr");
    float f, b;
    float i;

    // --- STEP 1: Read old file ---
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
    if (spell_start < 0) spell_start = inv_start + 2; // safe fallback

    // --- STEP 2: Open file for writing ---
    b = fopen(filename, FILE_WRITE);
    if (b < 0) return;

    // --- STEP 3: Write all lines before inventory ---
    for (i = 0; i < inv_start; i++)
        fputs(b, file_contents[i], "\n");

    // --- STEP 4: Write inventory ---
    fputs(b, "#INVENTORY_START\n");
    fputs(b, ftos(targ.inv_count), "\n");
    for (i = 0; i < targ.inv_count; i++)
    {
        fputs(b, targ.inventory[i], "\n");
        fputs(b, ftos(targ.inventory_count[i]), "\n");
    }

    // --- STEP 5: Write spells ---
    fputs(b, "#SPELLS_START\n");
    fputs(b, ftos(targ.spell_count), "\n");
    for (i = 0; i < targ.spell_count; i++)
        fputs(b, targ.spell[i], "\n");

    // --- STEP 6: Write remaining lines after spells ---
    for (i = spell_start + 2; i < total_lines; i++) // skip old spell count + spells
    {
        if (strlen(file_contents[i]) > 0)
            fputs(b, file_contents[i], "\n");
    }

    fclose(b);
    sprint(targ, PRINT_HIGH, strcat(targ.loginname, " inventory saved\n"));
};