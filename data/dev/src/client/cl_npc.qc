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

		// Manual newline
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

		if (UI(stringwidth(StripColors(test), 1)) <= max_width)
		{
			line = test;
			continue;
		}

		// Overflow. Find the last space.
		float split = -1;
		float j;

		for (j = strlen(line) - 1; j >= 0; j--)
		{
			if (substring(line, j, 1) == " ")
			{
				split = j;
				break;
			}
		}

		if (split >= 0)
		{
			string left  = substring(line, 0, split);
			string right = substring(line, split + 1,
                         strlen(line) - split - 1);
			//string right = substring(line, split + 1, strlen(line));

			sui_text(pos, MENU_TEXT_SMALL, left, MENU_TEXT_1, 1, 0);

			lines += 1;
			pos_y += UI(10);

			// Start next line with the text after the split.
			line = right;

			// Re-process the current character on the new line.
			i--;
		}
		else
		{
			// No spaces at all, hard wrap.
			sui_text(pos, MENU_TEXT_SMALL, line, MENU_TEXT_1, 1, 0);

			lines += 1;
			pos_y += UI(10);

			line = "";

			// Re-process current character.
			i--;
		}
	}

	if (line != "")
	{
		sui_text(pos, MENU_TEXT_SMALL, line, MENU_TEXT_1, 1, 0);
		lines += 1;
	}

	return lines;
};

//
// Quest Preview Window
//

void() User_NPCQuestPreview =
{
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	//
	// FRAME
	//

	vector pos = [UI(0), UI(0)];
	vector size = [UI(450), UI(350)];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.85, 0);
	sui_border_box([0, 0], size, UI(2), MENU_BORDER, 0.3, 0);

	//
	// HEADER
	//

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([UI(5), UI(5)], MENU_TEXT_MEDIUM, strcat("^2Quest: ^7", quest_preview_name), MENU_TEXT_1, 1, 0);

	//
	// QUEST DESCRIPTION PANEL
	//

	vector panel_pos = [UI(5), UI(40)];
	vector panel_size = [size_x - UI(10), UI(145)];

	sui_border_box(panel_pos, panel_size, UI(2), MENU_BORDER, 0.3, 0);
	sui_fill(panel_pos, panel_size, MENU_BG_DARK, 0.75, 0);

	//
	// DESCRIPTION TEXT
	//

	sui_push_frame(panel_pos, panel_size);
	sui_clip_to_frame();

	vector text_pos = [UI(5), UI(5)];
	float max_width = 38 * UI_Scale();

	float used = UI_DrawWrappedText(text_pos, max_width, quest_preview_description);

	text_pos_y += used * UI(10);

	//
	// OBJECTIVE
	//

	text_pos_y += UI(8);

	UI_DrawWrappedText(text_pos, max_width, strcat("^3Objective:^7 ", quest_preview_objective));

	sui_reset_clip();
	sui_pop_frame();

	//
	// REWARDS PANEL
	//

	vector reward_pos = [UI(5), UI(195)];
	vector reward_size = [size_x - UI(10), UI(70)];

	sui_border_box(reward_pos, reward_size, UI(2), MENU_BORDER, 0.3, 0);
	sui_fill(reward_pos, reward_size, MENU_BG_DARK, 0.75, 0);

	sui_text([UI(10), UI(200)], MENU_TEXT_SMALL, "^5Rewards", MENU_TEXT_1, 1, 0);

	//
	// REWARD TEXT
	//

	vector reward_text_pos = [UI(10), UI(220)];
	sui_text(reward_text_pos, MENU_TEXT_SMALL, strcat("^7Experience: ^2", ftos(quest_preview_reward_exp)), MENU_TEXT_1, 1, 0);

	reward_text_pos_y += UI(12);

	sui_text(reward_text_pos, MENU_TEXT_SMALL, strcat("^7Gold: ^3", ftos(quest_preview_reward_gold)), MENU_TEXT_1, 1, 0);

	if (quest_preview_reward_item != "")
	{
		reward_text_pos_y += UI(12);

		string item_text;
		item_text = strcat("^7Item: ^5", quest_preview_reward_item);

		if (quest_preview_reward_item_count > 1)
			item_text = strcat(item_text, " x", ftos(quest_preview_reward_item_count));

		sui_text(reward_text_pos, MENU_TEXT_SMALL, item_text, MENU_TEXT_1, 1, 0);
	}

	//
	// LEVEL REQUIREMENT
	//

	sui_text([UI(300), UI(200)], MENU_TEXT_SMALL, strcat("^7Level: ^3", ftos(quest_preview_level)), MENU_TEXT_1, 1, 0);

	//
	// BUTTONS
	//

	vector btn_size = [UI(90), UI(25)];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	if (my_button("quest_accept", [UI(5), UI(-5)], btn_size, "Accept", ""))
	{
		sendevent("QuestAccept", "s", quest_preview_id);
		localsound("q_acpt.wav");

		quest_preview_description = "";
	}

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);

	if (my_button("quest_decline", [UI(-5), UI(-5)], btn_size, "Decline", ""))
	{
		sendevent("QuestPreviewCancel", "");
		localsound("menu/menu_next.wav");
	}

	sui_pop_frame();
};

