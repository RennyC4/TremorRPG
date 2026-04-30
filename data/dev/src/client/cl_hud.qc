//
// Player HUD
//
string(string s) StripColors;

// ===============
// Monster Plaques
// ===============

float MONSTER_PLAQUE_DIST = 2000;
float MONSTER_FADE_SPEED  = 6;
float LOCKON_SCALE_SPEED  = 8;

.float plaque_alpha;
.float lockon_reticle_scale;

float(entity targ) Monster_Visible =
{
    vector start = vPlayerOrigin + self.view_ofs;
    vector end   = targ.origin + [0,0,targ.maxs_z * 0.9];

    traceline(start, end, TRUE, world);

    if (trace_fraction == 1 || trace_ent == targ)
        return TRUE;

    return FALSE;
};

void() CSQC_DrawMonsterPlaques =
{
    entity mon;
    float plyr_level = getstatf(STAT_LEVEL);

    for (mon = world; (mon = find(mon, classname, "monster")); )
    {
        if (!mon || mon.health <= 0)
            continue;

        float dist = vlen(mon.origin - vPlayerOrigin);
        if (dist > MONSTER_PLAQUE_DIST)
            continue;

        // ---- Visibility test (from camera to head)
        float visible = Monster_Visible(mon);

        if (!mon.plaque_alpha)
            mon.plaque_alpha = 0;

        float target_alpha = visible ? 1 : 0;

        mon.plaque_alpha += (target_alpha - mon.plaque_alpha) *
                            min(1, MONSTER_FADE_SPEED * frametime);

        if (mon.plaque_alpha < 0.02)
            continue;

        float alpha = mon.plaque_alpha;

        // ---- TRUE HEAD POSITION (prevents sinking into body)
        vector head_pos;
        head_pos = mon.origin;
        head_pos_z += mon.maxs_z + 48;

        vector plaque_coord = project(head_pos);
        if (plaque_coord_z <= 0)
            continue;

        // Centering
        plaque_coord_x -= 25;
        plaque_coord_y -= 14;

        // -------------------
        // NAME
        // -------------------
        drawstring(plaque_coord + [1,-7,0], mon.displayname,
                   [10,10], '0 0 0', alpha, 0);
        drawstring(plaque_coord + [0,-8,0], mon.displayname,
                   [10,10], '1 1 1', alpha, 0);

        // -------------------
        // HEALTH BAR (shorter)
        // -------------------
        vector hbar_bg_size = '42 4 0';
        vector hbar_size    = '42 4 0';

        float hp_frac = bound(0, mon.health / mon.max_health, 1);
        hbar_size_x *= hp_frac;

        vector hbar_pos = plaque_coord + [4, 8, 0];

        drawfill(hbar_pos + [1,1], hbar_bg_size, '0 0 0', alpha, 0);
        drawfill(hbar_pos, hbar_size,    '0.6 0 0', alpha, 0);

        // -------------------
        // LEVEL (fixed position)
        // -------------------
        string lvl_display = (mon.level >= plyr_level + 6) ? "?" : ftos(mon.level);

        vector level_pos = plaque_coord + [48, 6, 0];

        drawstring(level_pos + [1,1,0], lvl_display,
                   [10,10], '0 0 0', alpha, 0);
        drawstring(level_pos, lvl_display,
                   [10,10], '1 .8 0', alpha, 0);

        // -------------------
        // LOCK-ON RETICLE WITH SCALE
        // -------------------
        if (lock_on_active && lock_on_target == mon)
        {
            if (!mon.lockon_reticle_scale || mon.lockon_reticle_scale > 2.5)
                mon.lockon_reticle_scale = 2.5;

            float target_scale = 1.0;

            mon.lockon_reticle_scale +=
                (target_scale - mon.lockon_reticle_scale) *
                min(1, LOCKON_SCALE_SPEED * frametime);

            vector target_coord = project(mon.origin + [0,0, mon.maxs_z * 0.6]);
            if (target_coord_z > 0)
            {
                float s = mon.lockon_reticle_scale;

                vector draw_size = [64 * s, 64 * s];

                target_coord_x -= draw_size_x * 0.5;
                target_coord_y -= draw_size_y * 0.5;

                if (target_coord_y > g_height / 1.75)
                    target_coord_y = g_height / 1.75;

                drawpic(target_coord,
                        "progs/targetdot.spr_0",
                        draw_size,
                        '1 1 1',
                        alpha,
                        0);
            }
        }
        else
        {
            // Reset scale if not locked onto
            mon.lockon_reticle_scale = 2.5;
        }
    }
};


// ============================
// Floating Text + Name Tags
// ============================

#define FLOATTEXT_MAX_WIDTH 400
#define FLOATTEXT_VERTICAL_OFFSET 24

// Scale
vector FLOATTEXT_SCALE = [11,11];
float FLOATTEXT_SCALE_X = 11;
float FLOATTEXT_SCALE_Y = 11;

// Padding
vector FLOATTEXT_PADDING = [6,2,0];
float FLOATTEXT_PADDING_X = 6;
float FLOATTEXT_PADDING_Y = 2;

#define FLOATTEXT_LINEHEIGHT (FLOATTEXT_SCALE_Y + 2)

