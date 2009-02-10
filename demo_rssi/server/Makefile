COMPONENT=ServerAppC
include $(MAKERULES)
CFLAGS += -I../../lib/dispatcher -L../../lib/dispatcher \
          -I../../lib/nxtprotocol -L../../lib/nxtprotocol \
          -I../../lib/moteprotocol -L../../lib/moteprotocol \
          -DCC2420_DEF_RFPOWER=23 \
          -DCYNAR_UNIQUE="\"Cynar\"" \
          -DRSSI_TARGET=-30 \
          -DPINGTIME=350 \
          -DNCLIENTS=2
#          -DPACKET_LINK \
