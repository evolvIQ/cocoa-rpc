import xmlrpclib, sys

uri = "http://localhost:8080"
if len(sys.argv) > 1:
  uri = sys.argv[1]

proxy = xmlrpclib.ServerProxy(uri)

print proxy.Echo.echo("Hello, world!")
