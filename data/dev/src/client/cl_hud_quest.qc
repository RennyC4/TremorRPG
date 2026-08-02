//
// Estimate string width for drawstring alignment
//

float quest_visible_count;
float quest_visible_index[64];
float quest_abandon_confirm;
float quest_abandon_index;

string quest_objective_notify_name;
string quest_objective_notify_text;
float quest_objective_notify_time;

string quest_description_requested;

//
// Draw centered UI string
//

//
// String width for drawstring alignment
// Ignores Quake color codes
//

float(string text, float size) UI_StringWidth =
{
	float width;

	text = StripColors(text);
	width = strlen(text) * (size * 0.5);

	return width;
};

//
// Get string width ignoring Quake color codes
//

float(string str, float fontsize) UI_StringWidthClean =
{
	return UI_StringWidth(StripColors(str), fontsize);
};

//
// Draw centered UI string
//

void(vector center, string text, float fontsize, float alpha, float xoffset) UI_DrawCenteredString =
{
	float width;
	float chars;

	vector pos;

	width = UI_StringWidthClean(text, 16);

	//
	// Proportional font correction
	// Long strings need slightly less width
	//

	chars = strlen(StripColors(text));

	if (chars > 20)
		width *= 0.92;
	else if (chars > 10)
		width *= 0.96;


	pos_x = center_x - (width * 0.5) + xoffset;
	pos_y = center_y;

	drawstring(pos, text, [fontsize, fontsize, 0], '1 1 1', alpha, 0);
};

//
// Quest Log Screen
//

