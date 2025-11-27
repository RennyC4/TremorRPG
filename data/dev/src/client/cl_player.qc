void() Camera_IdleOrbit;
void() Compass_Draw;
void() Coords_Draw;
void() Player_Animate;
void() OtherPlayer_Anistate;
void() Skeleton_Animate;
void() CSQC_DayNight_Update;
void(entity pl) DrawFloatingText;
void() Player_Think;

.float attack_released;
.float anim_attacking;
.float attack_finished;
.float respawn_finished;

.entity lantern_vfx;
.entity weapon_vfx;
.entity offhand_vfx;
.entity arrow_vfx;
.entity armor_vfx;

string nightskybox = "skyworld_star";
string dayskybox = "";
const float TIME_DAWN = 0;
const float TIME_DAY = 1;
const float TIME_DUSK = 2;
const float TIME_NIGHT = 3;

//
// Player skeleton attach objects
//

void() Skeleton_ObjectDraw =
{
	string gender = getstats(STAT_GENDER); // TODO? send .gender from SSQC, this is shared with monsters that use player bones

	if (!self.skeletonindex)
	{
		self.skeletonindex = skel_create(self.modelindex);
		self.frame = frameforname(self.modelindex, "Idle");
	}
	skel_build(self.skeletonindex, self, self.modelindex, 0, 0, 0, 1);
	Skeleton_Animate();

	// draw lantern
	if (self.effects == EF_BRIGHTLIGHT)
	{
		var float PART_LANTERN = particleeffectnum("lantern");
		
		if (!self.lantern_vfx)
		{
			self.lantern_vfx = spawn();
			self.lantern_vfx.owner = self;
			self.lantern_vfx.drawmask = MASK_VIEWMODEL;
			self.lantern_vfx.worldlight = TRUE;

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

			dynamiclight_add(org, 600, [1, .6, .6], 1, "", PFLAGS_CORONA);
		}
	}
	else if (self.lantern_vfx)
	{
		remove(self.lantern_vfx);
		self.lantern_vfx = world;
	}

	//
	// draw weapon
	//

	if (self.main_hand != "" && self.main_hand != "Unarmed")
	{
		if (!self.weapon_vfx)
		{
			self.weapon_vfx = spawn();
			self.weapon_vfx.owner = self;
			self.weapon_vfx.drawmask = MASK_VIEWMODEL;
			self.weapon_vfx.worldlight = TRUE;
		}
		else
		{
			//
			// Models to draw
			//

			string lname = string_tolower(self.main_hand); // case insensitivity

			if (!self.bonfire)
			{
				// Misc
				if (self.main_hand == "Hatchet")
					setmodel(self.weapon_vfx, "models/hatchet0.glb");
				if (self.main_hand == "Mining Pick")
					setmodel(self.weapon_vfx, "models/pick0.glb");

				// Swords
				if (self.main_hand == "Broken Sword")
					setmodel(self.weapon_vfx, "models/sword0.glb");
				if (self.main_hand == "Short Sword")
					setmodel(self.weapon_vfx, "models/sword1.glb");

				// Daggers
				if (self.main_hand == "Rusty Dagger")
					setmodel(self.weapon_vfx, "models/dagger0.glb");

				// Clubs
				if (self.main_hand == "Wood Club")
					setmodel(self.weapon_vfx, "models/club0.glb");

				// Arrows
				if (strstrofs(lname, "arrow", 0) != -1) // check if this is an arrow-type item
				{
					// prevent player model intrusion
					if (self.entnum == player_localentnum)
					{
						if (!camera_mode && thirdcam_dist < 30) // First-person mode
						{
							// In first-person: use world layer, hide model from camera
							self.weapon_vfx.drawmask = MASK_ENGINE;
							self.weapon_vfx.renderflags |= RF_EXTERNALMODEL;
						}
						else // Third-person mode
						{
							if (camera_gdist > 24) // Normal distance: show armor
							{

								self.weapon_vfx.drawmask = MASK_ENGINE;
								self.weapon_vfx.renderflags &= ~RF_EXTERNALMODEL;
							}
							else // Too close: completely hide armor
							{
								self.weapon_vfx.drawmask = 0; // <- hide entity
								self.weapon_vfx.renderflags &= ~RF_EXTERNALMODEL;
							}
						}
					}

					setmodel(self.weapon_vfx, "models/quiver.glb");
				}
				else
					self.weapon_vfx.renderflags &= ~RF_EXTERNALMODEL;
				
				// Show arrow in hand before firing
				float duration = frameduration(self.modelindex, self.frame);
				if (self.frame == frameforname(self.modelindex, "Archery") && self.frame1time <= duration * 0.5)
				{
					if (!self.arrow_vfx)
					{
						self.arrow_vfx = spawn();
						self.arrow_vfx.owner = self;
						self.arrow_vfx.drawmask = MASK_VIEWMODEL;
					}
					setmodel(self.arrow_vfx, "models/arrow2.glb");

					vector arrow_org = gettaginfo(self, gettagindex(self, "mixamorig:RightHand"));
					vector arrow_offset = '0 0 0';

					// local offset into world space
					arrow_org += v_forward * arrow_offset_x;
					arrow_org += v_right   * arrow_offset_y;
					arrow_org += v_up      * arrow_offset_z;
					self.arrow_vfx.origin = arrow_org;

					// angles
					vector arrow_ang = vectoangles(v_forward, v_up);
					self.arrow_vfx.angles = arrow_ang;
				}
				else if (self.arrow_vfx)
				{
					remove(self.arrow_vfx);
					self.arrow_vfx = world;
				}
			}
			else
				setmodel(self.weapon_vfx, __NULL__);
			//
			//
			//

			if (strstrofs(lname, "arrow", 0) != -1) // check if this is an arrow-type item
				org = gettaginfo(self, gettagindex(self, "mixamorig:Spine1"));			
			else
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
			
			// Stealth causes objects to alpha, same with monsters running back to their spawn point
			if (self.crouch || self.ai_mode == AI_RUNBACK)
			{
				self.weapon_vfx.effects = self.effects;
				self.weapon_vfx.alpha = self.alpha;
			}
			else
				self.weapon_vfx.effects = 0;
		}
	}
	else if (self.weapon_vfx)
	{
		remove(self.weapon_vfx);
		self.weapon_vfx = world;
	}

	//
	// draw offhand
	//

	if (self.off_hand != "" && self.off_hand != "Empty")
	{
		if (!self.offhand_vfx)
		{
			self.offhand_vfx = spawn();
			self.offhand_vfx.owner = self;
			self.offhand_vfx.drawmask = MASK_VIEWMODEL;
			self.offhand_vfx.worldlight = TRUE;
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

				// Bows
				if (self.off_hand == "Short Bow")
					setmodel(self.offhand_vfx, "models/bow0.glb");
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

			// Stealth causes objects to alpha, same with monsters running back to their spawn point
			if (self.crouch || self.ai_mode == AI_RUNBACK)
			{
				self.offhand_vfx.effects = self.effects;
				self.offhand_vfx.alpha = self.alpha;
			}
			else
				self.offhand_vfx.effects = 0;
		}
	}
	else if (self.offhand_vfx)
	{
		remove(self.offhand_vfx);
		self.offhand_vfx = world;
	}

	//
	// Draw armor
	//

	if (self.armorname != "" && self.armorname != "Plain Clothes")
	{
		if (!self.armor_vfx)
		{
			self.armor_vfx = spawn();
			self.armor_vfx.owner = self;
			self.armor_vfx.worldlight = TRUE;
		}
		else
		{
			org = gettaginfo(self, gettagindex(self, "mixamorig:Spine2"));
			offset = '0 0 0';  // offset relative to the bone

			//
			// Models to draw
			//

			// Chest armor
			if (self.armorname == "Padded Armor")
			{
				setmodel(self.armor_vfx, "models/armor0.glb");
				if (gender == "Female")
				{
					self.armor_vfx.scale = 0.88;
					offset = '0 3 3';  // offset relative to the bone
				}
			}
		}

		// local offset into world space
		org += v_forward * offset_x;
		org += v_right   * offset_y;
		org += v_up      * offset_z;

		self.armor_vfx.origin = org;

		// angles
		ang = vectoangles(v_forward, v_up);
		self.armor_vfx.angles = ang;

		// prevent player model intrusion
		if (self.entnum == player_localentnum)
		{
			if (!camera_mode && thirdcam_dist < 30) // First-person mode
			{
				// In first-person: use world layer, hide model from camera
				self.armor_vfx.drawmask = MASK_ENGINE;
				self.armor_vfx.renderflags |= RF_EXTERNALMODEL;
			}
			else // Third-person mode
			{
				if (camera_gdist > 24) // Normal distance: show armor
				{

					self.armor_vfx.drawmask = MASK_ENGINE;
					self.armor_vfx.renderflags &= ~RF_EXTERNALMODEL;
				}
				else // Too close: completely hide armor
				{
					self.armor_vfx.drawmask = 0; // <- hide entity
					self.armor_vfx.renderflags &= ~RF_EXTERNALMODEL;
				}
			}
		}

		// Stealth causes objects to alpha, same with monsters running back to their spawn point
		if (self.crouch || self.ai_mode == AI_RUNBACK)
		{
			self.armor_vfx.effects = self.effects;
			self.armor_vfx.alpha = self.alpha;
		}
		else
			self.armor_vfx.effects = 0;
	}
	else if (self.armor_vfx)
	{
		if (self.armor_vfx.skeletonindex)
			skel_delete(self.armor_vfx.skeletonindex);

		remove(self.armor_vfx);
		self.armor_vfx = world;
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
		if (line = fgets(v))
			sparm5 = line;
		fclose(v);
	}
	sendevent("SSQC_ReadsParms", "sssss", sparm1, sparm2, sparm3, sparm4, sparm5); // send sParms to SSQC
};

