//
// Trees and their stats concerning wood working
//

#define TREE_RESPAWN 60

void() tree_respawn =
{
	self.effects = 0;

    tracebox(self.origin, self.mins, self.maxs, self.origin, FALSE, self);
    if (trace_fraction < 1 || trace_startsolid || trace_allsolid)
    {
        self.nextthink = time + TREE_RESPAWN; // retry in 5 seconds
        self.think = tree_respawn;
        return;
    }

	self.alpha = 1;
    self.solid = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;
    self.health = self.max_health;

    setmodel(self, self.mdl);
	setsize(self, self.mins, self.maxs);
};

// Fade tree out on death
void() tree_remove =
{
	if (self.alpha > 0.1)
		self.alpha -= 0.05;
	else
	{
		setmodel(self, __NULL__); // don't draw tree
		self.think = tree_respawn;
		self.nextthink = time + TREE_RESPAWN;
		return;
	}
	self.nextthink = time + 0.1;
};

//
// Hatchet hitting tree code
//

void() DoJob_Hatchet =
{
    vector source, end;
    float dmg = 1 + floor(self.skill_woodcutting / 20); // scaling

    makevectors(self.v_angle);

    source = self.origin + self.view_ofs;
    end = source + v_forward * 64;  // hatchet reach

    traceline(source, end, FALSE, self);

    if (trace_fraction == 1)
        return; // nothing hit

    // Swing sound

    if (trace_ent.classname == "tree")
    {
        float required = 0;
        float skill = self.skill_woodcutting;

        if (trace_ent.level == 1) required = 15;
        if (trace_ent.level == 2) required = 40;
        if (trace_ent.level == 3) required = 80;
        if (trace_ent.level == 4) required = 150;
        if (trace_ent.level == 5) required = 250;

        if (skill < required)
        {
            centerprint(self, "You are not skilled enough to cut this tree.\n");
            return;
        }

        // Play sound
        // Do particle effect

        trace_ent.health -= ceil(dmg);
        sprint(self, PRINT_HIGH, "Hit a tree: Play sound\n");
        
        // --- XP gain ---
        float xp_chance;
        float skill_factor;
        float tree_factor;

        tree_factor = trace_ent.level + 1;    // level 0 gives some xp, but low
        skill_factor = (self.skill_woodcutting / 20) + 1;

        xp_chance = tree_factor / skill_factor;

        if (xp_chance > 0.35) xp_chance = 0.35;  // max 35%
        if (xp_chance < 0.01) xp_chance = 0.01;  // min 1%

		if (random() < xp_chance)
		{
			self.skill_woodcutting += 0.1;
			string f = sprintf("%.1f", self.skill_woodcutting); // use self.
			sprint(self, PRINT_HIGH, "Woodcutting increased to ", f, "\n");
		}

        // Tree destroyed
        if (trace_ent.health <= 0)
        {
            trace_ent.solid = SOLID_NOT;
            trace_ent.takedamage = DAMAGE_NO;
        
            trace_ent.think = tree_remove;
            trace_ent.nextthink = time;
        }
    }
};

//
// misc_tree1 - regular tree
//

void() misc_tree =
{
	precache_model("models/tree.glb");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;
	self.classname = "tree";
	self.takedamage = DAMAGE_AIM;
	self.max_health = 6 + floor(random() * 4); // 6 - 9 health
	self.health = self.max_health;
	self.alpha = 1;
	self.mdl = "models/tree.glb";
	self.level = 1;

	setmodel(self, "models/tree.glb");
	setsize(self, [-16, -16, 0], [16, 16, 100]);

	droptofloor();
};

//
// misc_tree2 - dead tree
//

void() misc_tree2 =
{
	precache_model("models/tree2.glb");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;
	self.classname = "tree";
	self.takedamage = DAMAGE_AIM;
	self.max_health = 3 + floor(random() * 3); // 3 - 5 health
	self.health = self.max_health;
	self.alpha = 1;
	self.mdl = "models/tree2.glb";
	self.level = 0;

	setmodel(self, "models/tree2.glb");
	setsize(self, [-12, -12, 0], [12, 12, 100]);

	droptofloor();
};