//
// Inventory
//

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