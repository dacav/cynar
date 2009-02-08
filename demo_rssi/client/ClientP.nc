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

module ClientP {

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
        interface Random;
    }

}

implementation {

    typedef enum {
        STATUS_INIT = 0,
        STATUS_SYNC,
        STATUS_WAITING,
        STATUS_EXECUTING,
        STATUS_MOVING
    } cln_status_t;

    static int8_t stored_rssi;
    static int8_t elab_rssi;
    static cln_status_t status;
    static uint8_t myid = unique(CYNAR_UNIQUE);
    static am_addr_t srv_addr;

    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    int8_t elaborate_rssi(int8_t r1, int8_t r2)
    {
        return (r1 + r2) >> 1;
    }

    bool keep_moving(int8_t rssi)
    {
        return TRUE;
    }

    task void start_reachthreshold(void)
    {
        uint32_t rnd;

        rnd = call Random.rand32() % PINGTIME;
        call PingTimer.startOneShot(rnd);
    }

    task void start_moving(void)
    {
        int8_t rssi;

        atomic rssi = elab_rssi;
        if (keep_moving(rssi)) {
            if (call NxtCommands.move[myid](ROBOT_SPEED) != SUCCESS)
                call Leds.led0Toggle();
            else
                call Leds.led2Toggle();
        }
    }

    task void check_execution(void)
    {
        int8_t rssi;

        atomic rssi = elab_rssi;
        if (!keep_moving(rssi)) {
            if (call NxtCommands.stop[myid](TRUE) != SUCCESS)
                call Leds.led0Toggle();
            else
                call Leds.led2Toggle();
        }
    }

    event void Boot.booted()
    {
        if (call RadioControl.start() != SUCCESS) {
            call Leds.led0Toggle();
        }
    }

    event void PingTimer.fired()
    {
        message_t msg;
        am_addr_t addr;

        atomic addr = srv_addr;
        call Forge.ping(prepare_packet(&msg));
        if (call RadioAMSend.send(addr, &msg, sizeof(mote_protocol_t))) {
            call Leds.led0Toggle();
        }
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer,
                                            size_t len)
    {
        cln_status_t s;

        if (err != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
        call Leds.led2Toggle();
        atomic {
            switch (status) {
            case STATUS_EXECUTING:
                status = STATUS_MOVING;
                break;
            case STATUS_MOVING:
                status = STATUS_WAITING;
                break;
            default:
                call Leds.led0Toggle();
            }
            s = status;
        }
        if (s == STATUS_MOVING) {
            call PingTimer.startOneShot(PINGTIME);
        }
        /*
        else {
        TODO Here additive stuff
        }
        */
    }

    event message_t * RadioReceive.receive(message_t *msg, void *payload,
                                           uint8_t len)
    {
        am_addr_t sender;
        int8_t rssi;

        if (len == sizeof(mote_protocol_t)) {
            sender = call RadioAMPacket.source(msg);
            rssi = call CC2420Packet.getRssi(msg);
            atomic stored_rssi = rssi;
            call Interpreter.interpret(sender, payload);
        }
        return msg;
    }

    event void Dispatcher.inconsistent(disp_status_t x)
    {
    }
        
    event void RadioControl.startDone(error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        } else {
            call Leds.led1Toggle();
        }
    }

    event void RadioControl.stopDone(error_t e)
    {
    }

    event void RadioAMSend.sendDone(message_t *msg, error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
            return;
        }
        atomic {
            if (status == STATUS_SYNC)
                status = STATUS_WAITING;
        }
        call Leds.led1Toggle();
    }

    event void Interpreter.reachThreshold(uint16_t id, uint8_t thershold)
    {
        atomic {
            if (status != STATUS_WAITING)
                return;
            status = STATUS_EXECUTING;
        }
        post start_reachthreshold();
    }

    event void Interpreter.sync(uint16_t id) 
    {
        message_t msg;
        error_t e;

        atomic {
            if (status != STATUS_INIT)
                return;
            status = STATUS_SYNC;
            srv_addr = id;
        }
        call Forge.sync(prepare_packet(&msg));
        e = call RadioAMSend.send(id, &msg, sizeof(mote_protocol_t));
        if (e != SUCCESS)
            call Leds.led0Toggle();
    }

    event void Interpreter.response(uint16_t id, int8_t rssi)
    {
        cln_status_t s;
        int8_t srv_rssi;

        atomic {
            if (status != STATUS_EXECUTING && status != STATUS_MOVING)
                return;
            s = status;
            srv_rssi = stored_rssi;
        }
        srv_rssi = elaborate_rssi(srv_rssi, rssi);
        atomic elab_rssi = srv_rssi;

        if (s == STATUS_EXECUTING) {
            post start_moving();
        } else {
            post check_execution();
        }
    }

    /* Unused: this is server stuff */
    event void Interpreter.ping(uint16_t id) {}
    event void Interpreter.baseCommandExecuted(error_t err,
                                               uint8_t *buffer,
                                               size_t len) {}
    event void Interpreter.unknown_command(uint16_t id, mote_protocol_t *msg) {}

}

