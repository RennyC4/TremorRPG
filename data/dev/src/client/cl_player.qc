void() CSQC_Input_Frame =
{
	input_movevalues_x = bound(-350, input_movevalues_x, 350);
	input_movevalues_y = bound(-350, input_movevalues_y, 350);
	input_movevalues_z = bound(-350, input_movevalues_z, 350);
};

void() Player_Hud =
{
	if (cvar("developer") == 0)
	{
		float player_loggedin = getstatf(STAT_LOGGEDIN);
		float player_menu = getstatf(STAT_MENU);
		if (player_menu > 0)
		{
			setcursormode(TRUE,"gfx/xhair", [16, 16], cvar("vid_conautoscale")); // enable mouse cursor when menus are active

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
				User_InventoryScreen();
			if (player_menu == MENU_DIALOGUE)
				User_NPCDialogue(); // Remove me
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

			setcursormode(FALSE,"", 0, 0);
		}
	}
};