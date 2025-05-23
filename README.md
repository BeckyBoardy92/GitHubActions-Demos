# GitHub Actions: Get Time by Country or UTC Offset

This project provides a GitHub Actions workflow and a Python script to output the current time based on a country, city/region, or UTC offset you specify at runtime.

## Files and Their Purpose

- `.github/workflows/time-by-country.yml`: The GitHub Actions workflow file. It defines a manual workflow that takes a location input and runs the script.
- `scripts/get_time.py`: The Python script that prints the current time for the given input (country code, timezone, or UTC offset).

## How It Works

- When you run the workflow, you provide a location input. This can be:
  - A two-letter ISO country code (e.g., `US`, `IN`, `GB`)
  - A valid timezone string (e.g., `Europe/London`, `Asia/Tokyo`)
  - A UTC offset (e.g., `UTC+2`, `UTC-5`)
- The script will print the current time for the specified location.

## How to Run the Workflow

1. Commit and push the files to your GitHub repository.
2. Go to your repository on GitHub.
3. Click the **Actions** tab.
4. Select the **Get Time by Country** workflow from the left sidebar.
5. Click the **Run workflow** button.
6. Enter your desired location (country code, timezone, or UTC offset) and click **Run workflow**.
7. View the workflow run logs to see the output time.

## Examples

### Using a Country Code
- Input: `US`
- Output: `Current time in US: 2025-05-23 14:30:00 (America/New_York)`

### Using a Timezone String
- Input: `Europe/London`
- Output: `Current time in Europe/London: 2025-05-23 19:30:00`

### Using a UTC Offset
- Input: `UTC+2`
- Output: `Current time in UTC+2: 2025-05-23 21:30:00`

## Supported Inputs

- **Country Codes:** Any valid ISO 3166-1 alpha-2 country code supported by the `pytz` library (e.g., `US`, `IN`, `GB`, `FR`, `JP`, `AU`, etc.).
- **Timezone Strings:** Any valid timezone string from the `pytz` library (e.g., `Europe/Paris`, `Asia/Kolkata`, `America/Los_Angeles`).
- **UTC Offsets:** Strings starting with `UTC` followed by `+` or `-` and the hour offset (e.g., `UTC+3`, `UTC-7`).

If you enter an invalid value, the script will print an error message.

## Running the Script Locally

You can also run the script directly on your machine (Python 3 and `pytz` required):

```powershell
python scripts/get_time.py US
python scripts/get_time.py Europe/London
python scripts/get_time.py UTC+2
```

## Requirements
- Python 3.x
- `pytz` library (install with `pip install pytz`)

## License
MIT
