# base node image
FROM node:24.3-bullseye-slim as base

# set for base and all layer that inherit from it
ENV NODE_ENV production

RUN apt-get update && apt-get install -y openssl sqlite3

# Install all node_modules, including dev dependencies
FROM base as deps

WORKDIR /directus

ADD package.json .npmrc ./
#Install Python
RUN apt-get install -y python3 make g++
# Set environment variable for Python
ENV PYTHON /usr/bin/python3
RUN npm install --production=false

# Setup production node_modules
FROM base as production-deps

WORKDIR /directus

COPY --from=deps /directus/node_modules /directus/node_modules
ADD package.json .npmrc ./
RUN npm prune --production

# Finally, build the production image with minimal footprint
FROM base

ENV DATABASE_URL=file:/data/database/data.db
ENV PORT="8055"
ENV NODE_ENV="production"

# add shortcut for connecting to database CLI
RUN echo "#!/bin/sh\nset -x\nsqlite3 \$DATABASE_URL" > /usr/local/bin/database-cli && chmod +x /usr/local/bin/database-cli

WORKDIR /directus

COPY --from=production-deps /directus/node_modules /directus/node_modules

ADD . .

CMD ["bash", "start.sh"]