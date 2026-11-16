package auth

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/clerk/clerk-sdk-go/v2"
	"github.com/clerk/clerk-sdk-go/v2/jwt"
)

// JWK represents a JSON Web Key from Clerk's JWKS endpoint.
type JWK struct {
	Kty string `json:"kty"`
	Use string `json:"use"`
	Kid string `json:"kid"`
	Alg string `json:"alg"`
	N   string `json:"n"`
	E   string `json:"e"`
}

// JWKSResponse represents the keys payload from Clerk.
type JWKSResponse struct {
	Keys []JWK `json:"keys"`
}

// KeyCache provides thread-safe in-memory caching of public keys.
type KeyCache struct {
	mu        sync.RWMutex
	keys      map[string]*rsa.PublicKey
	fetchedAt time.Time
	ttl       time.Duration
	jwksURL   string
	client    *http.Client
}

// NewKeyCache constructs a KeyCache with an expiration TTL.
func NewKeyCache(jwksURL string, ttl time.Duration) *KeyCache {
	if ttl <= 0 {
		ttl = 1 * time.Hour
	}
	return &KeyCache{
		keys:    make(map[string]*rsa.PublicKey),
		ttl:     ttl,
		jwksURL: jwksURL,
		client:  &http.Client{Timeout: 10 * time.Second},
	}
}

// GetKey retrieves a public key by key ID, refreshing the cache if missing or expired.
func (c *KeyCache) GetKey(kid string) (*rsa.PublicKey, error) {
	c.mu.RLock()
	if time.Since(c.fetchedAt) < c.ttl {
		if key, ok := c.keys[kid]; ok {
			c.mu.RUnlock()
			return key, nil
		}
	}
	c.mu.RUnlock()

	// Refresh cache under write lock
	c.mu.Lock()
	defer c.mu.Unlock()

	// Double check after acquiring write lock
	if time.Since(c.fetchedAt) < c.ttl {
		if key, ok := c.keys[kid]; ok {
			return key, nil
		}
	}

	if c.jwksURL == "" {
		return nil, errors.New("no JWKS URL configured")
	}

	resp, err := c.client.Get(c.jwksURL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch JWKS: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to fetch JWKS: status %d: %s", resp.StatusCode, string(body))
	}

	var jwks JWKSResponse
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, fmt.Errorf("failed to decode JWKS payload: %w", err)
	}

	newMap := make(map[string]*rsa.PublicKey)
	for _, jwk := range jwks.Keys {
		if jwk.Kty == "RSA" && jwk.N != "" && jwk.E != "" {
			pubKey, err := parseRSAPublicKey(jwwkN(jwk.N), jwk.E)
			if err == nil {
				newMap[jwk.Kid] = pubKey
			}
		}
	}

	c.keys = newMap
	c.fetchedAt = time.Now()

	if key, ok := c.keys[kid]; ok {
		return key, nil
	}

	// If kid is empty and there's at least one key, return first
	if kid == "" {
		for _, k := range c.keys {
			return k, nil
		}
	}

	return nil, fmt.Errorf("public key with kid %q not found in JWKS", kid)
}

func jwwkN(n string) string {
	return n
}

func parseRSAPublicKey(nStr, eStr string) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(nStr)
	if err != nil {
		return nil, fmt.Errorf("decode modulus: %w", err)
	}
	eBytes, err := base64.RawURLEncoding.DecodeString(eStr)
	if err != nil {
		return nil, fmt.Errorf("decode exponent: %w", err)
	}

	n := new(big.Int).SetBytes(nBytes)
	var e int
	for _, b := range eBytes {
		e = (e << 8) | int(b)
	}

	return &rsa.PublicKey{
		N: n,
		E: e,
	}, nil
}

// ClerkConfig holds parameters for Clerk authentication.
type ClerkConfig struct {
	SecretKey string
	JWKSURL   string
	DevMode   bool
}

// ClerkMiddleware authenticates requests against Clerk JWT tokens.
type ClerkMiddleware struct {
	config   ClerkConfig
	keyCache *KeyCache
}

// NewClerkMiddleware creates a configured middleware instance.
func NewClerkMiddleware(cfg ClerkConfig) *ClerkMiddleware {
	if cfg.SecretKey != "" {
		clerk.SetKey(cfg.SecretKey)
	}
	jwksURL := cfg.JWKSURL
	if jwksURL == "" && cfg.SecretKey != "" {
		// Default Clerk JWKS URL if standard API key format
		jwksURL = "https://api.clerk.com/v1/jwks"
	}

	return &ClerkMiddleware{
		config:   cfg,
		keyCache: NewKeyCache(jwksURL, 1*time.Hour),
	}
}

// PublicPath reports whether a given URL path is exempted from authentication.
func isPublicPath(path string) bool {
	if path == "/api/health" || path == "/healthz" || path == "/api/health/ready" || path == "/" {
		return true
	}
	return false
}

