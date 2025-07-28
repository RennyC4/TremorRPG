//shared definitions

#define printf(x, ...) print(sprintf(x, __VA_ARGS__))

void() precache_everything =
{
	precache_model("models/testplayer.iqm");
	precache_sound("levelup.wav\n");
};