FROM php:8.2-cli-alpine
WORKDIR /app/Boot
COPY . /app/Boot
ENV BOOT_REPORTS_DIR=/app/Boot/var/sample-reports BOOT_SEND_TELEGRAM=false
CMD ["php", "-S", "0.0.0.0:8080", "-t", "public_html"]
