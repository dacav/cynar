COMPONENT=RobotAppC
include $(MAKERULES)
CFLAGS += -I../lib/dispatcher -L../lib/dispatcher -DPACKET_LINK