// write/update sparm file
void() sParms_Write =
{
	sparm1 = getstats(STAT_MAINHAND);
	sparm2 = getstats(STAT_OFFHAND);
	sparm3 = getstats(STAT_ARMORNAME);
	sparm4 = getstats(STAT_SPELLEQUIPPED);
	sparm5 = getstats(STAT_ARMORNAME);
	
	float v = fopen("sparms", FILE_WRITE); // write sParm file
	if (v)
	{
		fputs(v, LOGIN_NAME, "\n");
		fputs(v, sparm1, "\n");
		fputs(v, sparm2, "\n");
		fputs(v, sparm3, "\n");
		fputs(v, sparm4, "\n");
		fputs(v, sparm5, "\n");
		fclose(v);
	}
};

// open and wipe sParm file
void() sParms_Wipe =
{
	float v = fopen("sparms", FILE_WRITE);
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

	vector t, o;
	if (autocvar_ca_show)	//when we're using the UI, don't send any attack or jump stuff. these are generally annoying modifiers or so
		input_buttons = 0;
		
	if ((input_buttons & 1) && pointedshadername == "")
	{
		t = mousefar;
		o = mousenear;
		if (vlen(o - t) > 8192)
			t = o + normalize(t)*8192;
		traceline(o, t, TRUE, world);

		if (vlen(trace_endpos - o) < 512)
		{
			float s = getsurfacenearpoint(trace_ent, trace_endpos);
			pointedshadername = getsurfacetexture(trace_ent, s);
			pointedsurfacenormal = getsurfacenormal(trace_ent, s);
			if (gecko_get_texture_extent(pointedshadername) == '0 0 0')
				pointedshadername = "";
			if (pointedshadername == "")
				pointedshadername = "";
			else
			{
				//fixme: no unfocus!
				pointedshadername = strzone(pointedshadername);
				//print("sending input to ", pointedshadername, "\n");

				gecko_navigate(pointedshadername, "cmd:focus");

				pointedent = trace_ent;
				pointedsurface = s;
			}
		}
	}

	if (pointedshadername != "")
	{
		input_buttons = input_buttons - (input_buttons & 1);

		makevectors(input_angles);
		if (v_forward * pointedsurfacenormal >= 0)
		{
			gecko_navigate(pointedshadername, "cmd:unfocus");
			strunzone(pointedshadername);
			pointedshadername = "";
		//	print("release (angle)!\n");
		}
		else
		{
			t = mousefar;
			o = mousenear;
			if (vlen(o - t) > 8192)
				t = o + normalize(t)*8192;
			traceline(o, t, TRUE, world);

			//this code is vile.
			//it expects the texture to be aligned to the surface plane with flat projection.
			//it will also break on any polysoup/patch surfaces
			//it should at least accept any weird shaped cut up triangles, so long as they're all flat on the surface.

			vector xyz1, xyz2, xyz3;
			vector st1, st2, st3;
			xyz1 = getsurfacepointattribute(pointedent, pointedsurface, 0, 0);
			xyz2 = getsurfacepointattribute(pointedent, pointedsurface, 1, 0);
			xyz3 = getsurfacepointattribute(pointedent, pointedsurface, 2, 0);
			st1 = getsurfacepointattribute(pointedent, pointedsurface, 0, 4);
			st2 = getsurfacepointattribute(pointedent, pointedsurface, 1, 4);
			st3 = getsurfacepointattribute(pointedent, pointedsurface, 2, 4);

			float f1, f2, backoff;
			vector dir1 = xyz2 - xyz1;
			vector std1 = st2 - st1;
			vector dir2 = xyz3 - xyz1;
			vector std2 = st3 - st1;
			f1 = 1/vlen(dir1);
			dir1 *= f1;
			std1 *= f1;
			backoff = dir1 * dir2;
			std2 = std2 - (std1 * backoff);
			dir2 = dir2 - (dir1 * backoff);
			f2 = 1/vlen(dir2);
			dir1 *= f2;
			std1 *= f2;
			//the two directions should be perpendicular, and normalized

			float d1 = dir1*xyz1;
			float p = dir1*trace_endpos;
			float d2 = dir1*(xyz1+dir1);
			f1 = (p-d1) / (d2 - d1);

			d1 = dir2*xyz1;
			p = dir2*trace_endpos;
			d2 = dir2*(xyz1+dir2);
			f2 = (p-d1) / (d2 - d1);

			vector res = st1 + std1*f1 + std2*f2;

			res_x-= floor(res_x);
			res_y-= floor(res_y);
			gecko_mousemove(pointedshadername, res_x, res_y);

//			pointparticles(particleeffectnum("te_spike"), xyz1 + dir1*f1 + dir2*f2, trace_plane_normal, 1);
		}
	}
};

