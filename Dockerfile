FROM mcr.microsoft.com/playwright:v1.45.1-jammy
RUN npm install -g netlify-cli serve
RUN apt update && apt install jq -y