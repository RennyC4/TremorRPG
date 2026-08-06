//
//	Area Load - Keeping things organized, these are called from worldspawn();
//

string(string filename) ReadFileToString =
{
    string line;
    string data = "";

    float f = fopen(filename, FILE_READ);

    if (f < 0)
    {
        dprint(strcat("Failed to open ", filename, "\n"));
        return "";
    }

    while (1)
    {
        line = fgets(f);

        if (!line)
            break;

        data = strcat(data, line, "\n");
    }

    fclose(f);
    return data;
};

void(string filename) LoadEntityFile =
{
    string data;
    float pos;

    data = ReadFileToString(filename);

    if (!data)
    {
        dprint(strcat("No entity file: ", filename, "\n"));
        return;
    }

    pos = 0;

    while (pos < strlen(data))
    {
        entity e;
        float next;

        e = spawn();

        next = parseentitydata(e, data, pos);

        if (next <= pos)
        {
            removeinstant(e);
            break;
        }

        pos = next;

        if (!e.classname)
        {
            removeinstant(e);
            continue;
        }

        if (!isfunction(e.classname))
        {
            dprint(strcat("Unknown entity classname: ", e.classname, "\n"));
            removeinstant(e);
            continue;
        }

        self = e;
        callfunction(e.classname);
    }
};

void() LoadArea_Elderfen =
{
	LoadEntityFile("area_ents/elderfen/structs.ent"); // structures
	LoadEntityFile("area_ents/elderfen/trees.ent"); // trees
	LoadEntityFile("area_ents/elderfen/monsters.ent"); // monsters
	LoadEntityFile("area_ents/elderfen/mining.ent"); // mining nodes
	LoadEntityFile("area_ents/elderfen/fish.ent"); // fishing nodes
	LoadEntityFile("area_ents/elderfen/decor.ent"); // world decor
	LoadEntityFile("area_ents/elderfen/bonfires.ent"); // bonfires
};