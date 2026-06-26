//
// Monsters: Most are defined in the maps themselves (hmp / bsp)
//
void(entity e) NPC_CommitState;
void() itemchest_think;
.float lootmode; // 0 = player item chest, 1 = monster loot chest

float(entity chest, string lootfile) Loot_FillChest =
{
    string line;
    string item;
    string chance_str;
    float fh;
    float sep;
    float chance;
    float dropped;

    dropped = 0;

    fh = fopen(strcat("ltb/", lootfile, ".ltb"), FILE_READ);

    if (fh < 0)
        return 0;

    while (1)
    {
        line = fgets(fh);
        if (!line)
            break;

        if (line == "")
            continue;

        sep = strstrofs(line, "%", 0);
        if (sep < 0)
            continue;

        item = substring(line, 0, sep);
        chance_str = substring(line, sep + 1, strlen(line));

        item = strtrim(item);
        chance = stof(strtrim(chance_str));

        if (random() <= chance)
        {
            entity it;

            it = spawn();
            it.classname = "chestloot";
            it.netname = item;
            it.owner = chest;

            dropped = 1;
        }
    }

    fclose(fh);
    return dropped;
};

void(string lootfile, vector pos) Spawn_LootChest =
{
    entity chest;
    float hasloot;

    // TEMP: build chest first (but don’t commit visually yet)
    chest = spawn();
    chest.owner = world;

    chest.movetype = MOVETYPE_TOSS;
    chest.solid = SOLID_TRIGGER;
    chest.classname = "item";

    setmodel(chest, "models/chest.glb");
    setsize(chest, '-16 -16 -0', '16 16 16');
    setorigin(chest, pos);

    chest.velocity_z = 270;
	chest.scale = 0.75;

    chest.lootmode = 1;
    chest.netname = lootfile;

    hasloot = Loot_FillChest(chest, lootfile);

    // IMPORTANT FIX
    if (!hasloot)
    {
        remove(chest);
        return;
    }
	sound(self, CHAN_AUTO, "item/drop.wav", 1, ATTN_NORM);

    chest.think = itemchest_think;
    chest.nextthink = time + 1;
};

void(float flIsNew) Monster_SendFlags =
{
    float flChanged = 0;

    if (flIsNew)
    {
        flChanged = ESF_ORIGIN | ESF_ANGLES | ESF_VELOCITY | ESF_FLAGS | ESF_EFFECTS |
                    ESF_HEALTH | ESF_MODEL | ESF_EQUIPMENT | ESF_ANIMATION | ESF_MISC;
    }
    else
    {
        if (self.origin != self.last_origin) flChanged |= ESF_ORIGIN;
        if (self.angles != self.last_angles) flChanged |= ESF_ANGLES;
        if (self.velocity != self.last_velocity) flChanged |= ESF_VELOCITY;
        if (self.flags != self.last_flags) flChanged |= ESF_FLAGS;
        if (self.effects != self.last_effects) flChanged |= ESF_EFFECTS;
        if (self.health != self.last_health || self.max_health != self.last_max_health) flChanged |= ESF_HEALTH;
        if (self.modelindex != self.last_modelindex) flChanged |= ESF_MODEL;
        if (self.main_hand != self.last_main_hand || self.off_hand != self.last_off_hand) flChanged |= ESF_EQUIPMENT;
        if (self.anistate != self.last_anistate || self.attack_speed != self.last_attack_speed) flChanged |= ESF_ANIMATION;
		if (self.alpha != self.last_alpha || self.displayname != self.last_displayname || self.speed != self.last_speed || self.level != self.last_level || self.ai_mode != self.last_ai_mode || self.movetype != self.last_movetype) flChanged |= ESF_MISC;
    }

    self.SendFlags = flChanged;
};

