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
        interface Dispatcher;

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
        STATUS_INIT = 0,
        STATUS_ACTIVATING,
        STATUS_SHUTDOWN,
        STATUS_IDLE,
        STATUS_UART_ONLY,   
        STATUS_UART_SHARE,
        STATUS_UART_FINISH,
        STATUS_INCONSISTENT
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
    static bool req_ack;

    command error_t RadioControl.start()
    {
        error_t e;

        atomic {
            switch (status) {
                case STATUS_INIT:
                    status = STATUS_ACTIVATING;
                    break;
                case STATUS_ACTIVATING:
                    return EBUSY;
                default:
                    return EALREADY;
            }
        }
        e = call SubSplitControl.start();        
        if (e != SUCCESS) {
            atomic status = STATUS_INIT;
        }
        return e;
    }

    command error_t RadioControl.stop()
    {
        error_t e;

        atomic {
            switch (status) {
                case STATUS_IDLE:
                    status = STATUS_SHUTDOWN;
                    break;
                case STATUS_INIT:
                    return EALREADY;
                case STATUS_SHUTDOWN:
                    return EBUSY;
                default:
                    return FAIL;
            }
        }
        e = call SubSplitControl.stop();
        if (e == EALREADY)
            atomic status = STATUS_INIT;
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
        disp_status_t s;

        if (error == SUCCESS) {
            atomic {
                s = status;
                switch (status) {
                    case STATUS_ACTIVATING:
                    case STATUS_UART_FINISH:
                        status = STATUS_IDLE;
                        break;
                    default:
                        s = status = STATUS_INCONSISTENT;
                }
            }
            if (s == STATUS_INCONSISTENT)
                signal Dispatcher.inconsistent(s);
        }
        signal RadioControl.startDone(error);
    }

    event void SubSplitControl.stopDone(error_t error)
    {
        error_t e;
        disp_status_t s;

        atomic {
            s = status;
            status = STATUS_INCONSISTENT;
        }

        switch (s) {
            case STATUS_SHUTDOWN:
                if (error == SUCCESS) {
                    atomic status = STATUS_INIT;
                } else {
                    atomic status = STATUS_IDLE;
                }
                signal RadioControl.stopDone(error);
                break;
            case STATUS_UART_SHARE:
                if (error == SUCCESS) {
                    e = call NxtTransmitter.send(buffer, BUFLEN, req_ack);
                    if (e != SUCCESS) {
                        atomic status = STATUS_UART_FINISH;
                        signal NxtTransmitter.done(e, NULL, 0);
                        call SubSplitControl.start();
                    }
                } else {
                    atomic status = STATUS_IDLE;
                    signal NxtTransmitter.done(FAIL, NULL, 0);
                }
                break;
            default:
                atomic status = STATUS_INCONSISTENT;
                signal Dispatcher.inconsistent(s);
        }
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
        call Forge.halt(buffer, BUFLEN);
        return SUCCESS;
    }

    command error_t NxtComm.rotateTime(int8_t speed, uint32_t time,
                                       bool brake, uint8_t motors)
    {
        call Forge.rotateTime(buffer, BUFLEN, speed, time, brake, motors);
    }

    command error_t NxtComm.rotateAngle(int8_t speed, uint32_t angle,
                                        bool brake, uint8_t motors)
    {
        return FAIL;
    }

    command error_t NxtComm.stopRotation(bool brake, uint8_t motors)
    {
        return FAIL;
    }

    command error_t NxtComm.move(int8_t speed)
    {
        return FAIL;
    }

    command error_t NxtComm.turn(int8_t speed, uint32_t degrees)
    {
        return FAIL;
    }

    command error_t NxtComm.stop(bool brake)
    {
        return FAIL;
    }

    event void NxtTransmitter.done(error_t err, uint8_t *buf,
                                   size_t len)
    {
        disp_status_t s;

        atomic {
            s = status;
            status = STATUS_UART_FINISH;
        }
        signal NxtTransmitter.done(err, buf, len);
        switch (s) {
            case STATUS_UART_ONLY:
                atomic status = STATUS_INIT;
                break;
            case STATUS_UART_SHARE:
                call SubSplitControl.start();
                break;
            default:
                signal Dispatcher.inconsistent(s);
        }
    }

    command void Dispatcher.reset(void)
    {
        atomic status = STATUS_INIT;
    }

}