void() Player_DayNightHandler =
{
	static float next_time_update = 0;
	float do_fog = FALSE;

	vector scrsz = [g_width, g_height];

	if (time >= next_time_update)
	{
		CSQC_DayNight_Update();
		do_fog = TRUE;
		next_time_update = time + 1.0;
	}

	if (timeofday == TIME_DAY) // day
	{
		drawfill('0 0', scrsz, '255 255 255', 0);

		if (do_fog)
		{
			if (cvar("r_shadow_realtime_world_lightmaps") != 1)
				cvar_set("r_shadow_realtime_world_lightmaps", "1");

			if (cvar_string("r_skybox") != dayskybox)
				cvar_set("r_skybox", dayskybox);

			if (cvar("r_skyfog") != 0.5)
				cvar_set("r_skyfog", "0.5");

				localcmd("fog 0.02\n");
		}
	}
	else if (timeofday == TIME_NIGHT) // night
	{
		drawfill('0 0', scrsz, '0 0 50', 0.1);

		if (do_fog)
		{
			if (cvar("r_shadow_realtime_world_lightmaps") != 0.1)
				cvar_set("r_shadow_realtime_world_lightmaps", "0.1");

			if (cvar_string("r_skybox") != nightskybox)
				cvar_set("r_skybox", nightskybox);

			if (cvar("r_skyfog") != 0)
				cvar_set("r_skyfog", "0");

			localcmd("fog 0.05 0\n");
		}
	}
	else if (timeofday == TIME_DAWN) // early morning (dawn)
	{
		drawfill('0 0', scrsz, '255 255 255', 0.075);

		if (do_fog)
		{
			if (cvar("r_shadow_realtime_world_lightmaps") != 0.5)
				cvar_set("r_shadow_realtime_world_lightmaps", "0.5");

			if (cvar_string("r_skybox") != dayskybox)
				cvar_set("r_skybox", dayskybox);

			if (cvar("r_skyfog") != 0.1)
				cvar_set("r_skyfog", "0.1");

			localcmd("fog 0.035\n");
		}
	}
	else // sunset (dusk)
	{
		drawfill('0 0', scrsz, '130 25 0', 0.1);

		if (do_fog)
		{
			if (cvar("r_shadow_realtime_world_lightmaps") != 0.25)
				cvar_set("r_shadow_realtime_world_lightmaps", "0.25");

			if (cvar_string("r_skybox") != dayskybox)
				cvar_set("r_skybox", dayskybox);

			if (cvar("r_skyfog") != 0.8)
				cvar_set("r_skyfog", "0.8");

			localcmd("fog 0.035 0.3 .15 0 1\n");
		}
	}
};

