# Trino
A parallelised querying tool to connect to all sort of data sources, including data lake, data warehouse, direct database connection etc.. It also provides caching and other services on top. 

# How to deploy
https://trino.io/docs/current/installation/deployment.html

## AWS quick POC
Easiest way is to use docker on an EC2 (for dev/POC only), launch EC2 in a public subnet (so no gateway/lb needed) with port 22 (SSH), 8080 (Trino port) open.

### install docker on EC2
https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/

### run Trino
https://hub.docker.com/r/trinodb/trino
```
docker run -d -p 8080:8080 --name trino trinodb/trino
```

### setup catalog (connectors)
```
docker exec -it trino bash
vi /etc/trino/catalog/{source-name}.properties
```
file content:
```
connector.name={type, e.g. sqlserver}
connection-url=jdbc:sqlserver://{host}:{port};database={database-name};encrypt=true;trustServerCertificate=true;
connection-user={user}
connection-password={password}
```
then restart the docker container

### to verify data source
```
docker exec -it trino trino
```
run query to verify
```
select * from {source-name}.{schema}.{table} limit 10;
```

### UI to view query executions
http://{server-ip}:8080/ui

### Client libraries (external connections)
https://trino.io/resources.html
