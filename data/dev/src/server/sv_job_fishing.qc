//
// Fishing
//

.float fishing_node_idle_expire;
.float bobber_in_water;
.float spawn_time;

void() fishing_node_respawn;

void(entity e) Fishing_ForceOff =
{
	e.melee_finished = time;
	e.fishing_finished = time;
	e.fishcast_finished = time;
	e.lockview_finished = time;
	e.anistate = ANISTATE_NONE;
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
	WriteByte(MSG_ENTITY, self.health);
	return TRUE;
};

//
// Fishing node out
//
void() fishing_node_remove =
{
	float respawn_time = 120 + random() * 480;

	self.think = fishing_node_respawn;
	self.nextthink = time + respawn_time;
};

//
// Idle despawn checker
//
void() fishing_node_idle_check =
{
	self.angles_y += random_range(-3, 3);

	if (time >= self.fishing_node_idle_expire)
	{
		self.think = fishing_node_remove;
		self.nextthink = time + 0.1;
		return;
	}

	self.nextthink = time + 5;
};

//
// Respawn fishing node
//
void() fishing_node_respawn =
{
	self.health = self.max_health;
	self.cnt = 0;

	self.fishing_node_idle_expire = time + (180 + random() * 300);

	self.SendFlags = 1; // Send CSQC update
	self.think = fishing_node_idle_check;
	self.nextthink = time + 5;
};

//
// Fishing result logic
//
void() Fishing_Bobber_SearchNode =
{
	float found = FALSE;

	entity targ = findradius(self.origin, 60);
	while (targ)
	{
		if (targ.classname == "fishing_node" && targ.health > 0)
		{
			found = TRUE;

			// Reset idle timer
			targ.fishing_node_idle_expire = time + (180 + random() * 300);

			// -----------------------
			// XP Gain (like mining)
			// -----------------------
			float xp_chance;
			float skill_factor;
			float node_factor;

			node_factor = targ.level + 1;
			skill_factor = (self.owner.skill_fishing / 20) + 1;

			xp_chance = node_factor / skill_factor;

			if (xp_chance > 0.35) xp_chance = 0.35;
			if (xp_chance < 0.01) xp_chance = 0.01;

			if (random() < xp_chance)
			{
				self.owner.skill_fishing += 0.1;

				string f = sprintf("%.1f", self.owner.skill_fishing);
				sprint(self.owner, PRINT_HIGH, "Fishing increased to ", f, "\n");
			}

			// -----------------------
			// Loot roll (skill vs node difficulty)
			// -----------------------
			float skill = self.owner.skill_fishing;

			// Difficulty curve based on node level
			float required = 25 * targ.level * targ.level;
			float diff = skill - required;

			// Base chance
			float success_chance = 0.15;

			// Scale based on how over/under leveled you are
			if (diff < 0)
				success_chance += diff * 0.005; // harsher penalty
			else
				success_chance += diff * 0.002; // softer bonus

			// Clamp
			if (success_chance < 0.02) success_chance = 0.02;
			if (success_chance > 0.9) success_chance = 0.9;

			string item_name;

			// mostly fish, seldomly epic rare valuable for selling
			if (random() < success_chance)
			{
				if (targ.level == 0)
					item_name = "Small Fish";
				else
					item_name = "Small Fish"; // fallback (or higher tier later)
			}
			else // junk list, all these items are garbage
			{
				item_name = "Old Boot";
			}

			AddToInventory(self.owner, item_name, 1);

			string eventlog_print = strcat("^4Fishing:^2 You caught ", item_name, "!");
			stuffcmd(self.owner, sprintf("conecho event %s\n", eventlog_print));

			sound(self, CHAN_VOICE, "fishsplash.wav", 1, ATTN_NORM);

			// -----------------------
			// Consume node
			// -----------------------
			targ.health -= 1;

			if (targ.health <= 0)
			{
				targ.SendFlags = 1; // Send CSQC update
				targ.think = fishing_node_remove;
				targ.nextthink = time + 0.1;
			}
			break;
		}
		targ = targ.chain;
	}

	if (!found)
	{
		string eventlog_print = (strcat("^4Fishing:^1 Miss!"));
		stuffcmd(self.owner, sprintf("conecho event %s\n", eventlog_print));
	}

	Fishing_ForceOff(self.owner);
	sub_remove();
};

