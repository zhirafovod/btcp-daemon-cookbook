from twisted.application import internet, service
from twisted.web.resource import Resource
from twisted.web.server import Site
from twisted.python import log
from twisted.python.logfile import DailyLogFile
import sys
import logging
import os

from btcp.tracker import *
from btcp.btcp import *
from btcp.flowcontrol import *

resource = Resource()
factory = Site(resource)

# some persistent data configuration
factory.torrents = {}  # torrent files on local torrent client
factory.interval = 10  # interval to check tracker updates for torrent client, is set by Tracker
factory.port = 9200
factory.log_dir = '/var/tmp/'
factory.conf_file = '/etc/btcp/btcp.conf'

# logging options
log.startLogging(DailyLogFile.fromFullPath(factory.log_dir + "btcp.log"))
logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)

# start btcp instance
btcp = BtCP(f=factory)
btcp.start()
factory.btcp = btcp

# Control Server
resource.putChild('form',FormHandler(f=factory))
resource.putChild('getallfiles',CommandHandler(f=factory, run='getAllFiles'))
resource.putChild('getalldata',CommandHandler(f=factory, run='getAllData'))
resource.putChild('savebtfile',CommandHandler(f=factory, run='saveBtFile'))
# Tracker Server
resource.putChild('ann',TrackerHandler(f=factory))
resource.putChild('announce',TrackerHandler(f=factory))

# debugging
logging.debug('resource: %s, %s' %(resource, resource.__dict__))
logging.debug('factory: %s, %s' %(factory, factory.__dict__))

# Twistd configuration:
btcpService = service.MultiService()
internet.TCPServer(factory.port, factory).setServiceParent(btcpService) # create a service for web, hook it up to btcpService Multiservice
#trackerService = internet.TCPServer(factory.port, factory) # create the service
application = service.Application("btcp.web")  # create the Application
# add the service to the application
btcpService.setServiceParent(application)
