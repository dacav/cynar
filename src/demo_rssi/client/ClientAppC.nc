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

configuration ClientAppC {
}
implementation {

    components MainC,
               DispatcherC,
               ClientP,
               MoteCommandsParserP,
               MoteCommandsForgeP,
               new SensirionSht11C() as Sensors,
//               new Msp430InternalTemperatureC(),
               CC2420PacketC,
               RandomC,
               new TimerMilliC() as Timeout,
               new TimerMilliC() as Resend,
               LedsC;

    ClientP.Boot -> MainC.Boot;

    ClientP.RadioReceive -> DispatcherC.RadioReceive;
    ClientP.RadioControl -> DispatcherC.RadioControl;
    ClientP.RadioAMSend -> DispatcherC.RadioAMSend;
    ClientP.RadioPacket -> DispatcherC.RadioPacket;
    ClientP.RadioAMPacket -> DispatcherC.RadioAMPacket;
    ClientP.Dispatcher -> DispatcherC.Dispatcher;

    ClientP.CC2420Packet -> CC2420PacketC.CC2420Packet;
    ClientP.Read -> Sensors.Temperature;

    ClientP.Leds -> LedsC;
    ClientP.Timeout -> Timeout;
    ClientP.Resend -> Resend;

    MoteCommandsParserP.NxtCommands -> DispatcherC.NxtCommands;
    ClientP.Interpreter -> MoteCommandsParserP.MoteCommandsInterpreter;
    ClientP.NxtCommands -> DispatcherC.NxtCommands;
    ClientP.Forge -> MoteCommandsForgeP.MoteCommandsForge;

}