// ---------------------------
// Draw a floating text bubble
// ---------------------------
void(entity e) Draw_FloatingText =
{
    if (!e || e.floattext_time <= time || e.floattext_msg == "")
        return;

    // ----------------------
    // 0. Truncate message
    // ----------------------
    if (strlen(e.floattext_msg) > 255)
    {
        e.floattext_msg = substring(e.floattext_msg, 0, 252);
        e.floattext_msg = strcat(e.floattext_msg, " ...");
    }

    // ----------------------
    // 1. Smoothed draw position
    // ----------------------
    vector drawPos;
    if (e.entnum == player_localentnum)
        drawPos = vPlayerOrigin + [0, 0, -16]; // Move down a bit
    else
        drawPos = e.origin; // other players already interpolated

    vector top = drawPos + [0,0,e.maxs_z] + [0,0,FLOATTEXT_VERTICAL_OFFSET];
    vector screen = project(top);
    if (screen_z <= 0)
        return;

    // ----------------------
    // 2. Fade factor
    // ----------------------
    float fade = bound(0, (e.floattext_time - time)/3, 1);

    // ----------------------
    // 3. Word wrap
    // ----------------------
    string clean = StripColors(e.floattext_msg);
    float msg_len = strlen(clean);

    string lines[64];
    float line_count = 0;
    float bubble_width = 0;

    float start_index = 0;
    while (start_index < msg_len && line_count < 64)
    {
        float end_index = start_index;
        string line = "";
        float line_width = 0;

        while (end_index < msg_len)
        {
            // Find next word
            float word_end = end_index;
            while (word_end < msg_len && substring(clean, word_end, 1) != " ")
                word_end++;

            string word = substring(e.floattext_msg, end_index, word_end - end_index);
            string next_line = (line == "" ? word : strcat(line, " ", word));
            float w = stringwidth(next_line, TRUE, FLOATTEXT_SCALE);

            if (w > FLOATTEXT_MAX_WIDTH)
            {
                if (line != "") break;

                // Word too long: split by char
                float split_index = 0;
                while (split_index < strlen(word))
                {
                    float char_w = stringwidth(substring(word,0,split_index+1),TRUE,FLOATTEXT_SCALE);
                    if (char_w > FLOATTEXT_MAX_WIDTH) break;
                    split_index++;
                }

                line = substring(word,0,split_index);
                start_index += split_index;
                break;
            }

            line = next_line;
            line_width = w;
            end_index = word_end + 1;
        }

        if (line_count < 64)
        {
            lines[line_count++] = line;
            bubble_width = max(bubble_width, stringwidth(line,TRUE,FLOATTEXT_SCALE));
        }

        if (start_index < end_index) start_index = end_index;
    }

    float bubble_height = line_count * FLOATTEXT_LINEHEIGHT;

    // ----------------------
    // 4. Draw bubble background
    // ----------------------
    vector bg_pos = screen - [bubble_width / 2 + FLOATTEXT_PADDING_X, 0, 0];
    vector bg_size = [bubble_width + FLOATTEXT_PADDING_X*2, bubble_height + FLOATTEXT_PADDING_Y * 2,0];

    drawfill(bg_pos,bg_size,'0 0 0',fade*0.45);

    // Gold border
    float t = 1;
    drawfill(bg_pos + [0,bg_size_y,0],[bg_size_x,t,0],'1 0.84 0',fade); // top
    drawfill(bg_pos - [0,t,0],[bg_size_x,t,0],'1 0.84 0',fade);          // bottom
    drawfill(bg_pos - [t,0,0],[t,bg_size_y,0],'1 0.84 0',fade);          // left
    drawfill(bg_pos + [bg_size_x,0,0],[t,bg_size_y,0],'1 0.84 0',fade);  // right

    // ----------------------
    // 5. Draw each line
    // ----------------------
    vector line_pos = bg_pos + [FLOATTEXT_PADDING_X,FLOATTEXT_PADDING_Y,0];

    for (float i = 0; i < line_count; i++)
    {
        string msg = lines[i];
        w = stringwidth(msg, TRUE, FLOATTEXT_SCALE);
        vector draw_pos = line_pos + [bubble_width/2 - w/2,0,0];

        drawstring(draw_pos + [1,1,0], msg, FLOATTEXT_SCALE,'0 0 0',fade,0); // shadow
        drawstring(draw_pos, msg, FLOATTEXT_SCALE,'1 1 1',fade,0);

        line_pos_y += FLOATTEXT_LINEHEIGHT;
    }
};

// ----------------------
// Draw all name tags + chat bubbles
// ----------------------
void() Draw_NameTag_ChatBubble =
{
    entity b;
    for (b = world; (b = find(b, classname,"player")); )
    {
        if (vlen(b.origin - vPlayerOrigin) > 1250) continue;
        if (b.modelindex == 0 || b.netname == "") continue;

        // Smoothed draw position
        vector drawPos;
        if (b.entnum == player_localentnum)
            drawPos = vPlayerOrigin;
        else
            drawPos = b.origin;

        // ----------------------
        // Name tag
        // ----------------------
        vector top = drawPos + [0,0,b.maxs_z] + [0,0,10];
        vector scale = [10,10];
        float w = stringwidth(b.netname,TRUE,scale);
        vector pos = project(top) - [w*0.5,0,0];

		// Don't draw local players name tag
		if (b.entnum != player_localentnum && pos_z > 0)
		{
			drawstring(pos + [1,1,0], b.netname, scale,'0 0 0',1,0); // shadow
			if (b.pvp != 1)
				drawstring(pos,b.netname,scale,'.5 .5 1',1,0);
			else
				drawstring(pos,b.netname,scale,'1 .25 .25',1,0);
		}

        // ----------------------
        // Floating chat
        // ----------------------
        Draw_FloatingText(b);
    }
};

