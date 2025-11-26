//
// Player HUD
//

//
// Player name tags + chat bubble
//
void(entity e) Draw_FloatingText =
{
    if (!e || e.floattext_time <= time || e.floattext_msg == "")
        return;

    vector top = e.origin + [0,0,e.maxs_z] + [0,0,24]; // position above head
    vector screen = project(top);
    if (screen_z <= 0)
        return;

    float fade = (e.floattext_time - time) / 3;
    fade = bound(0, fade, 1);

    vector scale = [11,11];

    // Split message into lines if needed (wrapped)
    string msg = e.floattext_msg;
    float msg_w = stringwidth(msg, TRUE, scale);
    float msg_h = scale_y;

    vector pos = screen - [msg_w * 0.5, 0, 0];

    // Background
    vector pad = [6,2,0];
    vector bg_pos = pos - [pad_x, pad_y, 0];
    vector bg_size = [msg_w + pad_x*2, msg_h + pad_y*2, 0];
    drawfill(bg_pos, bg_size, '0 0 0', fade * 0.45);

    // Gold border (1px)
    float t = 1;
    drawfill(bg_pos + [0,bg_size_y,0], [bg_size_x,t,0], '1 0.84 0', fade); // top
    drawfill(bg_pos - [0,t,0], [bg_size_x,t,0], '1 0.84 0', fade);          // bottom
    drawfill(bg_pos - [t,0,0], [t,bg_size_y,0], '1 0.84 0', fade);          // left
    drawfill(bg_pos + [bg_size_x,0,0], [t,bg_size_y,0], '1 0.84 0', fade);  // right

    // Text
    drawstring(pos + [1,1,0], msg, scale, '0 0 0', fade, 0); // shadow
    drawstring(pos, msg, scale, '1 1 1', fade, 0);           // white
};

void() Draw_NameTag =
{
    entity b;

    for (b = world; (b = find(b, classname, "player")); )
    {
        // Skip distant players
        if (vlen(b.origin - vPlayerOrigin) > 1250)
            continue;
        if (b.modelindex == 0 || b.netname == "")
            continue;

        // NAME TAG
        if (b.entnum != player_localentnum)
        {
            vector top = b.origin + [0,0,b.maxs_z] + [0,0,10];
            vector scale = [10,10];
            float w = stringwidth(b.netname, TRUE, scale);
            vector pos = project(top) - [w*0.5,0,0];

            drawstring(pos + [1,1,0], b.netname, scale, '0 0 0', 1, 0);
            if (b.pvp != 1)
                drawstring(pos, b.netname, scale, '.5 .5 1', 1, 0);
            else
                drawstring(pos, b.netname, scale, '1 .25 .25', 1, 0);
        }

        // FLOATING CHAT TEXT
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

//
// Reki's Code to draw 3D objects on the HUD
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

	vector pos = [2.5, (g_height - 182.5)];
	vector size = [35, 35];

	if (!pvp || pvp == 2)
	{
		if (incombat) // only show when in combat
			drawpic (pos, "progs/combat.png", size, '1 1 1', 1, 0);
	}
	else if (pvp == 1)
		drawpic (pos, "progs/combat.png", size, '1 .25 .25', 1, 0); // PVP icon
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
		doll.origin_z -= 35;
		doll.frame = frameforname(doll.modelindex, "Idle");
	}

	doll.angles_y += 50 * frametime;
	if (gender == "Female")
		doll.frame1time += frametime / 2;
	else
		doll.frame1time += frametime;

	entdraw(doll, pos, '150 250', -245);
};

//
// Character stat screen + skill point distribution
//

