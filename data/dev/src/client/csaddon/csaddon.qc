//FIXME: slice tool is a bit shite and has no way to change points 1+2, only the last one can be freely changed.

var float autocvar_ca_show = 0;
var float autocvar_ca_editormode = MODE_LIGHTEDIT;
string autocvar_ca_colourtint;

var vector vidsize = '640 480 0';
vector curmousepos;
vector mousediff;
vector originalmousepos;
float mousedown;
float shiftdown;
float ctrldown;
vector mousenear;
vector mousefar;

float releasedmouse;

string pointedshadername;
vector pointedsurfacenormal;
entity pointedent;
float pointedsurface;

float editorrsd[editornames.length];

static void() csaddon_savemap =
{
	localcmd(strcat("mod_terrain_save \"", mapname, "\"\n"));
};

struct
{
	string text;
	string cmd;
	void() cb;
} editorcommands[] =
{
	{"Close",			"ca_show 0\n"},
	{"Noclip",			"noclip\n"},
	{"Notarget",			"notarget\n"},
	{"Fullbright",			"toggle r_fullbright\n"},
	{"Brush Editor Bindings",	"brushedit_binds\n"},
	//{"Save",			__NULL__, csaddon_savemap}, // RennyC: This breaks hmps
};
float(float key, float unic, vector mouse) editor_options_key =
{
	if (key == K_MOUSE1)
	{
		int sel = (mouse_y - 16) / 8;
		if (sel >= 0 && sel < editorcommands.length)
		{
			if (editorcommands[sel].cb)
				editorcommands[sel].cb();
			else
				localcmd(editorcommands[sel].cmd);
			return TRUE;
		}
	}
	return FALSE;
};
void(vector mouse) editor_options_overlay =
{
	vector pos = '0 16';
	int sel = (mouse_y - pos_y) / 8;
	for (int i = 0; i < editorcommands.length; i++)
	{
		string txt = editorcommands[i].text;
		string cmd = editorcommands[i].cmd;
		if (substring(cmd, 0, 7) == "toggle ")
		{
			if (cvar(substring(cmd, 7, -2)))
				txt = strcat(txt, " (ON)");
			else
				txt = strcat(txt, " (OFF)");
		}
		drawstring(pos, txt, 		'8 8', (sel==i)?'0 0 1':'1 1 1', 1, 0);
		pos_y += 8;
	}
};

static void() perf_renderscene =
{
	renderscene();
};

