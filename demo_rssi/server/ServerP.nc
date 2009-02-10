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

module ServerP {

    uses {

        interface Boot;

        /* Commands to the nxt */
        interface NxtCommands[uint8_t id];

        /* Radio communication */
        interface Receive as RadioReceive;
        interface SplitControl as RadioControl;
        interface AMSend as RadioAMSend;
        interface AMPacket as RadioAMPacket;
        interface Packet as RadioPacket;
        interface CC2420Packet;

        /* Error management for Nxt Dispatcher */
        interface Dispatcher;

        /* High level mote commands */
        interface MoteCommandsInterpreter as Interpreter;
        interface MoteCommandsForge as Forge;

        interface Leds;
        interface Timer<TMilli> as PingTimer;

    }

}

implementation {

    static message_t message, *msg_ptr;
    static const int8_t myid = unique(CYNAR_UNIQUE);

    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    event void Boot.booted()
    {
        msg_ptr = &message;
        call Forge.reachThreshold(prepare_packet(msg_ptr), RSSI_TARGET);
        if (call RadioControl.start() != SUCCESS)
            call Leds.led0Toggle();
    }

    event void PingTimer.fired()
    {
        error_t e;

        e = call RadioAMSend.send(TOS_BCAST_ADDR, msg_ptr,
                                  sizeof(mote_protocol_t));
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        } else {
            call Leds.led2Toggle();
        }
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer,
                                            size_t len)
    {
    }

    event message_t * RadioReceive.receive(message_t *msg, void *payload,
                                           uint8_t len)
    {
        am_addr_t sender;

        if (len == sizeof(mote_protocol_t)) {
            sender = call RadioAMPacket.source(msg);
            call Interpreter.interpret(sender, payload);
        }
        return msg;
    }

    event void Dispatcher.inconsistent(disp_status_t x)
    {
    }
        
    event void RadioAMSend.sendDone(message_t *msg, error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        }
    }

    event void RadioControl.startDone(error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
        call PingTimer.startPeriodic(PINGTIME);
    }

    event void Interpreter.response(uint16_t id, int16_t temp)
    {
        call Leds.led1Toggle();
        call NxtCommands.print_temperature[myid](id, temp);
    }

    event void RadioControl.stopDone(error_t e) {} 
    event void Interpreter.reachThreshold(uint16_t id, uint8_t thershold) {} 
    event void Interpreter.baseCommandExecuted(error_t err, uint8_t *buffer, size_t len) {}
    event void Interpreter.ping(uint16_t id) {}
    event void Interpreter.unknown_command(uint16_t id, mote_protocol_t *msg) {}
    event void Interpreter.sync(uint16_t id) {}

}

