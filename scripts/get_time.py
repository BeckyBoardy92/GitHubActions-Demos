import sys
from datetime import datetime, timedelta, timezone
import pytz
from countryinfo import CountryInfo

# Usage: python get_time.py <country>

def get_time_by_country(country):
    try:
        info = CountryInfo(country)
        capital = info.capital()
        if not capital:
            raise Exception("No capital found for country.")
        # Try to find a timezone for the capital city
        from pytz import country_timezones, all_timezones
        country_code = info.iso()['alpha2']
        timezones = country_timezones.get(country_code)
        # Prefer a timezone that contains the capital name, else fallback to first
        tz_name = None
        if timezones:
            for tz in timezones:
                if capital.replace(' ', '_') in tz:
                    tz_name = tz
                    break
            if not tz_name:
                tz_name = timezones[0]
        else:
            # Fallback: try to find a timezone by capital name
            for tz in all_timezones:
                if capital.replace(' ', '_') in tz:
                    tz_name = tz
                    break
        if not tz_name:
            raise Exception("No timezone found for capital city.")
        tz = pytz.timezone(tz_name)
        now = datetime.now(tz)
        print(f"Current time in {country} ({tz_name}): {now.strftime('%Y-%m-%d %H:%M:%S')}")
    except Exception as e:
        print(f"Invalid country or timezone: {country}. Error: {e}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage: python get_time.py <country>")
        sys.exit(1)
    country = sys.argv[1]
    get_time_by_country(country)

if __name__ == "__main__":
    main()
