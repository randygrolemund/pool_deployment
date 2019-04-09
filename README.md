# pool_deployment
Scripts and files to deploy what's needed to run a mining pool



I mostly use one of these pools:

https://github.com/dvandal/cryptonote-nodejs-pool
https://github.com/muscleman/cryptonote-nodejs-pool

I like considtency, and because of this, I wrote a deployment script to configure most of what is needed to spin up a pool.

** I wrote this for Ubuntu, i'm currently running v18.04 on all my pool servers.

Inside pool_setup.sh, you'll see som variables you can change. I tried to make this as easy as possible.
Change the following value to fit your deployment, and algo. Pool_algo is in quotes, because it contains spaces. 

** This script allows for you to change the version of nodejs that will be installed, choose 8, 10, or 11.
I'm currently running v11 on nearly all my pools.

when you are done running this script, you will have installed, configured, and tuned the following:

- Nodej
- Redis
- PM2 (used to keep the pools running)
- The user that will be running the pool (do not use root!)
- Nginx and associated SSL certs (/etc/ssl/)
- API reverse proxy in Nginx (your API will be like: https://ccx.profitbotpro.com/api)
- This will move the website folder to the pool directory in the users home folder, it will setup the name of the pool,
  algo, the favicon (change to our own), it will add the PBP banner to home.html, and also conigure getting_started.html.
- Create a /certs folder on the partition root, for the pool certs, and assign ownership to the pool_service user.

Once you have run this script, all you have to do it download and npm update the pool, download the wallet and daemon, and run them.
The folders these run in will already be created.


# Pool Parameters, change for each!!
pool_name=LightChain
pool_symbol=LCX
pool_algo="Cryptonight Light (Aeon v7)"

# Enter the node version, 8, 10 or 11
node_version=11

# These will also be used for the wallet
pool_username=pool_service
pool_password=your_password

# Certificates - Enter your own below
cert_bundle=ssl-bundle.crt
cert_key=server.key
cert_ca=intermediate_domain_ca.pem

# Certs path
nginx_cert_path=/etc/ssl/
pool_cert_path=/certs/
pool_home_directory=/home/$pool_username
server_user_path=/home/ubuntu
