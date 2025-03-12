FROM alpine:3.21.3

# Mount secrets during build
RUN --mount=type=secret,id=GIT_AUTH_TOKEN \
    --mount=type=secret,id=TEST_SECRET_FILE \
    echo "Token: $(cat /run/secrets/GIT_AUTH_TOKEN)" > /token.txt && \
    echo "Secret file: $(cat /run/secrets/TEST_SECRET_FILE)" > /secretfile.txt

# Create a script to output the values
RUN echo '#!/bin/sh' > /run.sh && \
    echo 'cat /token.txt' >> /run.sh && \
    echo 'cat /secretfile.txt' >> /run.sh && \
    chmod +x /run.sh

CMD ["/run.sh"]
