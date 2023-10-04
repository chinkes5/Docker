# Docker
A place for all my docker compose files

## Wordpress
This is three containers- wordpress, mysql, and myphpadmin. The last one is to edit the database in case I mess up royally...
There is an environment file that you would put in the specific values to run in the compose YAML. In Portainer, this file gets a default name, stack.env. I'm using an NFS share to persist storage for the containers, which is hosted on my Synology, and the primary IP is used to connect. The wordpress db user/pwd just needs a reference to the hard coded db user/pwd above.

## Cloudflare DDNS
This gets the API key in an environment file, no other configuration!

## Pihole
Had to figure out MACVLAN settings to get this one to work. The container would come up with most of the settings copied from [their sample](https://github.com/pi-hole/docker-pi-hole/blob/master/examples/docker-compose.yml.example). However, I'm using it as the DNS lookup for my AD servers (so I don't have to change all the existing machines) and the Docker host is using Port 53. Giving the container it's own IP allows me to get it in the right place on my DNS resolution path.
![Diagram of network, going from the public DNS servers, to the cloud, to my router/firewall to my Pihole to my two domain controllers to many clients](https://github.com/chinkes5/Docker/blob/main/dns-network.drawio.png)
This diagram shows how my clients are continuing to use the Domain Controllers for DNS but now the DC use PiHole for DNS forwarder. This then heads out of my network and I use some 'open' DNS servers on the internet.

Add lists to gravity from https://firebog.net/

### MACVLAN
The additional bit is adding a network to my Unifi Controller for the network defined in the compose file. In the end, I made a subnet that fit in at the beginning of my network IP ranges. I think the network can't be that far off what the NIC is already using, noted here as Parent.