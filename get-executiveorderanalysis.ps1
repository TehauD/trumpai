# Define the URL of the Federal Register page containing the executive orders
$baseUrl = "https://www.federalregister.gov/presidential-documents/executive-orders/donald-trump/2025"

# Define the directory where PDFs and CSV will be saved
$outputDir = "C:\git\Trumpai"
$csvFilePath = Join-Path -Path $outputDir -ChildPath "executive_orders_metadata.csv"
$rawMetadataCsvFilePath = Join-Path -Path $outputDir -ChildPath "executive_orders_raw_metadata.csv"

# Define the URL for your local LM Studio instance
$lmStudioUrl = "http://localhost:1234/v1/chat/completions"

# Create the output directory if it doesn't exist
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Initialize metadata storage
$metadataCollection = @()
$rawMetadataCollection = @()

# Define the metadata fields you want to extract
$metadataFields = @(
    "Order number",
    "Date signed",
    "Signed by",
    "Detailed Summary",
    "Agency Impacted",
    "Within Executive Powers",
    "Exceeds Executive Powers",
    "Legal",
    "Pros",
    "Cons",
    "Keywords",
    "Authority granted to",
    "Impacted entities",
    "Budgetary impact",
    "Enforcement Mechanism",
    "Implementation timeline",
    "Long-term Impact",
    "Stakeholder Reactions",
    "Historical Context",
    "Implementation Challenges",
    "Public Perception",
    "Legal Precedents",
    "Executive Order Comparisons",
    "Executive Order Duration",
    "Scope of Applicability",
    "Interaction with Other Laws/Regulations",
    "Delegated Powers",
    "Revocation/Modification Process",
    "Political Context",
    "Priority Areas Addressed",
    "Compliance Requirements",
    "Court Involvement",
    "Regulatory or Legislative Action Needed",
    "Impact on International Relations",
    "Enabling Legislation",
    "Review and Oversight Mechanism",
    "Temporary vs. Permanent Measures",
    "Environmental Considerations",
    "Civil Liberties Considerations",
    "Public Health Impact",
    "Data and Reporting Requirements",
    "Security Implications",
    "Partisan Support/Opposition",
    "Executive Action Precedent",
    "Economic Sector Impact",
    "Labor/Workforce Impact",
    "Technological Impact",
    "Social Justice Considerations",
    "Transparency",
    "Public Engagement or Consultation"
)