/*the renderscene builtin in the parent progs is redirected to here*/
void() wrap_renderscene =
{
	float x;
	vector col;
	local float i;
	
	if (ca_checksave)
	{
		if (ca_checksave(autocvar_ca_show?autocvar_ca_editormode:0))
		{
			ca_checksave = __NULL__;
			localcmd("changelevel . .\n");
		}
	}
	
	vidsize = getproperty(VF_SCREENVSIZE);

	/*inactive? then show nothing*/
	if (!autocvar_ca_show)
	{
		mousefar = unproject((vidsize*0.5) + '0 0 8192');
		mousenear = unproject(vidsize*0.5);

#ifdef CAMQUAKE
		if (isdemo())
			spline_overrides(gettime(5));
#endif

		renderscene();

		if (autocvar_ca_colourtint != "")
		{
			local string shdrname = strcat("tint_", autocvar_ca_colourtint);
			/*make sure the shader exist*/
			shaderforname(shdrname,
					"{\n"
						//if we can actually use glsl...
						"if $glsl\n"
							"glslprogram\n"
							"{\n"
								"varying vec4 tf;\n"
								"#ifdef VERTEX_SHADER\n"
									"void main ()\n"
									"{\n"
										"gl_Position = tf = ftetransform();\n"
									"}\n"
								"#endif\n"

								"#ifdef FRAGMENT_SHADER\n"
									"uniform sampler2D s_t0;\n"
									"uniform sampler3D s_t1;\n"
									"void main()\n"
									"{\n"
										"vec2 fc;\n"
										"fc = tf.xy / tf.w;\n"
										"vec3 raw = texture2D(s_t0, (1.0 + fc) / 2.0).rgb;\n"

										//scale+bias the sample to not clamp out at the edges
										"#define LUTSIZE 16.0\n"
										"vec3 scale = vec3((LUTSIZE-1.0)/LUTSIZE);\n"
										"vec3 bias = vec3(1.0/(2.0*LUTSIZE));\n"

										"gl_FragColor = texture3D(s_t1, raw * scale + bias);\n"
									"}\n"
								"#endif\n"
							"}\n"
							"{\n"
								"map $currentrender\n"
							"}\n"
							"{\n"
								//16*16*16 image
								"clampmap $3d:",autocvar_ca_colourtint,"\n"
							"}\n"
						//else (glsl not available)
						"else\n"
							//just don't draw anything.
							"surfaceparm nodraw\n"
						"endif\n"
					"}\n"
				);
			drawpic(getproperty(VF_MIN), shdrname, getproperty(VF_SIZE), '1 1 1', 1);
		}

		if (releasedmouse)
		{	//remove the cursor if we activated it
			releasedmouse = FALSE;
			setcursormode(FALSE);
		}
		mousedown = 0;
		return;
	}
	
	if (mousedown == 2)
	{	//RMB re-enables mlook
		if (releasedmouse)
		{
			releasedmouse = FALSE;
			setcursormode(FALSE);
		}
	}
	else
	{
		if (FALSE == getcursormode(FALSE))
		{	//only release it again if it should be released.
			setcursormode(TRUE);
			releasedmouse = TRUE;
		}
	}

	/*hide hud and crosshair*/
	setproperty(VF_DRAWENGINESBAR, 0);
	setproperty(VF_DRAWCROSSHAIR, 0);

	vector mn = (vector)getproperty(VF_MIN);
	vector sz = (vector)getproperty(VF_SIZE);
	if (curmousepos_x >= mn_x && curmousepos_x <= mn_x+sz_x && curmousepos_y >= mn_y && curmousepos_y <= mn_y+sz_y)
	{
		mousefar = unproject(curmousepos + '0 0 8192');
		mousenear = unproject(curmousepos);
	}

	if (autocvar_ca_editormode == MODE_LIGHTEDIT)
		editor_lights_addentities();
	else if (autocvar_ca_editormode == MODE_ENTSEDIT)
		editor_ents_addentities();
#ifdef CAMQUAKE
	else if (autocvar_ca_editormode == MODE_SPLINEEDIT)
		editor_spline_addentities();
#endif
	else if (autocvar_ca_editormode == MODE_TERRAINEDIT)
		editor_terrain_addentities(curmousepos);
	else if (autocvar_ca_editormode == MODE_BRUSHEDIT)
		editor_brushes_addentities(curmousepos);

	perf_renderscene();

	for (i = 0, x = 0; i < editornames.length; i+=1)
	{
		if (editornames[i] != "")
		{
			float w = stringwidth(editornames[i], TRUE, '8 8 0') + 8;
			if (autocvar_ca_editormode == i)
				col = '1 0 0';
			else if (curmousepos_y < 8 && curmousepos_x >= x && curmousepos_x < x+w)
				col = '0 0 1';
			else
				col = '1 1 1';
			drawrawstring([x,0], editornames[i], '8 8 0', col, 1);

			x += w;
		}
		editorrsd[i] = x;
	}

	if (autocvar_ca_editormode == MODE_OPTIONS)
		editor_options_overlay(curmousepos);
	else if (autocvar_ca_editormode == MODE_LIGHTEDIT)
		editor_lights_overlay(curmousepos);
#ifdef CAMQUAKE
	else if (autocvar_ca_editormode == MODE_SPLINEEDIT)
	{
		editor_spline_overlay(&curmousepos, mousediff);
		originalmousepos = curmousepos;
		mousediff = '0 0 0';
	}
#endif
	else if (autocvar_ca_editormode == MODE_PARTICLEEDIT)
		editor_particles_overlay(curmousepos);
	else if (autocvar_ca_editormode == MODE_TERRAINEDIT)
		editor_terrain_overlay(curmousepos);
	else if (autocvar_ca_editormode == MODE_ENTSEDIT)
		editor_ents_overlay(curmousepos);
	else if (autocvar_ca_editormode == MODE_BRUSHEDIT)
		editor_brushes_overlay(curmousepos);

	drawcharacter(curmousepos - '4 4', '+', '8 8', '1 1 1', 1);
};