void() User_CharacterScreen =
{
	float get_h = getstatf(STAT_HEALTH);
	if (get_h <= 0)
		return;

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	string displaystat;

	string disp_gender = getstats(STAT_GENDER);
	float disp_level = getstatf(STAT_LEVEL);
	float disp_exp =  getstatf(STAT_EXP);
	float disp_neededexp =  getstatf(STAT_EXPNEEDED);
	float disp_gold =  getstatf(STAT_GOLD);
	float disp_skillpoints =  getstatf(STAT_SKILLPOINTS);
	string disp_mainhand = getstats(STAT_MAINHAND);
	string disp_offhand = getstats(STAT_OFFHAND);
	float disp_attackmin = getstatf(STAT_ATTACKMIN);
	float disp_attackmax = getstatf(STAT_ATTACKMAX);
	float disp_attackspeed = getstatf(STAT_ATTACKSPEED);
	float disp_attacktype = getstatf(STAT_ATTACKTYPE);
	string disp_armorname = getstats(STAT_ARMORNAME);
	float disp_armorvalue = getstatf(STAT_ARMORVALUE);
	float disp_unarmed = getstatf(STAT_SKILL_UNARMED);
	float disp_slash = getstatf(STAT_SKILL_SLASH);
	float disp_pierce = getstatf(STAT_SKILL_PIERCE);
	float disp_bash = getstatf(STAT_SKILL_BASH);
	float disp_stealth = getstatf(STAT_SKILL_STEALTH);
	float disp_backstab = getstatf(STAT_SKILL_BACKSTAB);
	float disp_offensivemagic = getstatf(STAT_SKILL_OFFENSIVEMAGIC);
	float disp_defensivemagic = getstatf(STAT_SKILL_DEFENSIVEMAGIC);
	float disp_neutralmagic = getstatf(STAT_SKILL_NEUTRALMAGIC);
	float disp_endurance = getstatf(STAT_SKILL_ENDURANCE);
	float disp_spellresist = getstatf(STAT_SKILL_SPELLRESIST);
	float disp_archery = getstatf(STAT_SKILL_ARCHERY);
	float disp_healthregen = getstatf(STAT_SKILL_HEALTHREGEN);
	float disp_manaregen = getstatf(STAT_SKILL_MANAREGEN);
	float disp_haggle = getstatf(STAT_SKILL_HAGGLE);
	float disp_climb = getstatf(STAT_SKILL_CLIMB);
	float disp_swim = getstatf(STAT_SKILL_SWIM);
	float disp_acrobatic = getstatf(STAT_SKILL_ACROBATIC);
	float disp_reapermarks = getstatf(STAT_REAPERMARK);
	float disp_blocking = getstatf(STAT_BLOCKVALUE);
	string disp_magicspell = getstats(STAT_SPELLEQUIPPED);
	float disp_spellmin = getstatf(STAT_SPELLMIN);
	float disp_spellmax = getstatf(STAT_SPELLMAX);
	float atbonfire = getstatf(STAT_BONFIRE);
	float disp_mining = getstatf(STAT_MINING);
	float disp_fishing = getstatf(STAT_FISHING);
	float disp_woodcutting = getstatf(STAT_WOODCUTTING);
	float disp_projmin = getstatf(STAT_PROJ_MIN);
	float disp_projmax = getstatf(STAT_PROJ_MAX);
	float disp_bankgold = getstatf(STAT_GOLD_BANK);
	
	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Display name, gender
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	displaystat = strcat(disp_gender, " ^1", LOGIN_NAME);
	sui_text([2.5, 4], MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// 3D Character box
	pos = [25, 25];
	size = [125, 150];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(pos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(pos, size, MENU_BG_DARK, 0.75, 0);

	// Draw 3D doll model
	pos_x -= 15;
	pos_y -= 65;
	Draw_3DPDoll(pos);

	//Level, Experience, Next Experience
	vector newpos = [2, 20];

	displaystat = strcat("^5Level: ^7", ftos(disp_level));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Exp: ^7", ftos(disp_exp), " / ", ftos(disp_neededexp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Gold: ^7", ftos(disp_gold), "^8 Bank: ", ftos(disp_bankgold));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Skill Points: ^7", ftos(disp_skillpoints));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = strcat("^5Main Hand");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// button to unequip main hand
	newpos_x += 40;
	my_button("unequip_mainhand", newpos, [30, 10], "Unequip") ? sendevent("User_UnequipMainhand", "", 0) : 0;
	newpos_x -= 40;
	
	newpos_y += 10;
	
	displaystat = strcat(disp_mainhand, " (^8", ftos(disp_attackmin), "-", ftos(disp_attackmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	float disp_dps = (disp_attackmin + disp_attackmax * 0.5) / disp_attackspeed; // calculate DPS

	// add skill calculation to DPS
	if (!disp_attacktype) // unarmed
		disp_dps = (disp_unarmed * 0.055) / disp_attackspeed; // unarmed - calculated differently
	else if (disp_attacktype == 1) // slashing
		disp_dps = disp_dps + (disp_slash * 0.1);
	else if (disp_attacktype == 2) // piercing
		disp_dps = disp_dps + (disp_pierce * 0.1);
	else if (disp_attacktype == 3) // bashing
		disp_dps = disp_dps + (disp_bash * 0.1);
	else 						   // archery - calculated differently
	{
		disp_dps = (((disp_attackmin + disp_attackmax) * 0.5) + ((disp_projmin + disp_projmax) * 0.5)) / disp_attackspeed;
		disp_dps += (disp_archery * 0.1);
	}

	string dispfix_dps = ftos(disp_dps);
	dispfix_dps = sprintf("%.2f", disp_dps); // cut down numbers

	if (!disp_attacktype)			string displaystat2 = "Unarmed";
	else if (disp_attacktype == 1)  displaystat2 = "Slash";
	else if (disp_attacktype == 2)  displaystat2 = "Pierce";
	else if (disp_attacktype == 3)  displaystat2 = "Bash";
	else if (disp_attacktype == 4)  displaystat2 = "Projectile";
	else displaystat2 = "Unknown";

	displaystat = strcat("^1DPS: ^7" , dispfix_dps, " (^8", displaystat2, "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = "^5Off Hand";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// button to unequip off hand
	newpos_x += 40;
	my_button("unequip_offhand", newpos, [30, 10], "Unequip") ? sendevent("User_UnequipOffhand", "", 0) : 0;
	newpos_x -= 40;
	
	newpos_y += 10;
	
	displaystat = disp_offhand;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^2Blocking: ^7" , ftos(disp_blocking), "\n");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	//newpos_y += 22;
	newpos_y += 12.5;

	displaystat = strcat("^5Armor: ^7", disp_armorname, " (^2+", ftos(disp_armorvalue), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Magic Spell : ^7", disp_magicspell, " ^7(^8", ftos(disp_spellmin), "-", ftos(disp_spellmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 20;

	displaystat = strcat("^1Reaper Marks: ^7", ftos(disp_reapermarks));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// Draw skill point box/frame/text
	pos = [75, 0];
	size = [250, 280];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	pos = [0, -15];
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text(pos, MENU_TEXT_MEDIUM, "^2Skills", MENU_TEXT_1, 1, 0);

	//
	// skill stats
	//

	// Draw skill point text
	newpos = [5, 7];

	displaystat = strcat("^5Unarmed: ^7", ftos(disp_unarmed));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Slashing: ^7", ftos(disp_slash));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Piercing: ^7", ftos(disp_pierce));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Bashing: ^7", ftos(disp_bash));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	newpos_y +=10;

	displaystat = strcat("^5Stealth: ^7", ftos(disp_stealth));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	newpos_y +=10;

	displaystat = strcat("^5Backstab: ^7", ftos(disp_backstab));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	newpos_y +=10;

	displaystat = strcat("^5Offensive Magic: ^7", ftos(disp_offensivemagic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Defensive Magic: ^7", ftos(disp_defensivemagic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Neutral Magic: ^7", ftos(disp_neutralmagic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Endurance: ^7", ftos(disp_endurance));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Spell Resist: ^7", ftos(disp_spellresist));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Archery: ^7", ftos(disp_archery));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Health Regen: ^7", ftos(disp_healthregen));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Mana Regen: ^7", ftos(disp_manaregen));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Haggling: ^7", ftos(disp_haggle));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Climbing: ^7", ftos(disp_climb));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Swimming: ^7", ftos(disp_swim));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Acrobatics: ^7", ftos(disp_acrobatic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	//
	// skill buttons for stat increases
	//


	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	newpos = [-5, 5]; // reset newpos

	if (atbonfire && disp_skillpoints > 0)
	{
		vector drawline_pos;
		float line_length = 118;
		drawline_pos = [25, -5];
		
		my_button("skillpoint_unarmed", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 0) : 0;
		newpos_y +=10;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		my_button("skillpoint_slash", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 1) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_pierce", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 2) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_bash", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 3) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_stealth", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 4) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_backstab", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 5) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_offensivemagic", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 6) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_defensivemagic", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 7) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_neutralmagic", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 8) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_endurance", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 9) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_spellresist", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 10) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_archery", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 11) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_healthregen", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 12) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_manaregen", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 13) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_haggling", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 14) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_climbing", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 15) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_swimming", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 16) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		my_button("skillpoint_acrobatics", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 17) : 0;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
		newpos_y +=10;
		sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], '1 1 1', 1);
	}

	// Job skills
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	line_length = 245;
	drawline_pos = [0, 0];
	newpos = [2.5, 50];

	// seperation line
	sui_line(newpos, 1, [drawline_pos_x, drawline_pos_y], [drawline_pos_x + line_length, drawline_pos_y], MENU_BORDER, 1);
	newpos_x = 5;
	
	newpos_y += 10;
	
	string e = sprintf("%.1f", disp_mining);
	displaystat = strcat("^5Mining: ^7", e);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	displaystat = strcat("^5Fishing: ^7", ftos(disp_fishing));
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	string f = sprintf("%.1f", disp_woodcutting);

	displaystat = strcat("^5Wood Cutting: ^7", f);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	//
	// Bottom button list
	//

	newpos = [3, -2]; // reset newpos

	// PVP button
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	float disp_pvp = getstatf(STAT_PVP);
	if (!disp_pvp)
		string pvpcolor = "^8PVP";
	else if (disp_pvp == 1)
		pvpcolor = "^1PVP";
	else
		pvpcolor = "^2PVP";

	my_button("pvp_toggle", newpos, [25, 25], pvpcolor) ? sendevent("User_TogglePVP", "") : 0;

	newpos_x += 26;
	my_button("stats_toggle", newpos, [72, 25], "Skills") ? sendevent("PlayerShowStats", "") : 0;
	newpos_x += 73;
	my_button("magic_toggle", newpos, [72, 25], "Magic") ? sendevent("PlayerShowMagic", "") : 0;
	newpos_x += 73;
	my_button("inventory_toggle", newpos, [72, 25], "Inventory") ? sendevent("PlayerShowInventory", "") : 0;

	sui_pop_frame();
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X") ? sendevent("ShutDownMenus", "") : 0;

	sui_pop_frame();

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("disconnect", [0, 0], [40, 20], "Disconnect") ? localcmd("cfg_save;disconnect\n") : 0;
};

