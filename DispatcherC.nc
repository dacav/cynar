/*
 * Copyright 2008 2009
 *           Giovanni Simoni
 *           Paolo Pivato
 *
 * This file is part of Cynar.
 *
 * Cynar is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Cynar is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cynar.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <stdio.h>

enum {
    AM_CYNAR = unique("Cynar")
};

configuration DispatcherC {

    provides {
        /* Nxt communication (through Uart0) */
        interface NxtCommands;

        /* Radio communication */
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend;
        interface Receive as RadioReceive;
        interface Packet as RadioPacket;
        interface AMPacket as RadioAMPacket;
    }
    uses {
        interface Boot;
    }
}
implementation {

    components DispatcherP as GlueDispatcher;
    components NxtCommandsP;
    components new Msp430Uart0C() as Uart0Access;
    components ActiveMessageC;
    components new AMSenderC(AM_CYNAR);
    components new AMReceiverC(AM_CYNAR);

    /* Forwarded from GlueDispatcher */
    NxtCommands = GlueDispatcher;
    RadioControl = GlueDispatcher; 
    RadioAMSend = GlueDispatcher;
    RadioReceive = GlueDispatcher;

    /* Forwarded to GlueDispatcher */
    Boot = GlueDispatcher;

    /* Required by GlueDispatcher */
    GlueDispatcher.SubAMSend -> AMSenderC;
    GlueDispatcher.SubReceive -> AMReceiverC;
    GlueDispatcher.SubNxtComm -> NxtCommandsP;

    NxtCommandsP.Resource -> Uart0Access.Resource;
    NxtCommandsP.UartStream -> Uart0Access.UartStream;

    /* Active message forwarded */
    RadioAMPacket = ActiveMessageC;
    RadioPacket = ActiveMessageC;
}

