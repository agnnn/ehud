/*
 * copyright (c) 2010, Department of Information Engineering, University of Padova.
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
 * Application for the sensors of the WSN that have to reply to the ping messages
 * sent by the Basestation.
 *
 * @date 09/01/2011 10:04
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */

module FixedNodeP
{
	uses
	{
		interface Boot;
		interface Leds;

		interface CC2420Packet as InfoRadio;
		interface CC2420Config;
		interface SplitControl as AMCtrlRadio;
		interface AMSend as AMSendRadioR;
		interface Receive;
	}
}


implementation
{
	message_t radioPacket;

	radio_msg rm;

	bool lockedRadio;

	task void sendBroadcast();


	/*************************************** INIT **************************************/

	event void Boot.booted() {
		call Leds.set(000);

		lockedRadio = FALSE;

		call CC2420Config.setChannel(CHANNEL_RADIO);
		call CC2420Config.sync();
	}

	event void CC2420Config.syncDone(error_t error) {
		if (error == SUCCESS) {
			call AMCtrlRadio.start();
		}
		else {
			call CC2420Config.sync();
		}
	}

	event void AMCtrlRadio.startDone(error_t error) {
		if (error == SUCCESS) {
			call InfoRadio.setPower(&radioPacket,POWER_RADIO);
		}
		else {
			call AMCtrlRadio.start();
		}
	}

	event void AMCtrlRadio.stopDone(error_t error) {
	}

	/****************************** RADIO: ReceiveMeasurement ********************************/

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		call Leds.led0Toggle();

		if ((len == sizeof(broadcast_msg))) {
			broadcast_msg* bm = (broadcast_msg*)payload;
			if (bm->id==BASE_STATION_ID)
			{			
				atomic
				{
					rm.id  = bm -> id;
					rm.counter = bm -> counter;
				}
			
				post sendBroadcast();
			}
		}
		return msg;
	}


	task void sendBroadcast() {
		if (!lockedRadio) {
			broadcast_msg* bm = (broadcast_msg*)(call AMSendRadioR.getPayload(&radioPacket, sizeof(broadcast_msg)));
			bm->id = TOS_NODE_ID;
			bm->counter = rm.counter;
			if (call AMSendRadioR.send(AM_BROADCAST_ADDR, &radioPacket, sizeof(broadcast_msg)) == SUCCESS) {
				lockedRadio = TRUE;
			}
		}
	}

	event void AMSendRadioR.sendDone(message_t* msg, error_t error) {
		if (&radioPacket == msg) {
				lockedRadio = FALSE;
		}
	}
}
