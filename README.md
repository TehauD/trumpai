# Executive Order Analysis Automation

## Overview
This PowerShell script automates the retrieval, analysis, and metadata extraction of executive orders from the Federal Register. It downloads PDFs, extracts text, and leverages AI (via LM Studio) to generate structured metadata for further analysis.

## Features
- **Automated Retrieval:** Scrapes executive order listings from the Federal Register.
- **PDF Downloading:** Fetches and saves executive orders as PDFs.
- **AI-Powered Metadata Extraction:** Uses LM Studio to analyze and structure metadata.
- **CSV Export:** Saves extracted insights into structured CSV files for analysis.

## Prerequisites
Before running the script, ensure the following dependencies are installed:

### Software Requirements
- **PowerShell 7+** (Recommended)
- **LM Studio** (Local AI Model Server)
- **Xpdf Tools** (For `pdftotext` utility)

### Installation
1. **Download & Install PowerShell 7+** (if not already installed):  
   [Download PowerShell](https://github.com/PowerShell/PowerShell/releases)

2. **Install Xpdf Tools** for PDF text extraction:  
   [Download Xpdf Tools](https://www.xpdfreader.com/download.html)

3. **Set up LM Studio:**
   - Install LM Studio and start a local AI model server at `http://localhost:1234/v1/chat/completions`.

4. **Clone the Repository:**
   ```sh
   git clone https://github.com/your-repo/executive-order-analysis.git
   cd executive-order-analysis
   ```

## Configuration
Modify the following variables in the script if needed:
```powershell
$baseUrl = "https://www.federalregister.gov/presidential-documents/executive-orders/donald-trump/2025"
$outputDir = "C:\git\Trumpai"
$lmStudioUrl = "http://localhost:1234/v1/chat/completions"
```
Ensure the `$outputDir` directory exists or will be created by the script.

## Usage
Run the script using PowerShell:
```powershell
.\executive_orders.ps1
```

The script will:
1. Scrape executive orders from the Federal Register.
2. Download the corresponding PDF files.
3. Extract metadata using LM Studio.
4. Save structured metadata into CSV files.

## Output Files
- **Downloaded PDFs:** Stored in `$outputDir`.
- **Structured Metadata CSV:** `executive_orders_metadata.csv`
- **Raw Metadata CSV:** `executive_orders_raw_metadata.csv`
- **AI Analysis Text Files:** Stored alongside PDFs.

## Troubleshooting
- **No PDFs downloaded?** Check the Federal Register URL and ensure valid executive orders are listed.
- **AI extraction failing?** Ensure LM Studio is running at the correct URL.
- **PowerShell execution errors?** Run PowerShell as Administrator and enable script execution:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope Process
  ```

## Future Enhancements
- Add multi-threading for faster processing.
- Improve AI prompts for better metadata extraction.
- Expand support for additional government documents.

## License
This project is licensed under the MIT License.

## Contributing
Feel free to submit pull requests to improve functionality or expand metadata fields.

## Contact
For questions or support, open an issue or reach out on LinkedIn!