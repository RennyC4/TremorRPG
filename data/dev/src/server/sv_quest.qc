//
// Quest handling - server side
//

float(entity targ, string itemname, float count) AddToInventory;
void(entity player, entity q) Quest_SendDescription;

//
// Quest status
//

#define QUEST_LOCKED    0
#define QUEST_AVAILABLE 1
#define QUEST_ACTIVE    2
#define QUEST_COMPLETE  3
#define QUEST_TURNEDIN  4

#define MAX_QUESTS 64
#define MAX_QUEST_OBJECTIVES 8

//
// Quest definition fields
//

entity quest_list;
.string quest_id;
.string quest_name;
.string quest_description;
.string quest_objective;
.string quest_zone;
.string quest_giver;
.string quest_turnin;
.string quest_type;
.string quest_target;
.float quest_count;
.float quest_repeatable;
.float quest_level;
.float reward_exp;
.float reward_gold;
.string reward_item;
.float reward_item_count;
.string next_quest;
.string required_quest;
.string quest_filename;
.float quest_index;
.entity quest_next;

//
// Player quest fields
//

.float player_quest_count;

.string player_quest_id[64];
.float player_quest_status[64];
.float player_quest_objective_progress[512];

//
// Legacy single progress (can remove later)
//
.float player_quest_progress[64];

//
// Quest objectives
//

.entity quest_objectives;
.entity objective_next;

.string objective_type;
.string objective_target;
.string objective_text;

.float objective_count;

//
// Quest prototypes
//

void() Quest_LoadAll;
void(entity q, string filename) Quest_Load;
entity(string id) Quest_Find;
float(string id) Quest_Exists;
entity(entity player, float slot) Quest_PlayerDefinition;
float(entity player, string id) Quest_PlayerHas;
void(entity player) Quest_LoadPlayer;
void(entity player) Quest_SavePlayer;
void(entity player, string id) Quest_Accept;
void(entity player, string id) Quest_Complete;
void(entity player, string id) Quest_TurnIn;
void(entity player, string type, string target, float amount) Quest_Event;
void(entity player, string id) Quest_Unlock;
float(entity player, string id) Quest_Completed;
float(entity player, string id) Quest_CanOffer;
float(entity player, string id) Quest_CanTurnIn;
float(entity player, string id) Quest_IsActive;
float(entity player, string id) Quest_IsCompleted;

void(entity player) Quest_SendLog; // CSQC
void(entity player, string id) Quest_SendPreview;

//
// Helpers
//

// Convert quest/objective pair into a single array index
float(float quest, float objective) Quest_ObjectiveIndex =
{
	return (quest * 8) + objective;
};

float(entity player, string id) Quest_IsActive =
{
	float slot;
	slot = Quest_PlayerHas(player, id);

	if (slot < 0)
		return FALSE;

	return player.player_quest_status[slot] == QUEST_ACTIVE;
};

float(entity player, string id) Quest_IsCompleted =
{
	float slot;
	slot = Quest_PlayerHas(player, id);

	if (slot < 0)
		return FALSE;

	return player.player_quest_status[slot] == QUEST_TURNEDIN;
};

//
// Add objective to quest
//

void(entity q, string value) Quest_AddObjective =
{
	entity obj;
	entity last;

	string type;
	string target;
	string count;
	string text;

	float p1;
	float p2;
	float p3;

	//
	// Find commas
	//

	p1 = strstrofs(value, ",", 0);
	if (p1 < 0)
		return;

	p2 = strstrofs(value, ",", p1 + 1);
	if (p2 < 0)
		return;

	p3 = strstrofs(value, ",", p2 + 1);
	if (p3 < 0)
		return;

	//
	// Split fields
	//

	type = strtrim(substring(value, 0, p1));
	target = strtrim(substring(value, p1 + 1, p2 - p1 - 1));
	count = strtrim(substring(value, p2 + 1, p3 - p2 - 1));
	text = strtrim(substring(value, p3 + 1, strlen(value) - p3));

	//
	// Create objective
	//

	obj = spawn();

	obj.objective_type = strtolower(type);
	obj.objective_target = strtolower(target);
	obj.objective_count = stof(count);
	obj.objective_text = text;

	//
	// Append
	//

	if (!q.quest_objectives)
		q.quest_objectives = obj;
	else
	{
		last = q.quest_objectives;

		while (last.objective_next)
			last = last.objective_next;

		last.objective_next = obj;
	}
};

