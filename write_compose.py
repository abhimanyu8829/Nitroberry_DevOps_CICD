f = open('docker-compose.yml', 'w')
f.write("""services:
  traefik:
    image: traefik:v2.10
    command:
      - --api.insecure=true
      - --entrypoints.web.address=:80
      - --providers.file.filename=/etc/traefik/dynamic.yml
    ports:
      - 80:80
      - 8080:8080
    volumes:
      - ./dynamic.yml:/etc/traefik/dynamic.yml
    networks:
      - app-network
  api1:
    image: nginx:alpine
    networks:
      - app-network
  api2:
    image: nginx:alpine
    networks:
      - app-network
  api3:
    image: nginx:alpine
    networks:
      - app-network
networks:
  app-network:
    driver: bridge
""")
f.close()
print('OK')
