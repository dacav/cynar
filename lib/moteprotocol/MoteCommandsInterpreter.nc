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

interface MoteCommandsInterpreter {

    command error_t interpret(uint16_t clid, mote_protocol_t *msg);

    event void reachThreshold(uint16_t clid, int8_t thershold, uint8_t window);

    event void sendTemperature(uint16_t clid);

    event void baseCommandExecuted(error_t err, uint8_t *buffer, size_t len);

    event void sync(uint16_t clid);

    event void ping(uint16_t clid);

    event void response(uint16_t clid, int16_t rssi);

    event void unknown_command(uint16_t id, mote_protocol_t *msg);

}

