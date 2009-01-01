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

        interface NxtCommandsForge as Forge;
        interface NxtTransmitter;

        interface SplitControl as SubSplitControl;
        interface AMSend as SubAMSend;
        interface Receive as SubReceive;

    }

}

implementation {

    typedef enum {
        STATUS_INIT = 0,    /* Initial state */
        STATUS_BUSY,        /* Required operation in progress */
        STATUS_IDLE,        /* Radio active, idle */
        STATUS_RADIO_TX,    /* Radio transmitting */
        STATUS_UART_TX,     /* Uart transmitting */
        STATUS_UART_RX,     /* Uart receiving */
    } disp_status_t;

    static disp_status_t status = 0;

    /* TODO:
     *
     *  The current implementation of this module doesn't allow the use of
     *  different length buffer.
     *
     *  A future version may provide a counter for the message length on the
     *  rs485 channel. 
     *
     */
    #define BUFLEN 6
    static uint8_t buffer[BUFLEN];

    command error_t RadioControl.start()
    {
        
    }

    command error_t RadioControl.stop()
    {
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

    event void SubSplitControl.startDone(error_t error)
    {
    }

    event void SubSplitControl.stopDone(error_t error)
    {
    }

    event message_t *SubReceive.receive(message_t *msg, void *payload,
                                        uint8_t len)
    {
        return signal RadioReceive.receive(msg, payload, len);
    }

    command uint8_t RadioAMSend.maxPayloadLength()
    {
        return call SubAMSend.maxPayloadLength();
    }

    command void *RadioAMSend.getPayload(message_t* msg, uint8_t len)
    {
        return call SubAMSend.getPayload(msg, len);
    }

    command error_t NxtComm.halt()
    {
//() != SUCCESS)
            return FAIL;
        call Forge.halt(buffer, BUFLEN);
    }

    command error_t NxtComm.rotateTime(int8_t speed, uint32_t time, bool brake,
                                       uint8_t motors)
    {
//() != SUCCESS)
            return FAIL;
        call Forge.rotateTime(buffer, BUFLEN, speed, time, brake, motors);
    }

    command error_t NxtComm.rotateAngle(int8_t speed, uint32_t angle, bool brake,
                                        uint8_t motors)
    {
//() != SUCCESS)
            return FAIL;
        return FAIL;
    }

    command error_t NxtComm.stopRotation(bool brake,
                                         uint8_t motors)
    {
//() != SUCCESS)
            return FAIL;
        return FAIL;
    }

    command error_t NxtComm.move(int8_t speed)
    {
//() != SUCCESS)
            return FAIL;
        return FAIL;
    }

    command error_t NxtComm.turn(int8_t speed, uint32_t degrees)
    {
//() != SUCCESS)
            return FAIL;
        return FAIL;
    }

    command error_t NxtComm.stop(bool brake)
    {
//() != SUCCESS)
            return FAIL;
        return FAIL;
    }

    event void NxtTransmitter.done(uint8_t *buf, size_t len, error_t err)
    {
    }

}

