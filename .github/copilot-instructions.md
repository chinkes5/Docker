# Copilot Instructions for Docker Compose Stacks

## Project Overview

This is a personal Docker Compose configuration repository hosting multiple service stacks deployed across **separate Docker instances** managed via **Portainer**:
- **Synology NAS**: Primary instance with NFS storage backend (`/volume5/docker/`)
- **Ubuntu VM**: Secondary instance for additional workloads
- Each `*.yaml` file is a **Portainer stack** (copy/paste into Portainer UI) with independent or networked services
- **Future**: Planned expansion to Azure Container Instances

## Architecture Principles

### Multi-Stack Organization
- **Independent stacks**: Each service has its own compose file (e.g., `wordpress.yaml`, `unifi-controller.yaml`, `pihole.yaml`)
- **Shared monitoring stack**: `monitoring.yaml` provides PostgreSQL + Uptime Kuma as a central backbone; other services (`Beszel.yaml`, `Dozzle.yaml`) connect to it via `external: true` networks
- **Shared storage**: All persistent data on **NAS deployment** uses NFS volumes at `/volume5/docker/`
- **Portainer management**: Stacks are independent unless explicitly networked via `external: true` networks

### Configuration Management
- **Environment variables via `.env` files**: Each stack has an `.env.example` template that must be copied and filled with secrets
- **Variable substitution**: `$NFS_IP`, `$PUID`, `$PGID`, `$SYSTEM_IP`, `$TAG` are injected at runtime
- **Database initialization**: `init-db.sh` auto-creates databases and users for monitoring stack services (runs once via `docker-entrypoint-initdb.d/`)
- **NAS-specific variables**: `NFS_IP` is required for all NAS-deployed stacks; Ubuntu/Azure deployments omit NFS volumes

## Key Stack Patterns

### Monitoring Stack (`monitoring.yaml`, `Beszel.yaml`, `Dozzle.yaml`)
```yaml
# Core: PostgreSQL + Uptime Kuma (own network)
# Satellites: Beszel, Dozzle (connect to monitor_net via external: true)
# Each satellite service: reads monitoring.env for DB credentials, connects to postgres_main
```
**Pattern**: Central database with external services consuming it. When adding monitoring services:
1. Add DB user/password in `monitoring.env.example` and `init-db.sh`
2. Service references `postgres_main:5432` from shared network
3. Use `networks: { monitor_net: { external: true } }` in satellite compose files

### Wordpress Stack (`wordpress.yaml`)
```yaml
# MySQL ← phpMyAdmin ← Wordpress
# All share single env_file (stack.env), volumes use NFS
# Port configuration: MYPHP_PORT, WP_PORT via variables
```
**Pattern**: Multi-tier app with shared env file. DB password must match WordPress env var format.

### UniFi Controller (`unifi-controller.yaml`)
- Uses bundled MongoDB (not external)
- Force internal database via `UNIFI_DB_HOST=127.0.0.1` to avoid connection string issues
- Set `PUID`/`PGID` to match NFS parent directory ownership on NAS
- Labels prevent Watchtower auto-updates: `com.centurylinklabs.watchtower.enable=false`

### Pi-hole (`pihole.yaml`)
- **Multi-network**: macvlan (native IP 192.168.1.2) + bridge (Docker overlay)
- macvlan requires parent NIC and subnet configuration in Unifi Network Settings
- Bypasses Docker DNS via dedicated IP, acts as DNS forwarder in network chain
- Disabled DHCP/IPv6 (static config mode)

### Cloudflare DDNS (`cloudflare-ddns.yaml`)
- Minimal config: API key only in environment file
- Single-purpose, stateless container

### Watchtower (`watchtower.yaml`)
- Global container updater with label-based exclusion
- Services opt-out via `com.centurylinklabs.watchtower.enable=false` label

## Deployment Approach

### Portainer Stack Deployment
All YAML files are designed to be **copy/pasted directly into Portainer**:
1. Create/update `*.yaml` file in this repo
2. Copy entire file contents → Portainer UI → "Stacks" → "Add Stack" → paste into editor
3. Upload `.env.example` as `.env` template in Portainer (fill in secrets via UI)
4. Portainer handles environment variable substitution automatically

**Important**: Each `.yaml` is a **standalone Portainer stack** - do not run via CLI (`docker-compose -f`) on Portainer-managed instances.

### Creating a New Service Stack
1. **Create compose file** (`service.yaml`): Use `version: "3.9"` or `"3.7"` for consistency
2. **Add env template** (`service.env.example`): Document all required variables
3. **Volumes**: For NAS deployment, use NFS driver template:
   ```yaml
   volumes:
     service_data:
       driver: local
       driver_opts:
         type: nfs
         o: addr=$NFS_IP,nolock,soft,rw,nfsvers=4
         device: :/volume5/docker/service
   ```
   For non-NFS deployments (Ubuntu VM, Azure), use local or cloud-native drivers
4. **Test locally** (optional): `cp service.env.example service.env` → fill values → `docker-compose -f service.yaml up -d`
5. **Deploy to Portainer**: Paste YAML into Portainer UI, configure env file

### Integrating with Monitoring Stack
- Add database user/password to `monitoring.env.example` and `init-db.sh`
- Service connect string: `postgres://$USER:$PASSWORD@postgres_main:5432/dbname`
- Use `networks: { monitor_net: { external: true } }` and `depends_on: [postgres]` (in core stack only)

### Storage Troubleshooting
- NFS volumes require correct path format: `:/volume5/docker/...` (colon-slash prefix)
- NFS options (`nolock,soft,rw`) prevent hangs on network issues
- UniFi/Synology permissions: run `PUID`/`PGID` commands on NAS to match container process ownership

## Conventions

- **Container naming**: `container_name` matches service abbreviation (e.g., `pihole`, `uptime_kuma`, `postgres_main`)
- **Restart policy**: Use `unless-stopped` (auto-restart on reboot) or `always`
- **Network modes**:
  - Standard bridge: Most services
  - macvlan: Only Pi-hole (needs native network access)
  - External: Satellite monitoring services
- **Port mapping**: Document what each port does (see `unifi-controller.yaml` line 22–28)
- **Timezone**: Set TZ environment var for consistent logging (e.g., `America/Denver`)

## File References

- **Architecture decisions**: See README.md sections on Pihole MACVLAN, Monitoring Stack consolidation, UniFi bundled DB
- **NFS config patterns**: All `*.yaml` files > `volumes` section
- **Database setup**: `init-db.sh` + `monitoring.env.example`
- **Network diagram**: `dns-network.drawio.png` shows DNS chain (Clients → PiHole → Public DNS)

## Common Tasks

| Task | Command | Notes |
|------|---------|-------|
| Deploy service | `docker-compose -f service.yaml up -d` | Set env vars first |
| View logs | `docker logs -f container_name` | Real-time with `-f` |
| Execute in container | `docker exec -it postgres_main psql -U admin` | Access databases |
| Update image | Watchtower auto-updates unless labeled `watchtower.enable=false` | |
| Backup NFS data | Via Synology Task Scheduler | Persistent volumes on NAS |
