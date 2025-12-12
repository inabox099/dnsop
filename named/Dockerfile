# Use Arch Linux as the base image
FROM archlinux:latest

# Install necessary tools for building AUR packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git sudo && \
    useradd -m builduser && \
    echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to a non-root user for building AUR packages
USER builduser
WORKDIR /home/builduser

# Clone and build bind-git from AUR
RUN git clone https://aur.archlinux.org/bind-git.git && \
    cd bind-git && \
    makepkg -si --noconfirm

# Clean up
USER root
RUN rm -rf /home/builduser/bind-git && \
    pacman -Rns --noconfirm base-devel git sudo && \
    pacman -Scc --noconfirm

# Download the root hints file and save it to /var/named/root.hint
RUN curl -o /var/named/root.hint https://www.internic.net/domain/named.root
RUN chown named:named /var/named/root.hint


RUN pacman -S --noconfirm vector && pacman -Scc --noconfirm
COPY vector.yaml /etc/vector/vector.yaml

WORKDIR /root

COPY bin/entrypoint.sh ./bin/entrypoint.sh
RUN chmod +x ./bin/entrypoint.sh

# VOLUME ["/etc/named", "/var/named"]

# Default command to run named
CMD ["bin/entrypoint.sh"]
