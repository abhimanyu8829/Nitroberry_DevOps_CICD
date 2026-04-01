$CURRENT = (docker ps --filter "name=api" -q).Count
if ($CURRENT -lt 5) {
    $NEW = $CURRENT + 1
    Write-Host "Scaling to $NEW servers..."
    docker run -d --name api$NEW --network app-network nginx:alpine
    docker exec api$NEW sh -c "echo API Server $NEW > /usr/share/nginx/html/index.html"
    
    $UPSTREAM = ""
    for ($i=1; $i -le $NEW; $i++) { $UPSTREAM += "    server api$i:80;`n" }
    
    @"
upstream backend {
$UPSTREAM
}
server { listen 80; location / { proxy_pass http://backend; } }
"@ | Out-File -FilePath nginx.conf -Encoding ascii
    
    docker cp nginx.conf lb:/etc/nginx/conf.d/default.conf
    docker exec lb nginx -s reload
}
