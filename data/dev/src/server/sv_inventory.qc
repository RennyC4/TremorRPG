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

	if (self.gold < price)
	{
		sprint(self, PRINT_HIGH, "Not enough ^3gold^7!\n");
		return;
	}
	else
		float gold_ok = TRUE;
		
    // first see if item already exists, then add it
	float count = 1;
    float i;
    for (i = 0; i < self.inv_count; i++)
    {
        if (self.inventory[i] == itemname)
        {
			if (gold_ok)
				self.gold -= price;

			// Health potion check
			if (self.classname == "player" && itemname == "Health Potion" && self.inventory_count[i] >= 2)
			{
				sprint (self, PRINT_HIGH, "Can only hold 2 ", itemname, "s\n");
				return;
			}

			string printgold = ftos(price);
			sprint (self, PRINT_HIGH, itemname, " bought!\n");
			string eventlog_print = strcat(itemname, " bought! ^1-^3", printgold, "g");
			stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

			stuffcmd (self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound

            self.inventory_count[i] += count;
            return;
        }
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
};

// Selling an item to a vendor
void(string itemname) CSEv_PlayerSellItem_s =
{
	string line;
	float price = 0;

	string fix_itemname = string_remove_spaces(itemname);
	string readfile = strcat("itm_", fix_itemname, ".txt");
	float v = fopen(readfile, FILE_READ);
	if (v >= 0)
	{
		if (line = fgets(v))
			price = stof(line); // grab price from item file
		fclose(v);
	}
	else
	{
		print ("Error: item file not found\n");
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

// Add an item, mainly used for item pick ups
// returns TRUE if player was able to grab the item
float(entity targ, string itemname, float count) AddToInventory =
{
    float i;

	if (itemname == "Unarmed" || itemname == "Empty")
		return; // that'd be silly

    // first see if item already exists, then add it
    for (i = 0; i < targ.inv_count; i++)
    {
		// Health potion check
		if (targ.classname == "player" && itemname == "Health Potion" && targ.inventory_count[i] >= 2)
		{
			sprint (targ, PRINT_HIGH, "Can only hold 2 ", itemname, "s\n");
			return FALSE;
		}
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

    targ.inventory[targ.inv_count] = itemname;
	targ.inventory_count[targ.inv_count] = count;
    targ.inv_count++;
	return TRUE;
};

// Remove an item, mainly used for dropping items
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

void() itemchest_think =
{
	self.owner = world; // allow original owner to grab item
	self.touch = Item_Touch;
	self.think = sub_remove; // Dropped items remove after a minute
	self.nextthink = time + 60;
};

void(string itemname) CSEv_DropItem_s =
{
	// Spawn chest
	makevectors (self.angles);

	entity itemchest = spawn();
	itemchest.owner = self;
	itemchest.movetype = MOVETYPE_TOSS;
	itemchest.solid = SOLID_TRIGGER;
	itemchest.classname = "item";
	itemchest.flags = FL_ITEM;
	itemchest.netname = itemname; // netname = what its holding
	itemchest.scale = 0.75;
	itemchest.angles_y = random()*360;
	itemchest.modelflags = MF_ROTATE;

	setmodel(itemchest, "models/chest.glb");
	setsize(itemchest, '-16 -16 -0', '16 16 16');
	setorigin(itemchest, self.origin);
	itemchest.velocity_z = 270;
	vector dir = v_forward;
	dir = normalize(dir);
	itemchest.velocity = itemchest.velocity + dir * (random_range(100, 300));

	itemchest.think = itemchest_think;
	itemchest.nextthink = time + 1;

	sound (self, CHAN_AUTO, "item/drop.wav", 1, ATTN_NORM);

	string eventlog_print = (strcat("Dropped ", itemname, "\n"));
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

	// Remove inventory item
	RemoveFromInventory(self, itemname, 1);
}

void(string itemname) CSEv_UseItem_s =
{
    if (!HasItem(self, itemname))
    {
        sprint(self, PRINT_HIGH, strcat("You don't have a ", itemname, "\n"));
        return;
    }

	// IMPORTANT: Capital letters are considered in itemname string!

	// Consumables
    if (itemname == "Health Potion")
		Player_UseItem(0, itemname);

	// Main hand equippables (weapons)
	if (itemname == "Broken Sword")
		Player_EquipItem(itemname, 0);
	else if (itemname == "Short Sword")
		Player_EquipItem(itemname, 0);
	else if (itemname == "Rusty Dagger")
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

	RemoveFromInventory(self, itemname, 1);
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
    if (other.classname != "player")
        return;
	if (self.stagger_finished > time) // prevent console spam on items that cannot be picked up
		return;

	float check = AddToInventory(other, self.netname, 1); // self.netname is the item's identifier string

	if (check) // player can grab item
	{
		string eventlog_print = (strcat("Got ", self.netname, "\n"));
		stuffcmd (other, sprintf("conecho event %s\n", eventlog_print));
		stuffcmd (other, sprintf("play %s\n", "item/get.wav"));
		remove(self);
	}
	else
		self.stagger_finished = time + 1;
};