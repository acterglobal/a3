FROM ghcr.io/element-hq/synapse:latest
RUN apt-get update && apt-get install git -y
RUN pip install git+https://github.com/acterglobal/synapse-super-invites/@ben-share-link-generator
ADD ci-start.sh /ci-start.sh
RUN chmod 770 /ci-start.sh
ENTRYPOINT /ci-start.sh