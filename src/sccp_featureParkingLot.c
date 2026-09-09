/*!
 * \file	sccp_featureParkingLot.c
 * \brief	SCCP ParkingLot Class
 * \author	Diederik de Groot <ddegroot [at] users.sf.net>
 * \date	2015-Sept-16
 * \note	This program is free software and may be modified and distributed under the terms of the GNU Public License.
 *		See the LICENSE file at the top of the source tree.
 */
#include "config.h"
#include "common.h"

SCCP_FILE_VERSION(__FILE__, "");

#include "sccp_featureParkingLot.h"

#ifdef CS_SCCP_PARK

#include "sccp_utils.h"
#include "sccp_vector.h"
#include "sccp_device.h"
#include "sccp_line.h"
#include "sccp_threadpool.h"
#	include "sccp_linedevice.h"
#	include "sccp_channel.h"
#	include "sccp_feature.h"
#	include "sccp_labels.h"

static const uint32_t appID = APPID_VISUALPARKINGLOT;

#ifdef HAVE_PBX_APP_H
#  include <asterisk/app.h>
#endif

/* asterisk-11 */
/*
Event: ParkedCall
Privilege: call,all
Timestamp: 1460205775.670404
Exten: 701
Channel: SCCP/10041-0000000e
Parkinglot: default
From: SCCP/10011-0000000f
Timeout: 45
CallerIDNum: 10041
CallerIDName: PHONE4
ConnectedLineNum: <unknown>
ConnectedLineName: <unknown>
Uniqueid: 1460205775.48

Event: UnParkedCall
Privilege: call,all
Timestamp: 1460205785.934545
Exten: 701
Channel: SCCP/10041-0000000e
Parkinglot: default
From: SCCP/10031-00000010
CallerIDNum: 10041
CallerIDName: PHONE4
ConnectedLineNum: <unknown>
ConnectedLineName: <unknown>
Uniqueid: 1460205775.48

Event: ParkedCallGiveUp
Privilege: call,all
Timestamp: 1460819185.922496
Exten: 701
Channel: SCCP/10041-00000001
Parkinglot: default
CallerIDNum: 10041
CallerIDName: PHONE4
ConnectedLineNum: 10011
ConnectedLineName: Diederik-Phone1
UniqueID: 1460819174.54

Event: ParkedCallTimeOut
Privilege: call,all
Timestamp: 1460974082.683646
Exten: 701
Channel: SCCP/10011-00000003
Parkinglot: default
CallerIDNum: 10011
CallerIDName: Diederik-Phone1
ConnectedLineNum: 10031
ConnectedLineName: Diederik-Phone3
UniqueID: 1460974037.17
*/

/* asterisk-13 */
/*
Event: ParkedCall
Privilege: call,all
SequenceNumber: 118
File: parking/parking_manager.c
Line: 676
Func: parked_call_message_response
ParkeeChannel: SCCP/10011-00000001
ParkeeChannelState: 6
ParkeeChannelStateDesc: Up
ParkeeCallerIDNum: 10011
ParkeeCallerIDName: Diederik-Phone1
ParkeeConnectedLineNum: <unknown>
ParkeeConnectedLineName: <unknown>
ParkeeLanguage: en
ParkeeAccountCode: 10011
ParkeeContext: internal
ParkeeExten: 10031
ParkeePriority: 3
ParkeeUniqueid: 1461160476.0
ParkeeLinkedid: 1461160476.0
ParkerDialString: SCCP/10031
Parkinglot: default
ParkingSpace: 701
ParkingTimeout: 45
ParkingDuration: 0

UnParkedCall
Privilege: call,all
SequenceNumber: 1091
File: parking/parking_manager.c
Line: 676
Func: parked_call_message_response
ParkeeChannel: SCCP/10011-00000001
ParkeeChannelState: 6
ParkeeChannelStateDesc: Up
ParkeeCallerIDNum: 10011
ParkeeCallerIDName: Diederik-Phone1
ParkeeConnectedLineNum: <unknown>
ParkeeConnectedLineName: <unknown>
ParkeeLanguage: en
ParkeeAccountCode: 10011
ParkeeContext: internal
ParkeeExten: 10031
ParkeePriority: 3
ParkeeUniqueid: 1461161791.29
ParkeeLinkedid: 1461161791.29
RetrieverChannel: SCCP/10041-00000003
RetrieverChannelState: 6
RetrieverChannelStateDesc: Up
RetrieverCallerIDNum: 10041
RetrieverCallerIDName: PHONE4
RetrieverConnectedLineNum: <unknown>
RetrieverConnectedLineName: <unknown>
RetrieverLanguage: en
RetrieverAccountCode: 79005
RetrieverContext: internal
RetrieverExten: 701
RetrieverPriority: 1
RetrieverUniqueid: 1461161803.31
RetrieverLinkedid: 1461161803.31
ParkerDialString: SCCP/10031
Parkinglot: default
ParkingSpace: 701
ParkingTimeout: 35
ParkingDuration: 10

Event: ParkedCallGiveUp
Privilege: call,all
SequenceNumber: 142
File: parking/parking_manager.c
Line: 676
Func: parked_call_message_response
ParkeeChannel: SCCP/10011-00000001
ParkeeChannelState: 6
ParkeeChannelStateDesc: Up
ParkeeCallerIDNum: 10011
ParkeeCallerIDName: Diederik-Phone1
ParkeeConnectedLineNum: <unknown>
ParkeeConnectedLineName: <unknown>
ParkeeLanguage: en
ParkeeAccountCode: 10011
ParkeeContext: internal
ParkeeExten: 10031
ParkeePriority: 3
ParkeeUniqueid: 1461160476.0
ParkeeLinkedid: 1461160476.0
ParkerDialString: SCCP/10031
Parkinglot: default
ParkingSpace: 701
ParkingTimeout: 36
ParkingDuration: 9

Event: ParkedCallTimeOut
Privilege: call,all
SequenceNumber: 427
File: parking/parking_manager.c
Line: 676
Func: parked_call_message_response
ParkeeChannel: SCCP/10011-00000007
ParkeeChannelState: 6
ParkeeChannelStateDesc: Up
ParkeeCallerIDNum: 10011
ParkeeCallerIDName: Diederik-Phone1
ParkeeConnectedLineNum: <unknown>
ParkeeConnectedLineName: <unknown>
ParkeeLanguage: en
ParkeeAccountCode: 10011
ParkeeContext: park-dial
ParkeeExten: SCCP_10031
ParkeePriority: 1
ParkeeUniqueid: 1461160740.12
ParkeeLinkedid: 1461160740.12
ParkerDialString: SCCP/10031
Parkinglot: default
ParkingSpace: 701
ParkingTimeout: 0
ParkingDuration: 45
*/

