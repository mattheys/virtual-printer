FROM debian:bookworm-slim

# Install CUPS, filters, ghostscript, the PDF driver, Avahi, and DBUS
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cups \
    cups-filters \
    ghostscript \
    printer-driver-cups-pdf \
    avahi-daemon \
    dbus \
    && rm -rf /var/lib/apt/lists/*

# Configure CUPS-PDF output path and permissions
RUN sed -i 's|#Out /var/spool/cups-pdf/${USER}|Out /output|' /etc/cups/cups-pdf.conf && \
    sed -i 's|#AnonDirName /var/spool/cups-pdf/ANONYMOUS|AnonDirName /output|' /etc/cups/cups-pdf.conf && \
    sed -i 's|#AnonUMask 0000|AnonUMask 0000|' /etc/cups/cups-pdf.conf && \
    sed -i 's|#UserUMask 0044|UserUMask 0000|' /etc/cups/cups-pdf.conf

# Create the output directory
RUN mkdir -p /output && chmod 777 /output

# Add the startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 631

CMD ["/start.sh"]
