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
 *
 * Application for the Basestation that sent ping messages in broadcast to the Agents.
 *
 * @date 09/01/2011 10:04
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */

module BaseStationP
{
	uses
	{
		interface Boot;
		interface Leds;
	
		interface Timer<TMilli> as SamplingRadioClock;

		interface SplitControl as AMCtrlSerial;
		interface AMSend as AMSendSerialR;

		interface CC2420Packet as InfoRadio;
		interface CC2420Config;
		interface SplitControl as AMCtrlRadio;
		interface AMSend as AMSendRadioR;
		interface Receive as ReceiveControl;
		interface Receive;
		
		interface Queue<radio_msg> as QueueBroadcast;
	}
}


implementation
{
	message_t serialPacket;
	message_t radioPacket;

	bool lockedSerial;
	bool lockedRadio;

	uint16_t counterDiffRadioPckg;
	uint16_t counterSameRadioPckg;

	task void sendSerialR();
	task void sendBroadcast();

	uint8_t cmd;

	/*************************************** INIT **************************************/

	event void Boot.booted() {
		call Leds.set(000);

		lockedRadio = FALSE;
		lockedSerial = FALSE;

		counterDiffRadioPckg = 0;

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
			call AMCtrlSerial.start();
		}
		else {
			call AMCtrlRadio.start();
		}
	}

	event void AMCtrlSerial.startDone(error_t error) {
		if (error == SUCCESS) {
			call InfoRadio.setPower(&radioPacket,POWER_RADIO);
			call Leds.led1On();
		}
		else {
			call AMCtrlSerial.start();
		}
	}

	event void AMCtrlRadio.stopDone(error_t error) {
	}

	event void AMCtrlSerial.stopDone(error_t error) {
	}

	/****************************** RADIO: ReceiveMeasurement ********************************/

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		radio_msg rm;
		call Leds.led0Toggle();

		if (len == sizeof(broadcast_msg)) {
			broadcast_msg* bm = (broadcast_msg*)payload;
			atomic
			{
				rm.id  = bm -> id;
				rm.counter = bm -> counter;
				rm.rssi    = call InfoRadio.getRssi(msg);
				rm.rss     = rm.rssi + RSSI_OFFSET;
				rm.lqi     = call InfoRadio.getLqi(msg);
				rm.channel = call CC2420Config.getChannel();
				rm.power   = POWER_RADIO;
			}
			if((call QueueBroadcast.size()) < QUEUE_SIZE) {
				call QueueBroadcast.enqueue(rm);
			}
			post sendSerialR();
		}
		return msg;
	}

	/************************* SERIAL: SAMSendMeasurement *****************************/

	task void sendSerialR() {
		if(lockedSerial){}
		else {
			if(! call QueueBroadcast.empty()) {
				radio_msg rm = call QueueBroadcast.dequeue();
				radio_msg* rmp = (radio_msg*)call AMSendSerialR.getPayload(&serialPacket, sizeof(radio_msg));

				if (rmp == NULL) {return;}

				atomic
				{
					rmp->id  = rm.id;
					rmp->counter = rm.counter;
					rmp->rss    = rm.rss;
					rmp->rssi     = rm.rssi;
					rmp->lqi     = rm.lqi;
					rmp->channel = rm.channel;
					rmp->power   = rm.power;
				}

			#ifdef DEBUG
			printf("ID: %u \n",rm.id);
			printf("counter: %u \n",rm.counter);
			printf("rss: %u \n",rm.rss);
			printfflush();
			#endif

				if (call AMSendSerialR.send(AM_BROADCAST_ADDR, &serialPacket, sizeof(radio_msg)) == SUCCESS) {
					lockedSerial = TRUE;
				}
			}
		}

		if(! call QueueBroadcast.empty()) {
			post sendSerialR();
		}
	}

	event void AMSendSerialR.sendDone(message_t* msg, error_t error) {
		if (&serialPacket == msg) {
			lockedSerial = FALSE;
			//call Leds.led0Toggle();
		}
	}
	
	/******************************* Radio *****************************/

	event void SamplingRadioClock.fired() {
		if(counterSameRadioPckg<MAX_PCKG) {
			post sendBroadcast();
		}
	}

	task void sendBroadcast() {
		if (!lockedRadio) {
			broadcast_msg* bm = (broadcast_msg*)(call AMSendRadioR.getPayload(&radioPacket, sizeof(broadcast_msg)));
			bm->id = BASE_STATION_ID;
			bm->counter = counterDiffRadioPckg;
			if (call AMSendRadioR.send(AM_BROADCAST_ADDR, &radioPacket, sizeof(broadcast_msg)) == SUCCESS) {
				lockedRadio = TRUE;
			}
		}
	}

	event void AMSendRadioR.sendDone(message_t* msg, error_t error) {
		if (&radioPacket == msg) {
			counterSameRadioPckg++;
			lockedRadio = FALSE;
		}
	}
	
		/************************* RADIO: AMReceiveControl *****************************/

	event message_t* ReceiveControl.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(mote_ctrl_msg)) {
			mote_ctrl_msg* rcm = (mote_ctrl_msg*)payload;

			uint8_t newCmd = rcm->work;

			if(cmd!=newCmd) {
				switch(newCmd) {
					case START:
					{
						counterSameRadioPckg = 0;
						counterDiffRadioPckg++;
						call SamplingRadioClock.startPeriodic(TIMER_SEND);
						call Leds.set(111);
						cmd = newCmd;
						break;
					}
					case STOP:
					{
						call SamplingRadioClock.stop();
						cmd = newCmd;
						break;
					}
				}
			}
		}
		return msg;
	}
}
