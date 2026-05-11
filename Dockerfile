FROM node:14 AS builder
WORKDIR /app

COPY package*.json ./
RUN npm uninstall node-sass && npm install --save-dev sass@1.32.0 --legacy-peer-deps

RUN npm ci --legacy-peer-deps

RUN npm install -g @angular/cli@7.3.9

COPY . .

RUN sed -i 's/"builder": "@angular-devkit\/build-angular:browser"/"builder": "@angular-devkit\/build-angular:browser","options":{"sass":{}}/g' angular.json 2>/dev/null; \
    sed -i 's/"node-sass"/"sass"/g' angular.json 2>/dev/null; \
    sed -i 's/"defaultProject": "kanban-frontend"/"defaultProject": "kanban-frontend",\n  "schematics": {\n    "@schematics/angular:component": {\n      "style": "scss"\n    }\n  }/g' angular.json 2>/dev/null; \
    true

RUN ng build --prod

FROM nginx:1.27-alpine AS runner
COPY default.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist/ /usr/share/nginx/html/
RUN cp -r /usr/share/nginx/html/kanban-ui/* /usr/share/nginx/html/ && rm -rf /usr/share/nginx/html/kanban-ui

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
