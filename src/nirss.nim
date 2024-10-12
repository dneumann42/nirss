import nirss/config
import nirss/api
export config, api

when isMainModule:
  import app/app
  run()
