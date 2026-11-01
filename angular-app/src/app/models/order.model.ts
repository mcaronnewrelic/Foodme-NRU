export interface OrderItem {
  id: string;
  menuItemId: string;
  itemName: string;
  quantity: number;
  unitPrice: number;
  specialInstructions?: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  restaurantId: string;
  restaurantName: string;
  status: 'pending' | 'confirmed' | 'preparing' | 'ready' | 'delivered' | 'cancelled';
  totalAmount: number;
  deliveryAddress: string;
  deliveryFee: number;
  taxAmount: number;
  specialInstructions?: string;
  estimatedDeliveryTime?: Date;
  createdAt: Date;
  updatedAt: Date;
  items: OrderItem[];
}