//
// Send quest preview (accept/decline)
//

void(entity player, string id) Quest_SendPreview =
{
	entity q;
	entity obj;

	if (player.classname != "player")
		return;

	q = Quest_Find(id);

	if (!q)
		return;

	msg_entity = player;

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_QUEST_PREVIEW);

	WriteString(MSG_MULTICAST, q.quest_id);
	WriteString(MSG_MULTICAST, q.quest_name);
	WriteString(MSG_MULTICAST, q.quest_description);

	//
	// First objective text
	//

	obj = q.quest_objectives;

	if (obj)
		WriteString(MSG_MULTICAST, obj.objective_text);
	else
		WriteString(MSG_MULTICAST, "");


	WriteFloat(MSG_MULTICAST, q.quest_level);

	WriteFloat(MSG_MULTICAST, q.reward_exp);
	WriteFloat(MSG_MULTICAST, q.reward_gold);

	WriteString(MSG_MULTICAST, q.reward_item);
	WriteFloat(MSG_MULTICAST, q.reward_item_count);

	multicast([0,0,0], MULTICAST_ONE_R);
};

void(string id) CSEv_QuestPreview_s =
{
    entity q;

    q = Quest_Find(id);

    Quest_SendPreview(self, id);

    if (q)
        Quest_SendDescription(self, q);

    self.menu = MENU_QUESTPREVIEW;
};

void() CSEv_QuestPreviewCancel =
{
	self.menu = MENU_DIALOGUE;
};

//
// Send quest description - needs it's own packet as these can overflow and crash
//

void(entity player, entity q) Quest_SendDescription =
{
	if (!player || !q)
		return;

	msg_entity = player;

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_QUESTDETAILS);

	WriteString(MSG_MULTICAST, q.quest_id);
	WriteString(MSG_MULTICAST, q.quest_description);

	multicast([0,0,0], MULTICAST_ONE_R);
};

//
// Send quest log to CSQC
//

void(entity player) Quest_SendLog =
{
	float i;
	float send_count;
	float obj_count;
	float objective;

	entity q;
	entity obj;

	if (player.classname != "player")
		return;

	//
	// Count quests that should appear in the quest log
	//

	send_count = 0;

	for (i = 0; i < player.player_quest_count; i++)
	{
		if (player.player_quest_status[i] == QUEST_AVAILABLE)
			continue;

		if (player.player_quest_status[i] == QUEST_TURNEDIN)
			continue;

		if (player.player_quest_status[i] == QUEST_LOCKED)
			continue;

		q = Quest_PlayerDefinition(player, i);

		if (!q)
			continue;

		//dprint(sprintf("quest=%s name=%g desc=%g\n", q.quest_id, strlen(q.quest_name), strlen(q.quest_description)));

		send_count++;
	}

	//
	// Send packet
	//

	msg_entity = player;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_QUESTINFO);

	//
	// Quest count
	//

	if (send_count > MAX_QUESTS)
		send_count = MAX_QUESTS;

	WriteByte(MSG_MULTICAST, send_count);

	//
	// Quest data
	//

	float sent;

	sent = 0;

	for (i = 0; i < player.player_quest_count; i++)
	{
		//
		// Don't send unavailable/history quests
		//

		if (player.player_quest_status[i] == QUEST_AVAILABLE)
			continue;
		if (player.player_quest_status[i] == QUEST_TURNEDIN)
			continue;
		if (player.player_quest_status[i] == QUEST_LOCKED)
			continue;

		q = Quest_PlayerDefinition(player, i);

		if (!q)
			continue;

		if (sent >= send_count)
			break;

		//
		// Basic quest information
		//

		WriteString(MSG_MULTICAST, q.quest_id);
		WriteString(MSG_MULTICAST, q.quest_name);
		//WriteString(MSG_ONE, q.quest_description); // crashes, needs it's own packet

		//
		// Objectives
		//

		obj_count = 0;

		for (obj = q.quest_objectives; obj; obj = obj.objective_next)
			obj_count++;

		if (obj_count > 8)
			obj_count = 8;

		WriteByte(MSG_MULTICAST, obj_count);

		objective = 0;

		for (obj = q.quest_objectives; obj && objective < obj_count; obj = obj.objective_next)
		{
			WriteString(MSG_MULTICAST, obj.objective_text);
			WriteByte(MSG_MULTICAST, player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)]);
			WriteFloat(MSG_MULTICAST, obj.objective_count);

			objective++;
		}

		//
		// Status
		//

		WriteByte(MSG_MULTICAST, player.player_quest_status[i]);

		//
		// Rewards
		//

		WriteFloat(MSG_MULTICAST, q.reward_exp);
		WriteFloat(MSG_MULTICAST, q.reward_gold);

		WriteString(MSG_MULTICAST, q.reward_item);
		WriteFloat(MSG_MULTICAST, q.reward_item_count);
		
		sent++;
		
		//dprint(sprintf("  %s desc length=%g\n", q.quest_id, strlen(q.quest_description)));
	}

	//dprint(sprintf("^5Quest_SendLog: sending %g quests\n", send_count));

	multicast(player.origin, MULTICAST_ONE_R);

	//
	// Descriptions are sent on demand
	//
	// Sending all descriptions here can exceed the Quake message limit
	// when a player has multiple active quests.
	//
};

