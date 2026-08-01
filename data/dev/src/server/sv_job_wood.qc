//
// Trees and their stats concerning wood working
//

.string tree_id;

#define LUMBER_BASE_VALUE 5
#define LUMBER_LEVEL1_SKILL 15
#define LUMBER_LEVEL1_BONUS 7

void() CSEv_PlayerSellLumber =
{
    float i;
    float lumber_count = 0;
    float haggle_bonus;
    float wood_bonus;
    float soft_bonus;
    float price_per;
    float total_gold;

    // Find lumber stack
    for (i = 0; i < self.inv_count; i++)
    {
        if (self.inventory[i] == "Lumber")
        {
            lumber_count = self.inventory_count[i];
            break;
        }
    }

    if (lumber_count <= 0)
    {
        sprint(self, PRINT_HIGH, "You have no Lumber to sell.\n");
        return;
    }

    // Haggle bonus
    haggle_bonus = ceil(self.skill_haggle * 0.5);

    // --- Harsher woodcutting scaling ---
    wood_bonus = LUMBER_LEVEL1_BONUS * (self.skill_woodcutting / 
                  (self.skill_woodcutting + (LUMBER_LEVEL1_SKILL * 2.5)));

    // Very slow late-game drift
    soft_bonus = sqrt(self.skill_woodcutting) * 0.08;

    // Hard caps to prevent gold inflation
    if (wood_bonus > LUMBER_LEVEL1_BONUS)
        wood_bonus = LUMBER_LEVEL1_BONUS;

    if (soft_bonus > 2.0)
        soft_bonus = 2.0;

    price_per = LUMBER_BASE_VALUE
              + haggle_bonus
              + floor(wood_bonus + soft_bonus);

    total_gold = price_per * lumber_count;

    // Give gold and remove lumber
    self.gold += total_gold;
    RemoveFromInventory(self, "Lumber", lumber_count);

    // Output strings
    string s_count = ftos(lumber_count);
    string s_gold  = ftos(total_gold);
    string s_price = ftos(price_per);

    sprint(self, PRINT_HIGH, "Sold ", s_count, " Lumber for ^3", s_gold, "^7 gold.\n");

    string eventlog_print = strcat("Sold ", s_count, " Lumber ^2+^3", s_gold, "g");
    stuffcmd(self, sprintf("conecho event %s\n", eventlog_print));

    stuffcmd(self, sprintf("play %s\n", "menu/menu_buysell.wav"));

    SendPlayerInventory(self);
};

void() tree_lumberdrop_think =
{
	self.touch = Item_Touch;
	self.think = sub_remove; //  remove after 30 seconds
	self.nextthink = time + 30;
};

// Spawn lumber bundle scaled by tree level
void() tree_lumberdrop =
{
	entity lumber = spawn();
	lumber.owner = self;
	lumber.movetype = MOVETYPE_TOSS;
	lumber.solid = SOLID_TRIGGER;
	lumber.classname = "item";
	lumber.flags = FL_ITEM;
	lumber.netname = "Lumber";
	lumber.scale = 0.75;
	lumber.angles_y = random() * 360;
	lumber.modelflags = MF_ROTATE;

	// Scale drop amount by tree level
	if (self.level == 0) lumber.count = 1;
	else if (self.level == 1) lumber.count = 2;
	else if (self.level == 2) lumber.count = 3;
	else if (self.level == 3) lumber.count = 4;
	else if (self.level == 4) lumber.count = 5;
	else if (self.level >= 5) lumber.count = 6;

	setmodel(lumber, "models/lumberbundle.glb");
	setsize(lumber, '-16 -16 -0', '16 16 16');
	setorigin(lumber, self.origin);
	lumber.velocity_z = 270;

	vector throwrand = [0, self.angles_y + random()*360, 0];
	makevectors(throwrand);
	vector dir = normalize(v_forward);
	lumber.velocity = lumber.velocity + dir * random_range(50, 100);

	lumber.think = tree_lumberdrop_think;
	lumber.nextthink = time + 1;
};

void() tree_respawn =
{
	self.effects = 0;

    tracebox(self.origin, self.mins, self.maxs, self.origin, FALSE, self);
    if (trace_fraction < 1 || trace_startsolid || trace_allsolid)
    {
		float respawn_time = 10;  // retry in 10 seconds if blocked
        self.nextthink = time + respawn_time;
        self.think = tree_respawn;
        return;
    }

	self.alpha = 1;
	self.angles_x = 0; // reset angle
    self.solid = SOLID_SLIDEBOX;
    self.takedamage = DAMAGE_AIM;
    self.health = self.max_health;
	self.cnt = FALSE; // allow item spawn again

    setmodel(self, self.mdl);
	setsize(self, self.mins, self.maxs);
};

