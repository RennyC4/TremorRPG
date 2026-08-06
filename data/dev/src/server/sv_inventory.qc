//
// Inventory
//

void() Item_Touch;

// Management checks
float(entity player, string itemname) HasItem =
{
    float i;

    for (i = 0; i < player.inv_count; i++)
        if (player.inventory[i] == itemname)
            return TRUE;

    return FALSE;
};

float(entity player, string itemname) GetItemCount =
{
    float i;

    for (i = 0; i < player.inv_count; i++)
        if (player.inventory[i] == itemname)
            return player.inventory_count[i];

    return 0;
};
//

// Buying an item from a vendor
void(string itemname, float price) CSEv_PlayerBuyItem_sf =
{
	price -= ceil(self.skill_haggle * 0.5);
	if (price < 1)
		price = 1;

	float gold_ok = FALSE;
	if (self.gold < price)
	{
		sprint(self, PRINT_HIGH, "Not enough ^3gold^7!\n");
		return;
	}
	else
		gold_ok = TRUE;

	float count = 1;
	string lname = string_tolower(itemname); // case insensitivity
	if (strstrofs(lname, "arrow", 0) != -1) // check if this is an arrow-type item
		count = 10; // give a bundle

    float i;
    // first see if item already exists, then add it
    for (i = 0; i < self.inv_count; i++)
    {
        if (self.inventory[i] == itemname)
        {
			// Health potion check
			if (self.classname == "player" && itemname == "Health Potion" && self.inventory_count[i] >= 2)
			{
				sprint (self, PRINT_HIGH, "Can only hold 2 ", itemname, "s\n");
				return;
			}
			// Mana potion check
			if (self.classname == "player" && itemname == "Mana Potion" && self.inventory_count[i] >= 2)
			{
				sprint (self, PRINT_HIGH, "Can only hold 2 ", itemname, "s\n");
				return;
			}
			// Hatchet check
			if (self.classname == "player" && itemname == "Hatchet" && (HasItem(self, "Hatchet") || self.main_hand == "Hatchet"))
			{
				sprint(self, PRINT_HIGH, "Can only carry 1 Hatchet.\n");
				return;
			}
			// Mining Pick check
			if (self.classname == "player" && itemname == "Mining Pick" && (HasItem(self, "Mining Pick") || self.main_hand == "Mining Pick"))
			{
				sprint(self, PRINT_HIGH, "Can only carry 1 Mining Pick.\n");
				return;
			}

			if (gold_ok)
				self.gold -= price;

			string printgold = ftos(price);
			sprint (self, PRINT_HIGH, itemname, " bought!\n");
			string eventlog_print = strcat(itemname, " bought! ^1-^3", printgold, "g");
			stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

			stuffcmd (self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound

            self.inventory_count[i] += count;
			return;
        }
    }

	// Hatchet check
	if (self.classname == "player" && itemname == "Hatchet" && (HasItem(self, "Hatchet") || self.main_hand == "Hatchet"))
	{
		sprint(self, PRINT_HIGH, "Can only carry 1 Hatchet.\n");
		return;
	}
	// Mining Pick check
	if (self.classname == "player" && itemname == "Mining Pick" && (HasItem(self, "Mining Pick") || self.main_hand == "Mining Pick"))
	{
		sprint(self, PRINT_HIGH, "Can only carry 1 Mining Pick.\n");
		return;
	}

    // if new item, check space
    if (self.inv_count >= MAX_INVENTORY)
    {
        sprint(self, PRINT_HIGH, "Inventory full!\n");
        return;
    }

	if (gold_ok)
		self.gold -= price;

	string printgold = ftos(price);
	sprint (self, PRINT_HIGH, itemname, " bought!\n");
	string eventlog_print = strcat(itemname, " bought! ^1-^3", printgold, "g");
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

	stuffcmd (self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound
	
    self.inventory[self.inv_count] = itemname;
    self.inventory_count[self.inv_count] = count;
    self.inv_count++;
	
	if (itemname == "Hatchet")
		self.hatchet_durability = 100;
	if (itemname == "Mining Pick")
		self.pick_durability = 100;
};

// Selling an item to a vendor
void(string itemname) CSEv_PlayerSellItem_s =
{
	string line;
	float price = 0;

	string fix_itemname = string_tolower(string_remove_spaces(itemname));
	string readfile = strcat("itm/", fix_itemname, ".txt");
	float v = fopen(readfile, FILE_READ);
	if (v >= 0)
	{
		price = 0;

		while ((line = fgets(v)))
		{
			string key;
			string value;

			key = Item_Key(line);
			value = Item_Value(line);

			if (key == "price")
			{
				price = stof(value);
				break; // We found it, no need to keep reading.
			}
		}
		fclose(v);
	}
	else
	{
		print ("Error: item file: ", readfile, " not found\n");
		return;
	}

	float count = 1;
    float i;

	price += ceil(self.skill_haggle * 0.5);
	self.gold += price;

	string printgold = ftos(price);
	sprint (self, PRINT_HIGH, itemname, " sold!\n");
	string eventlog_print = strcat(itemname, " sold! ^2+^3", printgold, "g");
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

	stuffcmd (self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound

	// Latern check
	if (itemname == "Lantern" && self.lantern)
	{
		self.effects &= ~EF_BRIGHTLIGHT;
		self.lantern = FALSE;
	}

    for (i = 0; i < self.inv_count; i++)
    {
        if (self.inventory[i] == itemname)
        {
            self.inventory_count[i] -= count;
            if (self.inventory_count[i] <= 0)
            {
                // Shift everything down
                for (; i < self.inv_count - 1; i++)
                {
                    self.inventory[i] = self.inventory[i+1];
                    self.inventory_count[i] = self.inventory_count[i+1];
                }
                self.inv_count--;
            }
            return;
        }
    }
};

// Add an item, mainly used for item pick ups / buying items and equipping NPCs for selling items
// returns TRUE if player was able to grab the item
float(entity targ, string itemname, float count) AddToInventory =
{
    float i;

	if (itemname == "Unarmed" || itemname == "Empty")
		return FALSE; // that'd be silly

    // first see if item already exists, then add it
    for (i = 0; i < targ.inv_count; i++)
    {
		if (targ.inventory[i] == itemname)
		{	
			targ.inventory_count[i] += count;
			return TRUE;
		}
    }

    // if new item, check space
    if (targ.inv_count >= MAX_INVENTORY && targ.classname == "player")
    {
        sprint(targ, PRINT_HIGH, "Inventory full!\n");
        return FALSE;
    }

	Quest_Event(targ, "collect", strtolower(itemname), 1);

	targ.inventory[targ.inv_count] = itemname;
	targ.inventory_count[targ.inv_count] = count;
	targ.inv_count++;
	return TRUE;
};

// Remove an item, mainly used for dropping items / arrows etc
void(entity player, string itemname, float count) RemoveFromInventory =
{
    float i;

    for (i = 0; i < player.inv_count; i++)
    {
        if (player.inventory[i] == itemname)
        {
            player.inventory_count[i] -= count;
            if (player.inventory_count[i] <= 0)
            {
                // Shift everything down
                for (; i < player.inv_count - 1; i++)
                {
                    player.inventory[i] = player.inventory[i+1];
                    player.inventory_count[i] = player.inventory_count[i+1];
                }
                player.inv_count--;
            }
            return;
        }
    }
};

void(entity player) DeleteInventory =
{
	float i;

	for (i = 0; i < player.inv_count; i++)
	{
		player.inventory[i] = __NULL__;
		player.inventory_count[i] = 0;
	}

	player.inv_count = 0; // Reset inventory count
};

// item check thinking
void() itemchest_think =
{
	self.owner = world; // allow original owner to grab item
	self.touch = Item_Touch;
	self.think = sub_remove; // Dropped items remove after 30 seconds
	self.nextthink = time + 30;
};

// Spawn item chest
.float itemdrop_finished;
void(string itemname) CSEv_DropItem_s =
{
	if (self.itemdrop_finished > time)
	{
		float remaining = self.itemdrop_finished - time;
		remaining = ceil(remaining);
		sprint(self, PRINT_HIGH, "You must wait ", ftos(remaining), " more seconds before dropping another item.\n");
		return;
	}

	float dropcount = 1; // regular drop count

	// special cases - example: scrap Arrows drop in bundles of 10
	if (!strcmp(itemname, "Scrap Arrow"))
	{
		float arrowcount = GetItemCount(self, "Scrap Arrow");

		if (arrowcount >= 10)
			dropcount = 10;
		else
			dropcount = arrowcount;
	}

	if (dropcount <= 0)
	{
		sprint(self, PRINT_HIGH, "You don't have any ", itemname, " to drop.\n");
		return;
	}

	makevectors(self.angles);

	entity itemchest = spawn();
	itemchest.owner = self;
	itemchest.movetype = MOVETYPE_TOSS;
	itemchest.solid = SOLID_TRIGGER;
	itemchest.classname = "item";
	itemchest.flags = FL_ITEM;
	itemchest.netname = itemname;
	itemchest.scale = 0.75;
	itemchest.angles_y = random() * 360;
	itemchest.modelflags = MF_ROTATE;

	itemchest.count = dropcount; // store the amount being dropped

	setmodel(itemchest, "models/chest.glb");
	setsize(itemchest, '-16 -16 -0', '16 16 16');
	setorigin(itemchest, self.origin);
	itemchest.velocity_z = 270;

	vector dir = normalize(v_forward);
	itemchest.velocity = itemchest.velocity + dir * random_range(100, 300);

	itemchest.think = itemchest_think;
	itemchest.nextthink = time + 1;

	sound(self, CHAN_AUTO, "item/drop.wav", 1, ATTN_NORM);

	string eventlog_print = strcat("Dropped ", ftos(dropcount), " ", itemname, "\n");
	stuffcmd(self, sprintf("conecho event %s\n", eventlog_print));

	// Lantern check
	if (!strcmp(itemname, "Lantern") && self.lantern)
	{
		self.effects &= ~EF_BRIGHTLIGHT;
		self.lantern = FALSE;
	}

	// Remove number from inventory
	RemoveFromInventory(self, itemname, dropcount);

	self.itemdrop_finished = time + 1;
};

void(string itemname) CSEv_UseItem_s =
{
    if (!HasItem(self, itemname))
    {
        sprint(self, PRINT_HIGH, strcat("You don't have a ", itemname, "\n"));
        return;
    }

	// IMPORTANT: Capital letters are considered in itemname string!

	//
	// Consumables
	//
    if (itemname == "Health Potion")
		CSEv_Player_UseItem_fs(0, itemname);
    if (itemname == "Lantern")
		CSEv_Player_UseItem_fs(1, itemname);
    if (itemname == "Mana Potion")
		CSEv_Player_UseItem_fs(2, itemname);
	// Fish
	if (itemname == "Small Fish")
		CSEv_Player_UseItem_fs(4, itemname);

	// Magic spells
	if (itemname == "Spell - Thorn" || itemname == "Spell - Light Heal" || itemname == "Spell - Levitate")
		CSEv_Player_UseItem_fs(3, itemname);

	// Main hand equippables (weapons)
	if (itemname == "Hatchet")
		Player_EquipItem(itemname, 0);
	if (itemname == "Mining Pick")
		Player_EquipItem(itemname, 0);
	if (itemname == "Fishing Rod")
		Player_EquipItem(itemname, 0);
	if (itemname == "Broken Sword")
		Player_EquipItem(itemname, 0);
	else if (itemname == "Short Sword")
		Player_EquipItem(itemname, 0);
	else if (itemname == "Rusty Dagger")
		Player_EquipItem(itemname, 0);
	else if (itemname == "Wood Club")
		Player_EquipItem(itemname, 0);

	// Main hand equippables (projectiles)
	if (itemname == "Scrap Arrow")
		Player_EquipItem(itemname, 0);

	// Armor equippables
	if (itemname == "Plain Clothes")
		Player_EquipItem(itemname, 1);
	else if (itemname == "Padded Armor")
		Player_EquipItem(itemname, 1);

	// Off hand equippables (shields, etc)
	else if (itemname == "Broken Buckler")
		Player_EquipItem(itemname, 2);
	else if (itemname == "Flimsy Buckler")
		Player_EquipItem(itemname, 2);
	else if (itemname == "Short Bow")
		Player_EquipItem(itemname, 2);
		
	// Helmets
	if (itemname == "Bandit Hood")
		Player_EquipItem(itemname, 3);
	
	Quest_Event(self, "use", strtolower(itemname), 1);
};

// called whenever we need to send player/client ONLY inventory data to CSQC
void(entity player) SendPlayerInventory =
{
    float i;

	msg_entity = player;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_INVENTORY);
	WriteByte(MSG_MULTICAST, player.inv_count);

    for (i = 0; i < player.inv_count; i++)
    {
        WriteString(MSG_MULTICAST, player.inventory[i]);
        WriteFloat(MSG_MULTICAST, player.inventory_count[i]);
    }
	multicast(self.origin, MULTICAST_ONE_R);
};

// called whenever we need to send inventory data to CSQC from an NPC ONLY
void(entity targ, entity client) SendNPCInventory =
{
	if (client.classname != "player")
		return;

    float i;

	msg_entity = client;
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_INVENTORY_NPC);
	WriteByte(MSG_MULTICAST, targ.inv_count);

    for (i = 0; i < targ.inv_count; i++)
    {
        WriteString(MSG_MULTICAST, targ.inventory[i]);
        WriteFloat(MSG_MULTICAST, targ.inventory_count[i]);
    }
	multicast(self.origin, MULTICAST_ONE_R);
};

void() Item_Touch =
{
	// =========================
	// MONSTER LOOT CHEST
	// =========================
	if (self.lootmode)
	{
		entity e = find(world, classname, "chestloot");

		while (e)
		{
			if (e.owner == self)
			{
				float amount;

				amount = e.loot_amount;

				if (amount <= 0)
					amount = 1;

				AddToInventory(other, e.netname, amount);

				string eventlog_print = strcat("Acquired ", ftos(amount), " ", e.netname, "\n");
				stuffcmd(other, sprintf("conecho event %s\n", eventlog_print));

				sound(other, CHAN_AUTO, "item/get.wav", 1, ATTN_NORM);

				SaveInventory(other);

				remove(e);
			}

			e = find(e, classname, "chestloot");
		}

		remove(self);
		return;
	}

    if (other.classname != "player")
        return;
    if (self.stagger_finished > time) // prevent console spam on items that cannot be picked up
        return;

    float check;
    float h;

    // Only allow 1 hatchet per player
    if (self.netname == "Hatchet" && (HasItem(other, "Hatchet") || other.main_hand == "Hatchet"))
    {
        sprint(other, PRINT_HIGH, "You can only carry one Hatchet.\n");
        self.stagger_finished = time + 3;
        return;
    }
    // Only allow 1 mining pick per player
    if (self.netname == "Mining Pick" && (HasItem(other, "Mining Pick") || other.main_hand == "Mining Pick"))
    {
        sprint(other, PRINT_HIGH, "You can only carry one Mining Pick.\n");
        self.stagger_finished = time + 3;
        return;
    }

    // Try adding the item first
    amount = self.count;
    if (amount <= 0)
        amount = 1;

    check = AddToInventory(other, self.netname, amount);

    // Only enforce potion limits if the item being picked up IS a potion
    if (!strcmp(self.netname, "Health Potion") || !strcmp(self.netname, "Mana Potion"))
    {
        if (HasItem(other, self.netname))
        {
            h = GetItemCount(other, self.netname);

            if (h > 2) // Already have more than 2? Block pickup
                check = FALSE;
        }
    }

    if (check) // player can grab item
    {
        amount = self.count;
        if (amount <= 0)
            amount = 1;

        eventlog_print = strcat("Acquired ", ftos(amount), " ", self.netname, "\n");
        stuffcmd(other, sprintf("conecho event %s\n", eventlog_print));

        sound(other, CHAN_AUTO, "item/get.wav", 1, ATTN_NORM);

        SaveInventory(other);
        remove(self);
    }
    else if (self.stagger_finished < time)
    {
        sprint(other, PRINT_HIGH, "Cannot hold item: ", self.netname, "\n");
        self.stagger_finished = time + 3;
    }
};