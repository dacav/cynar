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

module RemoteP {

    uses {

        interface Boot;
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend[uint8_t id];
        interface Packet as RadioPacket;
        interface MoteCommandsForge as Forge;
        interface Leds;

    }

}

implementation {

    static const int8_t myid = unique(CYNAR_UNIQUE);

    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    event void Boot.booted()
    {
        if (call RadioControl.start() != SUCCESS)
            call Leds.led0Toggle();
    }

    event void RadioAMSend.sendDone[uint8_t id](message_t *msg, error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        }
    }

    event void RadioControl.startDone(error_t e)
    {
        message_t msg;

        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
        call Forge.sync(prepare_packet(&msg));
        e = call RadioAMSend.send[myid](TOS_BCAST_ADDR, &msg,
                        sizeof(mote_protocol_t));
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        }
    }

    event void RadioControl.stopDone(error_t e) {} 

}

