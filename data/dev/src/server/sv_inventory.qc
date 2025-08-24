//
// Inventory
//

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

    // first see if item already exists, then add it
	float count = 1;
    float i;
    for (i = 0; i < self.inv_count; i++)
    {
        if (self.inventory[i] == itemname)
        {
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

	if (self.gold < price)
	{
		sprint(self, PRINT_HIGH, "Not enough gold!\n");
		return;
	}
	else
		self.gold -= price;

	string printgold = ftos(price);
	sprint (self, PRINT_HIGH, itemname, " bought!\n");
	string eventlog_print = strcat(itemname, " bought! ^1-^3", printgold, "g")
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

    self.inventory[self.inv_count] = itemname;
    self.inventory_count[self.inv_count] = count;
    self.inv_count++;
};

// Selling an item to a vendor
void(string itemname) CSEv_PlayerSellItem_s =
{
	string line;
	string fix_itemname = string_remove_spaces(itemname);
	string readfile = strcat("itm_", fix_itemname, ".txt");
	float v = fopen(readfile, FILE_READ);
	if (v >= 0)
	{
		if (line = fgets(v))
			float price = stof(line); // grab price from item file
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
	string eventlog_print = strcat(itemname, " sold! ^2+^3", printgold, "g")
	stuffcmd (self, sprintf("conecho event %s\n", eventlog_print));

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
void(entity targ, string itemname, float count) AddToInventory =
{
    float i;

    // first see if item already exists, then add it
    for (i = 0; i < targ.inv_count; i++)
    {
        if (targ.inventory[i] == itemname)
        {
            targ.inventory_count[i] += count;
            return;
        }
    }

    // if new item, check space
    if (targ.inv_count >= MAX_INVENTORY && targ.classname == "player")
    {
        sprint(targ, PRINT_HIGH, "Inventory full!\n");
        return;
    }

    targ.inventory[targ.inv_count] = itemname;
	targ.inventory_count[targ.inv_count] = count;
    targ.inv_count++;
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

void(entity player, string itemname) UseItem =
{
    if (!HasItem(player, itemname))
    {
        sprint(player, PRINT_HIGH, strcat("You don’t have a ", itemname, "\n"));
        return;
    }

    if (itemname == "health potion") // test crap
    {
        player.health = min(player.health + 25, player.max_health);
        RemoveFromInventory(player, itemname, 1);
        sprint(player, PRINT_HIGH, "You used a health potion\n");
    }
    else if (itemname == "keyred") // test crap
    {
        sprint(player, PRINT_HIGH, "You wave the red key, but nothing happens.\n");
    }
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

	// Example: self.netname is the item's identifier string
    AddToInventory(other, self.netname, 1);

	string eventlog_print = (strcat("+ ", self.netname, "\n"));
	stuffcmd (other, sprintf("conecho event %s\n", eventlog_print));

	remove(self);
};