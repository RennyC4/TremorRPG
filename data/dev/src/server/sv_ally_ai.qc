//
// Allies and special character AI functions are handled here
//

void() ally_ai_think;
void() ally_respawn;
void(float flIsNew) Ally_SendFlags;

void() ally_death =
{
	self.goalentity = self.enemy = world; // reset targets
	self.velocity = '0 0 0'; // slide fix
	self.solid = SOLID_NOT;
	self.deadflag = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.radius_candamage = FALSE;

	//self.think = ally_death2;
	//self.nextthink = time;

	Ally_SendFlags(FALSE); // Send delta snapshot
};

void() ally_ai_melee =
{
	if (self.melee_finished < time && self.stagger_finished < time)
	{
		if (self.noise1)
			sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
		if (self.enemy)
			self.enemy.incombat_finished = time + 15;

		// Done through CSQC when we get there
		self.melee_finished = time + self.attack_speed;
	}
	else
	{
		self.think = ally_ai_think;
		self.nextthink = time + 0.1;
	}
};

void() ally_ai_move = {};

// main ally ai execution function
void() ally_ai_update_state =
{
	self.goalentity = world;

	for (entity b = findradius(self.origin, self.sight_range); b; b = b.chain)
	{
		if (b.classname != "player")
			continue;

		if (!visible(b))
			continue;

		self.goalentity = b;
		break; // Face the first visible player found
	}

	TurnToTarget(10);
};

void() ally_ai_think =
{
    ally_ai_update_state();  // ALL logic + movement
    Ally_SendFlags(FALSE);   // delta compare
    NPC_CommitState(self);   // snapshot

    self.nextthink = time + 0.1;
};