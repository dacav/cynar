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

configuration ServerAppC {
}
implementation {

    components MainC,
               DispatcherC,
               ServerP,
               MoteCommandsParserP,
               MoteCommandsForgeP,
               CC2420PacketC,
               LedsC,
               new TimerMilliC() as PingTimer;

    ServerP.Boot -> MainC.Boot;

    ServerP.RadioReceive -> DispatcherC.RadioReceive;
    ServerP.RadioControl -> DispatcherC.RadioControl;
    ServerP.RadioAMSend -> DispatcherC.RadioAMSend;
    ServerP.RadioPacket -> DispatcherC.RadioPacket;
    ServerP.RadioAMPacket -> DispatcherC.RadioAMPacket;
    ServerP.Dispatcher -> DispatcherC.Dispatcher;

    ServerP.CC2420Packet -> CC2420PacketC.CC2420Packet;

    ServerP.Leds -> LedsC;

    MoteCommandsParserP.NxtCommands -> DispatcherC.NxtCommands;
    ServerP.Interpreter -> MoteCommandsParserP.MoteCommandsInterpreter;
    ServerP.NxtCommands -> DispatcherC.NxtCommands;
    ServerP.Forge -> MoteCommandsForgeP.MoteCommandsForge;

    ServerP.PingTimer -> PingTimer.Timer;
}

