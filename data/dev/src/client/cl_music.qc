//
// Music Handler
//

#define MUSIC_CHANNEL_A 10
#define MUSIC_CHANNEL_B 11

#define MUSIC_NONE       0
#define MUSIC_ELDERFEN   1
#define MUSIC_EXPLORE    2
#define MUSIC_COMBAT     3

//
// Active music channel
//

float cl_music_active_channel;

string cl_next_music;

float cl_music_fading;
float cl_music_fade_time;
float cl_music_fade_start;

string cl_current_music;

float cl_last_music_mode;
float cl_last_music_volume;

float cl_current_music_pool;
float cl_current_track_index;

float cl_music_start_time;
float cl_music_length;

float cl_music_fade_old_channel;
float cl_music_fade_new_channel;

//
// Music pools
//

#define ELDERFEN_TRACK_COUNT 2
string elderfen_tracks[2] =
{
	"music/town/1.ogg",
	"music/town/2.ogg"
};


#define EXPLORATION_TRACK_COUNT 4
string exploration_tracks[4] =
{
	"music/overworld/1.ogg",
	"music/overworld/2.ogg",
	"music/overworld/3.ogg",
	"music/overworld/4.ogg"
};


#define COMBAT_TRACK_COUNT 2
string combat_tracks[2] =
{
	"music/combat1.ogg",
	"music/combat2.ogg"
};

//
// Get inactive channel
//

float() Music_GetNextChannel =
{
	if (cl_music_active_channel == MUSIC_CHANNEL_A)
		return MUSIC_CHANNEL_B;

	return MUSIC_CHANNEL_A;
};

//
// Pick next track
//

float(float count, float current) Music_NextTrack =
{
	float next;

	if (count <= 1)
		return current;

	do
	{
		next = floor(random() * count);
	}
	while (next == current);

	return next;
};

//
// Stop music
//

void() Music_Stop =
{
	soundupdate(self, MUSIC_CHANNEL_A, "", -1, 0, 100, 0, 0);
	soundupdate(self, MUSIC_CHANNEL_B, "", -1, 0, 100, 0, 0);

	cl_current_music = "";
	cl_next_music = "";

	cl_music_fading = FALSE;
};

//
// Volume
//

float() Music_Volume =
{
	float volume;

	volume = cvar("musicvolume");

	if (volume < 0)
		volume = 0;

	if (volume > 1)
		volume = 1;

	return volume;
};

//
// Start a track
//

void(string track, float pool, float index) Music_Play =
{
	float channel;

	if (cl_current_music == track)
		return;

	if (cl_music_fading && cl_next_music == track)
		return;

	channel = Music_GetNextChannel();

	sound(self, channel, track, 0, 0, 100, 0, 0);

	cl_next_music = track;

	cl_current_music_pool = pool;
	cl_current_track_index = index;

	cl_music_start_time = time;
	cl_music_length = soundlength(track);

	cl_music_fade_old_channel = cl_music_active_channel;
	cl_music_fade_new_channel = channel;

	cl_music_fade_time = 2;
	cl_music_fade_start = time;

	cl_music_fading = TRUE;
};

//
// Music selection
//

void() Player_Music =
{
	float music;
	float track;
	float volume;

	if (!cl_music_active_channel)
	{
		cl_music_active_channel = MUSIC_CHANNEL_B;

		cl_last_music_volume = -1;
		cl_last_music_mode = -1;
	}

	music = getstatf(STAT_MUSIC);
	volume = Music_Volume();

	//
	// Live volume update
	//

	if (volume != cl_last_music_volume)
	{
		cl_last_music_volume = volume;

		soundupdate(self, cl_music_active_channel, "", volume, 0, 100, 0, 0);

		if (cl_music_fading)
			soundupdate(self, cl_music_fade_new_channel, "", 0, 0, 100, 0, 0);
	}

	if (music == cl_last_music_mode)
		return;

	cl_last_music_mode = music;

	if (music == MUSIC_NONE)
	{
		Music_Stop();
	}
	else if (music == MUSIC_ELDERFEN)
	{
		track = floor(random() * ELDERFEN_TRACK_COUNT);
		Music_Play(elderfen_tracks[track], MUSIC_ELDERFEN, track);
	}
	else if (music == MUSIC_EXPLORE)
	{
		track = floor(random() * EXPLORATION_TRACK_COUNT);
		Music_Play(exploration_tracks[track], MUSIC_EXPLORE, track);
	}
	else if (music == MUSIC_COMBAT)
	{
		track = floor(random() * COMBAT_TRACK_COUNT);
		Music_Play(combat_tracks[track], MUSIC_COMBAT, track);
	}
};

//
// Music thinker
//

void() Music_Update =
{
	float next;

	if (cl_current_music == "")
		return;
	if (cl_music_fading)
		return;
	if (time - cl_music_start_time < cl_music_length)
		return;

	if (cl_current_music_pool == MUSIC_ELDERFEN)
	{
		next = Music_NextTrack(ELDERFEN_TRACK_COUNT, cl_current_track_index);
		Music_Play(elderfen_tracks[next], MUSIC_ELDERFEN, next);
	}
	else if (cl_current_music_pool == MUSIC_EXPLORE)
	{
		next = Music_NextTrack(EXPLORATION_TRACK_COUNT, cl_current_track_index);
		Music_Play(exploration_tracks[next], MUSIC_EXPLORE, next);
	}
	else if (cl_current_music_pool == MUSIC_COMBAT)
	{
		next = Music_NextTrack(COMBAT_TRACK_COUNT, cl_current_track_index);
		Music_Play(combat_tracks[next], MUSIC_COMBAT, next);
	}
};

//
// Fade update
//

void() Music_FadeUpdate =
{
	float frac;
	float old_volume;
	float new_volume;

	if (!cl_music_fading)
		return;

	frac = (time - cl_music_fade_start) / cl_music_fade_time;

	if (frac >= 1)
	{
		frac = 1;

		cl_music_fading = FALSE;

		soundupdate(self, cl_music_fade_old_channel, "", -1, 0, 100, 0, 0);

		cl_music_active_channel = cl_music_fade_new_channel;

		cl_current_music = cl_next_music;
		cl_next_music = "";
	}

	old_volume = Music_Volume() * (1 - frac);
	new_volume = Music_Volume() * frac;

	soundupdate(self, cl_music_fade_old_channel, "", old_volume, 0, 100, 0, 0);

	soundupdate(self, cl_music_fade_new_channel, "", new_volume, 0, 100, 0, 0);
};