/*
 * Copyright (c) 2010, Department of Information Engineering, University of Padova.
 * All rights reserved.
 *
 * This file is part of Ehud.
 *
 * Ehud is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Ehud is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Ehud.  If not, see <http://www.gnu.org/licenses/>.
 *

 * ===================================================================================
 */

/**
 *
 * Configuration file of the module FixedNodeP.nc
 *
 * @date 09/01/2011 10:04
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */
									// /usr/msp430/include
#include "../TmoteComm.h"

//#define DEBUG

configuration FixedNodeC
{
}


implementation
{
	components MainC;
	components LedsC;

	components FixedNodeP as App;

	components CC2420ControlC;
	components CC2420ActiveMessageC as RAM;

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;

	App.CC2420Config -> CC2420ControlC.CC2420Config;
	App.InfoRadio -> RAM;
	App.AMCtrlRadio -> RAM;
	App.AMSendRadioR   -> RAM.AMSend[AM_RADIO_MSG];
	App.Receive  -> RAM.Receive[AM_RADIO_MSG];

}
