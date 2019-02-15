# VMQ Redis Backup

## Create backup

This project has a CI job to run a backup creation. You can schedule this job run.
It will upload backup data to a S3 bucket.

## Restore backup

To restore a previous data backup, you must have access to a **Docker Swarm manager** node (CLI) and **vmq-redis** containers (CLI or Portainer). Then, follow the steps on each of following stages:

### Prepare backup file

Get your backup file from S3 and copy it inside **vernemq-redis-data-vol** (mounted at */data* inside container), with the name `dump.rdb`.

### Omit *appendonly* temporally

Update **vmq-redis** service to change command in containers:

```
# Assuming 'mqtt' is the stack name
$ docker service update --args="redis-server" mqtt_vmq-redis
```

This tells redis to load database from `dump.rdb` and stop using `appendonly.aof` file.

### Rotate old files

Get into new container (Portainer or CLI) and run these commands:

```
# Replace the container name
$ docker exec -it mqtt_vmq-redis.<n>.<xxx> /bin/bash
# Assuming 'mqtt' is the stack name and '/data' is the current path
$ rm -f appendonly.aof.old
$ mv appendonly.aof appendonly.aof.old
$ redis-cli BGREWRITEAOF
```

This will rotate the old appendonly file and enable again appendonly mode, to generate a new sequence from current database.

### Re-enable *appendonly*

Update **vmq-redis** service again to change command in containers:

```
# Assuming 'mqtt' is the stack name
docker service update --args="redis-server --appendonly yes" mqtt_vmq-redis
```

This tells redis to load database from `appendonly.aof` again, and continue working like before backup restore.
