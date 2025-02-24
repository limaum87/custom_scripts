# Author: Felipe Lima
# Date: 23/01/2025
# License: This script is free to redistribute and use as needed.
#
# Description:
# This script checks the status of an application service and its connectivity to the database.
# If the service is stopped, it verifies whether the database is accessible before attempting to start it.
# The status of the checks and any actions taken are logged to a log file.

# Configuration
$DB_HOST = "192.168.8.2"   # Database server IP
$DB_PORT = 5432              # Database port (e.g., 1433 for SQL Server, 3306 for MySQL)
$APP_SERVICE = "Sonnar"      # Application service name
$LOG_FILE = "C:\logs\check_service.log"  # Path to the log file

# Function to write log messages
function Write-Log {
    param ($Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    Add-Content -Path $LOG_FILE -Value $LogEntry
    Write-Host $LogEntry
}

# Function to check if the application service is running
function Check-Service {
    $status = Get-Service -Name $APP_SERVICE -ErrorAction SilentlyContinue
    return $status.Status -eq "Running"
}

# Function to check if the database is accessible
function Check-DB {
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect($DB_HOST, $DB_PORT)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

# Main logic
if (Check-Service) {
    Write-Log "Service $APP_SERVICE is already running. Exiting."
    exit 0
}

Write-Log "Service $APP_SERVICE is stopped. Checking database connection..."

if (Check-DB) {
    Write-Log "Database is accessible. Starting service $APP_SERVICE..."
    Start-Service -Name $APP_SERVICE
} else {
    Write-Log "Database is not accessible. Skipping service start."
}

exit 0
