import SimpleXMLRPCServer, sys

port = 8080
if len(sys.argv) > 1:
  port = int(sys.argv[1])

serv = SimpleXMLRPCServer.SimpleXMLRPCServer(("0.0.0.0",port))
serv.register_function(lambda x:x, "Echo.echo")
serv.serve_forever()
