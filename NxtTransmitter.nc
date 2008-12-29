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

interface NxtTransmitter {

    /* Send the required bunch of data through the uart.
     *
     * This code automatically requires the uart resources and releases it
     * after the transfer has been completed, then it signals the done event
     *
     * @param buffer The buffer to be sent
     * @param len The length of the buffer
     * @param ack If setted to true, the system waits for an acknowledgment.
     *
     * @return SUCCESS if everything works.
     */
    command error_t send(uint8_t *buffer, size_t len, bool ack);

    event void done(uint8_t *buffer, size_t len, error_t err);

}

