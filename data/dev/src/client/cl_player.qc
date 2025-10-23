void() Camera_IdleOrbit;
void() Compass_Draw;
void() Coords_Draw;
void() Player_Animate;
void() Draw_NameTag;
void() OtherPlayer_Anistate;

.entity lantern_vfx;
.entity weapon_vfx;
.entity offhand_vfx;

//
// Player skeleton attach objects
//

void() Skeleton_ObjectDraw =
{
	if (!self.loggedin && self.classname == "player")
		return;

	string gender = getstats(STAT_GENDER); // TODO? send .gender from SSQC, this is shared with monsters that use player bones

	if (!self.skeletonindex)
	{
		self.skeletonindex = skel_create(self.modelindex);
		self.frame = frameforname(self.modelindex, "Idle");
	}
	skel_build(self.skeletonindex, self, self.modelindex, 0, 0, 0, 1);

	// draw lantern
	if (self.effects == EF_BRIGHTLIGHT)
	{
		var float PART_LANTERN = particleeffectnum("lantern");
		
		if (!self.lantern_vfx)
		{
			self.lantern_vfx = spawn();
			self.lantern_vfx.owner = self;
			self.lantern_vfx.drawmask = MASK_VIEWMODEL;

			setmodel(self.lantern_vfx, "models/lantern.glb");
		}
		else
		{
			vector org = gettaginfo(self, gettagindex(self, "mixamorig:RightUpLeg"));
			if (gender == "Male") // offset relative to the bone
				vector offset = '24 -26 0';
			else
				offset = '16 -18 0';

			// local offset into world space
			org += v_forward * offset_x;
			org += v_right   * offset_y;
			org += v_up      * offset_z;
			self.lantern_vfx.origin = org;

			// fix angles
			vector ang = vectoangles(v_forward, v_up);
			ang_z += (-1 * ang_z); // flip
			self.lantern_vfx.angles = ang;

			if (camera_mode)
				pointparticles(PART_LANTERN, org, [0, 0, 0]);

			dynamiclight_add(org, 700, [1, .7, .7], 1, "", PFLAGS_CORONA);
		}
	}
	else if (self.lantern_vfx)
	{
		remove(self.lantern_vfx);
		self.lantern_vfx = world;
	}

	// draw weapon
	if (self.main_hand != "" && self.main_hand != "Unarmed")
	{
		if (!self.weapon_vfx)
		{
			self.weapon_vfx = spawn();
			self.weapon_vfx.drawmask = MASK_VIEWMODEL;
		}
		else
		{
			//
			// Models to draw
			//
			
			if (!self.bonfire)
			{
				// Swords
				if (self.main_hand == "Broken Sword")
					setmodel(self.weapon_vfx, "models/sword0.glb");
				if (self.main_hand == "Short Sword")
					setmodel(self.weapon_vfx, "models/sword1.glb");

				// Daggers
				if (self.main_hand == "Rusty Dagger")
					setmodel(self.weapon_vfx, "models/dagger0.glb");
			}
			else
				setmodel(self.weapon_vfx, __NULL__);
			//
			//
			//

			org = gettaginfo(self, gettagindex(self, "mixamorig:RightHand"));
			offset = '0 0 0';  // offset relative to the bone
			if (gender == "Female")
				offset = '0 10 0';

			// local offset into world space
			org += v_forward * offset_x;
			org += v_right   * offset_y;
			org += v_up      * offset_z;
			self.weapon_vfx.origin = org;

			// angles
			ang = vectoangles(v_forward, v_up);
			self.weapon_vfx.angles = ang;
		}
	}
	else if (self.weapon_vfx)
	{
		remove(self.weapon_vfx);
		self.weapon_vfx = world;
	}

	// draw offhand
	if (self.off_hand != "" && self.off_hand != "Empty")
	{
		if (!self.offhand_vfx)
		{
			self.offhand_vfx = spawn();
			self.offhand_vfx.drawmask = MASK_VIEWMODEL;
		}
		else
		{
			//
			// Models to draw
			//

			if (!self.bonfire)
			{
				// Shields
				if (self.off_hand == "Broken Buckler")
					setmodel(self.offhand_vfx, "models/shield0.glb");
				if (self.off_hand == "Flimsy Buckler")
					setmodel(self.offhand_vfx, "models/shield1.glb");
			}
			else
				setmodel(self.offhand_vfx, __NULL__);
			//
			//
			//

			org = gettaginfo(self, gettagindex(self, "mixamorig:LeftHand"));
			offset = '0 0 0';  // offset relative to the bone

			// local offset into world space
			org += v_forward * offset_x;
			org += v_right   * offset_y;
			org += v_up      * offset_z;

			self.offhand_vfx.origin = org;

			// angles
			ang = vectoangles(v_forward, v_up);
			self.offhand_vfx.angles = ang;
		}
	}
	else if (self.offhand_vfx)
	{
		remove(self.offhand_vfx);
		self.offhand_vfx = world;
	}
};