// Fade tree out on death
void() tree_remove =
{
	if (!self.cnt) // run once
	{
		pointparticles(PART_TREEFALL, self.origin);
		sound(self, CHAN_VOICE, "treefall.wav", 1, ATTN_NORM);

		tree_lumberdrop();
		self.cnt = TRUE;
	}

	if (self.angles_x > -90)
		self.angles_x -= 5;
	else
		self.angles_x = -90;

	if (self.alpha > 0.1)
		self.alpha -= 0.05;
	else
	{
		setmodel(self, __NULL__); // don't draw tree
		self.think = tree_respawn;
		float respawn_time = 120 + random() * 480;  // 120–600 seconds
		self.nextthink = time + respawn_time;
		return;
	}
	self.nextthink = time + 0.1;
};

//
// Hatchet durability + break logic
//
void() Hatchet_CheckBreak =
{
    float wear;
    float break_chance;

    wear = 0.2 + trace_ent.level * 0.1;
    wear *= (1.1 - (self.skill_woodcutting * 0.01));
    if (wear < 0.05) wear = 0.05;

    self.hatchet_durability -= wear;

    if (self.hatchet_durability <= 10)
    {
        break_chance = (10 - self.hatchet_durability) * 0.02;

        if (random() < break_chance)
        {
            stuffcmd(self, sprintf("play %s\n", "item/equip.wav")); // play sound
            sprint(self, PRINT_HIGH, "^1Your hatchet broke!\n");

			string eventlog_print = strcat("^1Your hatchet broke!\n");
			stuffcmd(self, sprintf("conecho event %s\n", eventlog_print));

			CSEv_User_UnequipMainhand_();			
            RemoveFromInventory(self, "Hatchet", 1);
            self.hatchet_durability = 0;
        }
    }
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

    // Swing sound
	sound(self, CHAN_WEAPON, "hatchet1.wav", 1, ATTN_NORM);

    if (trace_fraction == 1)
        return; // nothing hit

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

        // Do particle effect
		pointparticles(PART_TREEHIT, trace_endpos);
        trace_ent.health -= ceil(dmg);
        
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

		sound(trace_ent, CHAN_BODY, "hittree.wav", 1, ATTN_NORM);

        // Tree destroyed
        if (trace_ent.health <= 0)
        {
            trace_ent.solid = SOLID_NOT;
            trace_ent.takedamage = DAMAGE_NO;

			Quest_Event(self, "wood", strtolower(trace_ent.tree_id), 1);

            trace_ent.think = tree_remove;
            trace_ent.nextthink = time + 0.25;
        }
		Hatchet_CheckBreak();
    }
};

//
// misc_tree1 - regular tree
//

void() misc_tree =
{
	precache_model("models/tree.glb");
	precache_model("models/lumberbundle.glb");
	precache_sound("hittree.wav");
	precache_sound("treefall.wav");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;
	self.classname = "tree";
	self.takedamage = DAMAGE_AIM;
	self.max_health = 6 + floor(random() * 4); // 6 - 9 health
	self.health = self.max_health;
	self.alpha = 1;
	self.mdl = "models/tree.glb";
	self.level = 1;
	self.deadflag = DEAD_DEAD; // Prevent thorn and other spells from hitting me
	self.tree_id = "tree1";

	setmodel(self, "models/tree.glb");
	setsize(self, [-16, -16, 0], [16, 16, 100]);

	// terrain check
	self.origin_z += 64;
	setorigin(self, self.origin);
	droptofloor();
};

//
// misc_tree2 - dead tree
//

void() misc_tree2 =
{
	precache_model("models/tree2.glb");
	precache_model("models/lumberbundle.glb");
	precache_sound("hittree.wav");
	precache_sound("treefall.wav");

	self.solid = SOLID_SLIDEBOX;
	self.worldlight = TRUE;
	self.classname = "tree";
	self.takedamage = DAMAGE_AIM;
	self.max_health = 3 + floor(random() * 3); // 3 - 5 health
	self.health = self.max_health;
	self.alpha = 1;
	self.mdl = "models/tree2.glb";
	self.level = 0;
	self.deadflag = DEAD_DEAD; // Prevent thorn and other spells from hitting me
	self.tree_id = "tree2";
	
	setmodel(self, "models/tree2.glb");
	setsize(self, [-12, -12, 0], [12, 12, 100]);

	// terrain check
	self.origin_z += 64;
	setorigin(self, self.origin);
	droptofloor();
};