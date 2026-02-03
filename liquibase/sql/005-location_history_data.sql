/* 
CREATE TABLE movr.location_history(
    id UUID PRIMARY KEY,
    vehicle_id UUID REFERENCES movr.vehicles(id) ON DELETE CASCADE,
    ts TIMESTAMP NOT NULL,
    longitude FLOAT8 NOT NULL,
    latitude FLOAT8 NOT NULL
);
*/

INSERT INTO movr.location_history (id, vehicle_id, ts, longitude, latitude) VALUES
	('0011521c-7c34-4e48-9146-8980f6202996', '001d7e32-932c-4b2a-af01-8f31f7a56b09', '2020-04-29 19:21:53+00:00', (-74.03534), 40.58763)
;

