# traefik-autoscale.ps1
$MIN_REPLICAS = 2
$MAX_REPLICAS = 6
$TARGET_CPU = 70

# Get CPU usage
$stats = docker stats --no-stream --format "{{.CPUPerc}}" (docker ps -q --filter "name=api") 2>$null
if ($stats) {
    $CPU_USAGE = ($stats | ForEach-Object { [float]($_ -replace '%','') } | Measure-Object -Average).Average
} else {
    $CPU_USAGE = 0
}

$CURRENT = (docker ps --filter "name=api" -q).Count
Write-Host "[$(Get-Date)] CPU: $([math]::Round($CPU_USAGE,1))% | Current: $CURRENT"

if ($CPU_USAGE -gt $TARGET_CPU -and $CURRENT -lt $MAX_REPLICAS) {
    $NEW = $CURRENT + 1
    Write-Host "Scaling UP to $NEW servers" -ForegroundColor Green
    
    # Add new container
    docker run -d --name api$NEW --network nitroberry_devops_cicd_app-network nginx:alpine
    docker exec api$NEW sh -c "echo 'API Server $NEW' > /usr/share/nginx/html/index.html"
    
    # Update Traefik config
    $servers = @()
    for ($i=1; $i -le $NEW; $i++) {
        if ($i -le 3) {
            $servers += "          - url: http://nitroberry_devops_cicd-api${i}-1:80"
        } else {
            $servers += "          - url: http://api${i}:80"
        }
    }
    $serverList = $servers -join "`n"
    
    $config = @"
http:
  routers:
    api:
      rule: PathPrefix("/")
      entryPoints:
        - web
      service: api
  
  services:
    api:
      loadBalancer:
        servers:
$serverList
"@
    
    $config | Out-File -FilePath dynamic.yml -Encoding utf8
    docker-compose restart traefik
}