void() Player_Screen =
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
		if (player_menu == MENU_BANKING)
		{
			User_NPCBanking();
		}
	}
	else // Regular gameplay
	{
		Player_DayNightHandler();

		float zonedisplay_finished = getstatf(STAT_ZONENAME_TIME);
		float health = getstatf(STAT_HEALTH);
		float casting = getstatf(STAT_CASTING);
		float atbonfire = getstatf(STAT_BONFIRE);
		float skillpoints = getstatf(STAT_SKILLPOINTS);

		if (zonedisplay_finished > time)
			Draw_ZoneName(g_width, g_height);
		else
			ZoneName_alpha.doalpha = 0;

		Draw_NameTag_ChatBubble();
		if (!player_idle && health > 0)
		{
			Draw_EventLog();
			Draw_ChatLog();
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
		if (atbonfire && skillpoints > 0)
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
};

float SERVER_FRAME_INTERVAL = 0.05;
.float prediction_error_time;
.vector prediction_error;
float(void) Player_PreDraw =
{
	if (self.entnum == player_localentnum)
	{
		// Initialize smoothing variables if not done yet
		if (vPlayerOrigin_time == 0)
		{
			vPlayerOrigin = self.origin;
			vPlayerOriginOld = self.origin;
			vPlayerOriginOld_z = self.origin_z;
			vPlayerVelocity = self.velocity;
			vPlayerOrigin_time = time;
		}

		// -------------------------------
		// Animate player BEFORE physics
		// -------------------------------
		Player_Animate();
		self.movetype = MOVETYPE_WALK;

		// Save logic state
		vector vOldOrigin = self.origin;
		vector vOldVelocity = self.velocity;
		float  fOldPMoveFlags = self.pmove_flags;

		// -------------------------------
		// Prediction loop
		// -------------------------------
		for (int i = servercommandframe + 1; i <= clientcommandframe; i++)
		{
			if (!getinputstate(i)) continue;
			if (input_timelength == 0) break;
			runstandardplayerphysics(self);
		}

		// Small velocity damping
		if (fabs(self.velocity_x) < 20) self.velocity_x *= 0.9;
		if (fabs(self.velocity_y) < 20) self.velocity_y *= 0.9;

		// Stair smoothing (vertical)
		if ((self.flags & FL_ONGROUND) && (self.origin_z - vPlayerOriginOld_z > 0))
		{
			vPlayerOriginOld_z += frametime * 150;
			if (vPlayerOriginOld_z > self.origin_z) vPlayerOriginOld_z = self.origin_z;
			if (self.origin_z - vPlayerOriginOld_z > 18) vPlayerOriginOld_z = self.origin_z - 18;
		}
		else
		{
			vPlayerOriginOld_z = self.origin_z;
		}

		// -------------------------------
		// Horizontal smoothing
		// -------------------------------
		float flSmoothTime = time - self.prediction_error_time;
		if (flSmoothTime < 0.1)
		{
			float flAlpha = 0.15;
			vPlayerOrigin_x = vPlayerOrigin_x * (1 - flAlpha) + (self.origin_x + self.prediction_error_x) * flAlpha;
			vPlayerOrigin_y = vPlayerOrigin_y * (1 - flAlpha) + (self.origin_y + self.prediction_error_y) * flAlpha;
		}

		vPlayerOrigin_z = self.origin_z;
		vector drawOrigin = vPlayerOrigin;

		// -------------------------------
		// Draw entity at smooth position
		// -------------------------------
		self.origin = drawOrigin;
		Skeleton_ObjectDraw();
		addentity(self);

		// -------------------------------
		// Restore real logic state
		// -------------------------------
		self.origin = vOldOrigin;
		setorigin(self, self.origin);
		self.velocity = vOldVelocity;
		self.pmove_flags = fOldPMoveFlags;
		self.movetype = MOVETYPE_NONE;
		self.renderflags = RF_EXTERNALMODEL;

		Player_Think();
	}
    else
    {
        // Interpolation for other players (unchanged)
        self.angles_x = 0;
        if (self.anistate) OtherPlayer_Anistate(); else Player_Animate();

        float flTimeSinceUpdate = time - self.last_update_time;
        if (flTimeSinceUpdate < 0) flTimeSinceUpdate = 0;

        vector vInterpolated;
        if (flTimeSinceUpdate > SERVER_FRAME_INTERVAL * 2)
            vInterpolated = self.last_origin;
        else
        {
            float flInterpFactor = flTimeSinceUpdate / SERVER_FRAME_INTERVAL;
            if (flInterpFactor > 1) flInterpFactor = 1;
            vInterpolated = self.prev_origin + (self.last_origin - self.prev_origin) * flInterpFactor;
            float flExtrapTime = min(max(flTimeSinceUpdate - SERVER_FRAME_INTERVAL, 0), SERVER_FRAME_INTERVAL);
            vInterpolated += self.velocity * flExtrapTime;
        }

        self.origin = vInterpolated;
        setorigin(self, self.origin);
        Skeleton_ObjectDraw();
        addentity(self);
    }

    return PREDRAW_NEXT;
};

void() Player_DoAttack =
{
	float player_menu = getstatf(STAT_MENU);
	float atbonfire = getstatf(STAT_BONFIRE);

	if (!player_menu)
	{
		if (User_DoAttack) // attack button, or que'd up
		{
			if (self.health <= 0)
			{
				if (self.attack_released)
				{
					self.respawn_finished = time + 1; // prevent +attack on respawn
					sendevent("User_StartAttack", "");
				}
				return;
			}
			else if (self.attack_released && !atbonfire && self.respawn_finished < time)
			{
				float stamina = getstatf(STAT_STAMINA);
				float skill_endurance = getstatf(STAT_SKILL_ENDURANCE);
				float attack_stamina = getstatf(STAT_ATTACKSTAM);
				float attackspeed = getstatf(STAT_ATTACKSPEED);
				float stamcalc = skill_endurance * 0.015; // calculation
				float can_attack = FALSE; // stamina check with blocking exception

				if (button4) // holding block
				{
					if (stamina >= 15)
						can_attack = TRUE;
				}
				else if (stamina >= (attack_stamina - stamcalc))
					can_attack = TRUE;
				if (self.anistate == ANISTATE_DODGE || self.anistate == ANISTATE_STEPDODGE)
					can_attack = FALSE;
				if (self.attack_type == 4 && (!(self.flags & FL_ONGROUND))) // bow air check
					can_attack = FALSE;

				if (can_attack)
				{
					if (self.attack_finished < time)
					{
						sendevent("User_StartAttack", "");
						if (self.health > 0 && !button4) // no attack animation if blocking
						{
							if (self.attack_type != 4 && self.stepdodge_counter < time)
								self.anim_attacking = TRUE;
						}
						self.attack_finished = time + attackspeed;
					}
				}
				else
				{
					if (!(stamina >= (attack_stamina - stamcalc)))
						cprint("^b^1Out of stamina ...\n");
				}
			}
			self.attack_released = FALSE;
		}
		else
			self.attack_released = TRUE;

		User_DoAttack = FALSE;
	}

};

float JumpPress;
void() Player_DoJump =
{
	if (User_DoJump)
	{
		// step dodge
		if (!button_left && !button_right && !button_down && !button_up)
		{
			sendevent("PlayerDodge", "f", 8);
			return;
		}

		// lets do multi-angle rolls fist
		if (button_left && button_down)
		{
			sendevent("PlayerDodge", "f", 4);
			return;
		}
		if (button_left && button_up)
		{
			sendevent("PlayerDodge", "f", 5);
			return;
		}
		if (button_right && button_down)
		{
			sendevent("PlayerDodge", "f", 6);
			return;
		}
		if (button_right && button_up)
		{
			sendevent("PlayerDodge", "f", 7);
			return;
		}

		// finish with direct angle roll checks
		if (button_left)
			sendevent("PlayerDodge", "f", 1);
		if (button_right)
			sendevent("PlayerDodge", "f", 2);
		if (button_down)
			sendevent("PlayerDodge", "f", 3);

		// jump
		if (button_up)
			sendevent("PlayerJump", "", 0);
	}
};

void() Player_Think =
{
	if (self.flags & FL_ONGROUND)
		PlayerOnGround = TRUE;
	else
		PlayerOnGround = FALSE;

	Player_DoAttack();

	if (self.health <= 0)
		return;

	Player_DoJump();

	if (deathcam_dist != 45)
		deathcam_dist = 45; // initial z start org for death camera

	if (LockOn_Toggle) // binding stuff work around
	{
		CSQC_LockOn_Toggle();
		LockOn_Toggle = FALSE;
	}
	if (LockOn_CycleToggle)
	{
		CSQC_LockOn_Cycle();
		LockOn_CycleToggle = FALSE;
	}
	

};