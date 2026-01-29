#!/usr/bin/env python3
# GENERATED — review before use
# Simple seeding script to generate random customers and emit SQL INSERT statements.
# By default it prints SQL to stdout. To apply directly to the local cockroach cluster using docker-compose,
# pipe into `docker-compose --env-file .env exec -T cockroach1 /cockroach/cockroach sql --insecure --database=app`.

import uuid
import random
import argparse
from datetime import datetime

FIRST_NAMES = ["Alice","Bob","Carol","David","Eve","Frank","Grace","Heidi","Ivan","Judy"]
LAST_NAMES = ["Smith","Johnson","Williams","Brown","Jones","Miller","Davis","Garcia","Rodriguez","Wilson"]
REGIONS = ["us-east", "us-west", "eu-central"]

EMAIL_DOMAINS = ["example.com","example.org","example.net"]


def random_customer():
    first = random.choice(FIRST_NAMES)
    last = random.choice(LAST_NAMES)
    cid = str(uuid.uuid4())
    email = f"{first.lower()}.{last.lower()}.{random.randint(1,9999)}@{random.choice(EMAIL_DOMAINS)}"
    phone = f"+1-555-{random.randint(1000,9999)}"
    region = random.choice(REGIONS)
    address = f"{random.randint(1,9999)} {random.choice(['Main St','Oak Ave','Pine Rd','Maple St'])}"
    created = datetime.utcnow().isoformat() + 'Z'
    return {
        'id': cid,
        'region': region,
        'first_name': first,
        'last_name': last,
        'email': email,
        'phone': phone,
        'address': address,
        'created_at': created
    }


def to_sql_insert(c):
    # Use parameter-safe quoting for simple types; values are already safe in this generator.
    return (
        "INSERT INTO customers.customer (id, region, first_name, last_name, email, phone, address, created_at) VALUES ("
        f"'{c['id']}', '{c['region']}', '{c['first_name']}', '{c['last_name']}', '{c['email']}', '{c['phone']}', '{c['address']}', '{c['created_at']}'"
        ");"
    )


def main():
    p = argparse.ArgumentParser(description='Seed random customers (emit SQL).')
    p.add_argument('-n', '--count', type=int, default=100, help='number of customers to generate')
    p.add_argument('--region', choices=REGIONS, help='restrict all generated customers to a region')
    args = p.parse_args()

    for _ in range(args.count):
        c = random_customer()
        if args.region:
            c['region'] = args.region
        print(to_sql_insert(c))

if __name__ == '__main__':
    main()
