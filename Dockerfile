FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive 

RUN apt-get update
RUN apt-get install -y python3.9 python3.9-dev python3-pip
RUN apt-get install -y git
RUN apt-get install wget

WORKDIR /pilot-tester

COPY . .

RUN chmod +x start-pilot.sh
RUN ln -s /usr/bin/python3.9 /usr/bin/python

CMD ["bash", "./start-pilot.sh"]