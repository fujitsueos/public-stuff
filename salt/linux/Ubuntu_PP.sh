#
LOGFILE=/tmp/fjcmp_pp.log
echo "------Starting Post Provision task--"
# stop FWs
echo "----Stopping FWs" 
#sudo service ufw stop
echo "----Check FWs status" 
#sudo service ufw status

#disable FWs
#echo "`date +%H:%M:%S : Disable FWs" >> $LOGFILE
#sudo ufw disable >>$LOGFILE 2>&1

#--install NGINX
echo "----INSTALL NGINX Section "
#update local package index
echo "--Update package index "
sudo apt update

#Install Nginx
echo "--Get and Install NGINX"
sudo apt -y install nginx

#LIST firewall app
echo "--List Firewall Rule"
sudo ufw app list

# ALLOW NGINX
echo "--ALLOW NGINX Firewall Rule"
sudo ufw allow 'Nginx HTTP'

#check FW status
echo "--CHECK NGINX Firewall Rule"
sudo ufw status

#check NGINX status
echo "--CHECK NGINX Status"
systemctl status nginx

