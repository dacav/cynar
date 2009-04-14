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

/** Interface for commands interpretation
 *
 * The interpret requires a pointer to a mote_protocol_t structure and the
 * identifier of the message's sender. The structure must contain a well
 * formed mote protocol message.
 *
 * The message interpretation will be achieved by raising an event that
 * will contain the parameters.
 *
 * @note    The implementing component is MoteCommandsParserP. It
 *          automatically delivers all NxtProtocol commands through the
 *          Dispatcher.
 * @note    This interface will be extended with possible protocol
 *          extensions.
 */
interface MoteCommandsInterpreter {

    /** Command interpretation
     * 
     * @param clid  Sending client identifier, will be forwarded to raised
     *              events.
     * @param msg   A pointer to the message structure.
     * @return      In case of failed Nxt delivered message, this function
     *              may return FAIL.
     */
    command error_t interpret(uint16_t clid, mote_protocol_t *msg);

    /** Reach threshold event
     *
     * @param clid      Client identifier;
     * @param threshold RSSI threshold to be reached;
     * @param window    RSSI boundaries to threshold;
     */
    event void reachThreshold(uint16_t clid, int8_t thershold, uint8_t window);

    /** Sending temperature request event
     *
     * @param clid  Client identifier;
     */
    event void sendTemperature(uint16_t clid);

    /** Raw nxt command execution
     *
     * @param err       SUCCESS if the command execution worked;
     * @param buffer    The buffer will contain any data returned by the Nxt
     *                  or will be NULL if the command doesn't require any
     *                  answer;
     * @param len       Buffer length, or 0 if the buffer is NULL.
     */
    event void baseCommandExecuted(error_t err, uint8_t *buffer, size_t len);

    /** Synchronization event
     *
     * This event represents a generic, not parametrized, remote
     * synchronization signal may be used at user discretion.
     *
     * @param clid  Client identifier.
     */
    event void sync(uint16_t clid);

    /** Ping event
     *
     * This event represents a not parametrized ping signal, and should be
     * used as ICMP-like protocol, although it may be used at user
     * discretion.
     *
     * @param clid  Client identifier.
     */
     event void ping(uint16_t clid);

    /** Beacon response for reachThreshold command.
     *
     * The beacon sender is supposed to retrieve the rssi value from the
     * client transmission, encode it into the response and send it back.
     *
     * @param clid  Client identifier;
     * @param rssi  RSSI value.
     */
     event void response(uint16_t clid, int16_t rssi);

    /** Unknown command detected
     *
     * If the interpreter isn't able to mess with the message, this event
     * will be raised.
     *
     * @param clid  Client identifier;
     * @param msg   The same, unaltered command.
     */
     event void unknown_command(uint16_t id, mote_protocol_t *msg);

}