void() User_NPCDialogue =
{
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	//
	// FRAME
	//

	vector pos = [UI(0), UI(0)];
	vector size = [UI(450), UI(375)];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, UI(2), MENU_BORDER, 0.3, 0);

	//
	// HEADER
	//

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([UI(2.5), UI(2.5)], MENU_TEXT_MEDIUM, strcat("^1", npc_name), MENU_TEXT_1, 1, 0);

	//
	// BUTTONS
	//

	vector btn_small = [UI(50), UI(22.5)];
	vector btn_large = [UI(85), UI(22.5)];

	//
	// BOTTOM BUTTONS
	//

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	if (my_button("npc_leave", [UI(2.5), UI(-2.5)], btn_small, "Leave", ""))
		sendevent("ShutDownMenus", "");

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);

	float buysell = getstatf(STAT_VENDOR);
	if (buysell == 1)
	{
		if (my_button("npc_buy", [UI(-2.5), UI(-2.5)], btn_large, "Buy / Sell", ""))
			sendevent("PlayerShowBuySell", "");
	}
	else if (buysell == 2)
	{
		if (my_button("npc_bank", [UI(-2.5), UI(-2.5)], btn_large, "Banking", ""))
			sendevent("PlayerShowBanking", "");
	}
	else if (buysell == 3)
	{
		if (my_button("npc_wood", [UI(-2.5), UI(-2.5)], btn_large, "Sell Lumber", ""))
			sendevent("PlayerSellLumber", "");
	}

	//
	// DIALOGUE PANEL
	//

	vector dialogue_pos;
	vector dialogue_size;

	dialogue_pos = [UI(2.5), UI(25)];
	dialogue_size_x = size_x - UI(5);
	dialogue_size_y = UI(130);

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(dialogue_pos, dialogue_size, UI(2), MENU_BORDER, 0.3, 0);

	sui_fill(dialogue_pos, dialogue_size, MENU_BG_DARK, 0.75, 0);

	//
	// DIALOGUE TEXT
	//

	sui_push_frame(dialogue_pos, dialogue_size);
	sui_clip_to_frame();

	vector linepos;
	linepos = [UI(2.5), UI(2.5)];

	float max_width;
	max_width = 36 * UI_Scale();

	float i;
	float numlines;
	numlines = tokenizebyseparator(npc_dialogue, "\n");

	for (i = 0; i < numlines; i++)
	{
		string line;
		line = argv(i);

		float used;
		used = UI_DrawWrappedText(linepos, max_width, line);

		linepos_y += used * UI(10);
		linepos_y += UI(5);
	}

	sui_reset_clip();
	sui_pop_frame();

	//
	// QUEST PANEL
	//

	float quest_count;

	quest_count = npc_available_count + npc_turnin_count;
	if (quest_count > 0)
	{
		vector quest_pos;
		vector quest_size;

		quest_pos = [UI(2.5), UI(165)];

		quest_size_x = size_x - UI(5);
		quest_size_y = UI(150);

		sui_border_box(quest_pos, quest_size, UI(2), MENU_BORDER, 0.3, 0);
		sui_fill(quest_pos, quest_size, MENU_BG_DARK, 0.75, 0);

		//
		// QUEST LIST
		//

		vector item_pos;
		sui_list_view_begin("npc_quest_list", [quest_pos_x + UI(2), quest_pos_y + UI(2)], [quest_size_x - UI(4), quest_size_y - UI(4)], [UI(180), UI(25)], quest_count, npc_quest_scroll, [UI(8), UI(8)]);

		while ((i = sui_list_item(item_pos)) >= 0)
		{
			//
			// AVAILABLE QUESTS
			//

			if (i < npc_available_count)
			{
				if (my_button(strcat("npc_offer_", ftos(i)), item_pos, [UI(180), UI(22.5)], strcat("^2! ^7", npc_available_name[i]), ""))
				{
					localsound("menu/menu_next.wav");
					sendevent("QuestPreview", "s", npc_available_id[i]);
				}
			}

			//
			// TURN INS
			//

			else
			{
				float turn_index;
				turn_index = i - npc_available_count;

				if (my_button(strcat("npc_turnin_", ftos(turn_index)), item_pos, [UI(180), UI(22.5)], strcat("^3?^7 ", npc_turnin_name[turn_index]), ""))
				{
					localsound("q_acpt.wav");
					sendevent("QuestTurnIn", "s", npc_turnin_id[turn_index]);
				}
			}
		}

		sui_list_view_end();
	}

	//
	// CLOSE BUTTON
	//

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
			string desc = strcat("desc/", string_remove_spaces(item));

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
			string desc = strcat("desc/", string_remove_spaces(item));

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