/* forward declarations */
struct parkinglot;
typedef struct parkinglot sccp_parkinglot_t;
static void notifyLocked(sccp_parkinglot_t *pl);

typedef struct plslot plslot_t;
typedef struct plobserver plobserver_t;

/* private variables */
struct plslot {
	int slot;
	const char *exten;
	const char *from;
	const char *channel;
	const char *callerid_num;
	const char *callerid_name;
	const char *connectedline_num;
	const char *connectedline_name;
};

struct plobserver {
	sccp_device_t * device;
	uint8_t instance;
	uint32_t transactionId;											/* same width as the id handed to the phone: truncating it to 8 bit could read back as 0 = "no window shown" */
};

struct parkinglot {
	pbx_mutex_t lock;
	char *context;
	boolean_t notifyPending;											/* a notification job is queued on the threadpool and will read the state current when it runs */
	unsigned int inflight;											/* notifications that dropped ->lock to talk to a phone and will re-take it: removal waits until 0 */
	SCCP_VECTOR(, plobserver_t) observers;
	SCCP_VECTOR(, plslot_t) slots;
	SCCP_RWLIST_ENTRY(sccp_parkinglot_t) list;
};

#define ICONSTATE_NEW_ON 0x020303												// option:closed, color=yellow, flashspeed=slow
#define ICONSTATE_NEW_OFF 0x010000												// option:open, color=off, flashspeed=None
#define ICONSTATE_OLD_ON 1													// option:closed
#define ICONSTATE_OLD_OFF 0													// option:open

/* private functions */
//#define sccp_parkinglot_lock(x)	({sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_2 "%s:%d:requestinglock:%p\n",__PRETTY_FUNCTION__,__LINE__,x);pbx_mutex_lock(&((sccp_parkinglot_t * const)(x))->lock);sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_2 "%s:%d:locked:%p\n",__PRETTY_FUNCTION__,__LINE__,x);})				// discard const
//#define sccp_parkinglot_unlock(x)	({sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_2 "%s:%d:unlock:%p\n",__PRETTY_FUNCTION__,__LINE__,x);pbx_mutex_unlock(&((sccp_parkinglot_t * const)(x))->lock);})			// discard const
#define sccp_parkinglot_lock(x)		({pbx_mutex_lock(&((sccp_parkinglot_t * const)(x))->lock);})				// discard const
#define sccp_parkinglot_unlock(x)	({pbx_mutex_unlock(&((sccp_parkinglot_t * const)(x))->lock);})				// discard const

SCCP_RWLIST_HEAD(sccp_parkinglot_vector, sccp_parkinglot_t) parkinglots;
#define OBSERVER_CB_CMP(elem, value) ((elem).device == (value).device && (elem).instance == (value).instance)
#define SLOT_CB_CMP(elem, value) ((elem).slot == (value))

#define SLOT_CLEANUP(elem) 							\
	if ((elem).exten) {sccp_free((elem).exten);}				\
	if ((elem).from) {sccp_free((elem).from);}				\
	if ((elem).channel) {sccp_free((elem).channel);}			\
	if ((elem).callerid_num) {sccp_free((elem).callerid_num);}		\
	if ((elem).callerid_name) {sccp_free((elem).callerid_name);}		\
	if ((elem).connectedline_num) {sccp_free((elem).connectedline_num);}	\
	if ((elem).connectedline_name) {sccp_free((elem).connectedline_name);}


