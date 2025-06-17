FROM alpine:3.22.0

# Mount secrets during build
RUN --mount=type=secret,id=GIT_AUTH_TOKEN \
    echo "Token: $(cat /run/secrets/GIT_AUTH_TOKEN)" > /token.txt

# Create a script to output the values
RUN echo '#!/bin/sh' > /run.sh && \
    echo 'cat /token.txt' >> /run.sh && \
    chmod +x /run.sh

CMD ["/run.sh"]
