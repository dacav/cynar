COMPONENT=ClientAppC
include $(MAKERULES)
CFLAGS += -I../../lib/dispatcher -L../../lib/dispatcher \
          -I../../lib/nxtprotocol -L../../lib/nxtprotocol \
          -I../../lib/moteprotocol -L../../lib/moteprotocol \
          -DCC2420_DEF_RFPOWER=11 \
          -DCYNAR_UNIQUE="\"Cynar\"" \
          -DROBOT_SPEED=80 \
          -DRESEND_PERIOD=350 \
		  -DNRESEND=1 \
          -DSECURITY_TIMEOUT=700
#          -DPACKET_LINK \
