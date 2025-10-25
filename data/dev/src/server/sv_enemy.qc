//
// Monsters: Most are defined in the maps themselves (hmp / bsp)
//

float(entity ePVEnt, float flChanged) Monster_SendEntity =
{
	WriteByte(MSG_ENTITY, ENT_MONSTER); // Unique identifier
	WriteCoord(MSG_ENTITY, self.origin_x); // Position X
	WriteCoord(MSG_ENTITY, self.origin_y); // Position Y
	WriteCoord(MSG_ENTITY, self.origin_z); // Position Z
	WriteCoord(MSG_ENTITY, self.angles_x); // Angle X
	WriteCoord(MSG_ENTITY, self.angles_y); // Angle Y
	WriteCoord(MSG_ENTITY, self.angles_z); // Angle Z
	WriteShort(MSG_ENTITY, self.velocity_x); // Velocity X
	WriteShort(MSG_ENTITY, self.velocity_y); // Velocity X
	WriteShort(MSG_ENTITY, self.velocity_z); // Velocity X
	WriteFloat(MSG_ENTITY, self.flags); // Flags, important for physics
	WriteFloat(MSG_ENTITY, self.effects);
	WriteByte(MSG_ENTITY, self.alpha);
	WriteShort(MSG_ENTITY, self.modelindex);
	WriteShort(MSG_ENTITY, self.health);
	WriteShort(MSG_ENTITY, self.max_health);
	WriteString(MSG_ENTITY, self.displayname);
	WriteByte(MSG_ENTITY, self.speed);
	WriteString(MSG_ENTITY, self.main_hand);
	WriteString(MSG_ENTITY, self.off_hand);
	WriteByte(MSG_ENTITY, self.level);
	WriteByte(MSG_ENTITY, self.anistate);
	WriteByte(MSG_ENTITY, self.ai_mode);
	WriteByte(MSG_ENTITY, self.attack_speed);

	return TRUE;
};

void() monster_respawn =
{
	self.solid = SOLID_SLIDEBOX;
	self.deadflag = DEAD_NO;
	self.takedamage = DAMAGE_AIM;
	self.alpha = 1; // removeme when we have animations + proper model
	self.health = self.max_health;
	self.radius_candamage = TRUE;
	self.ai_mode = AI_IDLE; // return to idling

	setorigin (self, self.saveorigin); // respawn at initial spawn spot

	self.think = monster_ai_think;
	self.nextthink = time + 0.1;
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

	if (!self.sight_range)
		self.sight_range = 500;
	if (!self.exp)
		self.exp = 1;
	if (!self.noise)
		self.noise = "monsters/sight1.wav";
	if (!self.ai_move_dist)
		self.ai_move_dist = 2000;

	self.saveorigin = self.origin + v_up * 1; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;
	monster_ai_spawnrunback();

	self.think = monster_ai_think;
	self.nextthink = time + 0.1 + random()*1; // stagger start think
	
	self.SendEntity = Monster_SendEntity;
};