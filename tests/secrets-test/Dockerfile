FROM alpine:3.21.3

# Use ARG for build-time variables
ARG GIT_AUTH_TOKEN
ARG TEST_SECRET

# Store the secret values in the image (for testing only)
RUN echo "Token: ${GIT_AUTH_TOKEN}" > /token.txt && \
    echo "Secret: ${TEST_SECRET}" > /secretfile.txt

# Create a script to output the values
RUN echo '#!/bin/sh' > /run.sh && \
    echo 'cat /token.txt' >> /run.sh && \
    echo 'cat /secretfile.txt' >> /run.sh && \
    chmod +x /run.sh

CMD ["/run.sh"]
