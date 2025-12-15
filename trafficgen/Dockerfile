# Use Arch Linux as the base image
FROM archlinux:latest

RUN pacman -Syy && pacman -S drill bind --noconfirm && pacman -Scc --noconfirm

USER root
WORKDIR /root
COPY fqdn.txt /root/fqdn.txt
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

CMD ["./entrypoint.sh"]