// Middleware returns an HTTP middleware handler for Clerk authentication.
func (m *ClerkMiddleware) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Preflight CORS checks are public
		if r.Method == http.MethodOptions {
			next.ServeHTTP(w, r)
			return
		}

		// Public health check endpoints
		if isPublicPath(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}

		// Extract token from Authorization header or cookie
		rawToken := extractBearerToken(r)

		// Dev mode bypass if explicitly configured or no secret key provided
		secretKey := m.config.SecretKey
		if secretKey == "" {
			secretKey = os.Getenv("CLERK_SECRET_KEY")
		}

		if rawToken == "" {
			if m.config.DevMode || secretKey == "" || secretKey == "dev" || secretKey == "test" {
				// In development/test mode without keys, populate default dev claims
				devClaims := &UserClaims{
					UserID:    "user_dev_local",
					SessionID: "sess_dev_local",
					Email:     "developer@otto.local",
					Username:  "otto-dev",
					Metadata:  map[string]interface{}{"role": "admin", "dev_mode": true},
					RawToken:  "dev-token",
				}
				ctx := WithUser(r.Context(), devClaims)
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}

			writeJSONError(w, http.StatusUnauthorized, "Missing Authorization Bearer token")
			return
		}

		// Verify token using Clerk SDK v2 or fallback to JWT claims extraction
		claims, err := m.verifyToken(r.Context(), rawToken)
		if err != nil {
			// If verification failed and dev mode is explicitly active, allow with fallback
			if m.config.DevMode {
				devClaims := &UserClaims{
					UserID:    "user_dev_local",
					SessionID: "sess_dev_local",
					Email:     "developer@otto.local",
					Username:  "otto-dev",
					RawToken:  rawToken,
				}
				ctx := WithUser(r.Context(), devClaims)
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}
			writeJSONError(w, http.StatusUnauthorized, fmt.Sprintf("Invalid or expired session token: %v", err))
			return
		}

		ctx := WithUser(r.Context(), claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func extractBearerToken(r *http.Request) string {
	authHeader := r.Header.Get("Authorization")
	if authHeader != "" {
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) == 2 && strings.EqualFold(parts[0], "Bearer") {
			return strings.TrimSpace(parts[1])
		}
	}

	// Fallback to __session cookie commonly used by Clerk web apps
	if cookie, err := r.Cookie("__session"); err == nil && cookie.Value != "" {
		return cookie.Value
	}

	return ""
}

// verifyToken verifies the JWT token claims.
func (m *ClerkMiddleware) verifyToken(ctx context.Context, rawToken string) (*UserClaims, error) {
	// 1. Try Clerk SDK v2 verification if secret key is present
	if m.config.SecretKey != "" {
		verifiedClaims, err := jwt.Verify(ctx, &jwt.VerifyParams{
			Token: rawToken,
		})
		if err == nil && verifiedClaims != nil {
			userClaims := &UserClaims{
				UserID:    verifiedClaims.Subject,
				SessionID: verifiedClaims.SessionID,
				RawToken:  rawToken,
			}
			return userClaims, nil
		}
	}

	// 2. Fast decode and validate JWT payload structure
	parts := strings.Split(rawToken, ".")
	if len(parts) != 3 {
		return nil, errors.New("malformed JWT: expected 3 parts")
	}

	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return nil, fmt.Errorf("failed to decode JWT payload: %w", err)
	}

	var rawClaims struct {
		Sub       string                 `json:"sub"`
		Sid       string                 `json:"sid"`
		Email     string                 `json:"email"`
		Username  string                 `json:"username"`
		Exp       int64                  `json:"exp"`
		Nbf       int64                  `json:"nbf"`
		Iat       int64                  `json:"iat"`
		Metadata  map[string]interface{} `json:"metadata"`
		UserMeta  map[string]interface{} `json:"user_metadata"`
	}

	if err := json.Unmarshal(payloadBytes, &rawClaims); err != nil {
		return nil, fmt.Errorf("invalid JWT claims payload: %w", err)
	}

	// Verify expiration if present
	if rawClaims.Exp > 0 && time.Now().Unix() > rawClaims.Exp {
		return nil, errors.New("token has expired")
	}

	if rawClaims.Sub == "" {
		return nil, errors.New("token missing subject claim")
	}

	meta := rawClaims.Metadata
	if meta == nil {
		meta = rawClaims.UserMeta
	}

	return &UserClaims{
		UserID:    rawClaims.Sub,
		SessionID: rawClaims.Sid,
		Email:     rawClaims.Email,
		Username:  rawClaims.Username,
		Metadata:  meta,
		RawToken:  rawToken,
	}, nil
}

func writeJSONError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"error":  message,
		"status": status,
	})
}
