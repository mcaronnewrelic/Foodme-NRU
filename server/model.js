var idFromName = function(name) {
  return name && name.toLowerCase().replace(/\W/g, '');
};

var isString = function(value) {
  return typeof value === 'string';
};

var DAYS = {
  Su: 0,
  Mo: 1,
  Tu: 2,
  We: 3,
  Th: 4,
  Fr: 5,
  Sa: 6
};

var parseDays = function(str) {
  return str.split(',').map(function(day) {
    return DAYS[day];
  });
};


var Restaurant = function(data) {
  // defaults
  this.days = [1, 2, 3, 4, 5, 6];
  this.menuItems = [];
  this.price = 0;
  this.rating = 0;

  this.update(data);

  this.id = this.id || idFromName(this.name);
};

Restaurant.prototype.update = function(data) {
  Object.keys(data).forEach(function(key) {
    if (key === 'price' || key === 'rating' && isString(data[key])) {
      this[key] = parseInt(data[key], 10);
    } else {
      this[key] = data[key];
    }
  }, this);

  // Add image URL based on restaurant name/id
  if (!this.image && this.id) {
    this.image = `/assets/img/restaurants/${this.id}.jpg`;
  }

  this.menuItems = this.menuItems.map(function(data) {
    return new MenuItem(data);
  });
};

Restaurant.prototype.validate = function(errors) {
  if (!this.name) {
    errors.push('Invalid: "name" is a mandatory field!');
  }

  return errors.length === 0;
};

Restaurant.fromArray = function(data) {
  return new Restaurant({
    id: data[1],
    name: data[0],
    cuisine: data[2],
    opens: data[3],
    closes: data[4],
    days: parseDays(data[5]),
    price: parseInt(data[6], 10),
    rating: parseInt(data[7], 10),
    location: data[8],
    description: data[9]
  });
};


var MenuItem = function(data) {
  this.id = data.id || Math.random().toString(36).substr(2, 9);
  this.name = data.name;
  this.price = data.price;
  this.description = data.description || '';
  this.category = data.category || this.categorizeMenuItem(data.name);
};

MenuItem.prototype.categorizeMenuItem = function(name) {
  const nameUpper = name.toUpperCase();
  
  if (nameUpper.includes('SALAD') || nameUpper.includes('GEMISCHTER')) {
    return 'Salads';
  } else if (nameUpper.includes('SOUP') || nameUpper.includes('SUPPE')) {
    return 'Soups';
  } else if (nameUpper.includes('WURST') || nameUpper.includes('BRATWURST') || nameUpper.includes('FRANKFURTER')) {
    return 'Sausages';
  } else if (nameUpper.includes('PIZZA') || nameUpper.includes('PASTA')) {
    return 'Italian';
  } else if (nameUpper.includes('BURGER') || nameUpper.includes('SANDWICH')) {
    return 'Burgers & Sandwiches';
  } else if (nameUpper.includes('DESSERT') || nameUpper.includes('CAKE') || nameUpper.includes('ICE')) {
    return 'Desserts';
  } else if (nameUpper.includes('DRINK') || nameUpper.includes('BEER') || nameUpper.includes('WINE') || nameUpper.includes('COCKTAIL')) {
    return 'Beverages';
  } else {
    return 'Main Dishes';
  }
};

MenuItem.fromArray = function(data) {
  return new MenuItem({
    name: data[1],
    price: parseFloat(data[2]),
    description: data[3] || '',
    category: data[4] || 'Main Dishes'
  });
};

exports.Restaurant = Restaurant;
exports.MenuItem = MenuItem;
