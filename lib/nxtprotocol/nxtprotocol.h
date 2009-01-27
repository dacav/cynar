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

#ifndef __NXT_PROTOCOL_H__
#define __NXT_PROTOCOL_H__

#define NOBRAKE 0           /* Brake disabled */
#define BRAKE 1             /* Brake enabled */

#define WHR_TIME 0          /* Rotation for a given time */
#define WHR_ANGLE 1         /* Rotation of a given angle */

#define MOV_RUN 0           /* Run forward until new command */
#define MOV_TURN 1          /* Turn */

#define MOTOR_0 1           /* Motor 0 selected */
#define MOTOR_1 2           /* Motor 1 selected */
#define MOTOR_2 4           /* Motor 2 selected */

#define MOTOR_MOVEMENT 5

/* Macro arguments */

#define HALT 1              /* NXT Shutdown */
#define ROTATE 2            /* Generic wheel rotation */
#define STOP 3              /* Generic wheel stop */
#define MOVE 4              /* Robot movement */
#define GET 5               /* Data retriving */

typedef nx_struct {
    nx_uint8_t action : 3;
    nx_uint8_t brake : 1;
    nx_uint8_t angle_turn : 1;
    nx_uint8_t motors : 3;
} nxt_protocol_header_t; 

/* The nxt buffer is 6 bytes long. The padding of the union must take care of
 * the header (1 byte)
 */
#define NXT_PADDING 5
#define NXT_BUFLEN 6

typedef nx_struct {
    nxt_protocol_header_t header;
    nx_union {
        nxle_uint8_t padding[NXT_PADDING];
        nx_struct {
            nxle_int8_t speed;
            nxle_uint8_t time;
        } rotate_time;
        nx_struct {
            nxle_int8_t speed;
            nxle_uint8_t angle;
        } rotate_angle;
        nx_struct {
            nxle_int8_t speed;
        } move;
        nx_struct {
            nxle_int8_t speed;
            nxle_uint32_t degrees;
        } turn;
    } data;
} nxt_protocol_t;

#endif /* __NXT_PROTOCOL_H__ */

