//
// Quest handling - server side
//

float(entity targ, string itemname, float count) AddToInventory;

//
// Quest status
//

#define QUEST_LOCKED    0
#define QUEST_AVAILABLE 1
#define QUEST_ACTIVE    2
#define QUEST_COMPLETE  3
#define QUEST_TURNEDIN  4

//
// Quest definition fields
//

entity quest_list;

.string quest_id;

.string quest_name;
.string quest_description;

.string quest_zone;

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
.float player_quest_progress[64];

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
void(entity player, string type, string target) Quest_Event;
void(entity player, string id) Quest_Unlock;
float(entity player, string id) Quest_Completed;
float(entity player, string id) Quest_CanOffer;
float(entity player, string id) Quest_CanTurnIn;
float(entity player, string id) Quest_IsActive;
float(entity player, string id) Quest_IsCompleted;

void(entity player) Quest_SendLog; // CSQC
//
// Helpers
//

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
// Send quest log to CSQC
//

void(entity player) Quest_SendLog =
{
	float i;
	float send_count;
	entity q;

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

	if (send_count > 64)
		send_count = 64;

	WriteByte(MSG_MULTICAST, send_count);

	//
	// Quest data
	//

	for (i = 0; i < player.player_quest_count; i++)
	{
		//
		// Don't send completed history
		//

		if (player.player_quest_status[i] == QUEST_AVAILABLE)
			continue;

		if (player.player_quest_status[i] == QUEST_TURNEDIN)
			continue;

		q = Quest_PlayerDefinition(player, i);

		if (!q)
			continue;

		//
		// Quest information
		//

		WriteString(MSG_MULTICAST, q.quest_id);
		WriteString(MSG_MULTICAST, q.quest_name);
		WriteString(MSG_MULTICAST, q.quest_description);

		//
		// Status / progress
		//

		WriteByte(MSG_MULTICAST, player.player_quest_status[i]);

		WriteFloat(MSG_MULTICAST, player.player_quest_progress[i]);
		WriteFloat(MSG_MULTICAST, q.quest_count);

		//
		// Rewards
		//

		WriteFloat(MSG_MULTICAST, q.reward_exp);
		WriteFloat(MSG_MULTICAST, q.reward_gold);

		WriteString(MSG_MULTICAST, q.reward_item);
		WriteFloat(MSG_MULTICAST, q.reward_item_count);
	}

	multicast(player.origin, MULTICAST_ONE_R);
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

		else if (key == "description")
			q.quest_description = value;

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

	if (!q.quest_type)
		dprint(sprintf("^1Quest %s missing type\n", q.quest_id));
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
		//
		// Already unlocked but not accepted yet?
		//

		if (player.player_quest_status[slot] == QUEST_AVAILABLE)
			return TRUE;

		//
		// Already active, complete, or turned in.
		//

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
	float slot = -1;

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
	// Already accepted?
	//

	for (i = 0; i < player.player_quest_count; i++)
	{
		if (player.player_quest_id[i] == id)
		{
			if (player.player_quest_status[i] == QUEST_AVAILABLE)
			{
				slot = i;
				break;
			}

			if (player.player_quest_status[i] == QUEST_ACTIVE ||
				player.player_quest_status[i] == QUEST_COMPLETE)
			{
				dprint("^3Quest already active\n");
				return;
			}
		}
	}

	//
	// Quest limit
	//

	if (player.player_quest_count >= 64)
	{
		dprint("^1Quest_Accept: Quest limit reached\n");
		return;
	}

	if (slot < 0)
		slot = player.player_quest_count;

	if (slot < 0 || slot >= 64)
	{
		dprint("^1Quest_Accept: Invalid quest slot\n");
		return;
	}

	//
	// Add quest
	//

	player.player_quest_id[slot] = q.quest_id;
	player.player_quest_status[slot] = QUEST_ACTIVE;
	player.player_quest_progress[slot] = 0;

	//player.player_quest_count++;
	if (slot == player.player_quest_count)
		player.player_quest_count++;

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
	dprint(sprintf("^2Quest Available:^7 %s\n", q.quest_name));
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
		return;

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
	// Give experience
	//

	if (q.reward_exp > 0)
		GiveExperience(player, world, q.reward_exp, q.reward_exp);

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
			AddToInventory(player, q.reward_item, q.reward_item_count);
			string eventlog_print = strcat("Acquired ", ftos(q.reward_item_count), " ", q.reward_item, "\n");
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
	// Feedback
	//

	centerprint(player, sprintf("Quest Complete\n\n%s", q.quest_name));
};

//
// Quest Event Handler
//
// Called when a gameplay event happens
// Examples:
//   Quest_Event(player, "kill", "bandit");
//   Quest_Event(player, "collect", "herb");
//

void(entity player, string type, string target) Quest_Event =
{
	entity quest;

	float i;
	float progress;
	float changed;

	if (!player)
		return;

	if (player.classname != "player")
		return;

	changed = FALSE;

	//
	// Check active quests
	//

	for (i = 0; i < player.player_quest_count; i++)
	{
		//
		// Only active quests
		//

		if (player.player_quest_status[i] != QUEST_ACTIVE)
			continue;


		//
		// Get quest definition
		//

		quest = Quest_PlayerDefinition(player, i);

		if (!quest)
			continue;


		//
		// Does event match quest?
		//

		if (quest.quest_type != type)
			continue;

		if (quest.quest_target != target)
			continue;


		//
		// Increase progress
		//

		progress = player.player_quest_progress[i];

		progress = progress + 1;


		//
		// Clamp progress
		//

		if (progress > quest.quest_count)
			progress = quest.quest_count;


		player.player_quest_progress[i] = progress;
		changed = TRUE;


		//
		// Quest complete?
		//

		if (progress >= quest.quest_count)
		{
			player.player_quest_status[i] = QUEST_COMPLETE;


			//
			// Completion popup
			//

			msg_entity = player;

			WriteByte(MSG_ONE, SVC_CGAMEPACKET);
			WriteByte(MSG_ONE, CSQC_QUEST_COMPLETE);
			WriteString(MSG_ONE, quest.quest_name);
		}
	}


	//
	// Update client and save
	//

	if (changed)
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

	string filename;
	string line;

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
		line = sprintf("%s|%g|%g\n", player.player_quest_id[i], player.player_quest_status[i], player.player_quest_progress[i]);
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

	string filename;
	string line;

	string id;
	string status;
	string progress;

	float pos1;
	float pos2;

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

		// Ignore comments
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

		if (!Quest_Exists(id))
		{
			dprint(sprintf("^3Unknown quest in save:^7 %s\n", id));
			continue;
		}

		//
		// Add quest
		//

		if (player.player_quest_count >= 64)
		{
			dprint("^1Quest_LoadPlayer: Quest limit reached\n");
			break;
		}

		player.player_quest_id[player.player_quest_count] = id;
		player.player_quest_status[player.player_quest_count] = stof(status);
		player.player_quest_progress[player.player_quest_count] = stof(progress);

		player.player_quest_count++;
	}

	fclose(f);
};