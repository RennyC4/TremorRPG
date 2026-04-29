//shared definitions

#define USEDISTANCE 72 // Use button distance, used for flavour text and actual distance to trigger NPC
#define printf(x, ...) print(sprintf(x, __VA_ARGS__))

void(float speed) TurnToTarget =
{
	vector dir, target_angles;
	float turn_speed, diff;

	if (self.enemy || self.goalentity)
	{
		if (self.enemy)
			dir = normalize(self.enemy.origin - self.origin);
		else if (self.goalentity)
			dir = normalize(self.goalentity.origin - self.origin);
		target_angles = vectoangles(dir);
	}
	else
		target_angles = self.idealangles;

    diff = anglemod(target_angles_y - self.angles_y);

    if (diff > 180)		diff -= 360;
    if (diff < -180)	diff += 360;

    turn_speed = speed;

    if (diff > turn_speed)
        self.angles_y = anglemod(self.angles_y + turn_speed);
    else if (diff < -turn_speed)
        self.angles_y = anglemod(self.angles_y - turn_speed);
    else
        self.angles_y = anglemod(self.angles_y + diff); // snap final tiny difference
};

// this visible function returns TRUE even if sight line crossed contents (above and below water), takes view_ofs into account
float (entity targ) visible_ofs =
{
 	traceline (self.origin + self.view_ofs, targ.origin + targ.view_ofs, TRUE, self); // "true", see through other monsters

	if (trace_fraction == 1)
 		return TRUE;
	else
	 	return FALSE;
};

// Returns the shortest signed difference from start to end: result range: -180 to +180
float(float start, float end) angle_diff =
{
    float D;

    D = anglemod(end) - anglemod(start);

    if (D >  180) D -= 360;
    if (D < -180) D += 360;

    return D;
};

void(entity targ) movetofloor =
{
	vector start = targ.origin;
	vector end = start - '0 0 10000';

	traceline(start, end, TRUE, self);

	if (trace_fraction < 1)
		setorigin(targ, trace_endpos);
};

// Removes spaces from a string
string(string s) string_remove_spaces =
{
    string result;
    float i, len;
    len = strlen(s);

    result = "";

    for (i = 0; i < len; i = i + 1)
    {
        string c = substring(s, i, 1);
        if (c != " ") result = strcat(result, c);
    }
    return result;
};

// Converts all A-Z letters in a string to lowercase
string(string s) string_tolower =
{
    string result;
    float i, c, len;

    result = "";
    len = strlen(s);

    for (i = 0; i < len; i = i + 1)
    {
        c = str2chr(s, i); // get character code
        if (c >= 'A' && c <= 'Z')
            c = c + 32; // convert to lowercase
        result = strcat(result, chr2str(c)); // append converted char
    }

    return result;
};

// strip decimal points
string(float f) FloatToIntString =
{
	string s = ftos(f);
	float i = strstrofs(s, ".", 0); // decimal point
	if (i >= 0)
		return substring(s, 0, i); // cut decimals
	return s;
};

float() crandom =
{
    return (random() * 2) - 1;
};

// Strip all non-numeric characters (integer only)
string(string s) String_StripNonNumeric =
{
	string out = "";
	float len = strlen(s);
	float i;
	float ch;

	for (i = 0; i < len; i++)
	{
		ch = str2chr(s, i); // Get ASCII code at this index

		// Keep digits 0–9 (ASCII 48–57)
		if (ch >= 48 && ch <= 57)
			out = strcat(out, substring(s, i, 1));
	}

	return out;
};