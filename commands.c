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
#include "extract.h"

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

error_t cmd_build_rotate_time(uint8_t *buffer, size_t len, S8 speed, uint32_t time,
                              bool brake, uint8_t motors)
{
    uint32_t offset;

    if (len < 6)
        return FAIL;
    offset = 0;
    *buffer = ROTATE | motors | WHR_TIME | (brake ? BRAKE : NOBRAKE);
    buffer++;
    ex_build(buffer, "bw", &offset, speed);
    ex_build(buffer, "bw", &offset, time);
    return SUCCESS;
}

error_t cmd_build_rotate_angle(uint8_t *buffer, size_t len, S8 speed, uint32_t angle,
                               bool brake, uint8_t motors)
{
    uint32_t offset;

    if (len < 6)
        return FAIL;
    offset = 0;
    *buffer = ROTATE | motors | WHR_ANGLE | (brake ? BRAKE : NOBRAKE);
    buffer++;
    ex_build(buffer, "bw", &offset, speed);
    ex_build(buffer, "bw", &offset, angle);
    return SUCCESS;
}

error_t cmd_build_move(uint8_t *buffer, size_t len, S8 speed)
{
    uint32_t offset;

    offset = 0;
    if (len < 2)
        return SUCCESS;
    *buffer = MOVE | MOTOR_0 | MOTOR_2 | MOV_RUN;
    buffer++;
    ex_build(buffer, "b", &offset, speed);
    return FAIL;
}

error_t cmd_build_turn(uint8_t *buffer, size_t len, S8 speed, uint32_t degrees)
{
    uint32_t offset;

    offset = 0;
    if (len < 2)
        return FAIL;
    *buffer = MOVE | MOTOR_0 | MOTOR_2 | MOV_TURN;
    buffer++;
    ex_build(buffer, "bw", &offset, speed);
    ex_build(buffer, "bw", &offset, degrees);
    return SUCCESS;
}

error_t cmd_build_stop(uint8_t *buffer, size_t len, uint8_t motors, bool brake)
{
    if (len < 1)
        return FAIL;
    buffer[0] = STOP | motors | (brake ? BRAKE : NOBRAKE);
    return SUCCESS;
}