void() User_QuestLogScreen =
{
	float i;
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

	quest_visible_count = 0;

	for (i = 0; i < quest_count; i++)
	{
		if (quest_log[i].status == QUEST_LOCKED)
			continue;

		quest_visible_index[quest_visible_count] = i;
		quest_visible_count++;
	}

	if (quest_selected >= quest_visible_count)
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

	for (i = 0; i < quest_visible_count; i++)
	{
		float q;
		string color;

		q = quest_visible_index[i];

		switch(quest_log[q].status)
		{
			case QUEST_ACTIVE:
				color = "^3";
				break;

			case QUEST_COMPLETE:
				color = "^2";
				break;

			case QUEST_AVAILABLE:
				color = "^5";
				break;

			default:
				color = "^7";
		}

		if (q == quest_selected)
			sui_fill(row-[UI(2),UI(1)], [UI(140),UI(13)], '0.35 0.3 0', 0.5, 0);

		my_button(strcat("quest_",ftos(q)), row, [UI(140),UI(12)], strcat(color,quest_log[q].name), "") ? quest_selected = q : 0;

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

    if (quest_visible_count > 0 && quest_selected < quest_count)
	{
		float q;
		float objective;

		string status;
		string status_color;

		float desc_lines;

		q = quest_selected;

		//
		// Request description if we don't have it yet
		//

		if (quest_log[q].description == "")
		{
			if (quest_description_requested != quest_log[q].id)
			{
				sendevent("QuestDescription", "s", quest_log[q].id);
				quest_description_requested = quest_log[q].id;
			}
		}

		vector text = [UI(8),UI(6)];

		sui_set_align([SUI_ALIGN_START,SUI_ALIGN_START]);


		//
		// Quest name
		//

		sui_text(text, MENU_TEXT_MEDIUM * UI_TextScale(), strcat("^5", quest_log[q].name), MENU_TEXT_1, 1, 0);
		text_y += UI(18);

		//
		// Divider
		//

		sui_fill([UI(5),text_y], [UI(250),1], MENU_BORDER, 0.5, 0);
		text_y += UI(8);

		//
		// Status
		//

		switch(quest_log[q].status)
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

		sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Status: ", status_color, status), MENU_TEXT_1, 1, 0);

		text_y += UI(14);

		//
		// Objectives
		//

		sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), "^6Objectives", MENU_TEXT_1, 1, 0);

		text_y += UI(14);

		for (objective = 0; objective < quest_log[q].objective_count; objective++)
		{
			string objective_color;

			if (quest_log[q].objective_progress[objective] >= quest_log[q].objective_needed[objective])
				objective_color = "^2";
			else
				objective_color = "^3";

			sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat(objective_color, quest_log[q].objective_text[objective], " ^7", ftos(quest_log[q].objective_progress[objective]), "/", ftos(quest_log[q].objective_needed[objective])), MENU_TEXT_1, 1, 0);
			text_y += UI(14);
		}

		text_y += UI(6);

		//
		// Description
		//

		desc_lines = UI_DrawWrappedText(text, UI(22), quest_log[q].description);

		text_y += desc_lines * UI(10);
		text_y += UI(20);

		//
		// Rewards
		//

		sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), "^6Rewards", MENU_TEXT_1, 1, 0);

		text_y += UI(14);

		sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7EXP: ^2", ftos(quest_log[q].reward_exp)), MENU_TEXT_1, 1, 0);

		text_y += UI(12);

		sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Gold: ^3", ftos(quest_log[q].reward_gold)), MENU_TEXT_1, 1, 0);

		if (quest_log[q].reward_item != "")
		{
			text_y += UI(12);
			sui_text(text, MENU_TEXT_SMALL * UI_TextScale(), strcat("^7Item: ^5", quest_log[q].reward_item, " x", ftos(quest_log[q].reward_item_count)), MENU_TEXT_1, 1, 0);
		}
		
		//
		// Abandon Quest
		//

		if (quest_log[q].status == QUEST_ACTIVE)
			my_button("abandon_quest", [UI(80), detail_size_y - UI(25)], [UI(100), UI(16)], "^1Abandon", "") ? (quest_abandon_confirm = TRUE, quest_abandon_index = q) : 0;
	}

    sui_pop_frame();

	if (quest_abandon_confirm)
	{
		vector confirm_pos = [UI(100), UI(100)];
		vector confirm_size = [UI(250), UI(100)];

		sui_push_frame(confirm_pos, confirm_size);

		sui_fill([0,0], confirm_size, MENU_BG_DARK, 0.9, 0);
		sui_border_box([0,0], confirm_size, 1, MENU_BORDER, 0.5, 0);

		sui_set_align([SUI_ALIGN_CENTER,SUI_ALIGN_START]);

		sui_text([0,UI(10)], MENU_TEXT_SMALL * UI_TextScale(), "^1Abandon Quest?", MENU_TEXT_1, 1, 0);

		sui_text([0,UI(32)], MENU_TEXT_SMALL * UI_TextScale(), quest_log[quest_abandon_index].name, MENU_TEXT_1, 1, 0);

		sui_set_align([SUI_ALIGN_START,SUI_ALIGN_START]);

		my_button("abandon_yes", [UI(35),UI(65)], [UI(70),UI(16)], "^2Yes", "") ?
		(
			localsound("q_aban.wav"),
			sendevent("User_AbandonQuest", "s", quest_log[quest_abandon_index].id),
			quest_abandon_confirm = FALSE
		) : 0;

		my_button("abandon_no", [UI(145),UI(65)], [UI(70),UI(16)], "^7No", "") ?
			quest_abandon_confirm = FALSE : 0;

		sui_pop_frame();
	}

    //
    // Close
    //

    sui_set_align([SUI_ALIGN_END,SUI_ALIGN_START]);
	if (my_button("close", [0,0], [UI(15),UI(15)], "X", ""))
	{
		quest_description_requested = "";
		sendevent("ShutDownMenus","");
	}

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

	//
	// Notification graphic
	//

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

	vector center;
	float fontsize;

	fontsize = UI(16);

	center_x = pos_x + (size_x * 0.5);
	center_y = pos_y + size_y + UI(8);

	//
	// "Accepted"
	//

	UI_DrawCenteredString(center, "Accepted", fontsize, alpha, 0);

	//
	// Quest name
	//

	center_y += UI(18);

	UI_DrawCenteredString(center, strcat("^3", quest_notify_name), fontsize, alpha, 0);
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

	//
	// Notification graphic
	//

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

	vector center;
	float fontsize;

	fontsize = UI(16);

	center_x = pos_x + (size_x * 0.5);
	center_y = pos_y + size_y + UI(8);

	//
	// "Completed"
	//

	UI_DrawCenteredString(center, "Completed", fontsize, alpha, 0);

	//
	// Quest name
	//

	center_y += UI(18);

	UI_DrawCenteredString(center, strcat("^3", quest_complete_name), fontsize, alpha, 0);
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
	float alpha;
	float offset;
	float objective;

	vector pos;
	vector size;

	string color;
	string progress;
	string collapse_text;

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
	{
		size_y = UI(22);

		for (i = 0; i < quest_count; i++)
		{
			if (quest_tracker_alpha[i] <= 0)
				continue;

			if (quest_log[i].status != QUEST_ACTIVE &&
				quest_log[i].status != QUEST_COMPLETE)
				continue;

			size_y += UI(12);

			for (objective = 0; objective < quest_log[i].objective_count; objective++)
				size_y += UI(8);

			size_y += UI(8);
		}
	}

	pos_x = g_width - size_x - UI(8);
	pos_y = UI(180);

	pos = [pos_x, pos_y, 0];
	size = [size_x, size_y, 0];

	//
	// Background
	//

	drawfill(pos, size, '0 0 0', 0.25);

	//
	// Header
	//

	drawstring(pos + [quest_tracker_padding, UI(8), 0], "^3Quests", MENU_TEXT_SMALL, '1 1 1', 1, 0);

	//
	// Collapse button
	//

	if (quest_tracker_collapsed)
		collapse_text = " + ";
	else
		collapse_text = " - ";

	my_button("quest_tracker_collapse", pos + [size_x - UI(28), UI(4)], [UI(20), UI(12)], collapse_text, "") ? quest_tracker_collapsed = !quest_tracker_collapsed : 0;

	if (quest_tracker_collapsed)
		return;

	y = UI(22);

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

		y += UI(12);

		for (objective = 0; objective < quest_log[i].objective_count; objective++)
		{
			color = "^3";

			if (quest_log[i].objective_progress[objective] >= quest_log[i].objective_needed[objective])
				color = "^2";

			progress = strcat(color, quest_log[i].objective_text[objective], " ", ftos(rint(quest_log[i].objective_progress[objective])), " / ", ftos(rint(quest_log[i].objective_needed[objective])));

			drawstring(pos + [quest_tracker_padding + UI(14) + offset, y, 0], progress, MENU_TEXT_SMALL, '1 1 1', alpha, 0);

			y += UI(8);
		}

		y += UI(8);
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

		y += UI(12);

		for (objective = 0; objective < quest_log[i].objective_count; objective++)
		{
			drawstring(pos + [quest_tracker_padding + UI(14) + offset, y, 0], strcat("^2", quest_log[i].objective_text[objective]), MENU_TEXT_SMALL, '1 1 1', alpha, 0);
			y += UI(8);
		}

		y += UI(4);
	}
};

