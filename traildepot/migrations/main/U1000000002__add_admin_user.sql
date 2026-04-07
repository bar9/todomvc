DELETE FROM _user;

INSERT INTO _user
(email, password_hash, verified, admin)
VALUES
    ('admin@localhost', (hash_password('secret')), true, true);
