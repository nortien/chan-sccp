/*!
 * \file        pbx_impl.h
 * \brief       SCCP PBX Asterisk Wrapper Header
 * \author      Diederik de Groot <ddegroot [at] users.sourceforge.net>
 * \note        Reworked, but based on chan_sccp code.
 *              The original chan_sccp driver that was made by Zozo which itself was derived from the chan_skinny driver.
 *              Modified by Jan Czmok and Julien Goodwin
 * \note        This program is free software and may be modified and distributed under the terms of the GNU Public License.
 *              See the LICENSE file at the top of the source tree.
 *
 */
#pragma once

#include "config.h"
#include "common.h"

#ifdef HAVE_ASTERISK
#include "ast/ast.h"
#endif

__BEGIN_C_EXTERN__
#define PBX_BRIDGE_TYPE struct ast_bridge

/*!
 * \brief SCCP PBX Callback function
 *
 * Register Callback_Functions for a particular PBX Implementation and PBX Version. This will make it possible to make
 * chan-sccp agnostic to the PBX Software we are connected to. And provides a way to cope with multiple different versions
 * of these PBX Implementation. There Callback functions are implemented under the pbx_impl directory
 */
typedef struct _PbxInterface {
	/* *INDENT-OFF* */
	/* channels */
	boolean_t(*const alloc_pbxChannel) (sccp_channel_t * channel, const void * ids, const PBX_CHANNEL_TYPE * pbxSrcChannel, PBX_CHANNEL_TYPE ** pbxDstChannel);	/* returns a new channel with pbx_channel_ref and ast_module_info_ref*/
	int (*const set_callstate) (constChannelPtr pbx_channel, enum ast_channel_state state);
	boolean_t(*const checkhangup) (constChannelPtr channel);
	int (*const hangup) (PBX_CHANNEL_TYPE * channel);							/* review 2026-09: assigned in no astNNN.c and never called - the wrapper sccp_astwrap_hangup is wired into sccp_tech.hangup (the table Asterisk calls), this member is the older plan */
	sccp_extension_status_t(*const extension_status) (constChannelPtr channel);

	void (*const setPBXChannelLinkedId) (PBX_CHANNEL_TYPE *pbxchannel, const char *linkedid);

	const char *(*const getChannelName) (const sccp_channel_t *channel);
	void (*const setChannelName) (const sccp_channel_t *channel, const char *name);
	const char *(*const getChannelUniqueID) (const sccp_channel_t *channel);
	const char *(*const getChannelAppl) (const sccp_channel_t *channel);
	const char *(*const getChannelExten) (const sccp_channel_t *channel);
	void (*const setChannelExten) (const sccp_channel_t *channel, const char *exten);
	const char *(*const getChannelLinkedId) (constChannelPtr channel);
	void (*const setChannelLinkedId) (const sccp_channel_t *channel, const char *linkedid);
	enum ast_channel_state (*const getChannelState) (const sccp_channel_t *channel);
	const struct ast_pbx *(*const getChannelPbx) (const sccp_channel_t *channel);
	const char *(*const getChannelContext) (constChannelPtr channel);					/* review 2026-09: assigned but never called - the core uses the pbx_channel_context() macro from define.h directly */
	void (*const setChannelContext) (const sccp_channel_t *channel, const char *context);
	/* review 2026-09: the four macroexten/macrocontext members are assigned in every astNNN.c and called
	 * from nowhere - the only mentions of macroexten in the tree are the wrappers, these rows and the
	 * pbx_channel_macroexten/macrocontext alias macros, none of them used. app_macro is gone since
	 * Asterisk 21, so keeping these four wrappers compiling is what the ast121/122/123_compat.h stubs
	 * exist for: a dead interface member dragging a compatibility layer behind it. */
	const char *(*const getChannelMacroExten) (constChannelPtr channel);
	void (*const setChannelMacroExten) (const sccp_channel_t *channel, const char *exten);
	const char *(*const getChannelMacroContext) (constChannelPtr channel);
	void (*const setChannelMacroContext) (const sccp_channel_t *channel, const char *context);
	const char *(*const getChannelCallForward) (constChannelPtr channel);					/* review 2026-09: assigned but never called - pbx_channel_call_forward() macro is used instead */
	void (*const setChannelCallForward) (const sccp_channel_t *channel, const char *fwdnum);

	/** get channel by name */
	boolean_t(*const getChannelByName) (const char *name, PBX_CHANNEL_TYPE **pbx_channel);
	boolean_t(*const getRemoteChannel) (const sccp_channel_t *channel, PBX_CHANNEL_TYPE **pbx_channel);
	void *(*const getChannelByCallback) (int (*is_match)(PBX_CHANNEL_TYPE *, void *),void *data);		/* review 2026-09: never assigned (only ast106/108/110 name it) and never called - a capability that was declared and not written; same for getPeerCodecCapabilities, rtp_codec, feature_stopMusicOnHold and eventSubscribe below */

	int (*const set_nativeAudioFormats) (constChannelPtr channel, skinny_codec_t codecs[]);
	int (*const set_nativeVideoFormats) (constChannelPtr channel, skinny_codec_t codecs[]);
	int (*const getPeerCodecCapabilities) (constChannelPtr channel, void **capabilities);			/* review 2026-09: never assigned in 111+, never called */
	int (*const send_digit) (constChannelPtr channel, const char digit);
	int (*const send_digits) (constChannelPtr channel, const char *digits);

	int (*const sched_add) (int when, sccp_sched_cb callback, const void *data);
	int (*const sched_del) (int id);
	int (*const sched_add_ref) (int *id, int when, sccp_sched_cb callback, sccp_channel_t *channel);
	int (*const sched_del_ref) (int *id, sccp_channel_t *channel);
	int (*const sched_replace_ref) (int *id, int when, ast_sched_cb callback, sccp_channel_t *channel);
	long (*const sched_when) (int id);										/* review 2026-09: assigned, never called - left from the old scheduler API; sched_add_ref/sched_del_ref are the live pair */
	int (*const sched_wait) (int id);

	/* rtp */
//	int (*const rtp_getPeer) (constChannelPtr channel, struct sockaddr_in * address);		/* review 2026-09: the pre-sockaddr_storage signature; the live one is the next line */
	boolean_t(*const rtp_getPeer) (PBX_RTP_TYPE * rtp, struct sockaddr_storage *address);
	boolean_t(*const rtp_getUs) (PBX_RTP_TYPE * rtp, struct sockaddr_storage *address);
	int (*const rtp_setPhoneAddress) (const struct sccp_rtp * rtp, const struct sockaddr_storage * new_peer, int nat_active);
	boolean_t(*const rtp_setWriteFormat) (constChannelPtr channel, skinny_codec_t codec);
	boolean_t(*const rtp_setReadFormat) (constChannelPtr channel, skinny_codec_t codec);
	boolean_t(*const rtp_destroy) (PBX_RTP_TYPE * rtp);
	void (*const rtp_stop) (PBX_RTP_TYPE *rtp);
	int (*const rtp_codec) (sccp_channel_t * channel);								/* review 2026-09: never assigned in 111+, never called */
	boolean_t(*const rtp_create_instance) (constDevicePtr d, constChannelPtr c, sccp_rtp_t *rtp);
	uint8_t(*const rtp_get_payloadType) (const struct sccp_rtp * rtp, skinny_codec_t codec);
	int(*const rtp_get_sampleRate) (skinny_codec_t codec);
	uint8_t(*const rtp_bridgePeers) (PBX_CHANNEL_TYPE * c0, PBX_CHANNEL_TYPE * c1, int flags, struct ast_frame ** fo, PBX_CHANNEL_TYPE ** rc, int timeoutms);	/* review 2026-09: assigned nowhere, called nowhere - its only implementation, sccp_astwrap_rtpBridge, is under '#if 0' in the wrappers ("until we figure out how to get directrtp back on track") and sccp_tech.bridge uses ast_rtp_instance_bridge instead */

	/* callerid */
	int (*const get_callerid_name) (PBX_CHANNEL_TYPE * pbxChannel, char **cid_name);
	int (*const get_callerid_number) (PBX_CHANNEL_TYPE * pbxChannel, char **cid_number);
	/* review 2026-09: the five getters ton/ani/subaddr/dnid/rdnis are assigned in every astNNN.c and
	 * called from nowhere - numbers and names are read through the iCallInfo subsystem instead. */
	int (*const get_callerid_ton) (PBX_CHANNEL_TYPE * pbxChannel, int *ton);
	int (*const get_callerid_ani) (PBX_CHANNEL_TYPE * pbxChannel, char **ani);
	int (*const get_callerid_subaddr) (PBX_CHANNEL_TYPE * pbxChannel, char **subaddr);
	int (*const get_callerid_dnid) (PBX_CHANNEL_TYPE * pbxChannel, char **dnid);
	int (*const get_callerid_rdnis) (PBX_CHANNEL_TYPE * pbxChannel, char **rdnis);
	sccp_callerid_presentation_t (*const get_callerid_presentation) (PBX_CHANNEL_TYPE * pbxChannel);

	void (*const set_callerid_name) (PBX_CHANNEL_TYPE * pbxChannel, const char *name);
	void (*const set_callerid_number) (PBX_CHANNEL_TYPE * pbxChannel, const char *number);
	void (*const set_callerid_ani) (PBX_CHANNEL_TYPE * pbxChannel, const char *ani);
	void (*const set_callerid_dnid) (PBX_CHANNEL_TYPE * pbxChannel, const char *dnid);				/* review 2026-09, unfinished: every astNNN.c assigns NULL here ("\todo implement callback"); the one caller, sccp_channel.c's forwarding path, is guarded by 'if (iPbx.set_callerid_dnid)', so the DNID of a forwarded call is never set and nothing says so */
	void (*const set_callerid_redirectingParty) (PBX_CHANNEL_TYPE * pbxChannel, const char *number, const char *name);
	void (*const set_callerid_redirectedParty) (PBX_CHANNEL_TYPE * pbxChannel, const char *number, const char *name);
	void (*const set_callerid_presentation) (PBX_CHANNEL_TYPE * pbxChannel, sccp_callerid_presentation_t presentation);
	
	void (*const set_dialed_number) (const sccp_channel_t *channel, const char *number);
	void (*const set_connected_line) (constChannelPtr channel, const char *number, const char *name, uint8_t reason);
	void (*const sendRedirectedUpdate) (constChannelPtr channel, const char *fromNumber, const char *fromName, const char *toNumber, const char *toName, uint8_t reason);

	/* feature section */
	sccp_parkresult_t(*const feature_park) (constChannelPtr hostChannel);
	/* Whether the pbx can park a call at all right now. Optional: a wrapper that does
	 * not set it leaves it NULL, and callers are expected to test the pointer, as they
	 * already do for feature_park itself. */
	boolean_t(*const feature_parkingAvailable) (void);
	boolean_t(*const feature_stopMusicOnHold) (constChannelPtr channel);					/* review 2026-09: never assigned in 111+, never called - duplicates the live moh_stop */
	boolean_t(*const feature_addToDatabase) (const char *family, const char *key, const char *value);
	boolean_t(*const feature_getFromDatabase) (const char *family, const char *key, char *out, int outlen);
	boolean_t(*const feature_removeFromDatabase) (const char *family, const char *key);
	boolean_t(*const feature_removeTreeFromDatabase) (const char *family, const char *key);
	boolean_t(*const feature_monitor) (const sccp_channel_t *channel);
	boolean_t(*const getFeatureExtension) (constChannelPtr channel, const char *featureName, char featureExtension[SCCP_MAX_EXTENSION]);
	boolean_t(*const getPickupExtension) (constChannelPtr channel, char pickupExtension[SCCP_MAX_EXTENSION]);

	void *(*const eventSubscribe)(constChannelPtr channel, char **featureExtension);			/* review 2026-09: never assigned in 111+, never called - the stasis subscription is made directly in sccp_astwrap_park, bypassing the interface (PBX_EVENT_SUBSCRIPTION in ast116.h was typed for it) */
	PBX_CHANNEL_TYPE *(*const findChannelByCallback)(int(*const found_cb)(PBX_CHANNEL_TYPE *c, void *data), void *data, boolean_t lock);	/* review 2026-09: assigned to a stub that returns NULL (its body is commented out over a use-after-free, see sccp_astwrap_findChannelWithCallback) and called from nowhere */

	int(*const moh_start) (PBX_CHANNEL_TYPE * pbx_channel, const char *mclass, const char* interpclass);
	void(*const moh_stop) (PBX_CHANNEL_TYPE * pbx_channel);
	int(*const queue_control) (const PBX_CHANNEL_TYPE * pbx_channel, enum ast_control_frame_type control);
	int(*const queue_control_data) (const PBX_CHANNEL_TYPE * pbx_channel, enum ast_control_frame_type control, const void *data, size_t datalen);

	/* conference */
	boolean_t(*const allocTempPBXChannel) (PBX_CHANNEL_TYPE * pbxSrcChannel, PBX_CHANNEL_TYPE ** pbxDstChannel);
	boolean_t(*const masqueradeHelper) (PBX_CHANNEL_TYPE *pbxChannel, PBX_CHANNEL_TYPE *pbxTmpchannel);
	PBX_CHANNEL_TYPE *(*const requestAnnouncementChannel) (pbx_format_enum_type format, const PBX_CHANNEL_TYPE * requestor, void *data);

	boolean_t(*const set_language)(PBX_CHANNEL_TYPE *pbxChannel, const char *language);

	/* devicestate / extension state */
	skinny_busylampfield_state_t (*const getExtensionState)(const char *extension, const char *context);

	PBX_CHANNEL_TYPE *(*const findPickupChannelByExtenLocked)(PBX_CHANNEL_TYPE *chan, const char *exten, const char *context);
	PBX_CHANNEL_TYPE *(*const findPickupChannelByGroupLocked)(PBX_CHANNEL_TYPE *chan);

 	PBX_ENDPOINT_TYPE *(*const endpoint_create)(const char *tech, const char *resource);
	void (*const endpoint_online)(PBX_ENDPOINT_TYPE *endpoint, const char *address);
	void (*const endpoint_offline)(PBX_ENDPOINT_TYPE *endpoint, const char *cause);
	void (*const endpoint_shutdown)(PBX_ENDPOINT_TYPE **endpoint);

        void (*const set_owner)(sccp_channel_t *channel, PBX_CHANNEL_TYPE *pbx_channel);
        void (*const removeTimingFD)(PBX_CHANNEL_TYPE *pbx_channel);
	int (*const dumpchan)(PBX_CHANNEL_TYPE * const pbx_channel, char * const buf, size_t size);
	boolean_t (*const channel_is_bridged) (sccp_channel_t *channel);
	PBX_CHANNEL_TYPE *(*const get_bridged_channel) (PBX_CHANNEL_TYPE *pbx_channel);					/* takes pbx_channel_ref */
	PBX_CHANNEL_TYPE *(*const get_underlying_channel) (PBX_CHANNEL_TYPE *pbx_channel);				/* takes pbx_channel_ref */
															/* review 2026-09: the real implementation (via tech->bridged_channel) survives only in ast106..ast111; from ast112 on the member is aliased to sccp_astwrap_getBridgeChannel, whose meaning is 'the bridge peer', not 'the underlying channel'. Nobody noticed because the three callers in sccp_conference.c had already been fenced behind ASTERISK_VERSION_GROUP < 112 - in 16..23 it is never called. If it ever were, it would hand back the far end of the bridge. */
	boolean_t (*const attended_transfer) (sccp_channel_t *destination_channel, sccp_channel_t *source_channel);	/* takes pbx_channel_ref on source_channel */

	void (*const set_callgroup)(sccp_channel_t * channel, ast_group_t value);
	void (*const set_pickupgroup)(sccp_channel_t * channel, ast_group_t value);				/* review 2026-09: set_pickupgroup and set_named_pickupgroups are assigned but never called - only the 'call' half is (sccp_feature.c), because pickup needs the new channel's callgroup cleared, not its pickupgroup; the pickup half was written for symmetry */
#if CS_AST_HAS_NAMEDGROUP && ASTERISK_VERSION_GROUP >= 111
	void (*const set_named_callgroups)(sccp_channel_t * channel, struct ast_namedgroups * value);
	void (*const set_named_pickupgroups)(sccp_channel_t * channel, struct ast_namedgroups * value);
#else
	void (*const set_named_callgroups)(sccp_channel_t * channel, void * value);
	void (*const set_named_pickupgroups)(sccp_channel_t * channel, void * value);
#endif
	int (*register_manager)(const char * action, int authority, int (*func)(struct mansession * s, const struct message * m), const char * synopsis, const char * description);
#if ASTERISK_VERSION_GROUP >= 108
	int (*const register_application)(const char * app_name, int (*execute_cb)(struct ast_channel *, const char *));
#else
	int (*const register_application)(const char * app_name, int (*execute_cb)(struct ast_channel *, void *));
#endif
	int (*const unregister_application)(const char * app_name);
	int (*const register_function)(struct pbx_custom_function * custom_function);
	int (*const unregister_function)(struct pbx_custom_function * custom_function);

	uint (*const get_codec_framing)(constChannelPtr c);
	uint (*const get_dtmf_payload_code)(constChannelPtr c);

	void (*const retrieve_remote_capabilities)(channelPtr c);
	/* *INDENT-ON* */
} PbxInterface;

extern const PbxInterface iPbx;
__END_C_EXTERN__
// kate: indent-width 8; replace-tabs off; indent-mode cstyle; auto-insert-doxygen on; line-numbers on; tab-indents on; keep-extra-spaces off; auto-brackets off;
