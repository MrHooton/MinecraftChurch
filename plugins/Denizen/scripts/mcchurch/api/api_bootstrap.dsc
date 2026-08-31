mcchurch_api_bootstrap:
  type: world
  debug: false
  events:

    on server start:
    - webserver start port:8081
    - announce "<&7>[MCChurch] API webserver started on port 8081"
