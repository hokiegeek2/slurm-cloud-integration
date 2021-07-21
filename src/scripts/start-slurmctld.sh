sudo service munge start
sudo service mysql start
sudo service slurmdbd start
sudo mysql -u root < initialize-mariadb.sh

slurmd
slurmctld -D