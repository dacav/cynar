COMPONENT=ServerAppC
include $(MAKERULES)
CFLAGS += -I../../lib/dispatcher -L../../lib/dispatcher \
          -I../../lib/nxtprotocol -L../../lib/nxtprotocol \
          -I../../lib/moteprotocol -L../../lib/moteprotocol \
          -DCC2420_DEF_RFPOWER=23 \
          -DCYNAR_UNIQUE="\"Cynar\"" \
          -DROBOT_SPEED=80 \
          -DRSSI_TARGET=-10 \
          -DRSSI_WINDOW=10 \
          -DPINGTIME=350 \
          -DNCLIENTS=4
#          -DPACKET_LINK \
