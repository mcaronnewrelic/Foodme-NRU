export interface Restaurant {
  id: string;
  name: string;
  cuisine: string;
  price: number;
  rating: number;
  description?: string;
  image?: string;
  menuItems?: MenuItem[];
}

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
}

export interface Customer {
  name?: string;
  email?: string;
  phone?: string;
  address?: string;
}

export interface CartItem {
  menuItem: MenuItem;
  quantity: number;
  restaurant: Restaurant;
}

export interface Order {
  id: string;
  customer: Customer;
  items: CartItem[];
  restaurant: Restaurant;
  total: number;
  status: 'pending' | 'confirmed' | 'preparing' | 'delivered';
  createdAt: Date;
}
