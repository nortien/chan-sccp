#ifndef AST121_COMPAT_H
#define AST121_COMPAT_H
/*
 * Asterisk 21+ removed the macroexten/macrocontext channel fields, leftovers
 * from the deprecated app_macro application (removed in Asterisk 21, see
 * asterisk/asterisk@e8f548c). chan-sccp's ast116-based implementation (reused
 * here for ast121) still references them. Since the underlying concept no
 * longer exists in Asterisk, these are stubbed: getters return an empty
 * string, setters are no-ops.
 */
/* Declared up front: without it the struct is first seen inside the parameter
 * lists below, giving each stub its own incomplete type scoped to that
 * prototype. Callers passing a real ast_channel * then trip
 * -Wincompatible-pointer-types, which is fatal wherever -Werror is on. */
struct ast_channel;

static inline const char *ast_channel_macroexten(const struct ast_channel *chan) { (void)chan; return ""; }
static inline void ast_channel_macroexten_set(struct ast_channel *chan, const char *value) { (void)chan; (void)value; }
static inline const char *ast_channel_macrocontext(const struct ast_channel *chan) { (void)chan; return ""; }
static inline void ast_channel_macrocontext_set(struct ast_channel *chan, const char *value) { (void)chan; (void)value; }
#endif
