FROM phusion/baseimage:master
MAINTAINER kaim

RUN apt-get update && \
    apt-get install -y wget cabextract hashdeep xmlstarlet trash-cli unzip iputils-ping genisoimage aria2 rsync jq curl  && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV SYSTEMS="w100-x64"
ENV OFFICE="o2k16-x64"
ENV LANGUAGE="enu"
ENV PARAMS="-includesp -includecpp -includedotnet -includemsse"
ENV ISO="no"
ENV SLEEP=48h
ENV DOWNLOADERS="aria2c wget"

# Define the GitHub repository URL
ARG REPO_URL=https://raw.githubusercontent.com/hellkaim/docker-wsusoffline/master

# WSUSOFFLINE
# Download scripts from GitHub
ADD ${REPO_URL}/update.sh /wsus/update.sh
ADD ${REPO_URL}/run.sh /wsus/run.sh
ADD ${REPO_URL}/preferences.bash /wsus/preferences.bash
ADD ${REPO_URL}/download.sh /wsus/download.sh
RUN ln -s /wsus/run.sh /etc/my_init.d/run.sh
RUN chmod +x /wsus/*.sh
RUN ln -s /wsus/wsusoffline/client /client

VOLUME ["/client"]
CMD ["/sbin/my_init"]