//
// Quest Objective Complete Notification
//

void() Draw_QuestObjectiveComplete =
{
	if (time >= quest_objective_notify_time)
		return;

	vector screen;
	screen_x = g_width;
	screen_y = g_height;

	float cx = screen_x * 0.5;
	float duration = 3;

	float t = (quest_objective_notify_time - time) / duration;
	t = bound(0, t, 1);

	float fade;
	if (t < 0.33)
		fade = t / 0.33;
	else
		fade = 1;

	string title = "Objective Complete";
	string msg = quest_objective_notify_text;

	vector title_size = '14 14 0';
	vector size = '16 16 0';

	float title_width = stringwidth(title, 0, title_size);
	float text_width = stringwidth(msg, 0, size);

	vector title_pos;
	title_pos_x = floor(cx - title_width * 0.5);
	title_pos_y = UI(55);

	vector pos;
	pos_x = floor(cx - text_width * 0.5);
	pos_y = UI(75);

	// Title shadow
	drawstring(title_pos + '2 2 0', title, title_size, '0 0 0', fade * 0.6, 0);

	// Title
	drawstring(title_pos, title, title_size, '1 1 1', fade, 0);

	// Objective shadow
	drawstring(pos + '2 0 0', msg, size, '0 0 0', fade * 0.6, 0);
	drawstring(pos + '-2 0 0', msg, size, '0 0 0', fade * 0.6, 0);
	drawstring(pos + '0 2 0', msg, size, '0 0 0', fade * 0.6, 0);
	drawstring(pos + '0 -2 0', msg, size, '0 0 0', fade * 0.6, 0);

	// Objective
	drawstring(pos, msg, size, '1 0.82 0.15', fade, 0);
};