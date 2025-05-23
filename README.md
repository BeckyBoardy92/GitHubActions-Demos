# GitHub Actions: Get Time by Country

This project provides a GitHub Actions workflow and a Python script to output the current time based on a country you specify at runtime.

## Files and Their Purpose

- `.github/workflows/time-by-country.yml`: The GitHub Actions workflow file. It defines a manual workflow that takes a country input and runs the script.
- `scripts/get_time.py`: The Python script that prints the current time for the given country.

## How It Works

- When you run the workflow, you provide a country name as input (e.g., `Japan`, `Brazil`, `United Kingdom`).
- The workflow sets up Python, installs dependencies (`pytz` and `countryinfo`), and runs the script to print the current time for the specified country.

## How to Run the Workflow

1. Commit and push the files to your GitHub repository.
2. Go to your repository on GitHub.
3. Click the **Actions** tab.
4. Select the **Country Time** workflow from the left sidebar.
5. Click the **Run workflow** button.
6. Enter your desired country name (e.g., `Japan`, `Brazil`, `United Kingdom`) and click **Run workflow**.
7. View the workflow run logs to see the output time.

## Examples

### Using a Country Name
- Input: `Japan`
- Output: `Current time in Japan: 2025-05-23 14:30:00 (Asia/Tokyo)`

- Input: `Brazil`
- Output: `Current time in Brazil: 2025-05-23 09:30:00 (America/Sao_Paulo)`

- Input: `United Kingdom`
- Output: `Current time in United Kingdom: 2025-05-23 19:30:00 (Europe/London)`

## Supported Inputs

- **Country Names:** Any valid country name supported by the `countryinfo` and `pytz` libraries (e.g., `Japan`, `Brazil`, `United Kingdom`, `India`, `Australia`, etc.).

If you enter an invalid value, the script will print an error message.

## Running the Script Locally

You can also run the script directly on your machine (Python 3 and required libraries):

```powershell
python scripts/get_time.py Japan
python scripts/get_time.py Brazil
python scripts/get_time.py "United Kingdom"
```

## Requirements
- Python 3.x
- `pytz` and `countryinfo` libraries (install with `pip install pytz countryinfo`)

## Approval Gates in GitHub Actions

Some workflows in this repository use an approval gate to require manual confirmation before continuing with potentially sensitive or impactful steps (such as running queries or restarting services).

### How Approval Gates Work

- When the workflow reaches the approval step, it will pause and wait for a designated user (the workflow initiator by default) to manually approve or reject the continuation.
- The workflow will show a pending status in the Actions UI with a prompt to approve or reject.
- Only after approval will the workflow proceed to the next steps.
- If rejected, the workflow will stop and no further actions will be taken.

### Example (using trstringer/manual-approval)

- The approval step uses the `trstringer/manual-approval` action.
- The workflow outputs all parameters used at the start, then pauses for approval.
- You will see a button in the GitHub Actions UI to approve or reject the workflow.

#### Typical Workflow Sequence
1. Workflow is triggered and parameters are displayed in the logs.
2. Workflow pauses at the approval step and waits for manual input.
3. Approver reviews the parameters and instructions, then clicks **Approve** or **Reject**.
4. If approved, the workflow continues to the next steps (e.g., running queries, restarting services).
5. If rejected, the workflow stops immediately.

### Why Use Approval Gates?
- To prevent accidental or unauthorized execution of critical operations.
- To allow a human to review parameters and context before proceeding.
- To add an extra layer of safety for workflows that interact with production systems or sensitive resources.

## License
MIT
