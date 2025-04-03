$subnet = "192.168.8"  
$timeoutMilliseconds = 100 

$results = @()

Write-Host "Escaneando rede.."

for ($i = 1; $i -le 254; $i++) {
    $ip = "$subnet.$i"
    $client = New-Object System.Net.Sockets.TcpClient
    $beginConnect = $client.BeginConnect($ip, 9100, $null, $null)
    Start-Sleep -Milliseconds $timeoutMilliseconds
    if ($client.Connected) {
        $client.Close()
        $results += [pscustomobject]@{
            enderecoiptestado = $ip
            port = 9100
            open = $true
        }
    }
    else {
        $client.Close()
    }
}

if ($results.Count -eq 0) {
    Write-Host "Nenhum dispositivo com a porta 9100 aberta foi encontrado na rede."
}
else {
    $results | Format-Table -AutoSize
}

