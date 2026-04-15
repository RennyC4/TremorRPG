//
// Monsters: Most are defined in the maps themselves (hmp / bsp)
//

#define MSF_ORIGIN       1
#define MSF_ANGLES       2
#define MSF_VELOCITY     4
#define MSF_FLAGS        8
#define MSF_EFFECTS      16
#define MSF_HEALTH       32
#define MSF_MODEL        64
#define MSF_EQUIPMENT    128
#define MSF_ANIMATION    256
#define MSF_MISC         512

void(float flIsNew) Monster_SendFlags =
{
    float flChanged = 0;

    if (flIsNew)
    {
        flChanged = MSF_ORIGIN | MSF_ANGLES | MSF_VELOCITY | MSF_FLAGS | MSF_EFFECTS |
                    MSF_HEALTH | MSF_MODEL | MSF_EQUIPMENT | MSF_ANIMATION | MSF_MISC;
    }
    else
    {
        if (self.origin != self.last_origin) flChanged |= MSF_ORIGIN;
        if (self.angles != self.last_angles) flChanged |= MSF_ANGLES;
        if (self.velocity != self.last_velocity) flChanged |= MSF_VELOCITY;
        if (self.flags != self.last_flags) flChanged |= MSF_FLAGS;
        if (self.effects != self.last_effects) flChanged |= MSF_EFFECTS;
        if (self.health != self.last_health || self.max_health != self.last_max_health) flChanged |= MSF_HEALTH;
        if (self.modelindex != self.last_modelindex) flChanged |= MSF_MODEL;
        if (self.main_hand != self.last_main_hand || self.off_hand != self.last_off_hand) flChanged |= MSF_EQUIPMENT;
        if (self.anistate != self.last_anistate || self.attack_speed != self.last_attack_speed) flChanged |= MSF_ANIMATION;
    }

    self.SendFlags = flChanged;
};

void(entity e) Monster_CommitState =
{
    e.last_origin = e.origin;
    e.last_angles = e.angles;
    e.last_velocity = e.velocity;
    e.last_flags = e.flags;
    e.last_effects = e.effects;
    e.last_health = e.health;
    e.last_max_health = e.max_health;
    e.last_modelindex = e.modelindex;
    e.last_main_hand = e.main_hand;
    e.last_off_hand = e.off_hand;
    e.last_anistate = e.anistate;
    e.last_attack_speed = e.attack_speed;
};

float(entity ePVEnt, float flChanged) Monster_SendEntity =
{
    WriteByte(MSG_ENTITY, ENT_MONSTER);
	WriteShort(MSG_ENTITY, flChanged);

    if (flChanged & MSF_ORIGIN)
    {
        WriteCoord(MSG_ENTITY, self.origin_x);
        WriteCoord(MSG_ENTITY, self.origin_y);
        WriteCoord(MSG_ENTITY, self.origin_z);
    }

    if (flChanged & MSF_ANGLES)
    {
        WriteCoord(MSG_ENTITY, self.angles_x);
        WriteCoord(MSG_ENTITY, self.angles_y);
        WriteCoord(MSG_ENTITY, self.angles_z);
    }

    if (flChanged & MSF_VELOCITY)
    {
        WriteShort(MSG_ENTITY, self.velocity_x);
        WriteShort(MSG_ENTITY, self.velocity_y);
        WriteShort(MSG_ENTITY, self.velocity_z);
    }

    if (flChanged & MSF_FLAGS)
        WriteFloat(MSG_ENTITY, self.flags);

    if (flChanged & MSF_EFFECTS)
        WriteFloat(MSG_ENTITY, self.effects);

    if (flChanged & MSF_MODEL)
        WriteShort(MSG_ENTITY, self.modelindex);

    if (flChanged & MSF_HEALTH)
    {
        WriteShort(MSG_ENTITY, self.health);
        WriteShort(MSG_ENTITY, self.max_health);
    }

    if (flChanged & MSF_MISC)
    {
        WriteByte(MSG_ENTITY, self.alpha);
        WriteString(MSG_ENTITY, self.displayname);
        WriteByte(MSG_ENTITY, self.speed);
        WriteByte(MSG_ENTITY, self.level);
        WriteByte(MSG_ENTITY, self.ai_mode);
    }

    if (flChanged & MSF_EQUIPMENT)
    {
        WriteString(MSG_ENTITY, self.main_hand);
        WriteString(MSG_ENTITY, self.off_hand);
    }

    if (flChanged & MSF_ANIMATION)
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
	
	Monster_SendFlags(FALSE); // Send delta snapshot
};

void() monster_ai_spawnrunback =
{
	if (!self.ai_runback_temp)
	{
		self.ai_runback_temp = spawn();
		self.ai_runback_temp.owner = self;
		setmodel(self.ai_runback_temp, string_null);
		setorigin(self.ai_runback_temp, self.origin);
		setsize(self.ai_runback_temp, self.mins, self.maxs);
		movetofloor(self.ai_runback_temp);
	}
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
	monster_ai_spawnrunback();

	self.think = monster_ai_think;
	self.nextthink = time + 0.1 + random()*1; // stagger start think
	
	self.SendEntity = Monster_SendEntity;
	Monster_CommitState(self);
};