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

        interface Computation as Average;

    }

}

implementation {

    typedef enum {
        STATUS_INIT = 0,
        STATUS_RECEPTIVE,
        STATUS_SYNCING,
        STATUS_MOVING,
        STATUS_STOPPING,
        STATUS_TURN_MOVING
    } cln_status_t;

    static int8_t stored_rssi;  /* Last RSSI value */
    static struct {
        int8_t value;   /* Threshold */
        uint8_t window; /* Threshold window */
    } target_rssi;
    static cln_status_t status = STATUS_INIT;   /* Status of the client */
    static am_addr_t remote_id; /* Remote control identifier */
    static int16_t stored_temp; /* Last Temperature value */
    static bool sending = FALSE;    /* The mote is sending temperature */
    static message_t message;
    static uint8_t myid = unique(CYNAR_UNIQUE);
    static bool backward = FALSE;   /* Backward moving flag */

    void turn_and_go(void)
    {
        atomic status = STATUS_TURN_MOVING;
        call NxtCommands.turn[myid](ROBOT_SPEED, 180);
    }

    void move_on(void)
    {
        atomic status = STATUS_MOVING;
        call NxtCommands.move[myid](ROBOT_SPEED);
    }

    void approach(void)
    {
        if (backward)
            turn_and_go();
        else
            move_on();
    }

    void leave(void)
    {
        if (backward)
            move_on();
        else
            turn_and_go();
    }

    void stop(void)
    {
        atomic status = STATUS_STOPPING;
        call NxtCommands.stop[myid](FALSE);
    }

    event void Average.output_value(int32_t v)
    {
        int8_t value;
        uint8_t window;

        atomic {
            value = target_rssi.value;
            window = target_rssi.window;
        }

        if (v > value) {
            leave();
        } else if (v > value - window) {
            stop();
        } else {
            approach();
        }
    }

    event void NxtCommands.done[uint8_t id](error_t err, uint8_t *buffer,
                                            size_t len)
    {
        cln_status_t s;

        if (err == SUCCESS) {
            atomic {
                s = status;
            }
            switch (s) {
                case STATUS_TURN_MOVING:
                case STATUS_MOVING:
                case STATUS_STOPPING:
                    break;
                default:
                    call Leds.led0Toggle();
            }
        } else {
            call Leds.led0Toggle();
        }
        atomic status = STATUS_RECEPTIVE;
    }

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

    event void Timeout.fired()
    {
    }

    event void Resend.fired()
    {
        error_t e;
        int16_t temp;
        static uint32_t cnt = 0;

        if (cnt++ >= NRESEND) {
            call Resend.stop();
            sending = FALSE;
        } else {
            atomic {
                temp = stored_temp;
                call Forge.response(prepare_packet(&message), temp);
            }
            e = call RadioAMSend.send(TOS_BCAST_ADDR, &message,
                                      sizeof(mote_protocol_t));
            if (e != SUCCESS)
                call Leds.led0Toggle();
        }
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

    event void Interpreter.reachThreshold(uint16_t id, int8_t value,
                                          uint8_t window)
    {
        cln_status_t s;
        int8_t rssi;

        atomic {
            if (status != STATUS_RECEPTIVE)
                return;
            s = status;
            status = STATUS_SYNCING;
            target_rssi.value = value;
            target_rssi.window = window;
            rssi = stored_rssi;
        }
        call Leds.led2Toggle();
        call Average.input_value(rssi);
    }

    event void Interpreter.sync(uint16_t id)
    {
        atomic {
            if (status != STATUS_INIT)
                return;
            remote_id = id;
            status = STATUS_RECEPTIVE;
        }
    }

    event void Read.readDone(error_t e, uint16_t temp) 
    {
        if (e != SUCCESS) {
            call Leds.led0Toggle();
        }
        atomic stored_temp = temp / 100 - 40;
        call Resend.startPeriodic(RESEND_PERIOD);
    }

    event void Interpreter.sendTemperature(uint16_t id)
    {
        atomic {
            if (sending)
                return;
            if (status != STATUS_RECEPTIVE)
                return;
            if (remote_id != id)
                return;
            sending = TRUE;
        }
        call Read.read();
    }

    /* Unused */
    event void Interpreter.response(uint16_t id, int16_t temperature) {}
    event void Interpreter.baseCommandExecuted(error_t err,
                                               uint8_t *buffer,
                                               size_t len) {}
    event void Interpreter.unknown_command(uint16_t id, mote_protocol_t *msg) {}
    event void Interpreter.ping(uint16_t id) {}

}

