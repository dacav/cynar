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

    }

}

implementation {

    event void Boot.booted()
    {
        call NxtCommands.halt();
    }

    event void NxtCommands.done(error_t err, uint8_t *buffer, size_t len)
    {

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


