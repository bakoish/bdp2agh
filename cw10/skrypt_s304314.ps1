# Changelog
# Utworzony dnia: 14-01-2024
# 
# Skrypt pobiera zip, waliduje oraz wysyla dane do bazy TSQL korzystajc z WINRAR.

# Varables
$downloadUrl = "http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"
$path = "D:\projekty\github\bdp2agh\cw10"
$downloadPath = $path 
$unzipPath = $path 
$processedPath = "$path\PROCESSED"
$badFilePath = "$path\InternetSales_new.bad_$(Get-Date -Format 'yyyyMMddHHmmss')"
$zipPassword = Read-Host -Prompt 'Wprowadź hasło do zip'
$indexNumber = "304314"
$winrarPath = "D:\Winrar\WinRAR.exe" 

# SQL SERVER VAR
$databaseServer = "DESKTOP-TIG55ML"
$databaseName = "AdventureWorksDW2019"
$tableName = "CUSTOMERS_$indexNumber"

# GET SCRIPT NAME
$scriptName = $MyInvocation.MyCommand.Name
$logPath = "$processedPath\$scriptName_$(Get-Date -Format 'yyyyMMddHHmmss').log"

# CREATE FOLDER PROCESSED
if(!(Test-Path -Path $processedPath ))
{
    New-Item -ItemType directory -Path $processedPath
}

function Log-Message {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Message
    )

    # GET CURRENT DATE AND TIME
    $TIMESTAMP = GET-DATE -FORMAT 'MM/dd/yyyy hh:mm:ss'

    # ADD MESSAGE TO LOG FILE
    ADD-CONTENT -PATH $LOGPATH -VALUE "$TIMESTAMP – $MESSAGE - SUCCESSFUL"

    # DISPLAY MESSAGE IN CONSOLE
    WRITE-HOST "$TIMESTAMP – $MESSAGE - COMPLETED"
}

# DOWNLOAD FILE
Invoke-WebRequest -Uri $downloadUrl -OutFile "$downloadPath\InternetSales_new.zip"
Log-Message -Message "DOWNLOAD FILE STEP"

# UNZIP FILE
& $winrarPath x -ibck -inul -p"$zipPassword" "$downloadPath\InternetSales_new.zip" "$unzipPath\"
Log-Message -Message "UNZIP STEP"
Start-Sleep -Seconds 2

# READ CSV FILE
$csv = Import-Csv -Path "$unzipPath\InternetSales_new.txt" -Delimiter '|'
$header = $csv[0].PSObject.Properties.Name
$validRows = @()
$badRows = @()
$csv = $csv | Sort-Object * -Unique 

foreach ($row in $csv) {
    if ($row.PSObject.Properties.Name.Count -ne $header.Count) {
        $badRows += $row
        continue
    }

    if ([int]$row.OrderQuantity -gt 100) {
        $badRows += $row
        continue
    }

    if (![string]::IsNullOrEmpty($row.SecretCode)) {
        $badRows += $row
        continue
    }

    if (!($row.Customer_Name -match '^[^,]+,[^,]+$')) {
        $badRows += $row
        continue
    }

    $firstName, $lastName = $row.Customer_Name.Split(',')
    $row | Add-Member -NotePropertyName 'FIRST_NAME' -NotePropertyValue $firstName.Trim()
    $row | Add-Member -NotePropertyName 'LAST_NAME' -NotePropertyValue $lastName.Trim()
    $row.PSObject.Properties.Remove('Customer_Name')
    $validRows += $row
}


# SAVE VALIDATED AND BAD ROWS TO FILE
$validRows | Export-Csv -Path "$unzipPath\InternetSales_new.csv" -NoTypeInformation
$badRows | Export-Csv -Path $badFilePath -NoTypeInformation
Log-Message -Message "FILE SAVED STEP"

# CONNECT TO DATABASE
$conn = New-Object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = "Server=$databaseServer;Database=$databaseName;Integrated Security=True;"

$query = @"
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$tableName')
BEGIN
    DROP TABLE $tableName
END

CREATE TABLE $tableName (
    ProductKey INT,
    CurrencyAlternateKey VARCHAR(255),
    FIRST_NAME VARCHAR(255),
    LAST_NAME VARCHAR(255),
    OrderDateKey DATE,
    OrderQuantity VARCHAR(255),
    UnitPrice VARCHAR(255),
    SecretCode VARCHAR(255)
)
"@

# EXECUTE SQL
$command = $conn.CreateCommand() 
$command.CommandText = $query
$conn.Open()
$command.ExecuteNonQuery() > $null
Log-Message -Message "CREATE TABLE STEP"

# READ CSV
$csvData = Import-Csv -Path $unzipPath\InternetSales_new.csv
foreach ($row in $csvData) {
    $query = @"
    INSERT INTO $tableName (ProductKey, CurrencyAlternateKey, OrderDateKey, OrderQuantity, UnitPrice, SecretCode, FIRST_NAME, LAST_NAME)
    VALUES ('$($row.ProductKey)', '$($row.CurrencyAlternateKey)', '$($row.OrderDateKey)', '$($row.OrderQuantity)', '$($row.UnitPrice)', '$($row.SecretCode)', '$($row.FIRST_NAME)', '$($row.LAST_NAME)')
"@
    $command = $conn.CreateCommand()
    $command.CommandText = $query 
    $command.ExecuteNonQuery() > $null
}
Log-Message -Message "DATA INSERTION STEP"

# MOVE FILE
Move-Item -Path "$unzipPath\InternetSales_new.csv" -Destination "$processedPath\$(Get-Date -Format 'yyyyMMddHHmmss')_InternetSales_new_processed.csv"
Log-Message -Message "File Move Step"


# UPADTE SECRETCODE
$query = @"
UPDATE $tableName
SET SecretCode = LEFT(NEWID(), 5) + RIGHT(NEWID(), 5)
"@
$command = $conn.CreateCommand()
$command.CommandText = $query
$command.ExecuteNonQuery() > $null
Log-Message -Message "SECRETCODE UPDATE STEP"

# SELECT ALL ROWS AND EXPORT
$query = "SELECT * FROM $tableName"
$command = $conn.CreateCommand()
$command.CommandText = $query
$reader = $command.ExecuteReader()
$table = new-object 'System.Data.DataTable'
$table.Load($reader)
$table | Export-Csv -Path "$processedPath\Exported_Customers.csv" -NoTypeInformation -Encoding UTF8 -Delimiter "`t"
Log-Message -Message "SELECT AND EXPORT STEP"


$conn.Close()
# ZIP CSV
Compress-Archive -Path "$processedPath\Exported_Customers.csv" -DestinationPath "$processedPath\Exported_Customers.zip"
Log-Message -Message "ZIP FILE STEP"