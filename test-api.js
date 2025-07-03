const http = require('http');

// Test the restaurants list
console.log('🔍 Testing /api/restaurant...');
http.get('http://localhost:3000/api/restaurant', (res) => {
  let data = '';
  res.on('data', (chunk) => { data += chunk; });
  res.on('end', () => {
    try {
      const restaurants = JSON.parse(data);
      console.log('✅ Restaurants loaded:', restaurants.length);
      
      if (restaurants.length > 0) {
        const firstRestaurant = restaurants[0];
        console.log('📍 First restaurant:', firstRestaurant.name, 'ID:', firstRestaurant.id);
        
        // Test individual restaurant
        console.log('🔍 Testing individual restaurant...');
        http.get(`http://localhost:3000/api/restaurant/${firstRestaurant.id}`, (res2) => {
          let data2 = '';
          res2.on('data', (chunk) => { data2 += chunk; });
          res2.on('end', () => {
            try {
              const restaurant = JSON.parse(data2);
              console.log('✅ Restaurant loaded:', restaurant.name);
              console.log('🍽️  Menu items count:', restaurant.menuItems ? restaurant.menuItems.length : 'No menu items');
              
              if (restaurant.menuItems && restaurant.menuItems.length > 0) {
                console.log('📋 First 3 menu items:');
                restaurant.menuItems.slice(0, 3).forEach((item, i) => {
                  console.log(`   ${i+1}. ${item.name} (${item.category}) - $${item.price}`);
                });
                
                // Group by category
                const categories = {};
                restaurant.menuItems.forEach(item => {
                  if (!categories[item.category]) categories[item.category] = 0;
                  categories[item.category]++;
                });
                
                console.log('📂 Categories found:');
                Object.entries(categories).forEach(([cat, count]) => {
                  console.log(`   - ${cat}: ${count} items`);
                });
              }
              
              console.log('\n✅ API test completed successfully!');
            } catch(e) {
              console.log('❌ Error parsing restaurant JSON:', e.message);
            }
          });
        }).on('error', (err) => {
          console.log('❌ Error fetching restaurant:', err.message);
        });
      }
    } catch(e) {
      console.log('❌ Error parsing restaurants JSON:', e.message);
    }
  });
}).on('error', (err) => {
  console.log('❌ Error fetching restaurants:', err.message);
});