/* exported functions */
/* returns locked pl */
static sccp_parkinglot_t * addParkinglot(const char *parkinglot)
{
	pbx_assert(parkinglot != NULL);

	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (addParkinglot) %s\n", parkinglot);
	sccp_parkinglot_t *pl = (sccp_parkinglot_t *) sccp_calloc(sizeof(sccp_parkinglot_t), 1);
	if (!pl) {
		return NULL;
	}

	pl->context = pbx_strdup(parkinglot);
	pbx_mutex_init(&pl->lock);
	SCCP_VECTOR_INIT(&pl->observers,1);
	SCCP_VECTOR_INIT(&pl->slots,1);

	SCCP_RWLIST_WRLOCK(&parkinglots);
	/* The lookup that preceded us only held the read lock: another thread may have created this context
	 * in between. Re-check under the write lock and hand out the existing parkinglot, otherwise two
	 * parkinglots with the same context end up in the list and observers/slots get split between them. */
	sccp_parkinglot_t *existing = NULL;
	SCCP_RWLIST_TRAVERSE(&parkinglots, existing, list) {
		if (sccp_strcaseequals(existing->context, parkinglot)) {
			break;
		}
	}
	if (existing) {
		sccp_parkinglot_lock(existing);
		SCCP_RWLIST_UNLOCK(&parkinglots);
		if (pl->context) {
			sccp_free(pl->context);
		}
		SCCP_VECTOR_FREE(&pl->observers);
		SCCP_VECTOR_FREE(&pl->slots);
		pbx_mutex_destroy(&pl->lock);
		sccp_free(pl);
		return existing;
	}
	sccp_parkinglot_lock(pl);
	SCCP_RWLIST_INSERT_HEAD(&parkinglots, pl, list);
	SCCP_RWLIST_UNLOCK(&parkinglots);
	return pl;
}

static int removeParkinglot(sccp_parkinglot_t *pl)
{
	pbx_assert(pl != NULL && pl != NULL);

	int res = FALSE;
	sccp_parkinglot_t *removed = NULL;
	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (removeParkinglot) %s\n", pl->context);

	/* Lock order everywhere else is parkinglots(rw) -> pl->lock (findParkinglotByContext takes
	 * pl->lock under the list rdlock). We arrive holding only pl->lock, so taking the list wrlock
	 * here would invert that order (ThreadSanitizer reported the potential deadlock against a
	 * device registering while another one unregistered). Drop pl->lock, take the list lock, then
	 * re-take pl under it. In between, a concurrent detach may already have removed and destroyed
	 * pl - so check it is still in the list before touching it - or an attach may have added an
	 * observer, so re-check that it is still empty. Destruction only ever happens after removal
	 * under the wrlock, hence "still listed" means "still alive". */
	sccp_parkinglot_unlock(pl);
	SCCP_RWLIST_WRLOCK(&parkinglots);
	{
		sccp_parkinglot_t *it = NULL;
		boolean_t present = FALSE;
		SCCP_RWLIST_TRAVERSE(&parkinglots, it, list) {
			if (it == pl) {
				present = TRUE;
				break;
			}
		}
		if (!present) {
			SCCP_RWLIST_UNLOCK(&parkinglots);
			sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (removeParkinglot) already removed concurrently\n");
			return FALSE;
		}
	}
	sccp_parkinglot_lock(pl);
	if (SCCP_VECTOR_SIZE(&pl->observers) != 0 || pl->inflight != 0) {				/* an observer attached meanwhile, or a notification still has to re-take pl->lock: keep the parkinglot */
		SCCP_RWLIST_UNLOCK(&parkinglots);
		sccp_parkinglot_unlock(pl);
		return FALSE;
	}
	removed = SCCP_RWLIST_REMOVE(&parkinglots, pl, list);
	SCCP_RWLIST_UNLOCK(&parkinglots);
	sccp_parkinglot_unlock(pl);

	if (removed) {
		if (removed->context) {
			sccp_free(removed->context);
		}
		SCCP_VECTOR_RESET(&removed->observers, SCCP_VECTOR_ELEM_CLEANUP_NOOP);
		SCCP_VECTOR_FREE(&removed->observers);
		SCCP_VECTOR_RESET(&removed->slots, SLOT_CLEANUP);
		SCCP_VECTOR_FREE(&removed->slots);
		pbx_mutex_destroy(&removed->lock);
		sccp_free(removed);
		res = TRUE;
	}
	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (removeParkinglot) done\n");
	return res;
}

