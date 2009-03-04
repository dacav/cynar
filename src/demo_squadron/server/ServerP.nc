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

        interface Timer<TMilli> as Beacon;
        interface Leds;

    }

}

implementation {

    typedef enum {
        STATUS_SYNCING = -1,
        STATUS_INIT = 0,
        STATUS_BEACON,
        STATUS_REPOSITIONING
    } srv_status_t;
    typedef struct {
        uint8_t active : 1;
        uint8_t padding : 7;
        uint16_t temperature;
    } cln_status_t;

    static message_t message, *msg_ptr;
    static const int8_t myid = unique(CYNAR_UNIQUE);
    static srv_status_t status = STATUS_INIT;
    static cln_status_t clients[NCLIENTS];
    static am_addr_t remote_id;
    static bool receiving_temp = FALSE;
    static bool moving = FALSE;

    /* Clears the packet and returns the payload */
    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    /* Prepares the global beacon message */
    void prepare_beacon()
    {
        msg_ptr = &message;
        call Forge.reachThreshold(prepare_packet(msg_ptr), RSSI_TARGET,
                                  RSSI_WINDOW);
    }

    task void display_temperature(void)
    {
        uint32_t i;
        uint16_t temp;
        cln_status_t *cln;
        bool active;

        call Beacon.stop();
        for (i=0; i<NCLIENTS; i++) {
            cln = clients + i;
            atomic active = cln->active;
            if (!active)
                continue;
            atomic {
                temp = cln->temperature;
                cln->active = 0;
            }
            call NxtCommands.print_temperature[myid](i + 1, temp);
        }
        call Beacon.startPeriodic(PINGTIME);
        atomic receiving_temp = FALSE;
    }

    task void start_reposition()
    {
        atomic {
            if (moving)
                return;
            moving = TRUE;
        }
        if (call NxtCommands.move[myid](ROBOT_SPEED) != SUCCESS)
            call Leds.led0Toggle();
    }

    task void stop_reposition()
    {
        atomic {
            if (!moving)
                return;
            moving = FALSE;
        }
        if (call NxtCommands.stop[myid](FALSE) != SUCCESS) 
            call Leds.led0Toggle();
    }

    event void Boot.booted()
    {
        prepare_beacon();
        if (call RadioControl.start() != SUCCESS) {
            call Leds.led0Toggle();
        }
    }

    event void Beacon.fired()
    {
        error_t e;

        call Leds.led2Toggle();
        if (!call Beacon.isRunning())
            return;

        e = call RadioAMSend.send(TOS_BCAST_ADDR, msg_ptr,
                                  sizeof(mote_protocol_t));
        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer,
                                            size_t len)
    {
        if (err != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
    }

    event message_t * RadioReceive.receive(message_t *msg, void *payload,
                                           uint8_t len)
    {
        am_addr_t sender;

        call Leds.led1Toggle();

        if (len == sizeof(mote_protocol_t)) {
            sender = call RadioAMPacket.source(msg);
            call Interpreter.interpret(sender, payload);
        }
        return msg;
    }

    event void RadioAMSend.sendDone(message_t *msg, error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
    }

    event void RadioControl.startDone(error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
    }

    event void Interpreter.response(uint16_t id, int16_t temp)
    {
        cln_status_t *cln;
        static uint8_t cnt = 0;

        atomic {
            if (!receiving_temp)
                return;
        }

        id--;   /* Used as index */
        if (id < 0 || id > NCLIENTS)
            return;
        atomic { 
            cln = clients + id;
            if (!cln->active) {
                cln->temperature = temp;
                cln->active = 1;
                cnt++;
            }
        }
        if (cnt == NCLIENTS) {
            post display_temperature();
        }
    }

    event void Interpreter.sync(uint16_t id)
    {
        srv_status_t s;

        atomic {
            s = status;
            status = STATUS_SYNCING;
        }

        switch (s) {
            case STATUS_INIT:
                atomic remote_id = id;
            case STATUS_REPOSITIONING:
                atomic status = STATUS_BEACON;
                post stop_reposition();
                call Beacon.startPeriodic(PINGTIME);
                break;
            case STATUS_BEACON:
                atomic status = STATUS_REPOSITIONING;
                call Beacon.stop();
                post start_reposition();
                break;
            default:
                call Leds.led0Toggle();
        }
    }

    event void Interpreter.sendTemperature(uint16_t id)
    {
        atomic {
            if (id == remote_id)
                receiving_temp = TRUE;
        }
    }

    event void RadioControl.stopDone(error_t e) {} 
    event void Interpreter.reachThreshold(uint16_t id, int8_t x, uint8_t y) {}
    event void Interpreter.baseCommandExecuted(error_t err, uint8_t *buffer,
                                               size_t len) {}
    event void Interpreter.ping(uint16_t id) {}
    event void Interpreter.unknown_command(uint16_t id, mote_protocol_t *msg) {}
    event void Dispatcher.inconsistent(disp_status_t x) {}
        
}

