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
        STATUS_ACTIVATING = 1,
        STATUS_SHUTDOWN = 2,
        STATUS_IDLE = 3,
        STATUS_RADIO_SEND = 4,
        STATUS_UART_ONLY = 5,
        STATUS_UART_SHARE = 6,
        STATUS_UART_FINISH = 7,
        STATUS_INCONSISTENT = 8,
    } disp_status_t;

    static disp_status_t status = STATUS_INIT;

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
        error_t e;

        atomic {
            switch (status) {
                case STATUS_INIT:
                    return FAIL;
                case STATUS_IDLE:
                    status = STATUS_RADIO_SEND;
                    break;
                default:
                    return EBUSY;
            }
        }
        e = call SubAMSend.send(addr, msg, len);
        if (e != SUCCESS)
            atomic status = STATUS_IDLE;
        return e;
    }

    command error_t RadioAMSend.cancel(message_t* msg)
    {
        error_t e;

        atomic {
            if (status != STATUS_RADIO_SEND)
                return FAIL;
        }
        e = call SubAMSend.cancel(msg);
        if (e == SUCCESS)
            atomic status = STATUS_IDLE;
        return e;
    }

    event void SubAMSend.sendDone(message_t *msg, error_t error)
    {
        disp_status_t s;

        atomic {
            s = status;
            if (status != STATUS_RADIO_SEND)
                status = STATUS_INCONSISTENT;
            else
                status = STATUS_IDLE;
        }
        if (s != STATUS_RADIO_SEND)
            signal Dispatcher.inconsistent(s);
        else
            signal RadioAMSend.sendDone(msg, error);
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
                        signal NxtComm.done(e, NULL, 0);
                        call SubSplitControl.start();
                    }
                } else {
                    atomic status = STATUS_IDLE;
                    signal NxtComm.done(FAIL, NULL, 0);
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

    /* Returns TRUE if the dispatcher is ready to transmit on the uart */
    bool test_nxt_status(disp_status_t *s)
    {
        atomic {
            switch (status) {
                case STATUS_IDLE:
                    status = STATUS_UART_SHARE;
                    break;
                case STATUS_INIT:
                    status = STATUS_UART_ONLY;
                    break;
                default:
                    return FALSE;
            }
            *s = status;
        }
        return TRUE;
    }

    error_t perform_transmission(disp_status_t s)
    {
        error_t e;

        if (s == STATUS_UART_ONLY) {
            e = call NxtTransmitter.send(buffer, BUFLEN, req_ack);
            if (e != SUCCESS) {
                atomic status = STATUS_INIT;
                signal NxtComm.done(e, NULL, 0);
            }
            return e;
        } else {
            e = call SubSplitControl.stop();
            if (e != SUCCESS) {
                atomic status = STATUS_IDLE;
                signal NxtComm.done(FAIL, NULL, 0);
            }
            return e;
        }
    }

    command error_t NxtComm.halt()
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.halt(buffer, BUFLEN);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    command error_t NxtComm.rotateTime(int8_t speed, uint32_t time,
                                       bool brake, uint8_t motors)
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.rotateTime(buffer, BUFLEN, speed, time, brake, motors);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    command error_t NxtComm.rotateAngle(int8_t speed, uint32_t angle,
                                        bool brake, uint8_t motors)
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.rotateAngle(buffer, BUFLEN, speed, angle, brake, motors);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    command error_t NxtComm.stopRotation(bool brake, uint8_t motors)
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.stopRotation(buffer, BUFLEN, brake, motors);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    command error_t NxtComm.move(int8_t speed)
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.move(buffer, BUFLEN, speed);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    command error_t NxtComm.turn(int8_t speed, uint32_t degrees)
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.turn(buffer, BUFLEN, speed, degrees);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    command error_t NxtComm.stop(bool brake)
    {
        disp_status_t s;

        if (!test_nxt_status(&s)) {
            return FAIL;
        }
        call Forge.stop(buffer, BUFLEN, brake);
        req_ack = FALSE;
        return perform_transmission(s);
    }

    event void NxtTransmitter.done(error_t err, uint8_t *buf,
                                   size_t len)
    {
        disp_status_t s;

        atomic {
            s = status;
            status = STATUS_UART_FINISH;
        }

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
        signal NxtComm.done(err, buf, len);
    }

    command void Dispatcher.reset(void)
    {
        atomic status = STATUS_INIT;
    }

}

