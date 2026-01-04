# GenieACS Docker Setup

Docker Compose setup for GenieACS with MongoDB.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                   docker-compose.genieacs.yml                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    MongoDB 4.4                               │   │
│  │                   Port: 27017                                │   │
│  │     (auto-imports data from parameters/ on first start)     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              ▼                                      │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐          │
│  │ genieacs-cwmp │  │ genieacs-nbi  │  │ genieacs-fs   │          │
│  │  Port: 7547   │  │  Port: 7557   │  │  Port: 7567   │          │
│  └───────────────┘  └───────────────┘  └───────────────┘          │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                    genieacs-ui                                 │ │
│  │                    Port: 3000                                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Services

| Service       | Port  | Description                          |
| ------------- | ----- | ------------------------------------ |
| MongoDB       | 27017 | Database for GenieACS                |
| GenieACS CWMP | 7547  | TR-069 CWMP endpoint for CPE devices |
| GenieACS NBI  | 7557  | Northbound API interface             |
| GenieACS FS   | 7567  | File server for firmware uploads     |
| GenieACS UI   | 3000  | Web-based management interface       |

## Quick Start

### Start All Services (Recommended)

The `docker-compose.genieacs.yml` includes both GenieACS and MongoDB services:

```bash
# Create required directories
mkdir -p data/logs data/ext

# Start all services
docker-compose -f docker-compose.genieacs.yml up -d
```

On first startup, MongoDB will automatically import the data from the `parameters/` folder (presets, provisions, virtualParameters, config).

### Start MongoDB Only (Optional)

If you need to run MongoDB separately:

```bash
docker-compose -f docker-compose.mongodb.yml up -d
```

## Database Initialization

The `parameters/` folder contains BSON files that are automatically imported when MongoDB starts for the first time:

| File                   | Collection        | Description                   |
| ---------------------- | ----------------- | ----------------------------- |
| config.bson            | config            | GenieACS configuration        |
| presets.bson           | presets           | Device presets                |
| provisions.bson        | provisions        | Provisioning scripts          |
| virtualParameters.bson | virtualParameters | Virtual parameter definitions |

To re-import the database (will delete existing data):

```bash
# Stop containers and remove MongoDB volume
docker-compose -f docker-compose.genieacs.yml down -v

# Start again (will re-import data)
docker-compose -f docker-compose.genieacs.yml up -d
```

## Access

- **GenieACS UI**: http://localhost:3000
- **CWMP Endpoint**: http://localhost:7547 (configure this in your CPE devices)
- **NBI API**: http://localhost:7557
- **File Server**: http://localhost:7567

## Stop Services

```bash
# Stop all services
docker-compose -f docker-compose.genieacs.yml down

# Stop and remove volumes (WARNING: deletes data)
docker-compose -f docker-compose.genieacs.yml down -v
```

## Configuration

### Environment Variables

Copy `env.example` to `.env` and modify as needed:

```bash
cp env.example .env
```

### Available Settings

| Variable                          | Default                              | Description                                              |
| --------------------------------- | ------------------------------------ | -------------------------------------------------------- |
| `MONGO_ROOT_USER`                 | `admin`                              | MongoDB root username                                    |
| `MONGO_ROOT_PASSWORD`             | `adminpassword`                      | MongoDB root password (CHANGE IN PRODUCTION!)            |
| `GENIEACS_MONGODB_CONNECTION_URL` | (auto-generated with credentials)    | MongoDB connection string                                |
| `GENIEACS_UI_JWT_SECRET`          | `changeme-to-a-secure-random-string` | JWT secret for UI authentication (change in production!) |
| `GENIEACS_CWMP_INTERFACE`         | `0.0.0.0`                            | CWMP interface binding                                   |
| `GENIEACS_NBI_INTERFACE`          | `0.0.0.0`                            | NBI interface binding                                    |
| `GENIEACS_FS_INTERFACE`           | `0.0.0.0`                            | File server interface binding                            |
| `GENIEACS_UI_INTERFACE`           | `0.0.0.0`                            | UI interface binding                                     |
| `GENIEACS_FS_HOSTNAME`            | (empty)                              | Hostname for file server URLs                            |
| `DATA_DIR`                        | `./data`                             | Directory for logs and extensions                        |
| `TZ`                              | `Asia/Jakarta`                       | Timezone                                                 |

### MongoDB Authentication

MongoDB is configured with authentication enabled by default. The default credentials are:

- **Username**: `admin`
- **Password**: `adminpassword`

⚠️ **IMPORTANT**: Change these credentials in production by setting `MONGO_ROOT_USER` and `MONGO_ROOT_PASSWORD` in your `.env` file.

## Volumes

| Volume            | Description              |
| ----------------- | ------------------------ |
| `mongodb_data`    | MongoDB data persistence |
| `genieacs-logs`   | GenieACS log files       |
| `genieacs-config` | GenieACS config files    |

## Extensions

Place custom GenieACS extensions in the `ext/` folder. They will be mounted to `/opt/genieacs/ext` in the container.

## Troubleshooting

### Check container logs

```bash
# GenieACS logs
docker logs genieacs-server

# MongoDB logs
docker logs genieacs-mongodb

# Follow logs in real-time
docker logs -f genieacs-server
```

### Check if services are running

```bash
docker-compose -f docker-compose.genieacs.yml ps
```

### Check internal service logs

```bash
# Access GenieACS container
docker exec -it genieacs-server bash

# View individual service logs
cat /var/log/genieacs/genieacs-cwmp.log
cat /var/log/genieacs/genieacs-ui.log
```

### MongoDB connection issues

Ensure MongoDB is running and accessible:

```bash
# With default credentials
docker exec -it genieacs-mongodb mongo -u admin -p adminpassword --authenticationDatabase admin --eval "db.adminCommand('ping')"
```

### Verify database import

```bash
# With default credentials
docker exec -it genieacs-mongodb mongo -u admin -p adminpassword --authenticationDatabase admin genieacs --eval "db.getCollectionNames()"
```

### Rebuild containers after changes

```bash
docker-compose -f docker-compose.genieacs.yml build --no-cache
docker-compose -f docker-compose.genieacs.yml up -d
```