var float(float,float,float) orig_input_event = __NULL__;
float (float event, float parama, float paramb) wrap_InputEvent =
{
	if (event == IE_KEYDOWN || event == IE_KEYUP)
	{
		if (parama == K_RSHIFT || parama == K_LSHIFT)
			shiftdown = (event == IE_KEYDOWN);
		if (parama == K_RCTRL || parama == K_LCTRL)
			ctrldown = (event == IE_KEYDOWN);
		if (parama == K_RALT || parama == K_LALT)
			altdown = (event == IE_KEYDOWN);
	}
	if (autocvar_ca_show)
	{
		if (event == IE_KEYDOWN)
		{
			if (parama == K_MOUSE1 && curmousepos_y < 8)
			{
				float i, nm = 0;
				for (i = editorrsd.length-1; i >= 0; i--)
				{
					if (curmousepos_x < editorrsd[i])
						nm = i;
					else
						break;
				}
				cvar_set("ca_editormode", ftos(nm));
				return TRUE;
			}
			if (autocvar_ca_editormode == MODE_OPTIONS)
			{
				if (editor_options_key(parama, paramb, curmousepos))
					return TRUE;
			}
			else if (autocvar_ca_editormode == MODE_LIGHTEDIT)
			{
				if (editor_lights_key(parama, paramb, curmousepos))
					return TRUE;
			}
#ifdef CAMQUAKE
			else if (autocvar_ca_editormode == MODE_SPLINEEDIT)
			{
				if (editor_spline_key(parama, paramb, &curmousepos, mousediff))
				{
					originalmousepos = curmousepos;
					mousediff = '0 0 0';
					return TRUE;
				}
			}
#endif
			else if (autocvar_ca_editormode == MODE_PARTICLEEDIT)
			{
				if (editor_particles_key(parama, paramb, curmousepos))
					return TRUE;
			}
			else if (autocvar_ca_editormode == MODE_TERRAINEDIT)
			{
				if (editor_terrain_key(parama, paramb, curmousepos))
					return TRUE;
			}
			else if (autocvar_ca_editormode == MODE_BRUSHEDIT)
			{
				if (editor_brushes_key(parama, paramb, curmousepos))
					return TRUE;
			}
			else if (autocvar_ca_editormode == MODE_ENTSEDIT)
			{
				if (editor_ents_key(parama, paramb, curmousepos))
					return TRUE;
			}
			if (parama == K_MOUSE1)
			{
				mousedown = 1;
				return TRUE;
			}
			if (parama == K_MOUSE2)
			{
				mousedown = 2;
				return TRUE;
			}
		}
		else if (event == IE_KEYUP)
		{
			if (parama == K_MOUSE1-1+mousedown)
				mousedown = FALSE;
		}
		else if (event == IE_MOUSEDELTA)
		{
			if (mousedown == 2)
				return FALSE;
			originalmousepos = curmousepos;
			curmousepos_x += parama;
			curmousepos_y += paramb;
			mousediff = curmousepos - originalmousepos;
			if (curmousepos_x < 0)
				curmousepos_x = 0;
			if (curmousepos_y < 0)
				curmousepos_y = 0;
			if (curmousepos_x > vidsize_x)
				curmousepos_x = vidsize_x;
			if (curmousepos_y > vidsize_y)
				curmousepos_y = vidsize_y;
			return TRUE;
		}
		else if (event == IE_MOUSEABS)
		{
			curmousepos_x = parama;
			curmousepos_y = paramb;
			if (mousedown == 2)
				return FALSE;
			return TRUE;
		}
	}
	else if (pointedshadername != "")
	{
/*		if (parama == K_MOUSE2)
		{
			strunzone(pointedshadername);
			pointedshadername = "";
			print("release (mouse2)!\n");
			return TRUE;
		}
*/
		if (event == IE_KEYDOWN || event == IE_KEYUP)
		{
			gecko_keyevent(pointedshadername, parama, event);
			if (event == 0)
				return TRUE;
		}
	}

	if (orig_input_event)
		return orig_input_event(event, parama, paramb);
	return FALSE;
};

void(float mask) wrap_addentities =
{
	mask = mask | MASK_ENGINE | MASK_VIEWMODEL;
	addentities(mask);
};

void(float prevprogs) init =
{
#ifdef CAMQUAKE
	Cam_Init();
#else
	editornames[MODE_SPLINEEDIT] = 0;
#endif

	if (prevprogs >= 0)
	{
		/*its easy to wrap a builtin*/
		externset(0, wrap_renderscene, "renderscene");
		externset(0, wrap_addentities, "addentities");

		/*wrap the parent's input event function*/
		orig_input_event = (float(float, float, float))externvalue(0, "CSQC_InputEvent");
		externset(0, wrap_InputEvent, "CSQC_InputEvent");
	}
	csfixups();
	localcmd(sprintf("alias rtlight_editor \"set ca_show 1; set ca_editormode %g\"\n", MODE_LIGHTEDIT));
	localcmd(sprintf("alias camquake_editor \"set ca_show 1; set ca_editormode %g\"\n", MODE_SPLINEEDIT));
	localcmd(sprintf("alias terrain_editor \"set ca_show 1; set ca_editormode %g\"\n", MODE_TERRAINEDIT));
	localcmd(sprintf("alias r_part_editor \"set ca_show 1; set ca_editormode %g\"\n", MODE_PARTICLEEDIT));
	localcmd(sprintf("alias entities_editor \"set ca_show 1; set ca_editormode %g\"\n", MODE_ENTSEDIT));
	
	//brush editor needs some commands for easier binds.
	editor_brushes_registercommands();
};
