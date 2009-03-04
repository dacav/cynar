COMPONENT=RobotAppC
include $(MAKERULES)
CFLAGS += -I../lib/dispatcher -L../lib/dispatcher -I../lib/nxtprotocol -L../lib/nxtprotocol -DPACKET_LINK -DCYNAR_UNIQUE="\"Cynar\""
