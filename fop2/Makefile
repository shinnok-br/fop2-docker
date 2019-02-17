INSTALL	= install
CHKCONFIG = /sbin/chkconfig
prefix	:= /usr/local

install:
	@if [ -f /usr/local/fop2/fop2.lic ]; then \
		cp /usr/local/fop2/fop2.lic server/fop2.lic; \
		clear; \
		if [ -f /etc/sysconfig/fop2 ]; then \
			NIC=`grep -o '\-i [^ "]*' /etc/sysconfig/fop2`; \
		fi; \
		if [ -f /etc/default/fop2 ]; then \
			NIC=`grep -o '\-i [^ "]*' /etc/default/fop2`; \
		fi; \
		server/fop2_server --reactivate $$NIC; \
		if [ $$? -ne 0 ]; then \
			echo; \
			echo "Upgrade Aborted. License reactivation failed."; \
			echo; \
			echo "Be sure you have internet access from this server, "; \
			echo "and that your code is not older than a year." ; \
			echo; \
			echo "If your license has expired, you must renew it in order to upgrade,"; \
			echo "or you can still use your current FOP2 version for as long as you want."; \
			echo; \
			echo "If you already bought an upgrade code please run the following command:"; \
			echo; \
			echo "server/fop2_server --upgrade"; \
			echo; \
			echo "If the upgrade is successful run "make" again to retry the installation."; \
			echo; \
			echo "Contact us at sales@asternic.biz for more information."; \
			exit; \
		fi; \
	fi; \
	test -d $(prefix) || mkdir -p $(prefix); \
	$(INSTALL) -d -m 755 server /usr/local/fop2; \
	$(INSTALL) --backup=numbered -m 644 server/buttons_custom.cfg.sample /usr/local/fop2/; \
	$(INSTALL) --backup=numbered -m 644 server/autobuttons.cfg /usr/local/fop2/; \
	if [ -f server/fop2.lic ]; then \
	$(INSTALL) --backup=numbered -m 644 server/fop2.lic /usr/local/fop2/; \
	fi; \
	$(INSTALL) -b -m 644 server/extensions_override_freepbx.conf /usr/local/fop2/; \
	if hash lsof 2>/dev/null; then \
	user=$$(lsof -i :80 | tail -n 1 | awk '{print $$3}'); \
	fi; \
	if [ "Z$$user" = "Z" ]; then \
	user=$$(getent passwd asterisk > /dev/null && if [ $$? -eq 0 ]; then echo 'asterisk'; fi); \
	fi; \
	if [ "Z$$user" = "Z" ]; then \
	user=$$(getent passwd apache > /dev/null && if [ $$? -eq 0 ]; then echo 'apache'; fi); \
	fi; \
	if [ "Z$$user" = "Z" ]; then \
	user=$$(getent passwd www-data > /dev/null && if [ $$? -eq 0 ]; then echo 'www-data'; fi); \
	fi; \
	chgrp $$user /usr/local/fop2; \
	chmod 775 /usr/local/fop2; \
	if [ ! -d /var/www/html ]; then \
	if [ -d /var/www ]; then \
		echo "no var www html changing web dir"; \
		sed 's/\/var\/www\/html\/fop2/\/var\/www\/fop2/g' server/fop2.cfg > /tmp/fop2.cfg; \
		mv /tmp/fop2.cfg server/fop2.cfg; \
	fi; \
	fi; \
	if [ -x /srv/www/htdocs ]; then \
		sed 's/\/var\/www\/html\/fop2/\/srv\/www\/htdocs\/fop2/g' server/fop2.cfg > /tmp/fop2.cfg; \
		mv /tmp/fop2.cfg server/fop2.cfg; \
	fi; \
	if [ -x /opt/pbxware/pw/home/sitemanager/admin ]; then \
		sed 's/\/var\/www\/html\/fop2/\/opt\/pbxware\/pw\/home\/sitemanager\/admin\/fop2/g' server/fop2.cfg > /tmp/fop2.cfg; \
		sed 's/\/etc\/asterisk\/voicemail/\/opt\/pbxware\/pw\/etc\/asterisk\/voicemail/g' server/autoconfig-users.sh > /tmp/autoconfig-users-mod.sh; \
		sed 's/mysql -/\/opt\/pbxware\/sh\/mysql -/' /tmp/autoconfig-users-mod.sh > /tmp/autoconfig-users2.sh; \
		sed 's/mysql -/\/opt\/pbxware\/sh\/mysql -/' server/autoconfig-buttons.sh > /tmp/autoconfig-buttons2.sh; \
		mv /tmp/fop2.cfg server/fop2.cfg; \
		mv /tmp/autoconfig-users2.sh server/autoconfig-users.sh; \
		mv /tmp/autoconfig-buttons2.sh server/autoconfig-buttons.sh; \
	fi; \
	if [ -f /usr/local/fop2/fop2.cfg ]; then \
		$(INSTALL) -m 644 server/fop2.cfg /usr/local/fop2/fop2.cfg.new; \
		echo "New configuration file /usr/local/fop2/fop2.cfg.new installed. Original fop2.cfg preserved."; \
		cp /usr/local/fop2/fop2.cfg /usr/local/fop2/fop2.cfg.bak; \
		cp /usr/local/fop2/fop2.cfg /usr/local/fop2/autobuttons.cfg.bak; \
		sed 's/users-freepbx/users/g' /usr/local/fop2/fop2.cfg > /tmp/fop2.cfg; \
		mv /tmp/fop2.cfg /usr/local/fop2/fop2.cfg; \
		sed 's/buttons-freepbx/users/g' /usr/local/fop2/autobuttons.cfg > /tmp/autobuttons.cfg; \
		mv /tmp/autobuttons.cfg /usr/local/fop2/autobuttons.cfg; \
	else \
		$(INSTALL) -b -m 644 server/fop2.cfg /usr/local/fop2/; \
	fi; \
	if [ -f /var/www/html/admin/modules/fop2admin/functions.inc.php ]; then \
		echo "FOP2Admin Module detected, you should go to FreePBX Module Manager and uninstall it as the new FOP2 Manager superseded it."; \
		echo "You can access the new FOP2Manager from http://your.server/fop2/admin"; \
		sed 's/fop2admin_get_config(/fop2admin_get_config_disabled(/g' /var/www/html/admin/modules/fop2admin/functions.inc.php > /tmp/functions.inc.php; \
		mv /tmp/functions.inc.php /var/www/html/admin/modules/fop2admin/functions.inc.php; \
		rm -f /var/www/html/admin/modules/fop2admin/uninstall.sql; \
	fi; \
	if [ -f /var/www/html/admin/modules/fop2admin/uninstall.sql ]; then \
		rm -f /var/www/html/admin/modules/fop2admin/uninstall.sql; \
		echo "FOP2Admin Module detected, you should go to FreePBX Module Manager and uninstall it."; \
	fi; \
	if [ -f /usr/local/fop2/FOP2Callbacks.pm ]; then \
		$(INSTALL) --backup=numbered -m 644 server/FOP2Callbacks.pm.sample /usr/local/fop2/; \
	else \
		$(INSTALL) --backup=numbered -m 644 server/FOP2Callbacks.pm.sample /usr/local/fop2/FOP2Callbacks.pm; \
	fi; \
	$(INSTALL) -m 751 server/fop2_server /usr/local/fop2/; \
	$(INSTALL) -m 755 server/tovoicemail.pl /usr/local/fop2/; \
	$(INSTALL) -m 755 server/recording_fop2.pl /usr/local/fop2/; \
	$(INSTALL) -m 755 server/recording_elastix.pl /usr/local/fop2/; \
	$(INSTALL) -m 755 server/recording_cdr.pl /usr/local/fop2/; \
	$(INSTALL) -m 751 server/generate_override_contexts.pl /usr/local/fop2/; \
	$(INSTALL) --backup=numbered -m 751 server/*.sh /usr/local/fop2/; \
	if [ -x /var/www/html ]; then \
		if [ -f /var/www/html/fop2/checkdir.php ]; then \
			cp /var/www/html/fop2/checkdir.php /var/www/html/fop2/checkdir.old.php; \
		fi; \
		if [ -f /var/www/html/fop2/js/presence.js ]; then \
			$(INSTALL) --backup=numbered html/js/presence.js /var/www/html/fop2/js/; \
		fi; \
		if [ -f /var/www/html/fop2/admin/config.php ]; then \
			cp /var/www/html/fop2/admin/config.php /var/www/html/fop2/admin/config.old.php; \
			$(INSTALL) html/admin/config.php /var/www/html/fop2/admin/config.new.php; \
		fi; \
		if [ -f /var/www/html/fop2/config.php ]; then \
			cp /var/www/html/fop2/config.php /var/www/html/fop2/config.old.php; \
			$(INSTALL) html/config.php /var/www/html/fop2/config.new.php; \
		fi; \
		$(INSTALL) -d -m 755 html /var/www/html/fop2; \
		$(INSTALL) -d -m 755 html/css /var/www/html/fop2/css; \
		$(INSTALL) -d -m 755 html/images /var/www/html/fop2/images; \
		$(INSTALL) -d -m 755 html/js /var/www/html/fop2/js; \
		$(INSTALL) -d -m 755 html/lang /var/www/html/fop2/lang; \
		$(INSTALL) -d -m 755 html/lib /var/www/html/fop2/lib; \
		$(INSTALL) -d -m 755 html/admin /var/www/html/fop2/admin; \
		mkdir -p /var/www/html/fop2/uploads; \
		chmod 771 /var/www/html/fop2/uploads; \
		cp -rp html/* /var/www/html/fop2/; \
		cp -rp html/.ht* /var/www/html/fop2/; \
		chown $$user.$$user /var/www/html/fop2/admin; \
		chown $$user.$$user /var/www/html/fop2/uploads; \
		chown $$user.$$user /var/www/html/fop2/admin/* -R; \
		if [ ! -f /var/www/html/fop2/admin/functions-custom.php ]; then \
			cp /var/www/html/fop2/admin/functions-custom-dist.php /var/www/html/fop2/admin/functions-custom.php; \
		fi; \
		if [ -f /var/www/html/fop2/config.old.php ]; then \
			rm -f /var/www/html/fop2/config.php~; \
			cp /var/www/html/fop2/config.old.php /var/www/html/fop2/config.php; \
			echo "New configuration file /var/www/html/fop2/config.new.php installed. Original config.php preserved."; \
		fi; \
		if [ -f /var/www/html/fop2/admin/config.old.php ]; then \
			cp /var/www/html/fop2/admin/config.old.php /var/www/html/fop2/admin/config.php; \
			echo "New configuration file /var/www/html/fop2/admin/config.new.php installed. Original config.php preserved."; \
		fi; \
	elif [ -x /var/www ]; then \
		if [ -f /var/www/fop2/checkdir.php ]; then \
			cp /var/www/fop2/checkdir.php /var/www/fop2/checkdir.old.php; \
		fi; \
		if [ -f /var/www/fop2/js/presence.js ]; then \
			$(INSTALL) --backup=numbered html/js/presence.js /var/www/fop2/js/; \
		fi; \
		if [ -f /var/www/fop2/admin/config.php ]; then \
			$(INSTALL) --backup=numbered html/admin/config.php /var/www/fop2/admin; \
		fi; \
		$(INSTALL) -d -m 755 html /var/www/fop2; \
		$(INSTALL) -d -m 755 html/css /var/www/fop2/css; \
		$(INSTALL) -d -m 755 html/images /var/www/fop2/images; \
		$(INSTALL) -d -m 755 html/js /var/www/fop2/js; \
		$(INSTALL) -d -m 755 html/lang /var/www/fop2/lang; \
		$(INSTALL) -d -m 755 html/lib /var/www/fop2/lib; \
		$(INSTALL) -d -m 755 html/admin /var/www/fop2/admin; \
		if [ -f /var/www/fop2/config.php ]; then \
    		cp /var/www/fop2/config.php /var/www/fop2/config.old.php; \
	    	$(INSTALL) html/config.php /var/www/fop2/config.new.php; \
		fi; \
		if [ -f /var/www/fop2/admin/config.php ]; then \
    		cp /var/www/fop2/admin/config.php /var/www/fop2/admin/config.old.php; \
	    	$(INSTALL) html/admin/config.php /var/www/fop2/admin/config.new.php; \
		fi; \
		$(INSTALL) -d -m 755 html/lib /var/www/fop2/lib; \
		mkdir -p /var/www/fop2/uploads; \
		chmod 777 /var/www/fop2/uploads; \
		cp -rp html/* /var/www/fop2/; \
		cp -rp html/.ht* /var/www/fop2/; \
		if [ ! -f /var/www/fop2/admin/functions-custom.php ]; then \
			cp /var/www/fop2/admin/functions-custom-dist.php /var/www/fop2/admin/functions-custom.php; \
		fi; \
		if [ -f /var/www/fop2/config.old.php ]; then \
			rm -f /var/www/fop2/config.php~; \
            cp /var/www/fop2/config.old.php /var/www/fop2/config.php; \
			echo "New configuration file /var/www/fop2/config.new.php installed. Original config.php preserved."; \
		fi; \
		if [ -f /var/www/fop2/admin/config.old.php ]; then \
            cp /var/www/fop2/admin/config.old.php /var/www/fop2/admin/config.php; \
			echo "New configuration file /var/www/fop2/admin/config.new.php installed. Original config.php preserved."; \
		fi; \
	elif [ -x /srv/www/htdocs ]; then \
		if [ -f /srv/www/htdocs/fop2/js/presence.js ]; then \
			$(INSTALL) --backup=numbered html/js/presence.js /srv/www/htdocs/fop2/js/; \
		fi; \
		if [ -f /srv/www/htdocs/fop2/admin/config.php ]; then \
			cp /srv/www/htdocs/fop2/admin/config.php /srv/www/htdocs/fop2/admin/config.old.php; \
            $(INSTALL) html/admin/config.php /srv/www/htdocs/fop2/admin/config.new.php; \
		fi; \
		if [ -f /srv/www/htdocs/fop2/config.php ]; then \
			cp /srv/www/htdocs/fop2/config.php /srv/www/htdocs/fop2/config.old.php; \
            $(INSTALL) html/config.php /srv/www/htdocs/fop2/config.new.php; \
		fi; \
		$(INSTALL) -d -m 755 html /srv/www/htdocs/fop2; \
		$(INSTALL) -d -m 755 html/css /srv/www/htdocs/fop2/css; \
		$(INSTALL) -d -m 755 html/images /srv/www/htdocs/fop2/images; \
		$(INSTALL) -d -m 755 html/js /srv/www/htdocs/fop2/js; \
		$(INSTALL) -d -m 755 html/lang /srv/www/htdocs/fop2/lang; \
		$(INSTALL) -d -m 755 html/lib /srv/www/htdocs/fop2/lib; \
		$(INSTALL) -d -m 755 html/admin /srv/www/htdocs/fop2/admin; \
		mkdir -p /srv/www/htdocs/fop2/uploads; \
		chmod 777 /srv/www/htdocs/fop2/uploads; \
		if [ -f /srv/www/htdocs/fop2/config.php ]; then \
			cp /srv/www/htdocs/fop2/config.php /srv/www/htdocs/fop2/config.old.php; \
		fi; \
		if [ -f /srv/www/htdocs/fop2/admin/config.php ]; then \
			cp /srv/www/htdocs/fop2/admin/config.php /srv/www/htdocs/fop2/admin/config.old.php; \
		fi; \
		cp -rp html/* /srv/www/htdocs/fop2/; \
		cp -rp html/.ht* /srv/www/htdocs/fop2/; \
		if [ ! -f /srv/www/htdocs/fop2/admin/functions-custom.php ]; then \
			cp /srv/www/htdocs/fop2/admin/functions-custom-dist.php /srv/www/htdocs/fop2/admin/functions-custom.php; \
		fi; \
		if [ -f /srv/www/htdocs/fop2/config.old.php ]; then \
			rm -f /srv/www/htdocs/fop2/config.php~; \
            cp /srv/www/htdocs/fop2/config.old.php /srv/www/htdocs/fop2/config.php; \
			echo "New configuration file /srv/www/htdocs/fop2/config.new.php installed. Original config.php preserved."; \
		fi; \
		if [ -f /srv/www/htdocs/fop2/admin/config.old.php ]; then \
            cp /srv/www/htdocs/fop2/admin/config.old.php /srv/www/htdocs/fop2/admin/config.php; \
			echo "New configuration file /srv/www/htdocs/fop2/admin/config.new.php installed. Original config.php preserved."; \
		fi; \
	elif [ -x /opt/pbxware/pw/home/sitemanager/admin ]; then \
		if [ -f /opt/pbxware/pw/home/sitemanager/admin/fop2/js/presence.js ]; then \
			$(INSTALL) --backup=numbered html/js/presence.js /opt/pbxware/pw/home/sitemanager/admin/fop2/js/; \
		fi; \
		if [ -f /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.php ]; then \
            cp /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.php /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.old.php; \
			$(INSTALL) html/admin/config.php /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.new.php; \
		fi; \
		if [ -f /opt/pbxware/pw/home/sitemanager/admin/fop2/config.php ]; then \
            cp /opt/pbxware/pw/home/sitemanager/admin/fop2/config.php /opt/pbxware/pw/home/sitemanager/admin/fop2/config.old.php; \
			$(INSTALL) html/config.php /opt/pbxware/pw/home/sitemanager/admin/fop2/config.new.php; \
		fi; \
		$(INSTALL) -d -m 755 html /opt/pbxware/pw/home/sitemanager/admin/fop2; \
		$(INSTALL) -d -m 755 html/css /opt/pbxware/pw/home/sitemanager/admin/fop2/css; \
		$(INSTALL) -d -m 755 html/images /opt/pbxware/pw/home/sitemanager/admin/fop2/images; \
		$(INSTALL) -d -m 755 html/js /opt/pbxware/pw/home/sitemanager/admin/fop2/js; \
		$(INSTALL) -d -m 755 html/lang /opt/pbxware/pw/home/sitemanager/admin/fop2/lang; \
		$(INSTALL) -d -m 755 html/lib /opt/pbxware/pw/home/sitemanager/admin/fop2/lib; \
		mkdir -p /opt/pbxware/pw/home/sitemanager/admin/fop2/uploads; \
		chmod 777 /opt/pbxware/pw/home/sitemanager/admin/fop2/uploads; \
		if [ -f /opt/pbxware/pw/home/sitemanager/admin/fop2/config.php ]; then \
			cp /opt/pbxware/pw/home/sitemanager/admin/fop2/config.php /opt/pbxware/pw/home/sitemanager/admin/fop2/config.old.php; \
		fi; \
		cp -rp html/* /opt/pbxware/pw/home/sitemanager/admin/fop2/; \
		cp -rp html/.ht* /opt/pbxware/pw/home/sitemanager/admin/fop2/; \
		if [ -f /opt/pbxware/pw/home/sitemanager/admin/fop2/config.old.php ]; then \
			rm -f /opt/pbxware/pw/home/sitemanager/admin/fop2/config.php~; \
            cp /opt/pbxware/pw/home/sitemanager/admin/fop2/config.old.php /opt/pbxware/pw/home/sitemanager/admin/fop2/config.php; \
			echo "New configuration file /opt/pbxware/pw/home/sitemanager/admin/fop2/config.new.php installed. Original config.php preserved."; \
		fi; \
		if [ -f /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.old.php ]; then \
            cp /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.old.php /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.php; \
			echo "New configuration file /opt/pbxware/pw/home/sitemanager/admin/fop2/admin/config.new.php installed. Original config.php preserved."; \
		fi; \
	else \
		echo "Could not install client. No suitable target found."; fi; \
	if [ -f /etc/debian_version ]; then \
		$(INSTALL) -m 755 init/fop2.debian /etc/init.d/fop2; \
		if [ ! -f /etc/default/fop2 ]; then \
			$(INSTALL) -m 644 init/default.fop2 /etc/default/fop2; \
		fi; \
		update-rc.d fop2 defaults; \
		if [ -f /etc/asterisk/snep/snep-features.conf ]; then \
			apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install php5-sqlite; \
		fi; \
		if hash a2enmod 2>/dev/null; then \
		a2enmod headers; \
		fi; \
		if hash apache2 2>/dev/null; then \
		apachectl graceful; \
		fi; \
	elif [ -f /etc/redhat-release ]; then \
		$(INSTALL) -m 755 init/fop2.redhat /etc/rc.d/init.d/fop2; \
		${CHKCONFIG} --add fop2 ; \
		if [ ! -f /etc/sysconfig/fop2 ]; then \
			$(INSTALL) -m 644 init/sysconfig.fop2 /etc/sysconfig/fop2; \
		fi; \
	fi
	@echo "Done!"

clean:
	@rm -rf /usr/local/fop2
	@rm -rf /var/www/html/fop2
	@if [ -x /etc/rc.d/init.d/fop2 ]; then \
		rm -f /etc/rc.d/init.d/fop2; fi;
	@if [ -x /etc/default/fop2 ]; then \
		rm -f /etc/default/fop2; fi;
	@if [ -x /etc/sysconfig/fop2 ]; then \
		rm -f /etc/sysconfig/fop2; fi;
	@if [ -x /etc/init.d/fop2 ]; then \
		rm -f /etc/init.d/fop2; fi;

.PHONY: install

