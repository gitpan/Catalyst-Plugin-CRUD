DROP TABLE tiny_url;

-- TinyURL
CREATE TABLE tiny_url (
        id SERIAL PRIMARY KEY NOT NULL /* ID */,
        disable INTEGER DEFAULT '0' NOT NULL /* ��� */,
        long_url TEXT NOT NULL /* URL */
);

GRANT ALL ON tiny_url TO PUBLIC;
GRANT ALL ON tiny_url_id_seq TO PUBLIC;


