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
	my_button("npc_leave", newpos, [50, 25], "Leave") ? sendevent("ShutDownMenus", "") : 0;

	// NPC chatter box
	newpos_y += 25;
	size_x -= 5;
	size_y -= 50;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(newpos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(newpos, size, MENU_BG_DARK, 0.75, 0);

	// NPC chatter
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