//
// Load all quests
//

void() Quest_LoadAll =
{
	float f;
	float index;

	string line;
	string filename;

	entity q;

	f = fopen("quest/index.txt", FILE_READ);
	if (f < 0)
	{
		dprint("^1Quest_LoadAll: Unable to open quest/index.txt\n");
		return;
	}

	index = 0;

	while ((line = fgets(f)))
	{
		line = strtrim(line);

		if (line == "")
			continue;

		// Ignore comments
		if (substring(line, 0, 1) == "#")
			continue;

		filename = strcat("quest/", line, ".qst");

		q = spawn();
		q.classname = "quest_definition";

		q.quest_index = index;
		q.quest_filename = filename;

		index = index + 1;

		//
		// Add to linked list
		//

		q.quest_next = quest_list;
		quest_list = q;

		Quest_Load(q, filename);

		if (!q.quest_id)
		{
			dprint(sprintf("^1Invalid quest file:^7 %s\n", filename));
			continue;
		}

		// Show loaded quests (debugging)
		//dprint(sprintf("^2Loaded Quest:^7 %s\n", q.quest_id));
	}

	fclose(f);
};

//
// Load a single quest definition
//

void(entity q, string filename) Quest_Load =
{
	float f;
	float pos;

	string line;
	string key;
	string value;

	f = fopen(filename, FILE_READ);
	if (f < 0)
	{
		dprint(sprintf("^1Quest_Load: Unable to open %s\n", filename));
		return;
	}

	while ((line = fgets(f)))
	{
		line = strtrim(line);

		if (line == "")
			continue;

		if (substring(line, 0, 1) == "#")
			continue;

		//
		// Split key=value
		//

		pos = strstrofs(line, "=", 0);

		if (pos < 0)
			continue;

		key = substring(line, 0, pos);
		value = substring(line, pos + 1, strlen(line));

		//
		// Quest data
		//

		if (key == "id")
			q.quest_id = strtolower(value);
	
		else if (key == "name")
			q.quest_name = value;

		else if (key == "giver")
			q.quest_giver = value;

		else if (key == "turnin")
			q.quest_turnin = value;

		else if (key == "description")
			q.quest_description = value;

		else if (key == "objective")
			Quest_AddObjective(q, value);

		else if (key == "zone")
			q.quest_zone = value;

		else if (key == "type")
			q.quest_type = value;

		else if (key == "target")
			q.quest_target = strtolower(value);

		else if (key == "count")
			q.quest_count = stof(value);

		else if (key == "repeatable")
			q.quest_repeatable = stof(value);

		else if (key == "level")
			q.quest_level = stof(value);

		//
		// Rewards
		//

		else if (key == "reward_exp")
			q.reward_exp = stof(value);

		else if (key == "reward_gold")
			q.reward_gold = stof(value);

		else if (key == "reward_item")
			q.reward_item = value;

		else if (key == "reward_item_count")
			q.reward_item_count = stof(value);

		//
		// Quest chain
		//

		else if (key == "next")
			q.next_quest = value;

		else if (key == "requires")
			q.required_quest = strtolower(value);
	}

	fclose(f);

	//
	// Validation
	//

	if (!q.quest_id)
		dprint("^1Quest missing id\n");

	if (!q.quest_name)
		dprint(sprintf("^1Quest %s missing name\n", q.quest_id));

	if (!q.quest_objectives)
		dprint(sprintf("^1Quest %s has no objectives\n", q.quest_id));
};

