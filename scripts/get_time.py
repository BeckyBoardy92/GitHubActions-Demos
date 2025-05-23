import sys
from datetime import datetime
import pytz
from countryinfo import CountryInfo

# Get country from command line argument
if len(sys.argv) < 2:
    print("Usage: python get_time.py <Country Name>")
    sys.exit(1)

country_name = sys.argv[1]

try:
    country = CountryInfo(country_name)
    timezones = country.timezones()
    if not timezones:
        print(f"No timezone found for {country_name}.")
        sys.exit(1)
    # Use the first timezone
    tz_name = timezones[0]
    try:
        tz = pytz.timezone(tz_name)
    except Exception:
        # Handle UTC offset timezones like 'UTC+09:00'
        if tz_name.startswith('UTC'):
            offset = tz_name.replace('UTC', '')
            # Convert '+09:00' to -9 for Etc/GMT-9 (sign is reversed)
            sign = '-' if '+' in offset else '+'
            hours = int(offset[1:3])
            tz_str = f'Etc/GMT{sign}{hours}'
            tz = pytz.timezone(tz_str)
        else:
            print(f"Unknown timezone format: {tz_name}")
            sys.exit(1)
    now = datetime.now(tz)
    print(f"Current time in {country_name} ({tz.zone}): {now.strftime('%Y-%m-%d %H:%M:%S')}")
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