void() Draw_ToolTip =
{
	if (!tt_contents)
		return;

	vector tt_pos = [_cursor_position_x, _cursor_position_y, 0];
	tt_pos += [14, 14];

	float i, numlines = 0;
	vector linepos = [0, 0];
	numlines = tokenizebyseparator(tt_contents, "\n");
	for (i = 0; i < numlines; i = i + 1)
	{
		string tt_line = argv(i);

		float largest_x; // leave uninitialised
		float tt_fix_x;

		tt_fix_x = stringwidth(tt_line, 1); // get length
		if (tt_fix_x > largest_x)
			largest_x += tt_fix_x; // record the largest length string in a file

		linepos_y += 10;

		tt_size[0] = largest_x * 8.75; // 10 is font size?
		tt_size[1] = linepos_y + 10;

		if (_cursor_position_x > g_width / 1.5) // Tool tip: move position
			tt_pos_x = _cursor_position_x - (g_width / 12) - tt_size[0];
	}
	drawfill(tt_pos, [tt_size[0],tt_size[1]], MENU_BG_DARK, 0.9, 0);
	drawtextfield(tt_pos+[2.5,2.5], [tt_size[0],tt_size[1]], 3, tt_contents);
};

float lowhealth_display_until;
float lowmana_display_until;
float lowhealth_display_start;
float lowmana_display_start;
void() Draw_PlayerAlerts =
{
	vector screen;
	screen_x = g_width;
	screen_y = g_height;

	float cx = screen_x * 0.5;
	float cy = screen_y * 0.25;

	float duration = 3;

	// =========================================================
	// LOW HEALTH
	// =========================================================
	if (time < lowhealth_display_until)
	{
		float t = (time - lowhealth_display_start) / duration;
		t = bound(0, t, 1);

		float fade = pow(1 - t, 2);
		float shake = pow(1 - t, 2) * 1.5;

		string msg = "LOW HEALTH";
		vector size = '16 16 0';

		float text_width = stringwidth(msg, 0, size);

		vector pos;
		pos_x = floor(cx - text_width * 0.5);
		pos_y = floor(cy - 20);

		pos_x += sin(time * 25) * shake;
		pos_y += cos(time * 20) * shake;

		// -------------------------
		// ICON (above text)
		// -------------------------
		vector icon_pos;
		icon_pos_x = pos_x + (text_width * 0.5) - 8; // center icon
		icon_pos_y = pos_y - 28;

		drawpic(icon_pos, "progs/lowhealth.png", '24 24 0', '1 1 1', fade, 0);

		// shadow
		vector shadow_pos;
		shadow_pos_x = pos_x + 1;
		shadow_pos_y = pos_y + 1;
		drawstring(shadow_pos, msg, size, '0 0 0', fade, 0);

		// main
		drawstring(pos, msg, size, '1 0 0', fade, 0);
	}

	// =========================================================
	// LOW MANA
	// =========================================================
	if (time < lowmana_display_until)
	{
		t = (time - lowmana_display_start) / duration;
		t = bound(0, t, 1);

		float fade = pow(1 - t, 2);
		float shake = pow(1 - t, 2) * 1.2;

		string msg = "LOW MANA";
		vector size = '16 16 0';

		float text_width = stringwidth(msg, 0, size);

		vector pos;
		pos_x = floor(cx - text_width * 0.5);
		pos_y = floor(cy);

		pos_x += sin(time * 22) * shake;
		pos_y += cos(time * 18) * shake;

		// -------------------------
		// ICON (above text)
		// -------------------------
		vector icon_pos;
		icon_pos_x = pos_x + (text_width * 0.5) - 8;
		icon_pos_y = pos_y - 28;

		drawpic(icon_pos, "progs/lowmana.png", '24 24 0', '1 1 1', fade, 0);

		// shadow
		vector shadow_pos;
		shadow_pos_x = pos_x + 1;
		shadow_pos_y = pos_y + 1;
		drawstring(shadow_pos, msg, size, '0 0 0', fade, 0);

		// main
		drawstring(pos, msg, size, '0 0.4 1', fade, 0);
	}
};

void() Draw_CastingStat =
{
	float casting = getstatf(STAT_CASTING);
	string disp_magicspell = getstats(STAT_SPELLEQUIPPED);
	float remaining = (casting - time);
	string cast_string = strcat("^6", disp_magicspell, (sprintf("^7: %.2f", remaining)));

	// position
	float str_width = stringwidth(cast_string, 1, [12, 12]);
	vector text_pos = [(g_width / 2) - (str_width / 2), g_height - 15];

	// text effects
	float wobble = sin(time * 3) * 0.5;
	vector pulse = [sin(time * 2) * 0.1, sin(time * 2) * 0.1];
	vector color_main = [0.8, 0.5 + 0.25 * sin(time), 0.8];
	vector color_shadow = [0, 0, 0];

	drawstring(text_pos + [1, 1 + wobble], cast_string, '12 12'+pulse, color_shadow, 1, 1); // shadow
	drawstring(text_pos + [0, wobble], cast_string, '12 12'+pulse, color_main, 1, 1);

	// sparkles
	int i = 0;
	while (i < strlen(cast_string))
	{
		if (random() < 0.05) // 5% chance per letter per frame
		{
			float offset_x = stringwidth(substring(cast_string, 0, i), 1, [12, 12]) + crandom() * 2;
			float offset_y = wobble - random()*4; // float above text
			drawstring(text_pos + [offset_x, offset_y], "*", [8, 8], [1,1,1], 1, 1);
		}
		i += 1;
	}
};