/* returns locked pl */
static sccp_parkinglot_t * const findParkinglotByContext(const char *parkinglot)
{
	pbx_assert(parkinglot != NULL);

	sccp_parkinglot_t *pl = NULL;
	SCCP_RWLIST_RDLOCK(&parkinglots);
	SCCP_RWLIST_TRAVERSE(&parkinglots, pl, list) {
		sccp_parkinglot_lock(pl);
		if (sccp_strcaseequals(pl->context, parkinglot)) {
			//sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (findParkinglotByContext) found match:%s\n", pl->context);
			// returning parkinglot locked
			break;
		}
		sccp_parkinglot_unlock(pl);
	}
	SCCP_RWLIST_UNLOCK(&parkinglots);
	return pl;
}

/* returns locked pl */
static sccp_parkinglot_t * const findCreateParkinglot(const char *parkinglot, boolean_t create)
{
	pbx_assert(parkinglot != NULL);

	//sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (findCreateParkinglot) %s (create:%s)\n", parkinglot, create ? "TRUE" : "FALSE");
	sccp_parkinglot_t *pl = findParkinglotByContext(parkinglot);
	if (!pl && create) {
		if (!(pl = addParkinglot(parkinglot))) {							/* returned locked */
			//pbx_log(LOG_NOTICE, "SCCP: (findCreateParkinglot) Could not add ParkingLot: %s\n", parkinglot);
			return NULL;
		}
		//sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (findCreateParkinglot) New %s Created\n", parkinglot);
	}
	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (findCreateParkinglot) Found:%s \n", pl ? "TRUE" : "FALSE");
	return pl;
}

// observer
static int attachObserver(sccp_device_t * device, const sccp_buttonconfig_t * const buttonConfig)
{
	pbx_assert(device != NULL && buttonConfig != NULL);
	int res = FALSE;

	if(!sccp_strlen_zero(buttonConfig->button.feature.options)) {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (attachObserver) device:%s at instance:%d\n", buttonConfig->button.feature.options, device->id, buttonConfig->instance);
		RAII(sccp_parkinglot_t *, pl, findCreateParkinglot(buttonConfig->button.feature.options, TRUE), sccp_parkinglot_unlock);
		if (pl) {
			plobserver_t observer = {
				.device = device,
				.instance = buttonConfig->instance,
				.transactionId = 0,
			};

			/* upgrade to wrlock */
			if (SCCP_VECTOR_APPEND(&pl->observers, observer) == 0) {
				res = TRUE;
			}
		}
	}
	return res;
}

static int detachObserver(sccp_device_t * device, const sccp_buttonconfig_t * const buttonConfig)
{
	pbx_assert(device != NULL && buttonConfig != NULL);
	int res = FALSE;

	if(!sccp_strlen_zero(buttonConfig->button.feature.options)) {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (detachObserver) device:%s at instance:%d\n", buttonConfig->button.feature.options, device->id, buttonConfig->instance);
		sccp_parkinglot_t * pl = findCreateParkinglot(buttonConfig->button.feature.options, FALSE); /* don't use RAII, removeParkinglot unlocks and destroys the lock */
		if (pl) {
			plobserver_t cmp = {
				.device = device,
				.instance = buttonConfig->instance,
			};
			if (SCCP_VECTOR_REMOVE_CMP_UNORDERED(&pl->observers, cmp, OBSERVER_CB_CMP, SCCP_VECTOR_ELEM_CLEANUP_NOOP) == 0) {
				res = TRUE;
			}
			if (SCCP_VECTOR_SIZE(&pl->observers) == 0) {
				removeParkinglot(pl);	// will destroy pl and unlock pl in the process
			} else {
				sccp_parkinglot_unlock(pl);
			}
		}
	}
	return res;
}

