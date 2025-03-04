# Obtém os eventos de logon e logoff 
$LogonEvents = Get-WinEvent -LogName Security -MaxEvents 1000 | Where-Object {
    ($_.Id -eq 4624 -or $_.Id -eq 4625 -or $_.Id -eq 4634 -or $_.Id -eq 4647) -and
    $_.TimeCreated -ge (Get-Date).AddHours(-144) -and
    $_.Properties[5].Value 
}


# Combina os eventos de logon e terminal services
$CombinedEvents = $LogonEvents 

# Exibe os resultados
if ($CombinedEvents.Count -eq 0) {
    Write-Host "Nenhum evento encontrado para o usuário $UserFilter no período especificado."
} else {
    foreach ($event in $CombinedEvents) {
        $user = $event.Properties[5].Value
        $ip = $event.Properties[18].Value
        Write-Output "Usuário: $user, IP: $ip"
    }
}