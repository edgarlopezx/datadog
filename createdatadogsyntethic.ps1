<#
.SYNOPSIS
    Creates a Datadog Synthetic API test.

.DESCRIPTION
    This script creates a Datadog Synthetic API test using the provided API key, APP key, and test configuration JSON.

.PARAMETER dd_api_key
    The Datadog API key.

.PARAMETER dd_app_key
    The Datadog APP key.

.PARAMETER json
    The JSON configuration for the Synthetic API test.

.EXAMPLE
    $apiKey = "your_api_key"
    $appKey = "your_app_key"

    $json = @"
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
                "url": "https://example.com",
                "timeout": 30
            }
        },
        "message": "Check if the example website is up and running",
        "name": "Example website",
        "tags": ["environment:test"],
        "type": "api",
        "locations": ["aws:us-east-1"]
    }
    "@

    .\CreateDatadogSyntheticsTest.ps1 -dd_api_key $apiKey -dd_app_key $appKey -json $json
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

# Set the Datadog API URL
$apiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests"

# Send the API request to create the Synthetic API test
try {
    $response = Invoke-RestMethod -Method Post -Uri $apiUrl -Headers $headers -Body $json
    Write-Host "Synthetic API test created successfully! Test ID: $($response.test.public_id)"
} catch {
    Write-Host "Error creating Synthetic API test: $($_.Exception.Response.StatusCode.value__)"
}
