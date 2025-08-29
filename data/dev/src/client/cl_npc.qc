//
// NPC Menus for dialogue / buying / selling etc are handled here
//

void() User_NPCDialogue =
{
	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	vector pos = [25, 25];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	// Display name
	vector newpos = [2.5, 2.5];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	string displaystat = strcat("^1", npc_name);
	sui_text(newpos, MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// Bottom buttons
	newpos_y -= 5;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button("npc_leave", newpos, [50, 22.5], "Leave") ? sendevent("ShutDownMenus", "") : 0;

	newpos_x -= 5;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("npc_buy", newpos, [85, 22.5], "Buy / Sell") ? sendevent("PlayerShowBuySell", "") : 0;

	// NPC chatter box
	newpos = [2.5, 0]; //reset newpos
	newpos_y += 25;
	size_x -= 5;
	size_y -= 50;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(newpos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(newpos, size, MENU_BG_DARK, 0.75, 0);

	// NPC chatter
	newpos = [2.5, 2.5]; //reset newpos
	newpos_y += 25;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	vector linepos = newpos;
	float i, numlines = 0;
	numlines = tokenizebyseparator(npc_dialogue, "\n");
	for (i = 0; i < numlines; i = i + 1)
	{
		string line = argv(i);
		sui_text(linepos, MENU_TEXT_SMALL, line, MENU_TEXT_1, 1, 0);
		linepos_y += 10;
	}

	sui_pop_frame();
};

void() User_NPCBuySell =
{
	float disp_gold =  getstatf(STAT_GOLD);

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	vector pos = [25, 25];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	// Display player name
	vector newpos = [2.5, 2.5];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	string displaystat = strcat("^2", LOGIN_NAME);
	sui_text(newpos, MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// Display Gold
	newpos_y -= 15;
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
	displaystat = strcat("^3Gold: ", ftos(disp_gold));
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	newpos = [2.5, 2.5]; // reset newpos

	// Display NPC name
	newpos_x -= 2.5;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	displaystat = strcat("^1", npc_name);
	sui_text(newpos, MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// Bottom buttons
	newpos_x += 2.5;
	newpos_y -= 5;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button("npc_leave", newpos, [50, 22.5], "Leave") ? sendevent("ShutDownMenus", "") : 0;

	newpos_x -= 5;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("npc_talk", newpos, [85, 22.5], "Dialogue") ? sendevent("PlayerShowDialogue", "") : 0;

	// Player Inventory
	size_x = size_x / 2;
	newpos = [2.5, 0]; //reset newpos
	newpos_y += 25;
	size_x -= 5;
	size_y -= 50;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(newpos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(newpos, size, MENU_BG_DARK, 0.75, 0);

	float i;
	string j = "";
	string desc = "";

	vector linepos = [2.5, 25];
	vector buttonpos = [-19, 25];
    for (i = 0; i < inv_count; i++)
    {
		float sellbutton_count = 0;
		string item_disp = strcat("^5", inventory[i], " ^7[^2", ftos(inventory_count[i]), "^7]");
		if (inventory_count[i] > 0)
		{
			while (sellbutton_count < npc_inv_count) // setup buy buttons
			{
				sellbutton_count += 1;
				j = strcat("s_", inventory[i]);
				desc = strcat("desc_", string_remove_spaces(inventory[i]));
			}
			//sui_text(linepos, MENU_TEXT_SMALL, item_disp, MENU_TEXT_1, 1, 0);

			sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
			my_button(j, buttonpos, [32, 10], "Sell") ? sendevent("PlayerSellItem", "s", inventory[i]) : 0;
			sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

			float hover_text_size = stringwidth(inventory[i], 1);
			sui_tooltip(desc, linepos, [hover_text_size * 8, 8], item_disp);
		}
		linepos_y += 10;
		buttonpos_y += 10; // move buy buttons down
    }

	// NPC Inventory
	newpos_x -= 5;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_border_box(newpos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(newpos, size, MENU_BG_DARK, 0.75, 0);

	linepos = [-25, 25];
	buttonpos = [15, 25];
    for (i = 0; i < npc_inv_count; i++)
    {
		float buybutton_count = 0;
		string item_disp = strcat("^5", npc_inventory[i], " ^7- ^3", ftos(npc_inventory_gold[i]), "^7g");
		if (npc_inventory_gold[i] > 0)
		{
			while (buybutton_count < npc_inv_count) // setup buy buttons
			{
				buybutton_count += 1;
				j = strcat("b_", npc_inventory[i]);
				desc = strcat("desc_", string_remove_spaces(npc_inventory[i])); // tooltip display
			}

			//sui_text(linepos, MENU_TEXT_SMALL, item_disp, MENU_TEXT_1, 1, 0);

			sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
			my_button(j, buttonpos, [25, 10], "Buy") ? sendevent("PlayerBuyItem", "sf", npc_inventory[i], npc_inventory_gold[i]) : 0;

			// tooltip
			sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
			float hover_text_size = stringwidth(npc_inventory[i], 1);
			sui_tooltip(desc, linepos, [hover_text_size * 8, 8], item_disp);

			sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
		}
		linepos_y += 10;
		buttonpos_y += 10; // move buy buttons down
    }

	sui_pop_frame();
};