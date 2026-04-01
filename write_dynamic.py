f = open('dynamic.yml', 'w')
f.write("""http:
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
          - url: http://nitroberry_devops_cicd-api1-1:80
          - url: http://nitroberry_devops_cicd-api2-1:80
          - url: http://nitroberry_devops_cicd-api3-1:80
""")
f.close()
print('OK')
