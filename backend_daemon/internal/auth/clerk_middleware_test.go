package auth

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func createTestJWT(claims map[string]interface{}) string {
	header := map[string]string{"alg": "none", "typ": "JWT"}
	hBytes, _ := json.Marshal(header)
	cBytes, _ := json.Marshal(claims)

	h64 := base64.RawURLEncoding.EncodeToString(hBytes)
	c64 := base64.RawURLEncoding.EncodeToString(cBytes)

	return h64 + "." + c64 + ".sig"
}

func TestClerkMiddleware_PublicEndpoints(t *testing.T) {
	middleware := NewClerkMiddleware(ClerkConfig{
		SecretKey: "live_secret_key_123",
		DevMode:   false,
	})

	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	}))

	// 1. /api/health should bypass auth
	req := httptest.NewRequest(http.MethodGet, "/api/health", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for /api/health, got %d", rr.Code)
	}

	// 2. OPTIONS preflight should bypass auth
	reqOptions := httptest.NewRequest(http.MethodOptions, "/api/git/analyze", nil)
	rrOptions := httptest.NewRecorder()
	handler.ServeHTTP(rrOptions, reqOptions)

	if rrOptions.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for OPTIONS preflight, got %d", rrOptions.Code)
	}
}

func TestClerkMiddleware_DevModeBypass(t *testing.T) {
	middleware := NewClerkMiddleware(ClerkConfig{
		SecretKey: "",
		DevMode:   true,
	})

	var userGot *UserClaims
	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, ok := UserFromContext(r.Context())
		if ok {
			userGot = user
		}
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPost, "/api/git/analyze", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 in dev mode, got %d", rr.Code)
	}
	if userGot == nil || userGot.UserID != "user_dev_local" {
		t.Fatalf("expected dev user claims in context, got %+v", userGot)
	}
}

func TestClerkMiddleware_ProtectedEndpoint_MissingToken(t *testing.T) {
	middleware := NewClerkMiddleware(ClerkConfig{
		SecretKey: "sk_live_dummy",
		DevMode:   false,
	})

	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/api/state", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized for missing token, got %d", rr.Code)
	}
}

func TestClerkMiddleware_ProtectedEndpoint_ValidToken(t *testing.T) {
	middleware := NewClerkMiddleware(ClerkConfig{
		SecretKey: "", // use internal token claims parser
		DevMode:   false,
	})

	token := createTestJWT(map[string]interface{}{
		"sub":   "user_test_99",
		"sid":   "sess_12345",
		"email": "test@otto.dev",
		"exp":   time.Now().Add(1 * time.Hour).Unix(),
	})

	var userGot *UserClaims
	handler := middleware.Middleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, ok := UserFromContext(r.Context())
		if ok {
			userGot = user
		}
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/api/state", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for valid token, got %d: %s", rr.Code, rr.Body.String())
	}
	if userGot == nil || userGot.UserID != "user_test_99" {
		t.Fatalf("expected user claims populated with user_test_99, got %+v", userGot)
	}
	if userGot.Email != "test@otto.dev" {
		t.Fatalf("expected email test@otto.dev, got %s", userGot.Email)
	}
}