void(vector pos, vector canvas_size) WorldMap_Draw =
{
    clearscene();

    setviewprop(VF_MIN, pos);
    setviewprop(VF_SIZE, canvas_size);

	if (autocvar_minimap == "full")
		addentities(MASK_ENGINE);

	setviewprop(VF_PERSPECTIVE, 1);
	setviewprop(VF_AFOV, 90);

    setviewprop(VF_ORIGIN, [vPlayerOrigin_x, vPlayerOrigin_y, vPlayerOrigin_z + 1500]);
	setviewprop(VF_ANGLES, [90, view_angles_y, 0]);
	setviewprop(VF_DRAWCROSSHAIR, 0);
	setviewprop(VF_DRAWWORLD, TRUE);
	setviewprop(VF_VIEWENTITY, 0.0);

	/*
	setviewprop(VF_PERSPECTIVE, 0);
	setviewprop(VF_FOVX, 2500);
	setviewprop(VF_FOVY, 2500);
	setviewprop(VF_MINDIST, 0);
	setviewprop(VF_MAXDIST, 1000);
	*/

	renderscene();

	drawstring([g_width - 58, 48], ".", [12, 12], '1 1 1', 1, 0);
};

void(float screenwidth, float screenheight) Draw_ZoneName =
{
	string zonename = getstats(STAT_ZONENAME);
	vector pos = [(screenwidth - stringwidth(zonename, TRUE, '18 18 0'))/2, (screenheight - 18)/3];

	if (ZoneName_alpha.doalpha < 7.8)
		ZoneName_alpha.doalpha += (2.5 * frametime);
	else
		ZoneName_alpha.doalpha = 0;

	drawstring(pos - '1 1', zonename, '18 18', '0 0 0', (sin(ZoneName_alpha.doalpha*0.40)*1), 0); // shadow
	drawstring(pos + '1 1', zonename, '18 18', '0 0 0', (sin(ZoneName_alpha.doalpha*0.40)*1), 0); // shadow
	drawstring(pos, zonename, '18 18', '.9 .1 0', (sin(ZoneName_alpha.doalpha*0.40)*1), 0);
};

void() Draw_ChatLog =
{
    vector size = [230, 100];
    vector pos;

    float offset_right = 0;
    float offset_bottom = 7;

    pos_x = g_width - size_x - offset_right;
    pos_y = g_height - size_y - offset_bottom;
    pos = [pos_x, pos_y];

    sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
    sui_push_frame(pos, size);

    // Background
    sui_fill([0, 0], size, '0 0 0', 0.5, 0);
    sui_border_box([0, 0], size, 2, '0 0 0', 0.1, 0);

    // Draw chat text
    float y = 4;
    float i;

    for (i = MAX_CHAT_LINES - 1; i >= 0; i--)
    {
        if (!chat_lines[i])
            continue;

		sui_text([2,y], MENU_TEXT_SMALL, chat_lines[i], '1 1 1', 1, 0);
        y += 12;
    }

    sui_pop_frame();
};

void() Draw_HUDIcons =
{
	vector pos = [8, -145];
	vector size = [32, 32];

	// Bottom Left Buttons (Event Log)
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	my_button_gfx("button_char", pos, size, "progs/char.png", "Skills") ? sendevent("PlayerShowStats", "") : 0; // avatar button
	pos_x += 38;
	my_button_gfx("button_magic", pos, size, "progs/magic.png", "Magic") ? sendevent("PlayerShowMagic", "") : 0; // magic
	pos_x += 38;
	my_button_gfx("button_inventory", pos, size, "progs/inventory.png", "Inventory") ? sendevent("PlayerShowInventory", "") : 0; // inventory

	//  Top Left Buttons (Compass)
	pos = [0, 0];
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	pos_x -= 8;
	pos_y += 142;

	my_button_gfx("button_system", pos, size, "progs/gear.png", "System") ? localcmd("togglemenu\n") : 0; // system menu
	pos_x -= 40;
	my_button_gfx("button_pvp", pos, size, "progs/pvp.png", "PvP Toggle") ? sendevent("User_TogglePVP", "") : 0; // pvp toggle
};

void() Draw_EventLog =
{
	vector pos = [0, -45];
	vector size = [230, 100];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	sui_push_frame(pos, size);
	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	sui_pop_frame();

	// draw text
	pos = [(g_width * 0.0001), (g_height - 146)];
	size = [330, 100];
	if (drawfont != drawfont2)
		drawfont = drawfont2;
	con_draw("event", pos, size, 12);
	if (drawfont != drawfont1)
		drawfont = drawfont1;
};

void() Draw_InCombatorPVP =
{
	float incombat = getstatf(STAT_INCOMBAT);
	float pvp = getstatf(STAT_PVP);

	vector pos = [195, -145];
	vector size = [35, 35];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	if (!pvp || pvp == 2)
	{
		if (incombat) // only show when in combat
			sui_pic(pos, size, "progs/combat.png", '1 1 1', 1, 0);
	}
	else if (pvp == 1)
		sui_pic(pos, size, "progs/combat.png", '1 .25 .25', 1, 0); // PVP icon
};


//
// Draw Health
//

