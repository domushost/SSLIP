#!/bin/bash

# Check record existence
check_record_for_ips() {
    local record="$1"
    local file="$2"

    grep -q "<name>$record</name>" "$file"
}

check_record_for_acct() {
    local record="$1"
    local file="$2"

    grep -q "<vhRoot>/home/$record/crt/</vhRoot>" "$file"
}

# Insert the dedicated IP
while true; do
    read -p "Dedicated IP Address: " ips_input
    if [ -z "$ips_input" ]; then
        echo "IP must be filled out!"
    else
        if check_record_for_ips "$ips_input" "/usr/local/lsws/conf/httpd_config.xml"; then
            echo "Warning: IP '$ips_input' already exist!"
            exit 1
        else
            break
        fi
    fi
done

# Insert the account name
while true; do
    read -p "Account name: " acct_input
	if [ -z "$acct_input" ]; then
        echo "Account name must be filled out!"
	else
    	if [[ $acct_input == *"."* ]]; then
    		echo "Account name must not contain any special chars '.'!"
    		exit 1
	    else
	        if check_record_for_acct "$acct_input" "/usr/local/lsws/conf/httpd_config.xml"; then
            	echo "Warning: Account '$acct_input' already exist!"
            	exit 1
			else
    	    	break
    	  	fi  	
    	fi
    fi
done

# Using awk to append
awk -v ips="$ips_input" -v acct="$acct_input" '
    /<\/virtualHostList>/ {
        print "    <virtualHost>"
        print "      <name>" ips "</name>"
        print "      <vhRoot>/home/" acct "/crt/</vhRoot>"
        print "      <configFile>/home/" acct "/crt/ip.conf</configFile>"
        print "      <allowSymbolLink>1</allowSymbolLink>"
        print "      <enableScript>1</enableScript>"
        print "      <restrained>1</restrained>"
        print "      <setUIDMode>0</setUIDMode>"
        print "      <chrootMode>0</chrootMode>"
        print "    </virtualHost>"
    }
    {print}
' /usr/local/lsws/conf/httpd_config.xml > tmpfile && mv tmpfile /usr/local/lsws/conf/httpd_config.xml

awk -v ips="$ips_input" -v acct="$acct_input" '
    /<\/listenerList>/ {
        print "    <listener>"
        print "      <name>" ips "</name>"
        print "      <address>" ips ":443</address>"
        print "      <secure>1</secure>"
        print "      <keyFile>/home/" acct "/crt/private.key</keyFile>"
        print "      <certFile>/home/" acct "/crt/certificate.crt</certFile>"
        print "      <CACertPath>/home/" acct "/crt/</CACertPath>"
        print "      <CACertFile>/home/" acct "/crt/ca_bundle.crt</CACertFile>"
        print "      <sslProtocol>12</sslProtocol>"
        print "    </listener>"
    }
    {print}
' /usr/local/lsws/conf/httpd_config.xml > tmpfile && mv tmpfile /usr/local/lsws/conf/httpd_config.xml

echo "Configuration has been updated with IP: $ips_input and account name: $acct_input"

# Restart LiteSpeed
/usr/local/lsws/bin/lswsctrl restart
echo "LiteSpeed succesfully restarted!"
