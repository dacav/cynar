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

module MPTestP {

    uses {

        interface Boot;

        interface SplitControl as USBControl;
        interface AMSend as USBSend[am_id_t id];
        interface Packet as USBPacket;
        interface AMPacket as USBAMPacket;

        interface MoteCommandsForge;
 
    }

}

#include "moteprotocol.h"

implementation {

    static uint8_t phase;
    static am_id_t myid;
    static am_addr_t myaddr;
    static message_t message;
    static message_t * msg_ptr;

    event void Boot.booted()
    {
        phase = 0;
        myid = call USBAMPacket.type(msg_ptr);
        myaddr = call USBAMPacket.address();
        call USBAMPacket.setSource(msg_ptr, myaddr);
        call USBControl.start();
    }

    task void send_next(void)
    {
        mote_protocol_t *msg;

        msg = (mote_protocol_t *)
              call USBPacket.getPayload(msg_ptr, sizeof(mote_protocol_t));

        switch (phase) {
            case 0:
                call MoteCommandsForge.baseMove(msg, 100);
                break;
            case 1:
                call MoteCommandsForge.baseRotateAngle(msg, 100, 180,
                                                       TRUE, 1 | 4);
                break;
            case 2:
                call MoteCommandsForge.reachThreshold(msg, 64);
                break;
            default:
                return;
        }
        phase++;
        call USBSend.send[myid](myaddr, msg_ptr, SIZE);
    }

    event void USBControl.startDone() 
    {
        post send_next();
    }
        
    event void USBSend.sendDone[am_id_t id](message_t* msg, error_t error)
    {
        post send_next();
    }

}

