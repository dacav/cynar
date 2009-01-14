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

        interface Dispatcher;
    }

}
implementation {

    components DispatcherP;
    components NxtCommandsForgeP;
    components NxtTransmitterP;
    components new Msp430Uart0C() as Uart0Access;
    components ActiveMessageC;
    components new AMSenderC(AM_CYNAR);
    components new AMReceiverC(AM_CYNAR);
    components BuffersP;

    /* Forwarded from DispatcherP */
    NxtCommands = DispatcherP;
    RadioControl = DispatcherP; 
    RadioAMSend = DispatcherP;
    RadioReceive = DispatcherP;
    Dispatcher = DispatcherP;

    /* Required by DispatcherP */
    DispatcherP.SubAMSend -> AMSenderC;
    DispatcherP.SubReceive -> AMReceiverC;
    DispatcherP.SubSplitControl -> ActiveMessageC;
    DispatcherP.NxtTransmitter -> NxtTransmitterP;
    DispatcherP.Forge -> NxtCommandsForgeP;

    Uart0Access.Msp430UartConfigure -> DispatcherP.Msp430UartConfigure;
    NxtTransmitterP.Resource -> Uart0Access.Resource;
    NxtTransmitterP.UartStream -> Uart0Access.UartStream;
    NxtCommandsForgeP.Buffers -> BuffersP.Buffers;

    /* Active message forwarded */
    RadioAMPacket = ActiveMessageC;
    RadioPacket = ActiveMessageC;
}

