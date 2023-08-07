#*********************************************************************
# Copyright (c) Intel Corporation 2023
# SPDX-License-Identifier: Apache-2.0
#*********************************************************************/
FROM node:18-bullseye-slim@sha256:b61546375b11029528cae16ae45fa6682a6962d7b0cc34d5a158ad8898970d0a as builder
LABEL license='SPDX-License-Identifier: Apache-2.0' \
    copyright='Copyright (c) Intel Corporation 2023'
WORKDIR /usr/src/app
COPY ["tsconfig.json","tsconfig.build.json","package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]

# Install dependencies
RUN npm ci

COPY src ./src/

# Transpile TS => JS
RUN npm run build
RUN npm prune --production

# Build the final image from alpine base
FROM alpine:latest@sha256:82d1e9d7ed48a7523bdebc18cf6290bdb97b82302a8a9c27d4fe885949ea94d1
ENV NODE_ENV=production

RUN addgroup -g 1000 node && adduser -u 1000 -G node -s /bin/sh -D node 
RUN apk update && apk add nodejs && rm -rf /var/cache/apk/*

COPY --from=builder  /usr/src/app/dist /app/dist
COPY --from=builder  /usr/src/app/node_modules /app/node_modules
COPY --from=builder  /usr/src/app/package.json /app/package.json

# set the user to non-root
USER node

# Default Ports Used
EXPOSE 3000

CMD ["node", "/app/dist/index.js"]

