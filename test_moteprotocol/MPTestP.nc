/*
 * Copyright 2008 2009
 *           Giovanni Simoni
 *           Paolo Pivato
 *
 * This file is part of MPTestP.
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
 * along with MPTestP.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include "moteprotocol.h"

module MPTestP {

    uses {

        interface Boot;

        interface SplitControl as USBControl;
        interface AMSend as USBSend[am_id_t id];
        interface Packet as USBPacket;
        interface AMPacket as USBAMPacket;

        interface MoteCommandsForge;
        interface Timer<TMilli> as Timer0;
        interface Leds;
 
    }

}

implementation {

    static message_t message, *msg_ptr;
    static am_id_t myid;
    static am_addr_t myaddr;

    event void Boot.booted() {
        msg_ptr = &message;

        call USBPacket.clear(msg_ptr);
        myaddr = call USBAMPacket.address();
        myid = call USBAMPacket.type(msg_ptr);
        call USBAMPacket.setSource(msg_ptr, myaddr);
        call USBControl.start();
    }

    event void USBControl.startDone(error_t error) {
        if (error == SUCCESS) {
            call Timer0.startOneShot(3000);
        } else {
            call Leds.led0Toggle();
        }
    }

    event void Timer0.fired()
    {
        uint8_t *payload;

        payload = call USBPacket.getPayload(msg_ptr, sizeof(mote_protocol_t));
        call MoteCommandsForge.baseRotateAngle((mote_protocol_t *)payload,
                                               100, 180, TRUE, 1 | 4);
        call USBSend.send[myid](myaddr, msg_ptr, sizeof(mote_protocol_t));
    }

    event void USBControl.stopDone(error_t error) {}

    event void USBSend.sendDone[am_id_t id](message_t* msg, error_t error) {
        if (error == SUCCESS) {
            call Leds.led1Toggle();
        } else {
        }
    }

}

