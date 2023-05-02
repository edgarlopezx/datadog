<#
.SYNOPSIS
    Creates or updates a DataDog Synthetic Test with the given parameters.

.DESCRIPTION
    This script creates or updates a DataDog Synthetic Test based on the test name. If the test already exists, it updates the test with new values. Otherwise, it creates a new test with the provided parameters.

.PARAMETER DD_API_KEY
    Your DataDog API Key.

.PARAMETER DD_APP_KEY
    Your DataDog Application Key.

.PARAMETER Product
    The product name used for the test name and tags.

.PARAMETER Environment
    The environment name used for the test name and tags.

.PARAMETER tags
    Additional tags for the Synthetic Test.

.PARAMETER hostname
    The hostname of your application.

.PARAMETER locations
    Test locations for the Synthetic Test.

.PARAMETER monitorPriority
    The priority of the monitor.

.PARAMETER min_failure_duration
    The minimum failure duration for the Synthetic Test.

.PARAMETER min_location_failed
    The minimum number of failed locations for the Synthetic Test.

.PARAMETER renotify_interval
    The renotification interval for the Synthetic Test.

.PARAMETER on_missing_data
    The behavior for missing data in the Synthetic Test.

.PARAMETER notify_audit
    Indicates whether to notify audit for the Synthetic Test.

.PARAMETER new_host_delay
    The delay for new hosts in the Synthetic Test.

.PARAMETER include_tags
    Indicates whether to include tags in the Synthetic Test.

.PARAMETER retry_count
    The number of retries for the Synthetic Test.

.PARAMETER retry_interval
    The interval between retries for the Synthetic Test.

.PARAMETER tick_every
    The tick frequency for the Synthetic Test.

.PARAMETER responseTime
    The response time threshold for the Synthetic Test.

.PARAMETER statusCode
    The expected status code for the Synthetic Test.

.PARAMETER alertMessage
    The alert message for the Synthetic Test.

.EXAMPLE
    .\createorupdatesynthetictest.ps1 -dd_api_key "yourdatadogapikey" -dd_app_key "yourdatadogappkey" -product "yourproduct" -environment "yourenvironment" -tags "tag1,tag2" -hostname "application-env.domain.com" -locations "pl:ww44455vdddf" -monitorpriority 2 -min_failure_duration 300 -min_location_failed 1 -renotify_interval 0 -on_missing_data "show_no_data" -notify_audit $false -new_host_delay 300 -include_tags $true -retry_count 2 -retry_interval 500 -tick_every 86400 -responsetime 50000 -statuscode 503 -alertmessage "alert: pagerduty [product] in [env] true"

    Creates or updates a DataDog Synthetic Test with the given parameters.
#>


param(
    [string]$dd_api_key,
    [string]$dd_app_key,
    [string]$product,
    [string]$environment,
    [string]$tags,
    [string]$hostname,
    [string]$locations,
    [string]$monitorpriority,
    [string]$min_failure_duration,
    [string]$min_location_failed,
    [string]$renotify_interval,
    [string]$on_missing_data,
    [string]$notify_audit,
    [string]$new_host_delay,
    [string]$include_tags,
    [string]$retry_count,
    [string]$retry_interval,
    [string]$tick_every,
    [string]$responsetime,
    [string]$statuscode,
    [string]$alertmessage
)

# JSON content as a string
$jsonContent = @"
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
"@

# Convert JSON string to a PowerShell object
$jsonObj = ConvertFrom-Json -InputObject $jsonContent

# Set test parameters
$product = "product"
$env = "env"
$testName = "[$product][$env] API Healthcheck Test - https://application-$env.domain.com/health/ready"
$testType = "api"
$tags = @("env:$env", "product:$product", "type:synthetics", "provider:healthcheck_test", "resource:API", "team:cloud")
$locations = @("pl:ww44455vdddf")
$monitorPriority = 2
$alertMessage = "ALERT: Pagerduty [$product] in [$env] true"

