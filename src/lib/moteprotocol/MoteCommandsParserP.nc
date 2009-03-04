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

module MoteCommandsParserP {

    uses {
        interface NxtCommands[uint8_t id];
    }

    provides {
        interface MoteCommandsInterpreter;
    }

}
implementation {

    static uint8_t myid = unique(CYNAR_UNIQUE);

    command error_t MoteCommandsInterpreter.interpret(uint16_t id,
                                                      mote_protocol_t *msg)
    {
        switch (msg->header.cmd) {
        case COMMAND_RPC:
            return call NxtCommands.exec[myid](&msg->data.rpc);
        case COMMAND_REACH_THRESHOLD:
            signal MoteCommandsInterpreter.reachThreshold(
                            id,
                            msg->data.threshold.value,
                            msg->data.threshold.window);
            break;
        case COMMAND_SYNC:
            signal MoteCommandsInterpreter.sync(id);
            break;
        case COMMAND_PING:
            signal MoteCommandsInterpreter.ping(id);
            break;
        case COMMAND_RESP:
            signal MoteCommandsInterpreter.response(id, (int8_t)msg->data.temperature);
            break;
        case COMMAND_SEND_TEMPERATURE:
            signal MoteCommandsInterpreter.sendTemperature(id);
            break;
        default:
            signal MoteCommandsInterpreter.unknown_command(id, msg);
        }
        return SUCCESS;
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer, size_t len)
    {
        signal MoteCommandsInterpreter.baseCommandExecuted(err, buffer, len);
    }

}

