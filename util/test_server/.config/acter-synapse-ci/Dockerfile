FROM ghcr.io/matrix-org/synapse:latest
RUN pip install synapse_super_invites
ADD ci-start.sh /ci-start.sh
RUN chmod 770 /ci-start.sh
ENTRYPOINT /ci-start.sh