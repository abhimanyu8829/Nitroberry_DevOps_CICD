# Load .env
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

# Deploy stack
docker stack deploy -c docker-compose.yml nb-stack

# Show status
docker service ls