# Function to send PDF content to LM Studio and write the response to a file
function Get-PdfWithLMStudio {
    param (
        [string]$PdfFilePath,
        [string]$LmStudioUrl
    )

    try {
        $pdfText = & "C:\Program Files\PowerShell\7\xpdf-tools-win-4.05\bin64\pdftotext.exe" -layout "$PdfFilePath" -

        if (-not $pdfText) {
            Write-Warning "Failed to extract text from PDF: $PdfFilePath"
            return
        }

        # Construct the AI prompt with specific metadata fields
        $prompt = "Extract the following metadata from the text below as a JSON object.  Return *ONLY* valid JSON.  Do not include any markdown code fences (e.g., ```json). If a field is not found or not applicable, set the value to null.  Ensure valid JSON structure.\n\n"
        $prompt += "Metadata Fields:\n"
        foreach ($field in $metadataFields) {
            $prompt += "- $field\n"
        }
        $prompt += "\nText:\n$pdfText"

        $payload = @{ messages = @( @{ role = "system"; content = "You are an expert at extracting metadata from legal documents. Your response *MUST* be valid JSON. Do not include markdown code fences." }, @{ role = "user"; content = $prompt } ) } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod -Uri $LmStudioUrl -Method Post -ContentType "application/json" -Body $payload

        # Check if the response is valid
        if (!$response) {
            Write-Error "Invoke-RestMethod failed to return a response for $($PdfFilePath)"
            return  # Skip to the next PDF
        }

        $rawResponseContent = $response.choices[0].message.content

        # *** DEBUGGING: Inspect the raw response ***
        Write-Host "Raw Response from LM Studio for $($PdfFilePath):"
        Write-Host $rawResponseContent
        Write-Host "--- End Raw Response ---"


        # Check if the response is empty or whitespace
        if ([string]::IsNullOrWhiteSpace($rawResponseContent)) {
            Write-Warning "LM Studio returned an empty or whitespace response for $($PdfFilePath). Skipping JSON conversion."
            $rawMetadataCollection += [PSCustomObject]@{
                PdfFileName = [System.IO.Path]::GetFileName($PdfFilePath);
                RawMetadata = $null  # Store null to indicate an empty response
            }
            return  # Skip to the next PDF
        }

        # Remove Markdown code fences
        $rawResponseContent = $rawResponseContent -replace '```json', '' -replace '```', ''

        # Attempt to convert from JSON and handle errors
        try {
            $analysis = $rawResponseContent | ConvertFrom-Json
        } catch {
            Write-Error "Conversion from JSON failed for $($PdfFilePath). Raw content: '$rawResponseContent'. Error: $($_.Exception.Message)"
            $rawMetadataCollection += [PSCustomObject]@{
                PdfFileName = [System.IO.Path]::GetFileName($PdfFilePath);
                RawMetadata = $rawResponseContent  # Store the raw content for debugging
            }
            return  # Skip to the next PDF
        }

        $analysisFileName = [System.IO.Path]::GetFileNameWithoutExtension($PdfFilePath) + "_analysis.txt"
        $analysisFilePath = Join-Path -Path $outputDir -ChildPath $analysisFileName

        try {
            $analysis | Out-File -FilePath $analysisFilePath -Encoding UTF8
            Write-Output "LM Studio analysis written to: $analysisFilePath"
        } catch {
            Write-Error "Failed to write analysis to file: $($_.Exception.Message)"
        }

        # Store metadata for CSV output
        $metadataHash = @{}  # Create a hashtable to store values

        foreach ($field in $metadataFields) {
            if ($analysis."$field" -eq $null) {
                $metadataHash[$field] = $null
            }
            else {
                $metadataHash[$field] = $analysis."$field"
            }

        }

        $metadataCollection += [PSCustomObject]$metadataHash

        # Store raw metadata
        $rawMetadataCollection += [PSCustomObject]@{
            PdfFileName = [System.IO.Path]::GetFileName($PdfFilePath);
            RawMetadata = $rawResponseContent
        }

    } catch {
        Write-Error "Failed to analyze PDF with LM Studio: $($_.Exception.Message)"
    }
}

# Use Invoke-WebRequest to get the HTML content of the page
try {
    $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
} catch {
    Write-Error "Failed to retrieve the page. Please check the URL or your internet connection."
    exit
}

$links = $response.Links | Where-Object { $_.href -match "/documents/" }
if ($links.Count -eq 0) {
    Write-Error "No executive order links found on the page."
    exit
}

foreach ($link in $links) {
    $eoPageUrl = "https://www.federalregister.gov" + $link.href

    try {
        $eoPageResponse = Invoke-WebRequest -Uri $eoPageUrl -UseBasicParsing
    } catch {
        Write-Warning "Failed to retrieve the executive order page: $eoPageUrl"
        continue
    }

    $pdfLink = $eoPageResponse.Links | Where-Object { $_.href -match "\.pdf$" }
    if ($pdfLink) {
        $pdfUrl = if ($pdfLink.href -notmatch "^https?://") { "https://www.federalregister.gov" + $pdfLink.href } else { $pdfLink.href }
        $fileName = $pdfUrl.Split("/")[-1]
        $outputFile = Join-Path -Path $outputDir -ChildPath $fileName

        try {
            Invoke-WebRequest -Uri $pdfUrl -OutFile $outputFile
            Write-Output "Downloaded: $fileName"
            Get-PdfWithLMStudio -PdfFilePath $outputFile -LmStudioUrl $lmStudioUrl
        } catch {
            Write-Warning "Failed to download PDF: $pdfUrl"
        }
    } else {
        Write-Warning "No PDF link found on the executive order page: $eoPageUrl"
    }
}

# Write structured metadata to CSV
if ($metadataCollection.Count -gt 0) {
    $metadataCollection | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8
    Write-Output "Structured metadata saved to CSV: $csvFilePath"
}

# Write raw metadata to CSV
if ($rawMetadataCollection.Count -gt 0) {
    $rawMetadataCollection | Export-Csv -Path $rawMetadataCsvFilePath -NoTypeInformation -Encoding UTF8
    Write-Output "Raw metadata saved to CSV: $rawMetadataCsvFilePath"
}

Write-Output "Download, analysis, and metadata extraction process completed."