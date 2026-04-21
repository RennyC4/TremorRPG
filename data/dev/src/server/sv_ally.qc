//
// Allies: Most are defined in the maps themselves (hmp / bsp), allies are town guards etc and are special characters
//

void(float flIsNew) Ally_SendFlags =
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
	}

	self.SendFlags = flChanged;
};

float(entity ePVEnt, float flChanged) Ally_SendEntity =
{
    WriteByte(MSG_ENTITY, ENT_ALLY);
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

void() ally_respawn =
{
	self.solid = SOLID_SLIDEBOX;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.alpha = 1; // remove me when we have animations + proper model
	self.health = self.max_health;
	self.radius_candamage = TRUE;
	self.ai_mode = AI_IDLE; // return to idling

	setorigin (self, self.saveorigin); // respawn at initial spawn spot

	self.think = ally_ai_think;
	self.nextthink = time + 0.1;
};

void() set_ally =
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
	self.takedamage = DAMAGE_NO; // change later ...
	self.radius_candamage = FALSE; // cannot be affected by radius damage, change later ...
	self.classname = "ally";
	self.idealangles = self.angles;
	self.worldlight = TRUE;

	self.flags |= FL_ALLY;
	self.th_die = ally_death;

	if (!self.sight_range)
		self.sight_range = 500;
	if (!self.exp)
		self.exp = 1;
	if (!self.noise)
		self.noise = "monsters/sight1.wav";
	if (!self.ai_move_dist)
		self.ai_move_dist = 2000;

	self.saveorigin = self.origin + v_up * 5; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;
	self.frame = 1; // Animation will be done CSQC-side

	ally_ai_spawnrunback();

	self.think = ally_ai_think;
	self.nextthink = time + 0.1 + random()*1; // stagger start think

	self.SendEntity = Ally_SendEntity;
	NPC_CommitState(self);
};