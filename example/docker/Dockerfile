FROM matomo:4.14.2-apache

# Install MariaDB
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
	&& apt install -y mariadb-server
	

# Start and configure MariaDB
COPY database_dump.sql database_dump.sql
RUN service mariadb start && sleep 10s \
	&& mysqladmin -u root password "root" \
	&& mysql -u root -p"root" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')" \
	&& mysql -u root -p"root" -e "DELETE FROM mysql.user WHERE User=''" \
	&& mysql -u root -p"root" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'" \
	&& mysql -u root -p"root" -e "FLUSH PRIVILEGES" \
	&& mysql -u root -p"root" -e "CREATE DATABASE matomo" \
	&& mysql -u root -p"root" matomo < database_dump.sql \
	&& rm database_dump.sql

# Import the config
COPY config.ini.php /var/www/html/config/config.ini.php
RUN chown www-data:www-data /var/www/html/config/config.ini.php

CMD ["/bin/bash","-c","service mariadb start && apache2-foreground"]