void() Draw_Health =
{
	float h = getstatf(STAT_HEALTH);
	float hmax = getstatf(STAT_MAXHEALTH);
	vector pos = [30, (g_height - 38)];

	// Bar
	vector hbar_size = '100 8 0';
	vector hbarpos = pos;
	
	drawfill(hbarpos + '1 1 0', hbar_size, '0.5 0 0', 0.35, 0); // background bar
	
	hbar_size_x = (h / hmax) * hbar_size_x; // keep bar updated
	drawfill(hbarpos + '1 1 0', hbar_size, '0.5 0 0', 1, 0);

	// text
	string h1 = FloatToIntString(h);
	string h2 = ftos(hmax);

	pos = [0, (g_height - 36)];
	drawstring (pos+[1,1], "Health", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "^1Health", '8 8 0', '1 1 1', 1, 0);

	pos_x += 40;
	drawstring (pos+[1,1], h1, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, h1, '8 8 0', '1 1 1', 1, 0);

	pos_x += 25;
	drawstring (pos+[1,1], "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "/", '8 8 0', '1 1 1', 1, 0);

	pos_x += 20;
	drawstring (pos+[1,1], h2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, h2, '8 8 0', '1 1 1', 1, 0);
};

//
// Draw Mana
//

void() Draw_Mana =
{
	float m = getstatf(STAT_MANA);
	float mmax = getstatf(STAT_MAXMANA);
	vector pos = [30, (g_height - 28)];

	// Bar
	vector mbar_size = '100 8 0';
	vector mbarpos = pos;

	drawfill(mbarpos + '1 1 0', mbar_size, '0 0 0.5', 0.35, 0); // background bar
	
	mbar_size_x = (m / mmax) * mbar_size_x; // keep bar updated
	drawfill(mbarpos + '1 1 0', mbar_size, '0 0 0.5', 1, 0);

	// text
	string m1 = FloatToIntString(m);
	string m2 = ftos(mmax);

	pos = [0, (g_height - 26)];
	drawstring (pos+[1,1], "Mana", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "^4Mana", '8 8 0', '1 1 1', 1, 0);

	pos_x += 40;
	drawstring (pos+[1,1], m1, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, m1, '8 8 0', '1 1 1', 1, 0);

	pos_x += 25;
	drawstring (pos+[1,1], "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "/", '8 8 0', '1 1 1', 1, 0);

	pos_x += 20;
	drawstring (pos+[1,1], m2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, m2, '8 8 0', '1 1 1', 1, 0);
	
	// Draw spell name on screen
	string disp_magicspell = getstats(STAT_SPELLEQUIPPED);
	if (disp_magicspell != "")
	{
		pos_x += 50;
		drawstring (pos+[1,1], disp_magicspell, '8 8 0', '0 0 0', 1, 0); // text shadow
		drawstring (pos, disp_magicspell, '8 8 0', '0 .75 .75', 1, 0);
	}
};

//
// Draw Stamina
//

void() Draw_Stamina =
{
	float s = getstatf(STAT_STAMINA);
	float smax = 100;
	vector pos = [30, (g_height - 18)];

	// Bar
	vector sbar_size = '100 8 0';
	vector sbarpos = pos;

	drawfill(sbarpos + '1 1 0', sbar_size, '0 0.5 0', 0.35, 0); // background bar
	
	sbar_size_x = (s / smax) * sbar_size_x; // keep bar updated
	drawfill(sbarpos + '1 1 0', sbar_size, '0 0.5 0', 1, 0);

	// Text
	string s1 = ftos(s);
	string s2 = ftos(smax);	
	string dispfix_stamina = sprintf("%.1f", s); // cut down numbers

	pos = [0, (g_height - 16)];
	drawstring (pos+[1,1], "Stamina", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "^2Stamina", '8 8 0', '1 1 1', 1, 0);

	pos_x += 40;
	if (s < 100)
	{
		drawstring (pos+[1,1], dispfix_stamina, '8 8 0', '0 0 0', 1, 0); // text shadow
		drawstring (pos, dispfix_stamina, '8 8 0', '1 1 1', 1, 0);
	}
	else
	{
		drawstring (pos+[1,1], s1, '8 8 0', '0 0 0', 1, 0); // text shadow
		drawstring (pos, s1, '8 8 0', '1 1 1', 1, 0);
	}

	pos_x += 25;
	drawstring (pos+[1,1], "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "/", '8 8 0', '1 1 1', 1, 0);

	pos_x += 20;
	drawstring (pos+[1,1], s2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, s2, '8 8 0', '1 1 1', 1, 0);
};

//
// Draw Experience
//

void() Draw_Exp =
{
    float e  = getstatf(STAT_EXP);
    float e2 = getstatf(STAT_EXPNEEDED);
    float e3 = getstatf(STAT_EXPOLDNEEDED);

    float disp = e - e3;
    float disp_max = e2 - e3;
    float ratio = bound(0, disp / disp_max, 1); // prevents overflow if exp > next

    // Bar positions and dimensions
    vector pos;
    pos_x = g_width * 0.0001;
    pos_y = g_height * 0.99;
    pos_z = 0;

    float bar_height = 8;
    float bar_width  = g_width;

    // Full bar background
    vector full_size = [bar_width, bar_height, 0];
    drawfill(pos, full_size, '0 0 0', 0.35, 0); // dark background

    // Filled exp portion
    vector fill_size = [bar_width * ratio, bar_height, 0];
    drawfill(pos, fill_size, '1 1 0', 0.25, 0); // yellow exp fill
};

//
// 3D Character portrait
//

void(entity ent, vector pos, vector canvas_size, float zoom) entdraw =
{
    clearscene();
    setviewprop(VF_MIN, pos);
    setviewprop(VF_SIZE, canvas_size);
 
    setviewprop(VF_AFOV, 25);
    setviewprop(VF_DRAWWORLD, FALSE);
 
    setviewprop(VF_ORIGIN, [zoom, 0, 0]);
    setviewprop(VF_ANGLES, '0 0 0');
 
    addentity(ent);
	renderscene();
};

entity doll;
void() Skeleton_ObjectDraw;
void(vector pos) Draw_3DPDoll =
{
	vector size = [150, 250];
	sui_transform_box(pos, size);

	string gender = getstats(STAT_GENDER);

    if (!doll) // Call this one time so we're not spawning infinite entities
    {
 		doll = spawn();

        precache_model("models/player_m.glb");
        precache_model("models/player_f.glb");

		if (gender == "Male")
		{
			setmodel(doll, "models/player_m.glb");
			modelindex_player_m = doll.modelindex;
		}
		else
		{
			setmodel(doll, "models/player_f.glb");
			modelindex_player_f = doll.modelindex;
		}

		doll.drawflags = 7; // override engine lighting
		doll.abslight = 500; // new lighting level

        setorigin(doll, '0 0 0');
		doll.angles_y -= 180;
		//doll.origin_z -= 0;

		doll.frame = frameforname(doll.modelindex, "Idle");
	}

	doll.angles_y += 50 * frametime;
	if (gender == "Female")
		doll.frame1time += frametime / 2;
	else
		doll.frame1time += frametime;

	entdraw(doll, pos, '175 275', -245);
};

//==============================================================
// Character Skills / Magic / Inventory screens
//==============================================================

// =================
// SKILL DATA ACCESS
// =================

string(float i) SkillName =
{
	switch (i)
	{
		case 0: return "Unarmed";
		case 1: return "Slashing";
		case 2: return "Piercing";
		case 3: return "Bashing";
		case 4: return "Stealth";
		case 5: return "Backstab";
		case 6: return "Offensive Magic";
		case 7: return "Defensive Magic";
		case 8: return "Neutral Magic";
		case 9: return "Endurance";
		case 10: return "Spell Resist";
		case 11: return "Archery";
		case 12: return "Health Regen";
		case 13: return "Mana Regen";
		case 14: return "Haggling";
		case 15: return "Climbing";
		case 16: return "Swimming";
		case 17: return "Acrobatics";

		// passive skills
		case 18: return "Mining";
		case 19: return "Fishing";
		case 20: return "Wood Cutting";
	}
	return "Unknown";
};

float(float i) SkillValue =
{
	switch (i)
	{
		case 0: return getstatf(STAT_SKILL_UNARMED);
		case 1: return getstatf(STAT_SKILL_SLASH);
		case 2: return getstatf(STAT_SKILL_PIERCE);
		case 3: return getstatf(STAT_SKILL_BASH);
		case 4: return getstatf(STAT_SKILL_STEALTH);
		case 5: return getstatf(STAT_SKILL_BACKSTAB);
		case 6: return getstatf(STAT_SKILL_OFFENSIVEMAGIC);
		case 7: return getstatf(STAT_SKILL_DEFENSIVEMAGIC);
		case 8: return getstatf(STAT_SKILL_NEUTRALMAGIC);
		case 9: return getstatf(STAT_SKILL_ENDURANCE);
		case 10: return getstatf(STAT_SKILL_SPELLRESIST);
		case 11: return getstatf(STAT_SKILL_ARCHERY);
		case 12: return getstatf(STAT_SKILL_HEALTHREGEN);
		case 13: return getstatf(STAT_SKILL_MANAREGEN);
		case 14: return getstatf(STAT_SKILL_HAGGLE);
		case 15: return getstatf(STAT_SKILL_CLIMB);
		case 16: return getstatf(STAT_SKILL_SWIM);
		case 17: return getstatf(STAT_SKILL_ACROBATIC);

		// passive skills
		case 18: return getstatf(STAT_MINING);
		case 19: return getstatf(STAT_FISHING);
		case 20: return getstatf(STAT_WOODCUTTING);
	}
	return 0;
};

//
// Helper DPS Calculation function
//
void(float atmin, float atmax, float atspd, float atype, float projmin, float projmax, float unarmed, float slash, float pierce, float bash, float archery, float &dps_out, string &type_out) Calc_DPS =
{
	float dps = (atmin + atmax * 0.5) / atspd;

	if (!atype)
		dps = (unarmed * 0.055) / atspd;
	else if (atype == 1)
		dps += slash * 0.1;
	else if (atype == 2)
		dps += pierce * 0.1;
	else if (atype == 3)
		dps += bash * 0.1;
	else
	{
		dps = (((atmin + atmax) * 0.5) + ((projmin + projmax) * 0.5)) / atspd;
		dps += archery * 0.1;
	}

	string type;
	if (!atype) type = "Unarmed";
	else if (atype == 1) type = "Slash";
	else if (atype == 2) type = "Pierce";
	else if (atype == 3) type = "Bash";
	else if (atype == 4) type = "Projectile";
	else type = "Unknown";

	dps_out = dps;
	type_out = type;
};

void() UI_DrawPlayerSummary =
{
	// =================
	// CACHE
	// =================
	string name = LOGIN_NAME;
	string gender = getstats(STAT_GENDER);

	float level = getstatf(STAT_LEVEL);
	float exp = getstatf(STAT_EXP);
	float expneed = getstatf(STAT_EXPNEEDED);

	float gold = getstatf(STAT_GOLD);
	float bank = getstatf(STAT_GOLD_BANK);
	float skillpoints = getstatf(STAT_SKILLPOINTS);
	float reapermarks = getstatf(STAT_REAPERMARK);

	string mainhand = getstats(STAT_MAINHAND);
	string offhand = getstats(STAT_OFFHAND);

	float atmin = getstatf(STAT_ATTACKMIN);
	float atmax = getstatf(STAT_ATTACKMAX);
	float atspd = getstatf(STAT_ATTACKSPEED);
	float atype = getstatf(STAT_ATTACKTYPE);

	float projmin = getstatf(STAT_PROJ_MIN);
	float projmax = getstatf(STAT_PROJ_MAX);

	float blocking = getstatf(STAT_BLOCKVALUE);

	string armor = getstats(STAT_ARMORNAME);
	float armorval = getstatf(STAT_ARMORVALUE);

	string spell = getstats(STAT_SPELLEQUIPPED);
	float spmin = getstatf(STAT_SPELLMIN);
	float spmax = getstatf(STAT_SPELLMAX);

	// =================
	// DPS
	// =================
	float dps;
	string dps_type;
	Calc_DPS(atmin, atmax, atspd, atype, projmin, projmax, getstatf(STAT_SKILL_UNARMED), getstatf(STAT_SKILL_SLASH), getstatf(STAT_SKILL_PIERCE), getstatf(STAT_SKILL_BASH), getstatf(STAT_SKILL_ARCHERY), dps, dps_type);
	string dpss = sprintf("%.2f", dps);

	// =================
	// HEADER
	// =================
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([3.5, 5], MENU_TEXT_MEDIUM, strcat(gender, " ^1", name), MENU_TEXT_SHADOW, 1, 0); // drop shadow
	sui_text([2.5, 4], MENU_TEXT_MEDIUM, strcat(gender, " ^1", name), MENU_TEXT_1, 1, 0);

	// =================
	// MODEL
	// =================
	vector modelpos = [25, 25];
	vector modelsz = [125, 150];

	sui_border_box(modelpos, modelsz, 2, MENU_BORDER, 0.3, 0);
	sui_fill(modelpos, modelsz, MENU_BG_DARK, 0.75, 0);

	Draw_3DPDoll(modelpos - [25, 0]);

	// =================
	// INFO COLUMN
	// =================
	vector info = [2, 20];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);

	#define LINE(str) sui_text(info, MENU_TEXT_SMALL, str, MENU_TEXT_1, 1, 0); info_y += 10;

	LINE(strcat("^5Level: ^7", ftos(level)));
	LINE(strcat("^5Exp: ^7", ftos(exp), " / ", ftos(expneed)));
	LINE(strcat("^5Gold: ^7", ftos(gold), "^8 Bank: ", ftos(bank)));
	LINE(strcat("^5Skill Points: ^7", ftos(skillpoints)));

	info_y += 2;

	// ===== Equipment =====
	sui_text(info, MENU_TEXT_SMALL, "^5Main Hand", MENU_TEXT_1, 1, 0);

	info_x += 40;
	my_button("unequip_mainhand", info, [30,10], "Unequip", "")
		? sendevent("User_UnequipMainhand", "", 0)
		: 0;
	info_x -= 40;

	info_y += 10;

	LINE(strcat(mainhand, " (^8", ftos(atmin), "-", ftos(atmax), "^7)"));
	LINE(strcat("^1DPS: ^7", dpss, " (^8", dps_type, "^7)"));

	info_y += 2;

	sui_text(info, MENU_TEXT_SMALL, "^5Off Hand", MENU_TEXT_1, 1, 0);

	info_x += 40;
	my_button("unequip_offhand", info, [30,10], "Unequip", "")
		? sendevent("User_UnequipOffhand", "", 0)
		: 0;
	info_x -= 40;

	info_y += 10;

	LINE(offhand);
	LINE(strcat("^2Blocking: ^7", ftos(blocking)));

	info_y += 2;

	LINE(strcat("^5Armor: ^7", armor, " (^2+", ftos(armorval), "^7)"));
	LINE(strcat("^5Magic Spell: ^7", spell, " (^8", ftos(spmin), "-", ftos(spmax), "^7)"));

	info_y += 10;

	LINE(strcat("^1Reaper Marks: ^7", ftos(reapermarks)));

	#undef LINE
};

//
// Skills Screen
//
void() User_SkillsScreen =
{
	float hp = getstatf(STAT_HEALTH);
	float skillpoints = getstatf(STAT_SKILLPOINTS);
	if (hp <= 0)
		return;

	// ========
	// BACKDROP
	// ========
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	// ============
	// MAIN WINDOW
	// ============
	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	UI_DrawPlayerSummary(); // Draw all left side player information + 3d model

	// ============
	// SKILLS PANEL
	// ============
	vector spanel = [75, 0];
	vector row = [0, 3];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(spanel, [250, 280]);

	sui_fill([0, 0], [250, 280], MENU_BG, 0.75, 0);
	sui_border_box([0, 0], [250, 280], 2, MENU_BORDER, 0.3, 0);

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text([1, -19], MENU_TEXT_MEDIUM, "^2Skills", MENU_TEXT_SHADOW, 1, 0); // drop shadow
	sui_text([0, -20], MENU_TEXT_MEDIUM, "^2Skills", MENU_TEXT_1, 1, 0);

	float i;
	float MAX_SKILLS = 21;
	for (i = 0; i < MAX_SKILLS; i++)
	{
		string sname = SkillName(i);
		float sval = SkillValue(i);
		string sval_str = sprintf("%.1f", sval);

		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

		float is_lastactive = (i == 17); // we do a gap here
		float is_passive = (i > 17);
		string col;

		if (is_passive)
		{
			col = "^8"; // dull grey / muted
			sui_text(row, MENU_TEXT_SMALL, strcat(col, sname, ": ^7", sval_str), MENU_TEXT_1, 1, 0);
		}
		else
		{
			col = "^5"; // your normal highlight color
			sui_text(row, MENU_TEXT_SMALL, strcat(col, sname, ": ^7", ftos(sval)), MENU_TEXT_1, 1, 0);
		}

		if (bonfire && skillpoints > 0 && !is_passive)
		{
			sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
			my_button(strcat("sp_", ftos(i)), row, [25, 10], "+", strcat("^3", sname))
				? sendevent("User_AddSkillPoint", "f", i)
				: 0;
		}

		if (is_lastactive) // do gap after last active skill
			row_y += 12;

		row_y += 10;
	}

	sui_pop_frame();

	// CLOSE button
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X", "")
		? sendevent("ShutDownMenus", "")
		: 0;

	sui_pop_frame();
};

//
// Magic Screen
//
void() User_MagicScreen =
{
	float hp = getstatf(STAT_HEALTH);
	if (hp <= 0)
		return;

	// =================
	// BACKDROP
	// =================
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);


	// ============
	// MAIN WINDOW
	// ============
	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	UI_DrawPlayerSummary(); // Draw all left side player information + 3d model

	// ===========
	// SPELL PANEL
	// ===========
	vector panel = [75, 0];
	vector row = [0, 2.5];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(panel, [250, 280]);

	sui_fill([0, 0], [250, 280], MENU_BG, 0.75, 0);
	sui_border_box([0, 0], [250, 280], 2, MENU_BORDER, 0.3, 0);

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	
	sui_text([1, -19], MENU_TEXT_MEDIUM, "^2Magic", MENU_TEXT_SHADOW, 1, 0); // drop shadow
	sui_text([0, -20], MENU_TEXT_MEDIUM, "^2Magic", MENU_TEXT_1, 1, 0);

	float i;
	for (i = 0; i < spell_count; i++)
	{
		string s = spell[i];
		if (!s)
		{
			row_y += 10;
			continue;
		}

		string desc = strcat("desc_", string_remove_spaces(s));
		string btn  = strcat("spell_", ftos(i));

		// ===================
		// RESET ALIGN PER ROW
		// ===================
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

		// label width for tooltip box
		float w = stringwidth(s, 1);

		vector label_size = [w * 8, 10];

		// draw tooltip label (LEFT SIDE)
		sui_tooltip(
			desc,
			row,
			label_size,
			strcat("^5", s)
		);

		// =========================
		// BUTTON (RIGHT SIDE)
		// =========================
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);

		my_button(btn, row, [32, 10], "Equip", "")
			? sendevent("EquipSpell", "s", s)
			: 0;

		// =========================
		// NEXT ROW
		// =========================
		row_y += 10;
	}

	sui_pop_frame();

	// =================
	// CLOSE
	// =================
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X", "")
		? sendevent("ShutDownMenus", "")
		: 0;

	sui_pop_frame();
};

