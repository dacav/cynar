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
        STATUS_ACTIVE,
        STATUS_REACHTH_0,   /* Before starting */
        STATUS_REACHTH_1    /* Moving */
    } cln_status_t;

    static am_addr_t srv_addr;
    static cln_status_t status;
    static int8_t last_rssi;
    static uint8_t myid = unique(CYNAR_UNIQUE);

    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    bool working_condition(int8_t remote)
    {
        int8_t local;

        atomic local = last_rssi;
        local = (local + remote) / 2;
        /* TODO here working condition! For the moment it's always time
         * to go forward. Retur FALSE in order to stop the robot.
         */
        return TRUE;
    }

    task void start_reachthreshold(void)
    {
        uint32_t rnd;

        atomic status = STATUS_REACHTH_0;
        rnd = call Random.rand32() % PINGTIME;
        call PingTimer.startOneShot(rnd);
    }

    task void ping(void)
    {
        message_t msg;
        am_addr_t addr;

        atomic addr = srv_addr;
        call Forge.ping(prepare_packet(&msg));
        if (call RadioAMSend.send(addr, &msg, sizeof(mote_protocol_t))) {
            call Leds.led0Toggle();
            call PingTimer.startOneShot(PINGTIME);
        }
    }

    event void Boot.booted()
    {
        if (call RadioControl.start() != SUCCESS) {
            call Leds.led0On();
        }
    }

    event void PingTimer.fired()
    {
        post ping();
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
            atomic {
                if (sender == srv_addr)
                    last_rssi = call CC2420Packet.getRssi(msg);
            }
            call Interpreter.interpret(sender, (mote_protocol_t *)payload);
        }
        return msg;
    }

    event void Dispatcher.inconsistent(disp_status_t x)
    {
    }
        
    event void RadioControl.startDone(error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0On();
            return;
        }
    }

    event void RadioControl.stopDone(error_t e)
    {
    }

    event void RadioAMSend.sendDone(message_t *msg, error_t e)
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
            call PingTimer.startOneShot(PINGTIME);
        } else {
            call Leds.led1Toggle();
        }
    }

    event void Interpreter.reachThreshold(uint16_t id, uint8_t thershold)
    {
        cln_status_t s;

        atomic {
            s = status;
        }
        switch (s) {
        case STATUS_INIT:
            return;
        case STATUS_ACTIVE:
            post start_reachthreshold();
            break;
        case STATUS_REACHTH_0:
        case STATUS_REACHTH_1:
            break;
        }
        return;
    }

    event void Interpreter.baseCommandExecuted(error_t err,
                                               uint8_t *buffer,
                                               size_t len)
    {
    }

    event void Interpreter.unknown_command(uint16_t id,
                                           mote_protocol_t *msg)
    {
    }

    event void Interpreter.sync(uint16_t id) 
    {
        atomic {
            srv_addr = id;
            status = STATUS_ACTIVE;
        }
        call Leds.led2On();
    }

    event void Interpreter.response(uint16_t id, int8_t rssi)
    {
        am_addr_t srv;
        cln_status_t s;
        bool work;

        atomic {
            srv = srv_addr;
            s = status;
        }
        if (srv != id)
            return;
        work = working_condition(rssi);
        if (s == STATUS_REACHTH_0) {
            if (work)
                call NxtCommands.move[myid](ROBOT_SPEED);
        } else {
            if (!work)
                call NxtCommands.stop[myid](TRUE);
        }
    }

    /* Unused: this is server stuff */
    event void Interpreter.ping(uint16_t id) {}

}

