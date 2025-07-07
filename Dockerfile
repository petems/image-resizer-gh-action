FROM alpine
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Install Imagemagick and new findutils
RUN apk add --no-cache file
RUN apk --update add imagemagick libjpeg-turbo findutils bash
ENTRYPOINT ["/entrypoint.sh"]
