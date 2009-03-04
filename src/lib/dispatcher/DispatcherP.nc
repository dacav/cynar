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

#include "nxtprotocol.h"

module DispatcherP {

    provides {

        interface NxtCommands as NxtComm[uint8_t id];

        /* Radio communication */
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend;
        interface Receive as RadioReceive;
        interface Dispatcher;
        interface Msp430UartConfigure;

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

    static nxt_protocol_t nxt_message;
    static uint8_t client_id;
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
        if (s != STATUS_RADIO_SEND) {
            signal Dispatcher.inconsistent(s);
        } else {
            signal RadioAMSend.sendDone(msg, error);
        }
    }

    event void SubSplitControl.startDone(error_t error)
    {
        disp_status_t s1, s2;

        if (error == SUCCESS) {
            atomic {
                s1 = status;
                switch (status) {
                    case STATUS_ACTIVATING:
                    case STATUS_UART_FINISH:
                        status = STATUS_IDLE;
                        break;
                    default:
                        status = STATUS_INCONSISTENT;
                }
                s2 = status;
            }
            if (s2 == STATUS_INCONSISTENT) {
                signal Dispatcher.inconsistent(s1);
            }
        }
        signal RadioControl.startDone(error);
    }

    event void SubSplitControl.stopDone(error_t error)
    {
        error_t e;
        disp_status_t s;
        uint8_t id;

        atomic {
            s = status;
            status = STATUS_INCONSISTENT;
            id = client_id;
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
                    atomic status = s;
                    e = call NxtTransmitter.send((uint8_t *)&nxt_message,
                             sizeof(nxt_protocol_t), req_ack);
                    if (e != SUCCESS) {
                        atomic status = STATUS_UART_FINISH;
                        signal NxtComm.done[id](e, NULL, 0);
                        call SubSplitControl.start();
                    }
                } else {
                    atomic status = STATUS_IDLE;
                    signal NxtComm.done[id](FAIL, NULL, 0);
                }
                break;
            default:
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
    bool test_nxt_status(disp_status_t *s, uint8_t id)
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
            client_id = id;
        }
        return TRUE;
    }

    error_t perform_transmission(disp_status_t s, uint8_t id)
    {
        error_t e;

        if (s == STATUS_UART_ONLY) {
            e = call NxtTransmitter.send((uint8_t *)&nxt_message,
                                         sizeof(nxt_protocol_t),
                                         req_ack);
            if (e != SUCCESS) {
                atomic status = STATUS_INIT;
                signal NxtComm.done[id](e, NULL, 0);
            }
            return e;
        } else {
            e = call SubSplitControl.stop();
            if (e != SUCCESS) {
                atomic status = STATUS_IDLE;
                signal NxtComm.done[id](FAIL, NULL, 0);
            }
            return e;
        }
    }

    command error_t NxtComm.halt[uint8_t id]()
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.halt(&nxt_message);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.rotateTime[uint8_t id](int8_t speed, uint32_t time,
                                                   bool brake, uint8_t motors)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.rotateTime(&nxt_message, speed, time, brake, motors);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.rotateAngle[uint8_t id](int8_t speed,
                                                    uint32_t angle,
                                                    bool brake,
                                                    uint8_t motors)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.rotateAngle(&nxt_message, speed, angle, brake, motors);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.stopRotation[uint8_t id](bool brake,
                                                     uint8_t motors)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.stopRotation(&nxt_message, brake, motors);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.move[uint8_t id](int8_t speed)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.move(&nxt_message, speed);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.turn[uint8_t id](int8_t speed, uint32_t degrees)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.turn(&nxt_message, speed, degrees);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.stop[uint8_t id](bool brake)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.stop(&nxt_message, brake);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.print_temperature[uint8_t id](uint16_t eid, int16_t temp)
    {
        disp_status_t s;
        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        call Forge.print_temperature(&nxt_message, eid, temp);
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    command error_t NxtComm.exec[uint8_t id](nxt_protocol_t *cmd)
    {
        disp_status_t s;

        if (!test_nxt_status(&s, id)) {
            return FAIL;
        }
        memcpy((uint8_t *)&nxt_message, cmd, sizeof(nxt_protocol_t));
        req_ack = FALSE;
        return perform_transmission(s, id);
    }

    event void NxtTransmitter.done(error_t err, uint8_t *buf,
                                   size_t len)
    {
        disp_status_t s;
        uint8_t id;

        atomic {
            s = status;
            status = STATUS_UART_FINISH;
            id = client_id;
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
        signal NxtComm.done[id](err, buf, len);
    }

    command void Dispatcher.reset(void)
    {
        atomic status = STATUS_INIT;
    }

    static msp430_uart_union_config_t config = {
        {
            ubr: UBR_1MHZ_9600, 
            umctl: UMCTL_1MHZ_9600, 
            ssel: 0x02,
            pena: 0,
            pev: 0,
            spb: 0,
            clen: 1,
            listen: 0,
            mm: 0,
            ckpl: 0,
            urxse: 0,
            urxeie: 0,
            urxwie: 0,
            utxe : 1,
            urxe : 1
        }
    };

    async command msp430_uart_union_config_t *Msp430UartConfigure.getConfig() {
        return &config;
    }

}

