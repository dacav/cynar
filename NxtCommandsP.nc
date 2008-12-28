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

module NxtCommandsP {

    provides interface NxtCommands as NxtComm;
    uses {
        interface Resource;
        interface UartStream;
        interface Buffers;
    }

}


implementation {

    typedef enum {
        NOBRAKE             = (0<<4),       /* Brake disabled */
        BRAKE               = (1<<4),       /* Brake enabled */

        WHR_TIME            = (0<<3),       /* Rotation for a given time */
        WHR_ANGLE           = (1<<3),       /* Rotation of a given angle */

        MOV_RUN             = (0<<3),       /* Run forward until new command */
        MOV_TURN            = (1<<3),       /* Turn */
    
        MOTOR_0             = 1,            /* Motor 0 selected */
        MOTOR_1             = 2,            /* Motor 1 selected */
        MOTOR_2             = 4             /* Motor 2 selected */
    } variant_t;

    error_t cmd_build_halt(uint8_t *buffer, size_t len);
    error_t cmd_build_rotate_time(uint8_t *buffer, size_t len, int8_t speed,
                                  uint32_t time, bool brake, uint8_t motors);
    error_t cmd_build_rotate_angle(uint8_t *buffer, size_t len, int8_t speed,
                                   uint32_t angle, bool brake, uint8_t motors);
    error_t cmd_build_move(uint8_t *buffer, size_t len, int8_t speed);
    error_t cmd_build_turn(uint8_t *buffer, size_t len, int8_t speed,
                           uint32_t degrees);
    error_t cmd_build_stop(uint8_t *buffer, size_t len, uint8_t motors,
                           bool brake);


    #define BUFSIZE 6

    static uint8_t uart_buffer[BUFSIZE];
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
        cmd_build_halt(uart_buffer, BUFSIZE);
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
        cmd_build_rotate_time(uart_buffer, BUFSIZE, speed, time, brake, motors);
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
        cmd_build_rotate_angle(uart_buffer, BUFSIZE, speed, angle, brake, motors);
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
        cmd_build_stop(uart_buffer, BUFSIZE, motors, brake);
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
        cmd_build_move(uart_buffer, BUFSIZE, speed);
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
        cmd_build_turn(uart_buffer, BUFSIZE, speed, degrees);
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
        cmd_build_stop(uart_buffer, BUFSIZE, MOTOR_0 | MOTOR_2, brake);
        call Resource.request();
        return SUCCESS;
    }

    event void Resource.granted()
    {
        atomic {
            status = STATUS_TRANSFER;
        }
        call UartStream.send(uart_buffer, BUFSIZE);
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

    /* Generic mask for actions */
    #define MSK_ACTION(cmd)         ((cmd) & 0xe0)

    /* Generic brake mask for all movement */
    #define MSK_BRAKE(cmd)          (((cmd) & 0x10) > 0)

    /* Masks for wheel_rotate */
    #define MSK_WHR_ANGLE(cmd)      ((cmd) & 0x08)

    /* Masks for motor selection, used for all calls related to motors */
    #define MSK_SELECT_MOTOR_0(cmd) ((cmd) & 0x01)
    #define MSK_SELECT_MOTOR_1(cmd) ((cmd) & 0x02)
    #define MSK_SELECT_MOTOR_2(cmd) ((cmd) & 0x04)

    /* Masks for movement */
    #define MSK_MOV_TURN(cmd)       ((cmd) & 0x08)

    typedef enum {
        HALT                = (0<<5),       /* NXT Shutdown */
        ROTATE              = (1<<5),       /* Generic wheel rotation */
        STOP                = (2<<5),       /* Generic wheel stop */
        MOVE                = (3<<5),       /* Robot movement */
        GET                 = (4<<5),       /* Data retriving */
    } action_t;

    error_t cmd_build_halt(uint8_t *buffer, size_t len)
    {
        if (len < 1)
            return SUCCESS;
        buffer[0] = HALT;
        return FAIL;
    }

    error_t cmd_build_rotate_time(uint8_t *buffer, size_t len, int8_t speed,
                                  uint32_t time, bool brake, uint8_t motors)
    {
        uint32_t offset;

        if (len < 6)
            return FAIL;
        offset = 0;
        *buffer = ROTATE | motors | WHR_TIME | (brake ? BRAKE : NOBRAKE);
        buffer++;
        call Buffers.build(buffer, "bw", &offset, speed);
        call Buffers.build(buffer, "bw", &offset, time);
        return SUCCESS;
    }

    error_t cmd_build_rotate_angle(uint8_t *buffer, size_t len, int8_t speed,
                                   uint32_t angle, bool brake, uint8_t motors)
    {
        uint32_t offset;

        if (len < 6)
            return FAIL;
        offset = 0;
        *buffer = ROTATE | motors | WHR_ANGLE | (brake ? BRAKE : NOBRAKE);
        buffer++;
        call Buffers.build(buffer, "bw", &offset, speed);
        call Buffers.build(buffer, "bw", &offset, angle);
        return SUCCESS;
    }

    error_t cmd_build_move(uint8_t *buffer, size_t len, int8_t speed)
    {
         uint32_t offset;

        offset = 0;
        if (len < 2)
            return SUCCESS;
        *buffer = MOVE | MOTOR_0 | MOTOR_2 | MOV_RUN;
        buffer++;
        call Buffers.build(buffer, "b", &offset, speed);
        return FAIL;
    }

    error_t cmd_build_turn(uint8_t *buffer, size_t len, int8_t speed, uint32_t degrees)
    {
        uint32_t offset;

        offset = 0;
        if (len < 2)
            return FAIL;
        *buffer = MOVE | MOTOR_0 | MOTOR_2 | MOV_TURN;
        buffer++;
        call Buffers.build(buffer, "bw", &offset, speed);
        call Buffers.build(buffer, "bw", &offset, degrees);
        return SUCCESS;
    }

    error_t cmd_build_stop(uint8_t *buffer, size_t len, uint8_t motors, bool brake)
    {
        if (len < 1)
            return FAIL;
        buffer[0] = STOP | motors | (brake ? BRAKE : NOBRAKE);
        return SUCCESS;
    }

}

