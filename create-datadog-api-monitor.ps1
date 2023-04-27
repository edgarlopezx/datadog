
function ConvertToJsonStringForOctopusVariable {
    param (
        [Parameter(Mandatory=$true)][string]$rawJson
    )

    $escapedJson = $rawJson.Replace("`"", "`"`"")
    return $escapedJson
}

param (
    [Parameter(Mandatory=$true)][string]$dd_api_key,
    [Parameter(Mandatory=$true)][string]$dd_app_key,
    [Parameter(Mandatory=$true)][string]$jsonList
)

# Convert the escaped JSON strings in jsonList back to raw JSON strings
$jsonArray = $jsonList.Split('|') | ForEach-Object {
    ConvertToJsonStringForOctopusVariable -rawJson $_
}

# Set the headers for the API request
$headers = @{
    "Content-Type" = "application/json";
    "DD-API-KEY" = $dd_api_key;
    "DD-APPLICATION-KEY" = $dd_app_key
}

# Set the Datadog API URL for retrieving and creating/updating Synthetic API tests
$getAllTestsApiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests"
$createOrUpdateTestApiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests"

# Retrieve all existing Synthetic API tests
$existingTests = Invoke-RestMethod -Method Get -Uri $getAllTestsApiUrl -Headers $headers

foreach ($json in $jsonArray) {
    $newTestConfig = $json | ConvertFrom-Json

    $existingTest = $existingTests.tests | Where-Object { $_.name -eq $newTestConfig.name -and $_.type -eq 'api' }

    if ($existingTest) {
        $existingTestConfigJson = $existingTest.config | ConvertTo-Json -Depth 10
        $newTestConfigJson = $newTestConfig.config | ConvertTo-Json -Depth 10

        if ($existingTestConfigJson -ne $newTestConfigJson) {
            # Update the existing test
            try {
                $response = Invoke-RestMethod -Method Put -Uri "$createOrUpdateTestApiUrl/$($existingTest.public_id)" -Headers $headers -Body $json
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
            $response = Invoke-RestMethod -Method Post -Uri $createOrUpdateTestApiUrl -Headers $headers -Body $json
            Write-Host "Created new Synthetic API test! Test ID: $($response.test.public_id)"
        } catch {
            Write-Host "Error creating Synthetic API test: $($_.Exception.Response.StatusCode.value__)"
        }
    }
}
