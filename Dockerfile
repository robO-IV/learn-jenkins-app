FROM mcr.microsoft.com/playwright:v1.45.1-jammy
RUN npm install -g netlify-cli serve
RUN apt update
RUN api install jq -y