static char * const getParkingLotCXML(sccp_parkinglot_t *pl, int protocolversion, uint8_t instance, uint32_t transactionId, char **const outbuf)
{
	pbx_assert(pl != NULL && outbuf != NULL);

	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (getParkingLotCXML) with version:%d\n", pl->context, protocolversion);
	*outbuf = NULL;
	if (SCCP_VECTOR_SIZE(&pl->slots)) {
		pbx_str_t *buf = ast_str_create(DEFAULT_PBX_STR_BUFFERSIZE);
		pbx_str_append(&buf, 0, "<?xml version=\"1.0\"?>");
		if (protocolversion < 15) {
			pbx_str_append(&buf, 0, "<CiscoIPPhoneMenu>");
		} else {
			pbx_str_append(&buf, 0, "<CiscoIPPhoneMenu appId='%d' onAppClosed='%d'>", appID, appID);
		}
		pbx_str_append(&buf, 0, "<Title>Parked Calls</Title>");
		pbx_str_append(&buf, 0, "<Prompt>Choose a ParkingLot Slot</Prompt>");
		for (size_t idx = 0; idx < SCCP_VECTOR_SIZE(&pl->slots); idx++) {
			plslot_t *slot = SCCP_VECTOR_GET_ADDR(&pl->slots, idx);
			pbx_str_append(&buf, 0, "<MenuItem>");
			const char *connected_line = !sccp_strcaseequals(slot->connectedline_name, "<unknown>") ? slot->connectedline_name : slot->from;
			if (!sccp_strcaseequals(slot->callerid_name, "<unknown>")) {
				pbx_str_append(&buf, 0, "<Name>%s (%s) by %s</Name>", slot->callerid_name, slot->callerid_num, connected_line);
			} else {
				pbx_str_append(&buf, 0, "<Name>%s by %s</Name>", slot->callerid_num, connected_line);
			}
			pbx_str_append(&buf, 0, "<URL>UserCallData:%d:%d:%d:%d:%s/%s</URL>", appID, instance, 0, transactionId, pl->context, slot->exten);
			pbx_str_append(&buf, 0, "</MenuItem>");
		}
		pbx_str_append(&buf, 0, "<SoftKeyItem>");
		pbx_str_append(&buf, 0, "<Name>Dial</Name>");
		pbx_str_append(&buf, 0, "<Position>1</Position>");
		pbx_str_append(&buf, 0, "<URL>UserDataSoftKey:Select:%d:DIAL/%d</URL>", appID, transactionId);
		pbx_str_append(&buf, 0, "</SoftKeyItem>\n");
		pbx_str_append(&buf, 0, "<SoftKeyItem>");
		pbx_str_append(&buf, 0, "<Name>Exit</Name>");
		pbx_str_append(&buf, 0, "<Position>3</Position>");
		pbx_str_append(&buf, 0, "<URL>UserDataSoftKey:Select:%d:EXIT/%d</URL>", appID, transactionId);
		pbx_str_append(&buf, 0, "</SoftKeyItem>\n");

		pbx_str_append(&buf, 0, "</CiscoIPPhoneMenu>");
		*outbuf = pbx_strdup(pbx_str_buffer(buf));
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (getParkingLotCXML) with version:%d, result:\n[%s]\n", pl->context, protocolversion, *outbuf);
		sccp_free(buf);
	}
	return *outbuf;
}

/* pl->lock held. Observers are stored by value and the vector is compacted on detach, so the returned
 * address is only valid until pl->lock is dropped: look the observer up again after re-taking it. */
static plobserver_t * findObserver(sccp_parkinglot_t *pl, constDevicePtr d, uint8_t instance)
{
	for (size_t idx = 0; idx < SCCP_VECTOR_SIZE(&pl->observers); idx++) {
		plobserver_t *observer = SCCP_VECTOR_GET_ADDR(&pl->observers, idx);
		if (observer && observer->device == d && observer->instance == instance) {
			return observer;
		}
	}
	return NULL;
}

typedef enum { PL_VISUAL_NONE = 0, PL_VISUAL_SHOW, PL_VISUAL_HIDE } plvisual_action_t;
typedef struct {
	plvisual_action_t action;
	uint32_t transactionId;
	char *xmlStr;												/* show: menu to send, NULL when the lot has no slots */
} plvisual_t;

/* pl->lock held: gather everything needed to update the visual parkinglot window on the phone, so that the
 * messages themselves can be sent with pl->lock dropped (see _notifyHelper for the lock order) */
static void prepareVisual(sccp_parkinglot_t *pl, constDevicePtr d, uint8_t instance, plvisual_action_t action, plvisual_t *visual)
{
	plobserver_t *observer = findObserver(pl, d, instance);
	memset(visual, 0, sizeof(*visual));
	if (!observer || action == PL_VISUAL_NONE) {
		return;
	}
	visual->action = action;
	if (action == PL_VISUAL_SHOW) {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (showVisualParkingLot) showing on device:%s, instance:%d\n", pl->context, d->id, instance);
		visual->transactionId = sccp_random();
		getParkingLotCXML(pl, d->protocolversion, instance, visual->transactionId, &visual->xmlStr);
	} else {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (hideVisualParkingLot) device:%s, instance:%d\n", pl->context, d->id, instance);
		visual->transactionId = observer->transactionId;
	}
}

/* pl->lock NOT held */
static void sendVisual(constDevicePtr d, plvisual_t *visual)
{
	if (visual->action == PL_VISUAL_SHOW) {
		if (visual->xmlStr) {
			d->protocol->sendUserToDeviceDataVersionMessage(d, appID, 0, 0, visual->transactionId, visual->xmlStr, 0);
			sccp_free(visual->xmlStr);
		} else {
			sccp_dev_displayprinotify(d, SKINNY_DISP_CANNOT_RETRIEVE_PARKED_CALL, SCCP_MESSAGE_PRIORITY_TIMEOUT, 5);
		}
	} else if (visual->action == PL_VISUAL_HIDE) {
		char xmlStr[DEFAULT_PBX_STR_BUFFERSIZE];
		if (d->protocolversion < 15) {
			snprintf(xmlStr, DEFAULT_PBX_STR_BUFFERSIZE, "<CiscoIPPhoneExecute><ExecuteItem Priority=\"0\" URL=\"Init:Services\"/></CiscoIPPhoneExecute>");
		} else {
			snprintf(xmlStr, DEFAULT_PBX_STR_BUFFERSIZE, "<CiscoIPPhoneExecute><ExecuteItem Priority=\"0\" URL=\"App:Close:%d\"/></CiscoIPPhoneExecute>", appID);
		}
		d->protocol->sendUserToDeviceDataVersionMessage(d, appID, 0, 0, visual->transactionId, xmlStr, 0);
	}
}

