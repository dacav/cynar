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

module RobotP {

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

        interface Leds;

    }

}

implementation {

    static uint8_t phase;

    event void Boot.booted()
    {
        call Leds.led1On();
        call RadioControl.start();
    }

    event void NxtCommands.done(error_t err, uint8_t *buffer, size_t len)
    {
        if (err != SUCCESS) {
            call Leds.led0On();
        } else {
            call Leds.led2Toggle();
        }
    }

    event message_t * RadioReceive.receive(message_t *msg, void *payload,
                                           uint8_t len)
    {
        call Leds.led2Toggle();
        if (call NxtCommands.exec((uint8_t *)payload, len) != SUCCESS) {
            call Leds.led0On();
        }
        return msg;
    }

    event void Dispatcher.inconsistent(disp_status_t x)
    {
        call Leds.led0On();
    }

    event void RadioControl.startDone(error_t e)
    {
        call Leds.led1Off();
    }

    event void RadioControl.stopDone(error_t e)
    {

    }

    event void RadioAMSend.sendDone(message_t * msg, error_t e)
    {

    }
}


