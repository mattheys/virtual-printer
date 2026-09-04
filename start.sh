#!/bin/bash
set -e

# Fallback values
PRINTER_NAME=${PRINTER_NAME:-Virtual_PDF}
PRINTER_DESC=${PRINTER_DESC:-Paperless PDF Printer}
PRINTER_UUID=${PRINTER_UUID:-urn:uuid:11111111-2222-3333-4444-555555555555}
AVAHI_HOSTNAME=${AVAHI_HOSTNAME:-PaperlessPrinter}
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create a local user/group inside the container that matches the host PUID/PGID
if ! getent group printgroup >/dev/null; then
    groupadd -g "$PGID" printgroup
fi
if ! getent passwd printuser >/dev/null; then
    useradd -u "$PUID" -g "$PGID" -M -s /bin/false printuser
fi

# Tell cups-pdf to assign anonymous print jobs to this exact user
sed -i "s/^#\?AnonUser.*/AnonUser printuser/" /etc/cups/cups-pdf.conf

# Clean up stale PID files
rm -f /var/run/dbus/pid /var/run/avahi-daemon/pid /var/run/cups/cupsd.pid

# Update Avahi hostname
sed -i "s/^#\?host-name=.*/host-name=$AVAHI_HOSTNAME/" /etc/avahi/avahi-daemon.conf

# Start DBUS
mkdir -p /var/run/dbus
dbus-daemon --system --fork

# Start Avahi
avahi-daemon -D

# Start CUPS in the background temporarily for configuration
cupsd

# Wait for CUPS to initialize
while [ ! -e /var/run/cups/certs/0 ]; do 
    sleep 1
done
sleep 2

# Allow remote access and share printers automatically
cupsctl --remote-any --share-printers

# Create the PDF printer if it doesn't exist
if ! lpstat -p "$PRINTER_NAME" > /dev/null 2>&1; then
    echo "Creating $PRINTER_NAME Printer..."
    lpadmin -p "$PRINTER_NAME" -v "cups-pdf:/" -E -P /usr/share/ppd/cups-pdf/CUPS-PDF_opt.ppd -o printer-is-shared=true -o printer-uuid="$PRINTER_UUID" -D "$PRINTER_DESC"
    
    # Accept jobs and set as default
    cupsaccept "$PRINTER_NAME"
    cupsenable "$PRINTER_NAME"
    lpadmin -d "$PRINTER_NAME"
fi

# Kill the background CUPS process
kill $(cat /var/run/cups/cupsd.pid)
sleep 1

# Start CUPS in the foreground
echo "Starting CUPS..."
exec /usr/sbin/cupsd -f
