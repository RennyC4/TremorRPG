//shared definitions

#define printf(x, ...) print(sprintf(x, __VA_ARGS__))

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