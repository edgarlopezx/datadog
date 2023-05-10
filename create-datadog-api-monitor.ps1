<#
.SYNOPSIS
    Creates or updates Datadog Synthetic API tests.

.DESCRIPTION
    This script creates or updates Datadog Synthetic API tests using the provided API key, APP key, and a JSON object containing multiple test configurations.

.PARAMETER dd_api_key
    The Datadog API key.

.PARAMETER dd_app_key
    The Datadog APP key.

.PARAMETER json
    The JSON object containing multiple test configurations.

.EXAMPLE
    $apiKey = "your_api_key"
    $appKey = "your_app_key"

    $json = @"
    [
        {
            "config": {
                "assertions": [
                    {
                        "operator": "is",
                        "type": "statusCode",
                        "target": 200
                    },
                    {
                        "operator": "lessThan",
                        "type": "responseTime",
                        "target": 2000
                    }
                ],
                "request": {
                    "method": "GET",
                    "url": "https://example1.com",
                    "timeout": 30
                }
            },
            "message": "Check if the example1 website is up and running",
            "name": "Example1 website",
            "tags": ["environment:test"],
            "type": "api",
            "locations": ["aws:us-east-1"]
        },
        {
            "config": {
                "assertions": [
                    {
                        "operator": "is",
                        "type": "statusCode",
                        "target": 200
                    },
                    {
                        "operator": "lessThan",
                        "type": "responseTime",
                        "target": 2000
                    }
                ],
                "request": {
                    "method": "GET",
                    "url": "https://example2.com",
                    "timeout": 30
                }
            },
            "message": "Check if the example2 website is up and running",
            "name": "Example2 website",
            "tags": ["environment:test"],
            "type": "api",
            "locations": ["aws:us-east-1"]
        }
    ]
    "@

    .\CreateOrUpdateDatadogSyntheticsTests.ps1 -dd_api_key $apiKey -dd_app_key $appKey -json $json
#>
param (
    [Parameter(Mandatory=$true)][string]$dd_api_key,
    [Parameter(Mandatory=$true)][string]$dd_app_key,
    [Parameter(Mandatory=$true)][string]$json
)

# Set the headers for the API request
$headers = @{
    "Content-Type" = "application/json";
    "DD-API-KEY" = $dd_api_key;
    "DD-APPLICATION-KEY" = $dd_app_key
}

# Set the Datadog API URL for retrieving and creating/updating Synthetic API tests
$getAllTestsApiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests"
$createOrUpdateTestApiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests"

# Convert the JSON string to a list of test configurations
$testConfigList = $json | ConvertFrom-Json

# Retrieve all existing Synthetic API tests
$existingTests = Invoke-RestMethod -Method Get -Uri $getAllTestsApiUrl -Headers $headers

foreach ($testConfig in $testConfigList) {
  $testConfigJson = $testConfig | ConvertTo-Json

  $existingTest = $existingTests.tests | Where-Object { $_.name -eq $testConfig.name -and $_.type -eq 'api' }

  if ($existingTest) {
      $existingTestConfigJson = $existingTest.config | ConvertTo-Json -Depth 10

      if ($existingTestConfigJson -ne $testConfigJson) {
          # Update the existing test
          try {
              $response = Invoke-RestMethod -Method Put -Uri "$createOrUpdateTestApiUrl/$($existingTest.public_id)" -Headers $headers -Body $testConfigJson
              Write-Host "Updated existing Synthetic API test! Test ID: $($response.test.public_id)"
          } catch {
              Write-Host "Error updating Synthetic API test: $($_.Exception.Response.StatusCode.value__)"
          }
      } else {
          Write-Host "Skipped updating Synthetic API test as the configuration is the same. Test ID: $($existingTest.public_id)"
      }
  } else {
      # Create a new test
      try {
          $response = Invoke-RestMethod -Method Post -Uri $createOrUpdateTestApiUrl -Headers $headers -Body $testConfigJson
          Write-Host "Created new Synthetic API test! Test ID: $($response.test.public_id)"
      } catch {
          Write-Host "Error creating Synthetic API test: $($_.Exception.Response.StatusCode.value__)"
      }
  }
}
