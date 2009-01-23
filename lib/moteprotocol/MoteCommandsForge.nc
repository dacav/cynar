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

interface MoteCommandsForge {

    command error_t baseHalt(mote_protocol_t *msg);

    command error_t baseRotateTime(mote_protocol_t *msg,
                                   int8_t speed, uint32_t time, bool brake,
                                   uint8_t motors);

    command error_t baseRotateAngle(mote_protocol_t *msg, int8_t speed,
                                    uint32_t angle, bool brake, uint8_t motors);

    command error_t baseStopRotation(mote_protocol_t *msg, bool brake,
                                     uint8_t motors);

    command error_t baseMove(mote_protocol_t *msg, int8_t speed);

    command error_t baseTurn(mote_protocol_t *msg, int8_t speed,
                             uint32_t degrees);

    command error_t baseStop(mote_protocol_t *msg, bool brake);

    command error_t reachThreshold(mote_protocol_t *msg, int16_t value);

}

