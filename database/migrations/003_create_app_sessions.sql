-- Login sessions for the app and admin panel.
-- Run once on the live database (digitrix_maha_maintain_pro) before using the new login.
-- Only a SHA-256 hash of each token is stored, never the token itself.

CREATE TABLE IF NOT EXISTS app_sessions (
  token_hash CHAR(64) NOT NULL PRIMARY KEY,
  phone_number VARCHAR(20) NULL,
  role VARCHAR(32) NULL,
  expires_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_app_sessions_expires (expires_at)
);
