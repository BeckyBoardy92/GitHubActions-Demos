import sys
from datetime import datetime, timedelta, timezone
import pytz

# Usage: python get_time.py <location>

def get_time_by_utc_offset(offset_str):
    try:
        sign = 1 if '+' in offset_str else -1
        hours = int(offset_str.split('UTC')[1].replace('+','').replace('-',''))
        tz = timezone(timedelta(hours=sign*hours))
        now = datetime.now(tz)
        print(f"Current time in {offset_str}: {now.strftime('%Y-%m-%d %H:%M:%S')}")
    except Exception as e:
        print(f"Invalid UTC offset: {offset_str}. Error: {e}")
        sys.exit(1)

def get_time_by_country(country):
    try:
        # Try to find a timezone for the country
        timezones = pytz.country_timezones.get(country.upper())
        if not timezones:
            # Try as a city/region
            tz = pytz.timezone(country)
            now = datetime.now(tz)
            print(f"Current time in {country}: {now.strftime('%Y-%m-%d %H:%M:%S')}")
        else:
            tz = pytz.timezone(timezones[0])
            now = datetime.now(tz)
            print(f"Current time in {country}: {now.strftime('%Y-%m-%d %H:%M:%S')} ({timezones[0]})")
    except Exception as e:
        print(f"Invalid country or timezone: {country}. Error: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: python get_time.py <country or UTC offset>")
        sys.exit(1)
    location = sys.argv[1]
    if location.upper().startswith('UTC'):
        get_time_by_utc_offset(location.upper())
    else:
        get_time_by_country(location)

if __name__ == "__main__":
    main()
