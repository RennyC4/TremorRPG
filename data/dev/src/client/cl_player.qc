void() Compass_Draw;
void() Coords_Draw;

void() CSQC_Input_Frame =
{
	input_movevalues_x = bound(-350, input_movevalues_x, 350);
	input_movevalues_y = bound(-350, input_movevalues_y, 350);
	input_movevalues_z = bound(-350, input_movevalues_z, 350);
};

string nightskybox = "skyworld_star";
string dayskybox = "";
void() Player_DayNightHandler =
{
	if (timeofday == 0) // day
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 1)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "1");
			cvar_set("r_skybox", dayskybox);
			localcmd("fog 0.02\n");
			cvar_set("r_skyfog", "0.5");
			cvar_set("v_cshift_empty", "0 0 0");
		}
	}
	else if (timeofday == 1) // night
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.1)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.1");
			cvar_set("r_skybox", nightskybox);
			localcmd("fog 0.04 0\n");
			cvar_set("r_skyfog", "0");
			cvar_set("v_cshift_empty", "0 0 50 125");
		}
	}
	else // mid afternoon/early morning
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.5)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.5");
			cvar_set("r_skybox", dayskybox);
			localcmd("fog 0.035\n");
			cvar_set("r_skyfog", "0.25");
			cvar_set("v_cshift_empty", "0 0 0");
		}
	}
};

void() Player_Hud =
{
	if (cvar("developer") == 0)
	{
		float player_loggedin = getstatf(STAT_LOGGEDIN);
		float player_menu = getstatf(STAT_MENU);
		if (player_menu > 0)
		{
			setcursormode(TRUE,"gfx/xhair", [5, 5], cvar("vid_conautoscale")); // enable mouse cursor when menus are active

			if (player_menu == MENU_LOGIN)
				User_LoginScreen();
			else
			{
				Draw_Health();
				Draw_Mana();
				Draw_Stamina();
				Draw_Exp();
				Draw_InCombatorPVP();
			}

			if (player_menu == MENU_CHARACTER)
				User_CharacterScreen();
			if (player_menu == MENU_INVENTORY)
			{
				User_InventoryScreen();
				Draw_ToolTip();
			}
			if (player_menu == MENU_MAGIC)
			{
				User_MagicScreen();
				Draw_ToolTip();
			}
			if (player_menu == MENU_DIALOGUE)
				User_NPCDialogue();
			if (player_menu == MENU_BUYSELL)
			{
				User_NPCBuySell();
				Draw_ToolTip();
			}
		}
		else // Regular gameplay
		{
			float zonedisplay_finished = getstatf(STAT_ZONENAME_TIME);
			if (zonedisplay_finished > time)
				Draw_ZoneName(g_width, g_height);
			else
				ZoneName_alpha.doalpha = 0;

			Draw_EventLog();
			Draw_Health();
			Draw_Mana();
			Draw_Stamina();
			Draw_Exp();
			Draw_InCombatorPVP();

			Compass_Draw();
			Coords_Draw();

			setcursormode(FALSE,"", 0, 0);
		}
		Player_DayNightHandler();
	}

	float lockon = getstatf(STAT_LOCKEDON);
	if (lockon)
	{
		// Get CSQC info
		// Setup
		vector plaque_pos = [LOCKON_COORD_X, LOCKON_COORD_Y, LOCKON_COORD_Z];
		vector player_pos = [getstatf(STAT_PLAYER_X), getstatf(STAT_PLAYER_Y), getstatf(STAT_PLAYER_Z)];
		vector plaque_coord = project(plaque_pos);

		plaque_coord_x -= 16; // center it
		plaque_coord_y -= 24;

		drawstring(plaque_coord, LOCKON_NAME, 10, [1, 1, 1], 1, 0);

		// Draw bar + level
		plaque_coord_x -= 12;
		plaque_coord_y += 8;

		vector hbar_size = '50 4 0';
		hbar_size_x = (LOCKON_HEALTH / LOCKON_MAXHEALTH) * hbar_size_x; // keep bar updated
		drawfill(plaque_coord + [0 , 2], hbar_size, '0.5 0 0', 1, 0);

		plaque_coord_x += 28;
		string lvl = ftos(LOCKON_LEVEL);
		drawstring(plaque_coord + [24, 0], lvl, 8, [1, .8, 0], 1, 0);
	}
};