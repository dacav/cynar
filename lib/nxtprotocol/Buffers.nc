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

interface Buffers {

    /** Extraciton of various length word data from a little endian buffer
     *
     * @note This function doesn't care about the buffer length, as it should be
     *       correctly specified into the fmt field.
     *
     * @param buffer The buffer containing the data;
     * @param fmt The extraction format to use;
     * @param offset A internal use offset that must be initialized to zero;
     * @param ret A pointer to the memory area that will contain the extracted
     *            data;
     * @return TRUE if there's still something to extract, FALSE otherwise.
     */
    command error_t parse(const uint8_t *buffer, const char *fmt,
                          uint32_t *offset, uint32_t *ret);

    /** Insertion of various length word data to a little endian buffer
     *
     * @note This function doesn't care about the buffer length, as it should be
     *       correctly specified into the fmt field.
     *
     * @param buffer The buffer containing the data;
     * @param fmt The extraction format to use;
     * @param offset A internal use offset that must be initialized to zero;
     * @param val The value to be stored;
     * @return TRUE if there's still something to extract, FALSE otherwise.
     */
    command error_t build(uint8_t *buffer, const char *fmt, uint32_t *offset, 
                          uint32_t val);

}

