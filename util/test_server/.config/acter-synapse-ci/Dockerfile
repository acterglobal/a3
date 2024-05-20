FROM ghcr.io/matrix-org/synapse:latest
RUN pip install synapse_super_invites==0.8.2
ADD ci-start.sh /ci-start.sh
RUN chmod 770 /ci-start.sh
ENTRYPOINT /ci-start.sh