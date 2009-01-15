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

        /* Radio communication */
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend;
        interface Packet as RadioPacket;

        /* Commands forge */
        interface NxtCommandsForge;

        interface Leds;
        interface Timer<TMilli> as Timer0;

    }

}

#define ROBOT_BUFLEN 6

implementation {

    static message_t msg;
    static message_t *msg_ptr;
    static uint8_t *buffer;
    static uint8_t phase;

    event void Boot.booted()
    {
        call Leds.led1On();
        msg_ptr = &msg;
        call RadioPacket.clear(msg_ptr);
        buffer = call RadioPacket.getPayload(msg_ptr, ROBOT_BUFLEN);
        phase = 0;
        call RadioControl.start();
    }

    event void Timer0.fired()
    {
        phase++;
        call Leds.led0Toggle();
        switch (phase & 1) {
        case 0:
            call NxtCommandsForge.rotateTime(buffer, ROBOT_BUFLEN, 85, 750,
                                             TRUE, 0x1 | 0x4);
            break;
        case 1:
            call NxtCommandsForge.turn(buffer, ROBOT_BUFLEN, 85, 90);
            break;
        }
        call RadioAMSend.send(TOS_BCAST_ADDR, msg_ptr, ROBOT_BUFLEN);
    }

    event void RadioControl.startDone(error_t e)
    {
        call Leds.led1Off();
        call Timer0.startPeriodic(2000);
    }

    event void RadioControl.stopDone(error_t e)
    {

    }

    event void RadioAMSend.sendDone(message_t * m, error_t e)
    {

    }
}


