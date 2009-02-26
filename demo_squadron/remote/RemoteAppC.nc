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

configuration RemoteAppC {
}
implementation {

    components MainC,
               ActiveMessageC,
               RemoteP,
               MoteCommandsForgeP,
               UserButtonC,
               new TimerMilliC() as Ping,
               LedsC;

    RemoteP.Boot -> MainC.Boot;
    RemoteP.RadioControl -> ActiveMessageC.SplitControl;
    RemoteP.RadioPacket -> ActiveMessageC.Packet;
    RemoteP.RadioAMSend -> ActiveMessageC.AMSend;
    RemoteP.Leds -> LedsC;
    RemoteP.Forge -> MoteCommandsForgeP.MoteCommandsForge;
    RemoteP.Notify -> UserButtonC.Notify;
    RemoteP.Ping -> Ping;

}