float(entity ePVEnt, float flChanged) Monster_SendEntity =
{
    WriteByte(MSG_ENTITY, ENT_MONSTER);
	WriteShort(MSG_ENTITY, flChanged);

    if (flChanged & ESF_ORIGIN)
    {
        WriteCoord(MSG_ENTITY, self.origin_x);
        WriteCoord(MSG_ENTITY, self.origin_y);
        WriteCoord(MSG_ENTITY, self.origin_z);
    }

    if (flChanged & ESF_ANGLES)
    {
        WriteCoord(MSG_ENTITY, self.angles_x);
        WriteCoord(MSG_ENTITY, self.angles_y);
        WriteCoord(MSG_ENTITY, self.angles_z);
    }

    if (flChanged & ESF_VELOCITY)
    {
        WriteCoord(MSG_ENTITY, self.velocity_x);
        WriteCoord(MSG_ENTITY, self.velocity_y);
        WriteCoord(MSG_ENTITY, self.velocity_z);
    }

    if (flChanged & ESF_FLAGS)
        WriteFloat(MSG_ENTITY, self.flags);

    if (flChanged & ESF_EFFECTS)
        WriteFloat(MSG_ENTITY, self.effects);

    if (flChanged & ESF_MODEL)
        WriteShort(MSG_ENTITY, self.modelindex);

    if (flChanged & ESF_HEALTH)
    {
        WriteShort(MSG_ENTITY, self.health);
        WriteShort(MSG_ENTITY, self.max_health);
    }

    if (flChanged & ESF_MISC)
    {
		WriteByte(MSG_ENTITY, self.alpha);
		WriteString(MSG_ENTITY, self.displayname);
		WriteByte(MSG_ENTITY, self.speed);
		WriteByte(MSG_ENTITY, self.level);
		WriteByte(MSG_ENTITY, self.ai_mode);
		WriteShort(MSG_ENTITY, self.movetype);
    }

    if (flChanged & ESF_EQUIPMENT)
    {
        WriteString(MSG_ENTITY, self.main_hand);
        WriteString(MSG_ENTITY, self.off_hand);
    }

    if (flChanged & ESF_ANIMATION)
    {
        WriteByte(MSG_ENTITY, self.anistate);
        WriteByte(MSG_ENTITY, self.attack_speed);
    }

    return TRUE;
};

void() monster_respawn =
{
	tracebox(self.saveorigin, self.mins, self.maxs, self.saveorigin, MOVE_NORMAL, self);

	// Blocked, wait a second
	if (trace_startsolid || trace_fraction < 1)
	{
		self.nextthink = time + 1;
		self.think = monster_respawn;
		return;
	}

	// Safe to respawn now
	setorigin(self, self.saveorigin);

	self.solid = SOLID_SLIDEBOX;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.health = self.max_health;
	self.radius_candamage = TRUE;
	self.ai_mode = AI_IDLE;

	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
	
	Monster_SendFlags(FALSE); // Send full delta snapshot
	NPC_CommitState(self);
};

void() set_monster =
{
	if (self.model)
		precache_model(self.model); // model
	if (self.noise)
		precache_sound(self.noise); // sight sound
	if (self.noise1)
		precache_sound(self.noise1); // attack sound
	if (self.noise2)
		precache_sound(self.noise2); // pain sound
	if (self.noise3)
		precache_sound(self.noise3); // death sound

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	if (!self.max_health)
		self.health = 1;
	else
		self.health = self.max_health;
	self.takedamage = DAMAGE_AIM;
	self.classname = "monster";
	self.radius_candamage = TRUE; // can be affected by radius damage
	self.flags |= FL_MONSTER;
	self.view_ofs = '0 0 48';
	self.th_die = monster_death;
	
	self.idealangles_y = random()*360;

	if (!self.sight_range)
		self.sight_range = 500;
	if (!self.exp)
		self.exp = 1;
	if (!self.noise)
		self.noise = "monsters/sight1.wav";
	if (!self.ai_move_dist)
		self.ai_move_dist = 2000;
	if (!self.attack_length)
		self.attack_length = 64;

	makevectors(self.angles);
	self.saveorigin = self.origin; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;
	
	movetofloor(self); 
	
	self.think = monster_ai_think;
	self.nextthink = time + 0.1 + random()*1; // stagger start think
	
	self.SendEntity = Monster_SendEntity;
	NPC_CommitState(self);
};