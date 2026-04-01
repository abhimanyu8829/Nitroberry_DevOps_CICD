# autoscale.ps1
$MIN_REPLICAS = 2
$MAX_REPLICAS = 6
$TARGET_CPU = 70

# Get actual CPU usage from Docker stats
$stats = docker stats --no-stream --format "{{.CPUPerc}}" (docker ps -q --filter "name=api") 2>$null
if ($stats) {
    $CPU_USAGE = ($stats | ForEach-Object { [float]($_ -replace '%','') } | Measure-Object -Average).Average
} else {
    $CPU_USAGE = 0
}

# Count current API containers
$CURRENT = (docker ps --filter "name=api" --format "{{.Names}}" | Measure-Object).Count

Write-Host "[$(Get-Date)] CPU: $([math]::Round($CPU_USAGE,1))% | Current replicas: $CURRENT"

if ($CPU_USAGE -gt $TARGET_CPU -and $CURRENT -lt $MAX_REPLICAS) {
    $NEW = $CURRENT + 1
    Write-Host "SCALING UP to $NEW replicas" -ForegroundColor Green
    
    # Create new container
    docker run -d --name api$NEW --network app-network nginx:alpine
    docker exec api$NEW sh -c "echo 'API Server $NEW' > /usr/share/nginx/html/index.html"
    
    # Update nginx config with new backend
    $UPSTREAM = ""
    for ($i=1; $i -le $NEW; $i++) {
        $UPSTREAM += "    server api$i:80;`n"
    }
    
    $CONFIG = @"
upstream backend {
$UPSTREAM
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        add_header X-Backend-Server `$upstream_addr;
    }
    location /whoami {
        return 200 "Server: `$upstream_addr\n";
        add_header Content-Type text/plain;
    }
}
"@
    
    $CONFIG | Out-File -FilePath nginx.conf -Encoding ascii
    docker cp nginx.conf lb:/etc/nginx/conf.d/default.conf
    docker exec lb nginx -s reload
    
} elseif ($CPU_USAGE -lt 30 -and $CURRENT -gt $MIN_REPLICAS) {
    $REMOVE = $CURRENT
    Write-Host "SCALING DOWN - removing api$REMOVE" -ForegroundColor Yellow
    docker stop api$REMOVE
    docker rm api$REMOVE
    
    # Update nginx config
    if ($REMOVE -gt 1) {
        $UPSTREAM = ""
        for ($i=1; $i -lt $REMOVE; $i++) {
            $UPSTREAM += "    server api$i:80;`n"
        }
        
        $CONFIG = @"
upstream backend {
$UPSTREAM
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        add_header X-Backend-Server `$upstream_addr;
    }
    location /whoami {
        return 200 "Server: `$upstream_addr\n";
        add_header Content-Type text/plain;
    }
}
"@
        
        $CONFIG | Out-File -FilePath nginx.conf -Encoding ascii
        docker cp nginx.conf lb:/etc/nginx/conf.d/default.conf
        docker exec lb nginx -s reload
    }
} else {
    Write-Host "No scaling needed"
}
