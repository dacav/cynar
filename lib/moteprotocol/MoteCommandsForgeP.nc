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

#include "moteprotocol.h"

module MoteCommandsForgeP {

    provides interface MoteCommandsForge;
    uses interface NxtCommandsForge;

}
implementation {

    nx_uint8_t * prepare_base_command(mote_protocol_t *m)
    {
        m->header.sender = SENDER_MOTHER;
        m->header.cmd = COMMAND_RPC;
        return m->data.buffer;
    }

    command error_t MoteCommandsForge.baseHalt(mote_protocol_t *msg)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.halt(buffer, RPC_LEN);
    }

    command error_t MoteCommandsForge.baseRotateTime(mote_protocol_t *msg,
                                                     int8_t speed,
                                                     uint32_t time,
                                                     bool brake,
                                                     uint8_t motors)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.rotateTime(buffer, RPC_LEN, speed,
                                                time, brake, motors);
    }

    command error_t MoteCommandsForge.baseRotateAngle(mote_protocol_t *msg,
                                                      int8_t speed,
                                                      uint32_t angle,
                                                      bool brake,
                                                      uint8_t motors)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.rotateAngle(buffer, RPC_LEN, speed,
                                                 angle, brake, motors);
    }

    command error_t MoteCommandsForge.baseStopRotation(mote_protocol_t *msg,
                                                       bool brake,
                                                       uint8_t motors)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.stopRotation(buffer, RPC_LEN, brake,
                                                  motors);
    }

    command error_t MoteCommandsForge.baseMove(mote_protocol_t *msg,
                                               int8_t speed)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.move(buffer, RPC_LEN, speed);
    }

    command error_t MoteCommandsForge.baseTurn(mote_protocol_t *msg,
                                               int8_t speed,
                                               uint32_t degrees)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.turn(buffer, RPC_LEN, speed, degrees);
    }

    command error_t MoteCommandsForge.baseStop(mote_protocol_t *msg,
                                               bool brake)
    {
        nx_uint8_t * buffer;
        buffer = prepare_base_command(msg);
        return call NxtCommandsForge.stop(buffer, RPC_LEN, brake);
    }

    command error_t MoteCommandsForge.reachThreshold(mote_protocol_t *msg,
                                                     int16_t value)
    {
        msg->header.sender = SENDER_MOTHER;
        msg->heaer.cmd = COMMAND_REACH_THRESHOLD;
        msg->data.threshold = (nx_uint16_t)value;
    }

}