//
// Find quest by ID
//

entity(string id) Quest_Find =
{
	entity q;

	for (q = quest_list; q; q = q.quest_next)
	{
		if (q.quest_id == id)
			return q;
	}

	return world;
};

//
// Quest exists?
//

float(string id) Quest_Exists =
{
	if (Quest_Find(id))
		return TRUE;

	return FALSE;
};

//
// Find player's quest slot
//

float(entity player, string id) Quest_PlayerHas =
{
	float i;

	for (i = 0; i < player.player_quest_count; i++)
	{
		if (player.player_quest_id[i] == id)
			return i;
	}

	return -1;
};

//
// Get quest definition from player slot
//

entity(entity player, float slot) Quest_PlayerDefinition =
{
	if (slot < 0 || slot >= player.player_quest_count)
		return world;

	return Quest_Find(player.player_quest_id[slot]);
};

//
// Can NPC offer quest?
//

float(entity player, string id) Quest_CanOffer =
{
	entity q;

	q = Quest_Find(id);

	if (!q)
		return FALSE;

	//
	// Has prerequisite?
	//

	if (q.required_quest)
	{
		if (!Quest_Completed(player, q.required_quest))
			return FALSE;
	}

	//
	// Already knows about it?
	//

	float slot;
	slot = Quest_PlayerHas(player, id);

	if (slot >= 0)
	{
		if (player.player_quest_status[slot] == QUEST_AVAILABLE)
			return TRUE;

		if (player.player_quest_status[slot] == QUEST_LOCKED)
			return TRUE;

		return FALSE;
	}

	return TRUE;
};	

//
// Accept quest
//

void(entity player, string id) Quest_Accept =
{
	entity q;

	float i;
	float slot;
	float objective;

	slot = -1;

	if (player.classname != "player")
		return;

	q = Quest_Find(id);

	if (!q)
	{
		dprint(sprintf("^1Quest_Accept: Quest not found: %s\n", id));
		return;
	}

	//
	// Level requirement
	//

	if (q.quest_level > player.level)
	{
		dprint(sprintf("^3Quest level too high:^7 %s\n", id));
		return;
	}

	//
	// Check existing quest slots
	//

	for (i = 0; i < player.player_quest_count; i++)
	{
		if (player.player_quest_id[i] != id)
			continue;

		//
		// Reuse abandoned quest slot
		//

		if (player.player_quest_status[i] == QUEST_LOCKED)
		{
			slot = i;
			break;
		}

		//
		// Accept previously unlocked quest
		//

		if (player.player_quest_status[i] == QUEST_AVAILABLE)
		{
			slot = i;
			break;
		}

		//
		// Already active/completed
		//

		if (player.player_quest_status[i] == QUEST_ACTIVE ||
			player.player_quest_status[i] == QUEST_COMPLETE)
		{
			dprint("^3Quest already active\n");
			return;
		}
	}

	//
	// Quest limit
	//

	if (slot < 0)
	{
		if (player.player_quest_count >= MAX_QUESTS)
		{
			dprint("^1Quest_Accept: Quest limit reached\n");
			return;
		}

		slot = player.player_quest_count;
		player.player_quest_count++;
	}

	//
	// Add / reactivate quest
	//

	player.player_quest_id[slot] = q.quest_id;
	player.player_quest_status[slot] = QUEST_ACTIVE;
	player.player_quest_progress[slot] = 0;

	//
	// Reset objective progress
	//

	for (objective = 0; objective < MAX_QUEST_OBJECTIVES; objective++)
		player.player_quest_objective_progress[Quest_ObjectiveIndex(slot, objective)] = 0;

	//
	// Save and update client
	//

	Quest_SavePlayer(player);
	Quest_SendLog(player);
};

