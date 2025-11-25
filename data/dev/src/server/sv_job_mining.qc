//
// Mining
//

void() mining_ore_think =
{
	self.touch = Item_Touch;
	self.think = sub_remove; //  remove after 30 seconds
	self.nextthink = time + 30;
};

// Spawn ore rock pickup
void() mining_oredrop =
{
	entity ore = spawn();
	ore.owner = self;
	ore.movetype = MOVETYPE_TOSS;
	ore.solid = SOLID_TRIGGER;
	ore.classname = "item";
	ore.flags = FL_ITEM;
	ore.scale = 0.25;
	ore.angles_y = random() * 360;
	ore.modelflags = MF_ROTATE;
	ore.count = 1;

	if (self.level == 0)
	{
		ore.netname = "Copper Ore";
	}

	setmodel(ore, self.mdl); // same model, just scaled down
	setsize(ore, '-16 -16 -0', '16 16 16');
	setorigin(ore, self.origin);
	ore.velocity_z = 270;

	vector throwrand = [0, self.angles_y + random()*360, 0];
	makevectors(throwrand);
	vector dir = normalize(v_forward);
	ore.velocity = ore.velocity + dir * random_range(50, 100);

	ore.think = mining_ore_think;
	ore.nextthink = time + 1;
};

void() ore_respawn =
{
	self.effects = 0;
	self.angles_y = random()*360;

    tracebox(self.origin, self.mins, self.maxs, self.origin, FALSE, self);
    if (trace_fraction < 1 || trace_startsolid || trace_allsolid)
    {
        self.nextthink = time + 5;
        self.think = ore_respawn;
        return;
    }

	self.alpha = 1;
    self.solid = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;
    self.health = self.max_health;
	self.cnt = FALSE; // allow item spawn again

    setmodel(self, self.mdl);
	setsize(self, self.mins, self.maxs);
};

// Fade ore out on death
void() ore_remove =
{
    self.solid = SOLID_NOT;
    self.takedamage = DAMAGE_NO;

	if (!self.cnt)
	{
		pointparticles(PART_OREDIE, self.origin);
		mining_oredrop();
		self.cnt = TRUE;
	}

    if (self.alpha > 0.1)
        self.alpha -= 0.05;
    else
    {
        float respawn_time = 60 + random() * 240;

        setmodel(self, __NULL__);
        self.think = ore_respawn;
        self.nextthink = time + respawn_time;
        return;
    }
    self.nextthink = time + 0.1;
};

//
// Pick durability + break logic
//

void() Pick_CheckBreak =
{
    float wear;
    float break_chance;

    wear = 0.2 + trace_ent.level * 0.1;
    wear *= (1.1 - (self.skill_mining * 0.01));
    if (wear < 0.05) wear = 0.05;

    self.pick_durability -= wear;

    if (self.pick_durability <= 10)
    {
        break_chance = (10 - self.pick_durability) * 0.02;

        if (random() < break_chance)
        {
            stuffcmd(self, sprintf("play %s\n", "item/equip.wav")); // play sound
            sprint(self, PRINT_HIGH, "^1Your mining pick broke!\n");

			string eventlog_print = strcat("^1Your mining pick broke!\n");
			stuffcmd(self, sprintf("conecho event %s\n", eventlog_print));

			CSEv_User_UnequipMainhand_();			
            RemoveFromInventory(self, "Mining Pick", 1);
            self.pick_durability = 0;
        }
    }
};

//
// Pick hitting mining ore
//

void() DoJob_Pick =
{
    vector source, end;
    float dmg = 1 + floor(self.skill_mining / 20); // scaling

    makevectors(self.v_angle);

    source = self.origin + self.view_ofs;
    end = source + v_forward * 64;  // pick reach

    traceline(source, end, FALSE, self);

    // Swing sound
	sound(self, CHAN_WEAPON, "miningpick1.wav", 1, ATTN_NORM);

    if (trace_fraction == 1)
        return; // nothing hit

    if (trace_ent.classname == "ore_copper")
    {
        float required = 0;
        float skill = self.skill_mining;

        if (trace_ent.level == 1) required = 15;
        if (trace_ent.level == 2) required = 40;
        if (trace_ent.level == 3) required = 80;
        if (trace_ent.level == 4) required = 150;
        if (trace_ent.level == 5) required = 250;

        if (skill < required)
        {
            centerprint(self, "You are not skilled enough to mine this ore.\n");
            return;
        }

        // Do particle effect
        pointparticles(PART_OREHIT, trace_endpos);
		trace_ent.health -= ceil(dmg);
        
        // --- XP gain ---
        float xp_chance;
        float skill_factor;
        float ore_factor;

        ore_factor = trace_ent.level + 1;    // level 0 gives some xp, but low
        skill_factor = (self.skill_mining / 20) + 1;

        xp_chance = ore_factor / skill_factor;

        if (xp_chance > 0.35) xp_chance = 0.35;  // max 35%
        if (xp_chance < 0.01) xp_chance = 0.01;  // min 1%

		if (random() < xp_chance)
		{
			self.skill_mining += 0.1;
			string f = sprintf("%.1f", self.skill_mining); // use self
			sprint(self, PRINT_HIGH, "Mining increased to ", f, "\n");
		}

		sound(trace_ent, CHAN_BODY, "hitore.wav", 1, ATTN_NORM);

        // Ore destroyed
        if (trace_ent.health <= 0)
        {
            trace_ent.solid = SOLID_NOT;
            trace_ent.takedamage = DAMAGE_NO;
        
            trace_ent.think = ore_remove;
            trace_ent.nextthink = time + 0.25;
        }
		Pick_CheckBreak();
    }
};

//
// misc_ore_copper
//

void() misc_ore_copper =
{
	float respawn_time = 1 + random()*300;

	precache_model("models/ore_copper.glb");
	precache_sound("hitore.wav");

	self.worldlight = TRUE;
	self.classname = "ore_copper";
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.health = 0;
	self.max_health = 6 + floor(random() * 4); // 6 - 9 health
	self.alpha = 0;
	self.level = 0;
	self.deadflag = DEAD_DEAD; // Prevent thorn and other spells from hitting me
	self.angles_y = random()*360;
	self.mdl = "models/ore_copper.glb";
	setsize(self, [-16, -16, 0], [16, 16, 48]);

	// terrain check
	self.origin_z += 64;
	setorigin(self, self.origin);
	droptofloor();

	self.think = ore_respawn;
	self.nextthink = time + respawn_time;
};