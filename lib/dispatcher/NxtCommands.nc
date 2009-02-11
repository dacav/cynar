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

interface NxtCommands {

    /** Launches a halt command
     *
     * The "halt" command will shut down the Nxt brick
     *
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */

    command error_t halt();

    /** Launches a temporized rotation
     *
     * The "rotate time" command will rotate the selected motor(s) for a given
     * time. The three least significative bits of the motors parameter will
     * allow the motor selection (Put in OR: 0x01 for the first motor, 0x02 for the
     * second, 0x04 for the third)
     *
     * @param speed The speed value, from -100 to 100
     * @param time The time (millseconds)
     * @param brake Set to TRUE in order to brake
     * @param motors Motors selection
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t rotateTime(int8_t speed, uint32_t time, bool brake,
                               uint8_t motors);

    /** Launches an angular rotation
     *
     * The "rotate angle" command will rotate the selected motor(s) of a given
     * angle. The three least significative bits of the motors parameter will
     * allow the motor selection (Put in OR: 0x01 for the first motor, 0x02 for the
     * second, 0x04 for the third)
     *
     * @param speed The speed value, from -100 to 100
     * @param angle The angle of rotation (degrees)
     * @param brake Set to TRUE in order to brake
     * @param motors Motors selection
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t rotateAngle(int8_t speed, uint32_t angle, bool brake,
                                uint8_t motors);

    /** Launches a stop
     *
     * The "stop rotation" command will stop the selected motor(s)
     * The three least significative bits of the motors parameter will allow
     * the motor selection (Put in OR: 0x01 for the first motor, 0x02 for the
     * second, 0x04 for the third)
     *
     * @param brake Set to TRUE in order to brake
     * @param motors Motors selection
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t stopRotation(bool brake, uint8_t motors);

    /** Launches a movement
     *
     * The "move" command enables a straight movement for the entire NXT. The
     * movement will continue until the next request involving motors 0 and
     * 2.
     *
     * @param speed The speed value, from -100 to 100
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t move(int8_t speed);

    /** Launches a movement
     *
     * The "turn" command enables a turning movement for the entire NXT. The
     * movement will be related to motors 0 and 2.
     *
     * @param speed The speed value, from -100 to 100
     * @param degrees The turning angle
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t turn(int8_t speed, uint32_t degrees);

    /** Launches a movement stop command
     *
     * The "stop" command will stop motors 0 and 2. It's handy for stopping a
     * movement required by "move" and "turn" commands. It's equivalent to a
     * "stop rotation" command involving motors 0 and 2.
     *
     * @param brake Set to TRUE in order to brake
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t stop(bool brake);

    command error_t print_temperature(uint16_t id, int16_t temp);

    /** Launches a remote command
     *
     * This primitive allows the component to delegate the command forging
     * to a different entity. This may be used for remote command
     * transmission.
     *
     * @warning The dispatcher component truncates the command to the first
     *          6 bytes. This behaviour may change in a future release
     *
     * @param cmd The mesage to be executed;
     * @return SUCCESS if the buffer is large enough to contain the command,
     *         FAIL otherwise
     */
    command error_t exec(nxt_protocol_t *cmd);

    /** The component has achieved the execution
     *
     * @note Depending on the error flag (err) the buffer may be available or
     *       not.
     * @param err SUCCESS if the execution succeded
     * @param buffer The buffer containing returning data (if any)
     * @param len The buffer's length
     */
    event void done(error_t err, uint8_t *buffer, size_t len);

}



