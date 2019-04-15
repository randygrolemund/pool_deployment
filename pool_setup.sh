#!/bin/bash
######## Created by Randy Grolemund https://www.profitbotpro.com
######## run script as su (root user) to avoid any permissions issues
######## Script will download and install everything, and then create pool_service account to run the pool
######## Never run a pool as root. Always crate a non-provelage account to run the pool.
######## Pay attention to the ports you expose: 80/443, 8117/8119 (2nd one SSL), 3333,4444,5555,7777
######## If you expose port 22 (SSH), only make it accessible to YOUR IP, not 0.0.0.0

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


echo "******Installing Nodejs version $node_version"
# Additional downloads
if [ $node_version -eq 8 ] || [ $node_version -eq 10 ];then
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash
fi
if [ $node_version = 11 ];then
curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
fi
add-apt-repository ppa:chris-lea/redis-server -y

# Update the server
apt update && apt -y upgrade

# Create swap partition
fallocate -l 1G /swapfile
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "$/swapfile swap swap defaults 0 0" >> /etc/fstab

# install additional software
apt install -y nginx redis-server libssl-dev libboost-all-dev nodejs unzip zip

# Install NPM and set to LTS release
npm install -g n
if [ $node_version -eq 8 ];then
sudo n lts
fi

# Tune Redis
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 1024 > /proc/sys/net/core/somaxconn

# Install PM2 Globally
npm install pm2 -g

#Create the pool_service user
echo "**** Creating $pool_username"
useradd -m $pool_username --shell /bin/bash
mkdir $pool_home_directory/${pool_symbol,,}-pool
mkdir $pool_home_directory/${pool_symbol,,}-wallet

# Configure website folder, move and set permissions
echo "**** Editing Pool config.js"
sed -i "s/pool_api_code/${pool_symbol,,}/g" $server_user_path/website/config.js
echo "**** Editing pool index.html"
sed -i "s/pool_name_code/$pool_name Mining Pool/g" $server_user_path/website/index.html
echo "**** Editing pool home.html"
sed -i "s/pool_symbol_code/${pool_symbol^^}/g" $server_user_path/website/pages/home.html
echo "**** Editing pool getting_started.html"
sed -i "s/pool_algo_code/$pool_algo/g" $server_user_path/website/pages/getting_started.html
echo "**** Moving pool webiste folder."
mv $server_user_path/website/ $pool_home_directory/${pool_symbol,,}-pool/
echo "**** Changing webiste folder permissions."
chown -R $pool_username:$pool_username $pool_home_directory/${pool_symbol,,}-pool/*

# Create the certs directory for pool, copy certs, change ownership to pool user
mkdir /certs
cp $server_user_path/$cert_bundle $server_user_path/$cert_key $server_user_path/$cert_ca $pool_cert_path
chown -R $pool_username:$pool_username /certs

# Copy certs for nginx to /etc/ssl
cp $server_user_path/$cert_bundle $server_user_path/$cert_key $server_user_path/$cert_ca $nginx_cert_path

# Stop nginx, edit & copy default file, then start
service nginx stop
sed -i "s/server_name_code/${pool_symbol,,}/g" $server_user_path/default
sed -i "s/pool_username_code/$pool_username/g" $server_user_path/default
sed -i "s/symbol_name_code/${pool_symbol,,}/g" $server_user_path/default
sed -i "s/cert_bundle/$cert_bundle/g" $server_user_path/default
sed -i "s/cert_key/$cert_key/g" $server_user_path/default
cp $server_user_path/default /etc/nginx/sites-enabled/
service nginx start

# Make sure pool user owns everything in home directory.
chown -R $pool_username:$pool_username $pool_home_directory/*

# Enable Redis server on startup
systemctl enable redis-server.service

#Enable PM2 on Startup for Ubuntu
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup ubuntu -u pool_service --hp /home/pool_service