//
// String parms
//

void() sParms_Read =
{
	string line;

	float v = fopen("sparms", FILE_READ); // read sParms
	if (v)
	{
		if (line = fgets(v)) // skip first line
		if (line = fgets(v))
			sparm1 = line;
		if (line = fgets(v))
			sparm2 = line;
		if (line = fgets(v))
			sparm3 = line;
		if (line = fgets(v))
			sparm4 = line;
		fclose(v);
	}
	sendevent("SSQC_ReadsParms", "ssss", sparm1, sparm2, sparm3, sparm4); // send sParms to SSQC
};

void() sParms_Write =
{
	sparm1 = getstats(STAT_MAINHAND);
	sparm2 = getstats(STAT_OFFHAND);
	sparm3 = getstats(STAT_ARMORNAME);
	sparm4 = getstats(STAT_SPELLEQUIPPED);

	float v = fopen("sparms", FILE_WRITE); // write sParm file
	if (v)
	{
		fputs(v, LOGIN_NAME, "\n");
		fputs(v, sparm1, "\n");
		fputs(v, sparm2, "\n");
		fputs(v, sparm3, "\n");
		fputs(v, sparm4, "\n");
		fclose(v);
	}
};

void() sParms_Wipe =
{
	float v = fopen("sparms", FILE_WRITE); // write and wipe sParm file
	if (v)
	{
		fputs(v, "");
		fclose(v);
	}
};

//
//

void() CSQC_Input_Frame =
{
	input_movevalues_x = bound(-350, input_movevalues_x, 350);
	input_movevalues_y = bound(-350, input_movevalues_y, 350);
	input_movevalues_z = bound(-350, input_movevalues_z, 350);
};

string nightskybox = "skyworld_star";
string dayskybox = "";
const float TIME_DAWN = 0;
const float TIME_DAY = 1;
const float TIME_DUSK = 2;
const float TIME_NIGHT = 3;

void() Player_DayNightHandler =
{
	if (timeofday == TIME_DAY) // day
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
	else if (timeofday == TIME_NIGHT) // night
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.1)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.1");
			cvar_set("r_skybox", nightskybox);
			localcmd("fog 0.05 0\n");
			cvar_set("r_skyfog", "0");
			cvar_set("v_cshift_empty", "0 0 50 125");
		}
	}
	else if (timeofday == TIME_DAWN) // early morning (dawn)
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
	else // sunset (dusk)
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.25)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.25");
			cvar_set("r_skybox", dayskybox);
			localcmd("fog 0.035 0.3 .15 0 1\n");
			cvar_set("r_skyfog", "0.8");
			cvar_set("v_cshift_empty", "130 25 0 32");
		}
	}
};

void() Player_Hud =
{
	if (cvar("developer") != 0)
		return;

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
		float health = getstatf(STAT_HEALTH);
		float casting = getstatf(STAT_CASTING);
		float atbonfire = getstatf(STAT_BONFIRE);

		if (zonedisplay_finished > time)
			Draw_ZoneName(g_width, g_height);
		else
			ZoneName_alpha.doalpha = 0;

		Draw_NameTag();
		if (!player_idle && health > 0)
		{
			Draw_EventLog();
			Draw_Health();
			Draw_Mana();
			Draw_Stamina();
			Draw_Exp();
			Draw_InCombatorPVP();
			if (autocvar_minimap != "off" && autocvar_minimap != "")
			{
				if (substring(world.model, -3, 3) == "hmp") // mini-map only on over world
					WorldMap_Draw([g_width - 112.5, 0], [112.5, 112.5]);
			}
			Compass_Draw();
			Coords_Draw();
			if (casting > time)
				Draw_CastingStat();
		}

		// bonfire SP reminder text
		if (atbonfire)
		{
			string msg1 = "You possess skill points!";
			float tw = (stringwidth(msg1, 0, [12,12]) / 2);
			vector txtpos = [(g_width * 0.5) - tw, g_height - 25];
			float fade = 0.5 + 0.5 * sin(time * 2);
			vector colour = [fade, 0, 0];

			drawstring (txtpos + [1,1], msg1, [12, 12], '0 0 0', 1, 0);
			drawstring (txtpos, msg1, [12, 12], colour, 1, 0);
		}

		if (time - last_input_time > idle_threshold)
			player_idle = TRUE; // turn on camera orbit

		setcursormode(FALSE,"", 0, 0);
	}
	Player_DayNightHandler();
};