//
// Unlock quest for player
//

void(entity player, string id) Quest_Unlock =
{
	entity q;
	float slot;

	if (player.classname != "player")
		return;

	q = Quest_Find(id);
	if (!q)
	{
		dprint(sprintf("^1Quest_Unlock: Quest not found %s\n", id));
		return;
	}

	//
	// Already knows quest?
	//

	slot = Quest_PlayerHas(player, id);
	if (slot >= 0)
		return;

	//
	// Quest limit
	//

	if (player.player_quest_count >= 64)
	{
		dprint("^1Quest_Unlock: Quest limit reached\n");
		return;
	}

	slot = player.player_quest_count;

	player.player_quest_id[slot] = q.quest_id;
	player.player_quest_status[slot] = QUEST_AVAILABLE;
	player.player_quest_progress[slot] = 0;

	player.player_quest_count++;

	Quest_SavePlayer(player);
	//Quest_SendLog(player);
};

//
// Check if player can turn in quest
//
// Returns:
// TRUE  = quest is ready
// FALSE = not ready
//

float(entity player, string id) Quest_CanTurnIn =
{
	float slot;

	if (player.classname != "player")
		return FALSE;

	//
	// Find player's quest
	//

	slot = Quest_PlayerHas(player, id);
	if (slot < 0)
		return FALSE;

	//
	// Must be complete
	//

	if (player.player_quest_status[slot] != QUEST_COMPLETE)
		return FALSE;

	return TRUE;
};

// =================
// Give Quest Experience
// =================
void(entity targ, float amount) GiveQuestExperience =
{
    if (amount <= 0)
        return;

    // Server EXP Multiplier
    if (exp_multiplier > 0)
        amount *= exp_multiplier;

    amount = ceil(amount);

    targ.exp += amount;

    string eventlog_print = strcat("^2", ftos(amount), "^7 exp received!\n");
    stuffcmd(targ, sprintf("conecho event %s\n", eventlog_print));

    Player_CheckLevelUp(targ);
};

//
// Turn in a completed quest
//

void(entity player, string id) Quest_TurnIn =
{
	entity q;
	float slot;

	//
	// Find player's quest
	//

	slot = Quest_PlayerHas(player, id);
	if (slot < 0)
	{
		dprint(sprintf("^1Quest_TurnIn: Player does not have %s\n", id));
		return;
	}

	//
	// Must be complete
	//

	if (player.player_quest_status[slot] != QUEST_COMPLETE)
	{
		dprint(sprintf( "^3Quest not complete:^7 %s\n", id));
		return;
	}

	//
	// Get quest definition
	//

	q = Quest_PlayerDefinition(player, slot);
	if (!q)
	{
		dprint(sprintf("^1Quest_TurnIn: Missing definition %s\n", id));
		return;
	}

	//
	// Update event box before quest rewards are given
	//

	string eventlog_print = strcat("^3", q.quest_name, " completed\n");
	stuffcmd(player, sprintf("conecho event %s\n", eventlog_print));

	//
	// Give experience
	//

	if (q.reward_exp > 0)
		GiveQuestExperience(player, q.reward_exp);

	//
	// Give gold
	//

	if (q.reward_gold > 0)
		GiveGold(player, world, q.reward_gold, q.reward_gold);

	//
	// Give item reward
	//

	if (q.reward_item)
	{
		if (q.reward_item_count > 0)
		{
			stuffcmd (player, sprintf("play %s\n", "item/get.wav")); // sound
			AddToInventory(player, q.reward_item, q.reward_item_count);
			eventlog_print = strcat("Acquired ", ftos(q.reward_item_count), " ", q.reward_item, "\n");
			stuffcmd(player, sprintf("conecho event %s\n", eventlog_print));
		}
	}

	//
	// Mark complete
	//

	player.player_quest_status[slot] = QUEST_TURNEDIN;

	//
	// Unlock next quest
	//

	if (q.next_quest)
		Quest_Unlock(player, q.next_quest);

	//
	// Save
	//

	Quest_SavePlayer(player);
	Quest_SendLog(player);

	//
	// Completion popup
	//

	msg_entity = player;

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_QUEST_COMPLETE);
	WriteString(MSG_MULTICAST, q.quest_name);

	multicast([0,0,0], MULTICAST_ONE_R);
};

