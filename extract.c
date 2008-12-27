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

#include "extract.h"

bool ex_parse(const uint8_t *buffer, const char *fmt, uint32_t *offset, uint32_t *ret)
{
    /* Two separated words: 0 for the format; 1 for the buffer */
    uint16_t *offs;
    const char *f;

    offs = (uint16_t *)offset;
    if (*(f = fmt + offs[0]) == 0)
        return FALSE;
    buffer += offs[1];
    switch (*f) {
    case 'b':   /* Byte (8) */
        *ret = *buffer;
        offs[1] ++;
        break;
    case 'h':   /* Half word (16) */
        *ret = *(uint16_t *)buffer;
        offs[1] += 2;
        break;
    case 'w':   /* Word (32) */
        *ret = *(uint32_t *)buffer;
        offs[1] += 4;
        break;
    }
    offs[0]++;
    return TRUE;
}

bool ex_build(uint8_t *buffer, const char *fmt, uint32_t *offset, uint32_t val)
{
    uint16_t *offs;
    const char *f;

    offs = (uint16_t *)offset;
    if (*(f = fmt + offs[0]) == 0)
        return FALSE;
    buffer += offs[1];
    switch (*f) {
    case 'b':   /* Byte (8) */
        *buffer = val;
        offs[1] ++;
        break;
    case 'h':   /* Half word (16) */
        *((uint16_t *)buffer) = val;
        offs[1] += 2;
        break;
    case 'w':   /* Word (32) */
        *((uint32_t *)buffer) = val;
        offs[1] += 4;
        break;
    }
    offs[0]++;

    return TRUE;
}


