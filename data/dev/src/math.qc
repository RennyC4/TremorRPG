float(float min, float max) random_range =
{
    return min + (random() * (max - min));
};

/*
 * misc_math.qc
 *
 * Author: Joshua Skelton joshua.skelton@gmail.com
 *
 * A collection of helpful math functions.
 */

// Forward declarations
float(float value, float minValue, float maxValue) clamp;
float(float a, float b) mod;
float(float x) sign;
float(float value, float minValue, float maxValue) wrap;

/*
 * clamp
 *
 * Limits the given value to the given range.
 *
 * value: A number
 *
 * minValue: The minimum value of the range
 *
 * maxValue: The maximum value of the range
 *
 * Returns: A number within the given range.
 */
 
float(float value, float minValue, float maxValue) clamp =
{
    if (value < minValue) {
        return minValue;
    }
    else if (value > maxValue) {
        return maxValue;
    }

    return value;
};
 
/*
 * sign
 *
 * Returns an indication of the sign of the given number.
 *
 * x: A number
 *
 * Returns: -1 if x < 0, 0 if x == 0, 1 if x > 0.
 */
float(float x) sign =
{
    if (x > 0)
		return 1;
    else if (x < 0)
        return -1;

    return 0;
};

/*
 * wrap
 *
 * Limits the given value to the given range and will wrap the value to the
 * the other end of the range if exceeded.
 *
 * value: A number
 *
 * minValue: The minimum value of the range
 *
 * maxValue: The maximum value of the range
 *
 * Returns: A number within the given range.
 */
float(float value, float minValue, float maxValue) wrap =
{
	float range = maxValue - minValue;
    return mod(value - minValue, range + 1) + minValue;
};