/* pl->lock re-taken: record the window state on the observer, if it is still attached */
static void commitVisual(sccp_parkinglot_t *pl, constDevicePtr d, uint8_t instance, plvisual_t *visual)
{
	plobserver_t *observer = NULL;
	if (visual->action != PL_VISUAL_NONE && (observer = findObserver(pl, d, instance))) {
		observer->transactionId = (visual->action == PL_VISUAL_SHOW) ? visual->transactionId : 0;
	}
}

/* called and returns with pl->lock held; drops it while the phone is being updated */
static void __showVisualParkingLot(sccp_parkinglot_t *pl, constDevicePtr d, uint8_t instance)
{
	pbx_assert(pl != NULL && d != NULL);
	plvisual_t visual;

	prepareVisual(pl, d, instance, PL_VISUAL_SHOW, &visual);
	pl->inflight++;
	sccp_parkinglot_unlock(pl);
	sendVisual(d, &visual);
	sccp_parkinglot_lock(pl);
	pl->inflight--;
	commitVisual(pl, d, instance, &visual);
}

/* called and returns with pl->lock held; drops it while the phone is being updated */
static void __hideVisualParkingLot(sccp_parkinglot_t *pl, constDevicePtr d, uint8_t instance)
{
	pbx_assert(pl != NULL && d != NULL);
	plvisual_t visual;

	prepareVisual(pl, d, instance, PL_VISUAL_HIDE, &visual);
	pl->inflight++;
	sccp_parkinglot_unlock(pl);
	sendVisual(d, &visual);
	sccp_parkinglot_lock(pl);
	pl->inflight--;
	commitVisual(pl, d, instance, &visual);
}

static void hideVisualParkingLot(const char *parkinglot, constDevicePtr d, uint8_t instance)
{
	pbx_assert(parkinglot != NULL &&  d != NULL);

	RAII(sccp_parkinglot_t *, pl, findCreateParkinglot(parkinglot, TRUE), sccp_parkinglot_unlock);
	if (pl) {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (hideVisualParkingLot) device:%s, instance:%d, size:%d\n", parkinglot, d->id, instance, (int)SCCP_VECTOR_SIZE(&pl->observers));
		__hideVisualParkingLot(pl, d, instance);
	}
}

/* Called and returns with pl->lock held. The device side (lamp, buttonconfig, feature event, window) runs
 * with pl->lock dropped: device->buttonconfig is taken before pl->lock on the register/unregister paths, so
 * taking it here under pl->lock was an ABBA against a device (un)registering while a call got parked.
 * While the lock is dropped the observer may get detached (and the vector compacted), so the observer is
 * addressed by (device, instance) and looked up again afterwards, never through a kept pointer. */
static void _notifyHelper(sccp_parkinglot_t *pl, constDevicePtr device, uint8_t instance)
{
	uint32_t iconstate = 0;
	sccp_buttonconfig_t *config = NULL;
	plvisual_t visual;
	plvisual_action_t action = PL_VISUAL_NONE;
	size_t numslots = SCCP_VECTOR_SIZE(&pl->slots);
	plobserver_t *observer = findObserver(pl, device, instance);
	if (!observer) {
		return;
	}
	if (observer->transactionId) {										/* window currently displayed: refresh or close it */
		action = (numslots > 0 && !device->active_channel) ? PL_VISUAL_SHOW : PL_VISUAL_HIDE;
	}
	prepareVisual(pl, device, instance, action, &visual);

	pl->inflight++;
	sccp_parkinglot_unlock(pl);

	if (device->protocolversion < 15) {
		sccp_device_setLamp(device, SKINNY_STIMULUS_PARKINGLOT, 0, numslots ? SKINNY_LAMP_ON : SKINNY_LAMP_OFF);
		iconstate = numslots ? ICONSTATE_OLD_ON : ICONSTATE_OLD_OFF;
	} else {
		iconstate = numslots ? ICONSTATE_NEW_ON : ICONSTATE_NEW_OFF;
	}

	// change button state
	SCCP_LIST_LOCK(&device->buttonconfig);
	SCCP_LIST_TRAVERSE(&device->buttonconfig, config, list) {
		if (config->type == FEATURE && config->instance == instance) {
			config->button.feature.status = iconstate;
		}
	}
	SCCP_LIST_UNLOCK(&device->buttonconfig);

	// update already displayed visual parkinglot window
	sendVisual(device, &visual);
	sccp_feat_changed(device, NULL, SCCP_FEATURE_PARKINGLOT);

	sccp_parkinglot_lock(pl);
	pl->inflight--;
	commitVisual(pl, device, instance, &visual);
}

