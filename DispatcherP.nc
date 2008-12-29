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

        interface NxtCommands as SubNxtComm;
        interface NxtTransmitter;

        interface SplitControl as SubSplitControl;
        interface AMSend as SubAMSend;
        interface Receive as SubReceive;

    }

}

implementation {

    typedef enum {
        STATUS_INIT = 0,
        STATUS_RADIO,
        STATUS_SHUTDOWN
    } disp_status_t;

    static disp_status_t status;

    command error_t RadioControl.start()
    {
        atomic {
            if (status != STATUS_INIT && status != STATUS_RADIO) {
                return EBUSY;
            }
        }
        return call SubSplitControl.start();
    }

    command error_t RadioControl.stop()
    {
        error_t e;

        atomic {
            if (status == STATUS_INIT)
                return EALREADY;
            if (status != STATUS_RADIO)
                return EBUSY;
        }
        e = call SubSplitControl.stop();
        if (e == SUCCESS) {
            atomic status = STATUS_SHUTDOWN;
        }
        return e;
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
        if (error == SUCCESS) {
            atomic {
                status = STATUS_RADIO;
            }
        }
        signal RadioControl.startDone(error);
    }

    event void SubSplitControl.stopDone(error_t error)
    {
        disp_status_t s;

        atomic s = status;
        if (s == STATUS_RADIO) {
            /* Shutdding down */
            if (error == SUCCESS) {
                atomic status = STATUS_INIT;
            }
            signal RadioControl.stopDone(error);
        }
    }

    event message_t *SubReceive.receive(message_t *msg, void *payload,
                                        uint8_t len)
    {
        return msg;
    }

    command uint8_t RadioAMSend.maxPayloadLength()
    {
    }

    command void *RadioAMSend.getPayload(message_t* msg, uint8_t len)
    {
    }

    command error_t NxtComm.halt(uint8_t *buffer, size_t len)
    {
        return FAIL;
    }

    command error_t NxtComm.rotateTime(uint8_t *buffer, size_t len, int8_t speed,
                                       uint32_t time, bool brake, uint8_t motors)
    {
        return FAIL;
    }

    command error_t NxtComm.rotateAngle(uint8_t *buffer, size_t len, int8_t speed,
                                        uint32_t angle, bool brake, uint8_t motors)
    {
        return FAIL;
    }

    command error_t NxtComm.stopRotation(uint8_t *buffer, size_t len, bool brake,
                                         uint8_t motors)
    {
        return FAIL;
    }

    command error_t NxtComm.move(uint8_t *buffer, size_t len, int8_t speed)
    {
        return FAIL;
    }

    command error_t NxtComm.turn(uint8_t *buffer, size_t len, int8_t speed,
                                 uint32_t degrees)
    {
        return FAIL;
    }

    command error_t NxtComm.stop(uint8_t *buffer, size_t len, bool brake)
    {
        return FAIL;
    }

    event void NxtTransmitter.done(uint8_t *buffer, size_t len, error_t err)
    {
    }

}

