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
        interface NxtCommands;
    }

    provides {
        interface MoteCommandsInterpreter;
    }

}
implementation {

    command error_t interpret(mote_protocol_t *msg)
    {
        switch (msg->header.cmd) {
        case COMMAND_RPC:
            return call NxtCommands.exec(&msg->data.rpc);
        case COMMAND_REACH_THRESHOLD:
            signal MoteCommandsInterpreter.reachThreshold(msg->data.threshold);
            break;
        /* HERE add more commands */
        }
        return SUCCESS;
    }

    event void NxtCommands.done(error_t err, uint8_t *buffer, size_t len)
    {
        signal MoteCommandsInterpreter.baseCommandExecuted(err, buffer, len);
    }

}

