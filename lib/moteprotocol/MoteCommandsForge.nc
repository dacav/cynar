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

    command void baseHalt(mote_protocol_t *msg);

    command void baseRotateTime(mote_protocol_t *msg,
                                int8_t speed, uint32_t time, bool brake,
                                uint8_t motors);

    command void baseRotateAngle(mote_protocol_t *msg, int8_t speed,
                                 uint32_t angle, bool brake, uint8_t motors);

    command void baseStopRotation(mote_protocol_t *msg, bool brake,
                                  uint8_t motors);

    command void baseMove(mote_protocol_t *msg, int8_t speed);

    command void baseTurn(mote_protocol_t *msg, int8_t speed,
                          uint32_t degrees);

    command void baseStop(mote_protocol_t *msg, bool brake);

    command void reachThreshold(mote_protocol_t *msg, int16_t value);

}

