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

    }

}

implementation {

    typedef struct {
        struct {
            uint8_t active : 1;
            uint8_t padding : 7;
        } status;
        int8_t rssi;
    } client_t;

    typedef enum {
        STATUS_INIT = 0,
        STATUS_SYNC,
        STATUS_SENDCMD,
        STATUS_ACTIVE,
    } srv_status_t;

    static uint8_t myid = unique(CYNAR_UNIQUE);
    static client_t clients[NCLIENTS];
    static srv_status_t status = STATUS_INIT;

    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    event void Boot.booted()
    {
        if (call RadioControl.start() != SUCCESS)
            call Leds.led0Toggle();
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer,
                                            size_t len)
    {
    }

    event message_t * RadioReceive.receive(message_t *msg, void *payload,
                                           uint8_t len)
    {
        am_addr_t sender;
        int8_t rssi;

        if (len == sizeof(mote_protocol_t)) {
            sender = call RadioAMPacket.source(msg);
            if (sender > 0 && sender < NCLIENTS) {
                rssi = call CC2420Packet.getRssi(msg);
                atomic clients[sender-1].rssi = rssi;
                call Interpreter.interpret(sender, payload);
            }
        }
        return msg;
    }

    event void Dispatcher.inconsistent(disp_status_t x)
    {
    }
        
    event void RadioControl.startDone(error_t e)
    {
        message_t msg;

        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }

        atomic status = STATUS_SYNC;
        call Forge.sync(prepare_packet(&msg));
        e = call RadioAMSend.send(TOS_BCAST_ADDR, &msg, sizeof(mote_protocol_t));
        if (e != SUCCESS)
            call Leds.led0Toggle();
    }

    event void RadioControl.stopDone(error_t e)
    {
    }

    event void RadioAMSend.sendDone(message_t *msg, error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        }
        atomic {
            if (status == STATUS_SENDCMD) {
                status = STATUS_ACTIVE;
            }
        }
    }

    event void Interpreter.reachThreshold(uint16_t id, uint8_t thershold)
    {
    }

    event void Interpreter.baseCommandExecuted(error_t err, uint8_t *buffer,
                                               size_t len)
    {
    }

    event void Interpreter.ping(uint16_t id)
    {
        int8_t rssi;
        message_t msg;

        atomic rssi = clients[id-1].rssi;
        call Forge.response(prepare_packet(&msg), rssi);
        call RadioAMSend.send(id, &msg, sizeof(mote_protocol_t));
    }

    event void Interpreter.unknown_command(uint16_t id,
                                           mote_protocol_t *msg)
    {
    }

    event void Interpreter.sync(uint16_t id)
    {
        static uint8_t counter = 0;
        message_t msg;

        if (id == call RadioAMPacket.address())
            return;

        counter++;
        if (counter >= NCLIENTS) {
            /* We have all clients synchronized! */
            atomic status = STATUS_SENDCMD;
            call Forge.reachThreshold(prepare_packet(&msg), RSSI_TARGET);
            call RadioAMSend.send(TOS_BCAST_ADDR, &msg, sizeof(mote_protocol_t));
        }
    }

    /* Unused: this is client stuff */
    event void Interpreter.response(uint16_t id, int8_t rssi) {}

}

