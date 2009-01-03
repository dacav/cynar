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

typedef enum {
    STATUS_INIT = 0,
    STATUS_ACTIVATING,
    STATUS_SHUTDOWN,
    STATUS_IDLE,
    STATUS_UART_ONLY,   
    STATUS_UART_SHARE,
    STATUS_UART_FINISH
} disp_status_t;

/** Since the dispatcher mechanism uses a two-level indirection, there may be
 * some inconsistent states. This cases will be signaled through the
 * inconsistent event.
 */
interface Dispatcher {

    /** Signals an inconsistence
     *
     * @param s The previous status
     */
    event void inconsistent(disp_status_t s);

    /** Resets dispatcher status
     *
     * This command will reset the internal status of the Dispatcher
     * component, but it doesn't fix the problem.
     */
    command void reset(void);

}

