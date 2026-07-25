//
// Estimate string width for drawstring alignment
//

float(string text, float size) UI_StringWidth =
{
    float i;
    float width;

    width = 0;

    for (i = 0; i < strlen(text); i++)
    {
        //
        // Skip Quake color codes
        //

        if (substring(text, i, 1) == "^")
        {
            i++;
            continue;
        }

        //
        // Quake console font is roughly 8 pixels per character
        //

        width += size * 0.5;
    }

    return width;
};

//
// Quest Log Screen
//

void() User_QuestLogScreen =
{
    float hp = getstatf(STAT_HEALTH);

    if (hp <= 0)
        return;

    //
    // Background
    //

    vector scrsz = [g_width, g_height];
    drawfill('0 0', scrsz, '0 0 0', 0.65);

    //
    // Main Window
    //

    vector pos = [0,0];
    vector size = [UI(450), UI(325)];

    sui_set_align([SUI_ALIGN_CENTER,SUI_ALIGN_CENTER]);
    sui_push_frame(pos,size);

    sui_fill([0,0], size, MENU_BG, 0.75,0);
    sui_border_box([0,0], size,2,MENU_BORDER,0.3,0);

    //
    // Safety selection
    //

    if (quest_selected >= quest_count)
        quest_selected = 0;

    //
    // Title
    //

    sui_set_align([SUI_ALIGN_CENTER,SUI_ALIGN_START]);
    sui_text([0,UI(5)], MENU_TEXT_MEDIUM * UI_TextScale(), "^2Quest Log", MENU_TEXT_1, 1, 0);

    //
    // LEFT PANEL
    //

    vector list_pos = [UI(10),UI(35)];
    vector list_size = [UI(150),UI(250)];

    sui_set_align([SUI_ALIGN_START,SUI_ALIGN_START]);

    sui_push_frame(list_pos,list_size);

    sui_fill([0,0],list_size,MENU_BG_DARK,0.5,0);
    sui_border_box([0,0],list_size,1,MENU_BORDER,0.3,0);

    //
    // Header
    //

    sui_text([UI(5),UI(5)], MENU_TEXT_SMALL * UI_TextScale(), strcat("^5Quests (",ftos(quest_count),")"), MENU_TEXT_1, 1, 0);

    vector row = [UI(5),UI(22)];
    float i;

    for (i = 0; i < quest_count; i++)
    {
        string color;

		switch(quest_log[i].status)
		{
			case QUEST_ACTIVE:
				color = "^3"; // Yellow - in progress
				break;

			case QUEST_COMPLETE:
				color = "^2"; // Green - completed
				break;

			case QUEST_AVAILABLE:
				color = "^5"; // Blue (or keep your current choice)
				break;

			default:
				color = "^7"; // White
		}

        //
        // Highlight selected quest
        //

        if (i == quest_selected)
            sui_fill(row-[UI(2),UI(1)], [UI(140),UI(13)], '0.35 0.3 0', 0.5, 0);

        my_button(strcat("quest_",ftos(i)), row, [UI(140),UI(12)], strcat(color,quest_log[i].name), "") ? quest_selected = i : 0;
        row_y += UI(14);
    }

    sui_pop_frame();

    //
    // RIGHT PANEL
    //

    vector detail_pos = [UI(170),UI(35)];
    vector detail_size = [UI(265),UI(250)];

    sui_push_frame(detail_pos,detail_size);

    sui_fill([0,0],detail_size,MENU_BG_DARK,0.5,0);
    sui_border_box([0,0],detail_size,1,MENU_BORDER,0.3,0);

    if (quest_count > 0 && quest_selected < quest_count)
    {
        struct questinfo q = quest_log[quest_selected];
        vector text = [UI(8),UI(6)];

        sui_set_align([SUI_ALIGN_START,SUI_ALIGN_START]);

        //
        // Quest name
        //

        sui_text(text, MENU_TEXT_MEDIUM * UI_TextScale(), strcat("^5",q.name), MENU_TEXT_1, 1, 0);
        text_y += UI(18);

        //
        // Divider
        //

        sui_fill([UI(5),text_y], [UI(250),1], MENU_BORDER, 0.5, 0);
        text_y += UI(8);

        //
        // Status
        //

        string status;
        string status_color;

        switch(q.status)
        {
            case QUEST_ACTIVE:
                status = "In Progress";
                status_color = "^3";
                break;

            case QUEST_COMPLETE:
                status = "Complete";
                status_color = "^2";
                break;

            case QUEST_AVAILABLE:
                status = "Available";
                status_color = "^5";
                break;

            default:
                status = "Unknown";
                status_color = "^7";
        }

        sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Status: ",status_color,status), MENU_TEXT_1, 1, 0);
        text_y += UI(14);

        //
        // Objective
        //

        if (q.status == QUEST_COMPLETE)
			sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Objective: ", "^2", q.objective), MENU_TEXT_1, 1, 0);
		else
			sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Progress: ", ftos(q.progress), " / ", ftos(q.needed)), MENU_TEXT_1, 1, 0);

        text_y += UI(18);

        //
        // Description
        //

		float desc_lines;
		desc_lines = UI_DrawWrappedText(text, UI(22), q.description);
		text_y += desc_lines * UI(10);
		text_y += UI(55);

        //
        // Rewards
        //

        sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), "^6Rewards", MENU_TEXT_1, 1, 0);
        text_y += UI(14);

        sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7EXP: ^2",ftos(q.reward_exp)), MENU_TEXT_1, 1, 0);
        text_y += UI(12);

        sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Gold: ^3",ftos(q.reward_gold)), MENU_TEXT_1, 1, 0);
        if (q.reward_item != "")
        {
            text_y += UI(12);
            sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Item: ^5", q.reward_item, " x", ftos(q.reward_item_count)), MENU_TEXT_1, 1, 0);
        }
    }

    sui_pop_frame();

    //
    // Close
    //

    sui_set_align([SUI_ALIGN_END,SUI_ALIGN_START]);
    my_button("close", [0,0], [UI(15),UI(15)], "X", "") ? sendevent("ShutDownMenus",""): 0;

    sui_pop_frame();
};

