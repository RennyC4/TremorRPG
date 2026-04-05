//
// NPC Menus for dialogue / buying / selling etc are handled here
//

void() User_NPCDialogue =
{
	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
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

	float buysell = getstatf(STAT_VENDOR);
	if (buysell == 1)
		my_button("npc_buy", newpos, [85, 22.5], "Buy / Sell") ? sendevent("PlayerShowBuySell", "") : 0;
	else if (buysell == 2)
		my_button("npc_bank", newpos, [85, 22.5], "Banking") ? sendevent("PlayerShowBanking", "") : 0;
	else if (buysell == 3)
		my_button("npc_wood", newpos, [85, 22.5], "Sell Lumber") ? sendevent("PlayerSellLumber", "") : 0;

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

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X") ? sendevent("ShutDownMenus", "") : 0;

	sui_pop_frame();
};

void() User_NPCBuySell =
{
	float disp_gold =  getstatf(STAT_GOLD);

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
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
	newpos_x -= 3.5;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	displaystat = strcat("^1", npc_name);
	sui_text(newpos, MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// Bottom buttons
	newpos_x += 3.25;
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
			j = strcat("s_", inventory[i]);
			desc = strcat("desc_", string_remove_spaces(inventory[i]));

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

// Character banking screens
string BANK_AMOUNT;
void() User_NPCBanking =
{
	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	vector pos = [0, 0];
	vector size = [360, 160];

	// line
	vector drawline_pos;
	float line_length = 118;
	drawline_pos = [25, 25];

	float disp_gold = getstatf(STAT_GOLD);
	float disp_gold_bank = getstatf(STAT_GOLD_BANK);

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);

	sui_text([0, 0], MENU_TEXT_LARGE, "Banking", MENU_TEXT_MEDIUM, 1, 0);
	sui_line(pos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1); // draw silly line

	// Draw player vs bank gold
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	pos = [0, -30];
	string player_gold = strcat("Your gold: ", ftos(disp_gold));
	string player_gold_bank = strcat("Stored gold: ", ftos(disp_gold_bank));

	sui_text(pos, MENU_TEXT_SMALL, player_gold, MENU_TEXT_MEDIUM, 1, 0);
	pos_y += 10;
	sui_text(pos, MENU_TEXT_SMALL, player_gold_bank, MENU_TEXT_MEDIUM, 1, 0);
	//

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	pos = [5,0];
	sui_text(pos, MENU_TEXT_MEDIUM, "Amount:", MENU_TEXT_1, 1, 0);

	pos = [75,0];
	// input box for numbers
	sui_fill(pos, '240 25 0', MENU_BG_DARK, 0.75, 0);
	text_input_control("gold_deposit", pos, [240, 25], 31, BANK_AMOUNT, cursor, FALSE);
	sui_border_box(pos, '240 25 0', 2, MENU_BORDER, 0.3, 0);

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	pos_y += 25;
	my_button("bank_deposit", [pos_x, pos_y], [240 / 2, 20], "Deposit") ? sendevent("User_BankDeposit", "s", BANK_AMOUNT) : 0;
	my_button("bank_withdraw", [pos_x+120, pos_y], [240 / 2, 20], "Withdraw") ? sendevent("User_BankWithdraw", "s", BANK_AMOUNT) : 0;

	// all buttons
	pos_y += 20;
	
	my_button("bank_deposit_all", [pos_x, pos_y], [240 / 2, 20], "Desposit All") ? sendevent("User_BankDepositAll", "s", BANK_AMOUNT) : 0;
	my_button("bank_withdraw_all", [pos_x+120, pos_y], [240 / 2, 20], "Withdraw All") ? sendevent("User_BankWithdrawAll", "s", BANK_AMOUNT) : 0;

	pos_y += 25;

	// Leave button & X button
	pos = [0,0];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button("npc_leave", pos, [50, 22.5], "Leave") ? sendevent("ShutDownMenus", "") : 0;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X") ? sendevent("ShutDownMenus", "") : 0;

	// Dialogue button
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("npc_talk", pos, [50, 22.5], "Dialogue") ? sendevent("PlayerShowDialogue", "") : 0;
};