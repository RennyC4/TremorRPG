//
// NPC Menus for dialogue / buying / selling etc are handled here
//

float(vector startpos, float max_width, string text) UI_DrawWrappedText =
{
	vector pos = startpos;

	float len = strlen(text);
	float i;

	string line = "";
	float lines = 0;

	for (i = 0; i < len; i++)
	{
		string ch = substring(text, i, 1);

		// handle manual newline
		if (ch == "\n")
		{
			if (line != "")
			{
				sui_text(pos, MENU_TEXT_SMALL, line, MENU_TEXT_1, 1, 0);
				lines += 1;
				pos_y += UI(10);
				line = "";
			}
			continue;
		}

		string test = strcat(line, ch);

		string clean = StripColors(test);
		float w = UI(stringwidth(clean, 1));

		if (w > max_width && line != "")
		{
			// 🔥 try to break at last space
			float j;
			float split = -1;

			for (j = strlen(line) - 1; j >= 0; j--)
			{
				if (substring(line, j, 1) == " ")
				{
					split = j;
					break;
				}
			}

			if (split > 0)
			{
				string left  = substring(line, 0, split);
				string right = substring(line, split + 1, strlen(line));

				sui_text(pos, MENU_TEXT_SMALL, left, MENU_TEXT_1, 1, 0);

				lines += 1;
				pos_y += UI(10);

				line = strcat(right, ch);
			}
			else
			{
				// no space found, hard break
				sui_text(pos, MENU_TEXT_SMALL, line, MENU_TEXT_1, 1, 0);

				lines += 1;
				pos_y += UI(10);

				line = ch;
			}
		}
		else
		{
			line = test;
		}
	}

	if (line != "")
	{
		sui_text(pos, MENU_TEXT_SMALL, line, MENU_TEXT_1, 1, 0);
		lines += 1;
	}

	return lines;
};

void() User_NPCDialogue =
{
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	// FRAME
	vector pos = [UI(0), UI(0)];
	vector size = [UI(450), UI(325)];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, UI(2), MENU_BORDER, 0.3, 0);

	// HEADER
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([UI(2.5), UI(2.5)], MENU_TEXT_MEDIUM, strcat("^1", npc_name), MENU_TEXT_1, 1, 0);

	// BUTTONS
	vector btn_small = [UI(50), UI(22.5)];
	vector btn_large = [UI(85), UI(22.5)];

	// LEFT (Leave)
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	if (my_button("npc_leave", [UI(2.5), UI(-2.5)], btn_small, "Leave", ""))
		sendevent("ShutDownMenus", "");

	// RIGHT (Buy/Sell/etc)
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);

	float buysell = getstatf(STAT_VENDOR);

	if (buysell == 1)
	{
		if (my_button("npc_buy", [UI(-2.5), UI(-2.5)], btn_large, "Buy / Sell", ""))
			sendevent("PlayerShowBuySell", "");
	}
	else if (buysell == 2)
	{
		if (my_button("npc_bank", [UI(2.5), UI(2.5)], btn_large, "Banking", ""))
			sendevent("PlayerShowBanking", "");
	}
	else if (buysell == 3)
	{
		if (my_button("npc_wood", [UI(2.5), UI(2.5)], btn_large, "Sell Lumber", ""))
			sendevent("PlayerSellLumber", "");
	}

	// CHAT PANEL
	vector panel_pos = [UI(2.5), UI(25)];
	vector panel_size = size - [UI(5), UI(50)];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(panel_pos, panel_size, UI(2), MENU_BORDER, 0.3, 0);
	sui_fill(panel_pos, panel_size, MENU_BG_DARK, 0.75, 0);

	// TEXT AREA (WITH CLIPPING)
	sui_push_frame(panel_pos, panel_size);
	sui_clip_to_frame();

	vector linepos = [UI(2.5), UI(2.5)];

	float max_width = panel_size_x - UI(5);

	float i, numlines;
	numlines = tokenizebyseparator(npc_dialogue, "\n");

	for (i = 0; i < numlines; i++)
	{
		string line = argv(i);

		float used = UI_DrawWrappedText(linepos, max_width, line);

		linepos_y += used * UI(10); // 🔥 real height
		linepos_y += UI(5);         // paragraph spacing
	}

	sui_reset_clip();
	sui_pop_frame();

	// CLOSE BUTTON
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	if (my_button("close", [UI(0), UI(0)], [UI(15), UI(15)], "X", ""))
		sendevent("ShutDownMenus", "");

	sui_pop_frame();
};