//
// Quest Event Handler
//
// Called when a gameplay event happens
// Examples:
//   Quest_Event(player, "kill", "bandit", 1);
//   Quest_Event(player, "collect", "herb", 1);
//

void(entity player, string type, string target, float amount) Quest_Event =
{
	entity quest;
	entity obj;

	float i;
	float objective;
	float complete;
	float changed;
	float updated;

	if (!player)
		return;
	if (player.classname != "player")
		return;

	if (amount <= 0)
		amount = 1;

	updated = FALSE;

	//
	// Check active quests
	//

	for (i = 0; i < player.player_quest_count; i++)
	{
		changed = FALSE;

		if (player.player_quest_status[i] != QUEST_ACTIVE)
			continue;

		quest = Quest_PlayerDefinition(player, i);

		if (!quest)
			continue;

		//
		// Special handling:
		// Bank withdrawals reduce bank deposit objectives
		//

		if (!strcmp(type, "bank") && !strcmp(target, "withdraw"))
		{
			objective = 0;

			for (obj = quest.quest_objectives; obj; obj = obj.objective_next)
			{
				if (!strcmp(obj.objective_type, "bank") &&
					!strcmp(obj.objective_target, "deposit"))
				{
					player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] -= amount;

					if (player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] < 0)
						player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] = 0;

					changed = TRUE;
					updated = TRUE;

					break;
				}

				objective++;
			}
		}
		else
		{
			//
			// Find matching objective
			//

			objective = 0;

			for (obj = quest.quest_objectives; obj; obj = obj.objective_next)
			{
				float oldprogress;

				if (strcmp(obj.objective_type, type))
				{
					objective++;
					continue;
				}

				if (strcmp(obj.objective_target, target))
				{
					objective++;
					continue;
				}

				oldprogress = player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)];

				player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] += amount;

				if (player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] > obj.objective_count)
					player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] = obj.objective_count;

				//
				// Objective just completed
				//

				if (oldprogress < obj.objective_count &&
					player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] >= obj.objective_count)
				{
					msg_entity = player;

					WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
					WriteByte(MSG_MULTICAST, CSQC_QUEST_OBJECTIVE_COMPLETE);
					WriteString(MSG_MULTICAST, obj.objective_text);

					multicast([0,0,0], MULTICAST_ONE_R);
				}

				changed = TRUE;
				updated = TRUE;

				break;
			}
		}

		if (!changed)
			continue;

		//
		// Check if all objectives are complete
		//

		complete = TRUE;
		objective = 0;

		for (obj = quest.quest_objectives; obj; obj = obj.objective_next)
		{
			if (player.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] < obj.objective_count)
			{
				complete = FALSE;
				break;
			}

			objective++;
		}

		if (complete)
			player.player_quest_status[i] = QUEST_COMPLETE;
	}

	//
	// Update client and save
	//

	if (updated)
	{
		Quest_SavePlayer(player);
		Quest_SendLog(player);
	}
};

//
// Save player quest progress
//

