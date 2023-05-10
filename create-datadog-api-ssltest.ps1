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
    $testConfigJson = $testConfig | ConvertTo-Json -Depth 10

    $existingTest = $existingTests.tests | Where-Object { $_.config.name -eq $testConfig.name -and $_.type -eq 'api' }

    if ($null -ne $existingTest) {
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
