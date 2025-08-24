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

// Converts all A-Z letters in a string to lowercase
string(string s) string_tolower =
{
    string result;
    float i, c, len;
    string ch;

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