void() Player_Think;
float(void) Player_PreDraw =
{
    if (self.entnum == player_localentnum)
	{
		Player_Animate();

		self.movetype = MOVETYPE_WALK;

		// prepare rollback
		vector vOldOrigin = self.origin;
		vector vOldVelocity = self.velocity;
		float fOldPMoveFlags = self.pmove_flags;

		// apply physics for every single input-frame that has not yet been
		// acknowledged by the server (servercommandframe = last acknowledged frame)
		for (int i = servercommandframe + 1; i <= clientcommandframe; i++)
		{
			float flSuccess = getinputstate(i);

			if (flSuccess == FALSE)
				continue;

			if (input_timelength == 0) // Partial frames are the worst
				break;

			runstandardplayerphysics(self);
		}

		// draw objects on bones (armor, lantern, swords, etc)
		Skeleton_ObjectDraw();

		vPlayerOriginOld = vPlayerOrigin; // smooth stair stepping, this has to be done manually!

		if ((self.flags & FL_ONGROUND) && (self.origin_z - vPlayerOriginOld_z > 0))
		{
			vPlayerOriginOld_z += frametime * 150;

			if (vPlayerOriginOld_z > self.origin_z)
				vPlayerOriginOld_z = self.origin_z;
			if (self.origin_z - vPlayerOriginOld_z > 18)
				vPlayerOriginOld_z = self.origin_z - 18;

			vPlayerOrigin_z += vPlayerOriginOld_z - self.origin_z;
		}
		else
			vPlayerOriginOld_z = self.origin_z;

		vPlayerOrigin = [self.origin_x, self.origin_y, vPlayerOriginOld_z];
		vPlayerVelocity = self.velocity;
		addentity(self);

		// time to roll back
		self.origin = vOldOrigin;
		setorigin(self, self.origin);
		self.velocity = vOldVelocity;
		self.pmove_flags = fOldPMoveFlags;
		self.movetype = MOVETYPE_NONE;

		self.renderflags = RF_EXTERNALMODEL; // set renderflag for mirrors!

		Player_Think();
	}
	else // other players
	{
		if (self.anistate)
			OtherPlayer_Anistate();
		else
			Player_Animate();

		Skeleton_ObjectDraw();
        addentity(self);
	}

    return PREDRAW_NEXT;
};

.float attack_released;
.float anim_attacking;
.float attack_finished;
void() Player_Think =
{
	float player_menu = getstatf(STAT_MENU);
	float atbonfire = getstatf(STAT_BONFIRE);

	if (!player_menu)
	{
		if (input_buttons & 1) // attack button
		{
			if (self.attack_released && !atbonfire)
			{
				float stamina = getstatf(STAT_STAMINA);
				float skill_endurance = getstatf(STAT_SKILL_ENDURANCE);
				float attack_stamina = getstatf(STAT_ATTACKSTAM);
				float attackspeed = getstatf(STAT_ATTACKSPEED);
				float stamcalc = skill_endurance * 0.015; // calculation

				if (stamina >= attack_stamina && self.attack_finished < time) // stamina drain on swing
				{
					sendevent("User_StartAttack", "");
					if (self.health > 0 && !button4) // don't do attack animation when holding block
						self.anim_attacking = TRUE;
					self.attack_finished = time + attackspeed;
				}
			}
			self.attack_released = FALSE;
		}
		else
			self.attack_released = TRUE;
	}

	if (self.health > 0)
	{
		if (deathcam_dist != 45)
			deathcam_dist = 45; // initial z start org for death camera

		// Binding stuff working around
		if (LockOn_Toggle)
		{
			CSQC_LockOn_Toggle();
			LockOn_Toggle = FALSE;
		}
		if (LockOn_CycleToggle)
		{
			CSQC_LockOn_Cycle();
			LockOn_CycleToggle = FALSE;
		}
	}
};