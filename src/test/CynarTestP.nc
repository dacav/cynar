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

module CynarTestP {

    uses {

        interface Boot;

        /* Commands to the nxt */
        interface NxtCommands;

        /* Radio communication */
        interface Receive as RadioReceive;
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend;

        /* Error management for Nxt Dispatcher */
        interface Dispatcher;

        interface Timer<TMilli> as Timer0;
        interface Leds;

    }

}

implementation {

    static uint8_t phase;

    event void Boot.booted()
    {
        phase = 0;
        call Timer0.startOneShot(1000);
    }

    event void Timer0.fired(void)
    {
        error_t e;

        phase++;
        call Leds.set(phase);
        switch (phase) {
        case 1:
            e = call NxtCommands.move(100);
            break;
        case 2:
            e = call NxtCommands.turn(100, 180);
            break;
        case 3:
            e = call NxtCommands.move(-100);
            break;
        case 4:
            e = call NxtCommands.turn(-100, 180);
            break;
        }

    }

    event void NxtCommands.done(error_t err, uint8_t *buffer, size_t len)
    {
        uint32_t time;

        if (err == SUCCESS) {
            switch (phase) {
            case 1:
                time = 2000;
                break;
            case 2:
                time = 1000;
                break;
            case 3:
                time = 2000;
                break;
            default:
                phase = 0;
                time = 1000;
            }
            call Timer0.startOneShot(time);
        } else {
            call Leds.led2Toggle();
        }
    }

    event message_t * RadioReceive.receive(message_t *msg, void *payload,
                                           uint8_t len)
    {
        return msg;
    }

    event void Dispatcher.inconsistent(disp_status_t x)
    {

    }

    event void RadioControl.startDone(error_t e)
    {

    }

    event void RadioControl.stopDone(error_t e)
    {

    }

    event void RadioAMSend.sendDone(message_t *msg, error_t err)
    {

    }
}


