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

#include <stdio.h>

configuration CynarTestAppC {
}
implementation {

    components MainC,
               DispatcherC,
               CynarTestP,
               LedsC, 
               new TimerMilliC() as Timer0;

    CynarTestP.Boot -> MainC.Boot;
    CynarTestP.NxtCommands -> DispatcherC.NxtCommands;
    CynarTestP.RadioReceive -> DispatcherC.RadioReceive;
    CynarTestP.Dispatcher -> DispatcherC.Dispatcher;
    CynarTestP.RadioControl -> DispatcherC.RadioControl;
    CynarTestP.RadioAMSend -> DispatcherC.RadioAMSend;
    CynarTestP.Timer0 -> Timer0;
    CynarTestP.Leds -> LedsC;

}

