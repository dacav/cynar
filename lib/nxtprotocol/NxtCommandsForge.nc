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

#include "nxtprotocol.h"

interface NxtCommandsForge {

    /** Encodes a halt command
     *
     * The "halt" command will shut down the Nxt brick
     *
     * @param msg The message to edit
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command void halt(nxt_protocol_t *msg);

    /** Encodes a temporized rotation
     *
     * The "rotate time" command will rotate the selected motor(s) for a given
     * time. The three least significative bits of the motors parameter will
     * allow the motor selection (Put in OR: 0x01 for the first motor, 0x02 for the
     * second, 0x04 for the third)
     *
     * @param msg The message to edit
     * @param speed The speed value, from -100 to 100
     * @param time The time (millseconds)
     * @param brake Set to TRUE in order to brake
     * @param motors Motors selection
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command void rotateTime(nxt_protocol_t *msg, int8_t speed,
                            uint32_t time, bool brake, uint8_t motors);

    /** Encodes an angular rotation
     *
     * The "rotate angle" command will rotate the selected motor(s) of a given
     * angle. The three least significative bits of the motors parameter will
     * allow the motor selection (Put in OR: 0x01 for the first motor, 0x02 for the
     * second, 0x04 for the third)
     *
     * @param msg The message to edit
     * @param speed The speed value, from -100 to 100
     * @param angle The angle of rotation (degrees)
     * @param brake Set to TRUE in order to brake
     * @param motors Motors selection
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
     command void rotateAngle(nxt_protocol_t *msg, int8_t speed,
                                uint32_t angle, bool brake, uint8_t motors);

    /** Encodes a stop
     *
     * The "stop rotation" command will stop the selected motor(s)
     * The three least significative bits of the motors parameter will allow
     * the motor selection (Put in OR: 0x01 for the first motor, 0x02 for the
     * second, 0x04 for the third)
     *
     * @param msg The message to edit
     * @param brake Set to TRUE in order to brake
     * @param motors Motors selection
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
     command void stopRotation(nxt_protocol_t *msg, bool brake,
                                  uint8_t motors);
    /** Encodes a movement
     *
     * The "move" command enables a straight movement for the entire NXT. The
     * movement will continue until the next request involving motors 0 and
     * 2.
     *
     * @param msg The message to edit
     * @param speed The speed value, from -100 to 100
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
     command void move(nxt_protocol_t *msg, int8_t speed);

    /** Encodes a movement
     *
     * The "turn" command enables a turning movement for the entire NXT. The
     * movement will be related to motors 0 and 2.
     *
     * @param msg The message to edit
     * @param speed The speed value, from -100 to 100
     * @param degrees The turning angle
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command void turn(nxt_protocol_t *msg, int8_t speed,
                         uint32_t degrees);

    /** Encodes a movement stop command
     *
     * The "stop" command will stop motors 0 and 2. It's handy for stopping a
     * movement required by "move" and "turn" commands. It's equivalent to a
     * "stop rotation" command involving motors 0 and 2.
     *
     * @param msg The message to edit
     * @param brake Set to TRUE in order to brake
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command void stop(nxt_protocol_t *msg, bool brake);

    command void print_temperature(nxt_protocol_t *msg, uint16_t id,
                                   int16_t temp);
}

