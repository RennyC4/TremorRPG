float lock_on_active;
entity lock_on_target;
const float lock_on_dist = 2000;
float cam_smooth = 0.3; // following speed

// Vector lerp — interpolation between two vectors
vector vlerp(vector a, vector b, float t) {return a + (b - a) * t;}

// Cross product — gives a vector perpendicular to both inputs
vector vcross(vector a, vector b)
{
	return [
		(a_y * b_z) - (a_z * b_y),
		(a_z * b_x) - (a_x * b_z),
		(a_x * b_y) - (a_y * b_x)
	];
}

void() CSQC_LockOn_Update =
{
	vector vieworg = vPlayerOrigin;
	vector viewangles = view_angles;

	if (lock_on_active && lock_on_target && lock_on_target.health > 0)
	{
		vector toTarget = lock_on_target.origin - vieworg;
		toTarget = normalize(toTarget);

		vector targetAngles = vectoangles(toTarget); // convert direction to angles
		viewangles = vlerp(viewangles, targetAngles, cam_smooth); // Smoothly turn towards the target
		viewangles_x = clamp(viewangles_x, -60, 60); // don’t look too far up/down

		vector right = vcross('0 0 1', toTarget);
		right = normalize(right);
		//setviewangles(viewangles);

		setproperty(VF_ANGLES, viewangles);
	}
	else
	{
		// Unlock automatically if target dies
		if (lock_on_active && (!lock_on_target || lock_on_target.health <= 0 || vlen(lock_on_target.origin - vieworg) > lock_on_dist))
		{
			lock_on_active = FALSE;
			lock_on_target = world;
		}
	}
};

void() CSQC_LockOn_Toggle =
{
	if (lock_on_active)
	{
		// Unlock
		lock_on_active = FALSE;
		lock_on_target = world;
		print("Lock off\n");
		return;
	}

	for (entity b = world;(b = find(b, classname, "monster"));)
	{
		if (vlen(b.origin - vPlayerOrigin) <= lock_on_dist)
		{
			lock_on_target = b;
			lock_on_active = TRUE;
			print("Locked on target\n");
		}
	}
};