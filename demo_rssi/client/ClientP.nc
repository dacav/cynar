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
        interface Timer<TMilli> as Timeout;
        interface Timer<TMilli> as Resend;

        /* Error management for Nxt Dispatcher */
        interface Dispatcher;

        /* High level mote commands */
        interface MoteCommandsInterpreter as Interpreter;
        interface MoteCommandsForge as Forge;

        interface Leds;
        interface Read<uint16_t>;

    }

}

implementation {

    typedef enum {
        STATUS_WAITING = 0,
        STATUS_MOVING,
        STATUS_REACHED
    } cln_status_t;

    static int8_t stored_rssi;
    static int8_t target_rssi;
    static cln_status_t status;
    static am_addr_t srv_addr;
    static int16_t stored_temp;
    static message_t message;
    static uint8_t myid = unique(CYNAR_UNIQUE);

    mote_protocol_t *prepare_packet(message_t *msg)
    {
        call RadioPacket.clear(msg);
        return call RadioPacket.getPayload(msg, sizeof(mote_protocol_t));
    }

    bool keep_moving(void)
    {
        int8_t e,t;

        atomic {
            e = stored_rssi;
            t = target_rssi;
        }

        return e > t;
    }

    void start_moving(void)
    {
        if (!keep_moving())
            return;
        call NxtCommands.move[myid](ROBOT_SPEED);
        atomic status = STATUS_MOVING;
    }

    void check_execution(void)
    {
        if (keep_moving())
            return;
        call NxtCommands.stop[myid](TRUE);
        atomic status = STATUS_REACHED;

        call Read.read();
    }

    event void Read.readDone(error_t e, uint16_t temp) 
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        }
        atomic stored_temp = temp / 100 - 40;
        call Resend.startPeriodic(RESEND_PERIOD);
    }

    task void run_execution(void)
    {
        cln_status_t s;

        call Timeout.stop();
        call Timeout.startOneShot(SECURITY_TIMEOUT);
        atomic s = status;
        if (s == STATUS_WAITING) {
            start_moving();
        } else {
            check_execution();
        }
    }

    event void Boot.booted()
    {
        if (call RadioControl.start() != SUCCESS)
            call Leds.led0Toggle();
    }

    event void Timeout.fired()
    {
        cln_status_t s;

        atomic s = status;
        if (s == STATUS_MOVING) {
            call NxtCommands.stop[myid](TRUE);
            atomic status = STATUS_WAITING;
        }
    }

    event void Resend.fired()
    {
        am_addr_t addr;
        error_t e;
        int16_t temp;
        static uint32_t cnt = 0;

        if (cnt++ >= NRESEND) {
            call Resend.stop();
        } else {
            atomic {
                temp = stored_temp;
                addr = srv_addr;
                call Forge.response(prepare_packet(&message), temp);
            }
            e = call RadioAMSend.send(addr, &message, sizeof(mote_protocol_t));
            if (e != SUCCESS)
                call Leds.led0Toggle();
        }
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer,
                                            size_t len)
    {
        if (err != SUCCESS)
            call Leds.led0Toggle();
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
        }
        call Leds.led2On();
    }

    event void RadioControl.stopDone(error_t e)
    {
    }

    event void RadioAMSend.sendDone(message_t *msg, error_t e)
    {
        if (e != SUCCESS)
            call Leds.led0Toggle();
        call Leds.led1Toggle();
    }

    event void Interpreter.reachThreshold(uint16_t id, uint8_t thershold)
    {
        cln_status_t s;

        atomic {
            target_rssi = thershold;
            s = status;
            srv_addr = id;
        }
        if (s == STATUS_REACHED)
            return;
        call Leds.led2Toggle();
        post run_execution();
    }

    /* Unused */
    event void Interpreter.response(uint16_t id, int16_t temperature) {}
    event void Interpreter.baseCommandExecuted(error_t err,
                                               uint8_t *buffer,
                                               size_t len) {}
    event void Interpreter.unknown_command(uint16_t id, mote_protocol_t *msg) {}
    event void Interpreter.ping(uint16_t id) {}
    event void Interpreter.sync(uint16_t id) {}

}

