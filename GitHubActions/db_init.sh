echo "create user \"Государственный адресный реестр\" password '1234567890';" | sudo -u postgres psql;
echo "create database \"Государственный адресный реестр\" owner \"Государственный адресный реестр\";" | sudo -u postgres psql;
