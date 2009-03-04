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

generic module AveragerP(size_t N) {
    
    provides interface Computation;

}
implementation {

    static int32_t buffer[N], prev;
    static int i, nwrite;

    void average(int32_t k, int32_t x)
    {
        if (k == 0)
            prev = buffer[x];
        else
            prev = (prev + buffer[x]) / 2;
    }

    void scan()
    {
        int j, k, n;

        n = i - nwrite;
        k = 0;
        if (n < 0) {
            for (j = N + n; j < N; j++)
                average(k++, j);
            for (j = 0; j < i; j++)
                average(k++, j);
        } else {
            for (j = i - nwrite; j < i; j++)
                average(k++, j);
        }
    }

    void insert(int32_t x)
    {
        buffer[i++] = x;
        i %= N;
        if (nwrite < N)
            nwrite++;
    }

    task void run(void)
    {
        scan();
        signal Computation.output_value(prev);
    }

    command void Computation.input_value(int32_t val)
    {
        insert(val);
        post run();
    }

}

