//
// Experience / Leveling / Skill point systems
//

// =======================================
// Player Level-Up System
// =======================================
void(entity targ) Player_CheckLevelUp =
{
    // Loop to handle multiple levels if enough XP is gained
    while (targ.exp >= targ.exp_next)
    {
        targ.level += 1;
        targ.skillpoints += 15;
        targ.max_health += 12;
        targ.max_mana += 5;

        sound(targ, CHAN_AUTO, "levelup.wav", 1, ATTN_NORM);

        string eventlog_print = strcat("^3Level ", ftos(targ.level), " reached! +15 SP\n");
        stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));

        // Cap XP properly and calculate next level XP
		targ.exp = targ.exp_oldnext = targ.exp_next;
        targ.exp_next = ceil(100 * (targ.level * targ.level * 1.15));

        pointparticles(PART_LEVELUP, targ.origin);
    }
};

// =======================================
// Give Experience
// =======================================
void(entity targ, float expmin, float expmax) GiveExperience =
{
    float amount = ceil(random_range(expmin, expmax));

    exp_multiplier = cvar("sv_expmultiplier");
    if (exp_multiplier > 0)  // server-adjustable multiplier
        amount *= exp_multiplier;

    amount = ceil(amount);
    targ.exp += amount;

    string eventlog_print = strcat("^2", ftos(amount), "^7 exp received!\n");
    stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));

    // Check for level-ups after adding XP
    Player_CheckLevelUp(targ);
};

// =======================================
// Give Gold
// =======================================
void(entity targ, float goldmin, float goldmax) GiveGold =
{
    float amount = ceil(random_range(goldmin, goldmax));

    gold_multiplier = cvar("sv_goldmultiplier");
    if (gold_multiplier > 0)  // server-adjustable multiplier
        amount *= gold_multiplier;

    amount = ceil(amount);
    targ.gold += amount;

    string eventlog_print = strcat("^3", ftos(amount), "^7 gold received!\n");
    stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));
};

// ==================
// Assign Skill Point
// ==================
void(float which) CSEv_User_AddSkillPoint_f =
{
    if (self.skillpoints <= 0)
        return;

    // Skill names (for messages)
    string skill_name[18] =
    {
        "Unarmed", "Slash", "Pierce", "Bash", "Stealth", "Backstab",
        "Offensive Magic", "Defensive Magic", "Neutral Magic", "Endurance",
        "Spell Resist", "Archery", "Health Regen", "Mana Regen", "Haggle",
        "Climb", "Swim", "Acrobatics"
    };

    // Base cap per level
    float cap = (self.level * 10) + 10;

    // Maximum hard caps for certain skills (0 = no extra cap)
    float skill_hardcap[18] =
    {
        0, 0, 0, 0, 225, 0, 0, 0, 0, 400, 0, 0, 240, 240, 0, 300, 300, 300
    };

    // Pointer to the actual skill variable
    float current;
    switch (which)
    {
        case 0: current = self.skill_unarmed; break;
        case 1: current = self.skill_slash; break;
        case 2: current = self.skill_pierce; break;
        case 3: current = self.skill_bash; break;
        case 4: current = self.skill_stealth; break;
        case 5: current = self.skill_backstab; break;
        case 6: current = self.skill_offensivemagic; break;
        case 7: current = self.skill_defensivemagic; break;
        case 8: current = self.skill_neutralmagic; break;
        case 9: current = self.skill_endurance; break;
        case 10: current = self.skill_spellresist; break;
        case 11: current = self.skill_archery; break;
        case 12: current = self.skill_healthregen; break;
        case 13: current = self.skill_manaregen; break;
        case 14: current = self.skill_haggle; break;
        case 15: current = self.skill_climb; break;
        case 16: current = self.skill_swim; break;
        case 17: current = self.skill_acrobatic; break;
        default: print("error: skill doesn't exist\n"); return;
    }

    // Determine effective cap (base cap + hard cap if any)
    float effective_cap = cap;
    if (skill_hardcap[which] > 0 && skill_hardcap[which] < cap)
        effective_cap = skill_hardcap[which];
    else if (skill_hardcap[which] > 0)
        effective_cap = skill_hardcap[which];

    // Check if skill can be increased
    if (current >= effective_cap)
    {
        sprint(self, PRINT_HIGH, strcat(skill_name[which], " skill is maxed out\n"));
        return;
    }

    // Increment skill and reduce skill points
    current += 1;
    self.skillpoints -= 1;

    // Write back to the proper skill variable
    switch (which)
    {
        case 0: self.skill_unarmed = current; break;
        case 1: self.skill_slash = current; break;
        case 2: self.skill_pierce = current; break;
        case 3: self.skill_bash = current; break;
        case 4: self.skill_stealth = current; break;
        case 5: self.skill_backstab = current; break;
        case 6: self.skill_offensivemagic = current; break;
        case 7: self.skill_defensivemagic = current; break;
        case 8: self.skill_neutralmagic = current; break;
        case 9: self.skill_endurance = current; break;
        case 10: self.skill_spellresist = current; break;
        case 11: self.skill_archery = current; break;
        case 12: self.skill_healthregen = current; break;
        case 13: self.skill_manaregen = current; break;
        case 14: self.skill_haggle = current; break;
        case 15: self.skill_climb = current; break;
        case 16: self.skill_swim = current; break;
        case 17: self.skill_acrobatic = current; break;
    }
};