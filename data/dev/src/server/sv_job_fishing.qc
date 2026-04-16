//
// Fishing
//

.float fishing_node_idle_expire;
void() fishing_node_respawn;

//
// Fishing node CSQC
//

float(entity ePVEnt, float flChanged) FishingNode_SendEntity =
{
	WriteByte(MSG_ENTITY, ENT_FISHNODE);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	WriteCoord(MSG_ENTITY, self.angles_x);
	WriteCoord(MSG_ENTITY, self.angles_y);
	WriteCoord(MSG_ENTITY, self.angles_z);
	return TRUE;
};

//
// Fade fishing node out on being fished up OR idle despawn
//
void() fishing_node_remove =
{
	if (!self.cnt)
	{
		//sound(self, CHAN_BODY, "orebreak.wav", 1, ATTN_NORM);
		//pointparticles(PART_OREDIE, self.origin);
		//mining_oredrop();
		self.cnt = TRUE;
	}

	if (self.alpha > 0.1)
	{
		self.alpha -= 0.05;
		self.nextthink = time + 0.1;
		return;
	}

	float respawn_time = 120 + random() * 480;

	setmodel(self, __NULL__);
	self.think = fishing_node_respawn;
	self.nextthink = time + respawn_time;
};

//
// Idle despawn checker
//
void() fishing_node_idle_check =
{
	if (self.alpha < 1 || self.solid == SOLID_NOT)
		return;

	if (time >= self.fishing_node_idle_expire)
	{
//		self.ore_nodrop = TRUE; // prevent loot
		self.think = fishing_node_remove;
		self.nextthink = time + 0.1;
		return;
	}

	self.nextthink = time + 5;
};

//
// (Re)spawn fishing node
//
void() fishing_node_respawn =
{
	self.angles_y = random()*360;

	self.alpha = 1;
	self.health = self.max_health;
	self.cnt = FALSE;

	//idle despawn timer (3–8 minutes)
	self.fishing_node_idle_expire = time + (180 + random() * 300);

	setmodel(self, self.mdl);
	setsize(self, self.mins, self.maxs);

	// Start idle checking loop
	self.think = fishing_node_idle_check;
	self.nextthink = time + 5;
};

//
// misc_fishing_node
//

void() misc_fishing_node =
{
	self.SendEntity = FishingNode_SendEntity;
	self.SendFlags = 1;

	float respawn_time = 1 + random()*300;

	precache_model("models/fishschool.glb");

	self.classname = "fish_node";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	self.health = 0;
	self.max_health = 6 + floor(random() * 4);
	self.alpha = 0;
	if (!self.level)
		self.level = 0;
	self.angles_y = random()*360;
	self.mdl = "models/fishschool.glb";

	setsize(self, [-64, -64, -64], [64, 64, 64]);

	setorigin(self, self.origin);

	self.think = fishing_node_respawn;
	self.nextthink = time + 1;
	//self.nextthink = time + respawn_time;
};