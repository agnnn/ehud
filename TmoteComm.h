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
 * Header file.
 *
 * @date 09/01/2011 10:04
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */

#ifndef TMOTE_COMM_H
#define TMOTE_COMM_H

//#define TIMER_RADIO 0xFA0 // [ms] (4 seconds)
//#define TIMER_SENSORS 0x3E80 // [ms] (10 seconds)

typedef nx_struct broadcast_msg
{
  nx_uint16_t id;   // ID of the sensor
  nx_uint16_t counter;  // ID of the sent packet [n-th]
} broadcast_msg;

typedef nx_struct radio_msg 
{
  nx_int16_t  rssi;           // RSSI [dBm] received signal strength indicator
  nx_int16_t  rss;            // RSS [dBm] received signal strength
  nx_int16_t  lqi;            // LQI [dBm] link quality indicator
  nx_uint8_t  channel;        // Transmission frequency 
  nx_uint8_t  power;          // Transmission power [dBm] 
  nx_uint16_t id;         // ID of the sensor
    nx_uint16_t counter;
} radio_msg;

typedef nx_struct mote_ctrl_msg 
{
	nx_uint8_t work;
} mote_ctrl_msg;

typedef enum 
{ 
	START = 0xA,	// Start of receiver activity
	STOP = 0xB,		// Stop of receiver activity
} cmd_t;

enum
{
  BASE_STATION_ID = 0,    // It has to be DIFFERENT from all the agents ID
  RSSI_OFFSET = -35,      // !!!Empiric!!! [dBm]
  QUEUE_SIZE = 30,       // Dimension of the FIFO stack

  TIMER_SEND = 50,    // Clock for the [ms]
  MAX_PCKG = 15,        // Maximum number of packet to send
  CHANNEL_RADIO = 6,  // Radio channel
  POWER_RADIO = 27,   // Power of the radio CC2420 [dBm] 
    
  AM_MOTE_CTRL_MSG = 86,		// ID of mote_ctrl_msg
  AM_RADIO_MSG = 0x29,     // both for radio_msg and p2p_msg
};

#endif
