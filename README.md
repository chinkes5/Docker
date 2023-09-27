# Docker
A place for all my docker compose files

## Wordpress
This is three containers- wordpress, mysql, and myphpadmin. The last one is to edit the database in case I mess up royally...
There is an environment file that you would put in the specific values to run in the compose YAML. In Portainer, this file gets a default name, stack.env. I'm using an NFS share to persist storage for the containers, which is hosted on my Synology, and the primary IP is used to connect. The wordpress db user/pwd just needs a reference to the hard coded db user/pwd above.

## Cloudflare DDNS
This gets the API key in an environment file, no other configuration!

## Pihole
Had to figure out MACVLAN settings to get this one to work. The container would come up with most of the settings copied from [their sample](https://github.com/pi-hole/docker-pi-hole/blob/master/examples/docker-compose.yml.example). However, I'm using it as the DNS lookup for my AD servers (so I don't have to change all the existing machines) and the Docker host is using Port 53. Giving the container it's own IP allows me to get it in the right place on my DNS resolution path.

### MACVLAN
The additional bit is adding a network to my Unifi Controller for the network defined in the compose file. Since the IP an' all is on the same network as all the rest of my stuff, I need to add it to all the rest of my stuff. You got to the controller -> settings -> Network page. Click on "Create New Network" and fill in the same values you are defining in the compose file (or vice-versa, depending on how you want to think about it). Unchecked Auto-Scale and I was ablet to fill in Host Address, the Netmask (to complete the CIDR range I wanted), VLAN ID, group, DHCP off. The Unifi gateway will now answer on the first IP of that range an' Bob's you're Uncle!