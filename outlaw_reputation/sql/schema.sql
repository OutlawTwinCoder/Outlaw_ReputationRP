CREATE TABLE IF NOT EXISTS outlaw_reputation_players (
    identifier VARCHAR(64) NOT NULL,
    rep_type VARCHAR(50) NOT NULL,
    value INT NOT NULL DEFAULT 0,
    PRIMARY KEY (identifier, rep_type)
);

CREATE TABLE IF NOT EXISTS outlaw_reputation_business (
    business VARCHAR(50) NOT NULL,
    rep INT NOT NULL DEFAULT 0,
    PRIMARY KEY (business)
);

CREATE TABLE IF NOT EXISTS outlaw_reputation_contribution (
    identifier VARCHAR(64) NOT NULL,
    business VARCHAR(50) NOT NULL,
    rep INT NOT NULL DEFAULT 0,
    PRIMARY KEY (identifier, business),
    INDEX idx_business (business)
);

CREATE TABLE IF NOT EXISTS outlaw_police_records (
    identifier VARCHAR(64) NOT NULL,
    known_crime_rep INT NOT NULL DEFAULT 0,
    last_update DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (identifier)
);
