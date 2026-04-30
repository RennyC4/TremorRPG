// =====================
// BLUE THEME PALETTE
// =====================
vector MENU_BG            = '0.08 0.18 0.12'; // deep navy-teal background
vector MENU_BG_DARK       = '0.03 0.10 0.07'; // near-black blue tint

vector MENU_BORDER        = '0.20 0.55 0.90'; // bright azure edge
vector MENU_BUTTON        = '0.12 0.28 0.22'; // muted blue-green panel
vector MENU_BUTTON_BORDER = '0.25 0.65 1.00'; // glowing cyan border

vector MENU_TEXT_1        = '0.90 0.95 1.00'; // near-white cool text
vector MENU_TEXT_2        = '0.60 0.75 0.85'; // secondary soft blue text

vector MENU_HIGHLIGHT     = '0.35 0.80 1.00'; // hover glow cyan
vector MENU_DARKEN        = '0.05 0.12 0.20'; // overlay dim blue

// =====================
// TEXT SIZES
// =====================
vector MENU_TEXT_SMALL    = '8 8 0';
vector MENU_TEXT_MEDIUM   = '16 16 0';
vector MENU_TEXT_LARGE    = '24 24 0';

float(string id, vector pos, vector size, string text, string label) my_button =
{
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BUTTON + MENU_HIGHLIGHT * 0.25 : MENU_BUTTON; 
	basecolor = sui_is_held(id) ? MENU_BUTTON - MENU_DARKEN * 0.1 : basecolor;
	sui_fill([0, 0], size, basecolor, 0.6, 0);
	sui_border_box([0, 0], size, 1, MENU_BUTTON_BORDER, 0.4, 0);

	// TOOL-TIP
	float hovered = cursor_mode ? sui_is_hovered(id) : 0;
	if (hovered && label != "")
	{
		vector tip_size = [(strlen(text) * 64), 12];
		vector tip_pos;

		// center above button
		tip_pos_x = ((size_x) - (tip_size_x * 0.4));
		tip_pos_y = -tip_size_y - 2;

		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
		sui_fill(tip_pos, tip_size, MENU_BG_DARK, 0.95, 0);
		sui_border_box(tip_pos, tip_size, 1, MENU_BORDER, 0.6, 0);

		sui_text(tip_pos, [8,8], label, '1 1 1', 1, 0);
	}

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_text([0, 0], MENU_TEXT_SMALL, text, MENU_TEXT_1, 1, 0);	
	sui_action_element([0, 0], size, id, sui_noop);
	sui_pop_frame();
	
	return sui_is_clicked(id);
};

float(string id, vector pos, vector size, string image, string label) my_button_gfx =
{
	sui_push_frame(pos, size);

	// INPUT STATE (GATED)
	float hovered = cursor_mode ? sui_is_hovered(id) : 0;
	float held    = cursor_mode ? sui_is_held(id)    : 0;

	if (!cursor_mode)
		held = 0;

	// SCALE
	float scale = 1;

	if (held)
		scale = 0.95;

	// VISUAL RESPONSE
	vector icon_color = '1 1 1';
	float icon_alpha = 1;

	if (hovered)
		icon_color = '1.25 1.25 1.25';

	if (held)
		icon_color = '0.9 0.9 0.9';

	vector drawsize = size * scale;
	vector offset = (size - drawsize) * 0.5;

	// DRAW ICON
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_pic(offset, drawsize, image, icon_color, icon_alpha, 0);

	// TOOL-TIP
	if (hovered)
	{
		vector tip_size = [32, 12];
		vector tip_pos;

		// center above button
		tip_pos_x = (size_x * 0.5) - (tip_size_x * 0.5);
		tip_pos_y = -tip_size_y - 12;

		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
		sui_fill(tip_pos, tip_size, MENU_BG, 0.85, 0);
		sui_border_box(tip_pos, tip_size, 1, MENU_BORDER, 0.6, 0);

		sui_text(tip_pos, [8,8], label, '1 1 1', 1, 0);
	}

	// INPUT (DISABLED IF NO CURSOR)
	if (cursor_mode)
		sui_action_element([0, 0], size, id, sui_noop);

	sui_pop_frame();

	// also gate click so it doesn't fire on toggle-off frame
	return cursor_mode ? sui_is_clicked(id) : 0;
};

void(string id, vector pos, vector size, float maxlen, __inout string text, __inout float cursor, float mask) text_input_control =
{
    vector textsize = [size_y - 4, size_y - 4];
    sui_push_frame(pos, size);
    
    vector basecolor = sui_is_hovered(id) ? MENU_BG_DARK + MENU_HIGHLIGHT * 0.08 : MENU_BG_DARK; 
    sui_fill([0, 0], size, basecolor, 0.6, 0);
    
    sui_text_input(id, [0, 0], size, text, cursor);
    
    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
    float focused = sui_is_last_clicked(id);
    focused ? sui_border_box([0, 0], size, 1, MENU_BORDER, 0.6, 0) : 0;    
    
    sui_push_frame([2, 0], [size_x - 4, size_y - 4]);
    
    // Masked or real text
    string display_text;
    if (mask)
    {
        display_text = "";
        for (float i = 0; i < strlen(text); i++)
            display_text = strcat(display_text, "*");
    }
    else
    {
        display_text = text;
    }
    
    float cursorx;
    if (stringwidth(display_text, 1, textsize) > size_x - 4)
    {
        sui_clip_to_frame();
        cursorx = 0;
        sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
        sui_text([0, 0], textsize, display_text, MENU_TEXT_1, 1, 0);
    }
    else
    {
        cursorx = stringwidth(substring(text, 0, cursor), 1, textsize);
        sui_text([0, 0], textsize, display_text, MENU_TEXT_1, 1, 0);
    }
    
    if (focused) 
        sui_fill([cursorx, 0], [2, textsize_y], MENU_TEXT_1, fabs(sin(time * 4)), 0);
    
    sui_reset_clip();
    sui_pop_frame();
    sui_pop_frame();
};

float tt_clear_finished;
void(string id, vector pos, vector size, string text) sui_tooltip =
{
	sui_push_frame(pos, size);
	sui_fill([0, 0], size, MENU_BG_DARK, 0.6, 0);
	sui_text([0, 0], MENU_TEXT_SMALL, text, MENU_TEXT_1, 1, 0);	
	sui_action_element([0, 0], size, id, sui_noop);
	sui_pop_frame();

	// open desc_itemname.txt for reading tooltip text
	if (sui_is_hovered(id))
	{
		tt_contents = ""; // reset string

		// setup file read
		string line = "";
		string readfile = strcat(id, ".txt");
		float v = fopen(readfile, FILE_READ);
		if (v >= 0)
		{
			while ((line = fgets(v)))
				tt_contents = strcat(tt_contents, line, "\n");
			fclose(v);
		}
		else
			print(strcat("sui_tooltip: Missing: ", id, ".txt file\n")); // print missing tooltip file

		tt_clear_finished = time + 0.1;
	}
	else if (tt_clear_finished < time)
		tt_contents = "";
};

void(vector pos, float width, vector pos1, vector pos2, vector rgb, float alpha, optional float flags) sui_line =
{
	vector size = pos1 + pos2;
	sui_transform_box(pos, [pos1_x + pos2_x, size_y]);
	drawline(width, pos + pos1, pos + pos2, rgb, alpha, flags);
};