//
// Bobber logic
//
void() DoJob_Fishing_Bobber =
{
	self.modelflags = MF_ROTATE;

	// failsafe
	if (time > self.spawn_time + 10)
	{
		Fishing_ForceOff(self.owner);
		sub_remove();
		return;
	}

	float water_here = pointcontents(self.origin);
	float water_above = pointcontents(self.origin + '0 0 8');

	if (water_here == CONTENT_WATER || water_above == CONTENT_WATER
	 || water_here == CONTENT_SLIME || water_above == CONTENT_SLIME
	 || water_here == CONTENT_LAVA  || water_above == CONTENT_LAVA)
	{
		if (!self.bobber_in_water)
		{
			sound(self, CHAN_BODY, "fishbobber.wav", 1, ATTN_NORM);

			self.bobber_in_water = TRUE;

			self.movetype = MOVETYPE_FLY;
			self.velocity = '0 0 0';

			self.origin_z += 16;
			setorigin(self, self.origin);

			float delay = 3 + random() * random() * 4;

			self.owner.anistate = ANISTATE_FISHIDLE;
			self.owner.fishing_finished = time + delay;

			self.think = Fishing_Bobber_SearchNode;
			self.nextthink = time + delay;

			return;
		}
	}
	else
	{
		if (self.flags & FL_ONGROUND)
		{
			string eventlog_print = (strcat("^4Fishing: ^1Failed!"));
			stuffcmd(self.owner, sprintf("conecho event %s\n", eventlog_print));

			Fishing_ForceOff(self.owner);
			sub_remove();
			return;
		}
		else
		{
			self.cnt += 1;
			if (self.cnt > 49)
			{
				Fishing_ForceOff(self.owner);
				self.cnt = 0;
				sub_remove();
				return;
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
	Player_RemoveCrouch(); // remove crouch
	self.velocity_x = self.velocity_y = 0; // stop movement

	sound(self, CHAN_WEAPON, "fishcast.wav", 1, ATTN_NORM);

	string eventlog_print = (strcat("^4Fishing:^2 Line cast ..."));
	stuffcmd(self, sprintf("conecho event %s\n", eventlog_print));

	makevectors(self.angles);

	entity bobber = spawn();
	bobber.owner = self;
	bobber.movetype = MOVETYPE_TOSS;
	bobber.solid = SOLID_SLIDEBOX;
	bobber.classname = "bobber";
	bobber.scale = 0.5;
	bobber.cnt = 0;
	bobber.hitcontentsmaski = CONTENTBIT_WATER | CONTENTBIT_SLIME | CONTENTBIT_LAVA | CONTENTBIT_SOLID;
	bobber.effects = EF_FULLBRIGHT;

	setmodel(bobber, "models/fishingbobber.glb");
	setsize(bobber, '-16 -16 -0', '16 16 16');
	setorigin(bobber, self.origin + v_forward * 24 + v_up * 48);

	bobber.velocity_z = 400 + random_range(-50, 50);
	bobber.spawn_time = time;
	bobber.bobber_in_water = FALSE;

	vector dir = v_forward + v_right * random_range(-0.15, 0.15) + v_up * random_range(0, 0.2);
	dir = normalize(dir);
	bobber.velocity = bobber.velocity + dir * random_range(300, 600);

	bobber.think = DoJob_Fishing_Bobber;
	bobber.nextthink = time + 1;
};

//
// Fishing node spawn
//
void() misc_fishing_node =
{

	precache_model("models/fishschool.glb");

	self.classname = "fishing_node";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	self.health = 0;
	self.max_health = 6 + floor(random() * 4);
	self.flags |= FL_FINDABLE_NONSOLID;

	if (!self.level)
		self.level = 0;

	self.angles_y = random()*360;
	self.mdl = "models/fishschool.glb";

	setsize(self, [-64, -64, -64], [64, 64, 64]);
	setorigin(self, self.origin);

	self.think = fishing_node_respawn;
	self.nextthink = time + (120 + random() * 480);

	self.SendEntity = FishingNode_SendEntity;
	self.SendFlags = 1;
};