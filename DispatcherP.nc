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

module DispatcherP {

    provides {

        interface NxtCommands as NxtComm;

        /* Radio communication */
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend;
        interface Receive as RadioReceive;

    }

    uses {

        /* Interfaces required for the radio-channel communication: they
         * will manage Uart0 and CC2420 interleavings if required, and
         * simply forwarded when possible (by keeping a single point of
         * wiring the code will be a little more clean).
         */
        interface Boot;

        interface NxtCommands as SubNxtComm;

        interface SplitControl as SubSplitControl;
        interface AMSend as SubAMSend;
        interface Receive as SubReceive;

    }

}

implementation {

    event void Boot.booted() {
        
    }

    command error_t RadioAMSend.send(am_addr_t addr, message_t* msg,
                                     uint8_t len)
    {
    }

    command error_t RadioAMSend.cancel(message_t* msg)
    {
    }

    event void SubAMSend.sendDone(message_t *msg, error_t error)
    {
    }

    event void SubSplitControl.startDone(error_t e)
    {
    }

    event void SubSplitControl.stopDone(error_t e)
    {
    }

    event message_t * SubReceive.receive(message_t *msg, void *payload,
                                         uint8_t len)
    {
        return msg;
    }

    event void SubNxtComm.done(error_t e)
    {
    }

    command uint8_t RadioAMSend.maxPayloadLength()
    {
        return call SubAMSend.maxPayloadLength();
    }

    command void* RadioAMSend.getPayload(message_t* msg, uint8_t len)
    {
        return call SubAMSend.getPayload(msg,len);
    }

    command error_t RadioControl.start()
    {

    }

    command error_t RadioControl.stop()
    {

    }

    command error_t NxtComm.halt()
    {
        call SubNxtComm.halt();
        return SUCCESS;
    }

    command error_t NxtComm.rotateTime(int8_t speed, uint32_t time,
                                       bool brake, uint8_t motors)
    {
        call SubNxtComm.rotateTime(speed, time, brake, motors);
        return SUCCESS;
    }

    command error_t NxtComm.rotateAngle(int8_t speed, uint32_t angle,
                                        bool brake, uint8_t motors)
    {
        call SubNxtComm.rotateAngle(speed, angle, brake, motors);
        return SUCCESS;
    }

    command error_t NxtComm.stopRotation(bool brake, uint8_t motors)
    {
        call SubNxtComm.stopRotation(brake, motors);
        return SUCCESS;
    }

    command error_t NxtComm.move(int8_t speed)
    {
        call SubNxtComm.move(speed);
        return SUCCESS;
    }

    command error_t NxtComm.turn(int8_t speed, uint32_t degrees)
    {
        call SubNxtComm.turn(speed, degrees);
        return SUCCESS;
    }

    command error_t NxtComm.stop(bool brake)
    {
        call SubNxtComm.stop(brake);
        return SUCCESS;
    }

}

