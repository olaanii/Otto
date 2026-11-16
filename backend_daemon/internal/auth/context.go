package auth

import "context"

type contextKey string

const userClaimsKey contextKey = "otto_user_claims"

// UserClaims represents the authenticated user's identity and metadata extracted from Clerk JWT.
type UserClaims struct {
	UserID    string                 `json:"user_id"`
	SessionID string                 `json:"session_id,omitempty"`
	Email     string                 `json:"email,omitempty"`
	Username  string                 `json:"username,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
	RawToken  string                 `json:"-"`
}

// WithUser attaches authenticated user claims to the request context.
func WithUser(ctx context.Context, claims *UserClaims) context.Context {
	return context.WithValue(ctx, userClaimsKey, claims)
}

// UserFromContext retrieves the authenticated user claims from context, if present.
func UserFromContext(ctx context.Context) (*UserClaims, bool) {
	if ctx == nil {
		return nil, false
	}
	claims, ok := ctx.Value(userClaimsKey).(*UserClaims)
	return claims, ok && claims != nil
}
