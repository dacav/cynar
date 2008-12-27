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

#ifndef __COMMANDS_H__
#define __COMMANDS_H__

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

/** Interpreter for command
 *
 * The remote command can be parsed by using this procedure. The buffer will
 * be refilled with the acknowledgment for the required command and, if
 * required, with the data to send back.
 *
 * @param buffer The command buffer;
 * @param len The command buffer's length
 * @return TRUE if the interpretation succeded, FALSE otherwise.
 */
error_t cmd_interpret(uint8_t *buffer, size_t len);
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

#endif /* __COMMANDS_H__ */