$testconfig = @{
    "name" = $testName
    "status" = "live"
    "type" = $testType
    "tags" = $tags
    "config" = @{
        "request" = @{
            "method" = "GET"
            "url" = "https://application-$env.domain.com/health/ready"
        }
        "assertions" = @()
    }
    "message" = $alertMessage
    "options" = @{
        "httpVersion" = "http1"
        "min_failure_duration" = 300 #$min_failure_duration
        "min_location_failed" = 1 #$min_location_failed
        "monitor_name" = $testName
        "monitor_options" = @{
            "renotify_interval" = 0 #$renotify_interval
            "on_missing_data" = "show_no_data" #$on_missing_data
            "notify_audit" = $false #$notify_audit
            "new_host_delay" = 300 #$new_host_delay
            "include_tags" = $true #$include_tags
        }
        "monitor_priority" = $monitorPriority
        "retry" = @{
            "count" = 2 #$retry_count
            "interval" = 500 #$retry_interval
        }
        "tick_every" = 86400 #$tick_every
    }
    "locations" = $locations
    "subtype" = "http"
}

# Add assertions for response time, status code, and content-type
$testconfig.config.assertions += @{
    "operator" = "lessThan"
    "type" = "responseTime"
    "target" = 50000 #$responseTime
}

$testconfig.config.assertions += @{
    "operator" = "is"
    "type" = "statusCode"
    "target" = 503 #$statusCode
}

$testconfig.config.assertions += @{
    "operator" = "is"
    "property" = "content-type"
    "type" = "header"
    "target" = "application/json; charset=utf-8"
}

# Add JSON path assertions for dependency health checks
$dependencyChecks = $jsonObj.DependencyHealthChecks.PSObject.Properties.Name
foreach ($dependency in $dependencyChecks) {
    $testconfig.config.assertions += @{
        "type" = "body"
        "operator" = "validatesJSONPath"
        "target" = @{
            "jsonPath" = "$.DependencyHealthChecks.$dependency.Status"
            "operator" = "contains"
            "targetValue" = "Healthy"
        }
    }
}

# Add JSON path assertion for OverallStatus
$testconfig.config.assertions += @{
    "type" = "body"
    "operator" = "validatesJSONPath"
    "target" = @{
        "jsonPath" = "$.OverallStatus"
        "operator" = "contains"
        "targetValue" = "Healthy"
    }
}

# Display the test configuration
$testconfigJson = $testconfig | ConvertTo-Json -Depth 5

# Function to find a test by name
function Find-TestByName {
    param(
        [string]$testName,
        [string]$DD_API_KEY,
        [string]$DD_APP_KEY
    )

    $apiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests"
    $headers = @{
        "DD-API-KEY" = $DD_API_KEY
        "DD-APPLICATION-KEY" = $DD_APP_KEY
    }

    $existingTests = Invoke-WebRequest -Uri $apiUrl -Headers $headers | ConvertFrom-Json

    foreach ($test in $existingTests.tests) {
        if ($test.config.name -eq $testName) {
            return $test
        }
    }

    return $null
}

# Check if the test already exists
$existingTest = Find-TestByName -testName $testName -DD_API_KEY $DD_API_KEY -DD_APP_KEY $DD_APP_KEY

if ($null -eq $existingTest) {
    # POST the request to create the test
    $response = Invoke-WebRequest -Uri $apiUrl -Method Post -Headers $headers -Body $testconfigJson
    $responseMessage = "Test created"
} else {
    # Update the existing test with new values
    $testId = $existingTest.public_id
    $apiUrl = "https://api.datadoghq.com/api/v1/synthetics/tests/$testId"

    $response = Invoke-WebRequest -Uri $apiUrl -Method Put -Headers $headers -Body $testconfigJson
    $responseMessage = "Test updated"
}

# Display the response and message
$response.Content
Write-Host $responseMessage