//
// Quest Accepted Notification
//

void() Draw_QuestAccepted =
{
	if (quest_notify_time <= time)
		return;

	float alpha;

	if (quest_notify_time - time < 1)
		alpha = quest_notify_time - time;
	else
		alpha = 1;

	vector size;
	size_x = UI(300);
	size_y = UI(200);

	vector pos;
	pos_x = (g_width - size_x) * 0.5;
	pos_y = UI(75);

	drawpic(pos, quest_notify_image, size, '1 1 1', alpha, 0);

	//
	// Notification text
	//

	string text;
	float width;
	vector textpos;

	text = strcat("Accepted ^3", quest_notify_name);

	width = UI_StringWidth(text, UI(16));

	textpos_x = pos_x + (size_x - width) * 0.5;
	textpos_y = pos_y + size_y + UI(8);

	drawstring(textpos, text, '16 16 0', '1 1 1', alpha, 0);
};

//
// Quest Completion Notification
//

void() Draw_QuestComplete =
{
	if (quest_complete_time <= time)
		return;

	float alpha;

	if (quest_complete_time - time < 1)
		alpha = quest_complete_time - time;
	else
		alpha = 1;

	vector size;
	size_x = UI(300);
	size_y = UI(200);

	vector pos;
	pos_x = (g_width - size_x) * 0.5;
	pos_y = UI(75);

	drawpic(pos, "progs/q_cmplt.png", size, '1 1 1', alpha, 0);

	//
	// Notification text
	//

	string text;
	float width;
	vector textpos;

	text = strcat("Completed ^3", quest_complete_name);

	width = UI_StringWidth(text, UI(16));

	textpos_x = pos_x + (size_x - width) * 0.5;
	textpos_y = pos_y + size_y + UI(8);

	drawstring(textpos, text, '16 16 0', '1 1 1', alpha, 0);
};

//
// Quest Tracker Update
//

float quest_tracker_alpha[64];
float quest_tracker_target[64];
float quest_tracker_collapsed;

