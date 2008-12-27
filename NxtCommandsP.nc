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

#include "commands.h"

module NxtCommandsP {

    provides interface NxtCommands as NxtComm;
    uses {
        interface Resource;
        interface UartStream;
    }

}
implementation {

    #define BUFSIZE 6

    static uint8_t buffer[BUFSIZE];
    static enum {
        STATUS_READY,
        STATUS_BUSY,
        STATUS_TRANSFER
    } status;

    command error_t NxtComm.halt()
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_halt(buffer, BUFSIZE);
        call Resource.request();
        return SUCCESS;
    }

    command error_t NxtComm.rotateTime(int8_t speed, uint32_t time,
                                       bool brake, uint8_t motors)
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_rotate_time(buffer, BUFSIZE, speed, time, brake, motors);
        call Resource.request();
        return SUCCESS;
    }

    command error_t NxtComm.rotateAngle(int8_t speed, uint32_t angle,
                                        bool brake, uint8_t motors)
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_rotate_angle(buffer, BUFSIZE, speed, angle, brake, motors);
        call Resource.request();
        return SUCCESS;
    }

    command error_t NxtComm.stopRotation(bool brake, uint8_t motors)
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_stop(buffer, BUFSIZE, motors, brake);
        call Resource.request();
        return SUCCESS;
    }

    command error_t NxtComm.move(int8_t speed)
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_move(buffer, BUFSIZE, speed);
        call Resource.request();
        return SUCCESS;
    }

    command error_t NxtComm.turn(int8_t speed, uint32_t degrees)
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_turn(buffer, BUFSIZE, speed, degrees);
        call Resource.request();
        return SUCCESS;
    }

    command error_t NxtComm.stop(bool brake)
    {
        atomic {
            if (status != STATUS_READY)
                return EBUSY;
            status = STATUS_BUSY;
        }
        cmd_build_stop(buffer, BUFSIZE, MOTOR_0 | MOTOR_2, brake);
        call Resource.request();
        return SUCCESS;
    }

    event void Resource.granted()
    {
        atomic {
            status = STATUS_TRANSFER;
        }
        call UartStream.send(buffer, BUFSIZE);
    }

    async event void UartStream.sendDone(uint8_t *buf, uint16_t len,
                                         error_t error)
    {
    }

    async event void UartStream.receivedByte(uint8_t byte)
    {
    }

    async event void UartStream.receiveDone(uint8_t *buf, uint16_t len,
                                            error_t error)
    {
    }

}
