# Docker
A place for all my docker compose files

## Wordpress
This is three containers- wordpress, mysql, and myphpadmin. The last one is to edit the database in case I mess up royally...
There is an environment file that you would put in the specific values to run in the compose YAML. In Portainer, this file gets a default name, stack.env. I'm using an NFS share to persist storage for the containers, which is hosted on my Synology, and the primary IP is used to connect. The wordpress db user/pwd just needs a reference to the hard coded db user/pwd above.

## Cloudflare DDNS
This gets the API key in an environment file, no other configuration!