static void notifyDevice(constDevicePtr device, const sccp_buttonconfig_t * const buttonConfig)
{
	pbx_assert(device != NULL && buttonConfig != NULL);

	if(!sccp_strlen_zero(buttonConfig->button.feature.options)) {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (notifyDevice) notifyDevice:%s\n", buttonConfig->button.feature.options, device->id);
		RAII(sccp_parkinglot_t *, pl, findCreateParkinglot(buttonConfig->button.feature.options, TRUE), sccp_parkinglot_unlock);
		if (pl) {
			_notifyHelper(pl, device, buttonConfig->instance);
		}
	}
}

/* threadpool job: bring every observer of the parkinglot up to date with its current state */
static void * notifyWorker(void *data)
{
	char *context = (char *) data;
	if (!context) {
		return NULL;
	}
	sccp_parkinglot_t *pl = findParkinglotByContext(context);						/* returns locked; NULL when the lot went away meanwhile */
	if (pl) {
		pl->notifyPending = FALSE;									/* a change from here on schedules a new run */
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (notify)\n", pl->context);

		/* _notifyHelper drops pl->lock while it talks to the phone; observers can attach/detach meanwhile and
		 * the vector gets compacted, so walk a snapshot (devices retained) instead of the live vector slots */
		size_t count = SCCP_VECTOR_SIZE(&pl->observers);
		plobserver_t *snapshot = count ? (plobserver_t *) sccp_calloc(sizeof(plobserver_t), count) : NULL;
		if (snapshot) {
			size_t num = 0;
			for (size_t idx = 0; idx < count; idx++) {
				plobserver_t *observer = SCCP_VECTOR_GET_ADDR(&pl->observers, idx);
				if (observer && (snapshot[num].device = sccp_device_retain(observer->device))) {
					snapshot[num].instance = observer->instance;
					num++;
				}
			}
			for (size_t idx = 0; idx < num; idx++) {
				_notifyHelper(pl, snapshot[idx].device, snapshot[idx].instance);
				sccp_device_release(&snapshot[idx].device);
			}
			sccp_free(snapshot);
		}
		sccp_parkinglot_unlock(pl);
	}
	sccp_free(context);
	return NULL;
}

/* pl->lock held. Slot changes arrive on the manager thread, inside asterisk's manager-hook callback (hook list
 * read-locked). The device side of a notification takes device->buttonconfig, and devices hold buttonconfig
 * while they emit manager events of their own (unregister path), which closed a lock-order cycle. So the
 * notification is queued on the threadpool instead of being run here; runs are coalesced, a pending job reads
 * the state current at the time it executes. */
static void notifyLocked(sccp_parkinglot_t *pl)
{
	pbx_assert(pl != NULL);

	if (pl->notifyPending || SCCP_VECTOR_SIZE(&pl->observers) == 0) {
		return;
	}
	char *context = pbx_strdup(pl->context);
	if (context && sccp_threadpool_add_work(GLOB(general_threadpool), notifyWorker, context)) {
		pl->notifyPending = TRUE;
	} else {
		pbx_log(LOG_NOTICE, "%s: (notify) could not queue the parkinglot notification, phones will catch up on the next change\n", pl->context);
		if (context) {
			sccp_free(context);
		}
	}
}

// slot
static int addSlot(const char *parkinglot, int slot, struct message *m)
{
	pbx_assert(parkinglot != NULL && m != NULL);

	int res = FALSE;

	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (addSlot) adding to slot:%d\n", parkinglot, slot);

	RAII(sccp_parkinglot_t *, pl, findCreateParkinglot(parkinglot, TRUE), sccp_parkinglot_unlock);
	if (pl) {
		if (SCCP_VECTOR_GET_CMP(&pl->slots, slot, SLOT_CB_CMP) == NULL) {
			plslot_t new_slot = { 
				.slot = slot,
				.exten = pbx_strdup(astman_get_header(m, PARKING_SLOT)),
				.from = pbx_strdup(astman_get_header(m, PARKING_FROM)),
				.channel = pbx_strdup(astman_get_header(m, PARKING_PREFIX "Channel")),
				.callerid_num = pbx_strdup(astman_get_header(m, PARKING_PREFIX "CallerIDNum")),
				.callerid_name = pbx_strdup(astman_get_header(m, PARKING_PREFIX "CallerIDName")),
				.connectedline_num = pbx_strdup(astman_get_header(m, PARKING_PREFIX "ConnectedLineNum")),
				.connectedline_name = pbx_strdup(astman_get_header(m, PARKING_PREFIX "ConnectedLineName")),
			};
			if (SCCP_VECTOR_APPEND(&pl->slots, new_slot) == 0)  {
				notifyLocked(pl);
				res = TRUE;
			}
		} else {
			notifyLocked(pl);
		}
	} else {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (addSlot) ParkingLot:%s is not being observed\n", parkinglot);
	}
	return res;
}

