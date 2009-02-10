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
#include "nxtprotocol.h"

module MoteCommandsForgeP {

    provides interface MoteCommandsForge;
    uses interface NxtCommandsForge;

}
implementation {

    nxt_protocol_t * prepare_base_command(mote_protocol_t *m)
    {
        m->header.sender = SENDER_MOTHER;
        m->header.cmd = COMMAND_RPC;
        return &m->data.rpc;
    }

    command void MoteCommandsForge.baseHalt(mote_protocol_t *msg)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.halt(nxtmsg);
    }

    command void MoteCommandsForge.baseRotateTime(mote_protocol_t *msg,
                                                  int8_t speed,
                                                  uint32_t time,
                                                  bool brake,
                                                  uint8_t motors)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.rotateTime(nxtmsg, speed, time, brake, motors);
    }

    command void MoteCommandsForge.baseRotateAngle(mote_protocol_t *msg,
                                                   int8_t speed,
                                                   uint32_t angle,
                                                   bool brake,
                                                   uint8_t motors)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.rotateAngle(nxtmsg, speed, angle, brake, motors);
    }

    command void MoteCommandsForge.baseStopRotation(mote_protocol_t *msg,
                                                    bool brake,
                                                    uint8_t motors)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.stopRotation(nxtmsg, brake, motors);
    }

    command void MoteCommandsForge.baseMove(mote_protocol_t *msg,
                                            int8_t speed)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.move(nxtmsg, speed);
    }

    command void MoteCommandsForge.baseTurn(mote_protocol_t *msg,
                                            int8_t speed,
                                            uint32_t degrees)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.turn(nxtmsg, speed, degrees);
    }

    command void MoteCommandsForge.baseStop(mote_protocol_t *msg,
                                            bool brake)
    {
        nxt_protocol_t *nxtmsg;
        nxtmsg = prepare_base_command(msg);
        call NxtCommandsForge.stop(nxtmsg, brake);
    }

    command void MoteCommandsForge.reachThreshold(mote_protocol_t *msg,
                                                  int8_t value)
    {
        msg->header.sender = SENDER_MOTHER;
        msg->header.cmd = COMMAND_REACH_THRESHOLD;
        msg->data.threshold = (nx_int8_t)value;
    }

    command void MoteCommandsForge.sync(mote_protocol_t *msg)
    {
        msg->header.sender = SENDER_MOTHER;
        msg->header.cmd = COMMAND_SYNC;
    }

    command void MoteCommandsForge.ping(mote_protocol_t *msg)
    {
        msg->header.sender = SENDER_CHILD;
        msg->header.cmd = COMMAND_PING;
    }

    command void MoteCommandsForge.response(mote_protocol_t *msg, int16_t temperature)
    {
        msg->header.sender = SENDER_MOTHER;
        msg->header.cmd = COMMAND_RESP;
        msg->data.temperature = temperature;
    }

}

