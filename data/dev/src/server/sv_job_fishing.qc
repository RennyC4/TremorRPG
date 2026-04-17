//
// Fishing
//

.float fishing_node_idle_expire;
void() fishing_node_respawn;

void() Fishing_ForceOff = // reset timer states cleanly
{	
	self.owner.melee_finished = time;
	self.owner.fishing_finished = time;
	self.owner.fishcast_finished = time;
	self.owner.lockview_finished = time;
	self.owner.anistate = ANISTATE_NONE;
};

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
// Fishing_Bobber_SearchNode - Searches for the actual fishing node and does its thing
//
void() Fishing_Bobber_SearchNode =
{
	sub_remove();
	
	// Run a radius search, interact with the node. Similar to how ore is mined.

	sprint (self.owner, PRINT_HIGH, "Fishing: Nothing WIP!\n"); // Debug message, can be removed

	string eventlog_print = (strcat("^4Fishing:^2 You caught something!"));
	stuffcmd (self.owner, sprintf("conecho event %s\n", eventlog_print));

	Fishing_ForceOff();
};

//
// DoJob_Fishing_Bobber - Fishing Rod 'attack button' action
//
void() DoJob_Fishing_Bobber =
{
    float water_check = pointcontents(self.origin);

    if (water_check == CONTENT_WATER)
    {
        if (!self.waterlevel) // just entered water
        {
            self.waterlevel = 1;

            // Stop falling
            self.movetype = MOVETYPE_FLY;
            self.velocity = '0 0 0';

            // Snap slightly upward so it sits 'near' surface
            self.origin_z += 16;
            setorigin(self, self.origin);

			self.owner.anistate = ANISTATE_FISHIDLE;
			self.owner.fishing_finished = time + 3; // add some randomness
			self.think = Fishing_Bobber_SearchNode;
			self.nextthink = time + 3;
			return;
        }
    }
	else
	{
		if (self.flags & FL_ONGROUND) // Bobber landed on ground, fail
		{
			string eventlog_print = (strcat("^4Fishing: ^1Failed!"));
			stuffcmd (self.owner, sprintf("conecho event %s\n", eventlog_print));

			self.owner.anistate = ANISTATE_NONE;
			Fishing_ForceOff();
			sub_remove();
		}
		else // extra check (weird geometry?)
		{
			self.cnt += 1;
			if (self.cnt > 49)
			{
				Fishing_ForceOff();
				self.cnt = 0;
				sub_remove();			
			}
		}
	}
	
    self.nextthink = time + 0.1;
};

//
// Fishing rod action
//
void() DoJob_Fishing =
{
	string eventlog_print = (strcat("^4Fishing:^2 Line cast ..."));
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));
	
	makevectors(self.angles);

	entity bobber = spawn();
	bobber.owner = self;
	bobber.movetype = MOVETYPE_TOSS;
	bobber.solid = SOLID_SLIDEBOX;
	bobber.classname = "bobber";
	bobber.scale = 0.5;
	bobber.hitcontentsmaski = CONTENTBIT_WATER | CONTENTBIT_SLIME | CONTENTBIT_LAVA | CONTENTBIT_SOLID;
	bobber.effects = EF_FULLBRIGHT;

	//bobber.modelflags = MF_ROTATE;

	setmodel(bobber, "models/fishingbobber.glb");
	setsize(bobber, '-16 -16 -0', '16 16 16');
	setorigin(bobber, self.origin + v_forward * 24 + v_up * 48);
	bobber.velocity_z = 400;

	vector dir = normalize(v_forward);
	bobber.velocity = bobber.velocity + dir * random_range(300, 600);

	bobber.think = DoJob_Fishing_Bobber;
	bobber.nextthink = time + 1;
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