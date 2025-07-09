#!/usr/bin/env python3
"""Simple Locust load test for FoodMe application"""

import json
import random
from locust import FastHttpUser, task, between
from faker import Faker

fake = Faker()


class FoodMeUser(FastHttpUser):
    wait_time = between(1, 3)

    @task(3)
    def get_restaurants(self):
        """Get list of restaurants"""
        self.client.get("/api/restaurant")

    @task(1)
    def place_order(self):
        """Place a food order"""
        order_data = {
            "deliverTo": {
                "name": fake.name(),
                "address": f"{fake.street_address()}, {fake.city()}, {fake.state_abbr()} {fake.zipcode()}"
            },
            "restaurant": {
                "name": "Beijing Express"
            },
            "payment": {
                "cvc": "456",
                "expire": "08/2027",
                "number": "1234123412341234",
                "type": "visa"
            },
            "items": [
                {"name": "Egg rolls (4)", "price": 3.95, "qty": 1},
                {"name": "General Tao's chicken", "price": 5.95, "qty": 1}
            ]
        }

        self.client.post("/api/order", json=order_data)


if __name__ == "__main__":
    import subprocess
    import sys

    host = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:3000"
    print(f"Running load test against: {host}")

    cmd = [
        "locust",
        "-f", __file__,
        "--host", host,
        "--headless",
        "-u", "5",
        "-r", "1",
        "-t", "30s"
    ]

    subprocess.run(cmd)
