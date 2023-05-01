# Set your Datadog API and APP keys
$apiKey = "your_api_key"
$appKey = "your_app_key"

<#
{
  "OverallStatus": "Healthy",
  "TotalCheckDuration": "0:0.07",
  "DependencyHealthChecks": {
    "SQLServer": {
      "Status": "Healthy",
      "Duration": "0:0.00"
    },
    "App": {
      "Status": "Healthy",
      "Duration": "0:0.05"
    },
    "AzureFunction": {
      "Status": "Healthy",
      "Duration": "0:0.07"
    },
    "azureblob": {
      "Status": "Healthy",
      "Duration": "0:0.01"
    },
    "azureeventhub": {
      "Status": "Healthy",
      "Duration": "0:0.00"
    }
  }
}
#>


# Define the JSON data for your Synthetic API test
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

# Set the headers for the API request
$headers = @{
    "Content-Type" = "application/json";
    "DD-API-KEY" = $apiKey;
    "DD-APPLICATION-KEY" = $appKey
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