//
// Inventory Screen
//
void() User_InventoryScreen =
{
	float hp = getstatf(STAT_HEALTH);
	if (hp <= 0)
		return;

	// =========================================================
	// BACKDROP
	// =========================================================
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	// =========================================================
	// MAIN WINDOW
	// =========================================================
	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	UI_DrawPlayerSummary(); // Draw all left side player information + 3d model

	// =========================================================
	// INVENTORY PANEL
	// =========================================================
	vector panel = [75, 0];
	vector row = [0, 2.5];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(panel, [250, 280]);

	sui_fill([0, 0], [250, 280], MENU_BG, 0.75, 0);
	sui_border_box([0, 0], [250, 280], 2, MENU_BORDER, 0.3, 0);

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text([1, -19], MENU_TEXT_MEDIUM, "^2Inventory", MENU_TEXT_SHADOW, 1, 0);  // drop shadow
	sui_text([0, -20], MENU_TEXT_MEDIUM, "^2Inventory", MENU_TEXT_1, 1, 0);

	// =========================================================
	// ITEMS
	// =========================================================
	float i;

	for (i = 0; i < inv_count; i++)
	{
		if (inventory_count[i] <= 0)
			continue;

		string item = inventory[i];

		string use_btn = strcat("u_", item);
		string drop_btn = strcat("d_", item);
		string desc = strcat("desc_", string_remove_spaces(item));

		string label = strcat("^5", item, " ^7[^2", ftos(inventory_count[i]), "^7]");

		// FIXED: consistent row alignment
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

		float w = stringwidth(item, 1);
		sui_tooltip(desc, row, [w * 8, 8], label);

		// ALWAYS present buttons
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);

		my_button(use_btn, row, [32, 10], "Use", "")
			? sendevent("UseItem", "s", item)
			: 0;

		my_button(drop_btn, row - [34, 0], [32, 10], "Drop", "")
			? sendevent("DropItem", "s", item)
			: 0;

		row_y += 10;
	}

	sui_pop_frame();

	// ======
	// CLOSE
	// ======
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X", "")
		? sendevent("ShutDownMenus", "")
		: 0;

	sui_pop_frame();
};