void() User_NPCBuySell =
{
	float disp_gold = getstatf(STAT_GOLD);

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	// =================
	// FRAME
	// =================
	vector pos;
	pos_x = UI(0);
	pos_y = UI(0);

	vector size;
	size_x = UI(450);
	size_y = UI(325);

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, UI(2), MENU_BORDER, 0.3, 0);

	// =================
	// HEADER
	// =================
	vector base;
	base_x = UI(2.5);
	base_y = UI(2.5);

	// Player name (left)
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(base, MENU_TEXT_MEDIUM, strcat("^2", LOGIN_NAME), MENU_TEXT_1, 1, 0);

	// NPC name (right)
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	vector npcpos;
	npcpos = base;
	npcpos_x += UI(-3.5);

	sui_text(npcpos, MENU_TEXT_MEDIUM, strcat("^1", npc_name), MENU_TEXT_1, 1, 0);

	// Gold
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
	vector goldpos;
	goldpos = base;
	goldpos_y += UI(-15);

	sui_text(goldpos, MENU_TEXT_SMALL,
		strcat("^3Gold: ", ftos(disp_gold)), MENU_TEXT_1, 1, 0);

	// =================
	// BOTTOM BUTTONS
	// =================
	vector btnpos;
	btnpos_x = UI(2.5);
	btnpos_y = UI(-2.5);

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	vector btn_size_small;
	btn_size_small_x = UI(50);
	btn_size_small_y = UI(22.5);

	my_button("npc_leave", btnpos, btn_size_small, "Leave", "")
		? sendevent("ShutDownMenus", "") : 0;

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);

	vector talkpos;
	talkpos = btnpos;
	talkpos_x += UI(-5);

	vector btn_size_large;
	btn_size_large_x = UI(85);
	btn_size_large_y = UI(22.5);

	my_button("npc_talk", talkpos, btn_size_large, "Dialogue", "")
		? sendevent("PlayerShowDialogue", "") : 0;

	// =================
	// PANELS
	// =================
	vector panel_pos;
	panel_pos_x = UI(2.5);
	panel_pos_y = UI(25);

	vector panel_size;
	panel_size = size;
	panel_size_x = panel_size_x / 2;
	panel_size_x -= UI(5);
	panel_size_y -= UI(50);

	// -----------------
	// PLAYER INVENTORY
	// -----------------
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(panel_pos, panel_size, UI(2), MENU_BORDER, 0.3, 0);
	sui_fill(panel_pos, panel_size, MENU_BG_DARK, 0.75, 0);

	vector linepos;
	linepos = panel_pos;

	vector buttonpos;
	buttonpos = panel_pos;
	buttonpos_x += panel_size_x - UI(35);

	float i;
	for (i = 0; i < inv_count; i++)
	{
		if (inventory_count[i] > 0)
		{
			string item = inventory[i];
			string item_disp = strcat("^5", item, " ^7[^2", ftos(inventory_count[i]), "^7]");
			string btn_id = strcat("s_", item);
			string desc = strcat("desc_", string_remove_spaces(item));

			vector sell_size;
			sell_size_x = UI(32);
			sell_size_y = UI(10);

			my_button(btn_id, buttonpos, sell_size, "Sell", "")
				? sendevent("PlayerSellItem", "s", item) : 0;

			float w = stringwidth(item, 1);

			vector tip_size;
			tip_size_x = UI(w * 8);
			tip_size_y = UI(8);

			sui_tooltip(desc, linepos, tip_size, item_disp);
		}

		linepos_y   += UI(10);
		buttonpos_y += UI(10);
	}

	// -----------------
	// NPC INVENTORY
	// -----------------
	vector npc_panel_pos;
	npc_panel_pos = panel_pos;
	npc_panel_pos_x += panel_size_x + UI(5);

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(npc_panel_pos, panel_size, UI(2), MENU_BORDER, 0.3, 0);
	sui_fill(npc_panel_pos, panel_size, MENU_BG_DARK, 0.75, 0);

	linepos = npc_panel_pos;
	buttonpos = npc_panel_pos;
	buttonpos_x += panel_size_x - UI(25);

	for (i = 0; i < npc_inv_count; i++)
	{
		if (npc_inventory_gold[i] > 0)
		{
			string item = npc_inventory[i];
			string item_disp = strcat("^5", item, " ^7- ^3", ftos(npc_inventory_gold[i]), "^7g");
			string btn_id = strcat("b_", item);
			string desc = strcat("desc_", string_remove_spaces(item));

			vector buy_size;
			buy_size_x = UI(25);
			buy_size_y = UI(10);

			my_button(btn_id, buttonpos, buy_size, "Buy", "")
				? sendevent("PlayerBuyItem", "sf", item, npc_inventory_gold[i]) : 0;

			float w = stringwidth(item, 1);

			vector tip_size;
			tip_size_x = UI(w * 8);
			tip_size_y = UI(8);

			sui_tooltip(desc, linepos, tip_size, item_disp);
		}

		linepos_y   += UI(10);
		buttonpos_y += UI(10);
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
	my_button("bank_deposit", [pos_x, pos_y], [240 / 2, 20], "Deposit", "") ? sendevent("User_BankDeposit", "s", BANK_AMOUNT) : 0;
	my_button("bank_withdraw", [pos_x+120, pos_y], [240 / 2, 20], "Withdraw", "") ? sendevent("User_BankWithdraw", "s", BANK_AMOUNT) : 0;

	// all buttons
	pos_y += 20;
	
	my_button("bank_deposit_all", [pos_x, pos_y], [240 / 2, 20], "Desposit All", "") ? sendevent("User_BankDepositAll", "s", BANK_AMOUNT) : 0;
	my_button("bank_withdraw_all", [pos_x+120, pos_y], [240 / 2, 20], "Withdraw All", "") ? sendevent("User_BankWithdrawAll", "s", BANK_AMOUNT) : 0;

	pos_y += 25;

	// Leave button & X button
	pos = [0,0];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button("npc_leave", pos, [50, 22.5], "Leave", "") ? sendevent("ShutDownMenus", "") : 0;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X", "") ? sendevent("ShutDownMenus", "") : 0;

	// Dialogue button
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("npc_talk", pos, [50, 22.5], "Dialogue", "") ? sendevent("PlayerShowDialogue", "") : 0;
};