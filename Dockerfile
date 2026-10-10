FROM ghcr.io/sdr-enthusiasts/docker-adsb-ultrafeeder:latest

COPY rootfs/ /
RUN chmod +x /etc/s6-overlay/startup.d/00-ha-options
