# Consulta WMI para obter métricas de RDP
$metrics = Get-WmiObject -Query "SELECT ActiveSessions, TotalSessions FROM Win32_PerfFormattedData_LocalSessionManager_TerminalServices"

# Verifica se os dados foram obtidos corretamente
if ($metrics) {
    $active = $metrics.ActiveSessions
    $total = $metrics.TotalSessions

    # Caminho para salvar o arquivo .prom
    $path = "C:\Program Files\windows_exporter\textfile_inputs\rdp_sessions.prom"

    # Certifica-se de que o diretório existe
    if (-Not (Test-Path -Path (Split-Path -Parent $path))) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
    }

    # Salva as métricas no formato Prometheus
    @"
# HELP rdp_active_sessions Number of active RDP sessions
# TYPE rdp_active_sessions gauge
rdp_active_sessions $active

# HELP rdp_total_sessions Total number of RDP sessions
# TYPE rdp_total_sessions gauge
rdp_total_sessions $total
"@ | Set-Content -Path $path
} else {
    Write-Output "Failed to retrieve RDP session data."
}
