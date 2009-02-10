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

#ifndef __MOTE_PROTOCOL_H__
#define __MOTE_PROTOCOL_H__

#include "nxtprotocol.h"

/* Length of a remote NXT command */
#define RPC_LEN 6

/* Sender identifiers */
#define SENDER_MOTHER 0
#define SENDER_CHILD 1

#define COMMAND_RPC 0
#define COMMAND_SYNC 1
#define COMMAND_PING 2
#define COMMAND_RESP 3
#define COMMAND_REACH_THRESHOLD 4

typedef nx_struct {
    nx_uint8_t sender : 1; 
    nx_uint8_t cmd : 7;
} mote_protocol_header_t;

typedef nx_struct {
    mote_protocol_header_t header;
    nx_union {
        nxt_protocol_t rpc;
        nx_int8_t threshold;
        nx_int16_t temperature;
    } data;
} mote_protocol_t;

#endif /* __MOTE_PROTOCOL_H__ */