void(entity player) Quest_SavePlayer =
{
	float f;
	float i;
	float objective;

	entity quest;
	entity obj;

	string filename;
	string line;
	string progress;

	if (player.classname != "player")
		return;

	filename = strcat("chr/", player.loginname, ".qst");
	f = fopen(filename, FILE_WRITE);

	if (f < 0)
	{
		dprint(sprintf("^1Quest_SavePlayer: Unable to open %s\n", filename));
		return;
	}

	fputs(f, "#QUESTS\n");

	for (i = 0; i < player.player_quest_count; i++)
	{
		quest = Quest_PlayerDefinition(player, i);

		if (!quest)
			continue;

		//
		// Build objective progress string
		//

		progress = "";
		objective = 0;

		for (obj = quest.quest_objectives; obj; obj = obj.objective_next)
		{
			if (progress != "")
				progress = strcat(progress, ",");

			progress = strcat(progress, ftos(player.player_quest_objective_progress[(i * MAX_QUEST_OBJECTIVES) + objective]));

			objective++;
		}

		//
		// Save:
		// quest_id|status|objective1,objective2,...
		//

		line = sprintf(
			"%s|%g|%s\n",
			player.player_quest_id[i],
			player.player_quest_status[i],
			progress
		);

		fputs(f, line);
	}

	fclose(f);
};

//
// Load player quest progress
//

void(entity player) Quest_LoadPlayer =
{
	float f;

	float objective;
	float start;
	float end;
	float slot;

	string filename;
	string line;

	string id;
	string status;
	string progress;
	string value;

	float pos1;
	float pos2;
	float comma;

	entity quest;

	filename = strcat("chr/", player.loginname, ".qst");
	f = fopen(filename, FILE_READ);

	if (f < 0)
		return; // No quest file yet

	//
	// Reset current quests
	//

	player.player_quest_count = 0;

	while ((line = fgets(f)))
	{
		line = strtrim(line);


		if (line == "")
			continue;

		//
		// Ignore comments
		//

		if (substring(line, 0, 1) == "#")
			continue;

		//
		// Split:
		//
		// quest_id|status|progress
		//

		pos1 = strstrofs(line, "|", 0);

		if (pos1 < 0)
			continue;

		pos2 = strstrofs(line, "|", pos1 + 1);

		if (pos2 < 0)
			continue;

		id = substring(line, 0, pos1);
		status = substring(line, pos1 + 1, pos2);
		progress = substring(line, pos2 + 1, strlen(line));

		//
		// Validate quest exists
		//

		quest = Quest_Find(id);

		if (!quest)
		{
			dprint(sprintf("^3Unknown quest in save:^7 %s\n", id));
			continue;
		}

		//
		// Quest limit
		//

		if (player.player_quest_count >= 64)
		{
			dprint("^1Quest_LoadPlayer: Quest limit reached\n");
			break;
		}

		//
		// Add quest
		//

		slot = player.player_quest_count;

		player.player_quest_id[slot] = id;
		player.player_quest_status[slot] = stof(status);

		//
		// Load objective progress
		//

		objective = 0;
		start = 0;

		while (objective < MAX_QUEST_OBJECTIVES)
		{
			comma = strstrofs(progress, ",", start);

			if (comma < 0)
				value = substring(progress, start, strlen(progress));
			else
				value = substring(progress, start, comma);

			if (value != "")
				player.player_quest_objective_progress[Quest_ObjectiveIndex(slot, objective)] = stof(value);

			objective++;

			if (comma < 0)
				break;

			start = comma + 1;
		}

		// Increase quest count
		player.player_quest_count++;
	}
	fclose(f);
};

void(string id) CSEv_QuestDescription_s =
{
	entity q;

	if (self.classname != "player")
		return;

	q = Quest_Find(id);

	if (!q)
	{
		dprint(sprintf("^1Quest description not found: %s\n", id));
		return;
	}

	Quest_SendDescription(self, q);
};

//
// Abandon Quest
//

void(string id) CSEv_User_AbandonQuest_s =
{
	float i;
	float objective;

	if (self.classname != "player")
		return;

	for (i = 0; i < self.player_quest_count; i++)
	{
		if (self.player_quest_id[i] != id)
			continue;

		self.player_quest_status[i] = QUEST_LOCKED;
		self.player_quest_progress[i] = 0;

		for (objective = 0; objective < MAX_QUEST_OBJECTIVES; objective++)
			self.player_quest_objective_progress[Quest_ObjectiveIndex(i, objective)] = 0;

		break;
	}

	Quest_SavePlayer(self);
	Quest_SendLog(self);
};