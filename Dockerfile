FROM cgr.dev/chainguard/node:18

ADD entrypoint.sh /entrypoint.sh
ADD action.yml /action.yml

ENTRYPOINT ["/entrypoint.sh"]
