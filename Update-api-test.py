import os
import json
import requests

# Retrieve environment variables
dd_api_key = '#{Datadog.ApiKey}'
dd_app_key = '#{Datadog.AppKey}'
monitor_variable_names = '#{MonitorsList}'

# Retrieve the JSON configurations of the monitors
monitor_json_configs = [f'#{{{variable_name}}}' for variable_name in monitor_variable_names.split('|')]

# Concatenate the JSON configurations using '|' as a separator
monitors = '|'.join(monitor_json_configs)

headers = {
    "Content-Type": "application/json",
    "DD-API-KEY": dd_api_key,
    "DD-APPLICATION-KEY": dd_app_key,
}

list_tests_url = "https://api.datadoghq.com/api/v1/synthetics/tests"
json_list = [json.loads(j) for j in monitors.split('|')]

for test_config in json_list:
    test_name = test_config["name"]

    # Check if the test already exists
    response = requests.get(list_tests_url, headers=headers)
    existing_tests = response.json()["tests"]
    existing_test = next((test for test in existing_tests if test["name"] == test_name and test["type"] == "api"), None)

    if existing_test:
        existing_test_config_json = json.dumps(existing_test["config"], sort_keys=True)
        new_test_config_json = json.dumps(test_config["config"], sort_keys=True)

        if existing_test_config_json != new_test_config_json:
            # Update the existing test
            update_test_url = f"https://api.datadoghq.com/api/v1/synthetics/tests/{existing_test['public_id']}"
            response = requests.put(update_test_url, headers=headers, data=json.dumps(test_config))

            if response.status_code == 200:
                print(f"Updated existing Synthetic API test! Test ID: {existing_test['public_id']}")
            else:
                print(f"Error updating Synthetic API test: {response.status_code}")
        else:
            print(f"Skipped updating Synthetic API test as the configuration is the same. Test ID: {existing_test['public_id']}")
    else:
        # Create a new test
        response = requests.post(list_tests_url, headers=headers, data=json.dumps(test_config))

        if response.status_code == 200:
            created_test_id = response.json()["test"]["public_id"]
            print(f"Created new Synthetic API test! Test ID: {created_test_id}")
        else:
            print(f"Error creating Synthetic API test: {response.status_code}")