static int removeSlot(const char *parkinglot, int slot)
{
	pbx_assert(parkinglot != NULL);

	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (removeSlot) removing slot:%d\n", parkinglot, slot);
	int res = FALSE;

	RAII(sccp_parkinglot_t *, pl, findCreateParkinglot(parkinglot, TRUE), sccp_parkinglot_unlock);
	if (pl) {
		if (SCCP_VECTOR_REMOVE_CMP_UNORDERED(&pl->slots, slot, SLOT_CB_CMP, SLOT_CLEANUP) == 0) {
			notifyLocked(pl);
			res = TRUE;
		}
	} else {
		sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "SCCP: (removeSlot) ParkingLot:%s is not being observed\n", parkinglot);
	}
	return !res;
}

/*
 * Handle Park Feature Button Press
 * -If we have an active call -> pressing the park feature key, will park that call
 * -If we are not on an active call:
 * 	- If there is 0 parked calls: Display Status Message, "No parked calls'
 * 	- If there is 1 parked call: Unpark that call immediatly
 *	- If there is more than 1 parked call: display the visual parking lot representation.
 */
static void handleButtonPress(constDevicePtr d, const sccp_buttonconfig_t * const buttonConfig)
{
	pbx_assert(d != NULL && buttonConfig != NULL);
	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (handleButtonPress) options:%s, instance:%d\n", d->id, buttonConfig->button.feature.options, buttonConfig->instance);

	AUTO_RELEASE(sccp_channel_t, channel , sccp_device_getActiveChannel(d));
	if (channel && channel->state != SCCP_CHANNELSTATE_OFFHOOK && channel->state != SCCP_CHANNELSTATE_HOLD) {
		sccp_channel_park(channel);
	} else if(!sccp_strlen_zero(buttonConfig->button.feature.options)) {
		RAII(sccp_parkinglot_t *, pl, findCreateParkinglot(buttonConfig->button.feature.options, TRUE), sccp_parkinglot_unlock);
		if (pl) {
			if (SCCP_VECTOR_SIZE(&pl->slots) == 0) {
				sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (handleButtonPress) 0 slot occupied. Show statusBar message\n", buttonConfig->button.feature.options);
				sccp_dev_displayprinotify(d, SKINNY_DISP_CANNOT_RETRIEVE_PARKED_CALL, SCCP_MESSAGE_PRIORITY_TIMEOUT, 5);
			} else {
				if(sccp_strcaseequals(buttonConfig->button.feature.args, "RetrieveSingle") && SCCP_VECTOR_SIZE(&pl->slots) == 1) {
					sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (handleButtonPress) 1 slot occupied -> Unpark Call Immediately\n", buttonConfig->button.feature.options);
					plslot_t *slot = SCCP_VECTOR_GET_ADDR(&pl->slots, 0);
					if (slot) {
						AUTO_RELEASE(sccp_line_t, line , channel ? sccp_line_retain(channel->line) : d->currentLine ? sccp_dev_getActiveLine(d) : sccp_line_find_byid(d, d->defaultLineInstance));
						AUTO_RELEASE(sccp_channel_t, new_channel,
							     sccp_channel_newcall(line, d, slot->exten, SKINNY_CALLTYPE_OUTBOUND, NULL, NULL));                                        // implicit release
					}
				} else {
					sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (handleButtonPress) multiple slots occupied -> Show Visual ParkingLot\n", buttonConfig->button.feature.options);
					__showVisualParkingLot(pl, d, buttonConfig->instance);
				}
			}
		}
	}
}

static void handleDevice2User(const char *parkinglot, constDevicePtr d, const char *slot_exten, uint8_t instance, uint32_t transactionId)
{
	pbx_assert(d != NULL);
	sccp_log(DEBUGCAT_PARKINGLOT)(VERBOSE_PREFIX_1 "%s: (handleDevice2Usewr) instance:%d, transactionId:%d\n", d->id, instance, transactionId);

	if (d->dtu_softkey.action && d->dtu_softkey.transactionID == transactionId) {
		if (sccp_strequals(d->dtu_softkey.action, "DIAL")) {
			AUTO_RELEASE(sccp_line_t, line , d->currentLine ? sccp_dev_getActiveLine(d) : sccp_line_find_byid(d, d->defaultLineInstance));
			AUTO_RELEASE(sccp_channel_t, new_channel, sccp_channel_newcall(line, d, slot_exten, SKINNY_CALLTYPE_OUTBOUND, NULL, NULL));                                        // implicit release
		} else if (sccp_strequals(d->dtu_softkey.action, "EXIT")) {
			hideVisualParkingLot(parkinglot, d, instance);
		}
	}
}
/* Assign to interface */
const ParkingLotInterface iParkingLot = {
	.attachObserver = attachObserver,
	.detachObserver = detachObserver,
	.addSlot = addSlot,
	.removeSlot = removeSlot,
	.handleButtonPress = handleButtonPress,
	.handleDevice2User = handleDevice2User,
	.notifyDevice = notifyDevice,
};
#else
const ParkingLotInterface iParkingLot = { 0 };
#endif
