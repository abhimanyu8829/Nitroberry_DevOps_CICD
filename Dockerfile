FROM nginx:1.27-alpine

# Update Alpine packages to reduce vulnerabilities
RUN apk update && apk upgrade --no-cache

# Copy website content
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80