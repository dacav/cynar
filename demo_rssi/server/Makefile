COMPONENT=ServerAppC
include $(MAKERULES)
CFLAGS += -I../../lib/dispatcher -L../../lib/dispatcher \
          -I../../lib/nxtprotocol -L../../lib/nxtprotocol \
          -I../../lib/moteprotocol -L../../lib/moteprotocol \
          -DPACKET_LINK -DCYNAR_UNIQUE="\"Cynar\"" \
          -DNCLIENTS=1 -DRSSI_TARGET=30
