# Docker
A place for all my Docker Compose files.

## Secrets Management
This repository uses `.env.example` files as templates for configuration. To run these services, you must:
1.  Create a copy of the relevant `.env.example` file and rename it to `.env` (e.g., `cp unifi-controller.env.example unifi-controller.env`).
2.  Fill in the required values (passwords, IP addresses, API keys) in the new `.env` file.

The actual `.env` files are listed in `.gitignore` and will not be committed to the repository. It is strongly recommended to store your secret values in a secure password manager.

---

## Wordpress
This is three containers- wordpress, mysql, and myphpadmin. The last one is to edit the database in case I mess up royally...
There is an environment file that you would put in the specific values to run in the compose YAML. In Portainer, this file gets a default name, stack.env. I'm using an NFS share to persist storage for the containers, which is hosted on my Synology, and the primary IP is used to connect. The wordpress db user/pwd just needs a reference to the hard coded db user/pwd above.

## Cloudflare DDNS
This gets the API key in an environment file, no other configuration!

## Monitoring Stack
This is a consolidated monitoring stack that includes:
- **PostgreSQL**: A single, central database instance.
- **Uptime Kuma**: For uptime monitoring and status pages.
- **Beszel**: For website monitoring.
- **Dozzle**: A real-time log viewer for other containers.

The core stack (`docker-compose.monitoring.yaml`) runs PostgreSQL and Uptime Kuma. It uses an `init-db.sh` script to automatically create separate databases and users for the services that need them. All credentials and settings are managed in a central `monitoring.env` file.

### How to Run
1.  Fill in the required passwords in `monitoring.env`.
2.  Start the core services: `docker-compose -f docker-compose.monitoring.yaml up -d`.
3.  Start Beszel and Dozzle using their respective compose files (`Beszel.yaml`, `Dozzle.yaml`) as needed. They will automatically connect to the shared network and database.


## Pihole
Had to figure out MACVLAN settings to get this one to work. The container would come up with most of the settings copied from [their sample](https://github.com/pi-hole/docker-pi-hole/blob/master/examples/docker-compose.yml.example). However, I'm using it as the DNS lookup for my AD servers (so I don't have to change all the existing machines) and the Docker host is using Port 53. Giving the container it's own IP allows me to get it in the right place on my DNS resolution path.

![Diagram of network, going from the public DNS servers, to the cloud, to my router/firewall to my Pihole to my two domain controllers to many clients](https://github.com/chinkes5/Docker/blob/main/dns-network.drawio.png)

This diagram shows how my clients are continuing to use the Domain Controllers for DNS but now the DC use PiHole for DNS forwarder. This then heads out of my network and I use some 'open' DNS servers on the internet.

Add lists to Gravity from https://firebog.net/. There are whitelists at https://github.com/anudeepND/whitelist too but not sure how to implement 'em.

### MACVLAN
The additional bit is adding a network to my Unifi Controller for the network defined in the compose file. In the end, I made a subnet that fit in at the beginning of my network IP ranges. I think the network can't be that far off what the NIC is already using, noted here as Parent.

## UniFi Controller
This uses the image from [jacobalberty/unifi](https://github.com/jacobalberty/unifi-docker). The configuration has been simplified to use a single container with a bundled MongoDB instance, which is more reliable and easier to manage.

It persists all its data to a single parent directory on an NFS share. To handle permissions correctly between the container and the Synology NAS, the `PUID` and `PGID` environment variables should be set to match the owner of the data directory on the NAS.

If migrating from an older setup, you may need to manually remove database connection strings from the `system.properties` file to force the controller to use its internal database. See [here](https://github.com/jacobalberty/unifi-docker/blob/main/Side-Projects.md) for more details.

The [bottom part](https://pimylifeup.com/synology-nas-unifi-network-controller/) of this tutorial talks about what to do once you have the controller running on Synology, specifically some network settings!