//
// Character inventory screen + use/drop items
//

void() User_InventoryScreen =
{
	float get_h = getstatf(STAT_HEALTH);
	if (get_h <= 0)
		return;

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	string displaystat;

	string disp_gender = getstats(STAT_GENDER);
	float disp_level = getstatf(STAT_LEVEL);
	float disp_exp =  getstatf(STAT_EXP);
	float disp_neededexp =  getstatf(STAT_EXPNEEDED);
	float disp_gold =  getstatf(STAT_GOLD);
	float disp_skillpoints =  getstatf(STAT_SKILLPOINTS);
	string disp_mainhand = getstats(STAT_MAINHAND);
	string disp_offhand = getstats(STAT_OFFHAND);
	float disp_attackmin = getstatf(STAT_ATTACKMIN);
	float disp_attackmax = getstatf(STAT_ATTACKMAX);
	float disp_attackspeed = getstatf(STAT_ATTACKSPEED);
	float disp_attacktype = getstatf(STAT_ATTACKTYPE);
	string disp_armorname = getstats(STAT_ARMORNAME);
	float disp_armorvalue = getstatf(STAT_ARMORVALUE);
	float disp_unarmed = getstatf(STAT_SKILL_UNARMED);
	float disp_slash = getstatf(STAT_SKILL_SLASH);
	float disp_pierce = getstatf(STAT_SKILL_PIERCE);
	float disp_bash = getstatf(STAT_SKILL_BASH);
	float disp_archery = getstatf(STAT_SKILL_ARCHERY);
	float disp_reapermarks = getstatf(STAT_REAPERMARK);
	float disp_blocking = getstatf(STAT_BLOCKVALUE);
	string disp_magicspell = getstats(STAT_SPELLEQUIPPED);
	float disp_spellmin = getstatf(STAT_SPELLMIN);
	float disp_spellmax = getstatf(STAT_SPELLMAX);
	float disp_projmin = getstatf(STAT_PROJ_MIN);
	float disp_projmax = getstatf(STAT_PROJ_MAX);
	float disp_bankgold = getstatf(STAT_GOLD_BANK);

	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Display name, gender
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	displaystat = strcat(disp_gender, " ^1", LOGIN_NAME);
	sui_text([2.5, 4], MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// 3D Character box
	pos = [25, 25];
	size = [125, 150];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(pos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(pos, size, MENU_BG_DARK, 0.75, 0);

	// Draw 3D doll model
	pos_x -= 15;
	pos_y -= 65;
	Draw_3DPDoll(pos);

	//Level, Experience, Next Experience
	vector newpos = [2, 20];

	displaystat = strcat("^5Level: ^7", ftos(disp_level));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Exp: ^7", ftos(disp_exp), " / ", ftos(disp_neededexp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Gold: ^7", ftos(disp_gold), "^8 Bank: ", ftos(disp_bankgold));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Skill Points: ^7", ftos(disp_skillpoints));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = strcat("^5Main Hand");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	// button to unequip main hand
	newpos_x += 40;
	my_button("unequip_mainhand", newpos, [30, 10], "Unequip") ? sendevent("User_UnequipMainhand", "", 0) : 0;
	newpos_x -= 40;

	newpos_y += 10;
	
	displaystat = strcat(disp_mainhand, " (^8", ftos(disp_attackmin), "-", ftos(disp_attackmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	float disp_dps = (disp_attackmin + disp_attackmax * 0.5) / disp_attackspeed; // calculate DPS
	
	// add skill calculation to DPS
	if (!disp_attacktype) // unarmed
		disp_dps = (disp_unarmed * 0.055) / disp_attackspeed; // unarmed - calculated differently
	else if (disp_attacktype == 1) // slashing
		disp_dps = disp_dps + (disp_slash * 0.1);
	else if (disp_attacktype == 2) // piercing
		disp_dps = disp_dps + (disp_pierce * 0.1);
	else if (disp_attacktype == 3) // bashing
		disp_dps = disp_dps + (disp_bash * 0.1);
	else 						   // archery - calculated differently
	{
		disp_dps = (((disp_attackmin + disp_attackmax) * 0.5) + ((disp_projmin + disp_projmax) * 0.5)) / disp_attackspeed;
		disp_dps += (disp_archery * 0.1);
	}

	string dispfix_dps = ftos(disp_dps);
	dispfix_dps = sprintf("%.2f", disp_dps); // cut down numbers

	if (!disp_attacktype)			string displaystat2 = "Unarmed";
	else if (disp_attacktype == 1)  displaystat2 = "Slash";
	else if (disp_attacktype == 2)  displaystat2 = "Pierce";
	else if (disp_attacktype == 3)  displaystat2 = "Bash";
	else if (disp_attacktype == 4)  displaystat2 = "Projectile";
	else displaystat2 = "Unknown";

	displaystat = strcat("^1DPS: ^7" , dispfix_dps, " (^8", displaystat2, "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = "^5Off Hand";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// button to unequip off hand
	newpos_x += 40;
	my_button("unequip_offhand", newpos, [30, 10], "Unequip") ? sendevent("User_UnequipOffhand", "", 0) : 0;
	newpos_x -= 40;

	newpos_y += 10;

	displaystat = disp_offhand;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^2Blocking: ^7" , ftos(disp_blocking), "\n");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	//newpos_y += 22;
	newpos_y += 12.5;

	displaystat = strcat("^5Armor: ^7", disp_armorname, " (^2+", ftos(disp_armorvalue), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Magic Spell : ^7", disp_magicspell, " ^7(^8", ftos(disp_spellmin), "-", ftos(disp_spellmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 20;

	displaystat = strcat("^1Reaper Marks: ^7", ftos(disp_reapermarks));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// Draw inventory point box/frame/text
	pos = [75, 0];
	size = [250, 280];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	pos = [0, -15];
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text(pos, MENU_TEXT_MEDIUM, "^2Inventory", MENU_TEXT_1, 1, 0);

	//
	// inventory item display
	//

	newpos = [2.5, 2.5];
	vector buttonpos = [-2.5, 2.5];
	vector linepos = [2.5, 2.5];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	float i;
	string j = "";
	string d = "";
	string desc = "";

    for (i = 0; i < inv_count; i++)
    {
		string item_disp = strcat("^5", inventory[i], " ^7[^2", ftos(inventory_count[i]), "^7]");
		if (inventory_count[i] > 0)
		{
			float usebutton_count = 0;
			while (usebutton_count < inventory_count[i]) // setup use buttons
			{
				usebutton_count += 1;
				j = strcat("u_", inventory[i]); // use
				d = strcat("d_", string_remove_spaces(inventory[i])); // drop
				desc = strcat("desc_", string_remove_spaces(inventory[i])); // tooltip display
			}
			
			//sui_text(linepos, MENU_TEXT_SMALL, item_disp, MENU_TEXT_1, 1, 0);

			sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
			buttonpos_x = -2.5;
			my_button(j, buttonpos, [32, 10], "Use") ? sendevent("UseItem", "s", inventory[i]) : 0;
			buttonpos_x = -34;
			my_button(d, buttonpos, [32, 10], "Drop") ? sendevent("DropItem", "s", inventory[i]) : 0;
			sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

			// tooltip (draw last)
			float hover_text_size = stringwidth(inventory[i], 1);
			sui_tooltip(desc, linepos, [hover_text_size * 8, 8], item_disp);

		}
		linepos_y += 10;
		buttonpos_y += 10;
    }

	//
	// Bottom button list
	//

	newpos = [3, -2]; // reset newpos

	// PVP button
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	float disp_pvp = getstatf(STAT_PVP);
	if (!disp_pvp)
		string pvpcolor = "^8PVP";
	else if (disp_pvp == 1)
		pvpcolor = "^1PVP";
	else
		pvpcolor = "^2PVP";

	my_button("pvp_toggle", newpos, [25, 25], pvpcolor) ? sendevent("User_TogglePVP", "") : 0;

	newpos_x += 26;
	my_button("stats_toggle", newpos, [72, 25], "Skills") ? sendevent("PlayerShowStats", "") : 0;
	newpos_x += 73;
	my_button("magic_toggle", newpos, [72, 25], "Magic") ? sendevent("PlayerShowMagic", "") : 0;
	newpos_x += 73;
	my_button("inventory_toggle", newpos, [72, 25], "Inventory") ? sendevent("PlayerShowInventory", "") : 0;

	sui_pop_frame();
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X") ? sendevent("ShutDownMenus", "") : 0;

	sui_pop_frame();

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("disconnect", [0, 0], [40, 20], "Disconnect") ? localcmd("cfg_save;disconnect\n") : 0;
};

//
// Character inventory screen + use/drop items
//

void() User_MagicScreen =
{
	float get_h = getstatf(STAT_HEALTH);
	if (get_h <= 0)
		return;

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	string displaystat;

	string disp_gender = getstats(STAT_GENDER);
	float disp_level = getstatf(STAT_LEVEL);
	float disp_exp =  getstatf(STAT_EXP);
	float disp_neededexp =  getstatf(STAT_EXPNEEDED);
	float disp_gold =  getstatf(STAT_GOLD);
	float disp_skillpoints =  getstatf(STAT_SKILLPOINTS);
	string disp_mainhand = getstats(STAT_MAINHAND);
	string disp_offhand = getstats(STAT_OFFHAND);
	float disp_attackmin = getstatf(STAT_ATTACKMIN);
	float disp_attackmax = getstatf(STAT_ATTACKMAX);
	float disp_attackspeed = getstatf(STAT_ATTACKSPEED);
	float disp_attacktype = getstatf(STAT_ATTACKTYPE);
	string disp_armorname = getstats(STAT_ARMORNAME);
	float disp_armorvalue = getstatf(STAT_ARMORVALUE);
	float disp_unarmed = getstatf(STAT_SKILL_UNARMED);
	float disp_slash = getstatf(STAT_SKILL_SLASH);
	float disp_pierce = getstatf(STAT_SKILL_PIERCE);
	float disp_bash = getstatf(STAT_SKILL_BASH);
	float disp_reapermarks = getstatf(STAT_REAPERMARK);
	float disp_blocking = getstatf(STAT_BLOCKVALUE);
	string disp_magicspell = getstats(STAT_SPELLEQUIPPED);
	float disp_spellmin = getstatf(STAT_SPELLMIN);
	float disp_spellmax = getstatf(STAT_SPELLMAX);
	float disp_projmin = getstatf(STAT_PROJ_MIN);
	float disp_projmax = getstatf(STAT_PROJ_MAX);
	float disp_archery = getstatf(STAT_SKILL_ARCHERY);
	float disp_bankgold = getstatf(STAT_GOLD_BANK);

	vector pos = [0, 0];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Display name, gender
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	displaystat = strcat(disp_gender, " ^1", LOGIN_NAME);
	sui_text([2.5, 4], MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// 3D Character box
	pos = [25, 25];
	size = [125, 150];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(pos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(pos, size, MENU_BG_DARK, 0.75, 0);

	// Draw 3D doll model
	pos_x -= 15;
	pos_y -= 65;
	Draw_3DPDoll(pos);

	//Level, Experience, Next Experience
	vector newpos = [2, 20];

	displaystat = strcat("^5Level: ^7", ftos(disp_level));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Exp: ^7", ftos(disp_exp), " / ", ftos(disp_neededexp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Gold: ^7", ftos(disp_gold), "^8 Bank: ", ftos(disp_bankgold));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Skill Points: ^7", ftos(disp_skillpoints));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = strcat("^5Main Hand");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	// button to unequip main hand
	newpos_x += 40;
	my_button("unequip_mainhand", newpos, [30, 10], "Unequip") ? sendevent("User_UnequipMainhand", "", 0) : 0;
	newpos_x -= 40;

	newpos_y += 10;
	
	displaystat = strcat(disp_mainhand, " (^8", ftos(disp_attackmin), "-", ftos(disp_attackmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	float disp_dps = (disp_attackmin + disp_attackmax * 0.5) / disp_attackspeed; // calculate DPS
	
	// add skill calculation to DPS
	if (!disp_attacktype) // unarmed
		disp_dps = (disp_unarmed * 0.055) / disp_attackspeed; // unarmed - calculated differently
	else if (disp_attacktype == 1) // slashing
		disp_dps = disp_dps + (disp_slash * 0.1);
	else if (disp_attacktype == 2) // piercing
		disp_dps = disp_dps + (disp_pierce * 0.1);
	else if (disp_attacktype == 3) // bashing
		disp_dps = disp_dps + (disp_bash * 0.1);
	else 						   // archery - calculated differently
	{
		disp_dps = (((disp_attackmin + disp_attackmax) * 0.5) + ((disp_projmin + disp_projmax) * 0.5)) / disp_attackspeed;
		disp_dps += (disp_archery * 0.1);
	}

	string dispfix_dps = ftos(disp_dps);
	dispfix_dps = sprintf("%.2f", disp_dps); // cut down numbers

	if (!disp_attacktype)			string displaystat2 = "Unarmed";
	else if (disp_attacktype == 1)  displaystat2 = "Slash";
	else if (disp_attacktype == 2)  displaystat2 = "Pierce";
	else if (disp_attacktype == 3)  displaystat2 = "Bash";
	else if (disp_attacktype == 4)  displaystat2 = "Projectile";
	else displaystat2 = "Unknown";

	displaystat = strcat("^1DPS: ^7" , dispfix_dps, " (^8", displaystat2, "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = "^5Off Hand";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// button to unequip off hand
	newpos_x += 40;
	my_button("unequip_offhand", newpos, [30, 10], "Unequip") ? sendevent("User_UnequipOffhand", "", 0) : 0;
	newpos_x -= 40;

	newpos_y += 10;

	displaystat = disp_offhand;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^2Blocking: ^7" , ftos(disp_blocking), "\n");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	//newpos_y += 22;
	newpos_y += 12.5;

	displaystat = strcat("^5Armor: ^7", disp_armorname, " (^2+", ftos(disp_armorvalue), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Magic Spell : ^7", disp_magicspell, " ^7(^8", ftos(disp_spellmin), "-", ftos(disp_spellmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 20;

	displaystat = strcat("^1Reaper Marks: ^7", ftos(disp_reapermarks));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// Draw inventory point box/frame/text
	pos = [75, 0];
	size = [250, 280];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	pos = [0, -15];
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text(pos, MENU_TEXT_MEDIUM, "^2Magic", MENU_TEXT_1, 1, 0);

	//
	// magic spell list display
	//

	newpos = [2.5, 2.5];
	vector buttonpos = [-2.5, 2.5];
	vector linepos = [2.5, 2.5];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	float i;
	string j = "";
	string desc = "";

    for (i = 0; i < spell_count; i++)
    {
		string spell_disp = strcat("^5", spell[i], "\n");
		if (spell[i])
		{
			float usebutton_count = 0;
			while (usebutton_count < spell_count) // setup use buttons
			{
				usebutton_count += 1;
				j = strcat("u_", spell[i]); // use
				desc = strcat("desc_", string_remove_spaces(spell[i])); // tooltip display
			}

			sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
			buttonpos_x = -2.5;
			my_button(j, buttonpos, [32, 10], "Equip")  ? sendevent("EquipSpell", "s", spell[i]) : 0;

			sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

			// tooltip (draw last)
			float hover_text_size = stringwidth(spell[i], 1);
			sui_tooltip(desc, linepos, [hover_text_size * 8, 8], spell_disp);
		}
		linepos_y += 10;
		buttonpos_y += 10;
    }

	//
	// Bottom button list
	//

	newpos = [3, -2]; // reset newpos

	// PVP button
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	float disp_pvp = getstatf(STAT_PVP);
	if (!disp_pvp)
		string pvpcolor = "^8PVP";
	else if (disp_pvp == 1)
		pvpcolor = "^1PVP";
	else
		pvpcolor = "^2PVP";

	my_button("pvp_toggle", newpos, [25, 25], pvpcolor) ? sendevent("User_TogglePVP", "") : 0;

	newpos_x += 26;
	my_button("stats_toggle", newpos, [72, 25], "Skills") ? sendevent("PlayerShowStats", "") : 0;
	newpos_x += 73;
	my_button("magic_toggle", newpos, [72, 25], "Magic") ? sendevent("PlayerShowMagic", "") : 0;
	newpos_x += 73;
	my_button("inventory_toggle", newpos, [72, 25], "Inventory") ? sendevent("PlayerShowInventory", "") : 0;

	sui_pop_frame();
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	my_button("close", [0, 0], [15, 15], "X") ? sendevent("ShutDownMenus", "") : 0;

	sui_pop_frame();

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("disconnect", [0, 0], [40, 20], "Disconnect") ? localcmd("cfg_save;disconnect\n") : 0;
};