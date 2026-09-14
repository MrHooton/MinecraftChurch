# ntfy_notifications.dsc
# Sends server lifecycle and player join/leave notifications through ntfy.
# The complete ntfy topic URL is stored only in Denizen secrets.secret as ntfy_url.

ntfy_send:
  type: task
  debug: false
  definitions: message
  script:
    - ~webget <secret[ntfy_url]> data:<[message]> method:POST hide_failure save:ntfy_request
    - if <entry[ntfy_request].failed>:
      - announce "<&c>[NTFY] Notification failed. HTTP status: <entry[ntfy_request].status.if_null[no_response]>" to_console

ntfy_notifications:
  type: world
  debug: false
  events:
    on server start:
      - define notification_message "Minecraft Church server is online."
      - ~run ntfy_send def:<[notification_message]>

    on player joins:
      - define notification_message "<player.name> joined the Minecraft Church server."
      - ~run ntfy_send def:<[notification_message]>

    on player quits:
      - define notification_message "<player.name> left the Minecraft Church server."
      - ~run ntfy_send def:<[notification_message]>

    on shutdown:
      - define notification_message "Minecraft Church server is shutting down."
      - ~run ntfy_send def:<[notification_message]>
