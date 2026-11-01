#!/usr/bin/python
# pylint: disable=missing-class-docstring,missing-function-docstring

import random
from locust import FastHttpUser, TaskSet, between, task
from faker import Faker
fake = Faker()


class Order:
    class Customer:
        name = ""
        address = ""

        def to_json(self):
            return dict(name=self.name, address=self.address)

    class Restaurant:
        name = ""

        def to_json(self):
            return dict(name=self.name)

    class Payment:
        cvc = "456"
        expire = "08/2027"
        number = "1234123412341234"
        type = "visa"

        def to_json(self):
            return dict(cvc=self.cvc, expire=self.expire, number=self.number, type=self.type)

    def __init__(self):
        self.deliver_to = self.Customer()
        self.restaurant = self.Restaurant()
        self.payment = self.Payment()
        self.items = []

    def to_json(self):
        return dict(
            deliverTo=self.deliver_to.to_json(),
            restaurant=self.restaurant.to_json(),
            payment=self.payment.to_json(),
            items=self.items
        )


customers = [
    'Emilia Brooks',
    'Hugo Awesomesauce',
    'Justin Ferguson',
    'Penelope Andrews',
    'Rebecca Elliott',
    'Rocco Marinara',
    'Yasmin Reid'
]

orders = []

sample_order = Order()
sample_order.restaurant.name = "Beijing Express"
sample_order.items = [
    {"name": "Egg rolls (4)", "price": 3.95, "qty": 1},
    {"name": "General Tao's chicken", "price": 5.95, "qty": 1},
    {"name": "Potstickers (6)", "price": 6.95, "qty": 1}
]
orders.append(sample_order)

sample_order = Order()
sample_order.restaurant.name = "Naan Sequitur"
sample_order.items = [
    {"name": "Butter Chicken", "price": 5.95, "qty": 1},
    {"name": "Basmati rice", "price": 6.95, "qty": 1},
    {"name": "Plain naan", "price": 5.95, "qty": 1},
    {"name": "Gulab Jamun", "price": 8.95, "qty": 1}
]
orders.append(sample_order)

sample_order = Order()
sample_order.restaurant.name = "Czech Point"
sample_order.items = [
    {"name": "Chicken breast fillet schnitzel ", "price": 10.45, "qty": 1},
    {"name": "Dumplings", "price": 5.95, "qty": 1}
]
orders.append(sample_order)


def get_restaurants(l):
    l.client.get("/api/restaurant")


def place_order(l):
    selected_order = random.choice(orders)
    selected_order.deliver_to.name = random.choice(customers)
    selected_order.deliver_to.address = (
        fake.street_address() + " " + fake.city() + ", " +
        fake.state_abbr() + " " + fake.zipcode()
    )
    l.client.post("/api/order", json=selected_order.to_json())


class UserBehavior(TaskSet):
    def on_start(self):
        get_restaurants(self)

    @task(3)
    def get_restaurants_task(self):
        get_restaurants(self)

    @task(1)
    def place_order_task(self):
        place_order(self)


class WebsiteUser(FastHttpUser):
    tasks = [UserBehavior]
    wait_time = between(1, 5)
