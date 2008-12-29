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

module NxtTransmitterP {

    provides interface NxtTransmitter;
    uses {
        interface Resource;
        interface UartStream;
    }

}

implementation {

    static enum {
        STATUS_READY,
        STATUS_TRANSMITTING,
        STATUS_RECEIVING
    } status;
    static uint8_t *ext_buffer;
    static size_t ext_len;
    static bool ext_ack;
    static error_t ext_error;

    task void receiveDone(void);

    command error_t NxtTransmitter.send(uint8_t *buffer, size_t len, bool ack)
    {
        error_t ret;

        atomic {
            if (status != STATUS_READY) {
                return FAIL;
            }
            status = STATUS_TRANSMITTING;
        }
        ret = call Resource.request();
        if (ret != SUCCESS) {
            atomic status = STATUS_READY;
        } else {
            atomic {
                ext_buffer = buffer;
                ext_len = len;
                ext_ack = ack;
            }
        }
        return ret;
    }

    event void Resource.granted()
    {
        uint8_t *buf;
        size_t len;

        atomic {
            buf = ext_buffer;
            len = ext_len;
        }
        call UartStream.send(buf, len);
    }

    async event void UartStream.sendDone(uint8_t *buf, uint16_t len,
                                         error_t error)
    {
        bool ack;

        if (error != SUCCESS) {
            call Resource.release();
            atomic ext_error = error;
            post receiveDone();
        } else {
            atomic {
                ack = ext_ack;
                status = ack ? STATUS_RECEIVING : STATUS_READY;
            }
            if (ack) {
                call UartStream.receive(buf, len);
            }
        }
    }

    async event void UartStream.receivedByte(uint8_t byte)
    {
    }

    async event void UartStream.receiveDone(uint8_t *buf, uint16_t len,
                                            error_t error)
    {
        atomic {
            ext_error = error;
        }
        post receiveDone();
    }

    task void receiveDone(void) {
        uint8_t *buffer;
        uint8_t len;
        error_t error;

        atomic {
            status = STATUS_READY;
            buffer = ext_buffer;
            len = ext_len;
            error = ext_error;
        }
        signal NxtTransmitter.done(buffer, len, error);
    }

}

