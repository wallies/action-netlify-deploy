FROM cgr.dev/chainguard/node:20-dev

ADD entrypoint.sh /entrypoint.sh
ADD action.yml /action.yml

ENTRYPOINT ["/entrypoint.sh"]
