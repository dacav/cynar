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

module NxtCommandsForgeP {

    provides interface NxtCommandsForge;

}

implementation {

    command void NxtCommandsForge.halt(nxt_protocol_t *msg)
    {
        msg->header.action = HALT;
    }

    command void NxtCommandsForge.rotateTime(nxt_protocol_t *msg,
                                             int8_t speed, uint32_t time,
                                             bool brake, uint8_t motors)
    {
        msg->header.action = ROTATE;
        msg->header.brake = (brake ? BRAKE : NOBRAKE);
        msg->header.angle_turn = WHR_TIME;
        msg->header.motors = motors;
        msg->data.rotate_time.speed = speed;
        msg->data.rotate_time.time = time;
    }

    command void NxtCommandsForge.rotateAngle(nxt_protocol_t *msg,
                                              int8_t speed, uint32_t angle,
                                              bool brake, uint8_t motors)
    {
        msg->header.action = ROTATE;
        msg->header.brake = (brake ? BRAKE : NOBRAKE);
        msg->header.angle_turn = WHR_ANGLE;
        msg->header.motors = motors;
        msg->data.rotate_angle.speed = speed;
        msg->data.rotate_angle.angle = angle;
    }

    command void NxtCommandsForge.stopRotation(nxt_protocol_t *msg,
                                               bool brake, uint8_t motors)
    {
        msg->header.action = STOP;
        msg->header.brake = (brake ? BRAKE : NOBRAKE);
        msg->header.motors = motors;
    }

    command void NxtCommandsForge.move(nxt_protocol_t *msg, int8_t speed)
    {
        msg->header.action = MOVE;
        msg->header.angle_turn = MOV_RUN;
        msg->data.move.speed = speed;
    }

    command void NxtCommandsForge.turn(nxt_protocol_t *msg, int8_t speed,
                                       uint32_t degrees)
    {
        msg->header.action = MOVE;
        msg->header.angle_turn = MOV_TURN;
        msg->data.turn.speed = speed;
        msg->data.turn.degrees = degrees;
    }

    command void NxtCommandsForge.stop(nxt_protocol_t *msg, bool brake)
    {
        msg->header.action = STOP;
        msg->header.motors = MOTOR_MOVEMENT;
        msg->header.brake = (brake ? BRAKE : NOBRAKE);
    }

}

