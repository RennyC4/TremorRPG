//
// NPCs, most are defined in the maps themselves (hmp / bsp)
//

$frame climb death stand jump move slash

void(entity targ, entity client) SendNPCInventory;
void(entity player) DeleteInventory;
void() npc_ai_think;
.string npc_dialog; // reference npc file scripts

void() npc_use =
{
	if (!self.user)
		return;
	if (self.user.menu != MENU_OFF)
		return;

	self.user.velocity = [0, 0];

	string contents = "";
	string line = "";

	// grab NPC dialogue from file
	string readfile = strcat("npc_", self.netname, "_d.txt");
	float v = fopen(readfile, FILE_READ);
	if (v >= 0)
	{
		while ((line = fgets(v)))
			contents = strcat(contents, line, "\n");
		self.npc_dialog = contents;
	}
	else
	{
		// Not all NPC's wish to talk, keep it in debug print however
		dprint("Possible Error: NPC dialogue file not found\n");
		self.think = npc_ai_think;
		self.nextthink = time + 0.1;
		return;
	}
	fclose(v);

	DeleteInventory(self); // clear any inventory first, fixes gold doubling

	if (!self.type) //type 0, regular NPC; may or may not buy/sell items
	{
		// Grab NPC inventory from file
		string what = "";
		readfile = strcat("npc_", self.netname, "_i.txt");
		float b = fopen(readfile, FILE_READ);
		if (b >= 0)
		{
			if (line = fgets(b)) // Get item count from text file
				self.read_inv_count = stof(line);

			float i;
			for (i = 0; i < self.read_inv_count; i++)
			{
				if (line = fgets(b)) // Add item
				{
					what = line;
					AddToInventory(self, line, 0);
				}
				if (line = fgets(b)) // Add count to item, NPCs use item count as buying price
					AddToInventory(self, what, stof(line));
			}
			SendNPCInventory(self, self.user); // Send NPC inventory to CSQC
			self.user.npc_vendor = 1; // Buy/Sell button
			fclose(b);
		}
		else // no item list found for npc
		{
			SendNPCInventory(self, self.user); // Clear NPC inventory when they have nothing either
			self.user.npc_vendor = 0; // CSQC: don't draw buy button for player
		}
	}
	else if (self.type == 1) // type 1, banking npc
		self.user.npc_vendor = 2; // Banking button
	else if (self.type == 2)
		self.user.npc_vendor = 3; // Sell wood button
	
	msg_entity = self.user;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_NPCINFO); // custom opcode for "open npc dialog"
	WriteString(MSG_MULTICAST, self.netname);
	WriteString(MSG_MULTICAST, self.npc_dialog);
	multicast(self.origin, MULTICAST_ONE_R);

	// Open player NPC window
	self.user.menu = MENU_DIALOGUE;
	stuffcmd (self.user, sprintf("play %s\n", "menu/menu_open.wav"));

	self.think = npc_ai_think;
	self.nextthink = time + 0.1;
};

void() npc_ai_think =
{
	entity best = world;
	float best_dist = self.sight_range; // maximum distance NPC can "see"

	for (entity b = world; (b = find(b, classname, "player"));) 
	{
		vector diff = (b.origin + b.view_ofs) - (self.origin + self.view_ofs);
		float dist = vlen(diff);

		if (dist <= self.sight_range && visible_ofs(b)) // check if within sight range and visible
		{
			if (dist < best_dist)
			{
				best = b;
				best_dist = dist;
			}
		}
	}

	// --- Assign the closest visible player (if any) ---
	if (best)
		self.goalentity = best;
	else
		self.goalentity = world;

	// --- Basic sanity check ---
	if (!self.netname)
	{
		print("Error: NPC without a netname defined!\n");
		self.netname = "error";
	}

	// --- Turn smoothly toward target ---
	TurnToTarget(10);

	self.nextthink = time + 0.1;
};

void() set_npc =
{
	precache_model(self.model);

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	if (!self.max_health)
		self.health = 1;
	else
		self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	self.classname = "npc";
	self.view_ofs = '0 0 48';
	self.radius_candamage = FALSE;
	self.idealangles = self.angles;
	self.th_use = npc_use;
	self.frame = $stand;
	self.worldlight = TRUE;

	if (!self.sight_range)
		self.sight_range = 100;

	self.saveorigin = self.origin + v_up * 5; // stash initial spawn spot

	setmodel(self, self.model);
	setsize(self, [-16, -16, 0], [16, 16, 56]);

	self.flags |= FL_FINDABLE_NONSOLID;

	self.think = npc_ai_think;
	self.nextthink = time + 0.1;

	droptofloor();
};


float(entity ePVEnt, float flChanged) Bonfire_SendEntity =
{
	WriteByte(MSG_ENTITY, ENT_BONFIRE);
	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);
	return TRUE;
};

void() bonfire_use =
{
	if (self.user && self.user.bonfire_finished < time)
	{
		if (self.user.bonfire == FALSE)
		{
			self.user.lantern = FALSE;
			self.user.effects &= ~EF_BRIGHTLIGHT;

			// Restore stats
			self.user.health = self.user.max_health;
			self.user.mana = self.user.max_mana;
			self.user.stamina = 100;
			// Remove pvp auto flag
			self.user.pvp_autoflagged = FALSE;
			self.user.pvpenable_count = 0;
			// Remove combat
			self.user.incombat_finished = time;
			self.user.incombat = FALSE;

			// Simulate sitting (we're enabling crouch, without alpha)
			setsize(self.user, [-16, -16, 0], [16, 16, 28]);
			self.user.view_ofs = [0, 0, 24];
			self.user.crouch = TRUE;
			self.user.movetype = MOVETYPE_NONE; // Stop user movement
			self.user.velocity = '0 0 0';
			self.user.anistate = ANISTATE_SIT;

			string eventlog_print = "^5You rest at the bonfire ...\n";
			stuffcmd (self.user, sprintf("conecho event %s\nwf\n", eventlog_print));

			self.user.bonfire = TRUE;
			self.user.bonfire_finished = time + 3;
			sound (self, CHAN_AUTO, "bonfire1.wav", 1, ATTN_NORM);
		}
		/*
		else
			// Moved to sv_player.qc for various reasons
		*/
	}
};

void() set_bonfire =
{
	self.SendEntity = Bonfire_SendEntity;
	self.solid = SOLID_SLIDEBOX;
	self.th_use = bonfire_use;
	setsize(self, [-16, -16, 0], [16, 16, 80]);
	droptofloor();

	self.SendFlags = 1;
};