void() QuestTracker_Update =
{
    float i;
    float speed;

    speed = frametime * 6;

    for (i = 0; i < quest_count; i++)
    {
        if (quest_log[i].status == QUEST_ACTIVE ||
            quest_log[i].status == QUEST_COMPLETE)
            quest_tracker_target[i] = 1;
        else
            quest_tracker_target[i] = 0;

        if (quest_tracker_alpha[i] < quest_tracker_target[i])
        {
            quest_tracker_alpha[i] += speed;

            if (quest_tracker_alpha[i] > 1)
                quest_tracker_alpha[i] = 1;
        }

        if (quest_tracker_alpha[i] > quest_tracker_target[i])
        {
            quest_tracker_alpha[i] -= speed;

            if (quest_tracker_alpha[i] < 0)
                quest_tracker_alpha[i] = 0;
        }
    }
};

//
// Quest Tracker
//

void() Draw_QuestTracker =
{
	float quest_tracker_enabled = TRUE;

    float quest_tracker_width = UI(180);
    float quest_tracker_padding = UI(6);

    float i;
    float y;
    float visible;
    float needed;
    float alpha;
    float offset;

    vector pos;
    vector size;

    string color;
    string progress;

    if (!quest_tracker_enabled)
        return;

    //
    // Count visible quests
    //

    visible = 0;
    for (i = 0; i < quest_count; i++)
    {
        if (quest_tracker_alpha[i] > 0)
            visible++;
    }

    if (!visible)
        return;

    //
    // Dynamic panel size
    //

    size_x = quest_tracker_width;

	if (quest_tracker_collapsed)
		size_y = UI(20);
	else
		size_y = UI(30) + (visible * UI(38));

    pos_x = g_width - size_x - UI(8);
    pos_y = UI(180);

    drawfill(pos, size, '0 0 0', 0.25);

    drawstring(pos + [quest_tracker_padding, UI(8), 0], "^3Quests", MENU_TEXT_SMALL, '1 1 1', 1, 0);

	//
	// Collapse button
	//

	string collapse_text;

	if (quest_tracker_collapsed)
		collapse_text = " + ";
	else
		collapse_text = " - ";

	my_button("quest_tracker_collapse", pos + [size_x - UI(28), UI(4)], [UI(20), UI(12)], collapse_text, "") ? quest_tracker_collapsed = !quest_tracker_collapsed : 0;

    y = UI(28);

	if (quest_tracker_collapsed)
		return;

    //
    // PASS 1
    // Draw ACTIVE quests first
    //

    for (i = 0; i < quest_count; i++)
    {
        if (quest_log[i].status != QUEST_ACTIVE)
            continue;

        alpha = quest_tracker_alpha[i];

        if (alpha <= 0)
            continue;

        offset = (1 - alpha) * UI(10);

        drawstring(pos + [quest_tracker_padding + offset, y, 0], strcat("^7", quest_log[i].name), MENU_TEXT_SMALL, '1 1 1', alpha, 0);

        y += UI(16);

        needed = quest_log[i].needed;
        if (needed < 1)
            needed = 1;

        color = "^3";

		progress = strcat(color, quest_log[i].objective, " ", ftos(rint(quest_log[i].progress)), " / ", ftos(rint(needed)));

        drawstring(pos + [quest_tracker_padding + UI(14) + offset, y, 0], progress, MENU_TEXT_SMALL, '1 1 1', alpha, 0);

        y += UI(22);
    }

    //
    // PASS 2
    // Draw COMPLETED quests
    //

    for (i = 0; i < quest_count; i++)
    {
        if (quest_log[i].status != QUEST_COMPLETE)
            continue;

        alpha = quest_tracker_alpha[i];

        if (alpha <= 0)
            continue;

        offset = (1 - alpha) * UI(10);

        drawstring(pos + [quest_tracker_padding + offset, y, 0], strcat("^2", quest_log[i].name), MENU_TEXT_SMALL, '1 1 1', alpha, 0);

        y += UI(16);

        drawstring(pos + [quest_tracker_padding + UI(14) + offset, y, 0], strcat("^2", quest_log[i].objective), MENU_TEXT_SMALL, '1 1 1', alpha, 0);

        y += UI(22);
    }
};