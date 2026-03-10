FROM nginx:stable-alpine

RUN apk upgrade --no-cache

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]