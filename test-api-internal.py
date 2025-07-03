#!/usr/bin/env python3
import requests
import json
import sys

def test_api(host="http://foodme:3000"):
    """Test the FoodMe API endpoints from within the Docker network"""
    
    print(f"Testing API at: {host}")
    
    try:
        # Test restaurant endpoint
        print("\n1. Testing GET /api/restaurant")
        response = requests.get(f"{host}/api/restaurant", timeout=10)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Found {len(data)} restaurants")
            if data:
                print(f"   First restaurant: {data[0]['name']}")
        else:
            print(f"   Error: {response.text}")
        
        # Test order endpoint with sample data
        print("\n2. Testing POST /api/order")
        order_data = {
            "deliverTo": {
                "name": "Test User",
                "address": "123 Test St, Test City, TS 12345"
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
                {"name": "Egg rolls (4)", "price": 3.95, "qty": 1}
            ]
        }
        
        response = requests.post(f"{host}/api/order", json=order_data, timeout=10)
        print(f"   Status: {response.status_code}")
        if response.status_code in [200, 201]:
            print("   ✅ Order placed successfully")
        else:
            print(f"   Error: {response.text}")
            
        return True
        
    except requests.exceptions.ConnectionError as e:
        print(f"❌ Connection failed: {e}")
        return False
    except requests.exceptions.Timeout as e:
        print(f"❌ Request timeout: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    host = sys.argv[1] if len(sys.argv) > 1 else "http://foodme:3000"
    success = test_api(host)
    sys.exit(0 if success else 1)
